// Pagina "Aparencia": vidro e cores.
import QtQuick

Column {
    spacing: 14

    Card {
        title: "Vidro"
        subtitle: "Moldura translúcida com o fundo desfocado."
        UiSwitch { label: "Ativar vidro (blur)"; checked: Settings.glass; onToggled: on => Settings.glass = on }
        UiSlider { label: "Opacidade"; from: 10; to: 100; value: Settings.glassOpacity; suffix: " %"; onMoved: v => Settings.glassOpacity = v }
    }
    Card {
        title: "Cores"
        ColorField { label: "Moldura e barras"; value: Settings.barColor; onPicked: c => Settings.barColor = c.toString() }
        ColorField { label: "Texto dos módulos"; value: Settings.textColor; onPicked: c => Settings.textColor = c.toString() }
        ColorField { label: "Destaque desta janela"; value: Settings.accent; onPicked: c => Settings.accent = c.toString() }
    }
}
