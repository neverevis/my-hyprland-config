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
    vec2 p = vec2(uv.x * aspect, uv.y) * 7.0;
    vec2 id = floor(p);
    // cada celula e um caco: cai girando com atraso proprio e revela o novo
    float best = 10.0, bid = 0.0; vec2 bc = vec2(0.0);
    for (int j = -1; j <= 1; j++) for (int i = -1; i <= 1; i++) {
        vec2 c = id + vec2(float(i), float(j));
        vec2 pt = c + vec2(hash(c), hash(c + 3.7));
        float d = length(p - pt);
        if (d < best) { best = d; bid = hash(c + 9.1); bc = pt; }
    }
    float t = clamp((progress * 1.6 - bid * 0.6) / 1.0, 0.0, 1.0);
    vec2 rel = (p - bc);
    float ang = t * (bid - 0.5) * 3.0;
    float s = sin(ang), co = cos(ang);
    vec2 q = bc + vec2(rel.x * co + rel.y * s, -rel.x * s + rel.y * co);
    q.y -= t * t * 5.0;                        // cai
    vec2 su = vec2(q.x / aspect, q.y) / 7.0;
    bool inside = su.y >= 0.0 && su.y <= 1.0 && su.x >= 0.0 && su.x <= 1.0;
    vec4 a = inside ? A(su) : vec4(0.0);
    float edge = smoothstep(0.0, 0.06, best) * 0.0;
    a.a *= (1.0 - t);
    vec4 c = B(uv);
    c = mix(c, vec4(a.rgb, 1.0), a.a * (inside ? 1.0 : 0.0));
    fragColor = c * qt_Opacity;
}
