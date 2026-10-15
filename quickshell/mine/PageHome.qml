// Pagina "Inicio": posicao e animacao do painel Inicio (Super).
import QtQuick

Column {
    spacing: 14

    Card {
        icon: "dashboard"
        title: "Painel Início"
        subtitle: "Abas de início, mídia, áudio, sistema e conexões. Abra com Super (sozinho)."
        UiButton { icon: "play"; text: "Abrir o painel"; kind: "accent"; onClicked: Settings.homeOpen = true }
    }
    Card {
        icon: "dock"
        title: "Posição"
        UiSwitch { label: "Acoplado à moldura"; description: "Sai da borda da tela como uma barra. Desligado, flutua no centro."; checked: Settings.homeDocked; onToggled: on => Settings.homeDocked = on }
        SidePick { visible: Settings.homeDocked; value: Settings.homeSide; onPicked: v => Settings.homeSide = v }
        UiSlider { visible: Settings.homeDocked; label: "Deslocamento"; from: -1000; to: 1000; value: Settings.homeOffset; suffix: " px"; onMoved: v => Settings.homeOffset = Math.round(v) }
        UiSlider { visible: Settings.homeDocked; label: "Curva ao encontrar a moldura"; from: 0; to: 40; value: Settings.homeFillet; suffix: " px"; onMoved: v => Settings.homeFillet = Math.round(v) }
        UiSlider { label: "Arredondamento"; from: 0; to: 40; value: Settings.homeRadius; suffix: " px"; onMoved: v => Settings.homeRadius = Math.round(v) }
    }
    Card {
        icon: "animation"
        title: "Animação"
        AnimPicker { target: "home" }
    }
}
