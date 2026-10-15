// Gera a paleta do tema a partir do wallpaper atual (ThemeColors.t).
// Principal: scripts/material.py (Material You, a mesma biblioteca do Caelestia), rodando no venv do Python.
// Se o venv/biblioteca nao existir, usa o calculo proprio abaixo (Canvas) como reserva.
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    width: 1; height: 1
    readonly property string src: Wallpaper.current
    readonly property string mode: Settings.themeModeEff
    readonly property string variant: Settings.themeVariant
    readonly property string py: Quickshell.env("HOME") + "/.local/share/quickshell-mine/venv/bin/python"
    readonly property string script: Qt.resolvedUrl("scripts/material.py").toString().replace("file://", "")
    property bool pyOk: true   // falhou uma vez: usa so a reserva
    property var cache: ({})   // caminho -> { h1, s1, h2, h3, s2, s3 }
    property var memo: ({})    // wallpaper|modo|estilo -> papeis do Material (resultado do script)
    property string runKey: ""

    readonly property string source: Settings.themeSource
    readonly property string preset: Settings.themePreset
    onSourceChanged: if (Settings.themeOn) load()
    onPresetChanged: if (Settings.themeOn && source === "preset") load()
    onSrcChanged: if (Settings.themeOn && source === "wallpaper") load()
    onModeChanged: if (Settings.themeOn) load()
    onVariantChanged: if (Settings.themeOn) load()
    Connections { target: Settings; function onThemeOnChanged() { if (Settings.themeOn) root.load() } }
    Component.onCompleted: if (Settings.themeOn) load()

    function load() {
        if (source === "preset") { apply(Presets.toMaterial(Presets.find(preset))); return }
        if (!src) return
        if (pyOk) {
            const key = src + "|" + mode + "|" + variant
            if (memo[key]) { apply(memo[key]); return }   // ja calculado nesta sessao: sem rodar o Python de novo
            runKey = key
            runner.command = [py, script, src, mode, variant]; runner.running = false; runner.running = true
            return
        }
        fallback()
    }
    function fallback() {
        if (cache[src]) { build(); return }
        cv.url = "file://" + src
        cv.loadImage(cv.url)
    }

    // papeis do Material You -> os papeis usados pelo shell
    function apply(m) {
        ThemeColors.m = m
        setTarget({
            primary: m.primary, onPrimary: m.onPrimary, secondary: m.secondary, tertiary: m.tertiary,
            primaryContainer: m.primaryContainer, secondaryContainer: m.secondaryContainer, tertiaryContainer: m.tertiaryContainer,
            background: m.background, surface: m.surfaceContainer, surfaceHigh: m.surfaceContainerHigh,
            outline: m.outline, text: m.onSurface, muted: m.onSurfaceVariant, error: m.error
        })
    }

    // ---- fade entre paletas: interpola de cor em cor (sem Behavior no singleton, que derrubava o shell) ----
    // passos a ~30 por segundo (e nao a cada quadro): cada passo recalcula todas as cores do shell e das janelas abertas
    property var fromT: ({})
    property var toT: ({})
    property real mix: 1
    readonly property int fadeMs: 600
    property real fadeStart: 0
    function setTarget(t) {
        const cur = ThemeColors.t
        if (!cur || cur.primary === undefined) { ThemeColors.t = t; toT = t; return }   // primeira paleta: sem fade
        if (Object.keys(t).every(k => String(cur[k]) === String(t[k]))) return       // mesma paleta: nada a fazer
        fromT = cur; toT = t
        fadeStart = Date.now()
        ThemeColors.fading = true
        step.restart()
    }
    Timer {
        id: step
        interval: 33; repeat: true; triggeredOnStart: true
        onTriggered: {
            const x = Math.min(1, (Date.now() - root.fadeStart) / root.fadeMs)
            root.mix = 1 - Math.pow(1 - x, 3)   // OutCubic
            if (x >= 1) { stop(); ThemeColors.fading = false }
        }
    }
    onMixChanged: {
        if (!toT.primary) return
        if (mix >= 1) { ThemeColors.t = toT; return }
        const out = {}
        for (const k in toT) {
            const a = Qt.color(fromT[k] ?? toT[k]), b = Qt.color(toT[k])
            out[k] = Qt.rgba(a.r + (b.r - a.r) * mix, a.g + (b.g - a.g) * mix, a.b + (b.b - a.b) * mix, 1)
        }
        ThemeColors.t = out
    }
    Process {
        id: runner
        stdout: StdioCollector {
            onStreamFinished: {
                // saida vazia = execucao interrompida por uma mais nova (troca rapida de wallpaper/modo): so ignora
                if (text.trim() === "") return
                try { const m = JSON.parse(text); root.memo[root.runKey] = m; root.apply(m) }
                catch (e) { console.warn("paleta: saida invalida do material.py, usando a reserva: " + e); root.pyOk = false; root.fallback() }
            }
        }
        // 9/15 = morto de proposito ao reiniciar (nao e falha)
        onExited: code => { if (code !== 0 && code !== 9 && code !== 15) { console.warn("paleta: material.py saiu com " + code + ", usando a reserva"); root.pyOk = false; root.fallback() } }
    }

    // ---- cor ----
    function rgb2hsl(r, g, b) {
        r /= 255; g /= 255; b /= 255
        const mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2, d = mx - mn
        let h = 0, s = 0
        if (d > 0) {
            s = d / (1 - Math.abs(2 * l - 1))
            if (mx === r) h = ((g - b) / d) % 6
            else if (mx === g) h = (b - r) / d + 2
            else h = (r - g) / d + 4
            h *= 60; if (h < 0) h += 360
        }
        return [h, s, l]
    }
    function hsl(h, s, l) {   // -> "#rrggbb"
        h = ((h % 360) + 360) % 360; s = Math.max(0, Math.min(1, s)); l = Math.max(0, Math.min(1, l))
        const c = (1 - Math.abs(2 * l - 1)) * s, x = c * (1 - Math.abs((h / 60) % 2 - 1)), m = l - c / 2
        let r = 0, g = 0, b = 0
        if (h < 60) { r = c; g = x } else if (h < 120) { r = x; g = c } else if (h < 180) { g = c; b = x }
        else if (h < 240) { g = x; b = c } else if (h < 300) { r = x; b = c } else { r = c; b = x }
        const to = v => ("0" + Math.round((v + m) * 255).toString(16)).slice(-2)
        return "#" + to(r) + to(g) + to(b)
    }

    // ---- analise: histograma de matiz ponderado por saturacao ----
    function analyze(data, n) {
        const bins = new Array(36).fill(0), sat = new Array(36).fill(0), cnt = new Array(36).fill(0)
        const sx = new Array(36).fill(0), sy = new Array(36).fill(0)
        for (let i = 0; i < n; i++) {
            const r = data[i * 4], g = data[i * 4 + 1], b = data[i * 4 + 2]
            const [h, s, l] = rgb2hsl(r, g, b)
            if (l < 0.12 || l > 0.95 || s < 0.12) continue
            const w = s * s * (1 - Math.abs(2 * l - 1))
            const k = Math.floor(h / 10) % 36
            bins[k] += w; sat[k] += s * w; cnt[k] += w
            sx[k] += Math.cos(h * Math.PI / 180) * w; sy[k] += Math.sin(h * Math.PI / 180) * w
        }
        const order = bins.map((w, k) => k).sort((a, b) => bins[b] - bins[a])
        const total = bins.reduce((a, b) => a + b, 0)
        if (total < 0.5) return { h1: 260, s1: 0.2, h2: 290, h3: 230, s2: 0.2, s3: 0.2 }   // wallpaper quase cinza
        const pick = (k) => {   // matiz medio (circular) em k-1..k+1
            let x = 0, y = 0, sw = 0, w = 0
            for (const j of [k - 1, k, k + 1]) { const q = (j + 36) % 36; x += sx[q]; y += sy[q]; sw += sat[q]; w += cnt[q] }
            return { h: (Math.atan2(y, x) * 180 / Math.PI + 360) % 360, s: w > 0 ? sw / w : 0.5, w: w }
        }
        const dist = (a, b) => { const d = Math.abs(a - b) % 360; return Math.min(d, 360 - d) }
        const first = pick(order[0]), found = [first]
        for (const k of order.slice(1)) {
            if (found.length >= 3) break
            const c = pick(k)
            if (c.w < total * 0.04) continue
            if (found.every(f => dist(f.h, c.h) >= 40)) found.push(c)
        }
        const f2 = found[1] ?? { h: first.h + 35, s: first.s }
        const f3 = found[2] ?? { h: first.h + 140, s: first.s }
        return { h1: first.h, s1: first.s, h2: f2.h, s2: f2.s, h3: f3.h, s3: f3.s }
    }

    function build() {
        const a = cache[src]
        if (!a) return
        const dark = Settings.themeModeEff !== "light"
        const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v))
        const s1 = clamp(a.s1, 0.5, 0.85), s2 = clamp(a.s2 * 0.9, 0.38, 0.75), s3 = clamp(a.s3 * 0.9, 0.38, 0.75)
        const tone = dark ? 0.76 : 0.40
        setTarget({
            primary: hsl(a.h1, s1, tone),
            onPrimary: hsl(a.h1, 0.35, dark ? 0.13 : 0.97),
            secondary: hsl(a.h2, s2, dark ? 0.72 : 0.42),
            tertiary: hsl(a.h3, s3, dark ? 0.72 : 0.42),
            background: hsl(a.h1, dark ? 0.22 : 0.28, dark ? 0.075 : 0.96),
            surface: hsl(a.h1, dark ? 0.2 : 0.25, dark ? 0.11 : 0.93),
            surfaceHigh: hsl(a.h1, dark ? 0.18 : 0.22, dark ? 0.17 : 0.88),
            outline: hsl(a.h1, dark ? 0.14 : 0.18, dark ? 0.32 : 0.72),
            text: hsl(a.h1, 0.2, dark ? 0.92 : 0.12),
            muted: hsl(a.h1, 0.1, dark ? 0.66 : 0.38),
            error: dark ? "#ff8a9a" : "#ba1a3a"
        })
    }

    // canvas de amostragem: o wallpaper reduzido a 64x36
    Canvas {
        id: cv
        property string url: ""
        x: -200; y: -200   // visivel (o Canvas so pinta assim), mas fora da tela
        width: 64; height: 36
        onImageLoaded: requestPaint()
        onPaint: {
            if (!url || !isImageLoaded(url)) return
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, 64, 36)
            ctx.drawImage(url, 0, 0, 64, 36)
            const d = ctx.getImageData(0, 0, 64, 36).data
            const res = root.analyze(d, 64 * 36)
            unloadImage(url)
            const c = root.cache
            c[root.src] = res
            root.cache = c
            root.build()
        }
    }
}
