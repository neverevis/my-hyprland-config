// Texto livre: frase com fonte (inclusive as manuscritas embutidas), tamanho, peso, italico, alinhamento e sombra.
// O tamanho escolhido e o maximo: o texto encolhe para caber no widget.
import QtQuick
import QtQuick.Effects

Item {
    id: w
    property int cols: 3
    property int rows: 1
    property var opts: ({})
    property string wid: ""
    property bool editing: false
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
        visible: !w.editing
        text: w.o("text") || (DeskState.editing ? "Duplo clique para escrever…" : "")
        opacity: w.o("text") ? 1 : 0.5
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

    // duplo clique edita ali mesmo: Ctrl+Enter salva, Esc cancela (sair do campo tambem salva)
    MouseArea {
        anchors.fill: parent
        enabled: !w.editing && !DeskState.editing && w.wid !== ""
        acceptedButtons: Qt.LeftButton
        onDoubleClicked: { ed.text = w.o("text") ?? ""; w.editing = true; ed.forceActiveFocus(); ed.selectAll() }
    }
    TextEdit {
        id: ed
        visible: w.editing
        anchors.fill: parent
        wrapMode: TextEdit.Wrap
        color: w.fg
        font.family: t.font.family; font.pixelSize: Math.min(w.o("size"), 28); font.weight: w.o("weight"); font.italic: w.o("italic")
        horizontalAlignment: t.horizontalAlignment
        verticalAlignment: TextEdit.AlignVCenter
        selectionColor: Theme.accent; selectedTextColor: Theme.accentText
        selectByMouse: true
        property bool cancel: false
        onActiveFocusChanged: {
            DeskState.wantKeys("text-f-" + w.wid, activeFocus)
            if (!activeFocus) { if (w.editing && !cancel && w.wid !== "") DeskState.setOpt(w.wid, "text", text); w.editing = false; cancel = false }
        }
        Keys.onEscapePressed: { cancel = true; w.editing = false; focus = false }
        Keys.onPressed: e => { if ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter) && (e.modifiers & Qt.ControlModifier)) { focus = false; e.accepted = true } }
    }
    Component.onDestruction: DeskState.wantKeys("text-f-" + w.wid, false)
}
