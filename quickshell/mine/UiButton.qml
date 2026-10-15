// Botao: kind = "normal" | "accent" | "danger" | "ghost"; "checked" deixa em destaque (para seletores); icon = nome do Ico.
import QtQuick

Rectangle {
    id: b
    property string text
    property string icon
    property string kind: "normal"
    property bool checked: false
    property int pad: 14
    signal clicked

    readonly property bool iconOnly: text === "" && icon !== ""
    implicitWidth: iconOnly ? 34 : content.implicitWidth + pad * 2
    implicitHeight: 34
    radius: 10
    readonly property bool hot: checked || kind === "accent"
    color: hot ? Theme.accent
        : kind === "danger" ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, mouse.containsMouse ? 0.22 : 0.12)
        : kind === "ghost" ? (mouse.containsMouse ? Theme.cardHi : "transparent")
        : (mouse.containsMouse ? Theme.cardHi : Theme.track)
    border.width: kind === "ghost" ? 0 : 1
    border.color: hot ? Theme.accent : (kind === "danger" ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.5) : Theme.border)
    opacity: mouse.pressed ? 0.8 : (enabled ? 1 : 0.45)
    Behavior on color { ColorAnimation { duration: 120 } }

    readonly property color fg: hot ? Theme.accentText : (kind === "danger" ? Theme.danger : Theme.text)
    Row {
        id: content
        anchors.centerIn: parent
        spacing: 7
        UiIcon { visible: b.icon !== ""; anchors.verticalCenter: parent.verticalCenter; name: b.icon; size: 16; color: b.fg }
        Text {
            visible: b.text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: b.text
            font.pixelSize: 13
            font.weight: Font.Medium
            color: b.fg
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
}
