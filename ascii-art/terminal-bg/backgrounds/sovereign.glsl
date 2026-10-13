// Sovereign
//
// A golden wireframe crown that turns slowly, and rings of its domain that move out across the ground.
//
// Enable it with: termbg sovereign
// @TEXT: SOVEREIGN

// The strength of the design over the background. 0 hides it.
const float STRENGTH = 0.4;
// The center of the crown, as a part of the window width and height. y = 0 is the top.
const vec2 CENTER = vec2(0.68, 0.42);
// The radius of the crown, as a part of the window height.
const float SIZE = 0.11;
// The turn speed of the crown, in radians for each second.
const float SPIN = 0.15;
// The downward angle of the view, in radians. A larger angle shows more of the top.
const float TILT = 0.35;

// Catppuccin yellow and peach for the gold.
const vec3 GOLD = vec3(0.976, 0.886, 0.686);
const vec3 DEEP_GOLD = vec3(0.980, 0.702, 0.529);

const float PI = 3.14159265;

// Turn a point of the crown, and put it on the screen.
// The result is the screen position in pixels and the depth: 1 is the front and -1 is the back.
vec3 project(vec3 p, float spin, vec2 center, float scale) {
    float s = sin(spin);
    float c = cos(spin);
    vec3 r = vec3(c * p.x + s * p.z, p.y, -s * p.x + c * p.z);
    // A view from a little above: a point at the back shows higher. Ghostty puts fragCoord y = 0 at the top.
    float up = r.y * cos(TILT) - r.z * sin(TILT);
    return vec3(center + vec2(r.x, -up) * scale, clamp(r.z, -1.0, 1.0));
}

// Return the light of a line from a to b at frag. The line is dimmer at the back.
float line(vec2 frag, vec3 a, vec3 b) {
    vec2 pa = frag - a.xy;
    vec2 ba = b.xy - a.xy;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-4), 0.0, 1.0);
    float d = length(pa - ba * h);
    float depth = mix(a.z, b.z, h);
    float core = 1.0 - smoothstep(0.4, 1.4, d);
    float glow = 0.25 * exp(-d * 0.35);
    return max(core, glow) * mix(0.3, 1.0, 0.5 + 0.5 * depth);
}

// Return the light of an orb at the point o at frag.
float orb(vec2 frag, vec3 o, float radius) {
    float d = length(frag - o.xy) - radius;
    return (1.0 - smoothstep(-0.5, 0.8, d)) * mix(0.3, 1.0, 0.5 + 0.5 * o.z);
}

// Return the light of the crown at frag.
float crown(vec2 frag, float spin, vec2 center, float scale) {
    float ink = 0.0;

    // The band: a lower ring and an upper ring.
    for (int i = 0; i < 32; i++) {
        float a0 = float(i) / 32.0 * 2.0 * PI;
        float a1 = float(i + 1) / 32.0 * 2.0 * PI;
        for (int k = 0; k < 2; k++) {
            float y = k == 0 ? 0.0 : 0.25;
            vec3 p0 = project(vec3(cos(a0), y, sin(a0)), spin, center, scale);
            vec3 p1 = project(vec3(cos(a1), y, sin(a1)), spin, center, scale);
            ink = max(ink, line(frag, p0, p1));
        }
    }

    // 8 points rise from the upper ring. Each point has an orb on its tip.
    for (int i = 0; i < 8; i++) {
        float v0 = float(i) / 8.0 * 2.0 * PI;
        float tip = v0 + PI / 8.0;
        float v1 = v0 + PI / 4.0;
        vec3 a = project(vec3(cos(v0), 0.25, sin(v0)), spin, center, scale);
        vec3 b = project(vec3(cos(tip) * 1.05, 0.72, sin(tip) * 1.05), spin, center, scale);
        vec3 c = project(vec3(cos(v1), 0.25, sin(v1)), spin, center, scale);
        ink = max(ink, line(frag, a, b));
        ink = max(ink, line(frag, b, c));
        ink = max(ink, orb(frag, project(vec3(cos(tip) * 1.05, 0.78, sin(tip) * 1.05), spin, center, scale),
                           0.035 * scale));
    }

    // Two arches cross over the top.
    for (int k = 0; k < 2; k++) {
        float phi = float(k) * PI / 2.0;
        for (int i = 0; i < 14; i++) {
            float s0 = float(i) / 14.0 * PI;
            float s1 = float(i + 1) / 14.0 * PI;
            vec3 p0 = vec3(0.95 * cos(s0) * cos(phi), 0.25 + 0.8 * sin(s0), 0.95 * cos(s0) * sin(phi));
            vec3 p1 = vec3(0.95 * cos(s1) * cos(phi), 0.25 + 0.8 * sin(s1), 0.95 * cos(s1) * sin(phi));
            ink = max(ink, line(frag, project(p0, spin, center, scale), project(p1, spin, center, scale)));
        }
    }

    // An orb and a cross on the top.
    ink = max(ink, orb(frag, project(vec3(0.0, 1.12, 0.0), spin, center, scale), 0.07 * scale));
    ink = max(ink, line(frag, project(vec3(0.0, 1.19, 0.0), spin, center, scale),
                       project(vec3(0.0, 1.48, 0.0), spin, center, scale)));
    ink = max(ink, line(frag, project(vec3(-0.11, 1.36, 0.0), spin, center, scale),
                       project(vec3(0.11, 1.36, 0.0), spin, center, scale)));
    return ink;
}

// Return the light of the rings of the domain at frag. They move out across the ground under the crown.
float domain(vec2 frag, vec2 center, float scale, float t) {
    vec2 ground = center + vec2(0.0, 0.15 * scale);
    vec2 q = (frag - ground) / scale;
    // The ground is seen from a little above, so a ring on it is a flat ellipse.
    q.y /= sin(TILT);
    float r = length(q);
    float wave = fract(r * 0.25 - t * 0.05);
    float ring = exp(-(wave - 0.5) * (wave - 0.5) * 900.0);
    // The rings start outside the crown and fade with distance.
    return ring * smoothstep(1.2, 2.0, r) * exp(-r * 0.12);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 term = texture(iChannel0, fragCoord / iResolution.xy);
    // The mod keeps the numbers small. It causes a small jump in the design about once each 3 hours.
    float t = mod(iTime, 10000.0);

    vec2 center = CENTER * iResolution.xy;
    float scale = SIZE * iResolution.y;

    float ink = 0.35 * domain(fragCoord, center, scale, t);
    // Skip the crown far from it, because the crown has many lines.
    if (length(fragCoord - center) < 2.0 * scale) {
        float c = crown(fragCoord, t * SPIN, center, scale);
        // A slow shimmer of light moves across the gold.
        c *= 0.8 + 0.2 * sin(t * 0.8 - fragCoord.x * 0.015);
        ink = max(ink, c);
    }

    ink = min(ink, 1.0);
    fragColor = paint(term, mix(DEEP_GOLD, GOLD, ink), STRENGTH * ink);
}
