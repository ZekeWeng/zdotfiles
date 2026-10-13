# Setup for each zsh login shell. ~/.zprofile links to this file.
# The path is set here, not in .zshenv, because /etc/zprofile runs path_helper.

# Homebrew
export HOMEBREW_CLEANUP_PERIODIC_FULL_DAYS=7
export HOMEBREW_CLEANUP_MAX_AGE_DAYS=7

# Paths
zdot_config_dir="${${(%):-%x}:A:h}"
. "$zdot_config_dir/paths/paths.zsh"
if [ -f "$zdot_config_dir/paths/local.zsh" ]; then
    . "$zdot_config_dir/paths/local.zsh"
fi
unset zdot_config_dir
