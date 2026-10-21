# Scripts
Collection of scripts that are packaged as executable binaries. Nix packages the Python ones.

Change, remove, or add more in `~/.dotfiles/nix-configs/python-binaries.nix`.

## `securepass.py`
A simple script to generate secure passwords in the terminal.
The packaged binary is named `securepass`, while `pwgen` and `pwgens` are defined as zsh aliases for convenience.

## `update_ssh_config.py`
This script fetches any items (Secure Note) in your Bitwarden vault that start with `ssh-config-` and writes them to `~/.ssh/config` to enable easy logins like e.g., `ssh host`.

Required fields are:
- `Host`
- `HostName`

Optional fields are:
- `IdentityFile`
- `AddressFamily`
- `Port`
- `User`

If `User` is not defined, the script will fall back to `root`.

See `VALID_SSH_OPTIONS` if you want to add additional fields.

## `translate.swift`
Translates text on the device with Apple's Translation framework, using Apple Intelligence models when available. It detects the source language and translates to English, or to Japanese if the text is already English. Pass text as arguments or on stdin, e.g. `translate 'こんにちは'` or the `tl` alias, which translates the clipboard.

Unlike the Python scripts, Nix can't build it, since Nix's Swift lacks the macOS SDK with the Translation framework. Each rebuild compiles it with `/usr/bin/swiftc` into `~/.local/bin/translate`, see `nix-configs/home.nix`.

Language pairs must be downloaded once in System Settings → General → Language & Region → Translation Languages. Without them, it exits with an error.
