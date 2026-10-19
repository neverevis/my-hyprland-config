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
    float k = sin(progress * 3.14159265);
    // gira forte no centro e nada perto das bordas (senao a imagem girada sai da tela e estica faixas)
    float ang = k * 2.2 * smoothstep(0.62, 0.0, r);
    float s = sin(ang), co = cos(ang);
    vec2 rd = vec2(d.x * co - d.y * s, d.x * s + d.y * co);
    vec2 q = clamp(rd / vec2(aspect, 1.0) + 0.5, 0.0, 1.0);
    float t = smoothstep(0.3, 0.7, progress);
    fragColor = mix(texture(src1, q), texture(src2, q), t) * qt_Opacity;
}
