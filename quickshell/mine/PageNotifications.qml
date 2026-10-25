// Painel "Notificacoes" (secoes do kit dentro da pagina Paineis): ligar, nao perturbar, posicao e aparencia dos avisos que crescem da moldura.
import Quickshell.Io
import QtQuick

Column {
    spacing: SetK.xl

    SetSection {
        title: "Notificações"; icon: "bell"; subtitle: "Se outro programa (dunst, mako…) já recebe os avisos, pare-o"
        SetRow { icon: "bell"; label: "Mostrar notificações"; description: "Um bloco ligado à moldura"; checked: Settings.notifOn; onToggled: on => Settings.notifOn = on }
        SetRow { icon: "bellOff"; label: "Não perturbar"; description: "Os avisos chegam, mas não aparecem na tela"; checked: Settings.notifDnd; onToggled: on => Settings.notifDnd = on }
        SetRow {
            icon: "send"; label: "Testar e limpar"
            UiButton { icon: "send"; text: "Enviar teste"; kind: "accent"; onClicked: test.running = true }
            UiButton { icon: "broom"; text: "Limpar todas"; onClicked: clear.running = true }
        }
    }

    SetSection {
        title: "Posição"; icon: "dock"
        SetChoice { icon: "frame"; label: "Estilo"; options: [[true, "Na moldura", "frame"], [false, "Soltas", "cards"]]; value: Settings.notifDocked; onPicked: v => Settings.notifDocked = v }
        SetRow { icon: "dock"; label: "Lado da tela"; below: SidePick { sides: ["right", "left", "top", "bottom"]; value: Settings.notifSide; onPicked: v => Settings.notifSide = v } }
        SetChoice { icon: "alignCenter"; label: "Ponto da borda"; options: [["start", "Início", "alignLeft"], ["center", "Centro", "alignCenter"], ["end", "Fim", "alignRight"]]; value: Settings.notifAnchor; onPicked: v => Settings.notifAnchor = v }
        SetRow { visible: Settings.notifAnchor !== "center"; icon: "arrow_top_right"; label: "Encostar no canto"; description: "Saem do canto da tela, emendadas com a moldura"; checked: Settings.notifCorner; onToggled: on => Settings.notifCorner = on }
    }

    SetSection {
        title: "Aparência"; icon: "tune"
        SetSlider { icon: "swap_horizontal"; label: "Largura do cartão"; from: 260; to: 520; unit: " px"; def: 360; value: Settings.notifWidth; onMoved: v => Settings.notifWidth = Math.round(v) }
        SetSlider { icon: "layers"; label: "Visíveis ao mesmo tempo"; from: 1; to: 8; def: 4; value: Settings.notifMax; onMoved: v => Settings.notifMax = Math.round(v) }
        SetSlider { icon: "timer"; label: "Tempo na tela"; from: 2; to: 20; unit: " s"; def: 6; value: Settings.notifTimeout; onMoved: v => Settings.notifTimeout = Math.round(v) }
        SetRow { icon: "cards"; label: "Agrupar por aplicativo"; description: "Vários avisos do mesmo app viram um cartão com o número"; checked: Settings.notifGroup; onToggled: on => Settings.notifGroup = on }
        SetExpander {
            icon: "curve"; label: "Cantos e curvas"; description: "Arredondamento e curva ao encontrar a moldura"
            SetSlider { sub: true; label: "Arredondamento"; from: 0; to: 30; unit: " px"; def: 14; value: Settings.notifRadius; onMoved: v => Settings.notifRadius = Math.round(v) }
            SetSlider { sub: true; label: "Curva ao encontrar a moldura"; from: 0; to: 30; unit: " px"; def: 12; value: Settings.notifFillet; onMoved: v => Settings.notifFillet = Math.round(v) }
        }
        SetExpander { icon: "animation"; label: "Animação"; lazy: Component { SetBlock { sub: true; AnimPicker { width: parent.width; target: "notifications" } } } }
    }

    Process { id: test; command: ["qs", "-c", "mine", "ipc", "call", "notifications", "test"] }
    Process { id: clear; command: ["qs", "-c", "mine", "ipc", "call", "notifications", "clear"] }
}
