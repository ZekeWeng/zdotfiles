// Dog under a leaf
//
// An apricot Australian labradoodle sits near the bottom-right corner and looks at you.
// A large leaf keeps the rain off it.
//
// The dog is made of soft shapes that join like fur: round haunches, a chest ruff, straight
// front legs, a big round head with a topknot, long ears, and a cream muzzle with a beard.
// Round ringlets make the fleece and the curly outline. The light comes from the top left.
//
// The dog has four poses: sit, paw, lie down, and sleep. It moves smoothly from one pose
// to the next. It also breathes, blinks, tilts its head, and wags its tail. The leaf sways.
//
// This is an overlay. termbg.sh renames mainImage of the background to bgImage
// and adds this file after it.
//
// Enable it with: termbg overlay dog-leaf

// ---- Settings ------------------------------------------------------------------------------------------

// The height of the dog, in screen pixels.
const float DOG_SIZE = 150.0;
// The space from the bottom-right corner of the window to the art, in screen pixels.
const vec2 DOG_MARGIN = vec2(90.0, 56.0);
// The strength of the art over the background. 0 hides it.
const float DOG_STRENGTH = 0.92;

// The colors of an apricot labradoodle.
const vec3 DOG_COAT = vec3(0.89, 0.66, 0.46);
const vec3 DOG_CREAM = vec3(0.97, 0.85, 0.70);
const vec3 DOG_DEEP = vec3(0.62, 0.40, 0.25);
const vec3 DOG_EAR = vec3(0.80, 0.55, 0.35);
const vec3 DOG_EYE = vec3(0.10, 0.06, 0.05);
const vec3 DOG_NOSE = vec3(0.14, 0.09, 0.08);
const vec3 DOG_TONGUE = vec3(0.92, 0.53, 0.57);

// The colors of the leaf.
const vec3 DOG_LEAF = vec3(0.36, 0.62, 0.30);
const vec3 DOG_LEAF_LIGHT = vec3(0.54, 0.78, 0.42);
const vec3 DOG_VEIN = vec3(0.24, 0.44, 0.20);

// The art box, in dog heights, around the center of the dog on the ground.
const vec2 DOG_BOX_MIN = vec2(-0.80, -0.06);
const vec2 DOG_BOX_MAX = vec2(0.80, 1.52);

// ---- Shapes --------------------------------------------------------------------------------------------

// Cellular noise: the distance to the nearest random point, and to the second nearest point.
// Each cell is one ringlet of fleece.
vec2 dogCells(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 near = vec2(8.0);
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 o = vec2(float(x), float(y));
            vec2 r = o + 0.1 + 0.8 * vec2(hash(i + o), hash(i + o + 5.3)) - f;
            float d = dot(r, r);
            near = d < near.x ? vec2(d, near.x) : vec2(near.x, min(near.y, d));
        }
    }
    return sqrt(near);
}

// The scale of the ringlets: the number of ringlets for each dog height.
const float RINGLETS = 26.0;

// Pull an edge in between the ringlets, so that the outline is a row of soft, round curls.
// The edge only moves in, so no loose pieces of fur show outside the shape.
float dogFluff(vec2 p, float amount) {
    return 0.6 * amount * smoothstep(0.2, 0.7, dogCells(p * RINGLETS * 0.55).x);
}

// ---- Poses --------------------------------------------------------------------------------------------

// A pose sets where each part of the dog is. Two poses blend smoothly, so the dog moves between them.
// All positions are in dog heights, with x = 0 at the middle of the dog and y up from the ground.
struct Pose {
    vec2 head;      // The move of the head, the ears, and the face from their place in the sit pose.
    float tilt;     // The tilt of the head, in radians. A positive tilt turns it to the left.
    vec4 torso;     // The center and the radii of the body.
    vec4 ruff;      // The center and the radii of the chest ruff.
    vec4 haunch;    // The center and the radii of the right haunch. The left haunch is its mirror.
    vec4 legLeft;   // The left front leg, from the paw end to the shoulder end.
    vec4 legRight;  // The right front leg, from the paw end to the shoulder end.
    vec2 pawLeft;   // The center of the left front paw.
    vec2 pawRight;  // The center of the right front paw.
    float hind;     // The x of the right back paw. The left back paw is its mirror.
    vec4 tail;      // The base of the tail, and the step from the base to its middle.
    float tailBend; // The direction of the tip of the tail, in radians from straight up.
    float eyes;     // How open the eyes are, from 0 to 1.
    float wag;      // How much the tail wags, from 0 to 1.
    float breath;   // How deep the breath is.
};

const int SIT = 0;
const int PAW = 1;
const int LIE = 2;
const int SLEEP = 3;

Pose pose(int id) {
    // The dog sits and looks at you.
    Pose sit = Pose(
        vec2(0.0), 0.0,
        vec4(0.0, 0.34, 0.25, 0.29), vec4(0.0, 0.50, 0.17, 0.14), vec4(0.25, 0.17, 0.17, 0.165),
        vec4(-0.10, 0.06, -0.11, 0.38), vec4(0.10, 0.06, 0.11, 0.38),
        vec2(-0.105, 0.045), vec2(0.105, 0.045), 0.31,
        vec4(0.30, 0.12, 0.13, 0.12), 0.25,
        1.0, 1.0, 0.012);
    if (id == SIT) return sit;
    if (id == PAW) {
        // The dog lifts its left front paw and tilts its head.
        Pose paw = sit;
        paw.tilt = 0.14;
        paw.legLeft = vec4(-0.27, 0.47, -0.12, 0.33);
        paw.pawLeft = vec2(-0.30, 0.49);
        return paw;
    }
    // The dog lies down like a sphinx, with its front paws forward.
    Pose lie = Pose(
        vec2(0.0, -0.30), 0.0,
        vec4(0.0, 0.17, 0.31, 0.16), vec4(0.0, 0.25, 0.18, 0.10), vec4(0.30, 0.11, 0.15, 0.11),
        vec4(-0.12, 0.05, -0.12, 0.12), vec4(0.12, 0.05, 0.12, 0.12),
        vec2(-0.12, 0.04), vec2(0.12, 0.04), 0.40,
        vec4(0.36, 0.06, 0.14, 0.0), 1.4,
        1.0, 0.3, 0.012);
    if (id == LIE) return lie;
    // The dog sleeps with its head on its paws, and it breathes slowly and deeply.
    Pose sleep = lie;
    sleep.head = vec2(0.02, -0.40);
    sleep.tilt = 0.22;
    sleep.eyes = 0.0;
    sleep.wag = 0.0;
    sleep.breath = 0.025;
    return sleep;
}

Pose mixPose(Pose a, Pose b, float k) {
    return Pose(
        mix(a.head, b.head, k), mix(a.tilt, b.tilt, k),
        mix(a.torso, b.torso, k), mix(a.ruff, b.ruff, k), mix(a.haunch, b.haunch, k),
        mix(a.legLeft, b.legLeft, k), mix(a.legRight, b.legRight, k),
        mix(a.pawLeft, b.pawLeft, k), mix(a.pawRight, b.pawRight, k), mix(a.hind, b.hind, k),
        mix(a.tail, b.tail, k), mix(a.tailBend, b.tailBend, k),
        mix(a.eyes, b.eyes, k), mix(a.wag, b.wag, k), mix(a.breath, b.breath, k));
}

// The order of the poses. Each pose holds for POSE_HOLD seconds, then the dog moves
// to the next pose in POSE_MOVE seconds.
const int POSES = 6;
const int SEQUENCE[POSES] = int[](SIT, PAW, SIT, LIE, SLEEP, LIE);
const float POSE_HOLD = 16.0;
const float POSE_MOVE = 2.5;

// The pose at the time t, between two poses during a move.
Pose poseAt(float t) {
    float slot = POSE_HOLD + POSE_MOVE;
    float phase = mod(t, slot * float(POSES));
    int i = int(phase / slot);
    float k = smoothstep(POSE_HOLD, slot, phase - float(i) * slot);
    return mixPose(pose(SEQUENCE[i]), pose(SEQUENCE[(i + 1) % POSES]), k);
}

// ---- The dog -------------------------------------------------------------------------------------------

// The parts of the dog, from back to front. Each part is its own layer, so a part in front
// covers the parts behind it and casts a soft shadow on them. This keeps each part distinct.
const int TAIL = 0;
const int HAUNCHES = 1;
const int TORSO = 2;
const int LEGS = 3;
const int PAWS = 4;
const int EARS = 5;
const int HEAD = 6;
const int MUZZLE = 7;
const int PARTS = 8;

// The point that the head turns around, at the top of the neck in the sit pose.
const vec2 NECK = vec2(0.0, 0.58);

// The position p in the frame of the head. An awake dog also tilts its head slowly, as a curious dog does.
vec2 headFrame(vec2 p, Pose ps, float t) {
    float curious = 0.10 * sin(t * 0.23) * smoothstep(-0.2, 0.6, sin(t * 0.11)) * ps.eyes;
    return rotate(p - NECK - ps.head, ps.tilt + curious) + NECK;
}

// The signed distance to a part of the dog at p. The fluff is long on the head, the ears, and the tail,
// and short on the legs and the paws, so the legs read as straight limbs.
float dogPart(int part, vec2 p, Pose ps, float t) {
    vec2 m = vec2(abs(p.x), p.y);
    if (part == TAIL) {
        // A plume that curls up on the right side. It wags in short bursts.
        float wag = ps.wag * 0.25 * sin(t * 11.0) * smoothstep(0.2, 0.5, sin(t * 0.37));
        vec2 base = ps.tail.xy;
        vec2 mid = base + ps.tail.zw;
        vec2 tip = mid + 0.13 * vec2(sin(ps.tailBend + wag), cos(ps.tailBend + wag));
        return smoothUnion(capsule(p, base, mid, 0.05), capsule(p, mid, tip, 0.055), 0.03) + dogFluff(p, 0.03);
    }
    if (part == HAUNCHES) {
        // The back legs, folded under the body, with the back paws in front of them.
        float d = ellipse(m - ps.haunch.xy, ps.haunch.zw);
        d = smoothUnion(d, ellipse(m - vec2(ps.hind, 0.035), vec2(0.075, 0.04)), 0.03);
        return d + dogFluff(p, 0.02);
    }
    if (part == TORSO) {
        float breath = 1.0 + ps.breath * sin(t * mix(0.9, 1.6, ps.eyes));
        float d = ellipse(p - ps.torso.xy, ps.torso.zw * vec2(0.86, breath));
        d = smoothUnion(d, ellipse(p - ps.ruff.xy, ps.ruff.zw), 0.06);
        return d + dogFluff(p, 0.022);
    }
    if (part == LEGS) {
        float d = min(capsule(p, ps.legLeft.xy, ps.legLeft.zw, 0.052),
                      capsule(p, ps.legRight.xy, ps.legRight.zw, 0.052));
        return d + dogFluff(p, 0.008);
    }
    if (part == PAWS) {
        float d = min(ellipse(p - ps.pawLeft, vec2(0.075, 0.047)), ellipse(p - ps.pawRight, vec2(0.075, 0.047)));
        return d + dogFluff(p, 0.005);
    }
    vec2 h = headFrame(p, ps, t);
    if (part == EARS) {
        // Long ears hang at the sides of the head. Mirror x, so one shape makes both ears.
        vec2 e = vec2(abs(h.x), h.y);
        return ellipse(rotate(e - vec2(0.205, 0.64), 0.2), vec2(0.085, 0.18)) + dogFluff(h, 0.03);
    }
    if (part == HEAD) {
        float d = ellipse(h - vec2(0.0, 0.765), vec2(0.2, 0.185));
        d = smoothUnion(d, ellipse(h - vec2(0.0, 0.89), vec2(0.15, 0.08)), 0.05);
        return d + dogFluff(h, 0.026);
    }
    // The muzzle and the beard.
    float d = ellipse(h - vec2(0.0, 0.665), vec2(0.105, 0.08));
    d = smoothUnion(d, ellipse(h - vec2(0.0, 0.60), vec2(0.072, 0.055)), 0.03);
    return d + dogFluff(h, 0.016);
}

// The base color of a part at p.
vec3 dogBase(int part, vec2 p, Pose ps, float t) {
    if (part == EARS) return DOG_EAR;
    if (part == MUZZLE) return DOG_CREAM;
    if (part == TORSO) {
        // The chest ruff is lighter.
        vec2 q = (p - ps.ruff.xy + vec2(0.0, 0.05)) / vec2(1.0, 1.4);
        return mix(DOG_COAT, DOG_CREAM, 0.5 * (1.0 - smoothstep(0.0, 0.12, length(q) - 0.08)));
    }
    if (part == PAWS) {
        // Light paws with two grooves between the toes.
        vec2 paw = abs(p.x - ps.pawLeft.x) < abs(p.x - ps.pawRight.x) ? ps.pawLeft : ps.pawRight;
        vec2 q = p - paw;
        float groove = 1.0 - smoothstep(0.004, 0.009, abs(abs(q.x) - 0.024));
        groove *= smoothstep(-0.03, 0.0, q.y) * (1.0 - smoothstep(0.02, 0.035, q.y));
        return mix(mix(DOG_COAT, DOG_CREAM, 0.35), DOG_DEEP, 0.6 * groove);
    }
    if (part == HEAD) {
        // The fringe over the eyes is a little darker.
        vec2 h = headFrame(p, ps, t);
        float y = (h.y - 0.81) / 0.03;
        float brow = exp(-y * y) * smoothstep(0.16, 0.04, abs(abs(h.x) - 0.085));
        return mix(DOG_COAT, DOG_DEEP, 0.3 * brow);
    }
    return DOG_COAT;
}

// The fur color at p, with fleece and light from the top left.
// d is the distance to the edge, n is the direction away from the shape, and fine makes shorter fur.
vec3 dogFur(vec3 base, vec2 p, float d, vec2 n, float fine) {
    // Fleece: each cell is a soft, round ringlet. Its top-left side catches the light,
    // and the space between ringlets is in shade. A slow warp bends the ringlets into waves.
    vec2 q = p * RINGLETS * fine + 1.5 * vec2(noise(p * 6.0), noise(p * 6.0 + 9.1));
    float ringlet = 1.0 - smoothstep(0.1, 0.62, dogCells(q).x);
    float lit = 1.0 - smoothstep(0.05, 0.5, dogCells(q + vec2(0.16, -0.16)).x);
    vec3 color = mix(mix(DOG_DEEP, base, 0.75), base, ringlet);
    color = mix(color, mix(base, DOG_CREAM, 0.7), 0.5 * lit * ringlet);

    // The side of a part that faces the light is bright, and the other side is dark.
    float edge = 1.0 - smoothstep(0.0, 0.06, -d);
    color *= 1.0 + 0.4 * edge * dot(n, normalize(vec2(-0.55, 0.85)));
    // A round part is a little brighter in its middle.
    return color * (0.88 + 0.12 * smoothstep(0.0, 0.1, -d));
}

// Return the dog at p, as a premultiplied color. px is the size of one screen pixel in dog heights.
vec4 dog(vec2 p, float px, float t) {
    Pose ps = poseAt(t);
    float dist[PARTS];
    for (int i = 0; i < PARTS; i++) dist[i] = dogPart(i, p, ps, t);

    vec4 art = vec4(0.0);
    vec2 e = vec2(0.004, 0.0);
    for (int i = 0; i < PARTS; i++) {
        float a = coverage(dist[i], px);
        if (a <= 0.0) continue;
        vec2 n = normalize(vec2(
            dogPart(i, p + e.xy, ps, t) - dogPart(i, p - e.xy, ps, t),
            dogPart(i, p + e.yx, ps, t) - dogPart(i, p - e.yx, ps, t)) + 1e-6);
        float fine = i == LEGS || i == PAWS ? 1.6 : 1.0;
        vec3 color = dogFur(dogBase(i, p, ps, t), p, dist[i], n, fine);

        // Each part in front casts a soft shadow just outside its edge, onto this part.
        for (int j = i + 1; j < PARTS; j++) color *= mix(0.55, 1.0, smoothstep(0.0, 0.035, dist[j]));
        art = over(art, color, a);
    }

    // The face, in the frame of the head.
    vec2 h = headFrame(p, ps, t);
    vec2 m = vec2(abs(h.x), h.y);

    // A small pink tongue under the mouth. A sleeping dog keeps its tongue in.
    float tongue = ellipse(h - vec2(0.0, 0.618), vec2(0.026, 0.02) * ps.eyes);
    art = over(art, DOG_TONGUE, ps.eyes * coverage(tongue, px));

    // The mouth: a short line down from the nose that turns out to each side.
    float mouth = min(capsule(h, vec2(0.0, 0.672), vec2(0.0, 0.645), 0.004),
                      capsule(m, vec2(0.0, 0.645), vec2(0.032, 0.637), 0.004));
    art = over(art, DOG_DEEP * 0.6, 0.8 * coverage(mouth, px));

    // The nose, with a soft shine on its top.
    art = over(art, DOG_NOSE, coverage(ellipse(h - vec2(0.0, 0.69), vec2(0.044, 0.031)), px));
    art = over(art, vec3(0.50, 0.44, 0.42), 0.7 * coverage(ellipse(h - vec2(-0.012, 0.703), vec2(0.015, 0.007)), px));

    // An awake dog blinks about each 5 seconds. A closed eye is a thin, curved line.
    float open = ps.eyes * (fract(t / 4.7) < 0.03 ? 0.0 : 1.0);
    float eye = ellipse(m - vec2(0.08, 0.772 - 0.006 * (1.0 - open)), vec2(0.026, 0.026 * max(open, 0.15)));
    art = over(art, DOG_EYE, coverage(eye, px));
    float glint = length(h - vec2(sign(h.x) * 0.08 - 0.008, 0.781)) - 0.007;
    return over(art, vec3(0.95), smoothstep(0.5, 0.9, open) * coverage(glint, px));
}

// ---- The leaf ------------------------------------------------------------------------------------------

// The center of the leaf, and half of its width, in dog heights.
const float LEAF_X = 0.0;
const float LEAF_HALF = 0.70;

// The height of the lower edge of the leaf at x. sway moves the leaf to the side.
float leafBottom(float x, float sway) {
    float dx = (x - LEAF_X - sway) / LEAF_HALF;
    float k = sqrt(max(1.0 - dx * dx, 0.0));
    return 1.10 + 0.10 * k - 0.12 * dx * dx - 0.02 * abs(sin(x * 22.0));
}

// Return the leaf and its stem at p, as a premultiplied color.
vec4 leaf(vec2 p, float px, float sway) {
    vec4 art = vec4(0.0);

    // The stem goes from the ground up into the leaf, behind the dog.
    float stem = capsule(p, vec2(0.52, 0.0), vec2(0.30 + sway, 1.16), 0.014);
    art = over(art, DOG_VEIN * (0.85 + 0.25 * p.y), coverage(stem, px));

    float dx = (p.x - LEAF_X - sway) / LEAF_HALF;
    if (abs(dx) >= 1.0) return art;

    // The leaf is a dome, and its tips bend down to a point.
    float k = sqrt(1.0 - dx * dx);
    float bottom = leafBottom(p.x, sway);
    float top = bottom + 0.24 * pow(k, 0.8) + 0.004;
    float d = max(p.y - top, bottom - p.y);
    float a = coverage(d, px);
    if (a <= 0.0) return art;

    // The top of the leaf is in the light, and the lower edge is in shade.
    float h = clamp((p.y - bottom) / max(top - bottom, 1e-3), 0.0, 1.0);
    vec3 color = mix(DOG_LEAF * 0.8, DOG_LEAF_LIGHT, h);
    // A center rib, and side ribs that curve down to the edge.
    float rib = abs(dx) * 7.0 - h * 1.5;
    float vein = min(abs(dx * LEAF_HALF) / 0.006, abs(fract(rib) - 0.5) * 2.0 / 0.12);
    color = mix(DOG_VEIN, color, smoothstep(0.6, 1.2, vein));
    return over(art, color, a);
}

// ---- The image -----------------------------------------------------------------------------------------

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    bgImage(fragColor, fragCoord);

    // The art position, in dog heights, from the center of the dog on the ground. y is up.
    // Ghostty puts fragCoord y = 0 at the top.
    vec2 ground = vec2(iResolution.x - DOG_MARGIN.x + DOG_BOX_MIN.x * DOG_SIZE, iResolution.y - DOG_MARGIN.y);
    vec2 p = vec2(fragCoord.x - ground.x, ground.y - fragCoord.y) / DOG_SIZE;
    if (any(lessThan(p, DOG_BOX_MIN)) || any(greaterThan(p, DOG_BOX_MAX))) return;

    float px = 1.0 / DOG_SIZE;
    float t = mod(iTime, 10000.0);
    vec4 term = texture(iChannel0, fragCoord / iResolution.xy);
    float isBg = isBackground(term);

    // The leaf keeps the space under it dry, so the background design fades out there.
    // The edges of the dry space are soft, so a calm design does not show a hard cut.
    float sway = 0.02 * sin(t * 0.7);
    float under = abs(p.x - LEAF_X - sway) / LEAF_HALF;
    float dry = (1.0 - smoothstep(0.55, 0.9, under)) * smoothstep(0.0, 0.1, leafBottom(p.x, sway) - p.y);
    fragColor = mix(fragColor, term, dry);

    // A soft shadow on the ground under the dog.
    vec2 s = vec2(p.x / 0.45, p.y / 0.025);
    float shadow = 0.45 * exp(-dot(s, s)) * isBg;
    fragColor = vec4(0.0, 0.0, 0.0, shadow) + fragColor * (1.0 - shadow);

    // The leaf and the stem, then the dog in front of them.
    vec4 art = leaf(p, px, sway);
    vec4 body = dog(p, px, t);
    art = body + art * (1.0 - body.a);
    if (art.a <= 0.0) return;

    // Draw only on background pixels, so that the terminal text stays clear.
    float k = DOG_STRENGTH * isBg;
    fragColor = art * k + fragColor * (1.0 - art.a * k);
}
