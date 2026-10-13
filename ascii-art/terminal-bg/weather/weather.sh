#!/bin/sh
# Print the background shader for the current weather in one place: clear, rain, or snow.
# Usage: weather.sh [--test WEATHER_CODE]
#
# The shader goes to stdout, and a one-line summary goes to stderr. termbg.sh writes the shader and reloads.
# The shader names the weather details in a "// @TEXT:" line, and termbg.sh draws them in the top right.
#
# --test uses the WMO weather code that you give in place of the real code, for example 63 for rain.
# WEATHER_IS_DAY=0 or WEATHER_IS_DAY=1 sets night or day in place of the real time, for a test.
# WEATHER_LAT and WEATHER_LON set the place, and WEATHER_NAME sets its name. The default place is San Francisco.
set -eu

lat="${WEATHER_LAT:-37.7749}"
lon="${WEATHER_LON:--122.4194}"
name="${WEATHER_NAME:-San Francisco}"
shaders="$(cd "$(dirname "$0")" && pwd)/shaders"

test_code=""
if [ "${1:-}" = "--test" ]; then
    test_code="${2:?error: give a WMO weather code after --test.}"
fi

fields="weather_code,precipitation,wind_speed_10m,wind_direction_10m,is_day"
fields="$fields,temperature_2m,relative_humidity_2m"
url="https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=$fields&temperature_unit=fahrenheit"
if ! json="$(curl -fsS --max-time 20 "$url")"; then
    echo "error: the weather request failed. The shader did not change." >&2
    exit 1
fi

# The values have no spaces, so set splits them into the positional parameters.
# shellcheck disable=SC2046
set -- $(printf '%s' "$json" | jq -r '.current | [.weather_code, .precipitation, .wind_speed_10m,
    .wind_direction_10m, .is_day, .temperature_2m, .relative_humidity_2m] | map(tostring) | join(" ")')
code="${test_code:-$1}" precip="$2" wind="$3" dir="$4" is_day="${WEATHER_IS_DAY:-$5}" temp="$6" humidity="$7"

# The values for the designs:
#   lean:   the lean of rain and snow. The API gives the direction that the wind comes from,
#           so wind from the west (270) blows east, and the rain leans to the right.
#   gust:   how much the lean changes.
#   amount: the amount of rain or snow, from the mm for each hour. A test in dry weather uses 2 mm.
read -r lean gust amount <<EOF
$(awk -v s="$wind" -v d="$dir" -v p="$precip" -v test="$test_code" 'BEGIN {
    lean = -sin(d * 3.14159265 / 180) * s / 100
    lean = lean > 0.5 ? 0.5 : (lean < -0.5 ? -0.5 : lean)
    if (test != "" && p <= 0) p = 2
    amount = 0.3 + p * 0.25 > 2 ? 2 : 0.3 + p * 0.25
    printf "%.3f %.3f %.3f\n", lean, (lean < 0 ? -lean : lean) * 0.25 + 0.01, amount
}')
EOF

# Select the design, its shader, the name of the weather, and the values that the shader uses.
# The codes are the WMO weather codes that Open-Meteo uses. Each code is clear, rain, or snow:
# clouds and fog count as clear. An empty shader shows no design.
case "$code" in
    95 | 96 | 99)
        design=storm label=THUNDERSTORM src=rain
        consts="DENSITY=$amount WIND=$lean GUST=$gust LIGHTNING=1.0"
        ;;
    5[1-7]) design=drizzle label=DRIZZLE src=rain consts="DENSITY=0.300 SPEED=0.700 WIND=$lean GUST=$gust" ;;
    6[1-7] | 8[0-2]) design=rain label=RAIN src=rain consts="DENSITY=$amount WIND=$lean GUST=$gust" ;;
    7[1-7] | 85 | 86) design=snow label=SNOW src=snow consts="DENSITY=$amount WIND=$lean" ;;
    *)
        if [ "$is_day" = 1 ]; then design="clear day" src=""; else design="clear night" src=stars; fi
        label=CLEAR consts=""
        ;;
esac

summary="code=$code precip=$precip wind=$wind dir=$dir is_day=$is_day: $design"
echo "$(date "+%Y-%m-%d %H:%M") $summary" >&2

# The details. "|" starts a new line, and "*" is the degree sign in the font. The wind changes from km/h to mph.
awk -v n="$name" -v t="$temp" -v l="$label" -v s="$wind" -v d="$dir" -v h="$humidity" 'BEGIN {
    split("N NE E SE S SW W NW", compass, " ")
    printf "// @TEXT: %s|%d*F %s|WIND %d MPH %s|HUMIDITY %d%%\n", toupper(n), t + 0.5, l, s * 0.621 + 0.5,
        compass[int((d + 22.5) / 45) % 8 + 1], h + 0.5
}'

if [ -z "$src" ]; then
    cat <<'EOF'
// Clear weather: no design. The terminal shows with no change.
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);
}
EOF
    exit 0
fi

# Set the values in the shader. Each value replaces the line "const float NAME = ...;".
expr=""
for c in $consts; do
    expr="$expr s/^const float ${c%%=*} = .*;/const float ${c%%=*} = ${c#*=};/;"
done
sed "$expr" "$shaders/$src.glsl"
