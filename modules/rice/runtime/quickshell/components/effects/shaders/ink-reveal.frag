#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float strength;
    float speed;
    float progress;
    float edgeSoftness;
    float bandStart;
    float bandEnd;
    vec4 tint;
    vec2 resolution;
};

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(41.0, 289.0))) * 45758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
        u.y);
}

void main() {
    vec2 uv = qt_TexCoord0;
    float grain = noise(uv * vec2(13.0, 8.0));
    float field = (uv.x * 0.62 + uv.y * 0.38) + (grain - 0.5) * 0.22;
    float edge = 1.0 - smoothstep(edgeSoftness * 0.30, edgeSoftness, abs(field - progress));
    float wash = (1.0 - smoothstep(progress - 0.14, progress + 0.12, field)) * 0.10;
    float alpha = max(edge, wash) * strength * qt_Opacity;
    fragColor = vec4(tint.rgb * alpha, alpha);
}
