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
    // dobra diagonal que varre do canto inferior direito para o superior esquerdo
    vec2 dir = normalize(vec2(-aspect, -1.0));
    float len = aspect + 1.0;
    float s = dot((uv - vec2(1.0)) * vec2(aspect, 1.0), -dir) ;   // distancia ao canto
    float line = progress * len * 1.15 - 0.1;
    float x = s - line;                       // >0 ainda antigo
    float R = 0.07;                           // raio do rolo
    vec4 c;
    if (x > R) {
        c = A(uv);
    } else if (x > 0.0) {
        // o rolo: faixa do antigo deslocada (curvatura) com brilho de cilindro
        float k = x / R;
        c = A(uv + (-dir) * vec2(1.0 / aspect, 1.0) * (R - x) * 0.6);
        c.rgb *= 0.7 + 0.5 * sin(k * 3.14159265);
    } else {
        c = B(uv);
        // sombra do rolo sobre o novo
        c.rgb *= 1.0 - 0.4 * smoothstep(0.12, 0.0, -x);
    }
    fragColor = c * qt_Opacity;
}
