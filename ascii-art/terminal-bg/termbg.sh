#!/bin/sh
# Switch the background design of the terminal.
# Usage: termbg.sh [list | next | weather [--test WEATHER_CODE] | NAME | off | overlay OVERLAY | update | names]
# list, or no argument, shows the mode now and the names of the backgrounds. The first mode is stars.
# weather makes the design follow the weather. The zsh module termbg updates it each hour.
# NAME sets one fixed background from backgrounds/ or weather/shaders/. Give the file name without .glsl.
# next moves to the next mode in the cycle: weather, stars, and each design in backgrounds/, in alphabetical order.
# off shows no design.
# overlay turns an overlay from overlays/ on or off, such as dog-leaf. An overlay shows over each mode.
# update writes the shader again for the mode now. The zsh module uses it.
# names prints each command, mode, and design on one line, for tab completion.
# The script writes $XDG_STATE_HOME/ghostty/termbg.glsl and reloads cmux.
# Ghostty has no reload command for scripts. Press Cmd+Shift+, in Ghostty to see a change.
set -eu

root="$(cd "$(dirname "$0")" && pwd)"
state="${XDG_STATE_HOME:-$HOME/.local/state}/ghostty"
out="$state/termbg.glsl"
mode_file="$state/termbg.mode"
overlays_file="$state/termbg.overlays"
tmp="$out.tmp"

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
    for o in $(cat "$overlays_file" 2>/dev/null || true); do
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
            if ! "$root/weather/weather.sh" "$@" >"$tmp"; then
                rm -f "$tmp"
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

mkdir -p "$state"
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
        compose "$mode"
        install_shader
        ;;
    overlay)
        name="${2:?error: give an overlay name. Run: termbg list}"
        if [ ! -f "$root/overlays/$name.glsl" ]; then
            echo "error: there is no overlay named $name. Run: termbg list" >&2
            exit 1
        fi
        if grep -qx "$name" "$overlays_file" 2>/dev/null; then
            grep -vx "$name" "$overlays_file" >"$overlays_file.next" || true
            mv "$overlays_file.next" "$overlays_file"
            echo "overlay off: $name"
        else
            echo "$name" >>"$overlays_file"
            echo "overlay on: $name"
        fi
        compose "$mode"
        install_shader
        ;;
    *) set_mode "$@" ;;
esac
