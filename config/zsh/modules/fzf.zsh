# fzf for the shell.

if ! command -v fzf >/dev/null 2>&1; then
    return 0
fi

# Keys and completions
if zdot_fzf_setup="$(fzf --zsh 2>/dev/null)"; then
    eval "$zdot_fzf_setup"
fi
unset zdot_fzf_setup

# fd
if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
fi

# Clipboard
if command -v pbcopy >/dev/null 2>&1; then
    zdot_fzf_clipboard="pbcopy"
else
    zdot_fzf_clipboard="cat >/dev/null"
fi

# Options
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --no-info"
# Ctrl+Y copies the selected command. The quotes keep the --bind value as one argument.
export FZF_CTRL_R_OPTS="--bind 'ctrl-y:execute-silent(echo -n {2..} | $zdot_fzf_clipboard)+abort'"
unset zdot_fzf_clipboard
