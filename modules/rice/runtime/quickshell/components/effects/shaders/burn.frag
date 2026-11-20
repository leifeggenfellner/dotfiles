#version 440

// Burn-away dissolve (D-082): the source item chars and burns from its
// bottom edge up along a ragged front, behind a glowing ember line.
// progress 0 = whole, 1 = gone.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    vec2 resolution;
    vec4 ember;
    vec4 soot;
};

layout(binding = 1) uniform sampler2D source;

float hash(vec2 point) {
    return fract(sin(dot(point, vec2(113.5, 271.9))) * 41537.1539);
}

float noise(vec2 point) {
    vec2 cell = floor(point);
    vec2 local = fract(point);
    vec2 curve = local * local * (3.0 - 2.0 * local);
    return mix(
        mix(hash(cell), hash(cell + vec2(1.0, 0.0)), curve.x),
        mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), curve.x),
        curve.y);
}

float fbm(vec2 point) {
    float value = 0.0;
    float amplitude = 0.52;
    for (int octave = 0; octave < 4; ++octave) {
        value += amplitude * noise(point);
        point = point * 2.04 + vec2(19.7, 4.3);
        amplitude *= 0.5;
    }
    return value;
}

void main() {
    vec4 color = texture(source, qt_TexCoord0);

    // Where the paper catches: low values burn first. Noise in pixels so
    // the front looks the same on any size; the bottom edge goes first.
    float paper = fbm(qt_TexCoord0 * resolution / 30.0) * 0.4 + (1.0 - qt_TexCoord0.y) * 0.6;
    float front = progress * 1.15 - 0.05;

    float whole = smoothstep(front, front + 0.04, paper);
    float glow = smoothstep(front - 0.015, front + 0.02, paper) * (1.0 - smoothstep(front + 0.02, front + 0.09, paper));
    float scorch = 1.0 - smoothstep(front + 0.04, front + 0.16, paper);

    vec3 rgb = mix(color.rgb, soot.rgb * color.a, scorch * 0.85);
    float alpha = color.a * whole;
    rgb = rgb * whole + ember.rgb * glow * max(color.a, 0.6);
    fragColor = vec4(rgb, max(alpha, glow * 0.9 * color.a)) * qt_Opacity;
}
