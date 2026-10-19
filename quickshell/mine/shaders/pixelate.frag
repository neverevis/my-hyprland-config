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
    float k = 1.0 - abs(progress * 2.0 - 1.0);       // 0 -> 1 -> 0
    // blocos em degraus (cada degrau dobra o tamanho): fica claramente pixelado, nao serrilhado
    float level = floor(pow(k, 0.7) * 5.0);           // 0..5
    float cells = 220.0 / pow(2.0, level);            // 220, 110, 55, 27, 14, 7 blocos na altura
    vec2 grid = vec2(cells * aspect, cells);
    vec2 q = level > 0.0 ? (floor(uv * grid) + 0.5) / grid : uv;
    float t = smoothstep(0.42, 0.58, progress);
    fragColor = mix(texture(src1, q), texture(src2, q), t) * qt_Opacity;
}
