# Load environment variables
source ~/.zshenv

# Initialize starship prompt
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi

# Initialize fzf
if command -v fzf &> /dev/null; then
    eval "$(fzf --zsh)"
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