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
# In a cmux terminal, "ssh HOST" opens a cmux SSH workspace.
# A daemon on the host keeps the shell alive after a disconnect.
# Each other form of ssh runs the usual ssh. Examples are "ssh HOST CMD", "ssh -p 22 HOST", and "cmd | ssh HOST".
ssh() {
    if [ -n "${CMUX_WORKSPACE_ID:-}" ] && [ -t 0 ] && [ -t 1 ] && [ "$#" -eq 1 ] && [ "${1#-}" = "$1" ] &&
        command -v cmux >/dev/null 2>&1; then
        cmux ssh "$1"
    else
        command ssh "$@"
    fi
}

# Utilities
alias c="clear"
alias h="history"
alias v="nvim"
alias vim="nvim"
alias ports="lsof -i -n -P | grep LISTEN"
alias myip="curl -s ifconfig.me"
