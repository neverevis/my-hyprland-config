// Texto livre: frase com fonte (inclusive as manuscritas embutidas), tamanho, peso, italico, alinhamento e sombra.
// O tamanho escolhido e o maximo: o texto encolhe para caber no widget.
// Extras: preenchimento (cor, destaque ou degrade), contorno, base (pilula ou caixa), opacidade e variaveis
// {time} {date} {battery} (atualizadas a cada minuto, so quando o texto usa alguma).
import Quickshell
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
    property var comp: ({})                       // composicao vinda do cartao (caixas internas, selos, destaque, raio)
    function o(k) { return DeskState.opt({ type: "text", opts: w.opts }, k) }

    readonly property string lk: o("look") === "end4" ? "end4" : "auto"
    readonly property string fillMode: o("fill")
    readonly property string backing: o("backing")
    readonly property bool gradient: fillMode === "gradient"
    readonly property real inset: backing === "none" ? 0 : 16
    // variaveis: o relogio so liga se o texto usa alguma
    readonly property string raw: o("text") ?? ""
    readonly property bool hasVars: raw.indexOf("{") >= 0
    SystemClock { id: clk; enabled: w.hasVars && w.visible; precision: SystemClock.Minutes }
    readonly property string shown: !hasVars ? raw : raw
        .replace(/\{time\}/g, Qt.formatTime(clk.date, Settings.clock24 ? "HH:mm" : "h:mm AP"))
        .replace(/\{date\}/g, DateTime.long(clk.date, "dddd, d MMM"))
        .replace(/\{battery\}/g, Battery.present ? Math.round(Battery.pct * 100) + "%" : "—")

    Item {
    id: body
    anchors.fill: parent
    opacity: w.o("blend") / 100
    // base atras do texto: pilula ou caixa
    Rectangle {
        visible: w.backing !== "none"
        anchors.fill: parent
        radius: w.backing === "pill" ? height / 2 : (w.comp.innerRadius > 0 ? w.comp.innerRadius : 17)
        readonly property color bc: Theme.role(w.comp.innerRole && w.comp.innerRole !== "auto" && w.comp.innerRole !== "none" ? w.comp.innerRole : "bg")
        color: Qt.rgba(bc.r, bc.g, bc.b, w.comp.innerAlpha > 0 ? w.comp.innerAlpha : 0.6)
    }
    UiText {
        id: t
        anchors { fill: parent; margins: w.inset }
        visible: !w.editing
        text: w.shown || (DeskState.editing ? "Duplo clique para escrever…" : "")
        opacity: w.raw ? 1 : 0.5
        color: w.gradient ? "white" : w.fillMode === "accent" ? w.ac : w.fg
        style: w.o("outline") ? Text.Outline : Text.Normal
        styleColor: Theme.role(w.o("outlineRole"))
        font.family: w.o("font") || Theme.fontExpressive
        font.pixelSize: w.o("size")
        font.weight: w.o("weight")
        font.italic: w.o("italic")
        fontSizeMode: Text.Fit
        minimumPixelSize: 10
        wrapMode: Text.WordWrap
        horizontalAlignment: ({ left: Text.AlignLeft, center: Text.AlignHCenter, right: Text.AlignRight })[w.o("align")]
        verticalAlignment: Text.AlignVCenter
        layer.enabled: w.o("shadow") && !w.bare && Settings.desktopShadow && !w.gradient   // sem fundo, a sombra ja vem do DeskView
        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: DeskState.shadowColor(false); shadowBlur: DeskState.shadowBlur(false); shadowVerticalOffset: DeskState.shadowOffset(false) + 1 }
    }

    // degrade: o texto (mascara) recortado de um retangulo com dois tons (so existe com o preenchimento em degrade)
    Loader {
        active: w.gradient && !w.editing
        anchors.fill: parent
        sourceComponent: Item {
            Rectangle {
                id: gr
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: w.ac }
                    GradientStop { position: 1; color: w.ac2 }
                }
            }
            ShaderEffectSource { id: gsrc; sourceItem: gr; hideSource: true; live: true }
            ShaderEffectSource { id: tsrc; sourceItem: t; hideSource: true; live: true }
            MultiEffect {
                anchors.fill: parent
                source: gsrc; maskEnabled: true; maskSource: tsrc
                shadowEnabled: w.o("shadow") && !w.bare && Settings.desktopShadow
                shadowColor: DeskState.shadowColor(false); shadowBlur: DeskState.shadowBlur(false); shadowVerticalOffset: DeskState.shadowOffset(false) + 1
            }
        }
    }
    }

    // duplo clique edita ali mesmo: Ctrl+Enter salva, Esc cancela (sair do campo tambem salva)
    MouseArea {
        anchors.fill: parent
        enabled: !w.editing && !DeskState.editing && w.wid !== ""
        acceptedButtons: Qt.LeftButton
        onDoubleClicked: { ed.text = w.o("text") ?? ""; w.editing = true; ed.forceActiveFocus(); ed.selectAll() }
    }
    // end4: o campo de edicao ganha borda de 2 px na cor primaria
    Rectangle { visible: w.editing && w.lk === "end4"; anchors.fill: parent; radius: 12; color: "transparent"; border.width: 2; border.color: Theme.primary }
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
