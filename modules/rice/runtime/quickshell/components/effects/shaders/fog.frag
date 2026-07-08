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
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
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

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; ++i) {
        v += a * noise(p);
        p = p * 2.02 + vec2(17.3, 9.1);
        a *= 0.5;
    }
    return v;
}

void main() {
    vec2 uv = qt_TexCoord0;
    float band = smoothstep(bandStart, bandStart + 0.10, uv.y)
        * (1.0 - smoothstep(bandEnd - 0.10, bandEnd, uv.y));
    float floorFade = smoothstep(0.0, 1.0, uv.y);
    vec2 drift = vec2(time * 0.018 * speed, -time * 0.006 * speed);
    float mist = fbm(vec2(uv.x * 2.2, uv.y * 1.35) + drift);
    float veil = smoothstep(0.28, 0.86, mist) * band * mix(0.65, 1.0, floorFade);
    float alpha = veil * strength * qt_Opacity;
    fragColor = vec4(tint.rgb * alpha, alpha);
}
