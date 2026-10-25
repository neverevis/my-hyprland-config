// "Detalhes": texto tecnico fora da vista. Botao pequeno que abre uma linha mono muda com o comando e um botao de copiar.
import Quickshell
import QtQuick

Column {
    id: root
    property string cmd
    property color tone: Theme.muted
    property bool open: false
    property bool copied: false
    width: parent ? parent.width : 300
    spacing: SetK.xs
    UiButton { text: root.open ? "Ocultar detalhes" : "Detalhes"; icon: root.open ? "chevUp" : "chevDown"; kind: "ghost"; implicitHeight: 28; onClicked: root.open = !root.open }
    Row {
        visible: root.open
        width: parent.width; spacing: SetK.sm
        UiText { width: parent.width - 40; anchors.verticalCenter: parent.verticalCenter; text: root.cmd; wrapMode: Text.WrapAnywhere; color: root.tone; font.pixelSize: SetK.fDesc; font.family: Theme.mono }
        UiButton { icon: root.copied ? "check" : "copy"; kind: "ghost"; onClicked: { Quickshell.execDetached(["wl-copy", root.cmd]); root.copied = true; cpT.restart() } }
    }
    Timer { id: cpT; interval: 1500; onTriggered: root.copied = false }
}
