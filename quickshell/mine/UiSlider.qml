// Linha com nome, valor e uma barra arrastavel (Ctrl + roda do mouse tambem ajusta).
import QtQuick

Item {
    id: r
    property string label
    property string icon
    property real from: 0
    property real to: 100
    property int value: 0
    property string suffix: ""
    signal moved(int v)

    height: 50
    width: parent ? parent.width : 300

    Row {
        spacing: 8
        UiIcon { visible: r.icon !== ""; name: r.icon; size: 15; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
        Text { text: r.label; color: Theme.text; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
    }
    Rectangle {
        anchors.right: parent.right
        width: valText.implicitWidth + 14; height: 22; radius: 7
        color: Theme.track
        border.width: 1; border.color: Theme.border
        Text { id: valText; anchors.centerIn: parent; text: r.value + r.suffix; color: Theme.text; font.pixelSize: 12; font.weight: Font.Medium }
    }

    Item {
        id: area
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 22
        readonly property real ratio: r.to > r.from ? Math.max(0, Math.min(1, (r.value - r.from) / (r.to - r.from))) : 0

        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; radius: 3; color: Theme.cardHi }
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: knob.x + knob.width / 2; height: 6; radius: 3; color: Theme.accent }
        Rectangle {
            id: knob
            anchors.verticalCenter: parent.verticalCenter
            width: 18; height: 18; radius: 9
            x: area.ratio * (area.width - width)
            color: Theme.accent
            border.width: 4; border.color: Theme.accentText
            scale: mouse.pressed ? 1.15 : (mouse.containsMouse ? 1.06 : 1)
            Behavior on scale { NumberAnimation { duration: 100 } }
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            function upd(x) {
                const t = Math.max(0, Math.min(1, (x - knob.width / 2) / (area.width - knob.width)))
                r.moved(Math.round(r.from + t * (r.to - r.from)))
            }
            onPressed: m => upd(m.x)
            onPositionChanged: m => { if (pressed) upd(m.x) }
        }
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse
            acceptedModifiers: Qt.ControlModifier   // so com Ctrl: a roda sozinha continua rolando a pagina
            onWheel: e => { const st = Math.max(1, Math.round((r.to - r.from) / 100)); r.moved(Math.max(r.from, Math.min(r.to, r.value + (e.angleDelta.y > 0 ? st : -st)))) }
        }
    }
}
