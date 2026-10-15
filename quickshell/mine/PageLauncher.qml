// Pagina "Launcher": aparencia e animacao do launcher de aplicativos (Super + Space).
import Quickshell.Io
import QtQuick

Column {
    spacing: 14

    Card {
        title: "Launcher de aplicativos"
        subtitle: "Abra com Super + Space. Os apps mais usados aparecem primeiro."
        UiButton { text: "Testar o launcher"; kind: "accent"; onClicked: qsLauncherToggle.running = true }
    }

    Card {
        title: "Aparência"
        UiSwitch { label: "Acoplado à moldura"; checked: Settings.launcherDocked; onToggled: on => Settings.launcherDocked = on }
        Row {
            visible: Settings.launcherDocked
            spacing: 6
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Lado"; color: Theme.text; font.pixelSize: 13; width: 70 }
            Repeater {
                model: [["bottom", "Baixo"], ["top", "Cima"], ["left", "Esquerda"], ["right", "Direita"]]
                delegate: UiButton {
                    required property var modelData
                    text: modelData[1]
                    checked: Settings.launcherSide === modelData[0]
                    onClicked: Settings.launcherSide = modelData[0]
                }
            }
        }
        UiSlider { visible: Settings.launcherDocked; label: "Deslocamento"; from: -1000; to: 1000; value: Settings.launcherOffset; suffix: " px"; onMoved: v => Settings.launcherOffset = Math.round(v) }
        UiSlider { visible: Settings.launcherDocked; label: "Curva ao encontrar a moldura"; from: 0; to: 40; value: Settings.launcherFillet; suffix: " px"; onMoved: v => Settings.launcherFillet = Math.round(v) }
        Row {
            visible: !Settings.launcherDocked
            spacing: 6
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Posição"; color: Theme.text; font.pixelSize: 13; width: 70 }
            Repeater {
                model: [["center", "Centro"], ["top", "Topo"]]
                delegate: UiButton {
                    required property var modelData
                    text: modelData[1]
                    checked: Settings.launcherPos === modelData[0]
                    onClicked: Settings.launcherPos = modelData[0]
                }
            }
        }
        UiSlider { label: "Largura"; from: 400; to: 1000; value: Settings.launcherWidth; suffix: " px"; onMoved: v => Settings.launcherWidth = v }
        UiSlider { label: "Resultados visíveis"; from: 3; to: 12; value: Settings.launcherRows; suffix: ""; onMoved: v => Settings.launcherRows = Math.round(v) }
        UiSlider { label: "Tamanho dos ícones"; from: 20; to: 56; value: Settings.launcherIcon; suffix: " px"; onMoved: v => Settings.launcherIcon = Math.round(v) }
        UiSlider { label: "Arredondamento"; from: 0; to: 40; value: Settings.launcherRadius; suffix: " px"; onMoved: v => Settings.launcherRadius = Math.round(v) }
    }

    Card {
        title: "Animação"
        AnimPicker { target: "launcher" }
    }

    Card {
        title: "Histórico de uso"
        subtitle: "O launcher conta quantas vezes você abriu cada app para ordenar os resultados."
        UiButton { text: "Limpar histórico"; kind: "danger"; onClicked: Settings.launcherUsage = ({}) }
    }

    Process { id: qsLauncherToggle; command: ["qs", "-c", "mine", "ipc", "call", "launcher", "toggle"] }
}
