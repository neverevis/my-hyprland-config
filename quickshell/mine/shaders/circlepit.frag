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
    vec2 d = (uv - 0.5) * vec2(aspect, 1.0);
    float R = progress * length(vec2(aspect, 1.0)) * 0.55;
    float r = length(d);
    // o novo aparece dentro do buraco, vindo de um pouco mais perto; o antigo e puxado para dentro
    vec2 nu = 0.5 + (uv - 0.5) * (0.8 + 0.2 * progress);
    vec2 ou = 0.5 + (uv - 0.5) * (1.0 - 0.15 * progress * smoothstep(R * 1.4, R, r));
    float m = smoothstep(R, R - 0.012, r);
    float rim = smoothstep(0.03, 0.0, abs(r - R)) * (1.0 - progress * 0.6);
    vec4 c = mix(A(ou), B(nu), m);
    c.rgb = mix(c.rgb, c.rgb * 0.45, rim * 0.6) + glow.rgb * rim * 0.12 * glow.a;
    fragColor = c * qt_Opacity;
}
