#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
BACKUP_DIR="$HOME/.zdotfiles_backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_PATH="$BACKUP_DIR/backup_$TIMESTAMP"

echo "${GREEN}Creating backup of current dotfiles...${NC}"

# Create backup directory
mkdir -p "$BACKUP_PATH"

# Files to backup
declare -a files=(
    ".zshrc"
    ".zshenv"
    ".gitconfig"
    ".gitignore_global"
    ".tmux.conf"
)

# Directories to backup
declare -a dirs=(
    ".config/nvim"
    ".config/ghostty"
)

# Backup files
echo "${YELLOW}Backing up files...${NC}"
for file in "${files[@]}"; do
    if [[ -f "$HOME/$file" ]]; then
        cp "$HOME/$file" "$BACKUP_PATH/"
        echo "✓ Backed up $file"
    fi
done

# Backup directories
echo "${YELLOW}Backing up directories...${NC}"
for dir in "${dirs[@]}"; do
    if [[ -d "$HOME/$dir" ]]; then
        mkdir -p "$BACKUP_PATH/$(dirname "$dir")"
        cp -r "$HOME/$dir" "$BACKUP_PATH/$dir"
        echo "✓ Backed up $dir"
    fi
done

# Create restore script
cat > "$BACKUP_PATH/restore.sh" << 'EOF'
#!/bin/bash

set -e

BACKUP_DIR=$(dirname "$0")

echo "Restoring dotfiles from backup..."

# Restore files
for file in .zshrc .zshenv .gitconfig .gitignore_global .tmux.conf; do
    if [[ -f "$BACKUP_DIR/$file" ]]; then
        cp "$BACKUP_DIR/$file" "$HOME/"
        echo "✓ Restored $file"
    fi
done

# Restore directories
if [[ -d "$BACKUP_DIR/.config/nvim" ]]; then
    mkdir -p "$HOME/.config"
    cp -r "$BACKUP_DIR/.config/nvim" "$HOME/.config/"
    echo "✓ Restored .config/nvim"
fi

if [[ -d "$BACKUP_DIR/.config/ghostty" ]]; then
    mkdir -p "$HOME/.config"
    cp -r "$BACKUP_DIR/.config/ghostty" "$HOME/.config/"
    echo "✓ Restored .config/ghostty"
fi

echo "Restore complete!"
EOF

chmod +x "$BACKUP_PATH/restore.sh"

echo "${GREEN}Backup complete!${NC}"
echo "${YELLOW}Backup location: $BACKUP_PATH${NC}"
echo "${YELLOW}To restore: $BACKUP_PATH/restore.sh${NC}"

# Clean up old backups (keep last 5)
echo "${YELLOW}Cleaning up old backups...${NC}"
if [[ -d "$BACKUP_DIR" ]]; then
    cd "$BACKUP_DIR"
    ls -dt backup_* | tail -n +6 | xargs rm -rf 2>/dev/null || true
fi

echo "${GREEN}Done!${NC}"