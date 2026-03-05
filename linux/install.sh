#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOTFILES_DIR="$HOME/.zdotfiles"

# Check we're on Linux
if [[ "$(uname)" != "Linux" ]]; then
    echo -e "${RED}This script is intended for Linux only.${NC}"
    exit 1
fi

echo -e "${GREEN}Starting Linux installation...${NC}"

# Run the Linux migration (install packages, fonts, tools)
echo -e "${YELLOW}Running Linux migration...${NC}"
bash "$DOTFILES_DIR/linux/migrate.sh"

# Source Linux-specific zsh config if not already in .zshrc
LINUX_SOURCE_LINE='[[ -f ~/.zdotfiles/linux/linux.zsh ]] && source ~/.zdotfiles/linux/linux.zsh'
if ! grep -qF "linux/linux.zsh" "$DOTFILES_DIR/zsh/.zshrc"; then
    echo -e "${YELLOW}Adding Linux-specific zsh config sourcing...${NC}"
    echo "" >> "$DOTFILES_DIR/zsh/.zshrc"
    echo "# Linux-specific config" >> "$DOTFILES_DIR/zsh/.zshrc"
    echo "$LINUX_SOURCE_LINE" >> "$DOTFILES_DIR/zsh/.zshrc"
fi

echo -e "${GREEN}Linux installation complete!${NC}"
echo -e "${YELLOW}Run 'exec zsh -l' or restart your terminal to apply changes.${NC}"
