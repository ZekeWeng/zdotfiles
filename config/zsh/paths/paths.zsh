# Paths for the shell.

# Functions
# Each function adds the folder in $1 to PATH, if the folder exists.
# PATH has unique entries, because .zshenv runs typeset -U.
zdotfiles_path_prepend() {
    if [ -d "$1" ]; then
        path=("$1" $path)
    fi
}

zdotfiles_path_append() {
    if [ -d "$1" ]; then
        path+=("$1")
    fi
}

# Homebrew
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Local bin
zdotfiles_path_prepend "$HOME/.local/bin"

# Go
if command -v go >/dev/null 2>&1; then
    export GOPATH="${GOPATH:-$HOME/go}"
    zdotfiles_path_prepend "$GOPATH/bin"
fi

# Rust
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# Python
for python_bin in "$HOME"/Library/Python/3.*/bin(N); do
    zdotfiles_path_prepend "$python_bin"
done
unset python_bin

# Homebrew keg-only formulas
if [ -z "${zdot_brew_kegs+set}" ]; then
    zdot_brew_kegs=(node@22 postgresql@15 rustup)
fi
for keg in $zdot_brew_kegs; do
    zdotfiles_path_prepend "${HOMEBREW_PREFIX:-}/opt/$keg/bin"
done
unset keg
