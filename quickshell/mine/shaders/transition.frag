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
    // varredura diagonal com borda suave, o novo entra com um leve zoom
    float s = (uv.x * aspect + (1.0 - uv.y)) / (aspect + 1.0);
    float p = progress * 1.3 - 0.15;
    float m = smoothstep(p - 0.15, p + 0.15, s);   // 1 = antigo
    vec2 nu = 0.5 + (uv - 0.5) * (0.92 + 0.08 * progress);
    fragColor = mix(B(nu), A(uv), m) * qt_Opacity;
}
