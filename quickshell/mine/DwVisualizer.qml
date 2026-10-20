// Visualizador de audio (Cava.qml): barras, espelho, onda, pontos, anel ou aurora (faixas translucidas que ondulam). Cores do tema, da capa da musica ou uma so.
// Sem o cava instalado mostra como instalar. Pode sumir quando nada toca.
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Item {
    id: w
    property int cols: 3
    property int rows: 1
    property var opts: ({})
    property color fg: Theme.text
    property color dim: Theme.muted
    property color ac: Theme.accent
    property color ac2: Theme.tertiary            // cor companheira (o DeskView passa a do tom escolhido)
    property color cont: Theme.primaryContainer
    property color contInk: Theme.primaryContainerInk
    property bool bare: false
    function o(k) { return DeskState.opt({ type: "visualizer", opts: w.opts }, k) }
    // cava so roda com o widget visivel e algo tocando (ou editando, para ver o preview)
    readonly property bool wantCava: w.visible && (w.player !== null || DeskState.editing)
    property bool usingCava: false
    onWantCavaChanged: syncCava()
    Component.onCompleted: syncCava()
    Component.onDestruction: if (usingCava) { usingCava = false; Cava.release() }
    function syncCava() { if (wantCava && !usingCava) { usingCava = true; Cava.use() } else if (!wantCava && usingCava) { usingCava = false; Cava.release() } }

    readonly property int n: o("bars")
    readonly property real gain: o("sensitivity") / 100
    // reamostra as 64 faixas para n
    readonly property var vals: {
        const src = Cava.values, out = []
        if (!src.length) { for (let i = 0; i < n; i++) out.push(0); return out }
        for (let i = 0; i < n; i++) { const a = Math.floor(i * src.length / n), b = Math.max(a + 1, Math.floor((i + 1) * src.length / n)); let s = 0; for (let j = a; j < b; j++) s += src[j]; out.push(Math.min(1, s / (b - a) * gain)) }
        return out
    }
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? null
    property color coverCol: w.ac
    property color coverCol2: w.ac2
    property color coverCol3: w.ac
    readonly property color c1: o("colors") === "mono" ? w.fg : o("colors") === "cover" ? coverCol : w.ac
    readonly property color c2: o("colors") === "mono" ? w.fg : o("colors") === "cover" ? coverCol2 : w.ac2
    readonly property color c3: o("colors") === "mono" ? w.fg : o("colors") === "cover" ? coverCol3 : Qt.tint(w.ac, Qt.rgba(w.ac2.r, w.ac2.g, w.ac2.b, 0.5))
    // pontas que caem (peaks) e pulso do grave
    property var peaks: []
    property real bass: 0
    readonly property real bandK: o("bandH") / 100
    Connections {
        target: Cava
        function onValuesChanged() {
            const v = w.vals, p = w.peaks.length === v.length ? w.peaks.slice() : v.map(() => 0)
            for (let i = 0; i < v.length; i++) p[i] = Math.max(v[i], p[i] - 0.015)
            w.peaks = p
            const raw = Cava.values, k = Math.min(6, raw.length)
            let s = 0; for (let i = 0; i < k; i++) s += raw[i]
            w.bass = Math.min(1, (k ? s / k : 0) * w.gain)
        }
    }
    opacity: o("idleHide") && Cava.level < 0.005 && !DeskState.editing ? 0 : 1
    Behavior on opacity { NumberAnimation { duration: 600 } }

    // cor da capa (media de uma miniatura)
    Image { id: art; visible: false; source: w.o("colors") === "cover" && w.player ? (w.player.trackArtUrl ?? "") : ""; sourceSize: Qt.size(8, 8); asynchronous: true
        onStatusChanged: if (status === Image.Ready) grab.requestPaint() }
    Canvas {
        id: grab; visible: false; width: 8; height: 8
        onPaint: {
            const c = getContext("2d"); c.drawImage(art, 0, 0, 8, 8)
            const d = c.getImageData(0, 0, 8, 8).data
            // as 3 cores mais saturadas e distintas, clareadas para ler em cima de qualquer fundo
            const cand = []
            for (let i = 0; i < d.length; i += 4) { const mx = Math.max(d[i], d[i + 1], d[i + 2]), mn = Math.min(d[i], d[i + 1], d[i + 2]); cand.push({ s: mx - mn, c: [d[i], d[i + 1], d[i + 2]] }) }
            cand.sort((a, b) => b.s - a.s)
            const pick = []
            for (const x of cand) {
                if (pick.every(p => Math.abs(p[0] - x.c[0]) + Math.abs(p[1] - x.c[1]) + Math.abs(p[2] - x.c[2]) > 90)) pick.push(x.c)
                if (pick.length === 3) break
            }
            while (pick.length < 3) pick.push(pick[pick.length - 1] ?? [128, 128, 128])
            const lift = p => { const k = Math.max(0, 150 - Math.max(p[0], p[1], p[2])); return Qt.rgba(Math.min(255, p[0] + k) / 255, Math.min(255, p[1] + k) / 255, Math.min(255, p[2] + k) / 255, 1) }
            w.coverCol = lift(pick[0]); w.coverCol2 = lift(pick[1]); w.coverCol3 = lift(pick[2])
        }
    }

    Column {
        visible: !Cava.available
        anchors.centerIn: parent
        spacing: 6
        UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "pulse"; size: 26; color: w.dim }
        UiText { anchors.horizontalCenter: parent.horizontalCenter; text: "Precisa do cava:"; color: w.fg; font.pixelSize: 13 }
        UiText { anchors.horizontalCenter: parent.horizontalCenter; text: "sudo pacman -S cava"; color: w.ac; font.pixelSize: 13; font.family: Theme.mono }
    }

    // capa no meio do anel
    RoundImage {
        readonly property real d: Math.min(w.width, w.height) * 0.26 * w.o("ringSize") / 100 * 2 * (w.o("pulse") ? 1 + 0.1 * w.bass : 1) - 10
        visible: Cava.available && w.o("vstyle") === "ring" && w.o("cover") && w.player && w.player.trackArtUrl && ready
        anchors.centerIn: parent
        width: Math.max(8, d); height: width; radius: width / 2
        source: w.player ? (w.player.trackArtUrl ?? "") : ""
    }
    Canvas {
        id: cv
        visible: Cava.available && w.opacity > 0.01
        readonly property string st: w.o("vstyle")
        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
        height: st !== "ring" ? parent.height * w.bandK : parent.height
        Connections { target: Cava; function onValuesChanged() { cv.requestPaint() } }
        onPaint: {
            const c = getContext("2d"); c.reset()
            const v = w.vals, n = v.length, W = width, H = height
            const grad = c.createLinearGradient(0, H, 0, 0)
            grad.addColorStop(0, w.c1); grad.addColorStop(st === "ring" ? 0.5 : 1, w.c2); if (st === "ring") grad.addColorStop(1, w.c3)
            c.fillStyle = grad; c.strokeStyle = grad
            if (st === "bars" || st === "mirror") {
                const bw = W / n
                for (let i = 0; i < n; i++) {
                    const h = Math.max(2, v[i] * (st === "mirror" ? H / 2 : H) * (w.o("pulse") ? 1 + 0.12 * w.bass : 1))
                    const x = i * bw + bw * 0.15, ww = bw * 0.7, r = Math.min(ww / 2, 6)
                    const y = st === "mirror" ? H / 2 - h : H - h, hh = st === "mirror" ? h * 2 : h
                    c.beginPath(); c.roundedRect(x, y, ww, hh, r, r); c.fill()
                    if (w.o("peaks") && st === "bars" && w.peaks[i] !== undefined) {
                        const py = H - Math.max(2, w.peaks[i] * H) - 5
                        c.beginPath(); c.roundedRect(x, Math.max(0, py), ww, 3, 1.5, 1.5); c.fill()
                    }
                }
            } else if (st === "wave") {
                c.lineWidth = 3; c.lineJoin = "round"
                c.beginPath()
                for (let i = 0; i < n; i++) { const x = i / (n - 1) * W, y = H - v[i] * H * 0.9 - 2; i ? c.lineTo(x, y) : c.moveTo(x, y) }
                c.stroke()
                c.lineTo(W, H); c.lineTo(0, H); c.closePath(); c.globalAlpha = 0.25; c.fill()
            } else if (st === "dots") {
                const bw = W / n, rows = Math.max(4, Math.floor(H / (bw * 0.9)))
                for (let i = 0; i < n; i++) for (let j = 0; j < rows; j++) {
                    if (j / rows > v[i]) break
                    c.beginPath(); c.arc(i * bw + bw / 2, H - j * (H / rows) - bw / 2, bw * 0.32, 0, Math.PI * 2); c.fill()
                }
            } else if (st === "aurora") {
                // tres faixas suaves (destaque, companheira e uma mistura), cada uma com a fase andando no tempo
                const t = Date.now() / 1000, cols = [w.c1, w.c2, w.c3]
                const sm = []
                for (let i = 0; i < n; i++) sm.push(((v[i - 1] ?? v[i]) + v[i] * 2 + (v[i + 1] ?? v[i])) / 4)
                for (let k = 0; k < 3; k++) {
                    const g = c.createLinearGradient(0, H, 0, 0), col = cols[k]
                    g.addColorStop(0, Qt.rgba(col.r, col.g, col.b, 0.55)); g.addColorStop(1, Qt.rgba(col.r, col.g, col.b, 0))
                    c.fillStyle = g
                    const pts = []
                    for (let i = 0; i <= 24; i++) {
                        const f = i / 24, idx = Math.min(n - 1, Math.floor(f * n)), amp = sm[(idx + k * Math.floor(n / 3)) % n]
                        pts.push([f * W, H - (0.12 + amp * 0.8) * H * (0.55 + 0.45 * Math.sin(t * (0.6 + k * 0.25) + f * 5 + k * 2.1) * 0.5 + 0.225)])
                    }
                    c.beginPath(); c.moveTo(0, H); c.lineTo(pts[0][0], pts[0][1])
                    for (let i = 1; i < pts.length; i++) { const mx = (pts[i - 1][0] + pts[i][0]) / 2, my = (pts[i - 1][1] + pts[i][1]) / 2; c.quadraticCurveTo(pts[i - 1][0], pts[i - 1][1], mx, my) }
                    c.lineTo(W, pts[pts.length - 1][1]); c.lineTo(W, H); c.closePath(); c.fill()
                }
            } else {   // anel
                const cx = W / 2, cy = H / 2, ms = Math.min(W, H), R = ms * 0.26 * w.o("ringSize") / 100 * (w.o("pulse") ? 1 + 0.1 * w.bass : 1)
                c.lineWidth = Math.max(2, Math.PI * 2 * R / n * 0.55); c.lineCap = "round"
                for (let i = 0; i < n; i++) {
                    const a = i / n * Math.PI * 2 - Math.PI / 2, len = 4 + v[i] * ms * 0.22 * w.o("ringSize") / 100
                    c.beginPath(); c.moveTo(cx + Math.cos(a) * R, cy + Math.sin(a) * R); c.lineTo(cx + Math.cos(a) * (R + len), cy + Math.sin(a) * (R + len)); c.stroke()
                }
            }
        }
    }
}
