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
    float n = 12.0;
    float i = floor(uv.y * n);
    float dir = mod(i, 2.0) < 1.0 ? 1.0 : -1.0;
    float delay = i / n * 0.3;
    float t = clamp((progress - delay) / 0.7, 0.0, 1.0);
    t = t * t * (3.0 - 2.0 * t);
    float x = dir > 0.0 ? uv.x : 1.0 - uv.x;   // as listras entram de lados opostos
    float m = step(x, t);
    fragColor = mix(A(uv), B(uv), m) * qt_Opacity;
}
