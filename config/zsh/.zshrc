# Setup for each interactive zsh shell.

# Options
setopt AUTO_CD GLOB_DOTS EXTENDED_GLOB CORRECT INTERACTIVE_COMMENTS

# Modules
zsh_config_dir="${${(%):-%x}:A:h}"
if [ -z "${zdot_zsh_modules+set}" ]; then
    zdot_zsh_modules=(history keybinds completions aliases fzf)
fi
for module in $zdot_zsh_modules; do
    . "$zsh_config_dir/modules/$module.zsh"
done
unset module zsh_config_dir

# Company
# .zshenv sets zdot_company_dir when zdot_company names a company folder.
if [ -n "${zdot_company_dir:-}" ] && [ -f "$zdot_company_dir/aliases.zsh" ]; then
    . "$zdot_company_dir/aliases.zsh"
fi

# Prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# zoxide
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# Local overrides
if [ -f "$HOME/.zshrc.local" ]; then
    . "$HOME/.zshrc.local"
fi
