#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "${GREEN}Starting dotfiles installation...${NC}"

# Create necessary directories
echo "${YELLOW}Creating directories...${NC}"
mkdir -p ~/.config

# Symlink configs
echo "${YELLOW}Creating symlinks...${NC}"

# Neovim
ln -sf ~/.zdotfiles/nvim ~/.config/nvim

# Ghostty
ln -sf ~/.zdotfiles/ghostty ~/.config/ghostty

# Zsh
ln -sf ~/.zdotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/.zdotfiles/zsh/.zshenv ~/.zshenv

# Git
ln -sf ~/.zdotfiles/git/.gitconfig ~/.gitconfig
ln -sf ~/.zdotfiles/git/.gitignore_global ~/.gitignore_global

# Tmux
ln -sf ~/.zdotfiles/tmux/.tmux.conf ~/.tmux.conf

# Install Homebrew packages
if command -v brew &> /dev/null; then
    echo "${YELLOW}Installing Homebrew packages...${NC}"
    brew bundle --file=~/.zdotfiles/Brewfile
else
    echo "${RED}Homebrew not found. Please install Homebrew first.${NC}"
fi

# Install Neovim plugin manager (lazy.nvim)
if [ ! -d ~/.local/share/nvim/lazy/lazy.nvim ]; then
    echo "${YELLOW}Installing lazy.nvim...${NC}"
    git clone --filter=blob:none https://github.com/folke/lazy.nvim.git --branch=stable \
        ~/.local/share/nvim/lazy/lazy.nvim
fi

echo "${GREEN}Installation complete!${NC}"
echo "${YELLOW}Please restart your terminal or run: exec zsh${NC}"
echo "${YELLOW}Note: Make sure to set your terminal font to 'JetBrainsMono Nerd Font' for best appearance${NC}"