// Realistic fog behind the terminal text: soft layers of mist and fast wisps that move with the wind.
// The fog shows only on background pixels, so the text stays clear.
// Enable it with: custom-shader = <path to this file>

// The strength of the fog over the background. 0 hides it.
const float STRENGTH = 0.3;
// The color of the fog: Catppuccin lavender, #b4befe.
const vec3 INK = vec3(0.706, 0.745, 0.996);
// The amount of fog, from 0 to 1.
const float DENSITY = 0.6;
// The side movement of the fog, in pixels for each second. A negative value moves it to the left.
const float DRIFT = 12.0;
// The size of the fog shapes, in pixels.
const float SIZE = 500.0;

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

// Put the fog of strength ink under the terminal pixel.
// Ghostty gives opaque background pixels. cmux gives transparent background pixels.
vec4 compose(vec4 term, float ink) {
    float isBg = max(1.0 - smoothstep(0.01, 0.06, distance(term.rgb, iBackgroundColor)), 1.0 - term.a);
    float a = STRENGTH * clamp(ink, 0.0, 1.0) * isBg;
    return vec4(INK * a, a) + term * (1.0 - a);
}

// Return the fog of one layer at frag. A near layer is larger and moves faster.
float mist(vec2 frag, float size, float speed, float seed) {
    // The mod keeps the numbers small. It causes a small jump in the fog about once each 3 hours.
    float t = mod(iTime, 10000.0);
    vec2 p = (frag - vec2(DRIFT * speed * t, 0.0)) / size + seed;
    // A slow warp makes the mist curl and change its shape.
    vec2 q = vec2(fbm(p + vec2(0.0, t * 0.02)), fbm(p + vec2(5.2, 1.3) - vec2(t * 0.015, 0.0)));
    return fbm(p + 1.2 * q);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 term = texture(iChannel0, fragCoord / iResolution.xy);
    vec2 uv = fragCoord / iResolution.xy;

    // A far, slow bank of fog and a near, faster layer of thin wisps.
    float bank = mist(fragCoord, SIZE, 0.6, 0.0);
    float wisps = mist(fragCoord, SIZE * 0.45, 1.4, 31.0);
    float f = 0.65 * bank + 0.35 * wisps;

    // DENSITY sets the part of the window that has fog.
    float ink = smoothstep(0.6 - 0.35 * DENSITY, 0.85 - 0.2 * DENSITY, f);

    // Fog is denser near the ground. Ghostty puts fragCoord y = 0 at the top.
    ink *= mix(0.45, 1.0, smoothstep(0.0, 1.0, uv.y));

    fragColor = compose(term, ink);
}
