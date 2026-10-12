# Update the Ghostty background design from the weather.

# config/ghostty/weather.sh writes the shader. This hook runs it in the background once each hour.
# A zsh hook runs it, not launchd, because macOS stops launchd jobs from reading files in ~/Desktop.
# The hook runs only when ~/.config/ghostty/local uses the weather shader.
if grep -q 'weather\.glsl' "$HOME/.config/ghostty/local" 2>/dev/null; then
    zdot_weather_script="${${(%):-%x}:A:h:h:h}/ghostty/weather.sh"
    zdot_weather_dir="${XDG_STATE_HOME:-$HOME/.local/state}/ghostty"

    _zdot_weather_precmd() {
        local stamp="$zdot_weather_dir/weather.stamp"
        # (N) gives no error for a missing file. (mh+0) matches a file that is 1 hour old or older.
        local old=($stamp(Nmh+0))
        if [[ -f $stamp && ${#old} -eq 0 ]]; then
            return
        fi
        # Touch the stamp first, so that other shells do not also start a request.
        mkdir -p "$zdot_weather_dir"
        touch "$stamp"
        "$zdot_weather_script" >>"$zdot_weather_dir/weather.log" 2>&1 &!
    }

    autoload -Uz add-zsh-hook
    add-zsh-hook precmd _zdot_weather_precmd
fi
