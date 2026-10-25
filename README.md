# dotfiles

This repository contains the dotfiles I use to configure my macOS systems.
They are highly opinionated and designed around my personal workflow and environment.
They may not be suitable for your system without modification, so use them at your own risk.

## Install Nix

**1. Install Nix (https://nixos.org/download/)**
```bash
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)
```

**2. Remove any existing files before starting on a fresh system. Create backups otherwise.**
```bash
sudo rm /etc/bashrc /etc/zshrc /etc/zshenv
```

**3. Install Rosetta to allow compiling Intel binaries (assuming Apple Silicon Mac).**
```bash
softwareupdate --install-rosetta --agree-to-license
```

**4. Install xcode command line tools**
```bash
xcode-select --install 
```

## Clone the repo and rebuild the system

**1. Clone the repo**
```bash
git clone https://github.com/myrheimb/dotfiles.git ~/.dotfiles
```

**2. Add your machine**

Add an entry for your computer/host name to `darwinConfigurations` in `nix-configs/flake.nix`, and a matching `user-specific/<username>/` folder.
```nix
MyBook = mkDarwin { hostname = "MyBook"; name = "username"; };
```

**3. Rebuild the system (takes a few minutes the first time)**

First time, use this command and replace `ComputerName` with the host name you added to `flake.nix`.
```bash
sudo nix run nix-darwin --extra-experimental-features nix-command --extra-experimental-features flakes -- switch --flake ~/.dotfiles/nix-configs#ComputerName
```

The rebuild links `.zshrc`, `.hushlogin`, the Claude Code configs and Zed's keymap and `ruff.toml` from this repo into your home folder, see `nix-configs/home.nix`. Any file already in the way is renamed with a `.before-home-manager` suffix.

Claude Code's sandbox lock lives in `nix-configs/darwin.nix`, not in `claude/settings.json`. The rebuild installs it as a root-owned `/Library/Application Support/ClaudeCode/managed-settings.json`, so Claude can't loosen it. Nix commands can't reach the Nix daemon from inside the sandbox, so the lock lets `nix`, `nix-instantiate` and `nix-shell` run outside it when called by their full `/run/current-system/sw/bin/` path. Each of those calls goes through Claude's normal permission check.

Inside the sandbox, Go, prek and uv keep their caches in `~/.cache/claude-sandbox`, set by a SessionStart hook in `claude/settings.json`. That is the only cache the sandbox can write. Tools you run yourself keep their usual caches, so nothing Claude plants there runs outside the sandbox.

Zed's `settings.json` is a baseline instead of a link. Each rebuild merges `zed/settings.json` into Zed's own settings file: baseline keys win, and anything you add in Zed stays on that machine. To share a tweak across machines, copy it into `zed/settings.json`.

For subsequent rebuilds, simply use the alias.
```bash
nixrb
```

## Managing the global Python

Dependencies for the system-wide `python3` live in `nix-configs/python-env/pyproject.toml`,
pinned in `uv.lock` and built by [uv2nix](https://github.com/pyproject-nix/uv2nix).
Don't add packages directly in `python.nix`.

After editing `pyproject.toml`, re-resolve and rebuild.
```bash
uv lock --directory ~/.dotfiles/nix-configs/python-env
nixrb
```

A pre-commit hook in `.githooks/` rejects commits while `uv.lock` is out of date with `pyproject.toml`.

Use `uv lock --upgrade` to bump versions, or `--upgrade-package NAME` for just one.

Add a new dependency (unpinned) with `uv add --raw --no-sync --directory ~/.dotfiles/nix-configs/python-env NAME`.
