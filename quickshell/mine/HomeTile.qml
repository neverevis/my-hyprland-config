// Atalho do painel Inicio: icone, nome e estado; ligado = cor de destaque. "more" mostra uma seta que abre o menu (o mesmo
// do clique direito). size: 1 = so o icone, 2 e 3 = icone + nome + estado. avail: false = sem o recurso neste PC (apagado).
// A dica (tip) aparece embaixo do botao depois de um instante com o mouse parado.
import QtQuick

Rectangle {
    id: t
    property string icon
    property string label
    property string sub
    property bool on: false
    property bool more: false
    property int size: 2
    property bool avail: true
    property string tip: ""
    property bool editing: false
    signal clicked()
    signal moreClicked()

    readonly property bool compact: size < 2
    radius: on ? 14 : Math.min(height / 2, 22)
    Behavior on radius { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    opacity: avail ? 1 : 0.45
    color: on ? Theme.tint(ma.pressed ? 0.38 : ma.containsMouse ? 0.30 : 0.22) : (ma.containsMouse ? Theme.cardHi : Theme.gl(Theme.card, 1.15))
    border.width: 1
    border.color: on ? Theme.tint(0.55) : Theme.border
    Behavior on color { enabled: !ThemeColors.fading; ColorAnimation { duration: 140 } }

    Rectangle {
        id: dot
        x: t.compact ? (t.width - width) / 2 : 10
        anchors.verticalCenter: parent.verticalCenter
        width: 36; height: 36; radius: 18
        color: t.on ? Theme.accent : Theme.track
        Behavior on color { enabled: !ThemeColors.fading; ColorAnimation { duration: 140 } }
        UiIcon { anchors.centerIn: parent; name: t.icon; size: 18; color: t.on ? Theme.accentText : Theme.text }
    }
    Column {
        visible: !t.compact
        anchors { left: dot.right; leftMargin: 10; right: moreBtn.visible ? moreBtn.left : parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 1
        UiText { width: parent.width; text: t.label; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight }
        UiText { width: parent.width; visible: t.sub !== ""; text: t.sub; color: Theme.muted; font.pixelSize: 11; elide: Text.ElideRight }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        enabled: !t.editing
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => { if (m.button === Qt.RightButton) { if (t.more) t.moreClicked() } else t.clicked() }
        onContainsMouseChanged: { if (containsMouse) tipT.restart(); else { tipT.stop(); tipBox.shown = false } }
        onPressed: { tipT.stop(); tipBox.shown = false }
    }
    Rectangle {
        id: moreBtn
        visible: t.more && !t.compact
        anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
        width: 26; height: 40; radius: 9
        color: mm.containsMouse ? Theme.cardHi : "transparent"
        UiIcon { anchors.centerIn: parent; name: "chevRight"; size: 16; color: Theme.muted }
        MouseArea { id: mm; anchors.fill: parent; enabled: !t.editing; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: t.moreClicked() }
    }

    Timer { id: tipT; interval: 650; onTriggered: tipBox.shown = t.tip !== "" }
    Rectangle {
        id: tipBox
        property bool shown: false
        visible: shown
        z: 50
        x: (t.width - width) / 2
        y: t.height + 6
        width: tipText.implicitWidth + 20; height: tipText.implicitHeight + 12
        radius: 8
        color: Theme.bg
        border.width: 1; border.color: Theme.border
        UiText { id: tipText; anchors.centerIn: parent; text: t.tip; color: Theme.text; font.pixelSize: 12 }
    }
}
