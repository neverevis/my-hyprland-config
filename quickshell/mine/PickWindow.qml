// Janela do navegador de imagens para o Pick.qml (camada de cima, teclado exclusivo enquanto aberta).
import Quickshell
import Quickshell.Wayland
import QtQuick

LazyLoader {
    active: Pick.open

    PanelWindow {
        id: win
        anchors { left: true; right: true; top: true; bottom: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "mine-pick"

        Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.45); MouseArea { anchors.fill: parent; onClicked: Pick.cancel() } }
        Rectangle {
            id: card
            anchors.centerIn: parent
            width: Math.min(1060, parent.width - 80); height: Math.min(720, parent.height - 80)
            radius: 22
            color: Theme.bg; border.width: 1; border.color: Theme.border
            focus: true
            Keys.onEscapePressed: Pick.cancel()
            MouseArea { anchors.fill: parent }
            scale: 0.96 + 0.04 * appear
            opacity: appear
            property real appear: 0
            Component.onCompleted: { appear = 1; browser.focusGrid() }
            Behavior on appear { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Row {
                x: 24; y: 20
                spacing: 12
                Rectangle { width: 36; height: 36; radius: 11; color: Theme.tint(0.18)
                    UiIcon { anchors.centerIn: parent; name: "images"; size: 20; color: Theme.accent } }
                Text { anchors.verticalCenter: parent.verticalCenter; text: Pick.title; color: Theme.text; font.pixelSize: 17; font.weight: Font.Bold }
            }
            UiButton { anchors { right: parent.right; rightMargin: 16; top: parent.top; topMargin: 18 } icon: "close"; kind: "ghost"; onClicked: Pick.cancel() }
            ImageBrowser {
                id: browser
                anchors { fill: parent; leftMargin: 16; rightMargin: 20; topMargin: 76; bottomMargin: 16 }
                onChosen: path => Pick.done(path)
                onCanceled: Pick.cancel()
            }
        }
    }
}
