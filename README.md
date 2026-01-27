# macOS Dotfiles

Streamlined dotfiles configuration for macOS with Neovim, Ghostty, Homebrew, and essential development tools.

## Quick Start

```bash
# Install prerequisites
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Clone and install
git clone https://github.com/zekeweng/zdotfiles.git ~/.zdotfiles
cd ~/.zdotfiles
chmod +x install.sh
./install.sh
exec zsh
```

## What's Included

**Core Tools:**
- Neovim - Modern text editor with LSP support
- Ghostty - Fast native macOS terminal
- Homebrew - Package manager with Brewfile
- Zsh with Starship - Enhanced shell with modern prompt and Git integration
- Git - Version control with useful aliases
- Tmux - Terminal multiplexer

**CLI Tools (via Brewfile):**
- fzf, ripgrep, fd, bat, eza - Modern replacements for find, grep, ls
- lazygit, gh - Git workflow tools
- Node.js, Bun, Python (uv), Go, Rust, Elixir - Development environments
- PostgreSQL, RabbitMQ, AWS CLI - Backend infrastructure
- Claude - Modern development and AI tools

## Installation

The `install.sh` script:
1. Creates symlinks for all config files
2. Installs Homebrew packages from Brewfile
3. Installs Starship prompt for enhanced shell styling
4. Sets up Neovim plugin manager (lazy.nvim)
5. Configures shell defaults

## Configuration

All configurations use symlinks, so editing files in `~/.zdotfiles/` immediately applies changes.

**Key locations:**
- Neovim: `~/.config/nvim` → `~/.zdotfiles/nvim/`
- Ghostty: `~/.config/ghostty` → `~/.zdotfiles/ghostty/`
- Zsh: `~/.zshrc` → `~/.zdotfiles/zsh/.zshrc`
- Git: `~/.gitconfig` → `~/.zdotfiles/git/.gitconfig`
- Tmux: `~/.tmux.conf` → `~/.zdotfiles/tmux/.tmux.conf`

## Package Management

```bash
# Install/update all packages
brew bundle --file=~/.zdotfiles/Brewfile

# Generate Brewfile from current setup
brew bundle dump --file=~/.zdotfiles/Brewfile --force

# Remove unlisted packages
brew bundle cleanup --file=~/.zdotfiles/Brewfile
```

## Maintenance

```bash
# Update everything
./scripts/update.sh

# Create backup before changes
./scripts/backup.sh

# Update individual components
brew update && brew upgrade
nvim --headless "+Lazy! sync" +qa
cd ~/.zdotfiles && git pull
```

## Customization

**Adding new configurations:**
1. Create config directory in `~/.zdotfiles/`
2. Add symlink to `install.sh`
3. Run `./install.sh`

**Syncing across machines:**
```bash
# Push changes
cd ~/.zdotfiles
git add . && git commit -m "Update configs" && git push

# Pull on new machine
cd ~/.zdotfiles && git pull && ./install.sh
```

## Troubleshooting

**Broken symlinks:**
```bash
find ~ -type l ! -exec test -e {} \; -delete
cd ~/.zdotfiles && ./install.sh
```

**Neovim issues:**
```bash
rm -rf ~/.local/share/nvim && nvim
```

**Homebrew issues:**
```bash
brew doctor
brew bundle --file=~/.zdotfiles/Brewfile --force
```

## License

MIT License - feel free to use and modify as needed.