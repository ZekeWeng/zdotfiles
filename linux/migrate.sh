#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Starting Linux migration...${NC}"

# Detect package manager
if command -v apt-get &> /dev/null; then
    PKG_MANAGER="apt"
    PKG_INSTALL="sudo apt-get install -y"
    PKG_UPDATE="sudo apt-get update"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    PKG_INSTALL="sudo dnf install -y"
    PKG_UPDATE="sudo dnf check-update || true"
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
    PKG_INSTALL="sudo pacman -S --noconfirm"
    PKG_UPDATE="sudo pacman -Sy"
else
    echo -e "${RED}No supported package manager found (apt, dnf, pacman).${NC}"
    exit 1
fi

echo -e "${YELLOW}Detected package manager: ${PKG_MANAGER}${NC}"
echo -e "${YELLOW}Updating package lists...${NC}"
$PKG_UPDATE

# Install essential tools
echo -e "${YELLOW}Installing essential packages...${NC}"

install_packages() {
    case $PKG_MANAGER in
        apt)
            $PKG_INSTALL \
                neovim git zsh tmux fzf ripgrep fd-find bat \
                nodejs npm python3 python3-pip python3-venv \
                golang rustc cargo elixir \
                postgresql rabbitmq-server awscli \
                xclip curl wget unzip fontconfig
            # fd and bat have different binary names on Debian/Ubuntu
            if ! command -v fd &> /dev/null && command -v fdfind &> /dev/null; then
                sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
            fi
            if ! command -v bat &> /dev/null && command -v batcat &> /dev/null; then
                sudo ln -sf "$(which batcat)" /usr/local/bin/bat
            fi
            ;;
        dnf)
            $PKG_INSTALL \
                neovim git zsh tmux fzf ripgrep fd-find bat \
                nodejs python3 python3-pip \
                golang rust cargo elixir \
                postgresql-server rabbitmq-server awscli \
                xclip curl wget unzip fontconfig
            ;;
        pacman)
            $PKG_INSTALL \
                neovim git zsh tmux fzf ripgrep fd bat \
                nodejs npm python python-pip \
                go rust elixir \
                postgresql rabbitmq aws-cli-v2 \
                xclip curl wget unzip fontconfig
            ;;
    esac
}

install_packages

# Install eza (not in most default repos)
if ! command -v eza &> /dev/null; then
    echo -e "${YELLOW}Installing eza...${NC}"
    case $PKG_MANAGER in
        apt)
            sudo mkdir -p /etc/apt/keyrings
            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
            sudo apt-get update && sudo apt-get install -y eza
            ;;
        dnf)
            sudo dnf install -y eza
            ;;
        pacman)
            sudo pacman -S --noconfirm eza
            ;;
    esac
fi

# Install lazygit
if ! command -v lazygit &> /dev/null; then
    echo -e "${YELLOW}Installing lazygit...${NC}"
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
    sudo install /tmp/lazygit /usr/local/bin
    rm -f /tmp/lazygit /tmp/lazygit.tar.gz
fi

# Install GitHub CLI
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}Installing GitHub CLI...${NC}"
    case $PKG_MANAGER in
        apt)
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli-stable.list > /dev/null
            sudo apt-get update && sudo apt-get install -y gh
            ;;
        dnf)
            sudo dnf install -y gh
            ;;
        pacman)
            sudo pacman -S --noconfirm github-cli
            ;;
    esac
fi

# Install starship prompt
if ! command -v starship &> /dev/null; then
    echo -e "${YELLOW}Installing starship prompt...${NC}"
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Install uv (Python package manager)
if ! command -v uv &> /dev/null; then
    echo -e "${YELLOW}Installing uv...${NC}"
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Install Nerd Fonts
echo -e "${YELLOW}Installing Nerd Fonts...${NC}"
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

for font in JetBrainsMono FiraCode; do
    if ! ls "$FONT_DIR"/${font}* &> /dev/null; then
        echo -e "${YELLOW}Installing ${font} Nerd Font...${NC}"
        curl -Lo /tmp/${font}.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
        unzip -o /tmp/${font}.zip -d "$FONT_DIR"
        rm -f /tmp/${font}.zip
    fi
done
fc-cache -fv

# Replace pbcopy/pbpaste with xclip aliases in zsh
echo -e "${YELLOW}Setting up clipboard aliases for Linux...${NC}"
LINUX_ZSH_DIR="$HOME/.zdotfiles/linux"
mkdir -p "$LINUX_ZSH_DIR"

cat > "$LINUX_ZSH_DIR/linux.zsh" << 'ZSHEOF'
# Linux-specific shell configuration

# Clipboard support (replaces macOS pbcopy/pbpaste)
if command -v xclip &> /dev/null; then
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
fi

# Use xdg-open instead of macOS open
alias open='xdg-open'
ZSHEOF

# Set zsh as default shell if it isn't already
if [ "$SHELL" != "$(which zsh)" ]; then
    echo -e "${YELLOW}Setting zsh as default shell...${NC}"
    chsh -s "$(which zsh)"
fi

echo -e "${GREEN}Linux migration complete!${NC}"
