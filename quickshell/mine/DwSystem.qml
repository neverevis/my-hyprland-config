// Widget de sistema (dados do SysInfo.qml): metricas basicas (CPU, RAM, disco), quentes (CPU, temperatura, GPU) ou
// todas, em aneis, barras ou graficos com historico. 1x1: so a primeira metrica.
import Quickshell
import Quickshell.Services.UPower
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
    property string wid: ""
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
    // bateria (so notebooks): nos tiles ela troca o disco
    readonly property var bat: UPower.displayDevice
    readonly property bool hasBat: !!bat && bat.ready && bat.isLaptopBattery
    readonly property real batV: hasBat ? bat.percentage : 0
    readonly property var tileInfo: ({
        cpu: { shape: "gem", pal: 0 }, mem: { pal: 1, shape: "cookie4" }, disk: { pal: 2, shape: "cookie12" },
        bat: { pal: 2, shape: "cookie12" }, temp: { pal: 2, shape: "sunny" }, gpu: { pal: 1, shape: "bun" }, net: { pal: 0, shape: "clover4" }
    })
    readonly property var tilePal: [[w.cont, w.contInk], [Theme.secondaryContainer, Theme.secondaryContainerInk], [Theme.tertiaryContainer, Theme.tertiaryContainerInk]]
    readonly property var tileItems: {
        const out = []
        for (const k of w.keys) {
            let id = k, d = w.all[k]
            if (k === "disk" && hasBat) { id = "bat"; d = { label: "Bateria", icon: "battery", t: Math.round(batV * 100) + "%" } }
            const ti = w.tileInfo[id]
            out.push({ label: d.label, icon: d.icon, t: d.t, shape: ti.shape, bg: w.tilePal[ti.pal][0], ink: w.tilePal[ti.pal][1] })
        }
        return (cols === 1 && rows === 1) ? out.slice(0, 1) : out
    }
    readonly property bool vert: o("vertical") || rows > cols
    readonly property var keys: ({ basic: ["cpu", "mem", "disk"], hot: ["cpu", "temp", "gpu"], all: ["cpu", "mem", "gpu", "temp", "disk", "net"] })[o("metrics")]
    readonly property var shown: (cols === 1 && rows === 1 ? keys.slice(0, 1) : keys).map(k => w.all[k])
    readonly property string look: o("look")

    // ---- tiles (um cartao por medida, com a forma M3 e o numero grande) ----
    Item {
        id: tl
        visible: w.look === "tiles"
        anchors.fill: parent
        readonly property int n: Math.max(1, w.tileItems.length)
        readonly property real gap: 8
        readonly property real tw: w.vert ? width : (width - (n - 1) * gap) / n
        readonly property real th: w.vert ? (height - (n - 1) * gap) / n : height
        HoverHandler { id: tlHover }
        Repeater {
            model: w.tileItems
            delegate: Rectangle {
                required property var modelData
                required property int index
                x: w.vert ? 0 : index * (tl.tw + tl.gap)
                y: w.vert ? index * (tl.th + tl.gap) : 0
                width: tl.tw; height: tl.th
                radius: Math.min(26, Math.min(width, height) * 0.24)
                color: modelData.bg
                Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                readonly property real m: Math.min(width, height)
                ShapeIcon {
                    anchors { top: parent.top; right: parent.right; margins: parent.m * 0.1 }
                    size: Math.max(26, parent.m * 0.4); padding: size * 0.24
                    shape: modelData.shape; icon: modelData.icon
                    color: Qt.rgba(modelData.ink.r, modelData.ink.g, modelData.ink.b, 0.16); iconColor: modelData.ink
                }
                Column {
                    anchors { left: parent.left; bottom: parent.bottom; margins: parent.m * 0.12 }
                    spacing: 0
                    UiText { text: modelData.t; color: modelData.ink; font.pixelSize: Math.max(14, parent.parent.m * 0.3); font.weight: Font.Bold; font.features: { "tnum": 1 } }
                    UiText { text: modelData.label; color: modelData.ink; opacity: 0.6; font.pixelSize: Math.max(10, parent.parent.m * 0.13); font.weight: Font.DemiBold }
                }
            }
        }
        // alca para virar entre horizontal e vertical (so aparece com o mouse em cima)
        Rectangle {
            anchors { right: parent.right; bottom: parent.bottom; margins: -4 }
            width: 24; height: 24; radius: 12
            color: Theme.card; border.width: 1; border.color: Theme.border
            opacity: (tlHover.hovered || fm.containsMouse) && w.wid !== "" && w.tileItems.length > 1 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            UiIcon { anchors.centerIn: parent; name: "refresh"; size: 13; color: Theme.text
                rotation: w.vert ? 90 : 0; Behavior on rotation { NumberAnimation { duration: 350; easing.type: Easing.OutBack } } }
            MouseArea { id: fm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: DeskState.setOpt(w.wid, "vertical", !o("vertical")) }
        }
    }
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
