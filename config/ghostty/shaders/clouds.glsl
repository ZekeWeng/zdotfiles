// Realistic clouds behind the terminal text: soft masses with bright tops, and a high, thin layer.
// The clouds show only on background pixels, so the text stays clear.
// Enable it with: custom-shader = <path to this file>

// The strength of the clouds over the background. 0 hides them.
const float STRENGTH = 0.3;
// The color of the clouds: Catppuccin lavender, #b4befe.
const vec3 INK = vec3(0.706, 0.745, 0.996);
// The part of the sky that the clouds cover, from 0 to 1.
const float COVER = 0.6;
// The side movement of the low clouds, in pixels for each second. A negative value moves them to the left.
const float DRIFT = 12.0;
// The size of the cloud shapes, in pixels.
const float SIZE = 700.0;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
        u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = p * 2.03 + vec2(1.7, 9.2);
        a *= 0.5;
    }
    return v;
}

// Put the clouds of strength ink under the terminal pixel.
// Ghostty gives opaque background pixels. cmux gives transparent background pixels.
vec4 compose(vec4 term, float ink) {
    float isBg = max(1.0 - smoothstep(0.01, 0.06, distance(term.rgb, iBackgroundColor)), 1.0 - term.a);
    float a = STRENGTH * clamp(ink, 0.0, 1.0) * isBg;
    return vec4(INK * a, a) + term * (1.0 - a);
}

// Return the cloud density at the cloud position p. The shape changes slowly over time.
float density(vec2 p, float t) {
    return fbm(p + vec2(0.0, t * 0.01)) + 0.15 * fbm(p * 3.0 - vec2(t * 0.03, 0.0));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 term = texture(iChannel0, fragCoord / iResolution.xy);
    // The mod keeps the numbers small. It causes a small jump in the clouds about once each 3 hours.
    float t = mod(iTime, 10000.0);

    // The low clouds. COVER sets the threshold, so more cover gives larger clouds.
    vec2 p = (fragCoord - vec2(DRIFT * t, 0.0)) / SIZE;
    float d = density(p, t);
    float edge = 1.0 - COVER;
    float body = smoothstep(edge * 0.9 + 0.2, edge * 0.9 + 0.45, d);

    // The sun lights the clouds from above, so the tops are bright and the bases are dark.
    // Ghostty puts fragCoord y = 0 at the top, so a smaller y is higher.
    float below = density(p + vec2(0.0, 0.03), t);
    float light = clamp(0.6 + 4.0 * (below - d), 0.35, 1.0);
    float low = body * light;

    // A high, thin layer of streaks moves more slowly.
    vec2 hp = (fragCoord - vec2(DRIFT * 0.4 * t, 0.0)) / (SIZE * vec2(2.5, 0.5)) + 17.0;
    float high = 0.35 * smoothstep(0.55, 0.8, fbm(hp)) * COVER;

    fragColor = compose(term, max(low, high));
}
