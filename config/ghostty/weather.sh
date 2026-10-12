#!/bin/sh
# Set the Ghostty background shader from the current weather in one place.
# Usage: weather.sh [--test WEATHER_CODE]
# --test uses the WMO weather code that you give in place of the real code, for example 63 for rain.
# WEATHER_IS_DAY=0 or WEATHER_IS_DAY=1 sets night or day in place of the real time, for a test.
# The script writes the shader to $XDG_STATE_HOME/ghostty/weather.glsl and reloads cmux.
# Ghostty has no reload command for scripts. Press Cmd+Shift+, in Ghostty to see a change.
# WEATHER_LAT and WEATHER_LON set the place. The default place is San Francisco.
set -eu

lat="${WEATHER_LAT:-37.7749}"
lon="${WEATHER_LON:--122.4194}"
shaders="$(cd "$(dirname "$0")" && pwd)/shaders"
out_dir="${XDG_STATE_HOME:-$HOME/.local/state}/ghostty"
out="$out_dir/weather.glsl"

test_code=""
if [ "${1:-}" = "--test" ]; then
    test_code="${2:?error: give a WMO weather code after --test.}"
fi

url="https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon"
url="$url&current=weather_code,precipitation,cloud_cover,wind_speed_10m,wind_direction_10m,is_day"
if ! json="$(curl -fsS --max-time 20 "$url")"; then
    echo "error: the weather request failed. The shader did not change." >&2
    exit 1
fi

code="$(printf '%s' "$json" | jq -r '.current.weather_code')"
precip="$(printf '%s' "$json" | jq -r '.current.precipitation')"
wind="$(printf '%s' "$json" | jq -r '.current.wind_speed_10m')"
dir="$(printf '%s' "$json" | jq -r '.current.wind_direction_10m')"
clouds="$(printf '%s' "$json" | jq -r '.current.cloud_cover')"
is_day="$(printf '%s' "$json" | jq -r '.current.is_day')"
is_day="${WEATHER_IS_DAY:-$is_day}"

if [ -n "$test_code" ]; then
    code="$test_code"
    # A test of rain or snow in dry weather uses a moderate amount.
    precip="$(awk -v p="$precip" 'BEGIN { printf "%s", (p > 0 ? p : 2) }')"
    # A test of clouds in a clear sky uses a cover of 70%.
    clouds="$(awk -v c="$clouds" 'BEGIN { printf "%s", (c >= 30 ? c : 70) }')"
fi

# The lean of the rain or the snow. The API gives the direction that the wind comes from.
# Wind from the west blows to the east, so the rain leans to the right.
lean="$(awk -v s="$wind" -v d="$dir" 'BEGIN {
    l = -sin(d * 3.14159265 / 180) * s / 100
    if (l > 0.5) l = 0.5
    if (l < -0.5) l = -0.5
    printf "%.3f", l
}')"
gust="$(awk -v l="$lean" 'BEGIN { printf "%.3f", (l < 0 ? -l : l) * 0.25 + 0.01 }')"
# The side movement of fog and clouds, in pixels for each second, from the wind speed in km/h.
drift="$(awk -v s="$wind" -v d="$dir" 'BEGIN {
    v = -sin(d * 3.14159265 / 180) * s
    if (v > 60) v = 60
    if (v < -60) v = -60
    printf "%.3f", v
}')"
# The part of the sky that clouds cover, from the cloud cover in percent.
cover="$(awk -v c="$clouds" 'BEGIN { c = c / 100; if (c < 0.3) c = 0.3; printf "%.3f", c }')"
# The amount of rain or snow, from the precipitation in mm for each hour.
amount="$(awk -v p="$precip" 'BEGIN { a = 0.3 + p * 0.25; if (a > 2) a = 2; printf "%.3f", a }')"

# Select the design. The codes are the WMO weather codes that Open-Meteo uses.
design=""
consts=""
case "$code" in
    95 | 96 | 99)
        design="storm"
        consts="DENSITY=$amount WIND=$lean GUST=$gust LIGHTNING=1.0"
        ;;
    5[1-7])
        design="drizzle"
        consts="DENSITY=0.300 SPEED=0.700 WIND=$lean GUST=$gust"
        ;;
    6[1-7] | 8[0-2])
        design="rain"
        consts="DENSITY=$amount WIND=$lean GUST=$gust"
        ;;
    7[1-7] | 85 | 86)
        design="snow"
        consts="DENSITY=$amount WIND=$lean"
        ;;
    45 | 48)
        design="fog"
        consts="DRIFT=$drift"
        ;;
    2 | 3)
        design="clouds"
        consts="DRIFT=$drift COVER=$cover"
        ;;
    *)
        if [ "$is_day" = 1 ]; then design="clear day"; else design="clear night"; fi
        ;;
esac

case "$design" in
    storm | drizzle | rain) src="$shaders/rain.glsl" ;;
    snow) src="$shaders/snow.glsl" ;;
    fog) src="$shaders/fog.glsl" ;;
    clouds) src="$shaders/clouds.glsl" ;;
    "clear night") src="$shaders/stars.glsl" ;;
    *) src="" ;;
esac

# Write to a temporary file first, so that a terminal never reads a part of the shader.
mkdir -p "$out_dir"
tmp="$out.tmp"
if [ -z "$src" ]; then
    cat >"$tmp" <<'EOF'
// Clear weather: no design. The terminal shows with no change.
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);
}
EOF
else
    expr=""
    for c in $consts; do
        expr="$expr s/^const float ${c%%=*} = .*;/const float ${c%%=*} = ${c#*=};/;"
    done
    sed "$expr" "$src" >"$tmp"
fi

echo "$(date "+%Y-%m-%d %H:%M") code=$code precip=$precip clouds=$clouds wind=$wind dir=$dir is_day=$is_day: $design"

if cmp -s "$tmp" "$out"; then
    rm -f "$tmp"
    exit 0
fi
mv "$tmp" "$out"

cmux="$(command -v cmux || echo /Applications/cmux.app/Contents/Resources/bin/cmux)"
if [ -x "$cmux" ]; then
    "$cmux" reload-config >/dev/null || echo "warning: cmux did not reload. Run: cmux reload-config" >&2
fi
