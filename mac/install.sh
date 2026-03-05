#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOTFILES_DIR="$HOME/.zdotfiles"

# Check we're on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}This script is intended for macOS only.${NC}"
    exit 1
fi

# Parse arguments
INSTALL_BREW=true
for arg in "$@"; do
    case $arg in
        --no-brew)
            INSTALL_BREW=false
            shift
            ;;
        *)
            ;;
    esac
done

echo -e "${GREEN}Starting macOS installation...${NC}"

# Install Homebrew packages
if [ "$INSTALL_BREW" = true ]; then
    if command -v brew &> /dev/null; then
        echo -e "${YELLOW}Installing Homebrew packages...${NC}"
        brew bundle --file="$DOTFILES_DIR/Brewfile"
    else
        echo -e "${RED}Homebrew not found. Please install Homebrew first.${NC}"
    fi
else
    echo -e "${YELLOW}Skipping Homebrew package installation (--no-brew flag)${NC}"
fi

echo -e "${GREEN}macOS installation complete!${NC}"
