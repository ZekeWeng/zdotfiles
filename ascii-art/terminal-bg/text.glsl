// Text
//
// Text in the top-right corner, drawn with a 5 x 7 pixel font.
// A design names its text in a line such as "// @TEXT: NIGHT SKY", and "|" starts a new line.
// termbg.sh renames mainImage of the design to textBgImage, adds this file after it,
// and puts the text in TEXT.

// The size of one font pixel, in screen pixels.
const float TEXT_PIXEL = 3.0;
// The space from the top-right corner of the window to the text, in screen pixels.
const vec2 TEXT_MARGIN = vec2(28.0, 20.0);
// The strength of the text over the background. 0 hides it.
const float TEXT_STRENGTH = 0.6;
// The color of the text.
const vec3 TEXT_COLOR = vec3(0.933, 0.941, 0.973);

// The ASCII codes of the text, as const int TEXT[96]. 10 starts a new line, and 0 ends the text.
// termbg.sh puts the array in place of the next line.
// @TEXT@

// Return the 5 x 7 glyph of the ASCII code c. Bit row * 5 + column is on, from the top-left pixel.
// x holds rows 0 to 5, and y holds row 6. "*" is the degree sign. A code with no glyph is empty.
uvec2 textGlyph(int c) {
    if (c == 65) return uvec2(0x231fc62eu, 0x11u); // A
    if (c == 66) return uvec2(0x2317c62fu, 0x0fu); // B
    if (c == 67) return uvec2(0x2210862eu, 0x0eu); // C
    if (c == 68) return uvec2(0x2318c62fu, 0x0fu); // D
    if (c == 69) return uvec2(0x0217843fu, 0x1fu); // E
    if (c == 70) return uvec2(0x0217843fu, 0x01u); // F
    if (c == 71) return uvec2(0x231e862eu, 0x1eu); // G
    if (c == 72) return uvec2(0x231fc631u, 0x11u); // H
    if (c == 73) return uvec2(0x0842108eu, 0x0eu); // I
    if (c == 74) return uvec2(0x1284211cu, 0x06u); // J
    if (c == 75) return uvec2(0x12519531u, 0x11u); // K
    if (c == 76) return uvec2(0x02108421u, 0x1fu); // L
    if (c == 77) return uvec2(0x231ad771u, 0x11u); // M
    if (c == 78) return uvec2(0x239ace31u, 0x11u); // N
    if (c == 79) return uvec2(0x2318c62eu, 0x0eu); // O
    if (c == 80) return uvec2(0x0217c62fu, 0x01u); // P
    if (c == 81) return uvec2(0x1358c62eu, 0x16u); // Q
    if (c == 82) return uvec2(0x1257c62fu, 0x11u); // R
    if (c == 83) return uvec2(0x2107043eu, 0x0fu); // S
    if (c == 84) return uvec2(0x0842109fu, 0x04u); // T
    if (c == 85) return uvec2(0x2318c631u, 0x0eu); // U
    if (c == 86) return uvec2(0x1518c631u, 0x04u); // V
    if (c == 87) return uvec2(0x2b5ac631u, 0x0au); // W
    if (c == 88) return uvec2(0x22a22a31u, 0x11u); // X
    if (c == 89) return uvec2(0x08422a31u, 0x04u); // Y
    if (c == 90) return uvec2(0x0222221fu, 0x1fu); // Z
    if (c == 48) return uvec2(0x233ae62eu, 0x0eu); // 0
    if (c == 49) return uvec2(0x084210c4u, 0x0eu); // 1
    if (c == 50) return uvec2(0x0444422eu, 0x1fu); // 2
    if (c == 51) return uvec2(0x2304111fu, 0x0eu); // 3
    if (c == 52) return uvec2(0x11f4a988u, 0x08u); // 4
    if (c == 53) return uvec2(0x23083c3fu, 0x0eu); // 5
    if (c == 54) return uvec2(0x2317844cu, 0x0eu); // 6
    if (c == 55) return uvec2(0x0422221fu, 0x02u); // 7
    if (c == 56) return uvec2(0x2317462eu, 0x0eu); // 8
    if (c == 57) return uvec2(0x110f462eu, 0x06u); // 9
    if (c == 46) return uvec2(0x0c000000u, 0x06u); // .
    if (c == 37) return uvec2(0x32222263u, 0x18u); // %
    if (c == 58) return uvec2(0x0c6018c0u, 0x00u); // :
    if (c == 47) return uvec2(0x02222200u, 0x00u); // /
    if (c == 45) return uvec2(0x000f8000u, 0x00u); // -
    if (c == 42) return uvec2(0x00032526u, 0x00u); // *
    return uvec2(0u);
}

// Return true if the text has a pixel on at frag.
// Each line is right-aligned. Each character is 5 pixels wide with 1 pixel of space,
// and each line is 7 pixels high with 3 pixels of space.
bool textOn(vec2 frag) {
    // x counts the font pixels to the left from the right edge. y counts down from the top.
    // Ghostty puts fragCoord y = 0 at the top.
    float x = (iResolution.x - TEXT_MARGIN.x - frag.x) / TEXT_PIXEL;
    float y = (frag.y - TEXT_MARGIN.y) / TEXT_PIXEL;
    if (x < 0.0 || y < 0.0) return false;
    int line = int(floor(y / 10.0));
    int row = int(floor(y)) - line * 10;
    if (row >= 7) return false;
    int k = int(floor(x / 6.0));
    int col = 4 - (int(floor(x)) - k * 6);
    if (col < 0) return false;

    // Find the start and the length of the line.
    int start = 0;
    int n = 0;
    int found = 0;
    for (int i = 0; i < 96; i++) {
        int c = TEXT[i];
        if (c == 0) break;
        if (c == 10) {
            if (n == line) {
                found = 1;
                break;
            }
            n++;
            start = i + 1;
        }
    }
    if (found == 0 && n != line) return false;
    int end = start;
    for (int i = 0; i < 96; i++) {
        if (i < start) continue;
        int c = TEXT[i];
        if (c == 0 || c == 10) break;
        end = i + 1;
    }
    int index = end - 1 - k;
    if (index < start) return false;

    uvec2 g = textGlyph(TEXT[index]);
    int bit = row * 5 + col;
    uint word = bit < 30 ? g.x : g.y;
    int shift = bit < 30 ? bit : bit - 30;
    return ((word >> uint(shift)) & 1u) == 1u;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    textBgImage(fragColor, fragCoord);
    if (!textOn(fragCoord)) return;
    vec4 term = texture(iChannel0, fragCoord / iResolution.xy);
    float a = TEXT_STRENGTH * isBackground(term);
    fragColor = vec4(TEXT_COLOR * a, a) + fragColor * (1.0 - a);
}
