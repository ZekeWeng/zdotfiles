#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOTFILES_DIR="$HOME/.zdotfiles"

# Clone dotfiles if not already present
if [[ ! -d "$DOTFILES_DIR" ]]; then
    echo -e "${YELLOW}Cloning zdotfiles...${NC}"
    git clone https://github.com/$(git config user.name 2>/dev/null || echo "zekeweng")/zdotfiles.git "$DOTFILES_DIR" 2>/dev/null || {
        echo -e "${RED}Could not clone zdotfiles. Please clone manually to ~/.zdotfiles${NC}"
        exit 1
    }
fi

echo -e "${GREEN}Starting dotfiles installation...${NC}"

# Create necessary directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p ~/.config

# Symlink configs
echo -e "${YELLOW}Creating symlinks...${NC}"

ln -sf "$DOTFILES_DIR/nvim" ~/.config/nvim
ln -sf "$DOTFILES_DIR/zsh/.zshrc" ~/.zshrc
ln -sf "$DOTFILES_DIR/zsh/.zshenv" ~/.zshenv
ln -sf "$DOTFILES_DIR/git/.gitconfig" ~/.gitconfig
ln -sf "$DOTFILES_DIR/git/.gitignore_global" ~/.gitignore_global
ln -sf "$DOTFILES_DIR/tmux/.tmux.conf" ~/.tmux.conf
ln -sf "$DOTFILES_DIR/starship.toml" ~/.config/starship.toml

# Install Neovim plugin manager (lazy.nvim)
if [ ! -d ~/.local/share/nvim/lazy/lazy.nvim ]; then
    echo -e "${YELLOW}Installing lazy.nvim...${NC}"
    git clone --filter=blob:none https://github.com/folke/lazy.nvim.git --branch=stable \
        ~/.local/share/nvim/lazy/lazy.nvim
fi

# Detect OS and run platform-specific install
OS="$(uname)"
case "$OS" in
    Darwin)
        echo -e "${YELLOW}Detected macOS. Running macOS install...${NC}"
        bash "$DOTFILES_DIR/mac/install.sh" "$@"
        ;;
    Linux)
        echo -e "${YELLOW}Detected Linux. Running Linux install...${NC}"
        bash "$DOTFILES_DIR/linux/install.sh"
        ;;
    *)
        echo -e "${RED}Unsupported OS: $OS${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}Installation complete!${NC}"
echo -e "${YELLOW}Please restart your terminal or run: exec zsh${NC}"
echo -e "${YELLOW}Note: Make sure to set your terminal font to 'JetBrainsMono Nerd Font' for best appearance${NC}"
