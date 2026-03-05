# Linux-specific shell configuration

# Fix terminal type for SSH sessions from Ghostty
if [[ "$TERM" == "xterm-ghostty" ]] && ! infocmp xterm-ghostty &> /dev/null; then
    export TERM=xterm-256color
fi

# Clipboard support (replaces macOS pbcopy/pbpaste)
if command -v xclip &> /dev/null; then
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
fi

# Use xdg-open instead of macOS open
alias open='xdg-open'

# Key bindings (fix keys that misbehave on Linux terminals)
bindkey '\e[3~' delete-char        # Delete key
bindkey '\e[H'  beginning-of-line  # Home key
bindkey '\e[F'  end-of-line        # End key
bindkey '\e[1~' beginning-of-line  # Home key (alt)
bindkey '\e[4~' end-of-line        # End key (alt)
bindkey '\e[5~' up-line-or-history   # Page Up
bindkey '\e[6~' down-line-or-history # Page Down
bindkey '\e[2~' overwrite-mode     # Insert key
bindkey '\e[A'  up-line-or-history   # Up arrow
bindkey '\e[B'  down-line-or-history # Down arrow
bindkey '\e[C'  forward-char       # Right arrow
bindkey '\e[D'  backward-char      # Left arrow
bindkey '\eOA'  up-line-or-history   # Up arrow (application mode)
bindkey '\eOB'  down-line-or-history # Down arrow (application mode)
bindkey '\eOC'  forward-char       # Right arrow (application mode)
bindkey '\eOD'  backward-char      # Left arrow (application mode)
bindkey '\e[1;5C' forward-word     # Ctrl+Right
bindkey '\e[1;5D' backward-word    # Ctrl+Left
