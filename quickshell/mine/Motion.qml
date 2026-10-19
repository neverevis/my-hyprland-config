// Motor das animacoes nomeadas (os dados ficam em Settings.animCfg): resolve qual animacao usar em cada lugar,
// e transforma cada uma numa curva que o Qt toca (easing.bezierCurve) e que o Hyprland entende.
// Dois tipos:
//   bezier: cubica classica (x1, y1, x2, y2 em centesimos) + duracao
//   spring: mola fisica (massa, rigidez, amortecimento), igual a do Hyprland 0.56. A duracao sai da fisica; no QML
//           a mola vira uma spline de varios trechos (Hermite entre os extremos), entao o mesmo NumberAnimation toca as duas.
// Velocidade global (animCfg.speed): divide as duracoes; nas molas, escala rigidez e amortecimento (mesmo movimento, mais rapido).
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property real speed: Math.max(0.25, Math.min(3, Settings.animCfg && Settings.animCfg.speed ? Settings.animCfg.speed : 1))

    // ---------- mola: solucao exata de m x'' + c x' + k x = 0, com x(0) = 1, v(0) = 0 (x = distancia que falta) ----------
    function springFn(m, k, c) {
        m = Math.max(0.5, m); k = Math.max(0.5, k); c = Math.max(0.5, c)
        const w0 = Math.sqrt(k / m), z = c / (2 * Math.sqrt(k * m))
        if (z < 0.999) {
            const wd = w0 * Math.sqrt(1 - z * z), a = z * w0
            return { z: z, w0: w0, wd: wd,
                x: t => Math.exp(-a * t) * (Math.cos(wd * t) + a / wd * Math.sin(wd * t)),
                v: t => -Math.exp(-a * t) * (w0 * w0 / wd) * Math.sin(wd * t) }
        }
        if (z <= 1.001)
            return { z: 1, w0: w0, wd: 0, x: t => (1 + w0 * t) * Math.exp(-w0 * t), v: t => -w0 * w0 * t * Math.exp(-w0 * t) }
        const s = Math.sqrt(z * z - 1), r1 = -w0 * (z - s), r2 = -w0 * (z + s), A = r2 / (r2 - r1), B = -r1 / (r2 - r1)
        return { z: z, w0: w0, wd: 0, x: t => A * Math.exp(r1 * t) + B * Math.exp(r2 * t), v: t => A * r1 * Math.exp(r1 * t) + B * r2 * Math.exp(r2 * t) }
    }

    // resumo fisico de uma mola: duracao ate assentar (ms), quanto passa do ponto (%) e quantas vezes balanca
    function springInfo(a) {
        const f = springFn(a.mass ?? 1, a.stiffness ?? 200, a.dampening ?? 20)
        // balancos: lobos depois de passar do alvo pela primeira vez, com mais de 0,5% de amplitude
        let last = 0, peak = 0, swings = 0, side = 1, lobe = 0, crossed = false
        for (let t = 0.001; t < 6; t += 0.001) {
            const x = f.x(t)
            if (Math.abs(x) > 0.002) last = t
            if (x < 0 && -x > peak) peak = -x
            if (x * side < 0) { if (crossed && lobe > 0.005) swings++; crossed = true; side = -side; lobe = 0 }
            lobe = Math.max(lobe, Math.abs(x))
            if (t - last > 0.4) break
        }
        if (crossed && lobe > 0.005) swings++
        return { f: f, T: Math.max(0.05, last), overshoot: peak * 100, swings: swings }
    }

    // ---------- cache: cada animacao vira { duration, curve, sample(u) } uma vez so ----------
    property var cache: ({})
    function keyOf(a) { return [a.type ?? "bezier", a.x1, a.y1, a.x2, a.y2, a.duration, a.mass, a.stiffness, a.dampening].join("|") }

    function bezierY(a, u) {
        const x1 = a.x1 / 100, y1 = a.y1 / 100, x2 = a.x2 / 100, y2 = a.y2 / 100
        const bx = s => 3 * (1 - s) * (1 - s) * s * x1 + 3 * (1 - s) * s * s * x2 + s * s * s
        const by = s => 3 * (1 - s) * (1 - s) * s * y1 + 3 * (1 - s) * s * s * y2 + s * s * s
        let lo = 0, hi = 1
        for (let i = 0; i < 22; i++) { const md = (lo + hi) / 2; if (bx(md) < u) lo = md; else hi = md }
        return by((lo + hi) / 2)
    }

    function compile(a) {
        const key = keyOf(a)
        const hit = cache[key]
        if (hit) return hit
        let r
        if ((a.type ?? "bezier") === "spring") {
            const inf = springInfo(a), f = inf.f, T = inf.T
            // pontos de controle: quartos de oscilacao (subamortecida) ou espacamento denso no comeco (amortecida)
            let knots = []
            if (f.wd > 0 && f.z < 0.85) {
                const q = Math.PI / (4 * f.wd)
                for (let t = q; t < T - q * 0.25; t += q) knots.push(t / T)
            } else {
                for (let i = 1; i < 14; i++) knots.push(Math.pow(i / 14, 1.6))
            }
            knots.push(1)
            const P = u => u >= 1 ? 1 : 1 - f.x(u * T)
            const D = u => u >= 1 ? 0 : -f.v(u * T) * T
            const curve = []
            let u0 = 0, p0 = 0, d0 = 0
            for (const u1 of knots) {
                const h = u1 - u0, p1 = P(u1), d1 = D(u1)
                curve.push(u0 + h / 3, p0 + d0 * h / 3, u1 - h / 3, p1 - d1 * h / 3, u1, p1)
                u0 = u1; p0 = p1; d0 = d1
            }
            r = { duration: Math.round(T * 1000), curve: curve, sample: P, overshoot: inf.overshoot, swings: inf.swings, spring: true }
        } else {
            r = { duration: a.duration ?? 300, curve: [a.x1 / 100, a.y1 / 100, a.x2 / 100, a.y2 / 100, 1, 1], sample: u => bezierY(a, u),
                  overshoot: Math.max(0, Math.max(a.y1, a.y2) - 100), swings: 0, spring: false }
        }
        cache[key] = r
        return r
    }

    // pontos para desenhar a curva (u de 0 a 1, n trechos)
    function points(a, n) {
        const c = compile(a), pts = []
        for (let i = 0; i <= n; i++) pts.push([i / n, c.sample(i / n)])
        return pts
    }

    // ---------- qual animacao usar em cada lugar ----------
    function nameFor(target, out) {
        const cfg = Settings.animCfg ?? {}
        const use = cfg.use ?? {}
        const inName = use[target] ?? Settings.animDefaults[target] ?? "Padrão"
        if (!out) return inName
        const v = (cfg.out ?? {})[target]
        if (v === "") return inName   // escolhido "igual a abrir"
        return v ?? Settings.animOutDefaults[target] ?? inName
    }
    function animFor(target, out) {
        return Settings.findAnim(nameFor(target, out)) ?? Settings.findAnim(Settings.animDefaults[target] ?? "Padrão") ?? Settings.builtinAnims[0]
    }
    // { duration (ms, ja com a velocidade global), curve (para easing.bezierCurve) }
    function of(target, out) {
        const c = compile(animFor(target, !!out))
        return { duration: Math.round(c.duration / speed), curve: c.curve }
    }
    function durationOf(target, out) { return of(target, out).duration }

    // ---------- Hyprland ----------
    // trecho de config Lua de uma animacao (curva com nome proprio + a folha que usa ela)
    function hyprCurve(id, a) {
        if ((a.type ?? "bezier") === "spring") {
            const s = speed
            return 'hl.curve("' + id + '", { type = "spring", mass = ' + (a.mass ?? 1).toFixed(2) + ', stiffness = ' + ((a.stiffness ?? 200) * s * s).toFixed(2)
                + ', dampening = ' + ((a.dampening ?? 20) * s).toFixed(2) + ' })'
        }
        return 'hl.curve("' + id + '", { type = "bezier", points = { { ' + (a.x1 / 100).toFixed(2) + ', ' + (a.y1 / 100).toFixed(2) + ' }, { '
            + (a.x2 / 100).toFixed(2) + ', ' + (a.y2 / 100).toFixed(2) + ' } } })'
    }
    function hyprLeaf(leaf, id, a, style) {
        const spring = (a.type ?? "bezier") === "spring"
        const sp = spring ? 1 : Math.max(0.1, (a.duration ?? 300) / speed / 100)
        return 'hl.animation({ leaf = "' + leaf + '", enabled = true, speed = ' + sp.toFixed(2) + ', ' + (spring ? "spring" : "bezier") + ' = "' + id + '"'
            + (style ? ', style = "' + style + '"' : "") + ' })'
    }
    // tudo o que o Hyprland deve usar (vazio quando o Hyprland nao segue o shell)
    function hyprLua() {
        const cfg = Settings.animCfg ?? {}
        if (!cfg.hypr) return ""
        const st = cfg.hyprStyle ?? {}
        const lines = []
        for (const t of Settings.animTargets) {
            if (!t.hypr) continue
            for (const ph of t.phases ? [false, true] : [false]) {
                const leaf = ph ? t.hypr[1] : t.hypr[0]
                if (!leaf) continue
                const id = "mine_" + leaf
                const a = animFor(t.id, ph)
                lines.push(hyprCurve(id, a))
                lines.push(hyprLeaf(leaf, id, a, t.style ? (st[t.style] ?? Settings.hyprStyleDefaults[t.style]) : ""))
            }
        }
        return lines.join("\n")
    }

    // ---------- "Testar": abre e fecha a coisa de verdade, com a animacao escolhida ----------
    readonly property var testable: ["launcher", "home", "picker", "notifications", "power", "settings", "osd"]
    function canTest(target) { return testable.indexOf(target) >= 0 }
    property string testing: ""
    function setOpen(target, on) {
        if (target === "launcher") Settings.launcherOpen = on
        else if (target === "home") Settings.homeOpen = on
        else if (target === "picker") Settings.wpPickerOpen = on
        else if (target === "power") Power.menuOpen = on
        else if (target === "settings") Settings.settingsOpen = on
    }
    function test(target) {
        if (target === "notifications") { notify.running = true; return }
        if (target === "osd") { Osd.preview(); return }
        testing = target
        if (target === "settings") { setOpen(target, false); testT.interval = durationOf(target, true) + 450 }
        else { setOpen(target, true); testT.interval = durationOf(target, false) + 900 }
        testT.restart()
    }
    Timer { id: testT; onTriggered: { root.setOpen(root.testing, root.testing === "settings"); root.testing = "" } }
    Process { id: notify; command: ["notify-send", "-a", "Animações", "Teste de animação", "É assim que as notificações entram e saem."] }
}
