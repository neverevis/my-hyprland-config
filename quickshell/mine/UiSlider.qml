// Linha com nome, valor e uma barra arrastavel.
import QtQuick

Item {
    id: r
    property string label
    property real from: 0
    property real to: 100
    property int value: 0
    property string suffix: ""
    signal moved(int v)

    height: 46
    width: parent ? parent.width : 300

    Text { text: r.label; color: Theme.text; font.pixelSize: 13 }
    Text { anchors.right: parent.right; text: r.value + r.suffix; color: Theme.muted; font.pixelSize: 13 }

    Item {
        id: area
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 22
        readonly property real ratio: r.to > r.from ? Math.max(0, Math.min(1, (r.value - r.from) / (r.to - r.from))) : 0

        Rectangle { id: rail; anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; radius: 3; color: Theme.cardHi }
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: knob.x + knob.width / 2; height: 6; radius: 3; color: Theme.accent }
        Rectangle {
            id: knob
            anchors.verticalCenter: parent.verticalCenter
            width: 16; height: 16; radius: 8
            x: area.ratio * (area.width - width)
            color: Theme.text
            border.width: 3; border.color: Theme.accent
            scale: mouse.pressed ? 1.15 : 1
            Behavior on scale { NumberAnimation { duration: 100 } }
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            function upd(x) {
                const t = Math.max(0, Math.min(1, (x - knob.width / 2) / (area.width - knob.width)))
                r.moved(Math.round(r.from + t * (r.to - r.from)))
            }
            onPressed: m => upd(m.x)
            onPositionChanged: m => { if (pressed) upd(m.x) }
        }
    }
}
