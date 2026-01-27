# Local bin
export PATH="$HOME/.local/bin:$PATH"

# Go
if command -v go &> /dev/null; then
    export GOPATH="$HOME/go"
    export PATH="$GOPATH/bin:$PATH"
fi

# Rust
if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi

# Node.js (if using nvm)
if [[ -d "$HOME/.nvm" ]]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
fi

# Python
if command -v python3 &> /dev/null; then
    export PATH="$HOME/Library/Python/3.11/bin:$PATH"
    export PATH="$HOME/Library/Python/3.12/bin:$PATH"
fi

# PostgreSQL (if installed via Homebrew)
if [[ -d "$HOMEBREW_PREFIX/opt/postgresql@15/bin" ]]; then
    export PATH="$HOMEBREW_PREFIX/opt/postgresql@15/bin:$PATH"
fi