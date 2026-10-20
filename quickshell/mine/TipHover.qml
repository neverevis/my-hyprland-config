// Dica de texto ao passar o mouse (Settings.barTips): ponha dentro de qualquer Item da barra.
//   TipHover { text: "Capturar uma area"; side: root.side; origin: root.origin }
// "origin" e o canto da janela da barra na tela (o ModuleView passa adiante); o cartao aparece pelo BarPopup.qml (tipo "tip").
import QtQuick

HoverHandler {
    id: h
    property string text: ""
    property string side: "bottom"
    property point origin: Qt.point(0, 0)
    enabled: text !== ""
    onHoveredChanged: {
        if (!hovered) { BarState.popLeave(); return }
        const it = h.parent
        if (!it) return
        const p = it.mapToItem(null, 0, 0)
        BarState.tipEnter(h.text, h.side, { x: p.x + h.origin.x, y: p.y + h.origin.y, w: it.width, h: it.height })
    }
}
