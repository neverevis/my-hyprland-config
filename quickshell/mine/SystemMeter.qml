// CPU, memoria, disco ou swap (kind: "cpu" | "memory" | "disk" | "swap") com historico para o grafico.
// Opcoes: display (text|bar|graph|segments|ring|disc), label, showValue, width, height, color, warn, warnAt (%), points, interval (ms)
// CPU e memoria leem /proc direto; disco e swap vem do SysInfo (scripts/sysinfo.py).
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
    readonly property bool viaInfo: kind === "disk" || kind === "swap"
    readonly property var meta: ({ cpu: { label: "CPU", icon: "chip", warn: 90 }, memory: { label: "RAM", icon: "memory", warn: 95 },
                                   disk: { label: "DSK", icon: "disk", warn: 90 }, swap: { label: "SWP", icon: "swap_vertical", warn: 85 } })[kind]

    display: opts.display ?? "text"
    label: opts.label ?? meta.label
    showValue: opts.showValue ?? (display === "text")
    w: opts.width ?? 60
    h: opts.height ?? (round ? 22 : 16)
    col: opts.color ? opts.color : (Settings.themeOn ? ThemeColors.primary : Settings.textColor)   // sem cor escolhida: destaque do tema (se ligado)
    warn: !!opts.warn
    warnAt: opts.warnAt ?? meta.warn
    icon: meta.icon
    value: pct / 100
    valueText: pct + "%"
    history: hist
    // swap: sem swap no sistema, o modulo some
    present: kind !== "swap" || !!SysInfo.d.swapTotal

    function push(v) {
        pct = v
        hist = hist.concat(v / 100).slice(-(opts.points ?? 30))
    }

    Component.onCompleted: if (viaInfo) SysInfo.use()
    Component.onDestruction: if (viaInfo) SysInfo.release()
    function fromInfo() {
        if (kind === "disk") push(Math.round(SysInfo.disk * 100))
        else if (SysInfo.d.swapTotal) push(Math.round(100 * SysInfo.d.swapUsed / SysInfo.d.swapTotal))
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
    Timer { interval: root.opts.interval ?? (root.display === "graph" ? 1000 : 2000); running: true; repeat: true; triggeredOnStart: true
        onTriggered: if (root.viaInfo) root.fromInfo(); else file.reload() }
}
