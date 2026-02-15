# Load environment variables
source ~/.zshenv

# Initialize starship prompt
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi

# Initialize fzf
if command -v fzf &> /dev/null; then
    eval "$(fzf --zsh)"

    # Configure fzf for history search (Ctrl+R) - compact display
    export FZF_CTRL_R_OPTS="
        --height=5
        --layout=reverse
        --border
        --no-info
        --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'"

    export FZF_DEFAULT_OPTS="--height 5 --layout=reverse --border --no-info"
fi

# Load additional config files
for config in ~/.zdotfiles/zsh/{aliases,functions,path}.zsh; do
    [[ -f $config ]] && source $config
done

# History settings
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE

# Enable emacs key bindings
bindkey -e

# Key bindings - Cmd+Arrow, Option+Arrow, and delete behavior
bindkey '^A' beginning-of-line         # Cmd+Left / Ctrl+A: beginning of line
bindkey '^E' end-of-line               # Cmd+Right / Ctrl+E: end of line
bindkey '^[[1;3D' backward-word        # Option+Left: move back one word
bindkey '^[[1;3C' forward-word         # Option+Right: move forward one word
bindkey '^[b' backward-word            # Option+B: move back one word (alt)
bindkey '^[f' forward-word             # Option+F: move forward one word (alt)
bindkey '^[[3~' delete-char            # Delete key: forward delete

# Auto completion
autoload -Uz compinit
compinit

# Enable case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Zsh options
setopt AUTO_CD
setopt GLOB_DOTS
setopt EXTENDED_GLOB
setopt CORRECT

# Modern command replacements (if available)
if command -v eza &> /dev/null; then
    alias ls='eza --group-directories-first'
    alias la='eza -la --group-directories-first'
    alias ll='eza -l --group-directories-first'
    alias tree='eza --tree'
fi

if command -v bat &> /dev/null; then
    alias cat='bat'
fi

if command -v rg &> /dev/null; then
    alias grep='rg'
fi

if command -v fd &> /dev/null; then
    alias find='fd'
fi