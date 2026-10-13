# Paths for the shell.

# Functions
# Each function adds the folder in $1 to PATH, if the folder exists. .zshenv runs typeset -U, so PATH has no duplicates.
zdot_path_prepend() {
    if [ -d "$1" ]; then
        path=("$1" $path)
    fi
}

zdot_path_append() {
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
zdot_path_prepend "$HOME/.local/bin"

# Go
if command -v go >/dev/null 2>&1; then
    export GOPATH="${GOPATH:-$HOME/go}"
    zdot_path_prepend "$GOPATH/bin"
fi

# Rust
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# Python
for zdot_python_bin in "$HOME"/Library/Python/3.*/bin(N); do
    zdot_path_prepend "$zdot_python_bin"
done
unset zdot_python_bin

# Homebrew keg-only formulas
if [ -z "${zdot_brew_kegs+set}" ]; then
    zdot_brew_kegs=(node@22 postgresql@15 rustup)
fi
for zdot_keg in $zdot_brew_kegs; do
    zdot_path_prepend "${HOMEBREW_PREFIX:-}/opt/$zdot_keg/bin"
done
unset zdot_keg
