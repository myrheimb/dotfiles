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

**2. Add symlinks to set things up**
```bash
ln -sv ~/.dotfiles/.zshrc ~/
ln -sv ~/.dotfiles/.hushlogin ~/
```

Optional: Additional symlinks if you use the Zed editor.
```bash
[[ -d ~/.config/zed ]] || mkdir -p ~/.config/zed
ln -sv ~/.dotfiles/zed/settings.json ~/.config/zed/settings.json
ln -sv ~/.dotfiles/zed/keymap.json ~/.config/zed/keymap.json
ln -sv ~/.dotfiles/zed/ruff.toml ~/.config/zed/ruff.toml
```

**3. Add your machine**

Add an entry for your computer/host name to `darwinConfigurations` in `nix-configs/flake.nix`, and a matching `user-specific/<username>/` folder.
```nix
MyBook = mkDarwin { hostname = "MyBook"; name = "username"; };
```

**4. Rebuild the system (takes a few minutes the first time)**

First time, use this command and replace `ComputerName` with the host name you added to `flake.nix`.
```bash
sudo nix run nix-darwin --extra-experimental-features nix-command --extra-experimental-features flakes -- switch --flake ~/.dotfiles/nix-configs#ComputerName
```

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

Use `uv lock --upgrade` to bump versions, or `--upgrade-package NAME` for just one.

Add a new dependency (unpinned) with `uv add --raw --no-sync --directory ~/.dotfiles/nix-configs/python-env NAME`.

## Optional: Personal Binary Cache

If you run a [personal binary cache](https://nix.dev/tutorials/nixos/binary-cache-setup.html), store the settings in `/etc/nix/local.conf`.

Bootstrap the file by running the command below.

```bash
sudo tee /etc/nix/local.conf >/dev/null <<EOF
extra-substituters = https://binary-cache.tld
extra-trusted-public-keys = binary-cache.tld:PUBLIC_KEY_HERE
extra-secret-key-files = /etc/nix/binary-cache.tld.priv
EOF
```

Make sure the private key is at the expected location.
E.g.,

```bash
sudo cp ~/.ssh/binary-cache.tld.priv /etc/nix/binary-cache.tld.priv
```
