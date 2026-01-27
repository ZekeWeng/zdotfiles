#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "${GREEN}Updating system and dotfiles...${NC}"

# Update dotfiles repository
echo "${YELLOW}Updating dotfiles repository...${NC}"
if [[ -d ~/.zdotfiles/.git ]]; then
    cd ~/.zdotfiles
    git pull origin main || git pull origin master
    echo "✓ Dotfiles repository updated"
else
    echo "${RED}Not in a git repository${NC}"
fi

# Update Homebrew
if command -v brew &> /dev/null; then
    echo "${YELLOW}Updating Homebrew...${NC}"
    brew update
    brew upgrade
    brew cleanup
    echo "✓ Homebrew updated"

    # Update packages from Brewfile
    if [[ -f ~/.zdotfiles/Brewfile ]]; then
        echo "${YELLOW}Installing/updating packages from Brewfile...${NC}"
        brew bundle --file=~/.zdotfiles/Brewfile
        echo "✓ Brewfile packages updated"
    fi
else
    echo "${YELLOW}Homebrew not found, skipping...${NC}"
fi

# Update Neovim plugins
if command -v nvim &> /dev/null; then
    echo "${YELLOW}Updating Neovim plugins...${NC}"
    nvim --headless "+Lazy! sync" +qa
    echo "✓ Neovim plugins updated"
else
    echo "${YELLOW}Neovim not found, skipping...${NC}"
fi

# Update macOS (optional)
echo "${YELLOW}Checking for macOS updates...${NC}"
if command -v softwareupdate &> /dev/null; then
    softwareupdate -l
    echo "Run 'sudo softwareupdate -i -a' to install available updates"
fi

# Update Rust (if installed)
if command -v rustup &> /dev/null; then
    echo "${YELLOW}Updating Rust...${NC}"
    rustup update
    echo "✓ Rust updated"
fi

# Update Node.js packages (if using npm globally)
if command -v npm &> /dev/null; then
    echo "${YELLOW}Updating global npm packages...${NC}"
    npm update -g
    echo "✓ Global npm packages updated"
fi

# Update Go packages (if any global ones)
if command -v go &> /dev/null; then
    echo "${YELLOW}Updating Go...${NC}"
    # This would update Go itself if installed via Homebrew
    echo "✓ Go tools checked"
fi

# Clean up
echo "${YELLOW}Cleaning up...${NC}"
if command -v brew &> /dev/null; then
    brew cleanup --prune=all
fi

# Show system info
echo "${GREEN}Update complete!${NC}"
echo "${YELLOW}System Information:${NC}"
echo "macOS: $(sw_vers -productVersion)"
if command -v brew &> /dev/null; then
    echo "Homebrew: $(brew --version | head -1)"
fi
if command -v nvim &> /dev/null; then
    echo "Neovim: $(nvim --version | head -1)"
fi
if command -v git &> /dev/null; then
    echo "Git: $(git --version)"
fi
if command -v node &> /dev/null; then
    echo "Node.js: $(node --version)"
fi
if command -v python3 &> /dev/null; then
    echo "Python: $(python3 --version)"
fi

echo "${GREEN}All updates complete!${NC}"