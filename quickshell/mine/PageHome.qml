// Pagina "Painel Inicio": posicao e animacao do painel Inicio (Super).
import Quickshell.Io
import QtQuick

Column {
    spacing: 14

    Card {
        title: "Painel Início"
        subtitle: "Cartão do usuário, player de mídia, atalhos e relógio. Abra com Super (sozinho) ou pelo botão abaixo."
        UiButton { text: "Abrir o painel"; kind: "accent"; onClicked: homeToggle.running = true }
    }
    Card {
        title: "Posição"
        UiSwitch { label: "Acoplado à moldura"; checked: Settings.homeDocked; onToggled: on => Settings.homeDocked = on }
        Row {
            visible: Settings.homeDocked
            spacing: 6
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Lado"; color: Theme.text; font.pixelSize: 13; width: 70 }
            Repeater {
                model: [["bottom", "Baixo"], ["top", "Cima"], ["left", "Esquerda"], ["right", "Direita"]]
                delegate: UiButton {
                    required property var modelData
                    text: modelData[1]
                    checked: Settings.homeSide === modelData[0]
                    onClicked: Settings.homeSide = modelData[0]
                }
            }
        }
        UiSlider { visible: Settings.homeDocked; label: "Deslocamento"; from: -1000; to: 1000; value: Settings.homeOffset; suffix: " px"; onMoved: v => Settings.homeOffset = Math.round(v) }
        UiSlider { visible: Settings.homeDocked; label: "Curva ao encontrar a moldura"; from: 0; to: 40; value: Settings.homeFillet; suffix: " px"; onMoved: v => Settings.homeFillet = Math.round(v) }
        UiSlider { label: "Arredondamento"; from: 0; to: 40; value: Settings.homeRadius; suffix: " px"; onMoved: v => Settings.homeRadius = Math.round(v) }
    }
    Card {
        title: "Animação"
        AnimPicker { target: "home" }
    }
    Process { id: homeToggle; command: ["qs", "-c", "mine", "ipc", "call", "home", "toggle"] }
}
