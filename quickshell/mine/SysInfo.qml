// Dados do sistema compartilhados (scripts/sysinfo.py: uma linha JSON por segundo), so enquanto alguem usa
// (SysInfo.use()/release(): widgets, modulos da barra). Guarda historico (60 amostras) para os graficos.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property int users: 0
    function use() { users++ }
    function release() { users = Math.max(0, users - 1) }
    readonly property string script: Qt.resolvedUrl("scripts/sysinfo.py").toString().replace("file://", "")

    property var d: ({})
    property var info: ({})        // estatico: cpuModel, cores, distro, kernel, wm, host
    property var disks: []
    property var hist: ({ cpu: [], mem: [], gpu: [], rx: [], tx: [] })
    readonly property real cpu: (d.cpu ?? 0) / 100
    readonly property real mem: d.memTotal ? d.memUsed / d.memTotal : 0
    readonly property real gpu: d.gpu ? (d.gpu.usage ?? 0) / 100 : 0
    readonly property real disk: disks.length ? disks[0].used / disks[0].total : 0
    readonly property var temp: d.cpuTemp ?? null
    readonly property var gpuTemp: d.gpu ? d.gpu.temp : null
    function bytes(b) { const u = ["B", "KB", "MB", "GB", "TB"]; let i = 0; while (b >= 1024 && i < 4) { b /= 1024; i++ } return (i ? b.toFixed(b < 10 ? 1 : 0) : Math.round(b)) + " " + u[i] }

    Process {
        running: root.users > 0
        command: ["python3", root.script]
        stdout: SplitParser {
            onRead: line => {
                let j
                try { j = JSON.parse(line) } catch (e) { return }
                if (j.static) root.info = j.static
                if (j.disks) root.disks = j.disks
                root.d = j
                const h = root.hist, push = (k, v) => { const a = h[k].concat([v]); if (a.length > 60) a.shift(); return a }
                root.hist = { cpu: push("cpu", (j.cpu ?? 0) / 100), mem: push("mem", j.memTotal ? j.memUsed / j.memTotal : 0), gpu: push("gpu", j.gpu ? (j.gpu.usage ?? 0) / 100 : 0),
                              rx: push("rx", j.rx ?? 0), tx: push("tx", j.tx ?? 0) }
            }
        }
    }
}
