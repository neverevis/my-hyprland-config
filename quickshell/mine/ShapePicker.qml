// Escolha de forma (Shapes.qml): cada opcao desenha a propria forma. value = id; picked(id) ao clicar.
import QtQuick

Flow {
    id: sp
    property string value: "rounded"
    property int sides: 10
    signal picked(string v)
    width: parent ? parent.width : 300
    spacing: 6
    Repeater {
        model: Shapes.list
        delegate: Rectangle {
            id: t
            required property var modelData
            readonly property bool on: sp.value === modelData[0]
            width: 74; height: 74; radius: 14
            color: on ? Theme.tint(0.14) : (m.containsMouse ? Theme.cardHi : Theme.track)
            border.width: on ? 2 : 1; border.color: on ? Theme.accent : Theme.border
            Flower {
                x: (parent.width - width) / 2; y: 9
                width: 36; height: 36
                shape: t.modelData[0]; sides: sp.sides
                radius: 9
                color: t.on ? Theme.accent : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.55)
            }
            UiText { anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 6 } width: parent.width - 8; horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight; text: t.modelData[1]; color: t.on ? Theme.accent : Theme.muted; font.pixelSize: 10; font.weight: t.on ? Font.Bold : Font.Normal }
            MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sp.picked(t.modelData[0]) }
        }
    }
}
