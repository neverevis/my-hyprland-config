// Geometria da moldura: calcula, para uma tela W x H, o retangulo de cada barra e o caminho SVG do "buraco".
// Lados no sentido horario: top -> right -> bottom -> left. Em cada lado usamos coordenadas locais
// (u ao longo do lado, v para dentro da tela) e convertemos para a tela com pt().
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    // profundidade do conteudo do seletor de wallpaper (so as miniaturas, sem titulos)
    function pickerDepth(vertical: bool): real { return vertical ? 296 : 186 }
    // comprimento do painel do seletor: N cartoes (passo 256 na horizontal, 142 na vertical) + folga + margens internas
    function pickerLen(vertical: bool, W: real, H: real): real {
        const n = Math.max(1, Math.min(5, Settings.wpPickerCount))
        return Math.min(n * (vertical ? 142 : 256) + 12 + 2 * pickerPad, (vertical ? H : W) - 140)
    }
    readonly property real pickerPad: 14

    readonly property var order: ["top", "right", "bottom", "left"]

    function pt(side: string, u: real, v: real, W: real, H: real): string {
        let x = 0, y = 0
        if (side === "top") { x = u; y = v }
        else if (side === "right") { x = W - v; y = u }
        else if (side === "bottom") { x = W - u; y = H - v }
        else { x = v; y = H - u }
        return x.toFixed(2) + " " + y.toFixed(2)
    }

    function lenOf(s: string, W: real, H: real): real { return (s === "top" || s === "bottom") ? W : H }

    function compute(W: real, H: real, prog: var): var {
        const bars = (Settings.bars || []).slice()
        // notificacoes: um bloco so (todos os cartoes) que cresce da moldura, como uma barra extra
        const npr = BarState.notifProg
        let nIdx = -1
        if (Settings.notifOn && npr > 0.002 && BarState.notifLen > 1) {
            const ns = Settings.notifSide, nv = ns === "left" || ns === "right"
            const PLn = nv ? H : W, fN = Settings.notifFillet
            const avail = PLn - 2 * (Settings.edge + (Settings.outline ? Settings.cornerRadius : 0) + fN)
            const len = Math.min(BarState.notifLen, avail)
            const sl = (avail - len) / 2
            const marg = 18
            const off = Settings.notifAnchor === "start" ? -sl + marg : (Settings.notifAnchor === "end" ? sl - marg : 0)
            nIdx = bars.length
            bars.push({ side: ns, width: len, offset: Math.max(-sl, Math.min(sl, off)), height: Settings.edge + 10 + BarState.notifDepth + 10,
                        full: false, autoHide: true, reserve: "overlay", notif: true, fillet: fN, topRadius: Settings.notifRadius })
            prog = Object.assign({}, prog || {})
            prog[nIdx] = npr
        }
        // painel acoplado (seletor de wallpaper ou launcher): entra como uma "barra" extra, para a moldura crescer ate ele (mesmo desenho das barras)
        // o launcher tem prioridade quando aberto; os dois nunca ficam abertos juntos (um fecha o outro)
        let panel = null
        const lp = BarState.launcherProg, wp = BarState.pickerProg
        if (Settings.launcherDocked && lp > 0.002) {
            const ls = Settings.launcherSide
            const lv = ls === "left" || ls === "right"
            const cw = Math.min(Settings.launcherWidth, (lv ? W : W) - 100), ch = BarState.launcherDepth
            panel = { kind: "launcher", prog: lp, bar: { side: ls, width: Math.min(lv ? ch : cw, (lv ? H : W) - 140), offset: Settings.launcherOffset,
                      height: Settings.edge + 8 + (lv ? cw : ch) + 12, full: false, autoHide: true, reserve: "overlay", picker: true,
                      fillet: Settings.launcherFillet, topRadius: Settings.launcherRadius } }
        } else if (wp > 0.002 && Settings.wpPickerDocked) {
            const ps = Settings.wpPickerSide
            const pv = ps === "left" || ps === "right"
            panel = { kind: "picker", prog: wp, bar: { side: ps, width: pickerLen(pv, W, H), offset: Settings.wpPickerOffset,
                      height: Settings.edge + 8 + pickerDepth(pv) + 12, full: false, autoHide: true, reserve: "overlay", picker: true,
                      fillet: Settings.wpPickerFillet, topRadius: Settings.wpPickerRadius } }
        }
        const pp = panel ? panel.prog : 0
        let pIdx = -1
        if (panel) {
            pIdx = bars.length
            bars.push(panel.bar)
            prog = Object.assign({}, prog || {})
            prog[pIdx] = pp
        }
        const edge = Settings.edge
        const outline = Settings.outline
        const r = outline ? Settings.cornerRadius : 0

        // barras que competem com o seletor (mesmo lado, faixas que se tocam) se escondem para dar lugar a ele
        const cover = new Array(bars.length).fill(0)
        const sepSet = {}
        let pRange = null, pSide = ""
        const slide = {}   // deslocamento (px, no eixo da tela) das barras que saem pelo lado
        if (pIdx >= 0) {
            const pb = bars[pIdx]
            const PL = (pb.side === "top" || pb.side === "bottom") ? W : H
            const f0 = Settings.fillet
            const rng = b => {
                const w = b.full ? PL : Math.min(b.width, Math.max(0, PL - 2 * (edge + r + f0)))
                const cs = Math.max(w / 2, Math.min(PL - w / 2, PL / 2 + (b.offset || 0)))
                return [cs - w / 2, cs + w / 2]
            }
            const pr = rng(pb)
            pRange = pr; pSide = pb.side
            const fm = Math.max(f0, pb.fillet ?? 0)   // a curva do seletor tambem ocupa espaco
            const m = 2 * fm + 8                 // folga entre a barra e o seletor
            bars.forEach((b, i) => {
                if (i === pIdx || b.side !== pb.side) return
                const br = rng(b)
                const hit = b.full || (br[0] < pr[1] + 2 * fm && br[1] > pr[0] - 2 * fm)
                if (!hit) return
                sepSet[i] = !b.full
                // sai pelo lado em que a barra ja esta (em relacao ao centro do seletor) ate sumir da tela
                if (!b.full) {
                    const outLow = -(br[1] + 2 * fm + 8), outHigh = PL - br[0] + 2 * fm + 8
                    slide[i] = (br[0] + br[1]) / 2 <= (pr[0] + pr[1]) / 2 ? outLow : outHigh
                    return
                }
                cover[i] = Math.min(1, pp * 3)    // sem espaco para sair: recolhe (3x mais rapido que o seletor sobe)
            })
        }

        // barras por lado (uma barra "full" sozinha ocupa o lado todo)
        const grp = { top: [], right: [], bottom: [], left: [] }
        bars.forEach((b, i) => { if (grp[b.side]) grp[b.side].push(i) })
        // progresso de mostrar (0 = escondida, 1 = visivel) das barras com autoHide
        const pf = i => (bars[i].autoHide ? Math.max(0, Math.min(1.3, prog && prog[i] !== undefined ? prog[i] : 1)) : 1) * (1 - cover[i])
        const tOf = i => bars[i].full ? Math.max(bars[i].height, edge) : Math.max(bars[i].height, edge + (bars[i].fillet ?? Settings.fillet) + (bars[i].topRadius ?? Settings.topRadius))   // altura minima: cada barra com as proprias curvas
        const inset = {}, zone = {}
        for (const s of order) {
            let idx = grp[s]
            const full = idx.find(i => bars[i].full)
            if (full !== undefined) idx = grp[s] = [full]
            // espaco reservado: barra fixa reserva tudo; barra que se esconde depende de "reserve":
            //   overlay (padrao) = nao reserva (aparece por cima das janelas), always = reserva sempre, follow = acompanha a animacao
            const zone1 = i => !bars[i].autoHide || bars[i].reserve === "always" ? tOf(i)
                : bars[i].reserve === "follow" ? edge + (tOf(i) - edge) * Math.min(1, pf(i)) : 0
            const zmax = idx.reduce((m, i) => Math.max(m, zone1(i)), 0)
            inset[s] = idx.length ? (full !== undefined ? edge + (tOf(full) - edge) * pf(full) : edge) : (outline ? edge : -2)
            zone[s] = idx.length ? Math.max(zmax, edge) : (outline ? edge : 0)
        }

        const res = new Array(bars.length).fill(null)
        let extra = ""
        let d = "M0 0 L0 " + H + " L" + W + " " + H + " L" + W + " 0 Z "   // retangulo da tela em sentido anti-horario (o buraco e horario; fill WindingFill)

        const sideData = []
        for (let k = 0; k < 4; k++) {
            const s = order[k], prev = order[(k + 3) % 4], next = order[(k + 1) % 4]
            const L = (s === "top" || s === "bottom") ? W : H
            const startU = inset[prev] + r, endU = L - inset[next] - r
            const rev = (s === "bottom" || s === "left")   // u cresce contra o eixo da tela
            const slo = rev ? L - endU : startU, shi = rev ? L - startU : endU   // limites no eixo da tela
            const base = inset[s]

            // posicoes de cada barra deste lado, no eixo da tela
            const items = []
            for (const i of grp[s]) {
                const b = bars[i]
                const full = !!b.full
                const f = full ? 0 : (b.fillet ?? Settings.fillet), g = full ? 0 : (b.topRadius ?? Settings.topRadius)
                const t = tOf(i)
                const p = pf(i)
                const avail = Math.max(0, shi - slo - 2 * f)
                const bw = full ? shi - slo : Math.max(60, Math.min(b.width, avail))
                const slack = Math.max(0, (avail - bw) / 2)
                const zero = (slo + shi) / 2
                const cs = zero + Math.max(-slack, Math.min(slack, b.offset || 0)) + (slide[i] !== undefined ? slide[i] * pp : 0)
                // o arredondamento NAO anima: so encolhe se a barra ainda for mais rasa que as curvas
                const te = full ? inset[s] : inset[s] + (t - inset[s]) * p
                const dr = Math.max(0, te - inset[s])
                const sc = (f + g) > 0 ? Math.min(1, dr / (f + g)) : 1
                items.push({ i: i, f: f, g: g, t: t, fe: f * sc, ge: g * sc, te: te, sep: !!sepSet[i], lo: cs - bw / 2, hi: cs + bw / 2, zero: zero })
            }
            // barras cobertas pelo seletor saem do desenho principal (viram poligonos separados, que podem se sobrepor a ele)
            const main = items.filter(it => !it.sep)
            main.sort((a, b) => a.lo - b.lo)
            let cursor = slo
            for (const it of main) {   // sem sobreposicao
                it.lo = Math.max(it.lo, cursor + it.f)
                if (it.hi < it.lo + 40) it.hi = it.lo + 40
                cursor = it.hi + it.f
            }
            for (const it of items) {
                const t = it.t
                const rect = s === "top" ? { x: it.lo, y: 0, w: it.hi - it.lo, h: t }
                    : s === "right" ? { x: W - t, y: it.lo, w: t, h: it.hi - it.lo }
                    : s === "bottom" ? { x: it.lo, y: H - t, w: it.hi - it.lo, h: t }
                    : { x: 0, y: it.lo, w: t, h: it.hi - it.lo }
                res[it.i] = { side: s, rect: rect, lo: it.lo, hi: it.hi, zero: it.zero, vertical: !(s === "top" || s === "bottom"), t: t, cover: cover[it.i], fade: slide[it.i] !== undefined ? Math.min(1, pp * 2.5) : 0, overlap: (pRange && s === pSide && it.sep) ? Math.max(0, Math.min(1, (Math.min(it.hi, pRange[1]) - Math.max(it.lo, pRange[0])) / Math.max(1, it.hi - it.lo))) : 0 }
            }

            // caminho do buraco neste lado, em ordem crescente de u
            const ul = main.map(it => ({ it: it, a: rev ? L - it.hi : it.lo, b: rev ? L - it.lo : it.hi }))
            ul.sort((x, y) => x.a - y.a)
            const P = (u, v) => pt(s, u, v, W, H)
            const arc = (rad, u, v, sweep) => rad > 0.01 ? "A" + rad + " " + rad + " 0 0 " + sweep + " " + P(u, v) + " " : "L" + P(u, v) + " "
            d += (k === 0 ? "M" : "L") + P(startU, base) + " "
            for (const e of ul) {
                const f = e.it.fe, g = e.it.ge, t = e.it.te
                d += "L" + P(e.a - f, base) + " " + arc(f, e.a, base + f, 1)
                d += "L" + P(e.a, t - g) + " " + arc(g, e.a + g, t, 0)
                d += "L" + P(e.b - g, t) + " " + arc(g, e.b, t - g, 0)
                d += "L" + P(e.b, base + f) + " " + arc(f, e.b + f, base, 1)
            }
            d += "L" + P(endU, base) + " "
            sideData.push({ s: s, next: next, startU: startU, base: base, ul: ul })
            // poligonos das barras cobertas (so a parte que sobe acima da faixa fina)
            for (const it of items.filter(x => x.sep && x.te - base > 1.5)) {   // sem fiapos quando ja quase sumiu
                const a = rev ? L - it.hi : it.lo, b = rev ? L - it.lo : it.hi
                const f = it.fe, g = it.ge, t = it.te
                extra += "M" + P(a - f, base) + " " + arc(f, a, base + f, 1) + "L" + P(a, t - g) + " " + arc(g, a + g, t, 0)
                    + "L" + P(b - g, t) + " " + arc(g, b, t - g, 0) + "L" + P(b, base + f) + " " + arc(f, b + f, base, 1) + "Z "
            }
            // canto ate o inicio do proximo lado
            const nx = (u, v) => pt(next, u, v, W, H)
            const q = nx(inset[s] + r, inset[next])
            d += r > 0.01 ? "A" + r + " " + r + " 0 0 1 " + q + " " : "L" + q + " "
        }
        d += "Z"
        // ---- brilho interno: faixas dentro do vidro, junto ao contorno do buraco ----
        // cada faixa e o buraco "expandido" para dentro da moldura em k px (a moldura fina recua, as barras estreitam e ficam mais rasas,
        // as curvas de encontro engrossam, o topo arredondado das barras afina); a faixa = buraco expandido menos o buraco (regra par-impar)
        const glow = []
        const nGlow = Settings.glowOn ? 18 : 0
        // perfil gaussiano: o borrao alarga a cauda alem do alcance (extensao e sigma crescem com ele)
        const soft = Settings.glowSoft / 100
        const ext = Settings.glowSize * (1 + 2 * soft)
        const sig = Settings.glowSize * 0.55 * (1 + soft)
        const prof = x => Math.exp(-(x / sig) * (x / sig))
        for (let n = 1; n <= nGlow; n++) {
            const gr = ext * n / nGlow
            const ga = Math.max(0, prof(ext * (n - 1) / nGlow) - prof(gr))   // alfa da faixa: a soma das faixas por cima de um ponto segue o perfil
            let gp = ""
            for (let k = 0; k < 4; k++) {
                const sd = sideData[k], s = sd.s, next = sd.next
                const P = (u, v) => pt(s, u, v, W, H)
                const arc = (rad, u, v, sweep) => rad > 0.01 ? "A" + rad + " " + rad + " 0 0 " + sweep + " " + P(u, v) + " " : "L" + P(u, v) + " "
                const base = sd.base - gr
                gp += (k === 0 ? "M" : "L") + P(sd.startU, base) + " "
                for (const e of sd.ul) {
                    const f = e.it.fe + gr, gg = Math.max(0, e.it.ge - gr), t = e.it.te - gr
                    const a = e.a + gr, b = e.b - gr
                    if (b - a < 2 * gg + 2 || t - gg < base + f) continue   // barra fina demais para esta faixa: o contorno segue reto
                    gp += "L" + P(a - f, base) + " " + arc(f, a, base + f, 1)
                    gp += "L" + P(a, t - gg) + " " + arc(gg, a + gg, t, 0)
                    gp += "L" + P(b - gg, t) + " " + arc(gg, b, t - gg, 0)
                    gp += "L" + P(b, base + f) + " " + arc(f, b + f, base, 1)
                }
                const nx = (u, v) => pt(next, u, v, W, H)
                const rr = r + gr
                const q = nx(inset[s] - gr + rr, inset[next] - gr)
                gp += "L" + P(lenOf(s, W, H) - inset[next] - r, base) + " "
                gp += rr > 0.01 ? "A" + rr + " " + rr + " 0 0 1 " + q + " " : "L" + q + " "
            }
            glow.push({ p: gp + "Z", a: ga })
        }
        return { glow: glow, path: d + extra, extra: extra !== "" ? extra : "M0 0", bars: res, zone: zone, inset: inset, notif: nIdx >= 0 ? res[nIdx] : null, picker: panel && panel.kind === "picker" ? res[pIdx] : null, launcher: panel && panel.kind === "launcher" ? res[pIdx] : null }
    }
}
