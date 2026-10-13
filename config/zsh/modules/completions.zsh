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

# "TOOL completion zsh" is slow, so cache its output. A new binary path, such as after an upgrade, makes it again.
_zdot_cached_completion() {
    local bin=${commands[$1]:A} cache="$XDG_CACHE_HOME/zsh/completions/$1.zsh" first=""
    [ -n "$bin" ] || return 0
    [ -f "$cache" ] && read -r first <"$cache"
    if [ "$first" != "# $bin" ]; then
        command mkdir -p "${cache:h}"
        if { echo "# $bin" && "$1" completion zsh; } >|"$cache.$$" 2>/dev/null; then
            command mv -f "$cache.$$" "$cache"
        else
            command rm -f "$cache.$$"
        fi
    fi
    [ -f "$cache" ] && . "$cache"
}
for tool in kubectl helm oc; do
    _zdot_cached_completion "$tool"
done
unset tool
