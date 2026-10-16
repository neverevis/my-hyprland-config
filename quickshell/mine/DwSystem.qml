// Widget de sistema: aneis de CPU, memoria e disco (+ tempo ligado no 2x2). 1x1: so o anel da CPU com a memoria por dentro.
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: w
    property int cols: 2
    property int rows: 1
    property var opts: ({})

    property real cpu: 0
    property real mem: 0
    property real disk: 0
    property real lastT: 0
    property real lastI: 0
    property string up: ""

    FileView { id: stat; path: "/proc/stat"; onLoaded: {
        const p = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
        const idle = p[3] + p[4], tot = p.reduce((a, b) => a + b, 0)
        if (w.lastT > 0) w.cpu = Math.max(0, Math.min(1, 1 - (idle - w.lastI) / Math.max(1, tot - w.lastT)))
        w.lastT = tot; w.lastI = idle } }
    FileView { id: meminfo; path: "/proc/meminfo"; onLoaded: {
        const t = text(), tot = Number(/MemTotal:\s+(\d+)/.exec(t)[1]), av = Number(/MemAvailable:\s+(\d+)/.exec(t)[1])
        w.mem = 1 - av / tot } }
    FileView { id: upf; path: "/proc/uptime"; onLoaded: {
        const s = parseFloat(text().split(" ")[0]) || 0, h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60)
        w.up = h > 0 ? h + " h " + m + " min" : m + " min" } }
    Process { id: df; command: ["df", "-P", "/"]; stdout: StdioCollector { onStreamFinished: {
        const l = text.trim().split("\n")[1]; if (l) w.disk = (parseInt(l.trim().split(/\s+/)[4]) || 0) / 100 } } }
    Timer { interval: 2000; repeat: true; running: true; triggeredOnStart: true; onTriggered: { stat.reload(); meminfo.reload() } }
    Timer { interval: 60000; repeat: true; running: true; triggeredOnStart: true; onTriggered: { df.running = true; upf.reload() } }

    component Ring: Item {
        id: ring
        property real value: 0
        property string label: ""
        property string icon: ""
        property color col: Theme.accent
        property real thick: 8
        property real shown: value
        Behavior on shown { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
        onShownChanged: cv.requestPaint()
        Canvas {
            id: cv
            anchors.fill: parent
            readonly property var deps: [ring.col, width]
            onDepsChanged: requestPaint()
            onPaint: {
                const c = getContext("2d"); c.reset()
                const r = Math.min(width, height) / 2 - ring.thick / 2 - 1, cx = width / 2, cy = height / 2
                c.lineWidth = ring.thick; c.lineCap = "round"
                c.strokeStyle = Qt.rgba(ring.col.r, ring.col.g, ring.col.b, 0.16)
                c.beginPath(); c.arc(cx, cy, r, Math.PI * 0.75, Math.PI * 2.25); c.stroke()
                c.strokeStyle = ring.col
                c.beginPath(); c.arc(cx, cy, r, Math.PI * 0.75, Math.PI * 0.75 + Math.PI * 1.5 * Math.max(0.001, ring.shown)); c.stroke()
            }
        }
        Column {
            anchors.centerIn: parent
            spacing: 0
            UiIcon { visible: ring.icon !== ""; anchors.horizontalCenter: parent.horizontalCenter; name: ring.icon; size: Math.max(12, ring.width * 0.16); color: Theme.muted }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(ring.value * 100) + "%"; color: Theme.text; font.pixelSize: Math.max(12, ring.width * 0.2); font.weight: Font.Bold; font.features: { "tnum": 1 } }
            Text { visible: ring.label !== ""; anchors.horizontalCenter: parent.horizontalCenter; text: ring.label; color: Theme.muted; font.pixelSize: Math.max(9, ring.width * 0.11); font.weight: Font.DemiBold }
        }
    }

    // 1x1: CPU por fora, memoria por dentro
    Item {
        visible: w.cols === 1
        anchors.fill: parent
        Ring { anchors.centerIn: parent; width: Math.min(parent.width, parent.height); height: width; value: w.cpu; label: "CPU"; thick: 9 }
    }
    // 2x1 / 2x2: tres aneis lado a lado
    Row {
        visible: w.cols > 1
        anchors.horizontalCenter: parent.horizontalCenter
        y: w.rows > 1 ? 10 : (parent.height - height) / 2
        spacing: 10
        readonly property real s: Math.min((w.width - 20) / 3, w.rows > 1 ? w.height * 0.5 : w.height)
        Ring { width: parent.s; height: parent.s; value: w.cpu; label: "CPU"; icon: w.rows > 1 ? "chip" : "" }
        Ring { width: parent.s; height: parent.s; value: w.mem; label: "RAM"; icon: w.rows > 1 ? "memory" : ""; col: Settings.themeOn ? ThemeColors.secondary : Theme.accent }
        Ring { width: parent.s; height: parent.s; value: w.disk; label: "Disco"; icon: w.rows > 1 ? "disk" : ""; col: Settings.themeOn ? ThemeColors.tertiary : Theme.accent }
    }
    Column {
        visible: w.rows > 1
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        spacing: 4
        Row {
            spacing: 8
            UiIcon { name: "clock"; size: 16; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Ligado há " + w.up; color: Theme.text; font.pixelSize: 14; font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
        }
        Text { text: Profile.user + "@" + (Quickshell.env("HOSTNAME") || "linux"); color: Theme.muted; font.pixelSize: 12 }
    }
}
