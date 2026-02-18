# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"

# List files
alias ls="eza --group-directories-first"
alias l="eza -la --group-directories-first"
alias la="eza -la --group-directories-first"
alias ll="eza -l --group-directories-first"
alias lt="eza --tree --level=2"
alias tree="eza --tree"

# Git
alias g="git"
alias ga="git add"
alias gaa="git add ."
alias gc="git commit"
alias gcm="git commit -m"
alias gca="git commit --amend"
alias gp="git push"
alias gpl="git pull"
alias gl="git log --oneline --graph --all"
alias gs="git status"
alias gss="git status -s"
alias gd="git diff"
alias gds="git diff --staged"
alias gb="git branch"
alias gbd="git branch -d"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gsw="git switch"
alias gm="git merge"
alias gr="git rebase"
alias grc="git rebase --continue"
alias gra="git rebase --abort"
alias glog="git log --oneline --graph --decorate"
alias gst="git stash"
alias gstp="git stash pop"
alias lg="lazygit"

# System
alias reload="exec zsh"
alias path='echo $PATH | tr ":" "\n"'
alias cat="bat"
alias grep="rg"
alias find="fd"
alias df="df -h"
alias du="du -h"
alias mkdir="mkdir -pv"
alias cp="cp -iv"
alias mv="mv -iv"
alias rm="rm -iv"

# Directories
alias dl="cd ~/Downloads"
alias dt="cd ~/Desktop"
alias docs="cd ~/Documents"
alias dev="cd ~/Developer"

# Utilities
alias c="clear"
alias h="history"
alias j="jobs"
alias v="nvim"
alias vim="nvim"
alias e="nvim"
alias ports="lsof -i -n -P | grep LISTEN"
alias myip="curl -s ifconfig.me"
alias week="date +%V"

# Claude
cc() {
  cp ~/.zdotfiles/claude-config.tar.gz . && tar xzf claude-config.tar.gz && rm claude-config.tar.gz
  echo "Claude config initialized in $(pwd)"
}

# Applications
alias cursor='open -a Cursor'