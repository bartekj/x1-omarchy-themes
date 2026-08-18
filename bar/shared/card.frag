#version 440

// X1 bar card frames.
//
// Shaded treatments of one rounded rectangle:
//   uStyle 0  lens     convex glass bead — soft dome, wide lit shoulder
//   uStyle 1  emboss   stamped plate — narrow crisp bevel, flat graded face
//   uStyle 2  dome     glass lozenge — full-height shoulder plus a gloss band
//
// Different shapes entirely — these change the silhouette, not the lighting:
//   uStyle 3  bracket  no surface; machined end caps, [ readout ]
//   uStyle 4  rail     no enclosure; an accent bar under the row
//   uStyle 5  chamfer  octagonal cut-corner plate with a hairline edge
//   uStyle 6  inset    a well carved into the bar — concave, not convex
//   uStyle 7  blade    square accent edge left, rounded right; directional
//
// bloom and flat are not here — bloom's halo spills outside the item's bounds
// and takes its colour from live load, so both live in CardFrame.qml.
//
// Every branch is on uStyle, which is a uniform, so control flow stays uniform
// across the quad and derivatives (fwidth) are legal inside the branches. A
// per-fragment early-out before them would not be.
//
// Source of truth: bar/shared/card.frag. Compiled to card.frag.qsb and
// copied into each plugin by tools/build-plugin-shared — do not edit the copies.
//
// Qt6 binds uniforms to ShaderEffect properties BY NAME via the reflection
// data in the .qsb. A name that does not match a QML property is silently
// left at zero, so every name below has a counterpart in CardFrame.qml.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    vec2  uSize;      // item size in px
    vec4  uTint;      // body colour (passed opaque, see uFill)
    vec4  uRim;       // rim + specular colour (passed opaque)
    vec4  uAccent;    // theme accent, for rail and blade (passed opaque)
    vec2  uLight;     // light direction in xy
    float uRadius;    // corner radius, px
    float uBulge;     // shoulder / chamfer / arm size, px
    float uFill;      // base fill alpha
    float uSpec;      // specular strength
    float uRimGain;   // fresnel strength
    int   uStyle;
};

// https://iquilezles.org/articles/distfunctions2d/ — negative inside.
float sdRoundRect(vec2 p, vec2 hs, float r) {
    vec2 q = abs(p) - (hs - vec2(r));
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// Same box with its corners cut at 45 degrees instead of rounded.
float sdChamferRect(vec2 p, vec2 hs, float c) {
    vec2 q = abs(p);
    float box = max(q.x - hs.x, q.y - hs.y);
    float diag = (q.x + q.y - (hs.x + hs.y - c)) * 0.70710678;
    return max(box, diag);
}

// Outward unit normal of the rounded rect, solved analytically.
//
// Taking this from screen-space derivatives instead (dFdx/dFdy of the
// distance) silently flips the lighting top-for-bottom, because dFdy's sign
// follows the render target's orientation rather than the texture
// coordinate's. Solving it here keeps "up" meaning up on every backend.
vec2 sdRoundRectGrad(vec2 p, vec2 hs, float r) {
    vec2 sgn = sign(p);
    vec2 q = abs(p) - (hs - vec2(r));
    if (max(q.x, q.y) > 0.0) {
        // Rounded corner or beyond an edge: away from the nearest arc centre.
        return normalize(max(q, vec2(0.0))) * sgn;
    }
    // Inside the inner rect: toward whichever edge is closest.
    return q.x > q.y ? vec2(sgn.x, 0.0) : vec2(0.0, sgn.y);
}

void main() {
    vec2 hs = uSize * 0.5;
    vec2 p = (qt_TexCoord0 - 0.5) * uSize;
    float r = clamp(uRadius, 0.0, min(hs.x, hs.y));

    // Vertical position, 0 at the top edge. Confirmed against the rendered
    // result, not assumed: with the analytic gradient the highlight lands on
    // the top edge for a light pointing up-left.
    float v = qt_TexCoord0.y;
    vec3 L = normalize(vec3(uLight, 0.85));

    vec3 rgb = uTint.rgb;
    float a = 0.0;

    if (uStyle == 3) {
        // Bracket: the card has no surface at all. Only the two end caps of
        // the outline survive, so the readout sits inside [ ] the way a
        // viewfinder crops a frame. Nothing to compete with the wallpaper.
        float d = sdRoundRect(p, hs, r);
        float aa = max(fwidth(d), 0.0001);
        float ring = 1.0 - smoothstep(1.1 - aa, 1.1 + aa, abs(d));
        float arm = min(max(uBulge, 2.0) * 2.5, hs.x * 0.45);
        float cap = smoothstep(hs.x - arm - 1.5, hs.x - arm + 1.5, abs(p.x));
        rgb = uTint.rgb;
        a = ring * cap * 0.75;

    } else if (uStyle == 4) {
        // Rail: no enclosure either — a single bar under the row, running
        // from the theme accent into the bar foreground. Reads as an
        // underline, not a container.
        float th = max(2.0, uBulge * 0.5);
        vec2 rp = vec2(p.x, p.y - (hs.y - th * 0.5));
        float d = sdRoundRect(rp, vec2(hs.x, th * 0.5), th * 0.5);
        float aa = max(fwidth(d), 0.0001);
        float cover = 1.0 - smoothstep(-aa, aa, d);
        rgb = mix(uAccent.rgb, uTint.rgb, qt_TexCoord0.x);
        a = cover * 0.8;

    } else if (uStyle == 5) {
        // Chamfer: corners cut at 45 rather than rounded, so the silhouette
        // itself is the character — a machined plate, not a pill.
        //
        // The cut is derived from the card's height rather than uBulge: that
        // knob is sized for the lens shoulder (~4px), and at 4px on a 30px
        // card the chamfer is indistinguishable from a rounded corner. Off
        // the height it reads correctly at any bar size or font scale.
        float c = clamp(hs.y * 0.6, 2.0, min(hs.x, hs.y));
        float d = sdChamferRect(p, hs, c);
        float aa = max(fwidth(d), 0.0001);
        float cover = 1.0 - smoothstep(-aa, aa, d);
        float edge = 1.0 - smoothstep(0.9 - aa, 0.9 + aa, abs(d));
        float face = (0.5 - v) * 0.18;
        rgb = uTint.rgb * (1.0 + face);
        a = cover * uFill * (1.0 + face) + edge * 0.5;

    } else if (uStyle == 6) {
        // Inset: the inverse of every style above — the card is a well cut
        // into the bar. A dark band along the top inner edge is the shadow
        // the rim above casts into it, a light band along the bottom is the
        // far wall catching the same light. Concave, so it recedes.
        float d = sdRoundRect(p, hs, r);
        float aa = max(fwidth(d), 0.0001);
        float cover = 1.0 - smoothstep(-aa, aa, d);
        vec2 g = sdRoundRectGrad(p, hs, r);
        float band = 1.0 - clamp(-d / max(uBulge, 0.001), 0.0, 1.0);

        // g points outward, so g.y is negative on the top edge and positive
        // on the bottom one.
        float shadow = max(0.0, -g.y) * band;
        float lit    = max(0.0,  g.y) * band;

        rgb = mix(uTint.rgb, vec3(0.0), shadow * 0.9);
        a = cover * uFill * 0.85 + shadow * 0.40 + lit * 0.22;

    } else if (uStyle == 7) {
        // Blade: square on the left with a solid accent edge, rounded on the
        // right. Asymmetry gives the card a reading direction, the way a
        // labelled callout does.
        float rSel = p.x > 0.0 ? r : 0.0;
        vec2 q = abs(p) - (hs - vec2(rSel));
        float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - rSel;
        float aa = max(fwidth(d), 0.0001);
        float cover = 1.0 - smoothstep(-aa, aa, d);
        float bar = 1.0 - smoothstep(2.6 - aa, 2.6 + aa, p.x + hs.x);
        float top = 1.0 - smoothstep(0.9 - aa, 0.9 + aa, abs(d));
        rgb = mix(uTint.rgb, uAccent.rgb, bar);
        a = cover * uFill + bar * 0.85 + top * 0.18 * (1.0 - bar);

    } else if (uStyle == 1) {
        // Emboss: a plate stamped out of the bar. The bevel is deliberately
        // narrow and steep — a wide soft shoulder here would just be the lens
        // again. Character comes from the crisp lit top edge, the dark
        // recessed bottom edge, and a gently graded face between them.
        float d = sdRoundRect(p, hs, r);
        float aa = max(fwidth(d), 0.0001);
        float cover = 1.0 - smoothstep(-aa, aa, d);
        float bevel = clamp(-d / 1.6, 0.0, 1.0);
        float bk = 1.0 - bevel;
        vec2 g = sdRoundRectGrad(p, hs, r);
        vec3 n = normalize(vec3(g * bk * 2.6, 1.0));

        float diff = max(dot(n, L), 0.0);
        float spec = pow(diff, 10.0) * uSpec;
        float fres = pow(1.0 - n.z, 2.0) * uRimGain * 0.6;
        float edge = (diff - 0.5) * 0.9 * bk;
        float face = (0.5 - v) * 0.30;

        rgb = uTint.rgb * (1.0 + edge + face) + uRim.rgb * spec;
        a = cover * (uFill * (1.0 + face * 1.6 + edge * 1.4) + spec * 0.55 + fres * 0.25);

    } else if (uStyle == 2) {
        // Dome: a glass lozenge. The shoulder spans the full half-height, so
        // the whole card is curve with no flat plateau, and a gloss band
        // across the top sells it as glass rather than plastic.
        float d = sdRoundRect(p, hs, r);
        float aa = max(fwidth(d), 0.0001);
        float cover = 1.0 - smoothstep(-aa, aa, d);
        float t = clamp(-d / max(hs.y, 0.001), 0.0, 1.0);
        float k = 1.0 - t;
        vec2 g = sdRoundRectGrad(p, hs, r);
        vec3 n = normalize(vec3(g * k * 1.7, 1.0));

        float diff = max(dot(n, L), 0.0);
        float spec = pow(diff, 8.0) * uSpec;
        float fres = pow(1.0 - n.z, 2.2) * uRimGain;
        float gloss = pow(max(0.0, 1.0 - v / 0.52), 1.6);
        float shade = (diff - 0.5) * 0.45;

        rgb = uTint.rgb * (1.0 + shade) + uRim.rgb * (spec + gloss * 0.55 + fres * 0.35);
        a = cover * (uFill * (1.0 + shade) + spec * 0.40 + gloss * 0.16 + fres * 0.35);

    } else {
        // Lens: height field is 0 at the rim, 1 across the plateau. The slope
        // is linear in k, i.e. a spherical cap rather than a quarter circle —
        // a quarter circle stands vertical at the rim and is already flat by
        // mid-shoulder, which crushes all the shading into a two-pixel band
        // and reads as a drawn outline instead of a dome.
        float d = sdRoundRect(p, hs, r);
        float aa = max(fwidth(d), 0.0001);
        float cover = 1.0 - smoothstep(-aa, aa, d);
        float t = clamp(-d / max(uBulge, 0.001), 0.0, 1.0);
        float k = 1.0 - t;
        vec2 g = sdRoundRectGrad(p, hs, r);
        vec3 n = normalize(vec3(g * k * 1.5, 1.0));

        float diff = max(dot(n, L), 0.0);
        float spec = pow(diff, 16.0) * uSpec;
        float fres = pow(1.0 - n.z, 2.0) * uRimGain;
        float shade = (diff - 0.5) * 0.5;

        rgb = uTint.rgb * (1.0 + shade) + uRim.rgb * (spec + fres * 0.4);
        a = cover * (uFill * (1.0 + shade * 1.2) + spec * 0.6 + fres * 0.4);
    }

    a = clamp(a, 0.0, 1.0);

    // Qt Quick composites premultiplied.
    fragColor = vec4(rgb * a, a) * qt_Opacity;
}
