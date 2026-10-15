# Environment for each zsh shell, also scripts and agent commands. ~/.zshenv links to this file.

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
# They are outside the repo, so agents that work in the repo cannot read them.
# Put tokens in the Keychain with secret-set, not in these files. See config/zsh/modules/aliases.zsh.
zdot_config_dir="${${(%):-%x}:A:h}"
zdot_secrets_dir="$XDG_CONFIG_HOME/zsh/private"
if [ -f "$zdot_secrets_dir/secrets.zsh" ]; then
    . "$zdot_secrets_dir/secrets.zsh"
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
        if [ -f "$zdot_secrets_dir/$zdot_company.secrets.zsh" ]; then
            . "$zdot_secrets_dir/$zdot_company.secrets.zsh"
        fi
        if [ -d "$zdot_config_dir/companies/$zdot_company" ]; then
            zdot_company_dir="$zdot_config_dir/companies/$zdot_company"
            if [ -f "$zdot_company_dir/env.zsh" ]; then
                . "$zdot_company_dir/env.zsh"
            fi
        fi
        ;;
esac
unset zdot_config_dir zdot_secrets_dir
