// Cartao do painel Inicio: fundo, borda e um titulo opcional com icone; os filhos ficam em "body" (abaixo do titulo).
import QtQuick

Rectangle {
    id: c
    property string title
    property string icon
    property int pad: 14
    default property alias content: body.data
    property alias body: body
    property alias headerRight: hr.data

    radius: 14
    color: Theme.gl(Theme.card, 1.15)
    border.width: 1
    border.color: Theme.border

    Row {
        id: head
        z: 1
        visible: c.title !== ""
        x: c.pad; y: c.pad - 2
        height: visible ? 24 : 0
        spacing: 8
        UiIcon { visible: c.icon !== ""; name: c.icon; size: 16; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
        Text { text: c.title; color: Theme.text; font.pixelSize: 14; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
    }
    Row { id: hr; anchors { right: parent.right; rightMargin: c.pad - 4; verticalCenter: head.verticalCenter } spacing: 6 }
    Item {
        id: body
        z: 1
        x: c.pad
        y: head.visible ? head.y + head.height + 10 : c.pad
        width: c.width - c.pad * 2
        height: c.height - y - c.pad
    }
}
