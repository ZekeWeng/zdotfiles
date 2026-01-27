# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"

# List files
alias ls="eza --group-directories-first"
alias la="eza -la --group-directories-first"
alias ll="eza -l --group-directories-first"
alias tree="eza --tree"

# Git
alias g="git"
alias ga="git add"
alias gaa="git add ."
alias gc="git commit"
alias gcm="git commit -m"
alias gp="git push"
alias gl="git pull"
alias gs="git status"
alias gd="git diff"
alias gb="git branch"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gm="git merge"
alias gr="git rebase"
alias lg="lazygit"

# System
alias reload="exec zsh"
alias path='echo $PATH | tr ":" "\n"'
alias cat="bat"
alias grep="rg"
alias find="fd"

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

# Applications
alias cursor='open -a Cursor'