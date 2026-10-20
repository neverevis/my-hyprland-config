.pragma library

.import "m3shapes.js" as M

// Formas do shell: as 35 do Material 3 (m3shapes.js) + as proprias (rounded, square, flower de petalas ajustaveis).
// Coordenadas: quadrado [-1, 1], y para baixo. Angulo t = 0 no topo, sentido horario: direcao (sin t, -cos t).
// Para o morph cada forma vira N raios a partir de um centro (todas as formas daqui sao "estreladas" a partir dele):
// entre duas formas interpola raio a raio (e o centro), com um giro opcional que alinha os lobos (o papel do casamento de
// cantos do Morph do androidx, mas robusto para trocas no meio da animacao e para a flor de petalas variaveis).
// Tudo fica em cache (biblioteca compartilhada por todos os Flower): nada e recalculado com a forma parada.

var N = 360

var m3 = {}
for (const id of M.ids) m3[id] = true
// ids antigos do shell; "softsquare" e o Square do M3 (o "square" do shell e o quadrado reto, sem recorte)
var alias = { ghost: "ghostish", pixel: "pixelcircle" }
function m3id(id) { return id === "softsquare" ? "square" : id }

function canon(id) {
    id = alias[id] || id
    return (id === "rounded" || id === "square" || id === "flower" || id === "softsquare" || (m3[id] && id !== "square")) ? id : "circle"
}
// desenhadas com Rectangle quando paradas (preenchem o retangulo inteiro)
function isBox(id) { id = canon(id); return id === "rounded" || id === "square" || id === "circle" }

// ---------- contornos ----------
var cubicCache = {}
// cubicas da forma M3 em [-1, 1]: Float64Array com 8 numeros por cubica
function cubics(id) {
    id = canon(id)
    const hit = cubicCache[id]
    if (hit) return hit
    const cs = M.get(m3id(id))
    if (!cs) return null
    const out = new Float64Array(cs.length * 8)
    for (let i = 0; i < cs.length; i++) for (let j = 0; j < 8; j++) out[i * 8 + j] = cs[i][j] * 2 - 1
    cubicCache[id] = out
    return out
}
// cubicas achatadas em pontos (densidade pelo tamanho de cada trecho)
function flatten(cs) {
    const o = []
    for (let i = 0; i < cs.length; i += 8) {
        const x0 = cs[i], y0 = cs[i + 1], x1 = cs[i + 2], y1 = cs[i + 3], x2 = cs[i + 4], y2 = cs[i + 5], x3 = cs[i + 6], y3 = cs[i + 7]
        const len = Math.hypot(x1 - x0, y1 - y0) + Math.hypot(x2 - x1, y2 - y1) + Math.hypot(x3 - x2, y3 - y2)
        const n = Math.max(2, Math.min(64, Math.ceil(len * 48)))
        for (let s = 0; s < n; s++) {
            const t = s / n, u = 1 - t, a = u * u * u, b = 3 * u * u * t, c = 3 * u * t * t, d = t * t * t
            o.push([a * x0 + b * x1 + c * x2 + d * x3, a * y0 + b * y1 + c * y2 + d * y3])
        }
    }
    return o
}
// retangulo com cantos arredondados (meia largura ex, meia altura ey, raio rr), sentido horario
function roundRect(ex, ey, rr) {
    rr = Math.max(0, Math.min(rr, ex, ey))
    const o = [], k = 16
    const corners = [[ex - rr, -ey + rr, -Math.PI / 2], [ex - rr, ey - rr, 0], [-ex + rr, ey - rr, Math.PI / 2], [-ex + rr, -ey + rr, Math.PI]]
    for (const c of corners) {
        if (rr <= 0) { o.push([c[0], c[1]]); continue }
        for (let s = 0; s <= k; s++) { const a = c[2] + s / k * Math.PI / 2; o.push([c[0] + rr * Math.cos(a), c[1] + rr * Math.sin(a)]) }
    }
    return o
}
function flowerR(t, k, d) { return k === 0 ? 1 : 1 - d * (1 - Math.cos(k * t)) / 2 }

// contorno [[x, y], ...] (API antiga Shapes.pts). Caixas: quadrado [-1, 1] (raio do "rounded" = 0.22 do lado, como o Flower)
function contour(id, sides, depth) {
    id = canon(id)
    const k = Math.max(0, sides ?? 12), d = depth ?? 0.11
    if (id === "flower") { const o = []; for (let i = 0; i < N; i++) { const t = i / N * Math.PI * 2, r = flowerR(t, k, d); o.push([r * Math.sin(t), -r * Math.cos(t)]) } return o }
    if (id === "square") return roundRect(1, 1, 0)
    if (id === "rounded") return roundRect(1, 1, 0.44)
    if (id === "circle") { const o = []; for (let i = 0; i < N; i++) { const t = i / N * Math.PI * 2; o.push([Math.sin(t), -Math.cos(t)]) } return o }
    return flatten(cubics(id))
}

// ---------- amostragem radial ----------
function angleOf(x, y) { const a = Math.atan2(x, -y); return a < 0 ? a + Math.PI * 2 : a }
// quanto o contorno "volta" (graus) visto do centro (cx, cy): 0 = cada raio corta o contorno uma vez so
function backtrack(P, cx, cy) {
    let tot = 0, back = 0
    const ds = []
    for (let i = 0; i < P.length; i++) {
        const a = P[i], b = P[(i + 1) % P.length]
        let d = angleOf(b[0] - cx, b[1] - cy) - angleOf(a[0] - cx, a[1] - cy)
        if (d > Math.PI) d -= Math.PI * 2; else if (d < -Math.PI) d += Math.PI * 2
        ds.push(d); tot += d
    }
    for (const d of ds) if (d * tot < 0) back += Math.abs(d)
    return back * 180 / Math.PI
}
// centro de onde a forma e estrelada (o do quadrado quase sempre; o triangulo pixelado precisa de outro)
function bestCenter(P) {
    if (backtrack(P, 0, 0) < 1) return [0, 0]
    let best = [0, 0], bv = 1e9
    for (let gx = -0.6; gx <= 0.6001; gx += 0.1)
        for (let gy = -0.6; gy <= 0.6001; gy += 0.1) {
            const v = backtrack(P, gx, gy) + Math.hypot(gx, gy) * 10
            if (v < bv) { bv = v; best = [gx, gy] }
        }
    return best
}
// raios de um contorno fechado vistos de (cx, cy) em N angulos (o mais distante, se um raio cortar mais de uma vez)
function sample(P, cx, cy) {
    const r = new Float64Array(N), da = Math.PI * 2 / N
    for (let i = 0; i < P.length; i++) {
        const a = P[i], b = P[(i + 1) % P.length]
        const ax = a[0] - cx, ay = a[1] - cy, bx = b[0] - cx, by = b[1] - cy
        const ta = angleOf(ax, ay)
        let d = angleOf(bx, by) - ta
        if (d > Math.PI) d -= Math.PI * 2; else if (d < -Math.PI) d += Math.PI * 2
        const lo = Math.min(ta, ta + d), hi = Math.max(ta, ta + d)
        const ex = bx - ax, ey = by - ay
        for (let j = Math.ceil(lo / da - 1e-9); j <= Math.floor(hi / da + 1e-9); j++) {
            const t = j * da, ux = Math.sin(t), uy = -Math.cos(t)
            const den = ux * ey - uy * ex
            let s
            if (Math.abs(den) < 1e-12) s = Math.max(ax * ux + ay * uy, bx * ux + by * uy)
            else s = (ax * ey - ay * ex) / den
            const idx = ((j % N) + N) % N
            if (s > r[idx]) r[idx] = s
        }
    }
    // buracos (nao deveria haver): vizinho
    for (let i = 0; i < N; i++) if (r[i] <= 0) r[i] = r[(i + N - 1) % N]
    return r
}

var radialCache = {}
var boxCount = 0
// { r: Float64Array(N), cx, cy } da forma. Caixas: ex/ey/rr em unidades do raio do item (dependem do tamanho dele)
function radial(id, sides, depth, ex, ey, rr) {
    id = canon(id)
    const k = Math.max(0, Math.round(sides ?? 12)), d = depth ?? 0.11
    let key
    if (id === "flower") key = "flower|" + k + "|" + d.toFixed(3)
    else if (isBox(id)) {
        ex = ex ?? 1; ey = ey ?? 1
        rr = id === "square" ? 0 : id === "circle" ? Math.min(ex, ey) : (rr ?? 0.44)
        key = "box|" + ex.toFixed(3) + "|" + ey.toFixed(3) + "|" + rr.toFixed(3)
    } else key = id
    const hit = radialCache[key]
    if (hit) return hit
    let e
    if (id === "flower") {
        const r = new Float64Array(N)
        for (let i = 0; i < N; i++) r[i] = flowerR(i / N * Math.PI * 2, k, d)
        e = { r: r, cx: 0, cy: 0 }
    } else if (isBox(id)) {
        e = { r: sample(roundRect(ex, ey, rr), 0, 0), cx: 0, cy: 0 }
        // tamanhos animados geram muitas caixas: limpa de vez em quando
        if (++boxCount > 300) { for (const kk in radialCache) if (kk.startsWith("box|")) delete radialCache[kk]; boxCount = 0 }
    } else {
        const P = flatten(cubics(id)), c = bestCenter(P)
        e = { r: sample(P, c[0], c[1]), cx: c[0], cy: c[1] }
    }
    radialCache[key] = e
    return e
}

// ---------- morph ----------
// giro (em amostras) que melhor encaixa b sobre a; so vale se melhorar bem o encaixe sem giro
function bestShift(a, b) {
    const ar = a.r, br = b.r, M8 = Math.round(N / 8)
    let e0 = 0
    for (let i = 0; i < N; i++) { const q = ar[i] - br[i]; e0 += q * q }
    let best = 0, be = e0
    for (let s = -M8; s <= M8; s++) {
        if (s === 0) continue
        let e = 0
        for (let i = 0; i < N && e < be; i++) { const q = ar[i] - br[(i + s + N) % N]; e += q * q }
        if (e < be) { be = e; best = s }
    }
    return be < e0 * 0.75 ? best : 0
}
// forma no instante k (0 = a, 1 = b; passa de 1 no "quique"): raios + centro. O quadro gira junto (k * shift) para que
// a comece onde estava e b termine onde deve: S_k(t) = (1 - k) a(t - k s) + k b(t - k s + s)
function frame(a, b, k, shift) {
    const r = new Float64Array(N), ar = a.r, br = b.r
    // deslocamentos fixos no quadro inteiro: parte inteira + fracao, uma vez so
    const oa = -k * shift, ob = oa + shift
    const ia = Math.floor(oa), fa = oa - ia, ib = Math.floor(ob), fb = ob - ib
    let ja = ((ia % N) + N) % N, jb = ((ib % N) + N) % N
    for (let i = 0; i < N; i++) {
        const ja1 = ja + 1 === N ? 0 : ja + 1, jb1 = jb + 1 === N ? 0 : jb + 1
        const ra = ar[ja] + (ar[ja1] - ar[ja]) * fa, rb = br[jb] + (br[jb1] - br[jb]) * fb
        const v = ra + (rb - ra) * k
        r[i] = v > 0 ? v : 0
        ja = ja1; jb = jb1
    }
    return { r: r, cx: a.cx + (b.cx - a.cx) * k, cy: a.cy + (b.cy - a.cy) * k }
}

// ---------- caminhos SVG em pixels: ox, oy = centro do item; R = raio em pixels ----------
function f1(v) { return Math.round(v * 100) / 100 }
var sinT = new Float64Array(N), cosT = new Float64Array(N)
for (let i = 0; i < N; i++) { sinT[i] = Math.sin(i / N * Math.PI * 2); cosT[i] = Math.cos(i / N * Math.PI * 2) }
// itens pequenos nao precisam dos 360 pontos: usa 1 raio a cada "passo"
function strideFor(R) { return R < 40 ? 4 : R < 90 ? 3 : R < 160 ? 2 : 1 }
function polySvg(e, ox, oy, R) {
    const r = e.r, cx = ox + e.cx * R, cy = oy + e.cy * R, st = strideFor(R)
    let s = "M" + f1(cx + r[0] * R * sinT[0]) + " " + f1(cy - r[0] * R * cosT[0])
    for (let i = st; i < N; i += st) s += "L" + f1(cx + r[i] * R * sinT[i]) + " " + f1(cy - r[i] * R * cosT[i])
    return s + "Z"
}
function cubicSvg(id, ox, oy, R) {
    const cs = cubics(id)
    if (!cs || !cs.length) return ""
    const X = v => f1(ox + v * R), Y = v => f1(oy + v * R)
    let s = "M" + X(cs[0]) + " " + Y(cs[1])
    for (let i = 0; i < cs.length; i += 8)
        s += "C" + X(cs[i + 2]) + " " + Y(cs[i + 3]) + " " + X(cs[i + 4]) + " " + Y(cs[i + 5]) + " " + X(cs[i + 6]) + " " + Y(cs[i + 7])
    return s + "Z"
}
// caminho exato da forma parada: M3 em cubicas; flor e caixas pelos raios
function restSvg(id, sides, depth, ox, oy, R, ex, ey, rr) {
    id = canon(id)
    if (!isBox(id) && id !== "flower") return cubicSvg(id, ox, oy, R)
    return polySvg(radial(id, sides, depth, ex, ey, rr), ox, oy, R)
}
