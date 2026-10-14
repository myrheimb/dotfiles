"""Create/update the local SSH config file with server info fetched from Bitwarden."""

from os import environ
from pathlib import Path
from subprocess import PIPE
from subprocess import CalledProcessError
from subprocess import TimeoutExpired
from subprocess import run

import json
import sys
import typing as t

SSH_FOLDER = Path(Path.home(), ".ssh")
SSH_CONFIG_FILE = Path(SSH_FOLDER, "config")

BW_ITEM_PREFIX = "ssh-config-"

SSH_PRIVATE_KEY_HEADERS = frozenset(
    {
        "-----BEGIN DSA PRIVATE KEY-----",
        "-----BEGIN EC PRIVATE KEY-----",
        "-----BEGIN OPENSSH PRIVATE KEY-----",
        "-----BEGIN RSA PRIVATE KEY-----",
    }
)

OPTIONAL_SSH_OPTIONS = (
    "AddressFamily",
    "BatchMode",
    "IdentityFile",
    "Port",
    "StrictHostKeyChecking",
    "User",
)


def run_bw(*arguments: str) -> str:
    """Run a Bitwarden CLI command and return its output."""
    command = f"bw {' '.join(arguments)}"
    try:
        result = run(
            ["bw", *arguments], check=True, capture_output=True, text=True, timeout=30
        )
    except CalledProcessError as error:
        raise SystemExit(
            f"'{command}' failed: {error.stderr.strip()}\nSSH config was not changed."
        )
    except TimeoutExpired:
        raise SystemExit(f"'{command}' timed out.\nSSH config was not changed.")

    return result.stdout


def unlock_vault() -> None:
    """Log in to or unlock Bitwarden if needed, keeping the session for this run."""
    status = json.loads(run_bw("status"))["status"]
    if status == "unlocked":
        return

    if status == "unauthenticated":
        command = "login"
        message = "Log in to Bitwarden to fetch your SSH hosts."
    else:
        command = "unlock"
        message = "Bitwarden is locked. Enter your master password to unlock it."

    # Flushed so it shows before bw's own prompt.
    print(message, flush=True)  # noqa: T201
    try:
        # Only stdout is captured, so bw can still prompt for the master password.
        result = run(["bw", command, "--raw"], check=True, stdout=PIPE, text=True)
    except CalledProcessError:
        raise SystemExit(f"'bw {command}' failed.\nSSH config was not changed.")

    environ["BW_SESSION"] = result.stdout.strip()


def is_private_ssh_key(path: Path) -> bool:
    """Tell SSH private keys apart from other files by their first line."""
    with path.open(errors="ignore") as key_file:
        return key_file.readline().strip() in SSH_PRIVATE_KEY_HEADERS


def list_private_ssh_keys() -> t.List[Path]:
    """Return the private keys in ~/.ssh."""
    return sorted(
        path
        for path in SSH_FOLDER.iterdir()
        if path.is_file() and is_private_ssh_key(path)
    )


def read_default_ssh_key(config: str) -> t.Optional[Path]:
    """Return the key of the 'Host *' section, which is always written first."""
    for line in config.splitlines():
        if line.strip().startswith("IdentityFile "):
            return Path(line.split(maxsplit=1)[1])

    return None


def select_default_ssh_key(current_key: t.Optional[Path]) -> Path:
    """Prompt user to choose a default private key for the global SSH config section."""
    candidates = list_private_ssh_keys()
    if not candidates:
        raise SystemExit(f"No private SSH keys found in {SSH_FOLDER}.")

    if len(candidates) == 1:
        return candidates[0]

    current_choice = (
        str(candidates.index(current_key) + 1) if current_key in candidates else ""
    )

    print("Select default SSH key for 'Host *':")  # noqa: T201
    for index, key_path in enumerate(candidates, start=1):
        marker = " (current)" if str(index) == current_choice else ""
        print(f"  {index}. {key_path}{marker}")  # noqa: T201

    hint = f", Enter keeps {current_choice}" if current_choice else ""
    while True:
        choice = (
            input(f"Enter choice [1-{len(candidates)}{hint}]: ").strip()
            or current_choice
        )
        if choice.isdigit() and 1 <= int(choice) <= len(candidates):
            return candidates[int(choice) - 1]

        print(f"Enter a number between 1 and {len(candidates)}.")  # noqa: T201


def render_default_section(default_key_path: Path) -> str:
    """Render the 'Host *' section that applies to every host."""
    return "\n".join(
        [
            "Host *",
            "  AddKeysToAgent yes",
            f"  IdentityFile {default_key_path}",
            "  StrictHostKeyChecking ask",
            "  IdentitiesOnly yes",
        ]
    )


def render_host(item: t.Dict[str, t.Any]) -> t.Optional[str]:
    """Render a Bitwarden item as an SSH config section, or None if it can't be."""
    # Bitwarden leaves out the value of empty fields.
    options = {
        field["name"]: field["value"]
        for field in item.get("fields") or []
        if field.get("value")
    }

    if "Host" not in options or "HostName" not in options:
        print(  # noqa: T201
            f"Skipping '{item['name']}': it needs a Host and a HostName field.",
            file=sys.stderr,
        )
        return None

    options.setdefault("User", "root")

    if "IdentityFile" in options:
        options["IdentityFile"] = Path(SSH_FOLDER, options["IdentityFile"])

    lines = [f"Host {options['Host']}", f"  HostName {options['HostName']}"]
    lines += [
        f"  {name} {options[name]}" for name in OPTIONAL_SSH_OPTIONS if name in options
    ]
    return "\n".join(lines)


def split_into_hosts(config: str) -> t.Dict[str, str]:
    """Map each Host in a config written by this script to its section."""
    sections = [section for section in config.strip().split("\n\n") if section]
    return {
        section.splitlines()[0].removeprefix("Host "): section for section in sections
    }


def describe_changes(current_config: str, new_config: str) -> t.List[str]:
    """Summarise which hosts would be added, removed or changed."""
    current_hosts = split_into_hosts(current_config)
    new_hosts = split_into_hosts(new_config)
    added = [host for host in new_hosts if host not in current_hosts]
    removed = [host for host in current_hosts if host not in new_hosts]
    changed = [
        host
        for host in new_hosts
        if host in current_hosts and new_hosts[host] != current_hosts[host]
    ]

    summary = []
    if added:
        summary.append(f"Added ({len(added)}): {', '.join(added)}")

    if removed:
        summary.append(f"Removed ({len(removed)}): {', '.join(removed)}")

    if changed:
        summary.append(f"Changed ({len(changed)}):")

    for host in changed:
        current_lines = current_hosts[host].splitlines()
        new_lines = new_hosts[host].splitlines()
        summary.append(f"  {host}")
        summary += [
            f"    - {line.strip()}" for line in current_lines if line not in new_lines
        ]
        summary += [
            f"    + {line.strip()}" for line in new_lines if line not in current_lines
        ]

    return summary


def main() -> None:
    """Create SSH config for all servers."""
    unlock_vault()
    run_bw("sync")
    items = json.loads(run_bw("list", "items", "--search", BW_ITEM_PREFIX))
    # Sorted so Bitwarden's ordering alone never counts as a change.
    host_sections = sorted(section for item in items if (section := render_host(item)))

    current_config = SSH_CONFIG_FILE.read_text() if SSH_CONFIG_FILE.exists() else ""
    default_key_path = select_default_ssh_key(read_default_ssh_key(current_config))
    sections = [render_default_section(default_key_path), *host_sections]
    new_config = "\n\n".join(sections) + "\n"

    changes = describe_changes(current_config, new_config)
    if not changes:
        print(f"{SSH_CONFIG_FILE} is already up to date.")  # noqa: T201
        return

    print("\n".join(changes))  # noqa: T201
    if (
        input(f"\nWrite these changes to {SSH_CONFIG_FILE}? [y/N] ").strip().lower()
        != "y"
    ):
        raise SystemExit("Aborted: SSH config was not changed.")

    SSH_CONFIG_FILE.write_text(new_config)
    host_count = len(host_sections)
    hosts = f"{host_count} {'host' if host_count == 1 else 'hosts'}"
    print(f"Updated {SSH_CONFIG_FILE} with {hosts}.")  # noqa: T201


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        raise SystemExit("\nAborted: SSH config was not changed.")
