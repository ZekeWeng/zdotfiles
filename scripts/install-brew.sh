#!/bin/sh
# Install the Homebrew packages: the groups in brew/, then ~/.config/brew/Brewfile.local if it exists.
# Usage: ./scripts/install-brew.sh [GROUP...]
# GROUP is shell, tools, languages, or apps. With no GROUP, the script installs each group and the local file.
# The script asks y/n for each cask that is not installed.
# It installs the formulas and the installed casks with no question.
# If the input is not a terminal, the script installs all casks with no question.
# The script does not uninstall or upgrade packages. Run "brew upgrade" to upgrade them.
set -eu
: "${HOME:?HOME must be set and must not be empty}"

# Use the real folder, so that the paths stay correct when you run the script through a symlink.
src="$(CDPATH='' cd -P -- "$(dirname -- "$(realpath -- "$0")")/.." && pwd -P)"
local_brewfile="$HOME/.config/brew/Brewfile.local"
all_groups="shell tools languages apps"
groups="${*:-$all_groups}"

# Stop before any install if a group does not exist.
for group in $groups; do
    case "$group" in
        "" | *[!a-z]*) group_ok=false ;;
        *) if [ -f "$src/brew/$group.Brewfile" ]; then group_ok=true; else group_ok=false; fi ;;
    esac
    if [ "$group_ok" = false ]; then
        echo "error: the group $group does not exist. Use one or more of: $all_groups." >&2
        exit 1
    fi
done

if ! command -v brew >/dev/null 2>&1; then
    echo "error: Homebrew is not installed. Install it with the command from https://brew.sh:" >&2
    # The script prints this command. It does not run it.
    # shellcheck disable=SC2016
    echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' >&2
    echo "Then open a new terminal. Run this script again." >&2
    exit 1
fi

installed_casks="$(brew list --cask -1 2>/dev/null || true)"
# POSIX has no mktemp. mkdir fails if the folder exists, so no other process can own it.
tmp_dir="${TMPDIR:-/tmp}/zdot-brew.$$"
(umask 077 && mkdir "$tmp_dir")
trap 'rm -rf "$tmp_dir"' EXIT

if [ ! -t 0 ]; then
    echo "note  The input is not a terminal. The script installs all casks with no question."
fi

# Ask y/n about the cask in $1. Return 0 for yes, and 1 for no.
ask_cask() {
    while true; do
        printf 'Install the cask %s? [Y/n] ' "$1"
        read -r answer || exit 1
        case "$answer" in
            "" | [Yy] | [Yy][Ee][Ss]) return 0 ;;
            [Nn] | [Nn][Oo]) return 1 ;;
            *) echo "Type y or n." ;;
        esac
    done
}

# Copy the Brewfile in $1 to $2. Remove each cask that is not installed and that you decline.
select_casks() {
    : >"$2"
    while IFS= read -r line <&3 || [ -n "$line" ]; do
        name="$(printf '%s\n' "$line" | sed -n 's/^[[:space:]]*cask[[:space:]][[:space:]]*"\([^"]*\)".*/\1/p')"
        if [ -t 0 ] && [ -n "$name" ]; then
            # brew list shows the short name of a cask from a tap, so remove the tap prefix.
            name="${name##*/}"
            if ! printf '%s\n' "$installed_casks" | grep -qxF -- "$name" && ! ask_cask "$name"; then
                echo "skip  $name"
                continue
            fi
        fi
        printf '%s\n' "$line" >>"$2"
    done 3<"$1"
}

# Ask all the questions first, so that the installs do not stop for an answer.
: >"$tmp_dir/Brewfile"
for group in $groups; do
    select_casks "$src/brew/$group.Brewfile" "$tmp_dir/$group.Brewfile"
    cat "$tmp_dir/$group.Brewfile" >>"$tmp_dir/Brewfile"
done
if [ "$#" -gt 0 ]; then
    echo "skip  $local_brewfile (you named the groups to install)"
elif [ -f "$local_brewfile" ]; then
    select_casks "$local_brewfile" "$tmp_dir/Brewfile.local"
else
    echo "skip  $local_brewfile (the file does not exist)"
fi

brew bundle --no-upgrade --file "$tmp_dir/Brewfile"
if [ -f "$tmp_dir/Brewfile.local" ]; then
    brew bundle --no-upgrade --file "$tmp_dir/Brewfile.local"
fi
