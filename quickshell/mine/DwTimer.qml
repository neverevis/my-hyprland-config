// Widget de timer (estado em Timers.qml): pomodoro, contagem regressiva ou cronometro. Anel de progresso,
// tempo grande, etapa e botoes (iniciar/pausar, zerar, pular etapa no pomodoro).
import QtQuick

Item {
    id: w
    property int cols: 2
    property int rows: 1
    property var opts: ({})
    property string wid: ""
    property color fg: Theme.text
    property color dim: Theme.muted
    property color ac: Theme.accent
    property color ac2: Theme.tertiary            // cor companheira (o DeskView passa a do tom escolhido)
    property color cont: Theme.primaryContainer
    property color contInk: Theme.primaryContainerInk
    property bool bare: false
    readonly property var me: ({ id: wid, type: "timer", opts: opts })
    function o(k) { return DeskState.opt(me, k) }
    onMeChanged: if (wid !== "" && !DeskState.find(wid)) Timers.register(wid, me)

    readonly property var s: (Timers.st, Timers.get(wid))
    readonly property real el: (Timers.now, Timers.elapsed(wid))
    readonly property real tot: Timers.total(me)
    readonly property real remain: tot > 0 ? Math.max(0, tot - el) : el
    readonly property real frac: tot > 0 ? Math.min(1, el / tot) : (el / 60000) % 1
    function fmt(ms) { const t = Math.round(ms / 1000), h = Math.floor(t / 3600), m = Math.floor(t % 3600 / 60), sec = t % 60
        return (h > 0 ? h + ":" + String(m).padStart(2, "0") : String(m).padStart(2, "0")) + ":" + String(sec).padStart(2, "0") }
    readonly property string phaseLabel: o("mode") === "stopwatch" ? "Cronômetro" : o("mode") === "countdown" ? "Regressivo"
        : (s.phase === "focus" ? "Foco" : s.phase === "long" ? "Pausa longa" : "Pausa") + " · ciclo " + s.cycle
    readonly property color phaseCol: o("mode") === "pomodoro" && s.phase !== "focus" ? w.ac2 : w.ac

    readonly property bool tiny: cols === 1 && rows === 1
    readonly property real ringS: tiny ? Math.min(width, height) : (rows > 1 ? Math.min(width, height * 0.66) : height)
    Item {
        id: ring
        width: w.ringS; height: w.ringS
        x: w.tiny || w.rows > 1 ? (w.width - width) / 2 : 0
        Canvas {
            id: cv
            anchors.fill: parent
            readonly property var deps: [w.frac, w.phaseCol, width, w.fg]
            onDepsChanged: requestPaint()
            onPaint: {
                const c = getContext("2d"); c.reset()
                const r = width / 2 - 5
                c.lineWidth = Math.max(4, width * 0.05); c.lineCap = "round"
                c.strokeStyle = Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.12)
                c.beginPath(); c.arc(width / 2, height / 2, r, 0, Math.PI * 2); c.stroke()
                c.strokeStyle = w.phaseCol
                c.beginPath(); c.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.max(0.002, w.frac)); c.stroke()
            }
        }
        Column {
            anchors.centerIn: parent
            UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: w.o("mode") === "pomodoro" ? (w.s.phase === "focus" ? "target" : "coffee") : (w.o("mode") === "stopwatch" ? "stopwatch" : "timer"); size: ring.width * 0.14; color: w.phaseCol }
            UiText { anchors.horizontalCenter: parent.horizontalCenter; visible: w.tiny || w.rows > 1; text: w.fmt(w.remain); color: w.fg; font.pixelSize: ring.width * 0.2; font.weight: Font.Bold; font.features: { "tnum": 1 } }
        }
        MouseArea { anchors.fill: parent; visible: w.tiny; cursorShape: Qt.PointingHandCursor; onClicked: w.s.running ? Timers.pause(w.wid) : Timers.start(w.wid) }
    }
    Column {
        visible: !w.tiny
        anchors { left: w.rows > 1 ? parent.left : ring.right; leftMargin: w.rows > 1 ? 0 : 16; right: parent.right
                  top: w.rows > 1 ? ring.bottom : undefined; topMargin: 8; verticalCenter: w.rows > 1 ? undefined : ring.verticalCenter }
        spacing: 4
        UiText { visible: w.rows === 1; text: w.fmt(w.remain); color: w.fg; font.pixelSize: Math.min(40, w.height * 0.36); font.weight: Font.Bold; font.features: { "tnum": 1 } }
        UiText { width: parent.width; horizontalAlignment: w.rows > 1 ? Text.AlignHCenter : Text.AlignLeft; text: w.phaseLabel; color: w.dim; font.pixelSize: 12 }
        Row {
            anchors.horizontalCenter: w.rows > 1 ? parent.horizontalCenter : undefined
            spacing: 6
            Repeater {
                model: [[w.s.running ? "pause" : "play", () => w.s.running ? Timers.pause(w.wid) : Timers.start(w.wid), true],
                        ["refresh", () => Timers.reset(w.wid), false]].concat(w.o("mode") === "pomodoro" ? [["next", () => Timers.skip(w.wid), false]] : [])
                delegate: Rectangle {
                    required property var modelData
                    width: modelData[2] ? 40 : 32; height: 32; radius: 16
                    color: modelData[2] ? w.phaseCol : (bm.containsMouse ? Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.16) : Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.08))
                    UiIcon { anchors.centerIn: parent; name: modelData[0]; size: 16; color: modelData[2] ? Theme.accentText : w.fg }
                    MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData[1]() }
                }
            }
        }
    }
}
