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
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 4; ++i) {
        value += amp * noise(p);
        p = p * 2.07 + vec2(11.3, 7.1);
        amp *= 0.5;
    }
    return value;
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 centered = uv - vec2(0.5);
    float aspect = resolution.x / max(1.0, resolution.y);
    centered.x *= aspect;

    float vignette = smoothstep(0.18, 0.78, length(centered));
    float slow = time * speed;
    float mist = fbm(uv * vec2(2.6, 1.5) + vec2(slow * 0.018, -slow * 0.010));
    float rays = pow(max(0.0, sin((uv.x + uv.y * 0.22 + slow * 0.018) * 18.0)), 18.0);
    float grain = noise(uv * resolution.xy * 0.55 + slow * 8.0);
    float bloom = smoothstep(0.55, 0.0, length(centered - vec2(0.0, -0.08))) * progress;

    vec3 deep = vec3(0.0, 0.018, 0.026);
    vec3 color = deep + tint.rgb * (mist * 0.10 + rays * 0.11 + bloom * 0.26);
    float alpha = (vignette * 0.56 + mist * 0.10 + rays * 0.10 + grain * 0.018 + bloom * 0.18) * strength * qt_Opacity;
    fragColor = vec4(color, alpha);
}
