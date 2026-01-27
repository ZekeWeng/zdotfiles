# Create directory and change into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract archives
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1" ;;
            *.tar.gz) tar xzf "$1" ;;
            *.bz2) bunzip2 "$1" ;;
            *.rar) unrar e "$1" ;;
            *.gz) gunzip "$1" ;;
            *.tar) tar xf "$1" ;;
            *.tbz2) tar xjf "$1" ;;
            *.tgz) tar xzf "$1" ;;
            *.zip) unzip "$1" ;;
            *.Z) uncompress "$1" ;;
            *.7z) 7z x "$1" ;;
            *) echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Find files
ff() {
    fd "$1" . | head -20
}

# Find and edit file
fe() {
    local file
    file=$(fd --type f | fzf) && nvim "$file"
}

# Change directory with fzf
cdf() {
    local dir
    dir=$(fd --type d | fzf) && cd "$dir"
}

# Git branch switch with fzf
gbs() {
    local branch
    branch=$(git branch | fzf | sed 's/^[* ]*//')
    [[ -n "$branch" ]] && git checkout "$branch"
}

# Kill process with fzf
fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
    [[ -n "$pid" ]] && echo "$pid" | xargs kill -"${1:-9}"
}

# Weather
weather() {
    curl -s "wttr.in/${1:-}"
}

# Show disk usage
usage() {
    du -h -d1 | sort -hr
}