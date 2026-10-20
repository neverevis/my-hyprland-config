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
vec4 A(vec2 uv) { return texture(src1, clamp(uv, 0.0, 1.0)); }
vec4 B(vec2 uv) { return texture(src2, clamp(uv, 0.0, 1.0)); }

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 g = floor(vec2(uv.x * aspect, uv.y) * 38.0);
    float h = hash(g);
    float p = progress * 1.3 - 0.15;
    float m = smoothstep(p - 0.08, p + 0.08, h);   // 1 = antigo
    vec2 f = fract(vec2(uv.x * aspect, uv.y) * 38.0) - 0.5;
    float star = smoothstep(0.5, 0.0, abs(f.x) + abs(f.y));   // brilho em losango
    float edge = (1.0 - abs(m - 0.5) * 2.0);
    vec4 c = mix(B(uv), A(uv), m);
    c.rgb += glow.rgb * pow(edge, 3.0) * star * 1.1 * glow.a;
    c.rgb += vec3(1.0) * pow(edge, 8.0) * star * 0.5;
    fragColor = c * qt_Opacity;
}
