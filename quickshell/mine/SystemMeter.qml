// CPU ou memoria (kind: "cpu" | "memory") com historico para o grafico.
// Opcoes: display (text|bar|graph|segments), label, showValue, width, height, color, warn, points, interval (ms)
import Quickshell.Io
import QtQuick

MeterView {
    id: root
    property string kind: "cpu"
    property var opts: ({})

    property real last: 0
    property real lastIdle: 0
    property int pct: 0
    property var hist: []

    display: opts.display ?? "text"
    label: opts.label ?? (kind === "cpu" ? "CPU" : "RAM")
    showValue: opts.showValue ?? (display === "text")
    w: opts.width ?? 60
    h: opts.height ?? 16
    col: opts.color ? opts.color : Settings.textColor
    warn: !!opts.warn
    value: pct / 100
    valueText: pct + "%"
    history: hist

    function push(v) {
        pct = v
        hist = hist.concat(v / 100).slice(-(opts.points ?? 30))
    }

    FileView {
        id: file
        path: root.kind === "cpu" ? "/proc/stat" : "/proc/meminfo"
        onLoaded: {
            const t = text()
            if (root.kind === "cpu") {
                const p = t.split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
                const idle = p[3] + p[4], total = p.reduce((a, b) => a + b, 0)
                if (root.last > 0) root.push(Math.round(100 * (1 - (idle - root.lastIdle) / Math.max(1, total - root.last))))
                root.last = total; root.lastIdle = idle
            } else {
                const total = Number(/MemTotal:\s+(\d+)/.exec(t)[1]), avail = Number(/MemAvailable:\s+(\d+)/.exec(t)[1])
                root.push(Math.round(100 * (1 - avail / total)))
            }
        }
    }
    Timer { interval: root.opts.interval ?? (root.display === "graph" ? 1000 : 2000); running: true; repeat: true; triggeredOnStart: true; onTriggered: file.reload() }
}
