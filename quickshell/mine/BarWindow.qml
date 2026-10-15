// Janela transparente de uma barra: fica sobre o centro alto desenhado pela moldura e guarda os modulos
// (e recebe cliques neles). "modelData" e a posicao da barra em Settings.bars; "geo" e o resultado de Geometry.compute.
// Com autoHide, a barra recolhe para a faixa fina e volta quando o mouse passa pela borda (animacao em Settings.anim*).
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: win
    required property int modelData
    required property var geo

    readonly property var info: geo.bars[modelData]
    readonly property var bar: Settings.bars[modelData]
    readonly property bool autoHide: !!(bar && bar.autoHide)
    readonly property var sections: Settings.sectionsOf(bar)

    // ---- mostrar / esconder ----
    property bool hovering: false   // alimentado pelo HoverHandler abaixo
    property bool armed: false      // mouse parado na borda pelo tempo de Settings.showDelay (0 = na hora)
    property bool shown: !autoHide || armed || hideTimer.running
    property real prog: shown ? 1 : 0
    Behavior on prog {
        NumberAnimation {
            duration: Settings.animOf("bars").duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Settings.animOf("bars").curve
        }
    }
    // fade dos modulos: acompanha o mesmo tempo da animacao, mas com curva propria
    // (aparece no fim da subida; some logo no comeco da descida), sem depender da curva da barra
    // quando o seletor de wallpaper compete pelo mesmo espaco, a barra recolhe junto com a subida dele
    readonly property real cover: info && info.cover ? info.cover : 0
    readonly property real eff: prog * (1 - cover)
    readonly property real ovl: info && info.fade ? info.fade : 0   // barra saindo da frente do seletor: os modulos dao fade out (e fade in na volta), no inicio do movimento
    property real fade: shown ? 1 : 0
    Behavior on fade {
        NumberAnimation {
            duration: Settings.animOf("bars").duration
            easing.type: win.shown ? Easing.InQuad : Easing.OutQuad
        }
    }
    onProgChanged: BarState.set(modelData, prog)
    Component.onCompleted: BarState.set(modelData, prog)

    onHoveringChanged: {
        if (hovering) {
            if (Settings.showDelay <= 0 || prog > 0.01) armed = true
            else showTimer.restart()
        } else {
            showTimer.stop()
            if (armed) hideTimer.restart()   // so segura aberta se chegou a abrir
            armed = false
        }
    }
    Timer { id: showTimer; interval: Math.max(1, Settings.showDelay); onTriggered: win.armed = win.hovering }
    Timer { id: hideTimer; interval: Settings.hideDelay }

    visible: !!info && !!bar
    anchors { top: true; left: true }
    // a janela e ~30% mais funda que a barra, para os modulos acompanharem curvas com overshoot (elastica)
    readonly property real full: info ? info.t : 0
    readonly property real extra: Math.ceil(full * 0.3) + 2
    readonly property string side: info ? info.side : "bottom"
    margins {
        left: info ? Math.round(info.rect.x - (side === "right" ? extra : 0)) : 0
        top: info ? Math.round(info.rect.y - (side === "bottom" ? extra : 0)) : 0
    }
    implicitWidth: info ? Math.round(info.rect.w + (info.vertical ? extra : 0)) : 1
    implicitHeight: info ? Math.round(info.rect.h + (info.vertical ? 0 : extra)) : 1
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "mine-bar"

    // area que recebe o mouse: tudo quando visivel; so uma faixa na borda quando escondida
    readonly property int trigger: 8
    readonly property bool open: !autoHide || prog > 0.01 || hovering
    Item {
        id: hit
        readonly property bool vert: win.side === "left" || win.side === "right"
        readonly property real depth: win.open ? win.full : win.trigger   // so a barra de verdade (ou a faixa) recebe o mouse
        width: vert ? depth : win.width
        height: vert ? win.height : depth
        x: win.side === "right" ? win.width - depth : 0
        y: win.side === "bottom" ? win.height - depth : 0
    }
    mask: Region { item: hit }

    Item {
        anchors.fill: parent
        HoverHandler { onHoveredChanged: win.hovering = hovered }

        // parte visivel da barra (cresce da borda): os modulos so aparecem dentro dela e acompanham a curva (inclusive overshoot)
        Item {
            id: clipper
            readonly property bool vert: win.side === "left" || win.side === "right"
            readonly property real vis: Math.max(0, Math.min(win.full + win.extra, Settings.edge + (win.full - Settings.edge) * win.eff))
            clip: true
            x: win.side === "right" ? win.width - vis : 0
            y: win.side === "bottom" ? win.height - vis : 0
            width: vert ? vis : win.width
            height: vert ? win.height : vis

            // centro dos modulos: no meio da parte visivel (vis/2 a partir da borda) e no meio da barra ao longo dela
            readonly property real cx: vert ? (win.side === "right" ? win.width - vis / 2 : vis / 2) : win.width / 2
            readonly property real cy: vert ? win.height / 2 : (win.side === "bottom" ? win.height - vis / 2 : vis / 2)

            // ---- secoes: cada uma e posicionada ao longo da barra (inicio / centro / fim + deslocamento + largura) ----
            Repeater {
                model: win.sections.length
                delegate: Item {
                    id: sec
                    required property int index
                    readonly property var cfg: win.sections[index] ?? ({})
                    readonly property bool vert: clipper.vert
                    readonly property real pad: 14
                    readonly property real total: vert ? win.height : win.width          // comprimento da barra
                    // o Repeater tambem conta como filho do Grid e soma um espacamento a mais: tira esse espacamento
                    readonly property real gridLen: vert ? grid.implicitHeight : grid.implicitWidth
                    readonly property real contentLen: Math.max(0, gridLen - (!vert && sec.cfg.modules && sec.cfg.modules.length > 0 ? (sec.cfg.spacing ?? 14) : 0))
                    readonly property real len: (cfg.width ?? 0) > 0 ? Math.min(cfg.width, total - 2 * pad) : contentLen
                    readonly property real off: cfg.offset ?? 0
                    readonly property real start: cfg.anchor === "start" ? pad + off
                        : (cfg.anchor === "end" ? total - pad - len + off : (total - len) / 2 + off)
                    readonly property real along: Math.max(0, Math.min(total - len, start))

                    width: vert ? grid.implicitWidth : len
                    height: vert ? len : grid.implicitHeight
                    x: vert ? clipper.cx - clipper.x - width / 2 : along
                    y: vert ? along : clipper.cy - clipper.y - height / 2
                    opacity: Math.min(win.fade, Math.pow(Math.max(0, Math.min(1, win.eff)), 2)) * (1 - win.ovl)   // ao esconder acompanha a barra; ao mostrar usa o fade lento
                    visible: opacity > 0.02
                    // ao aparecer os modulos sobem um pouquinho a partir da borda (e descem ao sumir)
                    readonly property real rise: (1 - Math.max(0, Math.min(1, win.fade))) * 7
                    transform: Translate {
                        x: sec.vert ? (win.side === "left" ? -sec.rise : sec.rise) : 0
                        y: sec.vert ? 0 : (win.side === "top" ? -sec.rise : sec.rise)
                    }

                    Grid {
                        id: grid
                        spacing: sec.cfg.spacing ?? 14
                        columns: sec.vert ? 1 : 99
                        horizontalItemAlignment: Grid.AlignHCenter
                        verticalItemAlignment: Grid.AlignVCenter
                        // alinhamento do conteudo dentro da secao (quando ela e mais larga que o conteudo)
                        readonly property real room: Math.max(0, sec.len - sec.contentLen)
                        readonly property real shift: sec.cfg.align === "start" ? 0 : (sec.cfg.align === "end" ? room : room / 2)
                        x: sec.vert ? 0 : shift
                        y: sec.vert ? shift : 0

                        Repeater {
                            model: sec.cfg.modules ? sec.cfg.modules.length : 0
                            delegate: ModuleView {
                                required property int index
                                readonly property var m: sec.cfg.modules[index] ?? ({})
                                type: m.type ?? ""
                                opts: m
                                vertical: sec.vert
                                side: win.side
                            }
                        }
                    }
                }
            }
        }
    }
}
