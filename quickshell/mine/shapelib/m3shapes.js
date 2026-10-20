.pragma library

// As 35 formas do Material 3 (as mesmas do end4 / androidx.compose.material3 MaterialShapes), sobre um porte enxuto do
// RoundedPolygon do androidx graphics-shapes (Apache 2.0): poligono com cantos arredondados (raio + suavizacao) em cubicas.
// Cada forma sai como lista de cubicas [x0, y0, cx0, cy0, cx1, cy1, x1, y1] normalizada no quadrado [0, 1].
// So o necessario para desenhar e amostrar (o morph fica em radial.js): sem features/medidas do Morph original.

var DistanceEpsilon = 1e-4

// ---------- pontos ----------
function P(x, y) { return { x: x, y: y } }
function sub(a, b) { return P(a.x - b.x, a.y - b.y) }
function add(a, b) { return P(a.x + b.x, a.y + b.y) }
function mul(a, k) { return P(a.x * k, a.y * k) }
function dot(a, b) { return a.x * b.x + a.y * b.y }
function len(a) { return Math.hypot(a.x, a.y) }
function dir(a) { const d = len(a); return d > 0 ? P(a.x / d, a.y / d) : P(0, 0) }
function rot90(a) { return P(-a.y, a.x) }
function lerpP(a, b, t) { return P(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t) }

// ---------- cubicas ----------
function C(x0, y0, x1, y1, x2, y2, x3, y3) { return [x0, y0, x1, y1, x2, y2, x3, y3] }
function line(x0, y0, x1, y1) { return C(x0, y0, x0 + (x1 - x0) / 3, y0 + (y1 - y0) / 3, x0 + (x1 - x0) * 2 / 3, y0 + (y1 - y0) * 2 / 3, x1, y1) }
function zeroLength(c) { return Math.abs(c[0] - c[6]) < DistanceEpsilon && Math.abs(c[1] - c[7]) < DistanceEpsilon }
function arc(cx, cy, x0, y0, x1, y1) {
    const p0d = dir(P(x0 - cx, y0 - cy)), p1d = dir(P(x1 - cx, y1 - cy))
    const r0 = rot90(p0d), r1 = rot90(p1d)
    const clockwise = dot(r0, P(x1 - cx, y1 - cy)) >= 0
    const cosa = dot(p0d, p1d)
    if (cosa > 0.999) return line(x0, y0, x1, y1)
    const k = Math.hypot(x0 - cx, y0 - cy) * 4 / 3 * (Math.sqrt(2 * (1 - cosa)) - Math.sqrt(1 - cosa * cosa)) / (1 - cosa) * (clockwise ? 1 : -1)
    return C(x0, y0, x0 + r0.x * k, y0 + r0.y * k, x1 - r1.x * k, y1 - r1.y * k, x1, y1)
}
function splitHalf(c) {
    // de Casteljau em t = 0.5
    const m = (a, b) => (a + b) / 2
    const x01 = m(c[0], c[2]), y01 = m(c[1], c[3]), x12 = m(c[2], c[4]), y12 = m(c[3], c[5]), x23 = m(c[4], c[6]), y23 = m(c[5], c[7])
    const xa = m(x01, x12), ya = m(y01, y12), xb = m(x12, x23), yb = m(y12, y23), xm = m(xa, xb), ym = m(ya, yb)
    return [C(c[0], c[1], x01, y01, xa, ya, xm, ym), C(xm, ym, xb, yb, x23, y23, c[6], c[7])]
}
function reverse(c) { return C(c[6], c[7], c[4], c[5], c[2], c[3], c[0], c[1]) }

// ---------- arredondamento ----------
function Rounding(radius, smoothing) { return { radius: radius || 0, smoothing: smoothing || 0 } }
var Unrounded = Rounding(0, 0)

function lineIntersection(p0, d0, p1, d1) {
    const rd1 = rot90(d1), den = dot(d0, rd1)
    if (Math.abs(den) < DistanceEpsilon) return null
    const num = dot(sub(p1, p0), rd1)
    if (Math.abs(den) < DistanceEpsilon * Math.abs(num)) return null
    return add(p0, mul(d0, num / den))
}
function corner(p0, p1, p2, rounding) {
    const c = { p0: p0, p1: p1, p2: p2, radius: 0, smoothing: 0, roundCut: 0, d1: P(0, 0), d2: P(0, 0) }
    const v01 = sub(p0, p1), v21 = sub(p2, p1), d01 = len(v01), d21 = len(v21)
    if (d01 > 0 && d21 > 0) {
        c.d1 = mul(v01, 1 / d01); c.d2 = mul(v21, 1 / d21)
        c.radius = rounding ? rounding.radius : 0
        c.smoothing = rounding ? rounding.smoothing : 0
        const cosA = dot(c.d1, c.d2), sinA = Math.sqrt(Math.max(0, 1 - cosA * cosA))
        c.roundCut = sinA > 1e-3 ? c.radius * (cosA + 1) / sinA : 0
    }
    c.cut = (1 + c.smoothing) * c.roundCut
    return c
}
function smoothingFor(c, allowed) {
    if (allowed > c.cut) return c.smoothing
    if (allowed > c.roundCut) return c.smoothing * (allowed - c.roundCut) / (c.cut - c.roundCut)
    return 0
}
function flanking(roundCut, smooth, cornerP, sideStart, inter, otherInter, center, r) {
    const sideDir = dir(sub(sideStart, cornerP))
    const curveStart = add(cornerP, mul(sideDir, roundCut * (1 + smooth)))
    const p = lerpP(inter, mul(add(inter, otherInter), 0.5), smooth)
    const curveEnd = add(center, mul(dir(sub(p, center)), r))
    const tangent = rot90(sub(curveEnd, center))
    const anchorEnd = lineIntersection(sideStart, sideDir, curveEnd, tangent) || inter
    const anchorStart = mul(add(curveStart, mul(anchorEnd, 2)), 1 / 3)
    return C(curveStart.x, curveStart.y, anchorStart.x, anchorStart.y, anchorEnd.x, anchorEnd.y, curveEnd.x, curveEnd.y)
}
function cornerCubics(c, cut0, cut1) {
    const allowed = Math.min(cut0, cut1)
    if (c.roundCut < DistanceEpsilon || allowed < DistanceEpsilon || c.radius < DistanceEpsilon)
        return [line(c.p1.x, c.p1.y, c.p1.x, c.p1.y)]
    const roundCut = Math.min(allowed, c.roundCut)
    const s0 = smoothingFor(c, cut0), s1 = smoothingFor(c, cut1)
    const r = c.radius * roundCut / c.roundCut
    const centerDist = Math.sqrt(r * r + roundCut * roundCut)
    const center = add(c.p1, mul(dir(mul(add(c.d1, c.d2), 0.5)), centerDist))
    const i0 = add(c.p1, mul(c.d1, roundCut)), i2 = add(c.p1, mul(c.d2, roundCut))
    const f0 = flanking(roundCut, s0, c.p1, c.p0, i0, i2, center, r)
    const f2 = reverse(flanking(roundCut, s1, c.p1, c.p2, i2, i0, center, r))
    return [f0, arc(center.x, center.y, f0[6], f0[7], f2[0], f2[1]), f2]
}

// ---------- poligono: lista de "features" (listas de cubicas) ----------
// vertices: [x0, y0, x1, y1, ...]; perVertex: lista de Rounding (ou null)
function polygon(vertices, rounding, perVertex) {
    const n = vertices.length / 2, V = i => P(vertices[i * 2], vertices[i * 2 + 1])
    const cs = []
    for (let i = 0; i < n; i++) cs.push(corner(V((i + n - 1) % n), V(i), V((i + 1) % n), perVertex ? perVertex[i] : rounding))
    // lados curtos demais: divide o espaco, primeiro para o arredondamento, depois para a suavizacao
    const adj = []
    for (let i = 0; i < n; i++) {
        const j = (i + 1) % n
        const roundCut = cs[i].roundCut + cs[j].roundCut, cut = cs[i].cut + cs[j].cut
        const side = len(sub(V(i), V(j)))
        if (roundCut > side) adj.push([side / roundCut, 0])
        else if (cut > side) adj.push([1, (side - roundCut) / (cut - roundCut)])
        else adj.push([1, 1])
    }
    const corners = []
    for (let i = 0; i < n; i++) {
        const cuts = [0, 0]
        for (let d = 0; d <= 1; d++) {
            const a = adj[(i + n - 1 + d) % n]
            cuts[d] = cs[i].roundCut * a[0] + (cs[i].cut - cs[i].roundCut) * a[1]
        }
        corners.push(cornerCubics(cs[i], cuts[0], cuts[1]))
    }
    const features = []
    for (let i = 0; i < n; i++) {
        const a = corners[i][corners[i].length - 1], b = corners[(i + 1) % n][0]
        features.push(corners[i])
        features.push([line(a[6], a[7], b[0], b[1])])
    }
    return features
}
// cubicas finais (como o RoundedPolygon: comeca no meio do primeiro canto, sem trechos de comprimento zero)
function cubicsOf(features) {
    let splitStart = null, splitEnd = null
    if (features.length && features[0].length === 3) {
        const h = splitHalf(features[0][1])
        splitStart = [features[0][0], h[0]]; splitEnd = [h[1], features[0][2]]
    }
    const out = []
    let first = null, last = null
    for (let i = 0; i <= features.length; i++) {
        let fc
        if (i === 0 && splitEnd) fc = splitEnd
        else if (i === features.length) { if (splitStart) fc = splitStart; else break }
        else fc = features[i]
        for (const c of fc) {
            if (!zeroLength(c)) {
                if (last) out.push(last)
                last = c
                if (!first) first = c
            } else if (last) {
                last = last.slice(); last[6] = c[6]; last[7] = c[7]
            }
        }
    }
    if (last && first) out.push(C(last[0], last[1], last[2], last[3], last[4], last[5], first[0], first[1]))
    return out
}
function transformed(features, fn) {
    return features.map(f => f.map(c => {
        const a = fn(c[0], c[1]), b = fn(c[2], c[3]), d = fn(c[4], c[5]), e = fn(c[6], c[7])
        return C(a.x, a.y, b.x, b.y, d.x, d.y, e.x, e.y)
    }))
}
// limites aproximados (pontos de controle inclusos), como o calculateBounds padrao do androidx
function bounds(features) {
    let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9
    for (const c of cubicsOf(features)) for (let i = 0; i < 8; i += 2) {
        x0 = Math.min(x0, c[i]); x1 = Math.max(x1, c[i]); y0 = Math.min(y0, c[i + 1]); y1 = Math.max(y1, c[i + 1])
    }
    return [x0, y0, x1, y1]
}
function normalized(features) {
    const b = bounds(features), w = b[2] - b[0], h = b[3] - b[1], side = Math.max(w, h)
    const ox = (side - w) / 2 - b[0], oy = (side - h) / 2 - b[1]
    return transformed(features, (x, y) => P((x + ox) / side, (y + oy) / side))
}
function rotate(features, deg) {
    const r = deg * Math.PI / 180, c = Math.cos(r), s = Math.sin(r)
    return transformed(features, (x, y) => P(c * x - s * y, s * x + c * y))
}
function scale(features, sx, sy) { return transformed(features, (x, y) => P(x * sx, y * sy)) }

// ---------- construtores (mesmos do androidx) ----------
function numVertices(n, radius, cx, cy) {
    const v = []
    for (let i = 0; i < n; i++) { const a = Math.PI / n * 2 * i; v.push(radius * Math.cos(a) + cx, radius * Math.sin(a) + cy) }
    return v
}
function regular(n, radius, cx, cy, rounding) { return polygon(numVertices(n, radius ?? 1, cx ?? 0, cy ?? 0), rounding ?? Unrounded, null) }
function circle(n) { n = n ?? 8; return regular(n, 1 / Math.cos(Math.PI / n), 0, 0, Rounding(1)) }
function rectangle(w, h, rounding, perVertex) {
    const l = -w / 2, t = -h / 2, r = w / 2, b = h / 2
    return polygon([r, b, l, b, l, t, r, t], rounding ?? Unrounded, perVertex)
}
function star(n, radius, inner, rounding) {
    const v = []
    for (let i = 0; i < n; i++) {
        let a = Math.PI / n * 2 * i
        v.push(radius * Math.cos(a), radius * Math.sin(a))
        a = Math.PI / n * (2 * i + 1)
        v.push(inner * Math.cos(a), inner * Math.sin(a))
    }
    return polygon(v, rounding ?? Unrounded, null)
}
// pontos [x, y, Rounding?] repetidos reps vezes em volta de (0.5, 0.5)
function custom(pts, reps) {
    const v = [], pr = []
    for (let i = 0; i < pts.length * reps; i++) {
        const p = pts[i % pts.length], a = Math.floor(i / pts.length) * 360 / reps * Math.PI / 180
        const dx = p[0] - 0.5, dy = p[1] - 0.5
        v.push(dx * Math.cos(a) - dy * Math.sin(a) + 0.5, dx * Math.sin(a) + dy * Math.cos(a) + 0.5)
        pr.push(p[2] ?? Unrounded)
    }
    return polygon(v, Unrounded, pr)
}

var r15 = Rounding(0.15), r20 = Rounding(0.2), r30 = Rounding(0.3), r50 = Rounding(0.5), r100 = Rounding(1)
function R(a, b) { return Rounding(a, b) }

// ---------- as 35 formas (valores de material-shapes.js do end4) ----------
var defs = {
    circle: () => normalized(rotate(circle(10), 45)),
    square: () => normalized(rectangle(1, 1, r30)),
    slanted: () => normalized(custom([[0.926, 0.970, R(0.189, 0.811)], [-0.021, 0.967, R(0.187, 0.057)]], 2)),
    arch: () => normalized(rectangle(1, 1, Unrounded, [r20, r20, r100, r100])),
    fan: () => normalized(custom([[1.004, 1.000, R(0.148, 0.417)], [0.000, 1.000, R(0.151)], [0.000, -0.003, R(0.148)], [0.978, 0.020, R(0.803)]], 1)),
    arrow: () => normalized(custom([[1.225, 1.060, R(0.211)], [0.500, 0.892, R(0.313)], [-0.216, 1.050, R(0.207)], [0.499, -0.160, R(0.215, 1.000)]], 1)),
    semicircle: () => normalized(rectangle(1.6, 1, Unrounded, [r20, r20, r100, r100])),
    oval: () => normalized(rotate(scale(rotate(circle(), -90), 1, 0.64), 135)),
    pill: () => normalized(rotate(custom([[0.428, -0.001, R(0.426)], [0.961, 0.039, R(0.426)], [1.001, 0.428], [1.000, 0.609, R(1.000)]], 2), 180)),
    triangle: () => normalized(rotate(regular(3, 1, 0.5, 0.5, r20), 30)),
    diamond: () => normalized(custom([[0.500, 1.096, R(0.151, 0.524)], [0.040, 0.500, R(0.159)]], 2)),
    clamshell: () => normalized(custom([[0.829, 0.841, R(0.159)], [0.171, 0.841, R(0.159)], [-0.020, 0.500, R(0.140)]], 2)),
    pentagon: () => normalized(custom([[0.828, 0.970, R(0.169)], [0.172, 0.970, R(0.169)], [-0.030, 0.365, R(0.164)], [0.500, -0.009, R(0.172)], [1.030, 0.365, R(0.164)]], 1)),
    gem: () => normalized(custom([[1.005, 0.792, R(0.208)], [0.5, 1.023, R(0.241, 0.778)], [-0.005, 0.792, R(0.208)], [0.073, 0.258, R(0.228)], [0.5, 0.000, R(0.241, 0.778)], [0.927, 0.258, R(0.228)]], 1)),
    sunny: () => normalized(rotate(star(8, 1, 0.8, r15), 45)),
    verysunny: () => normalized(rotate(custom([[0.500, 1.080, R(0.085)], [0.358, 0.843, R(0.085)]], 8), -45)),
    cookie4: () => normalized(custom([[1.237, 1.236, R(0.258)], [0.500, 0.918, R(0.233)]], 4)),
    cookie6: () => normalized(custom([[0.723, 0.884, R(0.394)], [0.500, 1.099, R(0.398)]], 6)),
    cookie7: () => normalized(rotate(normalized(star(7, 1, 0.75, r50)), 360 / 28 * 5)),
    cookie9: () => normalized(rotate(star(9, 1, 0.8, r50), 30)),
    cookie12: () => normalized(rotate(star(12, 1, 0.8, r50), 30)),
    ghostish: () => normalized(custom([[1.000, 1.140, R(0.254, 0.106)], [0.575, 0.906, R(0.253)], [0.425, 0.906, R(0.253)], [0.000, 1.140, R(0.254, 0.106)],
                                       [0.000, 0.000, R(1.0)], [0.500, 0.000, R(1.0)], [1.000, 0.000, R(1.0)]], 1)),
    clover4: () => normalized(custom([[1.099, 0.725, R(0.476)], [0.725, 1.099, R(0.476)], [0.500, 0.926]], 4)),
    clover8: () => normalized(custom([[0.758, 1.101, R(0.209)], [0.500, 0.964]], 8)),
    burst: () => normalized(rotate(custom([[0.592, 0.842, R(0.006)], [0.500, 1.006, R(0.006)]], 12), -60)),
    softburst: () => normalized(rotate(custom([[0.193, 0.277, R(0.053)], [0.176, 0.055, R(0.053)]], 10), 180)),
    boom: () => normalized(rotate(custom([[0.457, 0.296, R(0.007)], [0.500, -0.051, R(0.007)]], 15), 120)),
    softboom: () => normalized(rotate(custom([[0.733, 0.454], [0.839, 0.437, R(0.532)], [0.949, 0.449, R(0.439, 1.000)], [0.998, 0.478, R(0.174)],
                                              [0.998, 0.522, R(0.174)], [0.949, 0.551, R(0.439, 1.000)], [0.839, 0.563, R(0.532)], [0.733, 0.546]], 16), 45 - 360 / 16)),
    flower8: () => normalized(rotate(custom([[0.370, 0.187], [0.416, 0.049, R(0.381)], [0.479, 0.001, R(0.095)],
                                             [0.521, 0.001, R(0.095)], [0.584, 0.049, R(0.381)], [0.630, 0.187]], 8), 135)),
    puffy: () => normalized(scale(custom([
        [1.003, 0.563, R(0.255)], [0.940, 0.656, R(0.126)], [0.881, 0.654], [0.926, 0.711, R(0.660)], [0.914, 0.851, R(0.660)], [0.777, 0.998, R(0.360)],
        [0.722, 0.872], [0.717, 0.934, R(0.574)], [0.670, 1.035, R(0.426)], [0.545, 1.040, R(0.405)], [0.500, 0.947],
        [0.500, 1 - 0.053], [1 - 0.545, 1 + 0.040, R(0.405)], [1 - 0.670, 1 + 0.035, R(0.426)], [1 - 0.717, 1 - 0.066, R(0.574)], [1 - 0.722, 1 - 0.128],
        [1 - 0.777, 1 - 0.002, R(0.360)], [1 - 0.914, 1 - 0.149, R(0.660)], [1 - 0.926, 1 - 0.289, R(0.660)], [1 - 0.881, 1 - 0.346],
        [1 - 0.940, 1 - 0.344, R(0.126)], [1 - 1.003, 1 - 0.437, R(0.255)]], 2), 1, 0.742)),
    puffydiamond: () => normalized(rotate(custom([[0.870, 0.130, R(0.146)], [0.818, 0.357], [1.000, 0.332, R(0.853)],
                                                  [1.000, 1 - 0.332, R(0.853)], [0.818, 1 - 0.357]], 4), 90)),
    pixelcircle: () => normalized(custom([[1.000, 0.704], [0.926, 0.704], [0.926, 0.852], [0.843, 0.852], [0.843, 0.935], [0.704, 0.935], [0.704, 1.000],
                                          [0.500, 1.000], [1 - 0.704, 1.000], [1 - 0.704, 0.935], [1 - 0.843, 0.935], [1 - 0.843, 0.852], [1 - 0.926, 0.852],
                                          [1 - 0.926, 0.704], [1 - 1.000, 0.704]], 2)),
    pixeltriangle: () => normalized(custom([
        [0.888, 1 - 0.439], [0.789, 1 - 0.439], [0.789, 1 - 0.344], [0.675, 1 - 0.344], [0.674, 1 - 0.265], [0.560, 1 - 0.265], [0.560, 1 - 0.170],
        [0.421, 1 - 0.170], [0.421, 1 - 0.087], [0.287, 1 - 0.087], [0.287, 1 - 0.000], [0.113, 1 - 0.000],
        [0.110, 0.500], [0.113, 0.000], [0.287, 0.000], [0.287, 0.087], [0.421, 0.087], [0.421, 0.170], [0.560, 0.170], [0.560, 0.265],
        [0.674, 0.265], [0.675, 0.344], [0.789, 0.344], [0.789, 0.439], [0.888, 0.439]], 1)),
    bun: () => normalized(custom([[0.796, 0.500], [0.853, 0.518, r100], [0.992, 0.631, r100], [0.968, 1.000, r100],
                                  [0.032, 1 - 0.000, r100], [0.008, 1 - 0.369, r100], [0.147, 1 - 0.482, r100], [0.204, 1 - 0.500]], 2)),
    heart: () => normalized(custom([[0.782, 0.611], [0.499, 0.946, R(0.000)], [0.2175, 0.611], [-0.064, 0.276, R(1.000)], [0.208, -0.066, R(0.958)],
                                    [0.500, 0.268, R(0.016)], [0.792, -0.066, R(0.958)], [1.064, 0.276, R(1.000)]], 1))
}
var ids = Object.keys(defs)

var cache = {}
// cubicas da forma, normalizadas em [0, 1] (null se o id nao for uma forma M3)
function get(id) {
    if (cache[id]) return cache[id]
    const d = defs[id]
    if (!d) return null
    cache[id] = cubicsOf(d())
    return cache[id]
}
