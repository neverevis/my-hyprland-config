// Atalho do painel Inicio: icone, nome e estado; ligado = cor de destaque. "more" mostra uma seta que abre a aba ligada.
import QtQuick

Rectangle {
    id: t
    property string icon
    property string label
    property string sub
    property bool on: false
    property bool more: false
    signal clicked()
    signal moreClicked()

    radius: 14
    color: on ? Theme.tint(ma.containsMouse ? 0.30 : 0.22) : (ma.containsMouse ? Theme.cardHi : Theme.gl(Theme.card, 1.15))
    border.width: 1
    border.color: on ? Theme.tint(0.55) : Theme.border
    Behavior on color { ColorAnimation { duration: 140 } }

    Rectangle {
        id: dot
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        width: 36; height: 36; radius: 18
        color: t.on ? Theme.accent : Theme.track
        Behavior on color { ColorAnimation { duration: 140 } }
        UiIcon { anchors.centerIn: parent; name: t.icon; size: 18; color: t.on ? Theme.accentText : Theme.text }
    }
    Column {
        anchors { left: dot.right; leftMargin: 10; right: moreBtn.visible ? moreBtn.left : parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 1
        Text { width: parent.width; text: t.label; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight }
        Text { width: parent.width; visible: t.sub !== ""; text: t.sub; color: Theme.muted; font.pixelSize: 11; elide: Text.ElideRight }
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: t.clicked() }
    Rectangle {
        id: moreBtn
        visible: t.more
        anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
        width: 26; height: 40; radius: 9
        color: mm.containsMouse ? Theme.cardHi : "transparent"
        UiIcon { anchors.centerIn: parent; name: "chevRight"; size: 16; color: Theme.muted }
        MouseArea { id: mm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: t.moreClicked() }
    }
}
