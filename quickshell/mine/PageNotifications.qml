// Pagina "Notificacoes": aparencia, tempo e posicao dos avisos que crescem da moldura.
import Quickshell.Io
import QtQuick

Column {
    spacing: 14

    Card {
        title: "Notificações"
        subtitle: "O Quickshell recebe os avisos dos apps e mostra como um bloco ligado à moldura. Se outro programa (dunst, mako…) já estiver recebendo, pare-o."
        UiSwitch { label: "Mostrar notificações"; checked: Settings.notifOn; onToggled: on => Settings.notifOn = on }
        UiSwitch { label: "Não perturbe"; checked: Settings.notifDnd; onToggled: on => Settings.notifDnd = on }
        Row {
            spacing: 8
            UiButton { text: "Enviar teste"; kind: "accent"; onClicked: test.running = true }
            UiButton { text: "Limpar todas"; onClicked: clear.running = true }
        }
    }

    Card {
        title: "Posição"
        Row {
            spacing: 6
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Lado"; color: Theme.text; font.pixelSize: 13; width: 70 }
            Repeater {
                model: [["right", "Direita"], ["left", "Esquerda"], ["top", "Cima"], ["bottom", "Baixo"]]
                delegate: UiButton {
                    required property var modelData
                    text: modelData[1]
                    checked: Settings.notifSide === modelData[0]
                    onClicked: Settings.notifSide = modelData[0]
                }
            }
        }
        Row {
            spacing: 6
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Ponto"; color: Theme.text; font.pixelSize: 13; width: 70 }
            Repeater {
                model: [["start", "Início"], ["center", "Centro"], ["end", "Fim"]]
                delegate: UiButton {
                    required property var modelData
                    text: modelData[1]
                    checked: Settings.notifAnchor === modelData[0]
                    onClicked: Settings.notifAnchor = modelData[0]
                }
            }
        }
    }

    Card {
        title: "Aparência"
        UiSlider { label: "Largura do cartão"; from: 260; to: 520; value: Settings.notifWidth; suffix: " px"; onMoved: v => Settings.notifWidth = Math.round(v) }
        UiSlider { label: "Notificações visíveis"; from: 1; to: 8; value: Settings.notifMax; onMoved: v => Settings.notifMax = Math.round(v) }
        UiSlider { label: "Tempo na tela"; from: 2; to: 20; value: Settings.notifTimeout; suffix: " s"; onMoved: v => Settings.notifTimeout = Math.round(v) }
        UiSlider { label: "Arredondamento"; from: 0; to: 30; value: Settings.notifRadius; suffix: " px"; onMoved: v => Settings.notifRadius = Math.round(v) }
        UiSlider { label: "Curva ao encontrar a moldura"; from: 0; to: 30; value: Settings.notifFillet; suffix: " px"; onMoved: v => Settings.notifFillet = Math.round(v) }
    }

    Card {
        title: "Animação"
        AnimPicker { target: "notifications" }
    }

    Process { id: test; command: ["qs", "-c", "mine", "ipc", "call", "notifications", "test"] }
    Process { id: clear; command: ["qs", "-c", "mine", "ipc", "call", "notifications", "clear"] }
}
