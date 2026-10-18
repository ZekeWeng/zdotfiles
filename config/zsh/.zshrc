# Setup for each interactive zsh shell. ~/.zshrc links to this file.

# SSH
# An SSH login attaches to the tmux session "main". The programs in it continue after the connection stops.
# Detach, and the login closes. Set zdot_ssh_tmux=0 in ~/.zshenv.local to stop this.
# cmux sets CMUX_REAL_ZDOTDIR in each shell of a "cmux ssh" workspace. cmux keeps those shells after a
# disconnect, and each split needs its own shell, so these shells do not attach to "main".
if [ -n "${SSH_CONNECTION:-}" ] && [ -z "${TMUX:-}" ] && [ -z "${CMUX_REAL_ZDOTDIR:-}" ] &&
    [ "${zdot_ssh_tmux:-1}" != 0 ] &&
    [ -t 0 ] && [ -t 1 ] && command -v tmux >/dev/null 2>&1; then
    tmux new-session -A -s main && exit
fi

# Options
setopt AUTO_CD GLOB_DOTS EXTENDED_GLOB CORRECT INTERACTIVE_COMMENTS

# Modules
zdot_config_dir="${${(%):-%x}:A:h}"
if [ -z "${zdot_zsh_modules+set}" ]; then
    zdot_zsh_modules=(history keybinds completions aliases fzf termbg)
fi
for zdot_module in $zdot_zsh_modules; do
    . "$zdot_config_dir/modules/$zdot_module.zsh"
done
unset zdot_module zdot_config_dir

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
