# Enable GNU Parallel to inherit this shell’s environment
if [[ -r /run/current-system/sw/bin/env_parallel.zsh ]]; then
  source /run/current-system/sw/bin/env_parallel.zsh
fi

# Apply zsh theme
source "$ZSH/oh-my-zsh.sh"

# Ensure local fasttext model
source $HOME/.dotfiles/languageTool/setup.sh
create_properties_file
download_fasttext_model

# Load user-specific settings, aliases, and functions
source "$HOME/.dotfiles/zsh/aliases.zsh"
source "$HOME/.dotfiles/zsh/functions.zsh"
source "$HOME/.dotfiles/user-specific/$USER/profile.zsh"

# Prevent “too many open files”
ulimit -n 2048

# New tabs open in the current folder, so a tab opened in a devenv project
# starts a second devenv shell. If the first is still building, both build at once.
# Ask whether to start here or in ~.
if [[ -o interactive && -t 0 && $SHLVL -eq 1 && $PWD != $HOME && -e devenv.nix ]]; then
  read -k 1 "reply?Start in ${PWD/#$HOME/~} [Enter] or ~ [h]? "
  echo
  [[ $reply == [hH] ]] && cd "$HOME"
  unset reply
fi

# Enable devenv hook
eval "$(devenv hook zsh)"
