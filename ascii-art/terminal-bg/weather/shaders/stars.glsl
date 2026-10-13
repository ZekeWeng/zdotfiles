// Stars
//
// A night sky that turns slowly: stars in clusters that twinkle in their own colors,
// the Milky Way, and a shooting star from time to time.
//
// Enable it with: termbg stars
// @TEXT: NIGHT SKY

// The strength of the sky over the background. 0 hides it.
const float STRENGTH = 0.5;
// The color of the sky: Catppuccin lavender, #b4befe.
const vec3 INK = vec3(0.706, 0.745, 0.996);
// The amount of stars, as a multiple of the default amount.
const float DENSITY = 1.0;
// How much the stars twinkle. 0 stops it.
const float TWINKLE = 0.35;
// The turn speed of the sky, in radians for each second.
const float ROTATION = 0.0003;
// The strength of the Milky Way. 0 hides it.
const float MILKY_WAY = 0.12;
// The time between two chances of a shooting star, in seconds.
const float METEOR_TIME = 20.0;

// Keep the stronger of two sky colors.
vec4 brighter(vec4 a, vec4 b) {
    return b.a > a.a ? b : a;
}

// The tint of a star. Hot stars are blue, and cool stars are orange, as in the real sky.
// Most stars use INK. The other tints are Catppuccin blue, rosewater, and peach.
vec3 tint(float h) {
    if (h < 0.55) return INK;
    if (h < 0.75) return vec3(0.537, 0.706, 0.980);
    if (h < 0.92) return vec3(0.961, 0.878, 0.863);
    return vec3(0.980, 0.702, 0.529);
}

// Return the color and the ink of one star field at the sky position p.
// cell is the size of one star slot, in pixels. bright adds to the brightness of all stars in the field.
// cluster multiplies the chance of a star, so that some areas of the sky have more stars.
vec4 starField(vec2 p, float cell, float density, float bright, float cluster, float seed) {
    vec2 c = floor(p / cell);
    vec2 id = c + seed;
    if (hash(id) > density * DENSITY * cluster) return vec4(0.0);

    // The star stays in the middle half of its slot, so that the slot edge does not cut its glow.
    vec2 pos = (c + 0.25 + 0.5 * vec2(hash(id + 1.3), hash(id + 2.7))) * cell;
    vec2 rel = p - pos;
    float d = length(rel);

    // Most stars are very dim. A few stars are bright and have a soft glow.
    float mag = clamp(pow(hash(id + 4.1), 6.0) * 1.3 + bright, 0.0, 1.0);
    float core = 1.0 - smoothstep(0.4, 1.0 + 1.6 * mag, d);
    float glow = 0.5 * mag * exp(-d * mix(0.8, 0.35, mag));
    float star = max(core, glow);

    // The brightest stars have 4 thin rays.
    if (mag > 0.8) {
        float rays = exp(-abs(rel.x) * 1.5) * exp(-abs(rel.y) * 0.3) + exp(-abs(rel.y) * 1.5) * exp(-abs(rel.x) * 0.3);
        star = max(star, 0.6 * (mag - 0.8) * 5.0 * rays);
    }

    // The air makes stars twinkle. Each star has its own rate and amount.
    float h = hash(id + 5.5);
    float rate = mix(2.0, 6.0, hash(id + 6.6));
    float tw = 1.0 + TWINKLE * mix(0.3, 1.5, h) * (2.0 * noise(vec2(iTime * rate, h * 100.0)) - 1.0);
    return vec4(tint(hash(id + 8.8)), (0.15 + 0.85 * mag) * star * tw);
}

// Return the ink of a shooting star at frag.
// Each window of METEOR_TIME seconds has a shooting star at a random time, with a chance of 50%.
float meteor(vec2 frag) {
    float w = floor(iTime / METEOR_TIME);
    if (hash(vec2(w, 3.0)) > 0.5) return 0.0;
    float life = 0.9;
    float dt = iTime - (w * METEOR_TIME + 1.0 + hash(vec2(w, 5.0)) * (METEOR_TIME - 2.0 - life));
    if (dt < 0.0 || dt > life) return 0.0;

    // It starts in the top third of the window and moves down to the side.
    vec2 start = vec2(0.1 + 0.8 * hash(vec2(w, 7.0)), 0.05 + 0.3 * hash(vec2(w, 9.0))) * iResolution.xy;
    vec2 dir = normalize(vec2(hash(vec2(w, 11.0)) < 0.5 ? -1.0 : 1.0, 0.45));
    vec2 head = start + dir * iResolution.x * 0.6 * dt;

    vec2 rel = frag - head;
    float along = -dot(rel, dir);
    float across = abs(dot(rel, vec2(-dir.y, dir.x)));
    float len = iResolution.x * 0.08;
    if (along < -1.0 || along > len) return 0.0;
    return (1.0 - dt / life) * (1.0 - max(along, 0.0) / len) * (1.0 - smoothstep(0.5, 1.5, across));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 term = texture(iChannel0, fragCoord / iResolution.xy);

    // The sky turns slowly around a point far above the window. Ghostty puts fragCoord y = 0 at the top.
    vec2 pivot = vec2(iResolution.x * 0.35, -iResolution.y * 1.5);
    float angle = mod(iTime * ROTATION, 6.2832);
    float s = sin(angle);
    float c = cos(angle);
    vec2 p = mat2(c, s, -s, c) * (fragCoord - pivot) + pivot;

    // The Milky Way is a faint, uneven band across the sky.
    vec2 axis = normalize(vec2(1.0, -0.6));
    vec2 mid = iResolution.xy * 0.5;
    float dist = abs(dot(p - mid, vec2(-axis.y, axis.x))) / iResolution.y;
    float band = exp(-dist * dist * 30.0);
    float dust = smoothstep(0.35, 0.75, fbm(p * 0.004, 4));

    // Stars group in clusters, and there are more stars near the Milky Way.
    float cluster = mix(0.3, 1.7, smoothstep(0.3, 0.7, fbm(p * 0.0015 + 7.0, 4))) + 1.2 * band;

    // Many small, dim stars, some medium stars, and a few large, bright stars.
    vec4 sky = vec4(INK, MILKY_WAY * band * dust);
    sky = brighter(sky, starField(p, 10.0, 0.25, 0.0, cluster, 0.0));
    sky = brighter(sky, starField(p, 24.0, 0.25, 0.1, cluster, 31.0));
    sky = brighter(sky, starField(p, 56.0, 0.30, 0.3, cluster, 19.0));
    sky = brighter(sky, vec4(INK, meteor(fragCoord)));

    fragColor = paint(term, sky.rgb, STRENGTH * sky.a);
}
