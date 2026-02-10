#!/usr/bin/env python3
"""Create/update the local SSH config file with server info fetched from Bitwarden."""

from os import getenv
from pathlib import Path
from subprocess import CompletedProcess
from subprocess import run

import json
import typing as t

USER = getenv("USER")
USER_HOME = Path(getenv("HOME", f"/Users/{USER}"))

SSH_FOLDER = Path(USER_HOME, ".ssh")
SSH_CONFIG_FILE = Path(SSH_FOLDER, "config")

BW_ITEM_PREFIX = "ssh-config-"

# Ensure user is logged to Bitwarden CLI before proceeding.
if not getenv("BW_SESSION"):
    raise KeyError(
        "BW_SESSION environment variable is not set. "
        "Run 'bw login' or 'bw unlock' and export the BW_SESSION."
    )

VALID_SSH_OPTIONS = frozenset(
    {
        "AddressFamily",
        "Host",
        "HostName",
        "IdentityFile",
        "Port",
        "StrictHostKeyChecking",
        "User",
    }
)


def run_cmd(cmd: t.Sequence) -> CompletedProcess:
    """Reusable call of the subprocess run command."""
    # check=True ensures any returncode other than 0 will raise an exception.
    result = run(cmd, check=True, capture_output=True, text=True, timeout=10)
    return result


def bw_list_items() -> t.List[t.Dict[str, t.Any]]:
    """Fetch all items in Bitwarden containing the BW_ITEM_PREFIX."""
    cmd = ["bw", "list", "items", "--search", BW_ITEM_PREFIX]
    result = run_cmd(cmd)
    return json.loads(result.stdout)


def bw_sync_vault() -> None:
    """Sync the Bitwarden vault."""
    cmd = ["bw", "sync"]
    _result = run_cmd(cmd)


def list_private_ssh_keys() -> t.List[Path]:
    """Return candidate private keys from ~/.ssh."""
    excluded_names = {
        "authorized_keys",
        "config",
        "known_hosts",
    }
    candidates = []
    for key_path in sorted(SSH_FOLDER.iterdir()):
        if not key_path.is_file():
            continue
        if key_path.name in excluded_names:
            continue
        if key_path.suffix in [".pub", ".txt", ".log", ".bak"]:
            continue
        if key_path.name.startswith("known_hosts"):
            continue
        if key_path.name.endswith("_bak"):
            continue
        candidates.append(key_path)
    return candidates


def select_default_ssh_key() -> Path:
    """Prompt user to choose a default private key for the global SSH config section."""
    candidates = list_private_ssh_keys()
    if not candidates:
        raise SystemExit(f"No private SSH keys found in {SSH_FOLDER}.")

    print("Select default SSH key for 'Host *':")  # noqa: T201
    for index, key_path in enumerate(candidates, start=1):
        print(f"  {index}. {key_path}")  # noqa: T201

    while True:
        try:
            choice = input(f"Enter choice [1-{len(candidates)}]: ").strip()
        except KeyboardInterrupt:
            raise SystemExit("\nAborted: SSH config was not changed.")

        if not choice.isdigit():
            print("Invalid input. Enter a number.")  # noqa: T201
            continue

        selected_index = int(choice)
        if 1 <= selected_index <= len(candidates):
            return candidates[selected_index - 1]

        print(f"Invalid choice. Enter a number between 1 and {len(candidates)}.")  # noqa: T201


def reset_ssh_config() -> None:
    """Truncate the SSH config file and add a default entry."""
    default_key_path = select_default_ssh_key()
    with open(SSH_CONFIG_FILE, mode="w") as f:
        f.writelines("Host *\n")
        f.writelines("  AddKeysToAgent yes\n")
        f.writelines(f"  IdentityFile {default_key_path}\n")
        f.writelines("  StrictHostKeyChecking ask\n")
        f.writelines("  IdentitiesOnly yes\n")


def generate_config(host: t.Dict[str, t.Any]) -> None:
    """Take a host dictionary and write it as an SSH config item."""
    config_from_fields = {
        field["name"]: field["value"]
        for field in host["fields"]
        if field["name"] in VALID_SSH_OPTIONS
    }
    identityfile = Path(SSH_FOLDER, str(config_from_fields["IdentityFile"]))
    port = config_from_fields.get("Port", None)
    user = config_from_fields.get("User", None)
    addressfamily = config_from_fields.get("AddressFamily", None)

    with open(SSH_CONFIG_FILE, mode="a") as f:
        f.writelines("\n")
        f.writelines(f"Host {config_from_fields['Host']}\n")
        f.writelines(f"  HostName {config_from_fields['HostName']}\n")

        if identityfile.stem != "None":
            f.writelines(f"  IdentityFile {identityfile}\n")

        if addressfamily:
            f.writelines(f"  AddressFamily {addressfamily}\n")

        if port:
            f.writelines(f"  Port {port}\n")

        if user:
            f.writelines(f"  User {user}\n")
        else:
            f.writelines("  User root\n")


def confirm_overwrite() -> None:
    """Require explicit user acknowledgement before overwriting SSH config."""
    prompt = f"This will overwrite {SSH_CONFIG_FILE}. Type 'yes' to continue: "
    abort_prefix = ""
    try:
        user_input = input(prompt).strip().lower()
        should_abort = user_input != "yes"
    except KeyboardInterrupt:
        should_abort = True
        abort_prefix = "\n"

    if should_abort:
        raise SystemExit(f"{abort_prefix}Aborted: SSH config was not changed.")


def main() -> None:
    """Create SSH config for all servers."""
    confirm_overwrite()
    reset_ssh_config()
    bw_sync_vault()

    for host in bw_list_items():
        generate_config(host)

    print("SSH config updated successfully.")  # noqa: T201


if __name__ == "__main__":
    main()
