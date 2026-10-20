#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 region;   // x, y, largura, altura do cartao dentro da textura desfocada (0..1)
    vec4 tint;     // cor do cartao (rgb) e quanto cobre (a)
    vec2 size;     // tamanho do cartao em pixels
    float radius;  // raio dos cantos em pixels
};
layout(binding = 1) uniform sampler2D source;
void main() {
    vec2 p = (qt_TexCoord0 - 0.5) * size;
    vec2 q = abs(p) - (size * 0.5 - vec2(radius));
    float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
    float m = clamp(0.5 - d, 0.0, 1.0);       // borda suave de 1 px nos cantos
    vec3 wall = texture(source, region.xy + qt_TexCoord0 * region.zw).rgb;
    vec3 c = mix(wall, tint.rgb, tint.a);
    fragColor = vec4(c * m, m) * qt_Opacity;
}
