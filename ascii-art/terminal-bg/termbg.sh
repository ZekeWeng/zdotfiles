#!/bin/sh
# Switch the background design of the terminal.
# Usage: termbg.sh [list | next | weather [--test WEATHER_CODE] | NAME | off | overlay OVERLAY | update | names]
# list, or no argument, shows the mode now and the names of the backgrounds. The first mode is stars.
# weather makes the design follow the weather. The zsh module termbg updates it each hour.
# NAME sets one fixed background from backgrounds/ or weather/shaders/. Give the file name without .glsl.
# next moves to the next mode in the cycle: weather, stars, and each design in backgrounds/, in alphabetical order.
# off shows no design.
# overlay turns an overlay from overlays/ on or off, such as dog-leaf. An overlay shows over each mode.
# update writes the shader again for the mode now. --hourly skips it if the last hourly update is under 1 hour old.
# names prints each command, mode, and design on one line, for tab completion.
# The script writes $XDG_STATE_HOME/ghostty/termbg.glsl and reloads cmux.
# Ghostty has no reload command for scripts. Press Cmd+Shift+, in Ghostty to see a change.
set -eu

root="$(CDPATH='' cd -P -- "$(dirname -- "$(realpath -- "$0")")" && pwd -P)"
state="${XDG_STATE_HOME:-$HOME/.local/state}/ghostty"
out="$state/termbg.glsl"
mode_file="$state/termbg.mode"
overlays_file="$state/termbg.overlays"
stamp="$state/termbg.stamp"
weather_cache="$state/termbg.weather.glsl"
lock="$state/termbg.lock"
# Each run has its own temporary files, so that runs at the same time do not write into the same file.
tmp="$out.tmp.$$"
overlays_src="$overlays_file"
use_weather_cache=no

# Print the path of the background in $1. Return 1 if it does not exist.
find_bg() {
    for dir in backgrounds weather/shaders; do
        if [ -f "$root/$dir/$1.glsl" ]; then
            echo "$root/$dir/$1.glsl"
            return 0
        fi
    done
    return 1
}

# Write the shader that does not change the terminal to $tmp.
write_off() {
    cat >"$tmp" <<'EOF'
// No background design. The terminal shows with no change.
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);
}
EOF
}

# Draw the text of the shader in $tmp in the top-right corner, with text.glsl.
# A design names its text in a line such as "// @TEXT: NIGHT SKY". "|" starts a new line.
apply_text() {
    text="$(sed -n 's|^// @TEXT: ||p' "$tmp" | head -n 1)"
    [ -n "$text" ] || return 0
    # The ASCII codes of the text, as a GLSL array of 96 numbers, with 16 numbers on each line.
    array="$(printf '%s' "$text" | tr '|' '\n' | od -An -tu1 | awk '
        { for (i = 1; i <= NF; i++) codes[n++] = $i }
        END {
            printf "const int TEXT[96] = int[]("
            for (i = 0; i < 96; i++) {
                if (i % 16 == 0) printf "\n    "
                printf "%d%s", (i < n && i < 95 ? codes[i] : 0), (i < 95 ? ", " : "")
            }
            printf ");\n"
        }')"
    sed "s/void mainImage(/void textBgImage(/" "$tmp" >"$tmp.next"
    printf '%s\n' "$array" | awk -v f="$root/text.glsl" '
        { array = array $0 "\n" }
        END { while ((getline line < f) > 0) { if (line == "// @TEXT@") printf "%s", array; else print line } }
    ' >>"$tmp.next"
    mv "$tmp.next" "$tmp"
}

# Add each overlay that is on to the shader in $tmp.
# An overlay calls bgImage. Each overlay renames mainImage of the shader before it, so overlays can stack.
apply_overlays() {
    i=0
    for o in $(cat "$overlays_src" 2>/dev/null || true); do
        f="$root/overlays/$o.glsl"
        if [ ! -f "$f" ]; then
            echo "warning: there is no overlay named $o." >&2
            continue
        fi
        i=$((i + 1))
        sed "s/void mainImage(/void bgImage$i(/" "$tmp" >"$tmp.next"
        sed "s/bgImage(/bgImage$i(/" "$f" >>"$tmp.next"
        mv "$tmp.next" "$tmp"
    done
}

# Move $tmp to $out, and reload cmux if the shader changed.
# The move is atomic, so a terminal never reads a part of the shader.
install_shader() {
    if cmp -s "$tmp" "$out"; then
        rm -f "$tmp"
        return 0
    fi
    mv "$tmp" "$out"
    cmux="$(command -v cmux || echo /Applications/cmux.app/Contents/Resources/bin/cmux)"
    if [ -x "$cmux" ]; then
        "$cmux" reload-config >/dev/null || echo "warning: cmux did not reload. Run: cmux reload-config" >&2
    fi
}

# Write the shader for the mode in $1 to $tmp. The next arguments go to weather.sh.
build() {
    m="$1"
    shift
    case "$m" in
        off) write_off ;;
        weather)
            # An overlay change uses the last weather design, so it needs no network request.
            if [ "$use_weather_cache" = yes ] && [ -f "$weather_cache" ]; then
                cp "$weather_cache" "$tmp"
            elif "$root/weather/weather.sh" "$@" >"$tmp"; then
                cp "$tmp" "$weather_cache"
            else
                exit 1
            fi
            ;;
        *)
            if ! src="$(find_bg "$m")"; then
                echo "error: there is no background named $m. Run: termbg list" >&2
                exit 1
            fi
            cp "$src" "$tmp"
            ;;
    esac
}

# Write the full shader for the mode in $1 to $tmp: the shared helpers, the design, its text, and the overlays.
# The next arguments go to weather.sh.
compose() {
    build "$@"
    apply_text
    apply_overlays
    cat "$root/common.glsl" "$tmp" >"$tmp.next"
    mv "$tmp.next" "$tmp"
}

# Print the names of the .glsl files in the folders $1 and after, in alphabetical order.
shader_names() {
    for dir in "$@"; do
        for f in "$root/$dir"/*.glsl; do
            [ -f "$f" ] && basename "$f" .glsl
        done
    done | sort
}

# Print the modes in the cycle of next, in alphabetical order: weather, stars, and each design in backgrounds/.
cycle() {
    { echo weather && echo stars && shader_names backgrounds; } | sort
}

# Set the mode in $1, and write its shader. The next arguments go to weather.sh.
set_mode() {
    new="$1"
    shift
    compose "$new" "$@"
    echo "$new" >"$mode_file"
    install_shader
    echo "mode: $new"
}

# Wait up to 30 seconds for the lock, because the weather request can take 20 seconds.
# A lock that is older than 1 minute is from a run that stopped.
take_lock() {
    tries=0
    until mkdir "$lock" 2>/dev/null; do
        if [ -n "$(find "$lock" -maxdepth 0 -mmin +1 2>/dev/null)" ]; then
            rmdir "$lock" 2>/dev/null || true
            continue
        fi
        tries=$((tries + 1))
        if [ "$tries" -ge 300 ]; then
            echo "error: another termbg run holds $lock. If no termbg run is active, remove it." >&2
            exit 1
        fi
        sleep 0.1
    done
    trap 'rm -f "$tmp" "$tmp.next" "$overlays_file.next.$$"; rmdir "$lock" 2>/dev/null || true' EXIT
    trap 'exit 1' HUP INT TERM
}

mkdir -p "$state"
case "${1:-list}" in
    names | list) ;;
    *) take_lock ;;
esac
mode="$(cat "$mode_file" 2>/dev/null || echo stars)"

case "${1:-list}" in
    names)
        echo list next off overlay update weather
        shader_names backgrounds weather/shaders overlays
        ;;
    next)
        # The mode after the mode now. After the last mode, or from a mode outside the cycle, go to the first.
        new="$(cycle | awk -v m="$mode" '
            NR == 1 { first = $0 }
            found && !next_mode { next_mode = $0 }
            $0 == m { found = 1 }
            END { print (next_mode != "" ? next_mode : first) }')"
        set_mode "$new"
        ;;
    list)
        echo "mode: $mode"
        echo "modes: weather, off"
        echo "overlays on: $(tr '\n' ' ' 2>/dev/null <"$overlays_file" || true)"
        echo "overlays:"
        shader_names overlays | sed 's/^/    /'
        echo "backgrounds:"
        shader_names backgrounds weather/shaders | sed 's/^/    /'
        ;;
    update)
        if [ "${2:-}" = --hourly ]; then
            # Another shell possibly did the update while this run waited for the lock.
            if [ -n "$(find "$stamp" -mmin -60 2>/dev/null)" ]; then
                exit 0
            fi
            touch "$stamp"
            # Keep only the last 200 lines of the log. Write into the same file, because the zsh hook appends to it.
            log="$state/termbg.log"
            if [ -f "$log" ]; then
                tail -n 200 "$log" >"$log.$$"
                cat "$log.$$" >"$log"
                rm -f "$log.$$"
            fi
        fi
        compose "$mode"
        install_shader
        ;;
    overlay)
        name="${2:?error: give an overlay name. Run: termbg list}"
        if [ ! -f "$root/overlays/$name.glsl" ]; then
            echo "error: there is no overlay named $name. Run: termbg list" >&2
            exit 1
        fi
        # Write the new list to a temporary file. Save it only after the shader is installed.
        overlays_src="$overlays_file.next.$$"
        if grep -qx "$name" "$overlays_file" 2>/dev/null; then
            grep -vx "$name" "$overlays_file" >"$overlays_src" || true
            change="overlay off: $name"
        else
            {
                cat "$overlays_file" 2>/dev/null || true
                echo "$name"
            } >"$overlays_src"
            change="overlay on: $name"
        fi
        use_weather_cache=yes
        compose "$mode"
        install_shader
        mv "$overlays_src" "$overlays_file"
        echo "$change"
        ;;
    *) set_mode "$@" ;;
esac
