# Enable GNU Parallel to inherit this shell’s environment
if [[ -r /run/current-system/sw/bin/env_parallel.zsh ]]; then
  source /run/current-system/sw/bin/env_parallel.zsh
fi

# Apply zsh theme
source "$ZSH/oh-my-zsh.sh"

# Tools built locally instead of through Nix
export PATH="$HOME/.local/bin:$PATH"

# Load user-specific settings, aliases, and functions
source "$HOME/.dotfiles/zsh/aliases.zsh"
source "$HOME/.dotfiles/zsh/functions.zsh"
source "$HOME/.dotfiles/user-specific/$USER/profile.zsh"

# Prevent “too many open files”
ulimit -n 2048
