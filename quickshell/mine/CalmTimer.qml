// Timer, composicao "Sereno" (a padrao, um modo so): o tempo como numero grande, a etapa em cima, um fio de progresso
// (sem anel em Canvas) e os botoes. host = o DwTimer (estado, cores e opcoes vem dele).
import QtQuick

Item {
    id: c
    property Item host
    readonly property bool tall: host.rows > 1
    readonly property bool tiny: host.cols === 1 && host.rows === 1
    readonly property real u: Math.max(0.72, Math.min(1.25, height / (tall ? 278 : 114)))
    readonly property string mode: host.o("mode")
    readonly property var laps: (Timers.st, Array.from(Timers.get(host.wid).laps ?? []))
    function toggle() { host.s.running ? Timers.pause(host.wid) : Timers.start(host.wid) }

    Column {
        id: txt
        width: parent.width
        spacing: 0
        UiText { width: parent.width; elide: Text.ElideRight; text: host.phaseLabel; color: host.dim; font.pixelSize: Math.round((c.tiny ? 11 : 12) * c.u); font.weight: Font.Medium }
        UiText {
            text: host.fmt(host.remain); color: host.fg
            font.family: Theme.fontTitle; font.pixelSize: Math.round((c.tall ? 56 : c.tiny ? 28 : 42) * c.u); font.weight: Font.Medium; font.features: { "tnum": 1 }
        }
    }
    // voltas do cronometro (so nos altos): as 3 ultimas, a mais nova em cima
    Column {
        visible: c.tall && c.mode === "stopwatch" && c.laps.length > 0
        anchors { top: txt.bottom; topMargin: 6 * c.u }
        spacing: 2 * c.u
        Repeater {
            model: c.tall ? c.laps.slice(-3).reverse().map((v, i) => { const n = c.laps.length - i; return { n: n, d: v - (n > 1 ? c.laps[n - 2] : 0), t: v } }) : []
            delegate: UiText { required property var modelData; text: "#" + modelData.n + "   +" + host.fmt(modelData.d) + "   " + host.fmt(modelData.t); color: host.dim; font.pixelSize: Math.round(12 * c.u); font.features: { "tnum": 1 } }
        }
    }
    Rectangle {
        id: bar
        anchors { left: parent.left; right: c.tall || c.tiny ? parent.right : btns.left; rightMargin: c.tall || c.tiny ? 0 : 14 * c.u; bottom: parent.bottom; bottomMargin: c.tall ? 46 * c.u : c.tiny ? 0 : 6 * c.u }
        height: 3; radius: 1.5
        color: Qt.rgba(host.fg.r, host.fg.g, host.fg.b, 0.14)
        Rectangle { width: Math.round(parent.width * host.frac); height: parent.height; radius: 1.5; color: host.phaseCol }
    }
    Row {
        id: btns
        visible: !c.tiny
        anchors { right: c.tall ? undefined : parent.right; left: c.tall ? parent.left : undefined; bottom: parent.bottom; bottomMargin: c.tall ? 0 : (parent.height - height) / 2 }
        spacing: 6 * c.u
        Repeater {
            model: ["toggle", "refresh"].concat(c.mode === "pomodoro" ? ["next"] : c.mode === "stopwatch" ? ["flag"] : [])
            delegate: Rectangle {
                id: b
                required property string modelData
                required property int index
                readonly property bool main: index === 0
                width: Math.round((main ? 36 : 32) * c.u); height: width; radius: width / 2
                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                color: main ? host.phaseCol : Qt.rgba(host.fg.r, host.fg.g, host.fg.b, bm.containsMouse ? 0.18 : 0.09)
                scale: bm.pressed ? 0.94 : 1
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                UiIcon { anchors.centerIn: parent; name: b.main ? (host.s.running ? "pause" : "play") : b.modelData; size: Math.round(16 * c.u); color: b.main ? Theme.accentText : host.fg }
                MouseArea {
                    id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: b.main ? c.toggle() : b.modelData === "refresh" ? Timers.reset(host.wid) : b.modelData === "next" ? Timers.skip(host.wid) : Timers.lap(host.wid)
                }
            }
        }
    }
    MouseArea { anchors.fill: parent; visible: c.tiny; cursorShape: Qt.PointingHandCursor; onClicked: c.toggle() }
}
