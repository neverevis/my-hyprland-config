// Pagina "Notificacoes": aparencia, tempo e posicao dos avisos que crescem da moldura.
import Quickshell.Io
import QtQuick

Column {
    spacing: 14

    Card {
        icon: "bell"
        title: "Notificações"
        subtitle: "O Quickshell recebe os avisos dos apps e mostra como um bloco ligado à moldura. Se outro programa (dunst, mako…) já estiver recebendo, pare-o."
        UiSwitch { label: "Mostrar notificações"; checked: Settings.notifOn; onToggled: on => Settings.notifOn = on }
        UiSwitch { label: "Não perturbe"; description: "Os avisos continuam chegando, mas não aparecem na tela."; checked: Settings.notifDnd; onToggled: on => Settings.notifDnd = on }
        Row {
            spacing: 8
            UiButton { icon: "send"; text: "Enviar teste"; kind: "accent"; onClicked: test.running = true }
            UiButton { icon: "broom"; text: "Limpar todas"; onClicked: clear.running = true }
        }
    }

    Card {
        icon: "dock"
        title: "Posição"
        UiSeg {
            options: [[true, "Na moldura", "frame"], [false, "Soltas", "cards"]]
            value: Settings.notifDocked
            onPicked: v => Settings.notifDocked = v
        }
        SidePick { sides: ["right", "left", "top", "bottom"]; value: Settings.notifSide; onPicked: v => Settings.notifSide = v }
        UiLabel { text: "Ponto da borda" }
        UiSeg {
            options: [["start", "Início", "alignLeft"], ["center", "Centro", "alignCenter"], ["end", "Fim", "alignRight"]]
            value: Settings.notifAnchor
            onPicked: v => Settings.notifAnchor = v
        }
        UiSwitch {
            visible: Settings.notifAnchor !== "center"
            label: "Encostar no canto"; icon: "arrow_top_right"
            description: "As notificações saem do canto da tela, emendadas com a moldura."
            checked: Settings.notifCorner; onToggled: on => Settings.notifCorner = on
        }
    }

    Card {
        icon: "tune"
        title: "Aparência"
        UiSlider { label: "Largura do cartão"; from: 260; to: 520; value: Settings.notifWidth; suffix: " px"; onMoved: v => Settings.notifWidth = Math.round(v) }
        UiSwitch { label: "Agrupar por aplicativo"; description: "Vários avisos do mesmo app viram um cartão com o número; os outros aparecem quando ele fecha."; checked: Settings.notifGroup; onToggled: on => Settings.notifGroup = on }
        UiSlider { label: "Notificações visíveis"; from: 1; to: 8; value: Settings.notifMax; onMoved: v => Settings.notifMax = Math.round(v) }
        UiSlider { label: "Tempo na tela"; from: 2; to: 20; value: Settings.notifTimeout; suffix: " s"; onMoved: v => Settings.notifTimeout = Math.round(v) }
        UiSlider { label: "Arredondamento"; from: 0; to: 30; value: Settings.notifRadius; suffix: " px"; onMoved: v => Settings.notifRadius = Math.round(v) }
        UiSlider { label: "Curva ao encontrar a moldura"; from: 0; to: 30; value: Settings.notifFillet; suffix: " px"; onMoved: v => Settings.notifFillet = Math.round(v) }
    }

    Card {
        icon: "animation"
        title: "Animação"
        AnimPicker { target: "notifications" }
    }

    Process { id: test; command: ["qs", "-c", "mine", "ipc", "call", "notifications", "test"] }
    Process { id: clear; command: ["qs", "-c", "mine", "ipc", "call", "notifications", "clear"] }
}
