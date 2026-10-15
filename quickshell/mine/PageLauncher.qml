// Pagina "Launcher": aparencia e animacao do launcher de aplicativos (Super + Tab).
import QtQuick

Column {
    spacing: 14

    Card {
        icon: "apps"
        title: "Launcher de aplicativos"
        subtitle: "Abra com Super + Tab. Os apps mais usados aparecem primeiro."
        UiButton { icon: "play"; text: "Abrir o launcher"; kind: "accent"; onClicked: Settings.launcherOpen = true }
    }

    Card {
        icon: "dock"
        title: "Posição"
        UiSwitch { label: "Acoplado à moldura"; description: "Sai da borda da tela como uma barra. Desligado, flutua."; checked: Settings.launcherDocked; onToggled: on => Settings.launcherDocked = on }
        SidePick { visible: Settings.launcherDocked; value: Settings.launcherSide; onPicked: v => Settings.launcherSide = v }
        UiSeg {
            visible: !Settings.launcherDocked
            options: [["center", "Centro", "alignCenter"], ["top", "Topo", "arrowUp"]]
            value: Settings.launcherPos
            onPicked: v => Settings.launcherPos = v
        }
        UiSlider { visible: Settings.launcherDocked; label: "Deslocamento"; from: -1000; to: 1000; value: Settings.launcherOffset; suffix: " px"; onMoved: v => Settings.launcherOffset = Math.round(v) }
        UiSlider { visible: Settings.launcherDocked; label: "Curva ao encontrar a moldura"; from: 0; to: 40; value: Settings.launcherFillet; suffix: " px"; onMoved: v => Settings.launcherFillet = Math.round(v) }
    }

    Card {
        icon: "tune"
        title: "Aparência"
        UiSlider { label: "Largura"; from: 400; to: 1000; value: Settings.launcherWidth; suffix: " px"; onMoved: v => Settings.launcherWidth = v }
        UiSlider { label: "Resultados visíveis"; from: 3; to: 12; value: Settings.launcherRows; onMoved: v => Settings.launcherRows = Math.round(v) }
        UiSlider { label: "Tamanho dos ícones"; from: 20; to: 56; value: Settings.launcherIcon; suffix: " px"; onMoved: v => Settings.launcherIcon = Math.round(v) }
        UiSlider { label: "Arredondamento"; from: 0; to: 40; value: Settings.launcherRadius; suffix: " px"; onMoved: v => Settings.launcherRadius = Math.round(v) }
    }

    Card {
        icon: "animation"
        title: "Animação"
        subtitle: "As animações são criadas e editadas na página Animações."
        AnimPicker { target: "launcher" }
    }

    Card {
        icon: "history"
        title: "Histórico de uso"
        subtitle: "O launcher conta quantas vezes você abriu cada app para ordenar os resultados."
        UiButton { icon: "broom"; text: "Limpar histórico"; kind: "danger"; onClicked: Settings.launcherUsage = ({}) }
    }
}
