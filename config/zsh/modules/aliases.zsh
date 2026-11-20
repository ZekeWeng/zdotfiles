# Aliases for the shell.

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# eza
if command -v eza >/dev/null 2>&1; then
    alias l="eza --group-directories-first --git"
    alias la="eza --group-directories-first --git -a"
    alias ll="eza --group-directories-first --git -l"
    alias lt="eza --group-directories-first --git --tree --level=2"
    alias tree="eza --group-directories-first --git --tree"
fi

# Git

## Core
alias g="git"
alias ga="git add"
alias gp="git push"
alias gpl="git pull"
alias gcm="git commit -m"

## Status
alias gs="git status"
alias gss="git status -s"
alias gd="git diff"
alias gds="git diff --staged"

## Branch
alias gb="git branch --sort=-refname"
alias gbd="git branch -d"
alias gcb="git checkout -b"
alias gsw="git switch"
alias gswm="git switch main"

## Rebase
alias gr="git rebase"
alias gra="git rebase --abort"
alias grc="git rebase --continue"

## Log
alias gl="git log --oneline --graph --decorate"
alias gla="git log --oneline --graph --all --decorate"

## Stash
alias gst="git stash"
alias gstp="git stash pop"

# System
alias reload="exec zsh -l"
alias df="df -h"
alias du="du -h"
alias path='print -l $path'
alias mkdir="mkdir -pv"

## Safety
# Ask before overwrite or delete. Agent shells skip this, because no person can answer.
# Claude Code, Codex, Cursor, and Pi each set one or more of these variables.
zdot_agent="${AI_AGENT:-}${CLAUDECODE:-}${CODEX_THREAD_ID:-}${CODEX_SANDBOX:-}${CURSOR_AGENT:-}${PI_CODING_AGENT:-}"
if [ -t 0 ] && [ -z "$zdot_agent" ]; then
    alias cp="cp -iv"
    alias mv="mv -iv"
    alias rm="rm -iv"
fi
unset zdot_agent

# SSH
# "csh zw" opens a cmux SSH workspace. Each split in it is a new shell on the host.
# cmux keeps the shells on the host after a disconnect, and it attaches to them again.
# This alias hides the C shell /bin/csh in interactive zsh. "command csh" starts the C shell.
alias csh="cmux ssh"
# "tsh zw" shows the tmux sessions of the host as cmux workspaces. Each tmux pane is a cmux split.
# The programs continue when the laptop turns off. It needs the "Remote tmux" beta setting of cmux.
alias tsh="cmux ssh-tmux"

# End a cmux SSH workspace: close its sessions on the host, then close the workspace.
# "sshkill zw" or "sshkill workspace:7" ends the workspaces that match. "sshkill" ends each SSH workspace.
sshkill() {
    local ws
    local -a targets
    # Print the ref of each SSH workspace whose host or ref is an argument. With no arguments, print each one.
    local find_ssh='.workspaces[] | select(.remote.destination != null)
        | select($ARGS.positional == [] or ([.ref, .remote.destination] - $ARGS.positional | length) < 2)
        | .ref'
    targets=(${(f)"$(CMUX_QUIET=1 cmux workspace list --json | jq -r "$find_ssh" --args "$@")"})
    if [ "${#targets[@]}" -eq 0 ]; then
        echo "sshkill: no SSH workspace matches${1:+ $*}" >&2
        return 1
    fi
    for ws in "${targets[@]}"; do
        cmux ssh-session-cleanup --workspace "$ws" --all
        cmux workspace close "$ws"
    done
}

# Secrets
# No shell exports a token. Each read asks you for a password, so a command that an agent runs cannot read a token.
# macOS: each token is an item in the login Keychain, with the service "zdot".
# The item has no trusted apps and no partition, so each read asks for the login password.
# In the dialog, click Allow. "Always Allow" removes this protection.
# Linux: each token is a file in ~/.config/zsh/private/age, encrypted by age with a passphrase.
# Each read asks for the passphrase on the terminal. Use the same passphrase for each token.
# Print "keychain" or "age". The command name in $1 is for the error message.
zdot_secret_store() {
    if command -v security >/dev/null 2>&1; then
        echo keychain
    elif command -v age >/dev/null 2>&1; then
        echo age
    else
        echo "$1: this computer has no macOS Keychain and no age. Install age with Homebrew." >&2
        return 1
    fi
}
# Print the age file of the token named $2. The name must be a variable name, so that it cannot be a path.
zdot_secret_file() {
    case "$2" in
        "" | [!A-Za-z_]* | *[!A-Za-z0-9_]*)
            echo "$1: NAME must be a variable name, such as GITHUB_TOKEN." >&2
            return 2
            ;;
    esac
    printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/private/age/$2.age"
}
# "secret-set NAME" asks for the token, then for the password.
secret-set() {
    [ "$#" -eq 1 ] || { echo "usage: secret-set NAME" >&2; return 2; }
    local store file token
    store="$(zdot_secret_store secret-set)" || return
    if [ "$store" = keychain ]; then
        security add-generic-password -U -s zdot -a "$1" -T "" -w &&
            security set-generic-password-partition-list -S "" -s zdot -a "$1" >/dev/null
        return
    fi
    file="$(zdot_secret_file secret-set "$1")" || return
    printf 'Token for %s: ' "$1" >&2
    read -rs token
    echo >&2
    [ -n "$token" ] || { echo "secret-set: the token is empty." >&2; return 1; }
    # print is a builtin, so the token is not in the arguments of a process. umask 077 gives the file mode 600.
    if (umask 077 && command mkdir -p "${file:h}" && print -rn -- "$token" | age -p -o "$file.next"); then
        command mv -f "$file.next" "$file"
    else
        command rm -f "$file.next"
        return 1
    fi
}
# "secret NAME" prints the token.
secret() {
    [ "$#" -eq 1 ] || { echo "usage: secret NAME" >&2; return 2; }
    local store file
    store="$(zdot_secret_store secret)" || return
    if [ "$store" = keychain ]; then
        security find-generic-password -s zdot -a "$1" -w
        return
    fi
    file="$(zdot_secret_file secret "$1")" || return
    [ -f "$file" ] || { echo "secret: $1 does not exist. Run secret-set $1." >&2; return 1; }
    age -d "$file"
}
secret-rm() {
    [ "$#" -eq 1 ] || { echo "usage: secret-rm NAME" >&2; return 2; }
    local store file
    store="$(zdot_secret_store secret-rm)" || return
    if [ "$store" = keychain ]; then
        security delete-generic-password -s zdot -a "$1" >/dev/null
        return
    fi
    file="$(zdot_secret_file secret-rm "$1")" || return
    [ -f "$file" ] || { echo "secret-rm: $1 does not exist." >&2; return 1; }
    command rm -f -- "$file"
}
# The token lists: config/zsh/secrets.list, and config/zsh/companies/COMPANY/secrets.list if zdot_company is set.
# Each line is "NAME description". A line that starts with "#" is a comment.
zdot_secret_dir="${${(%):-%x}:A:h:h}"
# Print the lines of the token lists, with no comments and no empty lines.
zdot_secret_lists() {
    local list
    for list in "$zdot_secret_dir/secrets.list" "$zdot_secret_dir/companies/${zdot_company:-}/secrets.list"; do
        [ -f "$list" ] && grep -v '^[[:space:]]*\(#\|$\)' "$list"
    done
    return 0
}
# Succeed if the token named $1 is stored. It does not read the token, so it does not ask for a password.
zdot_secret_exists() {
    local store file
    store="$(zdot_secret_store secret-check)" || return
    if [ "$store" = keychain ]; then
        security find-generic-password -s zdot -a "$1" >/dev/null 2>&1
        return
    fi
    file="$(zdot_secret_file secret-check "$1")" && [ -f "$file" ]
}
# "secret-check" shows if each token in the lists is stored. It fails if a token is missing.
secret-check() {
    local line name missing=0
    for line in "${(@f)$(zdot_secret_lists)}"; do
        [ -n "$line" ] || continue
        name="${line%%[[:space:]]*}"
        if zdot_secret_exists "$name"; then
            echo "ok       $name"
        else
            echo "missing  $line"
            missing=1
        fi
    done
    return "$missing"
}
# "secret-setup" runs secret-set for each token in the lists that is missing.
secret-setup() {
    local line name
    for line in "${(@f)$(zdot_secret_lists)}"; do
        [ -n "$line" ] || continue
        name="${line%%[[:space:]]*}"
        zdot_secret_exists "$name" && continue
        echo "$line"
        secret-set "$name" || return
    done
    secret-check
}
# "with-secret GITHUB_TOKEN gh pr list" gives the token to one command as the variable GITHUB_TOKEN.
with-secret() {
    [ "$#" -ge 2 ] || { echo "usage: with-secret NAME COMMAND [ARGS...]" >&2; return 2; }
    local value
    value="$(secret "$1")" || return
    # Export the token in a subshell. "env NAME=TOKEN" puts the token in the arguments, which ps shows.
    (export "$1=$value" && "${@:2}")
}

# Utilities
alias c="clear"
alias h="history"
alias v="nvim"
alias vim="nvim"
alias ports="lsof -i -n -P | grep LISTEN"
alias myip="curl -s ifconfig.me"
