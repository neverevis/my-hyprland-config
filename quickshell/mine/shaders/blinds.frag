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
    float diag = (uv.x * aspect + uv.y) / (aspect + 1.0);
    float n = 14.0;
    float idx = floor(diag * n), f = fract(diag * n);
    float delay = idx / n * 0.55;
    float lp = clamp((progress - delay) / 0.45, 0.0, 1.0);
    lp = lp * lp * (3.0 - 2.0 * lp);
    float m = step(f, lp);                           // a faixa vai sendo preenchida pela nova
    float front = (lp > 0.0 && lp < 1.0) ? 1.0 - smoothstep(0.0, 0.05, abs(f - lp)) : 0.0;
    vec4 c = mix(texture(src1, uv), texture(src2, uv), m);
    c.rgb += glow.rgb * 0.35 * glow.a * front;
    fragColor = c * qt_Opacity;
}
