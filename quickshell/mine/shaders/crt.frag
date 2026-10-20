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
    float p = progress;
    vec4 c = vec4(0.0, 0.0, 0.0, 1.0);
    if (p < 0.5) {
        float t = p / 0.5;
        float h = mix(1.0, 0.004, t * t);           // o antigo colapsa numa linha
        float y = (uv.y - 0.5) / h + 0.5;
        if (y >= 0.0 && y <= 1.0) { c = A(vec2(uv.x, y)); c.rgb *= 1.0 + 1.5 * t; }
        float line = smoothstep(0.012, 0.0, abs(uv.y - 0.5)) * smoothstep(0.7, 1.0, t);
        c.rgb += vec3(line);
    } else {
        float t = (p - 0.5) / 0.5;
        float h = mix(0.004, 1.0, 1.0 - (1.0 - t) * (1.0 - t));   // o novo abre da linha
        float y = (uv.y - 0.5) / h + 0.5;
        if (y >= 0.0 && y <= 1.0) { c = B(vec2(uv.x, y)); c.rgb *= 1.0 + 1.2 * (1.0 - t); }
        float line = smoothstep(0.012, 0.0, abs(uv.y - 0.5)) * (1.0 - t);
        c.rgb += vec3(line);
    }
    c.rgb *= 0.92 + 0.08 * sin(uv.y * 900.0);       // linhas de varredura
    fragColor = c * qt_Opacity;
}
