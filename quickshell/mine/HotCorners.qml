// Cantos ativos: um quadradinho invisivel em cada canto escolhido (pagina Inicio). O mouse parado nele pelo tempo de
// Settings.hotCornerDelay faz a acao (abrir o Inicio, o launcher, a visao geral, mostrar a area de trabalho...).
pragma Singleton

import Quickshell
import Quickshell.Wayland
import QtQuick

Singleton {
    id: root
    readonly property var actions: [
        ["", "Nada"], ["home", "Início"], ["launcher", "Launcher"], ["overview", "Visão geral"], ["desktop", "Ver a área de trabalho"],
        ["picker", "Seletor de wallpaper"], ["settings", "Configurações"], ["power", "Menu de energia"], ["lock", "Bloquear"], ["night", "Luz noturna"]
    ]
    function run(a) {
        if (a === "home") Settings.homeOpen = !Settings.homeOpen
        else if (a === "launcher") Settings.launcherOpen = !Settings.launcherOpen
        else if (a === "picker") Settings.wpPickerOpen = !Settings.wpPickerOpen
        else if (a === "settings") Settings.settingsOpen = !Settings.settingsOpen
        else if (a === "overview") Quickshell.execDetached(["qs", "-c", "mine", "ipc", "call", "overview", "toggle"])
        else if (a === "desktop") DeskState.peek = !DeskState.peek
        else if (a === "power") Power.menuOpen = true
        else if (a === "lock") Power.lock()
        else if (a === "night") NightLight.toggle()
    }
    readonly property var corners: ["tl", "tr", "bl", "br"]

    Variants {
        model: root.corners.filter(c => !!(Settings.hotCorners || {})[c])
        delegate: PanelWindow {
            id: cw
            required property string modelData
            readonly property string act: (Settings.hotCorners || {})[modelData] ?? ""
            anchors { top: modelData[0] === "t"; bottom: modelData[0] === "b"; left: modelData[1] === "l"; right: modelData[1] === "r" }
            implicitWidth: 4; implicitHeight: 4
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "mine-corner"
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: fire.restart()
                onExited: fire.stop()
                onPositionChanged: if (!fire.running) fire.restart()
            }
            Timer { id: fire; interval: Math.max(1, Settings.hotCornerDelay); onTriggered: root.run(cw.act) }
        }
    }
}
