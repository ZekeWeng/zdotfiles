#!/bin/sh
# Install the dotfiles: zsh, Ghostty, SSH, Starship, tmux, git, and Neovim.
# Usage: ./scripts/install-dotfiles.sh
# Fixed files: the script links each one. It does not replace a path that exists and points to a different target.
# Manual files: the script copies each example into the repo one time, and links the home path to it.
# Git ignores the manual files. The script does not change a manual file that exists.
set -eu
: "${HOME:?HOME must be set and must not be empty}"

src="$(CDPATH='' cd -P -- "$(dirname -- "$(realpath -- "$0")")/.." && pwd -P)"

# Link the target in $1 to the path in $2.
# A broken link that points into this repo is replaced, so that a file can move in the repo.
link() {
    if [ "$(readlink "$2" 2>/dev/null)" = "$1" ]; then
        echo "ok    $2"
        return
    fi
    if [ -L "$2" ] && [ ! -e "$2" ]; then
        case "$(readlink "$2")" in
            "$src"/*)
                rm -- "$2"
                ln -s "$1" "$2"
                echo "move  $2 -> $1"
                return
                ;;
        esac
    fi
    if [ -e "$2" ] || [ -L "$2" ]; then
        echo "skip  $2 (the path exists. Move it. Run the script again.)"
        return
    fi
    mkdir -p "$(dirname "$2")"
    ln -s "$1" "$2"
    echo "link  $2 -> $1"
}

# Copy the example in $1 to the manual file in $2 only if the manual file does not exist. Give it the mode in $3.
seed() {
    if [ -e "$2" ] || [ -L "$2" ]; then
        echo "keep  $2"
        return
    fi
    mkdir -p "$(dirname "$2")"
    cp "$1" "$2"
    chmod "$3" "$2"
    echo "copy  $2 (manual file: edit it for this computer)"
}

# Copy the example in $1 to the manual file $2 in the repo, with the mode in $3. Then link the home path in $4 to it.
manual() {
    seed "$1" "$2" "$3"
    link "$2" "$4"
}

# ssh refuses a config folder that other users can write to.
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Fixed files
link "$src/config/zsh/.zshenv" "$HOME/.zshenv"
link "$src/config/zsh/.zprofile" "$HOME/.zprofile"
link "$src/config/zsh/.zshrc" "$HOME/.zshrc"
link "$src/config/ghostty/config" "$HOME/.config/ghostty/config"
link "$src/config/ssh/config" "$HOME/.ssh/config"
link "$src/config/starship/starship.toml" "$HOME/.config/starship.toml"
link "$src/config/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
link "$src/config/git/config" "$HOME/.config/git/config"
link "$src/config/git/ignore" "$HOME/.config/git/ignore"
link "$src/config/nvim" "$HOME/.config/nvim"

# Manual files. The files that can hold secrets get mode 600.
manual "$src/config/zsh/local/zshenv.local.example" "$src/config/zsh/zshenv.local" 600 "$HOME/.zshenv.local"
manual "$src/config/zsh/local/zshrc.local.example" "$src/config/zsh/zshrc.local" 644 "$HOME/.zshrc.local"
manual "$src/config/ssh/config.local.example" "$src/config/ssh/config.local" 600 "$HOME/.ssh/config.local"
manual "$src/config/git/gitconfig.example" "$src/config/git/gitconfig.local" 600 "$HOME/.gitconfig"
manual "$src/brew/Brewfile.local.example" "$src/brew/Brewfile.local" 644 "$HOME/.config/brew/Brewfile.local"
manual "$src/config/ghostty/local.example" "$src/config/ghostty/local" 644 "$HOME/.config/ghostty/local"
manual "$src/config/tmux/local.conf.example" "$src/config/tmux/local.conf" 644 "$HOME/.config/tmux/local.conf"
seed "$src/config/zsh/paths/local.zsh.example" "$src/config/zsh/paths/local.zsh" 644
# The secrets stay outside the repo, so git cannot commit them.
# Move the secret files from the old folder in the repo, so that the shell loads them again.
mkdir -p "$HOME/.config/zsh/private"
chmod 700 "$HOME/.config/zsh/private"
for old_secrets in "$src"/config/zsh/private/*.zsh; do
    [ -f "$old_secrets" ] || continue
    new_secrets="$HOME/.config/zsh/private/$(basename "$old_secrets")"
    if [ -e "$new_secrets" ]; then
        echo "skip  $old_secrets ($new_secrets exists. Merge the two files. Delete the old file.)"
    else
        mv "$old_secrets" "$new_secrets"
        echo "move  $old_secrets -> $new_secrets"
    fi
done
seed "$src/config/zsh/local/secrets.example" "$HOME/.config/zsh/private/secrets.zsh" 600
