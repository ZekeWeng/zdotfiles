# Completions for the shell.

# Homebrew
if [ -d "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh/site-functions" ]; then
    fpath+=("${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh/site-functions")
fi
typeset -U fpath

# compinit
# Run the full compinit one time each day. At other times, use the cache file.
autoload -Uz compinit
zcompdump_old=(~/.zcompdump(N.mh+24))
if [ ! -f ~/.zcompdump ] || [ ${#zcompdump_old} -gt 0 ]; then
    compinit
    touch ~/.zcompdump
else
    compinit -C
fi
unset zcompdump_old

# Styles
zstyle ":completion:*" matcher-list "m:{a-z}={A-Za-z}"
zstyle ":completion:*" menu select

# Tools
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then
    . "$HOME/google-cloud-sdk/completion.zsh.inc"
fi

if command -v kubectl >/dev/null 2>&1; then
    . <(kubectl completion zsh)
fi

if command -v helm >/dev/null 2>&1; then
    . <(helm completion zsh)
fi

if command -v oc >/dev/null 2>&1; then
    . <(oc completion zsh)
fi
