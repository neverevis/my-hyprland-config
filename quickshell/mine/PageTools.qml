// Pagina "Ferramentas": captura (seletor de area e as acoes), gravacao de tela (audio, pasta, quadros por segundo) e a
// prateleira de arquivos.
import Quickshell
import QtQuick

Column {
    spacing: 14

    Card {
        icon: "frame"
        title: "Captura"
        subtitle: "O seletor congela a tela: arraste uma área ou clique numa janela. Teclas 1-6 trocam a ação, C alterna círculo, Enter pega a tela inteira."
        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: Capture.actions
                delegate: UiButton { required property var modelData; icon: modelData.icon; text: modelData.label; onClicked: { Settings.settingsOpen = false; Qt.callLater(() => Capture.start(modelData.id)) } }
            }
        }
        Row {
            spacing: 10
            UiText { anchors.verticalCenter: parent.verticalCenter; text: "Pasta das capturas"; color: Theme.text; font.pixelSize: 13 }
            UiField { width: 320; text: Settings.shotDir; placeholderText: "Vazio = só copiar, não salvar"; onEditingFinished: Settings.shotDir = text.trim() }
        }
        UiText { width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 12
            text: "Para o Print Screen abrir este seletor, troque nos atalhos do Hyprland o comando por:  qs -c mine ipc call region open copy" }
        UiText { visible: Capture.lastMsg !== ""; width: parent.width; wrapMode: Text.WordWrap; text: "Última: " + Capture.lastMsg; color: Theme.text; font.pixelSize: 12 }
    }

    Card {
        icon: "monitor"
        title: "Gravação de tela"
        subtitle: Recorder.active ? "Gravando " + Recorder.elapsed : "Grave a tela inteira ou uma área (ação Gravar do seletor, botão do Início ou módulo da barra)."
        UiLabel { text: "Áudio" }
        UiSeg { options: [["none", "Sem som", "volumeOff"], ["system", "Som do PC", "speaker"], ["mic", "Microfone", "mic"]]; value: Settings.recAudio; onPicked: v => Settings.recAudio = v }
        UiSlider { label: "Quadros por segundo (0 = do monitor)"; from: 0; to: 144; value: Settings.recFps; onMoved: v => Settings.recFps = Math.round(v) }
        Row {
            spacing: 10
            UiText { anchors.verticalCenter: parent.verticalCenter; text: "Pasta"; color: Theme.text; font.pixelSize: 13 }
            UiField { width: 360; text: Settings.recDir; placeholderText: "~/Vídeos/Gravações"; onEditingFinished: Settings.recDir = text.trim() || "~/Vídeos/Gravações" }
        }
        Row {
            spacing: 8
            UiButton { icon: Recorder.active ? "pause" : "monitor"; text: Recorder.active ? "Parar" : "Gravar a tela inteira"; kind: Recorder.active ? "danger" : "accent"; onClicked: { if (Recorder.active) Recorder.stop(); else { Settings.settingsOpen = false; Qt.callLater(() => Recorder.start(false)) } } }
            UiButton { icon: "folderOpen"; text: "Abrir a pasta"; kind: "ghost"; onClicked: Qt.openUrlExternally("file://" + Recorder.dir) }
        }
    }

    Card {
        icon: "layers"
        title: "Prateleira de arquivos"
        subtitle: "Um cartão na lateral onde você solta arquivos e depois arrasta para outro lugar (como o dropover). Também pelo launcher: \"/prateleira\"."
        UiButton { icon: "layers"; text: "Abrir / fechar a prateleira"; onClicked: Quickshell.execDetached(["qs", "-c", "mine", "ipc", "call", "shelf", "toggle"]) }
        UiText { text: Settings.list(Settings.shelfFiles).length + " arquivo(s) guardado(s)"; color: Theme.muted; font.pixelSize: 12 }
    }

    Card {
        icon: "gamepad"
        title: "Painel de jogo"
        subtitle: "Mini-janelas por cima de tudo: mira, notas, imagem, gravação, volume por app e sistema. Com o painel aberto você move e fixa; fixadas ficam por cima do jogo sem pegar o mouse. Atalho sugerido: Super+G com  qs -c mine ipc call overlay toggle"
        UiButton { icon: "gamepad"; text: "Abrir o painel"; kind: "accent"; onClicked: { Settings.settingsOpen = false; Quickshell.execDetached(["qs", "-c", "mine", "ipc", "call", "overlay", "open"]) } }
        UiSlider { label: "Opacidade das fixadas"; from: 20; to: 100; value: Settings.overlayPinnedOpacity; suffix: " %"; onMoved: v => Settings.overlayPinnedOpacity = Math.round(v) }
        UiLabel { text: "Mira" }
        UiSeg { options: [["cross", "Cruz"], ["dot", "Ponto"], ["both", "Cruz e ponto"], ["circle", "Círculo"]]; value: Settings.overlayCrossStyle; onPicked: v => Settings.overlayCrossStyle = v }
        UiSlider { label: "Tamanho da mira"; from: 8; to: 60; value: Settings.overlayCrossSize; suffix: " px"; onMoved: v => Settings.overlayCrossSize = Math.round(v) }
        ColorField { label: "Cor da mira"; value: Settings.overlayCrossColor; onPicked: c => Settings.overlayCrossColor = c.toString() }
        UiSlider { label: "Tamanho da imagem flutuante"; from: 10; to: 150; value: Settings.overlayImageScale; suffix: " %"; onMoved: v => Settings.overlayImageScale = Math.round(v) }
    }
}
