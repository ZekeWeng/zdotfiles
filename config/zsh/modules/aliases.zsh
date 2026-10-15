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

# Utilities
alias c="clear"
alias h="history"
alias v="nvim"
alias vim="nvim"
alias ports="lsof -i -n -P | grep LISTEN"
alias myip="curl -s ifconfig.me"
