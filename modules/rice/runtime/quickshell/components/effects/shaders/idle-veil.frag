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
    vec2 uv = qt_TexCoord0;
    vec2 centered = uv - vec2(0.5);
    float aspect = resolution.x / max(resolution.y, 1.0);
    centered.x *= aspect;

    float distanceFromCenter = length(centered);
    float vignette = smoothstep(0.30, 0.88, distanceFromCenter);
    float risingFog = smoothstep(1.05, 0.08, uv.y + fbm(vec2(uv.x * 2.2, uv.y * 1.4 - time * speed)) * 0.30);
    float pulse = 0.88 + 0.12 * sin(time * 1.7);
    float alpha = progress * strength * qt_Opacity * clamp(0.38 + vignette * 0.78 + risingFog * 0.34, 0.0, 1.0) * pulse;

    vec3 color = mix(tint.rgb, vec3(dot(tint.rgb, vec3(0.299, 0.587, 0.114))), 0.32);
    fragColor = vec4(color * alpha, alpha);
}
