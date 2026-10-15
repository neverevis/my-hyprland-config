// Botao: kind = "normal" | "accent" | "danger"; "checked" deixa em destaque (para seletores).
import QtQuick

Rectangle {
    id: b
    property string text
    property string kind: "normal"
    property bool checked: false
    property int pad: 14
    signal clicked

    implicitWidth: label.implicitWidth + pad * 2
    implicitHeight: 34
    radius: 9
    readonly property bool hot: checked || kind === "accent"
    color: hot ? Theme.accent : (mouse.containsMouse ? Theme.cardHi : Theme.card)
    border.width: 1
    border.color: hot ? Theme.accent : (kind === "danger" ? Theme.danger : Theme.border)
    opacity: mouse.pressed ? 0.8 : 1
    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        id: label
        anchors.centerIn: parent
        text: b.text
        font.pixelSize: 13
        font.weight: Font.Medium
        color: b.hot ? Theme.accentText : (b.kind === "danger" ? Theme.danger : Theme.text)
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
}
