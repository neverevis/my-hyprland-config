// Linha de volume do painel Inicio: botao de icone (mudo), barra arrastavel (roda do mouse tambem) e porcentagem.
import QtQuick

Item {
    id: s
    property real value: 0          // 0..1
    property string icon: "volume"
    property bool muted: false
    property string label
    signal moved(real v)
    signal iconClicked()

    height: label !== "" ? 54 : 36
    width: parent ? parent.width : 300

    UiText { id: lbl; visible: s.label !== ""; text: s.label; color: Theme.muted; font.pixelSize: 12; elide: Text.ElideRight; width: parent.width - 50 }
    Item {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 36
        Rectangle {
            id: ib
            width: 36; height: 36; radius: 11
            color: s.muted ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.18) : (ibm.containsMouse ? Theme.cardHi : Theme.track)
            UiIcon { anchors.centerIn: parent; name: s.icon; size: 18; color: s.muted ? Theme.danger : Theme.text }
            MouseArea { id: ibm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: s.iconClicked() }
        }
        Item {
            id: area
            anchors { left: ib.right; leftMargin: 12; right: pct.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
            height: 24
            readonly property real r: Math.max(0, Math.min(1, s.muted ? 0 : s.value))
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 8; radius: 4; color: Theme.cardHi }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Math.max(8, knob.x + knob.width / 2); height: 8; radius: 4; color: Theme.accent; opacity: s.muted ? 0.4 : 1 }
            Rectangle {
                id: knob
                anchors.verticalCenter: parent.verticalCenter
                x: area.r * (area.width - width)
                width: 16; height: 16; radius: 8
                color: Theme.text
                scale: ma.pressed ? 1.2 : (ma.containsMouse ? 1.08 : 1)
                Behavior on scale { NumberAnimation { duration: 100 } }
            }
            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                function upd(x) { s.moved(Math.max(0, Math.min(1, (x - knob.width / 2) / (area.width - knob.width)))) }
                onPressed: m => upd(m.x)
                onPositionChanged: m => { if (pressed) upd(m.x) }
            }
            WheelHandler { onWheel: e => s.moved(Math.max(0, Math.min(1, s.value + (e.angleDelta.y > 0 ? 0.05 : -0.05)))) }
        }
        UiText {
            id: pct
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            width: 40
            horizontalAlignment: Text.AlignRight
            text: Math.round((s.muted ? 0 : s.value) * 100) + "%"
            color: Theme.text; font.pixelSize: 13; font.weight: Font.Medium
        }
    }
}
