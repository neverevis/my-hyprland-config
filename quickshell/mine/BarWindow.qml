// Janela transparente de uma barra: fica sobre o centro alto desenhado pela moldura e guarda os modulos
// (e recebe cliques neles). "modelData" e a posicao da barra em Settings.bars; "geo" e o resultado de Geometry.compute.
// Com autoHide, a barra recolhe para a faixa fina e volta quando o mouse passa pela borda (animacao em Settings.anim*).
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
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
    // mouse na borda deste lado (faixa fina em todo o lado, opcao "Revelar encostando em qualquer ponto da borda")
    readonly property bool edgeHot: autoHide && Settings.barEdgeReveal && !!BarState.edgeHover[side]
    readonly property bool hot: hovering || edgeHot
    property bool armed: false      // mouse parado na borda pelo tempo de Settings.showDelay (0 = na hora)
    // barsOpen: o comando "bar close" (IPC) esconde todas as barras, com ou sem autoHide
    // dock com "revealEmpty": aparece sozinho quando o workspace nao tem janela (e nunca por conta propria com tela cheia)
    readonly property bool wantEmpty: autoHide && sections.some(sc => (sc.modules || []).some(m => m.type === "taskbar" && m.revealEmpty))
    readonly property bool emptyWs: wantEmpty && !Hyprland.activeToplevel && !!Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.toplevels.values.length === 0
    property bool shown: BarState.barsOpen && (!autoHide || armed || hideTimer.running || emptyWs || (Settings.superReveal && BarState.superDown))
    property real prog: shown ? 1 : 0
    Behavior on prog { id: progB; MotionAnim { use: "bars"; out: progB.targetValue < 0.5 } }
    // fade dos modulos: acompanha o mesmo tempo da animacao, mas com curva propria
    // (aparece no fim da subida; some logo no comeco da descida), sem depender da curva da barra
    // quando o seletor de wallpaper compete pelo mesmo espaco, a barra recolhe junto com a subida dele
    readonly property real cover: info && info.cover ? info.cover : 0
    readonly property real eff: prog * (1 - cover)
    readonly property real ovl: info && info.fade ? info.fade : 0   // barra saindo da frente do seletor: os modulos dao fade out (e fade in na volta), no inicio do movimento
    property real fade: shown ? 1 : 0
    Behavior on fade {
        NumberAnimation {
            duration: Motion.durationOf("bars", !win.shown)
            easing.type: win.shown ? Easing.InQuad : Easing.OutQuad
        }
    }
    onProgChanged: BarState.set(modelData, prog)
    Component.onCompleted: BarState.set(modelData, prog)

    onHotChanged: {
        if (hot) {
            if (Settings.showDelay <= 0 || prog > 0.01) armed = true
            else showTimer.restart()
        } else {
            showTimer.stop()
            if (armed) hideTimer.restart()   // so segura aberta se chegou a abrir
            armed = false
        }
    }
    Timer { id: showTimer; interval: Math.max(1, Settings.showDelay); onTriggered: win.armed = win.hot }
    Timer { id: hideTimer; interval: Settings.hideDelay }

    visible: !!info && !!bar && !info.hidden   // hidden: sem espaco livre neste lado (outra barra tem prioridade)
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
    readonly property int trigger: Math.max(1, Math.min(16, Settings.barHoverStrip))
    readonly property bool open: BarState.barsOpen ? (!autoHide || prog > 0.01 || hovering) : prog > 0.01
    Item {
        id: hit
        readonly property bool vert: win.side === "left" || win.side === "right"
        readonly property real depth: win.open ? win.full : (BarState.barsOpen ? win.trigger : 0)   // so a barra de verdade (ou a faixa) recebe o mouse
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
            // faixa ocupada (em profundidade a partir da borda da tela): presa na moldura = 0..vis;
            // solta = so o retangulo dela, que entra deslizando pela borda
            readonly property bool det: !!(win.info && win.info.detached)
            readonly property real d1: det ? win.full - (1 - win.eff) * (win.full + 6) : vis
            readonly property real d0: det && win.info ? Math.max(0, d1 - win.info.th) : 0
            readonly property real dl: Math.max(0, d1 - d0)
            clip: true
            x: win.side === "right" ? win.width - d1 : (win.side === "left" ? d0 : 0)
            y: win.side === "bottom" ? win.height - d1 : (win.side === "top" ? d0 : 0)
            width: vert ? dl : win.width
            height: vert ? win.height : dl

            // centro dos modulos: no meio da faixa ocupada e no meio da barra ao longo dela
            readonly property real dm: (d0 + d1) / 2
            readonly property real cx: vert ? (win.side === "right" ? win.width - dm : dm) : win.width / 2
            readonly property real cy: vert ? win.height / 2 : (win.side === "bottom" ? win.height - dm : dm)

            // largura pelo conteudo (opcao "fit"): soma das secoes + respiro; animada, a barra cresce/encolhe com os apps
            readonly property real fitNeed: {
                let s = 0, n = 0
                for (let k = 0; k < secRep.count; k++) { const it = secRep.itemAt(k); if (it && it.contentLen > 0) { s += it.contentLen; n++ } }
                return s + Math.max(0, n - 1) * 24 + 2 * 14
            }
            property real fitAnim: fitNeed
            Behavior on fitAnim { enabled: clipper.fitAnim > 1; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            readonly property real fitOut: win.bar && win.bar.fit ? fitAnim : 0
            onFitOutChanged: BarState.setFit(win.modelData, fitOut)
            Component.onCompleted: BarState.setFit(win.modelData, fitOut)

            // ---- secoes: cada uma e posicionada ao longo da barra (inicio / centro / fim + deslocamento + largura) ----
            Repeater {
                id: secRep
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
                    // estilo do grupo: section (uma pilula da secao, se "bg"), pills (uma pilula por modulo), segmented (capsula unica com divisorias)
                    readonly property string gs: cfg.groupStyle ?? "section"
                    readonly property real gsp: gs === "segmented" ? 0 : (cfg.spacing ?? 14)
                    function roleColor(role, a) { const c = role ? ThemeColors.of(role) : Settings.textColor; return Qt.rgba(c.r, c.g, c.b, a) }
                    readonly property real contentLen: Math.max(0, gridLen - (sec.cfg.modules && sec.cfg.modules.length > 0 ? gsp : 0))
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

                    // depuracao: com a pagina Barras aberta, mostra a area de cada secao (a escolhida em destaque)
                    Rectangle {
                        readonly property bool dbg: Settings.barDebugBar === win.modelData
                        readonly property bool hot: dbg && Settings.barDebugSec === sec.index
                        visible: dbg
                        anchors.fill: parent
                        anchors.margins: -3
                        radius: 6
                        color: Qt.rgba(Settings.accent.r, Settings.accent.g, Settings.accent.b, hot ? 0.22 : 0.07)
                        border.width: hot ? 1.5 : 1
                        border.color: Qt.rgba(Settings.accent.r, Settings.accent.g, Settings.accent.b, hot ? 0.95 : 0.4)
                        z: -1
                        Behavior on color { ColorAnimation { duration: 160 } }
                        // nome da secao (so na escolhida)
                        Rectangle {
                            visible: parent.hot && !sec.vert
                            anchors { left: parent.left; bottom: parent.top; bottomMargin: -height / 2 }
                            width: dl.implicitWidth + 8; height: 13; radius: 4
                            color: Settings.accent
                            UiText { id: dl; anchors.centerIn: parent; text: sec.cfg.name || ("Seção " + (sec.index + 1)); color: Theme.accentText; font.pixelSize: 8; font.weight: Font.Bold }
                        }
                    }

                    // fundo da secao (opcao "bg"): pilula atras dos modulos, como os grupos do end4
                    Rectangle {
                        visible: (sec.gs === "segmented" || (sec.gs === "section" && !!sec.cfg.bg)) && sec.contentLen > 0
                        readonly property real pad: sec.gs === "segmented" ? 3 : (sec.cfg.bgPad ?? 9)
                        x: (sec.vert ? 0 : grid.x) - pad
                        y: (sec.vert ? grid.y : 0) - pad * 0.55
                        width: (sec.vert ? grid.implicitWidth : sec.contentLen) + pad * 2
                        height: (sec.vert ? sec.contentLen : grid.implicitHeight) + pad * 1.1
                        radius: Math.min(width, height) / 2
                        color: sec.roleColor(sec.cfg.bgRole, (sec.cfg.bgAlpha ?? 10) / 100)
                        border.width: sec.cfg.bgBorder || sec.gs === "segmented" ? 1 : 0
                        border.color: Qt.rgba(Settings.accent.r, Settings.accent.g, Settings.accent.b, 0.45)
                    }
                    Grid {
                        id: grid
                        spacing: sec.gsp
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
                            delegate: Item {
                                id: cw
                                required property int index
                                readonly property var m: sec.cfg.modules[index] ?? ({})
                                // pilula propria deste modulo: estilo "pills", ou a opcao "group" do modulo (group = false desliga)
                                readonly property bool own: m.group === false ? false : (sec.gs === "pills" || m.group === true)
                                readonly property real padA: own ? (m.bgPad ?? 9) : (sec.gs === "segmented" ? 9 : 0)
                                readonly property real padB: own ? 4 : 0
                                readonly property bool present: mv.itemVisible && mv.implicitWidth > 0
                                width: present ? mv.implicitWidth + (sec.vert ? padB * 2 : padA * 2) : 0
                                height: present ? mv.implicitHeight + (sec.vert ? padA * 2 : padB * 2) : 0
                                Rectangle {   // pilula do modulo
                                    visible: cw.own && cw.present
                                    anchors.fill: parent
                                    radius: cw.m.bgRadius !== undefined ? cw.m.bgRadius : Math.min(width, height) / 2
                                    color: sec.roleColor(cw.m.bgRole ?? sec.cfg.bgRole, (cw.m.bgAlpha ?? sec.cfg.bgAlpha ?? 14) / 100)
                                    border.width: (cw.m.bgBorder ?? sec.cfg.bgBorder) ? 1 : 0
                                    border.color: Qt.rgba(Settings.accent.r, Settings.accent.g, Settings.accent.b, 0.45)
                                }
                                Rectangle {   // divisoria do estilo "segmented"
                                    visible: sec.gs === "segmented" && cw.index > 0 && cw.present
                                    x: sec.vert ? 6 : 0; y: sec.vert ? 0 : 5
                                    width: sec.vert ? parent.width - 12 : 1; height: sec.vert ? 1 : parent.height - 10
                                    color: Qt.rgba(Settings.textColor.r, Settings.textColor.g, Settings.textColor.b, 0.22)
                                }
                                ModuleView {
                                    id: mv
                                    anchors.centerIn: parent
                                    type: cw.m.type ?? ""
                                    opts: cw.m
                                    vertical: sec.vert
                                    side: win.side
                                    barIdx: win.modelData
                                    origin: Qt.point(win.margins.left, win.margins.top)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
