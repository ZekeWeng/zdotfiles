// Snow
//
// Five depth layers of soft flakes that flutter and drift in gusts, and a line of snow on the ground.
// Near flakes are large and soft, like flakes close to a camera.
//
// Enable it with: termbg snow

// The strength of the snow over the background. 0 hides it.
const float STRENGTH = 0.35;
// The color of the snow: Catppuccin lavender, #b4befe.
const vec3 INK = vec3(0.706, 0.745, 0.996);
// The fall speed, as a multiple of the default speed.
const float SPEED = 1.0;
// The amount of snow, as a multiple of the default amount.
const float DENSITY = 1.0;
// The side drift of the snow, in horizontal pixels for each vertical pixel.
const float WIND = 0.2;
// The size of the side push of a gust, in layer pixels.
const float GUST = 18.0;
// The space between two columns of flakes, in layer pixels.
const float COL_W = 28.0;
// The height of one flake slot in a column, in layer pixels. Each slot has 1 flake or none.
const float SLOT = 40.0;
// The largest height of the snow line at the bottom, in screen pixels. 0 turns it off.
const float GROUND = 10.0;
// The time for the snow line to reach its full height, in seconds.
const float GROUND_TIME = 120.0;

// Return the ink of one layer of flakes at frag.
// scale is the size of one layer pixel, in screen pixels. A near layer has a larger scale.
// speed is the fall speed and radius is the flake radius, in layer pixels.
// blur is the width of the soft edge, in layer pixels. A near layer has more blur, like a camera.
float flakes(vec2 frag, float scale, float speed, float density, float radius, float blur, float seed) {
    vec2 p = frag / scale;

    // A slow gust field pushes groups of flakes to the side. Ghostty puts fragCoord y = 0 at the top.
    p.x -= GUST * (2.0 * noise(vec2(p.y * 0.004 + seed, iTime * 0.15)) - 1.0);
    // The wind drift makes each path lean.
    p.x -= p.y * WIND;

    float col = floor(p.x / COL_W);
    float spd = speed * SPEED * mix(0.75, 1.25, hash(vec2(col, seed + 1.0)));

    // The slots of a column move down. The mod keeps the numbers small.
    // It causes a small jump in the snow about once each hour.
    float y = p.y - mod(iTime * spd, SLOT * 4096.0) + hash(vec2(col, seed + 2.0)) * SLOT;
    float slot = floor(y / SLOT);
    vec2 id = vec2(col, slot) + seed;
    if (hash(id) > density * DENSITY) return 0.0;

    // Each flake has its own size, brightness, sway, and bob.
    vec4 h = vec4(hash(id + 3.1), hash(id + 7.7), hash(id + 11.3), hash(id + 13.9));
    float r = radius * mix(0.6, 1.4, h.x);
    float sway = mix(2.0, 6.0, h.y);
    float margin = sway + r + blur + 1.0;
    // The margin keeps the whole flake in its slot, so that the slot edge does not cut it.
    vec2 room = max(vec2(COL_W, SLOT) - 2.0 * margin, 0.0);
    vec2 center = vec2(COL_W, SLOT) * 0.5 + (vec2(h.z, h.w) - 0.5) * room;
    float rate = 0.5 + 1.2 * h.y;
    center.x += sway * sin(iTime * rate + 6.2832 * h.z);
    center.y += 1.5 * sin(iTime * rate * 1.7 + 6.2832 * h.w);

    float d = length(vec2(p.x - col * COL_W, y - slot * SLOT) - center);
    float brightness = mix(0.6, 1.0, h.x);
    return brightness * (1.0 - smoothstep(r - blur * 0.5, r + blur * 0.5, d));
}

// Return the ink of the snow line at the bottom of the window.
float ground(vec2 frag) {
    float grow = min(iTime / GROUND_TIME, 1.0);
    float n = noise(vec2(frag.x * 0.012, 0.0)) * 0.6 + noise(vec2(frag.x * 0.05, 5.0)) * 0.4;
    float h = GROUND * grow * mix(0.4, 1.0, n);
    float top = iResolution.y - h;
    return 0.8 * smoothstep(top - 1.5, top + 1.5, frag.y);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 term = texture(iChannel0, fragCoord / iResolution.xy);

    // From far to near. Far flakes are small, slow, sharp, and dim.
    // The nearest layer has a few large, soft flakes, like flakes close to a camera.
    float ink = 0.35 * flakes(fragCoord, 1.0, 20.0, 0.45, 0.8, 0.6, 41.0);
    ink = max(ink, 0.5 * flakes(fragCoord, 1.0, 28.0, 0.35, 1.2, 0.8, 53.0));
    ink = max(ink, 0.7 * flakes(fragCoord, 1.5, 32.0, 0.28, 1.6, 1.0, 17.0));
    ink = max(ink, 0.9 * flakes(fragCoord, 2.0, 38.0, 0.18, 2.2, 1.4, 0.0));
    ink = max(ink, 0.45 * flakes(fragCoord, 3.0, 48.0, 0.05, 3.5, 3.5, 29.0));

    if (GROUND > 0.0) ink = max(ink, ground(fragCoord));

    fragColor = paint(term, INK, STRENGTH * min(ink, 1.0));
}
