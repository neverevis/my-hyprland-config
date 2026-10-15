// Pagina "Moldura": formato do contorno e das curvas.
import QtQuick

Column {
    spacing: 14

    Card {
        icon: "frame"
        title: "Contorno"
        subtitle: "A faixa fina que contorna a tela inteira."
        UiSwitch { label: "Contorno na tela"; description: "Desligado, só as barras e os painéis aparecem."; checked: Settings.outline; onToggled: on => Settings.outline = on }
        UiSlider { label: "Espessura"; from: 2; to: 16; value: Settings.edge; suffix: " px"; onMoved: v => Settings.edge = v }
        UiSlider { label: "Cantos da tela"; from: 0; to: 40; value: Settings.cornerRadius; suffix: " px"; onMoved: v => Settings.cornerRadius = v }
    }
    Card {
        icon: "curve"
        title: "Curvas das barras"
        subtitle: "Como a faixa fina sobe até a barra."
        UiSlider { label: "Curva da subida"; from: 0; to: 30; value: Settings.fillet; suffix: " px"; onMoved: v => Settings.fillet = v }
        UiSlider { label: "Cantos do topo das barras"; from: 0; to: 30; value: Settings.topRadius; suffix: " px"; onMoved: v => Settings.topRadius = v }
    }
}
