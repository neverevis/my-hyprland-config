// Widget de sistema (dados do SysInfo.qml): metricas basicas (CPU, RAM, disco), quentes (CPU, temperatura, GPU) ou
// todas, em aneis, barras ou graficos com historico. 1x1: so a primeira metrica.
import Quickshell
import QtQuick

Item {
    id: w
    property int cols: 2
    property int rows: 1
    property var opts: ({})
    property color fg: Theme.text
    property color dim: Theme.muted
    property color ac: Theme.accent
    property color ac2: Theme.tertiary            // cor companheira (o DeskView passa a do tom escolhido)
    property color cont: Theme.primaryContainer
    property color contInk: Theme.primaryContainerInk
    property bool bare: false
    function o(k) { return DeskState.opt({ type: "system", opts: w.opts }, k) }
    Component.onCompleted: SysInfo.use()
    Component.onDestruction: SysInfo.release()

    readonly property color c2: w.ac2
    readonly property color c3: Qt.tint(w.ac, Qt.rgba(w.ac2.r, w.ac2.g, w.ac2.b, 0.5))
    readonly property var all: ({
        cpu: { label: "CPU", icon: "chip", v: SysInfo.cpu, t: Math.round(SysInfo.cpu * 100) + "%", h: SysInfo.hist.cpu, col: w.ac },
        mem: { label: "RAM", icon: "memory", v: SysInfo.mem, t: Math.round(SysInfo.mem * 100) + "%", h: SysInfo.hist.mem, col: w.c2 },
        disk: { label: "Disco", icon: "disk", v: SysInfo.disk, t: Math.round(SysInfo.disk * 100) + "%", h: [], col: w.c3 },
        temp: { label: "Temp.", icon: "temperature", v: SysInfo.temp !== null ? Math.min(1, SysInfo.temp / 100) : 0, t: SysInfo.temp !== null ? SysInfo.temp + "°" : "--", h: [], col: SysInfo.temp > 80 ? Theme.danger : w.c3 },
        gpu: { label: "GPU", icon: "gpuCard", v: SysInfo.gpu, t: SysInfo.d.gpu ? Math.round(SysInfo.gpu * 100) + "%" : "--", h: SysInfo.hist.gpu, col: w.c2 },
        net: { label: "Rede", icon: "network", v: Math.min(1, (SysInfo.d.rx ?? 0) / 5e6), t: "↓" + SysInfo.bytes(SysInfo.d.rx ?? 0) + "/s", h: SysInfo.hist.rx.map(x => Math.min(1, x / 5e6)), col: w.ac }
    })
    readonly property var keys: ({ basic: ["cpu", "mem", "disk"], hot: ["cpu", "temp", "gpu"], all: ["cpu", "mem", "gpu", "temp", "disk", "net"] })[o("metrics")]
    readonly property var shown: (cols === 1 && rows === 1 ? keys.slice(0, 1) : keys).map(k => w.all[k])
    readonly property string look: o("look")

    // ---- aneis ----
    Grid {
        visible: w.look === "rings"
        anchors.centerIn: parent
        columns: w.rows > w.cols ? 1 : Math.min(w.shown.length, w.rows > 1 ? 3 : w.shown.length)
        readonly property int nr: Math.ceil(w.shown.length / columns)
        spacing: 10
        readonly property real s: Math.min((w.width - (columns - 1) * 10) / columns, (w.height - (nr - 1) * 10) / nr)
        Repeater {
            model: w.shown
            delegate: Item {
                required property var modelData
                width: parent.s; height: parent.s
                Canvas {
                    anchors.fill: parent
                    readonly property var deps: [modelData.v, modelData.col, width, w.fg]
                    onDepsChanged: requestPaint()
                    onPaint: {
                        const c = getContext("2d"); c.reset()
                        const th = Math.max(5, width * 0.08), r = width / 2 - th / 2 - 1
                        c.lineWidth = th; c.lineCap = "round"
                        c.strokeStyle = Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.12)
                        c.beginPath(); c.arc(width / 2, height / 2, r, Math.PI * 0.75, Math.PI * 2.25); c.stroke()
                        c.strokeStyle = modelData.col
                        c.beginPath(); c.arc(width / 2, height / 2, r, Math.PI * 0.75, Math.PI * 0.75 + Math.PI * 1.5 * Math.max(0.002, modelData.v)); c.stroke()
                    }
                }
                Column {
                    anchors.centerIn: parent
                    UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: modelData.icon; size: Math.max(11, parent.parent.width * 0.15); color: w.dim }
                    UiText { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.t; color: w.fg; font.pixelSize: Math.max(11, parent.parent.width * (modelData.t.length > 5 ? 0.13 : 0.2)); font.weight: Font.Bold; font.features: { "tnum": 1 } }
                    UiText { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: w.dim; font.pixelSize: Math.max(9, parent.parent.width * 0.1); font.weight: Font.DemiBold }
                }
            }
        }
    }
    // ---- barras ----
    Column {
        visible: w.look === "bars"
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        spacing: Math.max(6, (w.height - w.shown.length * 30) / Math.max(1, w.shown.length + 1))
        Repeater {
            model: w.shown
            delegate: Column {
                required property var modelData
                width: parent.width
                spacing: 4
                Item {
                    width: parent.width; height: 16
                    Row { spacing: 6
                        UiIcon { name: modelData.icon; size: 13; color: modelData.col; anchors.verticalCenter: parent.verticalCenter }
                        UiText { text: modelData.label; color: w.fg; font.pixelSize: 12; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter } }
                    UiText { anchors.right: parent.right; text: modelData.t; color: w.dim; font.pixelSize: 12; font.features: { "tnum": 1 } }
                }
                Rectangle {
                    width: parent.width; height: 6; radius: 3; color: Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.12)
                    Rectangle { width: parent.width * Math.max(0.01, modelData.v); height: parent.height; radius: 3; color: modelData.col
                        Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } } }
                }
            }
        }
    }
    // ---- graficos ----
    Grid {
        visible: w.look === "graph"
        anchors.fill: parent
        columns: w.cols >= 3 && w.rows === 1 ? w.shown.length : (w.cols >= 2 && w.shown.length > 3 ? 2 : 1)
        readonly property int nr: Math.ceil(w.shown.length / columns)
        spacing: 8
        Repeater {
            model: w.shown
            delegate: Item {
                required property var modelData
                width: (w.width - (parent.columns - 1) * 8) / parent.columns
                height: (w.height - (parent.nr - 1) * 8) / parent.nr
                Row { spacing: 5; z: 2
                    UiIcon { name: modelData.icon; size: 12; color: modelData.col; anchors.verticalCenter: parent.verticalCenter }
                    UiText { text: modelData.label + "  " + modelData.t; color: w.fg; font.pixelSize: 11; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter } }
                Canvas {
                    anchors { fill: parent; topMargin: 16 }
                    readonly property var deps: [modelData.h, modelData.col, width, height]
                    onDepsChanged: requestPaint()
                    onPaint: {
                        const c = getContext("2d"); c.reset()
                        const h = modelData.h.length ? modelData.h : new Array(60).fill(modelData.v), n = h.length
                        const px = i => i / Math.max(1, 59) * width + (60 - n) / 59 * width, py = v => height - 2 - v * (height - 4)
                        c.beginPath(); c.moveTo(px(0), height)
                        h.forEach((v, i) => c.lineTo(px(i), py(v)))
                        c.lineTo(px(n - 1), height); c.closePath()
                        c.fillStyle = Qt.rgba(modelData.col.r, modelData.col.g, modelData.col.b, 0.22); c.fill()
                        c.beginPath(); h.forEach((v, i) => i ? c.lineTo(px(i), py(v)) : c.moveTo(px(i), py(v)))
                        c.strokeStyle = modelData.col; c.lineWidth = 2; c.lineJoin = "round"; c.stroke()
                    }
                }
            }
        }
    }
}
