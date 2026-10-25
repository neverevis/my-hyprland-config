// SetPreview: moldura da previa ao vivo no topo de uma SetPage (ou dentro de um SetBlock).
// Fundo do tema, cantos grandes, conteudo cortado nas bordas. Previas ficam paradas; so animam enquanto o mouse
// esta em cima (hovered) ou durante uma interacao — nada roda com a pagina escondida.
// Exemplo:  preview: SetPreview { height: 220; Image { anchors.fill: parent; ... } }
import QtQuick

Rectangle {
    id: p
    default property alias content: inner.data
    readonly property bool hovered: hh.hovered
    property int padding: 0
    width: parent ? parent.width : 400
    height: 200
    radius: SetK.boxRadius + 4
    color: Theme.track
    border.width: 1
    border.color: Theme.border
    clip: true
    HoverHandler { id: hh }
    Item { id: inner; anchors.fill: parent; anchors.margins: p.padding + 1 }
}
