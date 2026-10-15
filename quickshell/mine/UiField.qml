// Campo de texto estilizado.
import QtQuick
import QtQuick.Controls

TextField {
    id: f
    implicitHeight: 34
    color: Theme.text
    placeholderTextColor: Theme.muted
    selectionColor: Theme.accent
    selectedTextColor: Theme.accentText
    font.pixelSize: 13
    leftPadding: 10
    selectByMouse: true
    background: Rectangle {
        radius: 10
        color: Theme.track
        border.width: 1
        border.color: f.activeFocus ? Theme.accent : Theme.border
    }
}
