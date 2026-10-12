// Realistic rain behind the terminal text: 3 depth layers, motion blur, wind, and splashes.
// The rain shows only on background pixels, so the text stays clear.
// Enable it with: custom-shader = <path to this file>

// The strength of the rain over the background. 0 hides it.
const float STRENGTH = 0.35;
// The color of the rain: Catppuccin lavender, #b4befe.
const vec3 INK = vec3(0.706, 0.745, 0.996);
// The fall speed, as a multiple of the default speed.
const float SPEED = 1.0;
// The amount of rain, as a multiple of the default amount.
const float DENSITY = 1.0;
// The lean of the rain, in horizontal pixels for each vertical pixel.
const float WIND = 0.16;
// The change of the lean in a gust.
const float GUST = 0.04;
// The space between two columns of drops, in layer pixels.
const float COL_W = 10.0;
// The height of one drop slot in a column, in layer pixels.
const float SEG = 160.0;
// The life of a splash, in seconds.
const float SPLASH_TIME = 0.4;
// The lightning in a storm: 0 turns it off, and 1 turns it on.
const float LIGHTNING = 0.0;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// Put the rain of strength ink under the terminal pixel.
// Ghostty gives opaque background pixels. cmux gives transparent background pixels.
vec4 compose(vec4 term, float ink) {
    float isBg = max(1.0 - smoothstep(0.01, 0.06, distance(term.rgb, iBackgroundColor)), 1.0 - term.a);
    float a = STRENGTH * clamp(ink, 0.0, 1.0) * isBg;
    return vec4(INK * a, a) + term * (1.0 - a);
}

// The x position of the drops in a column, in layer pixels, before the wind lean.
float columnX(float col, float seed) {
    return col * COL_W + 1.0 + floor(hash(vec2(col, seed)) * (COL_W - 2.0));
}

// The fall speed of a column, in layer pixels for each second.
float columnSpeed(float col, float speed, float seed) {
    return speed * SPEED * mix(0.85, 1.15, hash(vec2(col, seed + 1.0)));
}

// The position of the screen y in the moving frame of a column.
// Ghostty puts fragCoord y = 0 at the top, so the frame moves to larger y.
// The mod keeps the numbers small. It causes a small jump in the rain about once each 20 minutes.
float frameY(float y, float col, float spd, float seed) {
    return y - mod(iTime * spd, SEG * 4096.0) + hash(vec2(col, seed + 2.0)) * SEG;
}

// Return true if the drop slot seg of a column has a drop.
bool hasDrop(float col, float seg, float density, float seed) {
    return hash(vec2(col, seg) + seed) < density * DENSITY;
}

// The length of the streak of a drop, in layer pixels.
float dropLength(float col, float seg, float len, float seed) {
    return floor(len * mix(0.7, 1.3, hash(vec2(seg, col) + seed + 5.0)));
}

// Return the ink of one layer of rain streaks at frag.
// scale is the size of one layer pixel, in screen pixels. A near layer has a larger scale.
float streaks(vec2 frag, float scale, float speed, float density, float len, float seed, float wind) {
    vec2 p = frag / scale;
    p.x -= p.y * wind;
    float col = floor(p.x / COL_W);
    if (floor(p.x) != columnX(col, seed)) return 0.0;

    float spd = columnSpeed(col, speed, seed);
    float y = frameY(p.y, col, spd, seed);
    float seg = floor(y / SEG);
    if (!hasDrop(col, seg, density, seed)) return 0.0;

    // The head is at the bottom of the streak. The tail fades out to the top.
    float ly = floor(y - seg * SEG);
    float l = dropLength(col, seg, len, seed);
    if (ly >= l) return 0.0;
    float fade = (ly + 1.0) / l;
    return fade * fade;
}

// Return the ink of the splashes of one layer at the bottom of the window.
float splashes(vec2 frag, float scale, float speed, float density, float len, float seed, float wind) {
    vec2 p = frag / scale;
    float floorY = iResolution.y / scale;
    if (p.y < floorY - 14.0) return 0.0;

    float ink = 0.0;
    float c0 = floor((p.x - floorY * wind) / COL_W);
    for (int i = -2; i <= 2; i++) {
        float col = c0 + float(i);
        float spd = columnSpeed(col, speed, seed);

        // Find the last drop that hit the floor. The head of a drop is at seg * SEG + its length.
        float yF = frameY(floorY, col, spd, seed);
        float seg = floor(yF / SEG);
        if (seg * SEG + dropLength(col, seg, len, seed) <= yF) seg += 1.0;
        if (!hasDrop(col, seg, density, seed)) continue;
        float age = (seg * SEG + dropLength(col, seg, len, seed) - yF) / spd;
        if (age > SPLASH_TIME) continue;
        float life = 1.0 - age / SPLASH_TIME;

        float cx = columnX(col, seed) + 0.5 + floorY * wind;

        // A small ring spreads on the floor.
        float r = 2.0 + age * 40.0;
        if (p.y > floorY - 1.0 && abs(abs(p.x - cx) - r) < 1.0) ink = max(ink, 0.6 * life);

        // 3 droplets jump up and fall back.
        for (int k = 0; k < 3; k++) {
            vec2 h = vec2(hash(vec2(col, seg + float(k) * 7.0) + seed), hash(vec2(seg, col + float(k)) + seed));
            float vx = (h.x - 0.5) * 70.0;
            float vy = 35.0 + h.y * 30.0;
            float dy = vy * age - 0.5 * 400.0 * age * age;
            if (dy < 0.0) continue;
            vec2 d = vec2(cx + vx * age, floorY - 1.0 - dy);
            if (floor(p) == floor(d)) ink = max(ink, life);
        }
    }
    return ink;
}

// Return the light of a lightning flash, from 0 to 1.
// Each 8 second window has a flash at a random time, with a chance of 40%.
float lightning() {
    float w = floor(iTime / 8.0);
    if (hash(vec2(w, 91.0)) > 0.4) return 0.0;
    float dt = iTime - (w + 0.1 + 0.6 * hash(vec2(w, 37.0))) * 8.0;
    if (dt < 0.0) return 0.0;
    return exp(-dt * 12.0) + 0.7 * exp(-max(dt - 0.15, 0.0) * 6.0) * step(0.15, dt);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 term = texture(iChannel0, fragCoord / iResolution.xy);
    float wind = WIND + GUST * sin(iTime * 0.13) * sin(iTime * 0.071);

    // Far, middle, and near layers. A far layer is thinner, slower, and dimmer.
    float ink = 0.35 * streaks(fragCoord, 1.0, 380.0, 0.20, 16.0, 41.0, wind);
    ink = max(ink, 0.6 * streaks(fragCoord, 1.5, 380.0, 0.22, 22.0, 17.0, wind));
    ink = max(ink, streaks(fragCoord, 2.0, 420.0, 0.25, 28.0, 0.0, wind));

    // Only the middle and near layers make splashes.
    ink = max(ink, 0.6 * splashes(fragCoord, 1.5, 380.0, 0.22, 22.0, 17.0, wind));
    ink = max(ink, splashes(fragCoord, 2.0, 420.0, 0.25, 28.0, 0.0, wind));

    // A storm has a short, double flash of light at random times.
    if (LIGHTNING > 0.0) ink = max(ink, LIGHTNING * 0.45 * lightning());

    fragColor = compose(term, ink);
}
