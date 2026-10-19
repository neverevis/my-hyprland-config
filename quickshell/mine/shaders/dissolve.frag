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
    float n = fbm(vec2(uv.x * aspect, uv.y) * 3.2);
    float p = progress * 1.2 - 0.1;
    float e = 0.12;
    float m = smoothstep(p - e, p + e, n);          // 1 = ainda antiga
    float edge = 1.0 - abs(m - 0.5) * 2.0;           // pico na borda
    vec4 a = texture(src1, uv), b = texture(src2, uv);
    vec4 c = mix(b, a, m);
    c.rgb += glow.rgb * pow(edge, 4.0) * 0.45 * glow.a;
    fragColor = c * qt_Opacity;
}
