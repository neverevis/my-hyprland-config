// Cartao com titulo; os filhos entram numa coluna.
import QtQuick

Rectangle {
    id: c
    property string title
    property string subtitle
    default property alias content: col.data

    width: parent ? parent.width : 300
    implicitHeight: col.implicitHeight + 32
    height: implicitHeight
    radius: 14
    color: Theme.card
    border.width: 1
    border.color: Theme.border

    Column {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        spacing: 14
        Column {
            visible: c.title !== ""
            width: parent.width
            spacing: 2
            Text { text: c.title; color: Theme.text; font.pixelSize: 15; font.weight: Font.DemiBold }
            Text { visible: c.subtitle !== ""; text: c.subtitle; color: Theme.muted; font.pixelSize: 12; wrapMode: Text.WordWrap; width: parent.width }
        }
    }
}
