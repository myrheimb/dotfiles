#!/bin/bash
project_directory="$1"
devenv_directory="$project_directory/.devenv"
[ -f "$devenv_directory/shell-env.sh" ] || exit 0

# zsh can't source devenv's shell-env.sh and macOS's bash 3.2 can't parse it, so replay its exports with devenv's bash.
env -i HOME="$HOME" USER="$USER" PATH=__session_path__ "$devenv_directory/profile/bin/bash" -c '
  cd "$1" && source .devenv/shell-env.sh >/dev/null 2>&1
  for name in $(compgen -e); do
    case $name in HOME|OLDPWD|PATH|PWD|SHLVL|TEMP|TEMPDIR|TMP|TMPDIR|USER|_) continue ;; esac
    printf "export %s=%q\n" "$name" "${!name}"
  done
  printf "export PATH=%q:\"\$PATH\"\n" "${PATH%:__session_path__}"
' bash "$project_directory"
