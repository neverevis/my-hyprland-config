// Linha de cor: nome + amostra; clicar abre o seletor logo abaixo.
import QtQuick

Column {
    id: cr
    property string label
    property color value
    property bool expanded: false
    signal picked(color c)

    width: parent ? parent.width : 300
    spacing: 10

    Item {
        width: parent.width
        height: 30
        Text { anchors.verticalCenter: parent.verticalCenter; text: cr.label; color: Theme.text; font.pixelSize: 13 }
        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 8
            Text { anchors.verticalCenter: parent.verticalCenter; text: cr.value.toString(); color: Theme.muted; font.pixelSize: 12 }
            Rectangle {
                width: 44; height: 24; radius: 7
                color: cr.value
                border.width: 2; border.color: cr.expanded ? Theme.accent : Theme.border
            }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: cr.expanded = !cr.expanded }
    }
    Loader {
        active: cr.expanded
        visible: active
        sourceComponent: ColorPicker { value: cr.value; onPicked: c => cr.picked(c) }
    }
}
