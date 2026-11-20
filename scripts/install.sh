#!/bin/sh
# Set up this computer on macOS or Linux: the dotfiles, the Homebrew packages, the login shell, and the agents.
# Usage: ./scripts/install.sh
# You can run the script again. Each step skips the work that is done.
# The script does not install Homebrew or Claude Code. It prints their install commands.
# On Linux, if chsh cannot change the login shell, the script adds a block to ~/.bashrc that starts zsh.
set -eu
: "${HOME:?HOME must be set and must not be empty}"

src="$(CDPATH='' cd -P -- "$(dirname -- "$(realpath -- "$0")")/.." && pwd -P)"
bashrc="$HOME/.bashrc"
bashrc_marker="# zdotfiles: start zsh."

case "$(uname -s)" in
    Darwin) os=macos ;;
    Linux) os=linux ;;
    *)
        echo "error: zdotfiles supports only macOS and Linux." >&2
        exit 1
        ;;
esac

step() { printf '\n==> %s\n' "$1"; }

step "Homebrew ($os)"
# A new terminal can have no brew in PATH. These are the folders of paths.zsh.
if ! command -v brew >/dev/null 2>&1; then
    for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
        if [ -x "$brew_bin" ]; then
            PATH="$(dirname "$brew_bin"):$PATH"
            break
        fi
    done
fi
if ! command -v brew >/dev/null 2>&1; then
    echo "error: Homebrew is not installed. Install it with this command:" >&2
    # The script prints this command. It does not run it.
    # shellcheck disable=SC2016
    echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' >&2
    if [ "$os" = linux ]; then
        echo "On Linux, install the packages that Homebrew needs first. See https://docs.brew.sh/Homebrew-on-Linux" >&2
    fi
    echo "Then open a new terminal. Run this script again." >&2
    exit 1
fi
echo "ok    $(command -v brew)"

step "Dotfiles"
"$src/scripts/install-dotfiles.sh"

step "Homebrew packages"
"$src/scripts/install-brew.sh"

step "Login shell"
# Print the login shell of the user from the user database. Print $SHELL if the database has no entry.
login_shell() {
    user="$(id -un)"
    case "$os" in
        macos) found="$(dscl . -read "/Users/$user" UserShell 2>/dev/null | sed -n 's/^UserShell: //p')" ;;
        linux) found="$(getent passwd "$user" 2>/dev/null | cut -d: -f7)" ;;
    esac
    echo "${found:-${SHELL:-}}"
}

# Change the login shell to the zsh in $1 with chsh. Return 1 if chsh cannot change it.
# chsh accepts only a shell in /etc/shells, and it asks for the password, so it needs a terminal.
try_chsh() {
    grep -qxF -- "$1" /etc/shells 2>/dev/null || return 1
    [ -t 0 ] || return 1
    chsh -s "$1"
}

# Add the block that starts the zsh in $1 to the end of ~/.bashrc.
# The block starts zsh only in an interactive terminal. Editors run "bash -c CMD" to read the environment,
# so that form keeps bash.
add_bashrc_block() {
    cat >>"$bashrc" <<EOF

$bashrc_marker scripts/install.sh added this block. Run "ZDOT_BASH=1 bash" to get bash.
if [[ \$- == *i* ]] && [ -z "\${ZDOT_BASH:-}" ] && [ -z "\${BASH_EXECUTION_STRING:-}" ] &&
    [ -t 0 ] && [ -t 1 ] && [ -x "$1" ]; then
    export SHELL="$1"
    exec "\$SHELL" -l
fi
EOF
}

# macOS has zsh in /bin, and /etc/shells has it. On Linux, the zsh comes from Homebrew.
if [ "$os" = macos ]; then
    zsh_bin=/bin/zsh
else
    zsh_bin="$(command -v zsh || true)"
fi
current_shell="$(login_shell)"
if [ -z "$zsh_bin" ]; then
    echo "error: zsh is not installed. brew/shell.Brewfile installs it. Run this script again." >&2
    exit 1
elif [ "${current_shell##*/}" = zsh ]; then
    echo "ok    $current_shell"
elif [ -f "$bashrc" ] && grep -qF -- "$bashrc_marker" "$bashrc"; then
    echo "ok    $bashrc starts zsh"
elif try_chsh "$zsh_bin"; then
    echo "chsh  $zsh_bin (open a new terminal)"
elif [ "$os" = linux ] && [ "${current_shell##*/}" = bash ]; then
    add_bashrc_block "$zsh_bin"
    echo "write $bashrc (it starts $zsh_bin, because chsh cannot change the login shell)"
else
    echo "skip  login shell $current_shell (chsh cannot change it. Run: chsh -s $zsh_bin)"
fi

step "Claude Code"
if command -v claude >/dev/null 2>&1 || [ -x "$HOME/.local/bin/claude" ]; then
    echo "ok    claude"
else
    echo "skip  claude (it is not installed. Install it with: curl -fsSL https://claude.ai/install.sh | bash)"
    echo "      Then run ./agents/install-agents.sh again, so that Claude Code gets the skills."
fi

step "Agents"
"$src/agents/install-agents.sh"

step "Done"
echo "Open a new terminal, so that the shell loads the new config."
if [ "$os" = macos ]; then
    echo "Put each token in the Keychain with: secret-set NAME"
else
    echo "Put each token in ~/.config/zsh/private/secrets.zsh. Linux has no Keychain."
fi
