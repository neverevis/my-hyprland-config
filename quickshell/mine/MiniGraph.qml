// Grafico de linha pequeno com preenchimento em degrade. values = lista de numeros; max = topo (0 = automatico).
import QtQuick

Canvas {
    id: g
    property var values: []
    property real max: 100
    property color color: Theme.accent
    property color color2: "transparent"   // segunda serie opcional (values2)
    property var values2: []
    onValuesChanged: requestPaint()
    onValues2Changed: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()

    function series(ctx, vals, col, top) {
        if (vals.length < 2) return
        const n = vals.length, w = width, h = height - 2
        const px = i => i / (n - 1) * w
        const py = v => 1 + h - Math.max(0, Math.min(1, (v / top) || 0)) * h
        ctx.beginPath()
        ctx.moveTo(px(0), py(vals[0]))
        for (let i = 1; i < n; i++) {
            ctx.lineTo(px(i), py(vals[i]))   // segmentos retos: nao inventa valores
        }
        ctx.lineWidth = 2
        ctx.strokeStyle = col
        ctx.stroke()
        ctx.lineTo(w, height); ctx.lineTo(0, height); ctx.closePath()
        const grad = ctx.createLinearGradient(0, 0, 0, height)
        grad.addColorStop(0, Qt.rgba(col.r, col.g, col.b, 0.14))
        grad.addColorStop(1, Qt.rgba(col.r, col.g, col.b, 0))
        ctx.fillStyle = grad
        ctx.fill()
    }
    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        let top = max
        if (top <= 0) top = Math.max(1, ...values, ...values2) * 1.15
        series(ctx, values2, color2, top)
        series(ctx, values, color, top)
    }
}
