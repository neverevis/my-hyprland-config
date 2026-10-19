#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float aspect;
    float seed;
    vec4 glow;
};
layout(binding = 1) uniform sampler2D src1;
layout(binding = 2) uniform sampler2D src2;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7)) + seed * 17.0) * 43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) { float v = 0.0, a = 0.5; for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; } return v; }
void main() {
    vec2 uv = qt_TexCoord0;
    vec2 d = (uv - 0.5) * vec2(aspect, 1.0);
    float r = length(d);
    float front = progress * (0.5 * length(vec2(aspect, 1.0)) + 0.25);
    float w = sin((r - front) * 38.0) * exp(-abs(r - front) * 9.0);
    vec2 dir = r > 0.0001 ? d / r : vec2(0.0);
    vec2 off = dir * w * 0.022 * (1.0 - progress * 0.6) / vec2(aspect, 1.0);
    float m = smoothstep(front - 0.05, front + 0.05, r);     // 1 = fora da frente (antiga)
    vec4 a = texture(src1, uv + off), b = texture(src2, uv + off * 0.6);
    vec4 c = mix(b, a, m);
    c.rgb += glow.rgb * max(0.0, w) * 0.25 * glow.a * (1.0 - progress);
    fragColor = c * qt_Opacity;
}
