// Geometria da moldura: calcula, para uma tela W x H, o retangulo de cada barra e o caminho SVG do "buraco".
// Lados no sentido horario: top -> right -> bottom -> left. Em cada lado usamos coordenadas locais
// (u ao longo do lado, v para dentro da tela) e convertemos para a tela com pt().
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    // profundidade do conteudo do seletor de wallpaper (so as miniaturas, sem titulos)
    function pickerDepth(vertical: bool): real { return vertical ? 336 : 226 }
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

    function compute(W: real, H: real, prog: var): var {
        const bars = (Settings.bars || []).slice()
        const nUser = bars.length   // as primeiras sao as do usuario (prioridade = ordem); depois vem notificacoes e paineis
        // notificacoes: um bloco so (todos os cartoes) que cresce da moldura, como uma barra extra
        const npr = BarState.notifProg
        let nIdx = -1
        if (Settings.notifOn && Settings.notifDocked && npr > 0.002 && BarState.notifLen > 1) {
            const ns = Settings.notifSide, nv = ns === "left" || ns === "right"
            const PLn = nv ? H : W, fN = Settings.notifFillet
            const avail = PLn - 2 * (Settings.edge + (Settings.outline ? Settings.cornerRadius : 0) + fN)
            const len = Math.min(BarState.notifLen, avail)
            const sl = (avail - len) / 2
            const marg = 18
            const off = Settings.notifAnchor === "start" ? -sl + marg : (Settings.notifAnchor === "end" ? sl - marg : 0)
            nIdx = bars.length
            bars.push({ side: ns, width: len, offset: Math.max(-sl, Math.min(sl, off)), height: Settings.edge + 10 + BarState.notifDepth + 10,
                        full: false, autoHide: true, reserve: "overlay", notif: true, fillet: fN, topRadius: Settings.notifRadius,
                        corner: Settings.notifCorner && Settings.notifAnchor !== "center" ? Settings.notifAnchor : "" })
            prog = Object.assign({}, prog || {})
            prog[nIdx] = npr
        }
        // indicador de volume acoplado: outro bloco pequeno que sai da moldura (no meio do lado escolhido)
        const opr = BarState.osdProg
        let oIdx = -1
        if (Settings.osdOn && Settings.osdDocked && opr > 0.002) {
            const os = Settings.osdSide, ov = os === "left" || os === "right"
            oIdx = bars.length
            bars.push({ side: os, width: BarState.osdLen(ov), offset: 0, height: Settings.edge + 10 + BarState.osdDepth + 10,
                        full: false, autoHide: true, reserve: "overlay", fillet: Settings.notifFillet, topRadius: Math.min(18, Settings.notifRadius + 4) })
            prog = Object.assign({}, prog || {})
            prog[oIdx] = opr
        }
        // painel acoplado (seletor de wallpaper ou launcher): entra como uma "barra" extra, para a moldura crescer ate ele (mesmo desenho das barras)
        // o launcher tem prioridade quando aberto; os dois nunca ficam abertos juntos (um fecha o outro)
        let panel = null
        const lp = BarState.launcherProg, wp = BarState.pickerProg, hp = BarState.homeProg
        if (Settings.homeDocked && hp > 0.002) {
            const hs = Settings.homeSide
            const hv = hs === "left" || hs === "right"
            const hlen = Math.min(hv ? BarState.homeH : BarState.homeW, (hv ? H : W) - 140)
            const hdep = hv ? BarState.homeW : BarState.homeH
            panel = { kind: "home", prog: hp, opening: Settings.homeOpen, bar: { side: hs, width: hlen, offset: Settings.homeOffset,
                      height: Settings.edge + 8 + hdep + 12, full: false, autoHide: true, reserve: "overlay", picker: true,
                      fillet: Settings.homeFillet, topRadius: Settings.homeRadius } }
        } else if (Settings.launcherDocked && lp > 0.002) {
            const ls = Settings.launcherSide
            const lv = ls === "left" || ls === "right"
            const cw = Math.min(Settings.launcherWidth, (lv ? W : W) - 100), ch = BarState.launcherDepth
            panel = { kind: "launcher", prog: lp, opening: Settings.launcherOpen, bar: { side: ls, width: Math.min(lv ? ch : cw, (lv ? H : W) - 140), offset: Settings.launcherOffset,
                      height: Settings.edge + 8 + (lv ? cw : ch) + 12, full: false, autoHide: true, reserve: "overlay", picker: true,
                      fillet: Settings.launcherFillet, topRadius: Settings.launcherRadius } }
        } else if (wp > 0.002 && Settings.wpPickerDocked) {
            const ps = Settings.wpPickerSide
            const pv = ps === "left" || ps === "right"
            panel = { kind: "picker", prog: wp, opening: Settings.wpPickerOpen, bar: { side: ps, width: pickerLen(pv, W, H), offset: Settings.wpPickerOffset,
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

        // barras do mesmo lado que um painel acoplado (launcher, seletor, Inicio) abrem espaco para ele (Settings.barsPanelMode):
        //   push = deslizam so ate encostar no painel (continuam visiveis); se nao couberem, saem pela borda
        //   out  = saem pela borda da tela;  sink = recolhem para dentro da moldura
        // tempo proprio (qv): saem antes do painel terminar de subir e so voltam quando ele ja recolheu boa parte
        const qv = (() => { const t = Math.max(0, Math.min(1, pp / (panel && !panel.opening ? 0.4 : 0.7))); return t * t * (3 - 2 * t) })()   // ao fechar so voltam com o painel quase recolhido
        const cover = new Array(bars.length).fill(0)
        const sepSet = {}
        const exitSet = {}
        let pRange = null, pSide = ""
        const slide = {}   // deslocamento final (px, no eixo da tela) das barras que abrem espaco
        if (pIdx >= 0) {
            const pb = bars[pIdx]
            const PL = (pb.side === "top" || pb.side === "bottom") ? W : H
            const f0 = Settings.fillet
            const mode = Settings.barsPanelMode
            const rng = (b, i) => {
                if (i < nUser && !b.full) {   // barras do usuario: largura/posicao em % (mesma conta do passo 1)
                    const a0 = edge, a1 = PL - edge
                    const w = Math.max(60, Math.min(a1 - a0, Settings.barSize(b, PL) / 100 * PL))
                    const lo = a0 + Settings.barPos(b, PL) / 100 * (a1 - a0 - w)
                    return [lo, lo + w]
                }
                const w = b.full ? PL : Math.min(b.width, Math.max(0, PL - 2 * (edge + r + f0)))
                const cs = Math.max(w / 2, Math.min(PL - w / 2, PL / 2 + (b.offset || 0)))
                return [cs - w / 2, cs + w / 2]
            }
            const pr = rng(pb, pIdx)
            pRange = pr; pSide = pb.side
            const fm = Math.max(f0, pb.fillet ?? 0)   // a curva do painel tambem ocupa espaco
            const pc = (pr[0] + pr[1]) / 2
            const lim0 = edge + r, lim1 = PL - edge - r   // ate onde uma barra empurrada pode ir (antes do canto da tela)
            const items = []
            bars.forEach((b, i) => {
                if (i === pIdx || b.side !== pb.side) return
                if (b.full) { cover[i] = qv; sepSet[i] = true; return }   // barra de ponta a ponta: sem espaco para sair, recolhe
                items.push({ i: i, r: rng(b, i), f: b.fillet ?? f0 })
            })
            // dir = -1: barras antes do painel (vao para o inicio do lado); +1: depois dele
            for (const dir of [-1, 1]) {
                const list = items.filter(o => dir < 0 ? (o.r[0] + o.r[1]) / 2 <= pc : (o.r[0] + o.r[1]) / 2 > pc)
                    .sort((a, b) => dir < 0 ? b.r[1] - a.r[1] : a.r[0] - b.r[0])   // a mais perto do painel primeiro
                let wall = dir < 0 ? pr[0] - fm : pr[1] + fm   // ate onde o painel (com a curva) ocupa
                let leaving = false                          // uma barra saiu pela borda: as de fora dela saem junto (estao no caminho)
                for (const o of list) {
                    const gap = o.f + 10
                    const clear = dir < 0 ? o.r[1] <= wall - gap : o.r[0] >= wall + gap
                    if (clear && !leaving) { wall = dir < 0 ? o.r[0] - o.f : o.r[1] + o.f; continue }
                    if (mode === "push" && !leaving) {
                        const d = dir < 0 ? (wall - gap) - o.r[1] : (wall + gap) - o.r[0]
                        const fits = dir < 0 ? o.r[0] + d - o.f >= lim0 : o.r[1] + d + o.f <= lim1
                        if (fits) {
                            slide[o.i] = d; sepSet[o.i] = true
                            wall = dir < 0 ? o.r[0] + d - o.f : o.r[1] + d + o.f
                            continue
                        }
                    }
                    if (mode === "sink") { if (!clear) { cover[o.i] = qv; sepSet[o.i] = true } continue }   // recolhida nao guarda lugar: o painel fica com a largura toda
                    // sai pela borda da tela, do lado em que ja esta
                    slide[o.i] = dir < 0 ? -(o.r[1] + 2 * fm + 8) : PL - o.r[0] + 2 * fm + 8
                    sepSet[o.i] = true; exitSet[o.i] = true
                    leaving = true
                }
            }
        }

        // barras por lado (uma barra "full" sozinha ocupa o lado todo)
        const grp = { top: [], right: [], bottom: [], left: [] }
        bars.forEach((b, i) => { if (grp[b.side]) grp[b.side].push(i) })
        // progresso de mostrar (0 = escondida, 1 = visivel) das barras com autoHide
        // "bar close" (IPC): com as barras do usuario fechadas, todas passam a seguir o progresso (as que nao se escondem tambem)
        const closed = !BarState.barsOpen
        const hides = i => bars[i].autoHide || (closed && i < nUser)
        const pf = i => (hides(i) ? Math.max(0, Math.min(1.3, prog && prog[i] !== undefined ? prog[i] : 1)) : 1) * (1 - cover[i])
        const detOf = i => i < nUser && !!bars[i].detached && !bars[i].full
        const gapOf = i => bars[i].gap ?? 8
        const thOf = i => Math.max(18, bars[i].height - edge)   // espessura da barra solta (sem a moldura)
        const tOf = i => detOf(i) ? edge + gapOf(i) + thOf(i) : bars[i].full ? Math.max(bars[i].height, edge) : Math.max(bars[i].height, edge + (bars[i].fillet ?? Settings.fillet) + (bars[i].topRadius ?? Settings.topRadius))   // altura minima: cada barra com as proprias curvas
        const inset = {}, zone = {}
        for (const s of order) {
            let idx = grp[s]
            const full = idx.find(i => bars[i].full)
            // com uma barra de ponta a ponta, so ficam o painel acoplado e as barras soltas (que flutuam acima dela)
            if (full !== undefined) idx = grp[s] = [full].concat(idx.filter(i => i === pIdx || (i !== full && i < nUser && !!bars[i].detached && !bars[i].full)))
            // espaco reservado: barra fixa reserva tudo; barra que se esconde depende de "reserve":
            //   overlay (padrao) = nao reserva (aparece por cima das janelas), always = reserva sempre, follow = acompanha a animacao
            const zone1 = i => !hides(i) || (bars[i].reserve === "always" && !closed) ? tOf(i)
                : bars[i].reserve === "follow" ? edge + (tOf(i) - edge) * Math.min(1, pf(i)) : 0
            const zmax = idx.reduce((m, i) => Math.max(m, zone1(i)), 0)
            inset[s] = idx.length ? (full !== undefined ? edge + (tOf(full) - edge) * pf(full) : edge) : (outline ? edge : -2)
            zone[s] = idx.length ? Math.max(zmax, edge) : (outline ? edge : 0)
        }

        const res = new Array(bars.length).fill(null)
        let extra = ""
        let d = "M0 0 L0 " + H + " L" + W + " " + H + " L" + W + " 0 Z "   // retangulo da tela em sentido anti-horario (o buraco e horario; fill WindingFill)

        // ---- passo 1: posicao das barras de cada lado ----
        // barras do usuario: largura e posicao em % do lado (pos 0 = encostada no inicio, 50 = centro, 100 = no fim).
        // perto das pontas (sem espaco para a curva da moldura) ela "gruda" no canto: vai ate a linha do lado vizinho
        // e o canto da moldura passa a sair do topo dela. att: -1 = canto do inicio do eixo da tela, +1 = do fim.
        // disputa de espaco: quem tem prioridade maior (paineis, notificacoes, depois a ordem das barras) fica onde pediu;
        // as outras vao para o lugar livre mais perto do que pediram, encolhem se precisar e, sem espaco, ficam escondidas.
        const SIDE = {}
        for (let k = 0; k < 4; k++) {
            const s = order[k], prev = order[(k + 3) % 4], next = order[(k + 1) % 4]
            const L = (s === "top" || s === "bottom") ? W : H
            const rev = (s === "bottom" || s === "left")   // u cresce contra o eixo da tela
            const startU = inset[prev] + r, endU = L - inset[next] - r
            const slo = rev ? L - endU : startU, shi = rev ? L - startU : endU   // limites no eixo da tela
            const lineLo = rev ? inset[next] : inset[prev], lineHi = rev ? L - inset[prev] : L - inset[next]   // linhas dos lados vizinhos
            const items = []
            for (const i of grp[s]) {
                const b = bars[i]
                const full = !!b.full
                const det = detOf(i)
                const f = full || det ? 0 : (b.fillet ?? Settings.fillet), g = full ? 0 : (b.topRadius ?? Settings.topRadius)
                const t = tOf(i)
                const p = pf(i)
                const zero = (slo + shi) / 2
                let bw, lo
                if (full) { bw = shi - slo; lo = slo }
                else if (i < nUser) {
                    const a0 = det ? lineLo + gapOf(i) : lineLo, a1 = det ? lineHi - gapOf(i) : lineHi
                    const fit = b.fit && BarState.fitLen[i] > 1 ? BarState.fitLen[i] : 0   // largura do conteudo (dock)
                    bw = Math.max(60, Math.min(a1 - a0, fit || Settings.barSize(b, L) / 100 * L))
                    lo = a0 + Settings.barPos(b, L) / 100 * (a1 - a0 - bw)
                } else {
                    const avail = Math.max(0, shi - slo - 2 * f)
                    bw = Math.max(60, Math.min(b.width, avail))
                    const slack = Math.max(0, (avail - bw) / 2)
                    lo = zero + Math.max(-slack, Math.min(slack, b.offset || 0)) - bw / 2
                }
                if (slide[i] !== undefined) lo += slide[i] * qv
                const te = full ? inset[s] : inset[s] + (t - inset[s]) * p
                const dr = Math.max(0, te - inset[s])
                const sc = (f + g) > 0 ? Math.min(1, dr / (f + g)) : 1
                const pri = i >= nUser ? -1000 + i : i   // menor = mais importante
                items.push({ i: i, f: f, g: g, t: t, fe: f * sc, ge: g * sc, te: te, p: p, sep: !!sepSet[i], det: det, full: full,
                             lo: lo, hi: lo + bw, bw: bw, zero: zero, att: 0, attU: 0, pri: pri, hidden: false, lift: 0 })
            }
            // disputa de espaco (so as que ficam na faixa principal; as afastadas pelo painel ja tem caminho proprio)
            const main = items.filter(it => !it.sep)
            const placed = []
            for (const it of main.slice().sort((a, b) => a.pri - b.pri)) {
                if (it.full) { placed.push(it); continue }
                const pad = it.det ? 8 : 0
                // trechos livres entre as ja colocadas (com espaco para as curvas das duas)
                // solta so disputa espaco com outras soltas: em cima de uma barra presa ela sobe (ver "lift" abaixo)
                const occ = placed.filter(o => it.det ? o.det : true).sort((a, b) => a.lo - b.lo)
                const gaps = []
                let a = lineLo
                for (const o of occ) {
                    gaps.push([a, o.lo - o.f - it.f - pad - (o.det ? 8 : 0)])
                    a = o.hi + o.f + it.f + pad + (o.det ? 8 : 0)
                }
                gaps.push([a, lineHi])
                let best = null, bestD = 1e9
                for (const [g0, g1] of gaps) {
                    if (g1 - g0 < it.bw) continue
                    const lo = Math.max(g0, Math.min(g1 - it.bw, it.lo))
                    const d = Math.abs(lo - it.lo)
                    if (d < bestD) { bestD = d; best = lo }
                }
                if (best === null) {   // nao cabe inteira: encolhe no maior trecho livre (ou esconde)
                    const big = gaps.reduce((m, x) => (x[1] - x[0] > m[1] - m[0] ? x : m), [0, 0])
                    if (big[1] - big[0] >= 60) { it.bw = big[1] - big[0]; best = big[0] }
                    else { it.hidden = true; continue }
                }
                it.lo = best; it.hi = best + it.bw
                // gruda no canto quando nao sobra espaco para a curva da moldura
                if (!it.det && slide[it.i] === undefined && cover[it.i] <= 0) {
                    const b = bars[it.i]
                    const want = it.i >= nUser ? (b.corner === "start" ? -1 : (b.corner === "end" ? 1 : 0)) : 0
                    if (want < 0 || it.lo < slo + it.f) { it.att = -1; it.lo = lineLo; it.hi = lineLo + it.bw }
                    else if (want > 0 || it.hi > shi - it.f) { it.att = 1; it.hi = lineHi; it.lo = lineHi - it.bw }
                    it.attU = rev ? -it.att : it.att
                }
                placed.push(it)
            }
            // barra solta sobre uma barra presa (ex.: dock acima da barra de baixo): flutua acima do topo dela
            for (const it of main) {
                if (!it.det || it.hidden) continue
                const under = main.filter(o => !o.det && !o.full && !o.hidden && o.hi > it.lo && o.lo < it.hi)
                it.lift = under.reduce((m, o) => Math.max(m, o.te - inset[s]), 0)
                it.t += it.lift
                const b = bars[it.i]
                if (!hides(it.i) || (b.reserve === "always" && !closed)) zone[s] = Math.max(zone[s], tOf(it.i) + under.reduce((m, o) => Math.max(m, o.t - edge), 0))
            }
            const hole = main.filter(it => !it.hidden && !it.det)
            const aS = hole.find(it => it.attU < 0), aE = hole.find(it => it.attU > 0)
            SIDE[s] = { L: L, rev: rev, items: items, main: hole, dets: items.filter(it => !it.hidden && it.det), startDepth: aS ? aS.te : null, endDepth: aE ? aE.te : null }
        }

        // ---- passo 2: caminho do buraco ----
        for (let k = 0; k < 4; k++) {
            const s = order[k], prev = order[(k + 3) % 4], next = order[(k + 1) % 4]
            const S = SIDE[s], L = S.L, rev = S.rev
            const base = inset[s]
            // profundidade nos dois cantos deste lado (topo da barra encostada, ou a linha da moldura)
            const vStart = S.startDepth ?? base, vEnd = S.endDepth ?? base
            const prevEnd = SIDE[prev].endDepth ?? inset[prev], nextStart = SIDE[next].startDepth ?? inset[next]
            const startU = prevEnd + r, endU = L - nextStart - r
            const items = S.items, main = S.main
            for (const it of items) {
                const t = it.t
                const rect = s === "top" ? { x: it.lo, y: 0, w: it.hi - it.lo, h: t }
                    : s === "right" ? { x: W - t, y: it.lo, w: t, h: it.hi - it.lo }
                    : s === "bottom" ? { x: it.lo, y: H - t, w: it.hi - it.lo, h: t }
                    : { x: 0, y: it.lo, w: t, h: it.hi - it.lo }
                res[it.i] = { side: s, rect: rect, lo: it.lo, hi: it.hi, zero: it.zero, vertical: !(s === "top" || s === "bottom"), t: t, cover: cover[it.i], fade: exitSet[it.i] ? Math.min(1, qv * 2.2) : 0, corner: it.att,
                              hidden: it.hidden, detached: it.det, v0: it.det ? base + it.lift + gapOf(it.i) : 0, th: it.det ? thOf(it.i) : 0, overlap: (pRange && s === pSide && it.sep) ? Math.max(0, Math.min(1, (Math.min(it.hi, pRange[1]) - Math.max(it.lo, pRange[0])) / Math.max(1, it.hi - it.lo))) : 0 }
            }

            const ul = main.map(it => ({ it: it, a: rev ? L - it.hi : it.lo, b: rev ? L - it.lo : it.hi }))
            ul.sort((x, y) => x.a - y.a)
            const P = (u, v) => pt(s, u, v, W, H)
            const arc = (rad, u, v, sweep) => rad > 0.01 ? "A" + rad + " " + rad + " 0 0 " + sweep + " " + P(u, v) + " " : "L" + P(u, v) + " "
            d += (k === 0 ? "M" : "L") + P(startU, vStart) + " "
            for (const e of ul) {
                const f = e.it.fe, g = e.it.ge, t = e.it.te
                if (e.it.attU >= 0) {   // ponta de baixo (u menor): curva da moldura + arredondamento do topo
                    d += "L" + P(e.a - f, base) + " " + arc(f, e.a, base + f, 1)
                    d += "L" + P(e.a, t - g) + " " + arc(g, e.a + g, t, 0)
                }
                if (e.it.attU <= 0) {   // ponta de cima
                    d += "L" + P(e.b - g, t) + " " + arc(g, e.b, t - g, 0)
                    d += "L" + P(e.b, base + f) + " " + arc(f, e.b + f, base, 1)
                }
            }
            d += "L" + P(endU, vEnd) + " "
            for (const it of items.filter(x => x.sep && !x.det && x.te - base > 1.5)) {   // sem fiapos quando ja quase sumiu
                const a = rev ? L - it.hi : it.lo, b = rev ? L - it.lo : it.hi
                const f = it.fe, g = it.ge, t = it.te
                extra += "M" + P(a - f, base) + " " + arc(f, a, base + f, 1) + "L" + P(a, t - g) + " " + arc(g, a + g, t, 0)
                    + "L" + P(b - g, t) + " " + arc(g, b, t - g, 0) + "L" + P(b, base + f) + " " + arc(f, b + f, base, 1) + "Z "
            }
            // barras soltas: retangulos arredondados afastados da moldura (entram/saem deslizando pela borda)
            for (const it of S.dets) {
                const a = rev ? L - it.hi : it.lo, b = rev ? L - it.lo : it.hi
                const th = thOf(it.i), v1f = base + it.lift + gapOf(it.i) + th
                const v1 = v1f - (1 - it.p) * (v1f + 6)   // p > 1 (curva elastica) passa um pouco do lugar
                const v0 = v1 - th
                const rr = Math.min(th / 2, bars[it.i].radius ?? 14)
                if (v1 <= 0.5) continue
                extra += "M" + P(a + rr, v0) + " L" + P(b - rr, v0) + " " + arc(rr, b, v0 + rr, 1)
                    + "L" + P(b, v1 - rr) + " " + arc(rr, b - rr, v1, 1) + "L" + P(a + rr, v1) + " " + arc(rr, a, v1 - rr, 1)
                    + "L" + P(a, v0 + rr) + " " + arc(rr, a + rr, v0, 1) + "Z "
            }
            // canto ate o inicio do proximo lado (sai do topo da barra encostada, se houver)
            const nx = (u, v) => pt(next, u, v, W, H)
            const q = nx(vEnd + r, nextStart)
            d += r > 0.01 ? "A" + r + " " + r + " 0 0 1 " + q + " " : "L" + q + " "
        }
        d += "Z"
        return { path: d + extra, extra: extra !== "" ? extra : "M0 0", bars: res, zone: zone, inset: inset, notif: nIdx >= 0 ? res[nIdx] : null, osd: oIdx >= 0 ? res[oIdx] : null, picker: panel && panel.kind === "picker" ? res[pIdx] : null, launcher: panel && panel.kind === "launcher" ? res[pIdx] : null, home: panel && panel.kind === "home" ? res[pIdx] : null }
    }
}
