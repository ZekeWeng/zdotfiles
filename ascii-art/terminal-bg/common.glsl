// Common
//
// The helpers that every design uses. termbg.sh puts this file at the start of each shader that it builds,
// so a design file holds only its own idea.
//
// Colors are premultiplied: a color c with the strength a is vec4(c * a, a).

// ---- Noise ---------------------------------------------------------------------------------------------

// A random number from 0 to 1 for the point p.
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// Smooth noise from 0 to 1.
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
        u.y);
}

// Layers of noise. Each layer is twice as fine and half as strong as the layer before it.
float fbm(vec2 p, int layers) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < layers; i++) {
        v += a * noise(p);
        p = p * 2.03 + vec2(1.7, 9.2);
        a *= 0.5;
    }
    return v;
}

// ---- Shapes --------------------------------------------------------------------------------------------

// The approximate signed distance to an ellipse with the radii r.
float ellipse(vec2 p, vec2 r) {
    return (length(p / r) - 1.0) * min(r.x, r.y);
}

// The signed distance to a line from a to b with the radius r.
float capsule(vec2 p, vec2 a, vec2 b, float r) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

// A union of two shapes that joins them smoothly over the distance k.
float smoothUnion(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

vec2 rotate(vec2 p, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return vec2(c * p.x + s * p.y, -s * p.x + c * p.y);
}

// How much of a pixel of the size px a shape covers, from its signed distance d. This makes smooth edges.
float coverage(float d, float px) {
    return clamp(0.5 - d / px, 0.0, 1.0);
}

// ---- Color ---------------------------------------------------------------------------------------------

// Put the color c with the strength a over the color dst.
vec4 over(vec4 dst, vec3 c, float a) {
    a = clamp(a, 0.0, 1.0);
    return vec4(c * a, a) + dst * (1.0 - a);
}

// 1 if the terminal pixel shows only the background, and 0 if it shows text, the cursor, or a selection.
// Ghostty gives opaque background pixels. cmux gives transparent background pixels,
// because cmux draws the background behind the terminal.
float isBackground(vec4 term) {
    return max(1.0 - smoothstep(0.01, 0.06, distance(term.rgb, iBackgroundColor)), 1.0 - term.a);
}

// Put the design art under the terminal pixel. The design shows only on background pixels,
// so the terminal text stays clear.
vec4 underText(vec4 term, vec4 art) {
    float k = isBackground(term);
    return art * k + term * (1.0 - art.a * k);
}

// Put the color c with the strength a under the terminal pixel.
vec4 paint(vec4 term, vec3 c, float a) {
    a = clamp(a, 0.0, 1.0);
    return underText(term, vec4(c * a, a));
}
