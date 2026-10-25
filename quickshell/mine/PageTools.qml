// Pagina "Ferramentas" (kit Set*): captura (acoes e seletor de area), gravacao de tela, prateleira de arquivos e painel de jogo.
import Quickshell
import QtQuick

SetPage {
    id: page
    title: "Ferramentas"
    subtitle: "Captura, gravação de tela, prateleira de arquivos e painel de jogo"

    // ---- captura ----
    SetSection {
        title: "Captura"; icon: "camera"
        subtitle: "Arraste uma área ou clique numa janela; teclas 1-6 trocam a ação, C a forma, Enter pega a tela toda"
        SetBlock {
            Flow {
                width: parent.width
                spacing: SetK.sm
                Repeater {
                    model: Capture.actions
                    delegate: UiButton { required property var modelData; icon: modelData.icon; text: modelData.label; onClicked: { Settings.settingsOpen = false; Qt.callLater(() => Capture.start(modelData.id)) } }
                }
            }
        }
        SetRow {
            icon: "folder"; label: "Pasta das capturas"; description: "Vazio = só copiar, não salvar"
            UiField { width: 240; text: Settings.shotDir; placeholderText: "~/Imagens/Screenshots"; onEditingFinished: Settings.shotDir = text.trim() }
        }
        SetRow { visible: Capture.lastMsg !== ""; icon: "info"; label: "Última"; description: Capture.lastMsg }
        SetExpander {
            icon: "tune"; label: "Seletor de área"; description: "Contornos das janelas e linhas-guia"
            SetRow { sub: true; label: "Contornar todas as janelas"; checked: Settings.regionOutlines; onToggled: on => Settings.regionOutlines = on }
            SetRow { sub: true; label: "Linhas-guia seguindo o cursor"; checked: Settings.regionAimLines; onToggled: on => Settings.regionAimLines = on }
        }
        SetExpander {
            icon: "search"; label: "Buscar por imagem e traduzir"; description: "Endereço da busca e idioma da tradução"
            SetRow { sub: true; label: "Buscar por imagem (URL base)"; UiField { width: 260; text: Settings.imageSearchUrl; placeholderText: "https://lens.google.com/uploadbyurl?url="; onEditingFinished: Settings.imageSearchUrl = text.trim() } }
            SetRow { sub: true; label: "Traduzir para (código)"; UiField { width: 80; text: Settings.translateTarget; placeholderText: "pt"; onEditingFinished: Settings.translateTarget = text.trim() || "pt" } }
        }
        SetExpander {
            icon: "keyboard"; label: "Usar no Print Screen"; description: "Troque o comando do atalho nos arquivos do Hyprland"
            SetRow {
                sub: true; label: "Comando"; description: "qs -c mine ipc call region open copy"
                UiButton { icon: "copy"; text: "Copiar"; kind: "ghost"; onClicked: Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" | wl-copy', "sh", "qs -c mine ipc call region open copy"]) }
            }
        }
    }

    // ---- gravacao ----
    SetSection {
        title: "Gravação de tela"; icon: "record"
        subtitle: Recorder.active ? "Gravando " + Recorder.elapsed : "A tela inteira ou uma área (ação Gravar do seletor, botão do Início ou módulo da barra)"
        SetRow {
            icon: Recorder.active ? "stopCircle" : "recordRec"; label: Recorder.active ? "Gravando " + Recorder.elapsed : "Gravar a tela inteira"
            UiButton { icon: Recorder.active ? "pause" : "monitor"; text: Recorder.active ? "Parar" : "Gravar"; kind: Recorder.active ? "danger" : "accent"; onClicked: { if (Recorder.active) Recorder.stop(); else { Settings.settingsOpen = false; Qt.callLater(() => Recorder.start(false)) } } }
            UiButton { icon: "folderOpen"; text: "Abrir a pasta"; kind: "ghost"; onClicked: Qt.openUrlExternally("file://" + Recorder.dir) }
        }
        SetChoice {
            icon: "speaker"; label: "Áudio"
            options: [["none", "Sem som", "volumeOff"], ["system", "Som do PC", "speaker"], ["mic", "Microfone", "mic"], ["both", "Os dois", "headphones"]]
            value: Settings.recAudio; onPicked: v => Settings.recAudio = v
        }
        SetSlider { icon: "speed"; label: "Quadros por segundo"; from: 0; to: 144; unit: " fps"; zeroLabel: "Do monitor"; def: 0; value: Settings.recFps; onMoved: v => Settings.recFps = Math.round(v) }
        SetRow { icon: "folder"; label: "Pasta das gravações"; UiField { width: 240; text: Settings.recDir; placeholderText: "~/Vídeos/Gravações"; onEditingFinished: Settings.recDir = text.trim() || "~/Vídeos/Gravações" } }
    }

    // ---- prateleira ----
    SetSection {
        title: "Prateleira de arquivos"; icon: "layers"
        subtitle: "Solte arquivos num cartão na lateral e arraste depois para outro lugar; também pelo launcher: /prateleira"
        SetRow {
            icon: "layers"; label: "Abrir ou fechar a prateleira"; description: Settings.list(Settings.shelfFiles).length + " arquivo(s) guardado(s)"
            UiButton { text: "Abrir"; kind: "accent"; onClicked: Quickshell.execDetached(["qs", "-c", "mine", "ipc", "call", "shelf", "toggle"]) }
        }
    }

    // ---- painel de jogo ----
    SetSection {
        title: "Painel de jogo"; icon: "gamepad"
        subtitle: "Mini-janelas por cima de tudo: mira, notas, imagem, gravação, volume e sistema"
        SetRow {
            icon: "gamepad"; label: "Abrir o painel"; description: "Aberto você move e fixa; as fixadas não pegam o mouse. Atalho sugerido: Super+G"
            UiButton { text: "Abrir"; kind: "accent"; onClicked: { Settings.settingsOpen = false; Quickshell.execDetached(["qs", "-c", "mine", "ipc", "call", "overlay", "open"]) } }
        }
        SetSlider { icon: "opacity"; label: "Opacidade das fixadas"; from: 20; to: 100; unit: " %"; value: Settings.overlayPinnedOpacity; onMoved: v => Settings.overlayPinnedOpacity = Math.round(v) }
        SetSlider { icon: "image"; label: "Tamanho da imagem flutuante"; from: 10; to: 150; unit: " %"; value: Settings.overlayImageScale; onMoved: v => Settings.overlayImageScale = Math.round(v) }
        SetExpander {
            icon: "target"; label: "Mira"; description: "Formato, tamanho e cor"
            SetChoice {
                sub: true; label: ""
                style: "tiles"; columns: 4; thumbHeight: 48
                options: [["cross", "Cruz"], ["dot", "Ponto"], ["both", "Cruz e ponto"], ["circle", "Círculo"]]
                value: Settings.overlayCrossStyle; onPicked: v => Settings.overlayCrossStyle = v
                thumb: Item {
                    id: ct
                    property var opt
                    property bool on
                    property bool hovered
                    readonly property string m: opt ? opt[0] : "cross"
                    readonly property color c: Settings.overlayCrossColor
                    Rectangle { visible: ct.m === "cross" || ct.m === "both"; anchors.centerIn: parent; width: 22; height: 2; color: ct.c }
                    Rectangle { visible: ct.m === "cross" || ct.m === "both"; anchors.centerIn: parent; width: 2; height: 22; color: ct.c }
                    Rectangle { visible: ct.m === "dot" || ct.m === "both"; anchors.centerIn: parent; width: 6; height: 6; radius: 3; color: ct.c }
                    Rectangle { visible: ct.m === "circle"; anchors.centerIn: parent; width: 22; height: 22; radius: 11; color: "transparent"; border.width: 2; border.color: ct.c }
                }
            }
            SetSlider { sub: true; label: "Tamanho da mira"; from: 8; to: 60; unit: " px"; value: Settings.overlayCrossSize; onMoved: v => Settings.overlayCrossSize = Math.round(v) }
            SetColor { sub: true; label: "Cor da mira"; mode: "hex"; value: Settings.overlayCrossColor; onPicked: v => Settings.overlayCrossColor = v.toString() }
        }
    }
}
