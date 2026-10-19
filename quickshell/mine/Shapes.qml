// Formas para recortar imagens e desenhar fundos (Flower.qml usa): pontos de um contorno fechado num quadrado de lado
// 2 (x e y de -1 a 1, y para baixo). Inspiradas nas formas do Material 3 (as do end4), feitas aqui por formula:
// curvas polares, poligonos com cantos arredondados e alguns desenhos (coracao, arco, fantasminha, pixel).
// list: [id, rotulo, icone] para os menus; pts(id) devolve [[x, y], ...].
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root
    readonly property var list: [
        ["rounded", "Arredondada", "squareRounded"], ["circle", "Círculo", "circleOutline"], ["flower", "Flor", "flowerOutline"], ["square", "Quadrada", "crop"],
        ["oval", "Oval", "circleOutline"], ["pill", "Pílula", "squareRounded"], ["heart", "Coração", "sparkle"], ["clover4", "Trevo", "flowerOutline"],
        ["clover8", "Trevo de 8", "flowerOutline"], ["sunny", "Sol", "sun"], ["burst", "Explosão", "star4"], ["softburst", "Explosão suave", "star4"],
        ["puffy", "Nuvem", "cloudSun"], ["gem", "Gema", "hexagon"], ["triangle", "Triângulo", "shape"], ["diamond", "Losango", "shape"],
        ["pentagon", "Pentágono", "hexagon"], ["slanted", "Inclinada", "shape"], ["arch", "Arco", "shape"], ["semicircle", "Meio círculo", "circleOutline"],
        ["ghost", "Fantasminha", "emoticon"], ["pixel", "Pixel", "grid"]
    ]
    // as que o Flower desenha com Rectangle (preenchem o retangulo inteiro)
    function isBox(id) { return id === "rounded" || id === "square" || id === "circle" }

    function polar(f, n) { const o = []; n = n || 240; for (let i = 0; i < n; i++) { const t = i / n * Math.PI * 2, r = f(t); o.push([r * Math.sin(t), -r * Math.cos(t)]) } return o }
    // poligono com cantos arredondados: cada canto vira uma curva entre pontos a k do caminho nas duas arestas
    function roundPoly(v, k) {
        const o = [], n = v.length
        for (let i = 0; i < n; i++) {
            const p = v[(i + n - 1) % n], c = v[i], q = v[(i + 1) % n]
            const a = [c[0] + (p[0] - c[0]) * k, c[1] + (p[1] - c[1]) * k], b = [c[0] + (q[0] - c[0]) * k, c[1] + (q[1] - c[1]) * k]
            for (let s = 0; s <= 10; s++) { const t = s / 10, u = 1 - t; o.push([u * u * a[0] + 2 * u * t * c[0] + t * t * b[0], u * u * a[1] + 2 * u * t * c[1] + t * t * b[1]]) }
        }
        return o
    }
    function regular(n, rot, sx, sy) { const v = []; for (let i = 0; i < n; i++) { const t = rot + i / n * Math.PI * 2; v.push([Math.sin(t) * (sx || 1), -Math.cos(t) * (sy || 1)]) } return v }
    // encaixa no quadrado [-1, 1] mantendo a proporcao e centralizando
    function fit(p) {
        let x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9
        for (const q of p) { x0 = Math.min(x0, q[0]); x1 = Math.max(x1, q[0]); y0 = Math.min(y0, q[1]); y1 = Math.max(y1, q[1]) }
        const s = 2 / Math.max(x1 - x0, y1 - y0), cx = (x0 + x1) / 2, cy = (y0 + y1) / 2
        return p.map(q => [(q[0] - cx) * s, (q[1] - cy) * s])
    }
    function arc(cx, cy, r, a0, a1, n) { const o = []; for (let i = 0; i <= n; i++) { const t = a0 + (a1 - a0) * i / n; o.push([cx + r * Math.cos(t), cy + r * Math.sin(t)]) } return o }

    function pts(id, sides, depth) {
        const k = Math.max(0, sides ?? 12), d = depth ?? 0.11
        switch (id) {
        case "flower": return polar(t => k === 0 ? 1 : 1 - d * (1 - Math.cos(k * t)) / 2)
        case "oval": return fit(polar(t => 1).map(q => [q[0], q[1] * 0.74]))
        case "pill": return fit(arc(0.45, 0, 0.55, -Math.PI / 2, Math.PI / 2, 40).concat(arc(-0.45, 0, 0.55, Math.PI / 2, Math.PI * 1.5, 40)))
        case "heart": {
            const o = []
            for (let i = 0; i < 240; i++) { const t = i / 240 * Math.PI * 2; o.push([16 * Math.pow(Math.sin(t), 3), -(13 * Math.cos(t) - 5 * Math.cos(2 * t) - 2 * Math.cos(3 * t) - Math.cos(4 * t))]) }
            return fit(o)
        }
        case "clover4": return polar(t => 0.62 + 0.38 * Math.pow(Math.abs(Math.cos(2 * t)), 0.55))
        case "clover8": return polar(t => 0.74 + 0.26 * Math.pow(Math.abs(Math.cos(4 * t)), 0.6))
        case "sunny": return polar(t => 0.9 + 0.1 * Math.cos(8 * t))
        case "burst": return polar(t => { const f = (t / (Math.PI * 2) * 12) % 1; return 0.76 + 0.24 * (1 - 2 * Math.abs(f - 0.5)) }, 480)
        case "softburst": return polar(t => 0.84 + 0.16 * Math.cos(10 * t))
        case "puffy": return polar(t => 0.84 + 0.16 * Math.pow(Math.abs(Math.cos(3 * t)), 0.5))
        case "gem": return fit(roundPoly(regular(6, 0, 0.82, 1), 0.22))
        case "triangle": return fit(roundPoly(regular(3, 0), 0.24))
        case "diamond": return fit(roundPoly(regular(4, 0, 0.82, 1), 0.2))
        case "pentagon": return fit(roundPoly(regular(5, 0), 0.22))
        case "slanted": return fit(roundPoly([[-0.6, -0.85], [1, -0.85], [0.6, 0.85], [-1, 0.85]], 0.18))
        case "arch": return fit(arc(0, -0.1, 0.9, Math.PI, Math.PI * 2, 60).concat([[0.9, 0.82], [0.86, 0.92], [0.78, 0.95], [-0.78, 0.95], [-0.86, 0.92], [-0.9, 0.82]]))
        case "semicircle": return fit(arc(0, 0.5, 1, Math.PI, Math.PI * 2, 80).concat([[0.96, 0.5], [-0.96, 0.5]]))
        case "ghost": {
            const o = arc(0, -0.15, 0.85, Math.PI, Math.PI * 2, 60)
            for (let i = 0; i <= 60; i++) { const x = 0.85 - 1.7 * i / 60; o.push([x, 0.85 - 0.12 * (1 - Math.cos(x / 1.7 * Math.PI * 2 * 3)) / 2]) }
            return fit(o)
        }
        case "pixel": {
            // circulo em degraus numa grade de 10: lado direito descendo, esquerdo subindo
            const N = 10, h = 2 / N, xs = [], o = []
            for (let r = 0; r < N; r++) { const yc = -1 + h * (r + 0.5); xs.push(Math.max(h, Math.round(Math.sqrt(Math.max(0, 1 - yc * yc)) / h) * h)) }
            for (let r = 0; r < N; r++) o.push([xs[r], -1 + h * r], [xs[r], -1 + h * (r + 1)])
            for (let r = N - 1; r >= 0; r--) o.push([-xs[r], -1 + h * (r + 1)], [-xs[r], -1 + h * r])
            return o
        }
        default: return polar(t => 1)
        }
    }
}
