# The termbg command, and the hourly update of the weather background.

# ascii-art/terminal-bg/termbg.sh switches the background design of the terminal.
zdot_termbg_script="${${(%):-%x}:A:h:h:h:h}/ascii-art/terminal-bg/termbg.sh"
zdot_termbg_dir="${XDG_STATE_HOME:-$HOME/.local/state}/ghostty"

termbg() {
    "$zdot_termbg_script" "$@"
}
# tbg is a short name, for example: tbg next, tbg weather, tbg sovereign.
alias tbg=termbg

# Tab completion shows the commands, the modes, and the designs.
_termbg() {
    compadd -- ${(f)"$("$zdot_termbg_script" names | tr ' ' '\n')"}
}
if (( $+functions[compdef] )); then
    compdef _termbg termbg
fi

# In weather mode, the hook updates the design in the background once each hour.
# A zsh hook runs it, not launchd, because macOS stops launchd jobs from reading files in ~/Desktop.
_zdot_termbg_precmd() {
    [[ "$(<"$zdot_termbg_dir/termbg.mode" 2>/dev/null)" == weather ]] || return
    local stamp="$zdot_termbg_dir/termbg.stamp"
    # (N) gives no error for a missing file. (mh+0) matches a file that is 1 hour old or older.
    local old=($stamp(Nmh+0))
    if [[ -f $stamp && ${#old} -eq 0 ]]; then
        return
    fi
    # Touch the stamp first, so that other shells do not also start a request.
    touch "$stamp"
    "$zdot_termbg_script" update >>"$zdot_termbg_dir/termbg.log" 2>&1 &!
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _zdot_termbg_precmd
