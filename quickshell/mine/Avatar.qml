// Foto de perfil redonda com anel na cor de destaque (ou a inicial, se nao houver ~/.face).
// editable: ao passar o mouse aparece uma camera; o clique abre o seletor para trocar a foto.
import QtQuick

Item {
    id: av
    property real size: 68
    property real ring: 2
    property color ringColor: Theme.accent
    property bool editable: false
    width: size + ring * 2 + 4; height: width

    RoundImage {
        id: img
        anchors.centerIn: parent
        width: av.size; height: av.size; radius: av.size / 2
        source: Profile.face
        sourceSize: Qt.size(Math.ceil(av.size * 2), Math.ceil(av.size * 2))
    }
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: img.ready ? "transparent" : Theme.tint(0.3)
        border.width: av.ring; border.color: av.ringColor
        Text { anchors.centerIn: parent; visible: !img.ready; text: Profile.initial; color: "white"; font.pixelSize: Math.round(av.size * 0.44); font.weight: Font.Bold }
    }
    // trocar a foto
    Rectangle {
        visible: av.editable
        anchors.centerIn: parent
        width: av.size; height: av.size; radius: av.size / 2
        color: Qt.rgba(0, 0, 0, 0.5)
        opacity: em.containsMouse || Profile.busy ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 140 } }
        Column {
            anchors.centerIn: parent
            spacing: 1
            UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: Profile.busy ? "refresh" : "camera"; size: Math.round(av.size * 0.3); color: "white" }
            Text { visible: av.size >= 60; anchors.horizontalCenter: parent.horizontalCenter; text: "Trocar"; color: "white"; font.pixelSize: 10; font.weight: Font.Medium }
        }
    }
    scale: em.pressed ? 0.95 : 1
    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
    MouseArea {
        id: em
        anchors.fill: parent
        enabled: av.editable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Profile.change()
    }
}
