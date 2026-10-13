# Environment for each zsh shell, also scripts and agent commands.

# Path
typeset -U path PATH manpath MANPATH

# XDG folders
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# Editor
export EDITOR="nvim"
export VISUAL="nvim"

# Locale
export LANG="en_US.UTF-8"

# Local overrides
# This file is first, because it sets zdot_company for the secrets below.
if [ -f "$HOME/.zshenv.local" ]; then
    . "$HOME/.zshenv.local"
fi

# Secrets
# secrets.zsh holds the secrets of this laptop.
zsh_config_dir="${${(%):-%x}:A:h}"
if [ -f "$zsh_config_dir/private/secrets.zsh" ]; then
    . "$zsh_config_dir/private/secrets.zsh"
fi

# Company
# If zdot_company is set, load its secrets and its exports. Their values win over the values above.
# zdot_company_dir tells .zshrc where to find the company aliases.
# The name must start with a letter or a digit, so that it cannot be a path such as "..".
unset zdot_company_dir
case "${zdot_company:-}" in
    "" | [!A-Za-z0-9]* | *[!A-Za-z0-9._-]*) ;;
    *)
        # install-agents.sh reads it to warn when the agent rules use a different company.
        export zdot_company
        if [ -f "$zsh_config_dir/private/$zdot_company.secrets.zsh" ]; then
            . "$zsh_config_dir/private/$zdot_company.secrets.zsh"
        fi
        if [ -d "$zsh_config_dir/companies/$zdot_company" ]; then
            zdot_company_dir="$zsh_config_dir/companies/$zdot_company"
            if [ -f "$zdot_company_dir/env.zsh" ]; then
                . "$zdot_company_dir/env.zsh"
            fi
        fi
        ;;
esac
unset zsh_config_dir
