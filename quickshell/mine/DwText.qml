// Texto livre: frase com fonte (inclusive as manuscritas embutidas), tamanho, peso, italico, alinhamento e sombra.
// O tamanho escolhido e o maximo: o texto encolhe para caber no widget.
import QtQuick
import QtQuick.Effects

Item {
    id: w
    property int cols: 3
    property int rows: 1
    property var opts: ({})
    property color fg: Theme.text
    property color dim: Theme.muted
    property color ac: Theme.accent
    property color ac2: Theme.tertiary            // cor companheira (o DeskView passa a do tom escolhido)
    property color cont: Theme.primaryContainer
    property color contInk: Theme.primaryContainerInk
    property bool bare: false
    function o(k) { return DeskState.opt({ type: "text", opts: w.opts }, k) }

    UiText {
        id: t
        anchors.fill: parent
        text: w.o("text")
        color: w.fg
        font.family: w.o("font") || Theme.font
        font.pixelSize: w.o("size")
        font.weight: w.o("weight")
        font.italic: w.o("italic")
        fontSizeMode: Text.Fit
        minimumPixelSize: 10
        wrapMode: Text.WordWrap
        horizontalAlignment: ({ left: Text.AlignLeft, center: Text.AlignHCenter, right: Text.AlignRight })[w.o("align")]
        verticalAlignment: Text.AlignVCenter
        layer.enabled: w.o("shadow") && !w.bare && Settings.desktopShadow   // sem fundo, a sombra ja vem do DeskView
        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: DeskState.shadowColor(false); shadowBlur: DeskState.shadowBlur(false); shadowVerticalOffset: DeskState.shadowOffset(false) + 1 }
    }
}
