# Setup for each zsh login shell.
# The path is set here, not in .zshenv, because /etc/zprofile runs path_helper.

# Homebrew
export HOMEBREW_CLEANUP_PERIODIC_FULL_DAYS=7
export HOMEBREW_CLEANUP_MAX_AGE_DAYS=7

# Paths
zsh_config_dir="${${(%):-%x}:A:h}"
. "$zsh_config_dir/paths/paths.zsh"
if [ -f "$zsh_config_dir/paths/local.zsh" ]; then
    . "$zsh_config_dir/paths/local.zsh"
fi
unset zsh_config_dir
