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
    float k = sin(progress * 3.14159265);
    float band = floor(uv.y * 24.0);
    float tick = floor(progress * 18.0);
    float h = hash(vec2(band, tick));
    float shift = (h - 0.5) * 0.25 * k * step(0.55, hash(vec2(band + 7.0, tick)));
    vec2 u = vec2(uv.x + shift, uv.y);
    float sw = hash(vec2(band * 3.1, tick + 5.0));
    float m = step(sw, progress * 1.1 - 0.02);     // blocos trocam em momentos diferentes
    float ab = 0.012 * k;
    vec4 a = vec4(A(u + vec2(ab, 0)).r, A(u).g, A(u - vec2(ab, 0)).b, 1.0);
    vec4 b = vec4(B(u + vec2(ab, 0)).r, B(u).g, B(u - vec2(ab, 0)).b, 1.0);
    vec4 c = mix(a, b, m);
    c.rgb += (hash(uv * 400.0 + tick) - 0.5) * 0.08 * k;
    fragColor = c * qt_Opacity;
}
