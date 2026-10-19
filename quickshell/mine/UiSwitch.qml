// Linha com nome (e descricao opcional) e interruptor.
import QtQuick

Item {
    id: r
    property string label
    property string description
    property string icon
    property bool checked: false
    signal toggled(bool on)

    width: parent ? parent.width : 300
    height: Math.max(32, txt.implicitHeight)

    UiIcon { id: ic; visible: r.icon !== ""; anchors.verticalCenter: parent.verticalCenter; name: r.icon; size: 17; color: Theme.muted; width: 22 }
    Column {
        id: txt
        anchors { left: ic.visible ? ic.right : parent.left; leftMargin: ic.visible ? 10 : 0; right: track.left; rightMargin: 14; verticalCenter: parent.verticalCenter }
        spacing: 2
        UiText { width: parent.width; text: r.label; color: Theme.text; font.pixelSize: 13; wrapMode: Text.WordWrap }
        UiText { visible: r.description !== ""; width: parent.width; text: r.description; color: Theme.muted; font.pixelSize: 12; wrapMode: Text.WordWrap }
    }
    Rectangle {
        id: track
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: 44; height: 24; radius: 12
        color: r.checked ? Theme.accent : Theme.cardHi
        border.width: 1; border.color: r.checked ? Theme.accent : Theme.border
        Behavior on color { enabled: !ThemeColors.fading; ColorAnimation { duration: 140 } }
        Rectangle {
            width: 18; height: 18; radius: 9
            y: 3; x: r.checked ? parent.width - width - 3 : 3
            color: r.checked ? Theme.accentText : Theme.muted
            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: r.toggled(!r.checked) }
}
