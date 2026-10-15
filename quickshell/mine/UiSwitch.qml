// Linha com nome e interruptor.
import QtQuick

Item {
    id: r
    property string label
    property bool checked: false
    signal toggled(bool on)

    height: 30
    width: parent ? parent.width : 300

    Text { anchors.verticalCenter: parent.verticalCenter; text: r.label; color: Theme.text; font.pixelSize: 13 }
    Rectangle {
        id: track
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: 42; height: 24; radius: 12
        color: r.checked ? Theme.accent : Theme.cardHi
        border.width: 1; border.color: r.checked ? Theme.accent : Theme.border
        Behavior on color { ColorAnimation { duration: 140 } }
        Rectangle {
            width: 18; height: 18; radius: 9
            y: 3; x: r.checked ? parent.width - width - 3 : 3
            color: r.checked ? Theme.accentText : Theme.muted
            Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: r.toggled(!r.checked) }
}
