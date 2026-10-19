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
    Component.onCompleted: Cava.use()
    Component.onDestruction: Cava.release()

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
    readonly property color c1: o("colors") === "mono" ? w.fg : o("colors") === "cover" ? coverCol : w.ac
    readonly property color c2: o("colors") === "mono" ? w.fg : w.ac2
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
            let r = 0, g = 0, b = 0, best = 0
            for (let i = 0; i < d.length; i += 4) { const s = Math.max(d[i], d[i + 1], d[i + 2]) - Math.min(d[i], d[i + 1], d[i + 2]); if (s >= best) { best = s; r = d[i]; g = d[i + 1]; b = d[i + 2] } }
            w.coverCol = Qt.rgba(r / 255, g / 255, b / 255, 1)
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

    Canvas {
        id: cv
        visible: Cava.available
        anchors.fill: parent
        readonly property string st: w.o("vstyle")
        Connections { target: Cava; function onValuesChanged() { cv.requestPaint() } }
        onPaint: {
            const c = getContext("2d"); c.reset()
            const v = w.vals, n = v.length, W = width, H = height
            const grad = c.createLinearGradient(0, H, 0, 0)
            grad.addColorStop(0, w.c1); grad.addColorStop(1, w.c2)
            c.fillStyle = grad; c.strokeStyle = grad
            if (st === "bars" || st === "mirror") {
                const bw = W / n
                for (let i = 0; i < n; i++) {
                    const h = Math.max(2, v[i] * (st === "mirror" ? H / 2 : H))
                    const x = i * bw + bw * 0.15, ww = bw * 0.7, r = Math.min(ww / 2, 6)
                    const y = st === "mirror" ? H / 2 - h : H - h, hh = st === "mirror" ? h * 2 : h
                    c.beginPath(); c.roundedRect(x, y, ww, hh, r, r); c.fill()
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
                const t = Date.now() / 1000, cols = [w.c1, w.c2, Qt.tint(w.c1, Qt.rgba(w.c2.r, w.c2.g, w.c2.b, 0.5))]
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
                const cx = W / 2, cy = H / 2, R = Math.min(W, H) * 0.26
                c.lineWidth = Math.max(2, Math.PI * 2 * R / n * 0.55); c.lineCap = "round"
                for (let i = 0; i < n; i++) {
                    const a = i / n * Math.PI * 2 - Math.PI / 2, len = 4 + v[i] * Math.min(W, H) * 0.22
                    c.beginPath(); c.moveTo(cx + Math.cos(a) * R, cy + Math.sin(a) * R); c.lineTo(cx + Math.cos(a) * (R + len), cy + Math.sin(a) * (R + len)); c.stroke()
                }
            }
        }
    }
}
