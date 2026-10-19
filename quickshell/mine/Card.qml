// Cartao com icone, titulo e subtitulo; os filhos entram numa coluna.
import QtQuick

Rectangle {
    id: c
    property string title
    property string subtitle
    property string icon
    default property alias content: col.data

    width: parent ? parent.width : 300
    implicitHeight: col.implicitHeight + 36
    height: implicitHeight
    radius: 16
    color: Theme.gl(Theme.card, 1)
    border.width: 1 + glow
    border.color: glow > 0.01 ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35 + 0.65 * glow) : Theme.border
    // acende a borda por um instante (a busca das configuracoes usa ao abrir um resultado)
    property real glow: 0
    function pulse() { glowAnim.restart() }
    SequentialAnimation {
        id: glowAnim
        NumberAnimation { target: c; property: "glow"; to: 1; duration: 160 }
        PauseAnimation { duration: 700 }
        NumberAnimation { target: c; property: "glow"; to: 0; duration: 700; easing.type: Easing.InOutQuad }
    }

    Column {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
        spacing: 14
        Row {
            visible: c.title !== ""
            width: parent.width
            spacing: 12
            Rectangle {
                id: badge
                visible: c.icon !== ""
                width: 34; height: 34; radius: 10
                anchors.verticalCenter: parent.verticalCenter
                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
                UiIcon { anchors.centerIn: parent; name: c.icon; size: 18; color: Theme.accent }
            }
            Column {
                width: parent.width - (badge.visible ? badge.width + 12 : 0)
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text { text: c.title; color: Theme.text; font.pixelSize: 15; font.weight: Font.DemiBold }
                Text { visible: c.subtitle !== ""; text: c.subtitle; color: Theme.muted; font.pixelSize: 12; wrapMode: Text.WordWrap; width: parent.width }
            }
        }
    }
}
