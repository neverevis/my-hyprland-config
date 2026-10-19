// Os widgets da area de trabalho desenhados numa area (usado na area de trabalho e na tela de bloqueio).
// Cada widget: cartao (fundo Cartao / Vidro / Sem fundo), conteudo do tipo dele e, se editable, arrastar com encaixe,
// guias de centro e barra de ferramentas (tamanho, opcoes, remover). Posicao, tamanho e cantos animam (animacao
// "Widgets da area de trabalho"); widgets em posicao automatica vao para onde a analise do wallpaper mandar.
// Cor do texto automatica: sem fundo, clara ou escura conforme o brilho do wallpaper embaixo (DeskState.auto).
import Quickshell
import QtQuick
import QtQuick.Effects

Item {
    id: view
    property rect area: Qt.rect(0, 0, width, height)
    property bool editable: false
    property bool lockMode: false          // so os widgets marcados "mostrar na tela de bloqueio"
    property bool darkBg: false            // fundo escurecido (tela de bloqueio): texto sempre claro nos sem fundo
    property alias count: rep.count
    function itemAt(i) { return rep.itemAt(i) }
    signal guides(bool gx, bool gy)

    // lista estavel de ids: quem continua no layout nao e recriado (assim pode animar ate o novo lugar)
    ListModel { id: slots }
    // tela de bloqueio: so os marcados; area de trabalho: some quem e "so na tela de bloqueio" (menos editando, para achar e mexer)
    readonly property var wanted: (Settings.desktopWidgets || []).filter(w => view.lockMode ? DeskState.opt(w, "lock")
        : !(DeskState.opt(w, "lock") && DeskState.opt(w, "lockOnly")) || (view.editable && DeskState.editing)).map(w => w.id)
    onWantedChanged: sync()
    function sync() {
        const ids = wanted
        for (let i = slots.count - 1; i >= 0; i--) if (!ids.includes(slots.get(i).wid)) slots.remove(i)
        const have = []
        for (let i = 0; i < slots.count; i++) have.push(slots.get(i).wid)
        for (const id of ids) if (!have.includes(id)) slots.append({ wid: id })
    }
    Component.onCompleted: sync()

    Repeater {
        id: rep
        model: slots
        delegate: Item {
            id: card
            required property string wid
            required property int index
            readonly property var w: { Settings.desktopWidgets; return DeskState.find(wid) }
            readonly property string cardStyle: { const c = w ? DeskState.opt(w, "card") : "auto"; return c === "auto" ? Settings.desktopCardStyle : c }
            // arrastando a alca do canto: dw/dh valem ate soltar
            property real dw: -1
            property real dh: -1
            property bool resizing: false
            readonly property real tw: dw > 0 ? dw : (w ? DeskState.px(w.cols) : 150)
            readonly property real th: dh > 0 ? dh : (w ? DeskState.px(w.rows) : 150)
            readonly property var pos: w ? (DeskState.auto, DeskState.posOf(w)) : ({ fx: 0, fy: 0 })
            readonly property real bx: view.area.x + pos.fx * Math.max(0, view.area.width - tw)
            readonly property real by: view.area.y + pos.fy * Math.max(0, view.area.height - th)
            property real ox: 0
            property real oy: 0
            property bool moving: false
            x: bx + ox; y: by + oy
            width: tw; height: th
            z: (Settings.desktopWidgets || []).findIndex(x => x.id === wid) + (moving ? 100 : 0) + (DeskState.selected === wid ? 50 : 0)
            Behavior on x { enabled: !card.moving && !card.resizing; MotionAnim { use: "desktop" } }
            Behavior on y { enabled: !card.moving && !card.resizing; MotionAnim { use: "desktop" } }
            Behavior on width { enabled: !card.resizing; MotionAnim { use: "desktop" } }
            Behavior on height { enabled: !card.resizing; MotionAnim { use: "desktop" } }
            property real born: 0
            Component.onCompleted: born = 1
            Behavior on born { NumberAnimation { duration: Motion.durationOf("desktop", false) + 120; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
            opacity: Math.min(1, born) * (!view.lockMode && w && DeskState.opt(w, "lock") && DeskState.opt(w, "lockOnly") ? 0.45 : 1)   // so da tela de bloqueio: apagado editando
            scale: (0.85 + 0.15 * born) * (moving ? 1.03 : 1)
            Behavior on scale { enabled: card.born >= 1; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

            // ---- cores do conteudo ----
            // tom (opcao "Cor"): global = o padrao da pagina Widgets; auto = claro/escuro pelo brilho do wallpaper embaixo;
            // primary/secondary/tertiary = uma familia da paleta (cartao no tom suave, texto e destaques na cor); neutral = so o
            // texto do tema; custom = a cor escolhida. Cada widget recebe fg, dim, ac (destaque), ac2 (cor companheira, ex.:
            // ponteiro dos minutos), cont (versao suave, ex.: a flor) e contInk (texto/marcas em cima da versao suave).
            readonly property real lum: { const a = DeskState.auto[wid]; return a && a.lum !== undefined ? a.lum : 0.3 }
            // wall0..wall7: uma cor de verdade do wallpaper (acompanha a troca de wallpaper), tratada como "minha cor"
            readonly property string rawTone: { const t = w ? DeskState.opt(w, "tone") : "global"; return t === "global" ? Settings.desktopTone : t }
            readonly property bool wallTone: rawTone.indexOf("wall") === 0
            readonly property string tone: wallTone ? "custom" : rawTone
            readonly property color custom: wallTone ? Theme.readable(ThemeColors.wallColor(parseInt(rawTone.slice(4)) || 0))
                : tone === "custom" ? (w && w.opts && w.opts.fgColor ? w.opts.fgColor : Settings.desktopToneColor) : "white"
            readonly property bool fam: tone === "primary" || tone === "secondary" || tone === "tertiary"
            readonly property var pal: Theme.family(fam ? tone : "primary")
            readonly property bool bare: cardStyle === "none"
            readonly property bool light: lum > 0.62 && !view.darkBg   // wallpaper claro embaixo: texto escuro
            readonly property color ink: light ? "#16151b" : "#f6f3fa"
            // sobre wallpaper claro (sem fundo) as cores da paleta escurecem para continuar legiveis
            function wallSafe(c) { return bare && light ? Qt.darker(c, 1.9) : c }
            readonly property color fgT: tone === "custom" ? custom
                : fam ? (bare ? (light ? Qt.darker(pal.main, 2.4) : pal.contInk) : pal.contInk)
                : tone === "neutral" ? (bare ? ink : Theme.text)
                : bare ? ink : Theme.text
            readonly property color acT: tone === "custom" ? custom
                : tone === "neutral" ? fgT
                : fam ? wallSafe(pal.main)
                : bare ? (light ? Qt.darker(Theme.accent, 1.8) : Qt.lighter(Theme.accent, 1.1)) : Theme.accent
            readonly property color ac2T: tone === "custom" ? Qt.tint(custom, Qt.rgba(0, 0, 0, 0.25)) : tone === "neutral" ? Qt.rgba(fgT.r, fgT.g, fgT.b, 0.7) : wallSafe(pal.pair)
            readonly property color contT: tone === "custom" ? Qt.tint(Theme.bg, Qt.rgba(custom.r, custom.g, custom.b, 0.35))
                : tone === "neutral" ? Theme.card : (bare && light ? Qt.lighter(pal.cont, 1.6) : pal.cont)
            readonly property color contInkT: tone === "custom" ? Qt.lighter(custom, 1.25) : tone === "neutral" ? Theme.text : (bare && light ? Qt.darker(pal.main, 2.2) : pal.contInk)
            // cores que o conteudo usa: animadas (o tema troca passo a passo; a cor pelo brilho do wallpaper chega um pouco
            // depois da troca de wallpaper e antes pulava de uma vez entre claro e escuro)
            property color fg: fgT
            property color ac: acT
            property color ac2: ac2T
            property color cont: contT
            property color contInk: contInkT
            Behavior on fg { ColorAnimation { duration: 700; easing.type: Easing.OutCubic } }
            Behavior on ac { ColorAnimation { duration: 700; easing.type: Easing.OutCubic } }
            Behavior on ac2 { ColorAnimation { duration: 700; easing.type: Easing.OutCubic } }
            Behavior on cont { ColorAnimation { duration: 700; easing.type: Easing.OutCubic } }
            Behavior on contInk { ColorAnimation { duration: 700; easing.type: Easing.OutCubic } }
            readonly property color dim: Qt.rgba(fg.r, fg.g, fg.b, 0.68)
            // fundo do cartao: no tom escolhido usa a versao suave da familia
            readonly property color cardBase: fam ? pal.cont : tone === "custom" ? contT : Theme.bg

            // cartao e vidro: sombra opcional por baixo (pagina Aparencia > Sombras e brilhos)
            RectangularShadow {
                anchors.fill: bg
                visible: Settings.desktopShadow && Settings.desktopShadowCards && !card.bare
                radius: bg.radius
                blur: 6 + Settings.desktopShadowSize * 0.4
                spread: 0
                offset.y: DeskState.shadowOffset(card.light) * 2
                color: DeskState.shadowColor(card.light)
            }
            Rectangle {
                id: bg
                anchors.fill: parent
                radius: Math.min(30, Math.min(width, height) * 0.2)
                color: card.cardStyle === "card" ? Qt.rgba(card.cardBase.r, card.cardBase.g, card.cardBase.b, Settings.desktopCard / 100)
                    : card.cardStyle === "glass" ? Qt.rgba(card.cardBase.r, card.cardBase.g, card.cardBase.b, Math.max(0.32, Settings.desktopCard / 100 * 0.55))
                    : "transparent"
                border.width: card.bare ? 0 : 1
                border.color: card.cardStyle === "glass" ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.6)
                clip: !card.bare
                Behavior on radius { MotionAnim { use: "desktop" } }
                Behavior on color { enabled: !ThemeColors.fading; ColorAnimation { duration: 220 } }
                Loader {
                    id: content
                    anchors.fill: parent
                    anchors.margins: card.bare ? 4 : 18
                    sourceComponent: DeskWidgets.component(card.w ? card.w.type : "")
                    onLoaded: card.feed()
                    // sem fundo: sombra suave para ler em cima de qualquer wallpaper
                    // (menos nos que tem fundo proprio, como o relogio flor: a sombra virava uma copia da forma por baixo)
                    layer.enabled: card.bare && Settings.desktopShadow && !(content.item && content.item.ownBackground)
                    layer.effect: MultiEffect { shadowEnabled: true; shadowColor: DeskState.shadowColor(card.light); shadowBlur: DeskState.shadowBlur(card.light); shadowVerticalOffset: DeskState.shadowOffset(card.light); blurMax: 32 }
                }
            }
            function feed() {
                const it = content.item
                if (!it || !w) return
                it.cols = w.cols; it.rows = w.rows
                // na tela de bloqueio o relogio pode ter outro estilo
                const ls = view.lockMode ? DeskState.opt(w, "lockStyle") : undefined
                it.opts = ls && ls !== "same" ? Object.assign({}, w.opts || {}, { style: ls }) : (w.opts || {})
                if (it.posX !== undefined) it.posX = Qt.binding(() => card.pos.fx)
                if (it.wid !== undefined) it.wid = wid
                if (it.fg !== undefined) { it.fg = Qt.binding(() => card.fg); it.dim = Qt.binding(() => card.dim); it.ac = Qt.binding(() => card.ac) }
                if (it.ac2 !== undefined) it.ac2 = Qt.binding(() => card.ac2)
                if (it.cont !== undefined) { it.cont = Qt.binding(() => card.cont); it.contInk = Qt.binding(() => card.contInk) }
                if (it.bare !== undefined) it.bare = Qt.binding(() => card.bare)
            }
            onWChanged: feed()

            // fora da edicao: clique direito abre o menu (na area de trabalho)
            MouseArea {
                anchors.fill: parent
                enabled: view.editable && !DeskState.editing
                acceptedButtons: Qt.RightButton
                onClicked: m => { const p = mapToItem(view, m.x, m.y); DeskMenu.show(p.x, p.y, card.wid) }
            }

            // ---- edicao ----
            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: bg.radius + 3
                color: card.moving ? Theme.tint(0.1) : "transparent"
                border.width: DeskState.selected === card.wid ? 3 : 2
                border.color: Theme.accent
                opacity: view.editable && DeskState.editing ? (dragArea.containsMouse || card.moving || DeskState.selected === card.wid ? 1 : 0.5) : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 160 } }
            }
            MouseArea {
                id: dragArea
                anchors.fill: parent
                enabled: view.editable && DeskState.editing
                hoverEnabled: true
                preventStealing: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: card.moving && !DeskState.locked ? Qt.ClosedHandCursor : Qt.ArrowCursor
                property real sx: 0
                property real sy: 0
                property bool dragged: false
                onPressed: m => {
                    if (m.button === Qt.RightButton) { const q = mapToItem(view, m.x, m.y); DeskMenu.show(q.x, q.y, card.wid); return }
                    const p = mapToItem(view, m.x, m.y); sx = p.x; sy = p.y; dragged = false
                    if (!DeskState.locked) { card.moving = true; DeskState.dragging = card.wid }
                }
                onPositionChanged: m => {
                    if (!pressed || !card.moving) return
                    const p = mapToItem(view, m.x, m.y)
                    if (Math.abs(p.x - sx) + Math.abs(p.y - sy) > 4) dragged = true
                    const a = view.area
                    let nx = Math.max(a.x, Math.min(a.x + a.width - card.width, card.bx + p.x - sx))
                    let ny = Math.max(a.y, Math.min(a.y + a.height - card.height, card.by + p.y - sy))
                    if (Settings.desktopSnap) { nx = a.x + Math.round((nx - a.x) / 24) * 24; ny = a.y + Math.round((ny - a.y) / 24) * 24 }
                    const cxs = a.x + (a.width - card.width) / 2, cys = a.y + (a.height - card.height) / 2
                    const gx = Math.abs(nx - cxs) < 18, gy = Math.abs(ny - cys) < 18
                    if (gx) nx = cxs
                    if (gy) ny = cys
                    view.guides(gx, gy)
                    card.ox = nx - card.bx; card.oy = ny - card.by
                }
                onReleased: m => {
                    if (m.button === Qt.RightButton) return
                    if (card.moving && dragged) {
                        const a = view.area
                        const fx = Math.max(0, Math.min(1, (card.bx + card.ox - a.x) / Math.max(1, a.width - card.width)))
                        const fy = Math.max(0, Math.min(1, (card.by + card.oy - a.y) / Math.max(1, a.height - card.height)))
                        DeskState.setPos(card.wid, fx, fy)
                    } else DeskState.selected = DeskState.selected === card.wid ? "" : card.wid   // clique: abre/fecha as opcoes
                    card.ox = 0; card.oy = 0
                    card.moving = false; DeskState.dragging = ""
                    view.guides(false, false)
                }
                onDoubleClicked: DeskState.selected = card.wid
            }
            // ---- alca do canto: tamanho arrastando (imagem: livre; os outros encaixam na grade) ----
            Rectangle {
                id: rsz
                readonly property bool free: card.w ? !!DeskState.info(card.w.type).free : false
                anchors { right: parent.right; bottom: parent.bottom; margins: -7 }
                width: 22; height: 22; radius: 11
                z: 20
                color: rszM.pressed || rszM.containsMouse ? Theme.accent : Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.95)
                border.width: 2; border.color: Theme.accent
                opacity: view.editable && DeskState.editing && !card.moving && (dragArea.containsMouse || rszM.containsMouse || card.resizing || DeskState.selected === card.wid) ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 140 } }
                UiIcon { anchors.centerIn: parent; name: "resize"; size: 12; color: rszM.pressed || rszM.containsMouse ? Theme.accentText : Theme.accent }
                MouseArea {
                    id: rszM
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    preventStealing: true
                    cursorShape: Qt.SizeFDiagCursor
                    property real sx: 0
                    property real sy: 0
                    property real sw: 0
                    property real sh: 0
                    property real x0: 0
                    property real y0: 0
                    function cells(px) { return (px + DeskState.gap) / (DeskState.cell + DeskState.gap) }
                    onPressed: m => {
                        const p = mapToItem(view, m.x, m.y); sx = p.x; sy = p.y; sw = card.width; sh = card.height; x0 = card.x; y0 = card.y
                        card.resizing = true
                    }
                    onPositionChanged: m => {
                        if (!pressed) return
                        const p = mapToItem(view, m.x, m.y), a = view.area
                        let c = cells(Math.max(60, Math.min(a.x + a.width - x0, sw + p.x - sx)))
                        let r = cells(Math.max(60, Math.min(a.y + a.height - y0, sh + p.y - sy)))
                        c = rsz.free ? Math.max(0.5, Math.round(c * 20) / 20) : Math.max(1, Math.round(c))
                        r = rsz.free ? Math.max(0.5, Math.round(r * 20) / 20) : Math.max(1, Math.round(r))
                        card.dw = DeskState.px(Math.min(6, c)); card.dh = DeskState.px(Math.min(5, r))
                        card.ox = x0 - card.bx; card.oy = y0 - card.by   // canto de cima parado
                    }
                    onReleased: {
                        const a = view.area, c = cells(card.dw), r = cells(card.dh)
                        const fx = Math.max(0, Math.min(1, (x0 - a.x) / Math.max(1, a.width - card.dw)))
                        const fy = Math.max(0, Math.min(1, (y0 - a.y) / Math.max(1, a.height - card.dh)))
                        DeskState.setGeom(card.wid, Math.round(c * 100) / 100, Math.round(r * 100) / 100, fx, fy)
                        card.dw = -1; card.dh = -1; card.ox = 0; card.oy = 0
                        Qt.callLater(() => card.resizing = false)
                    }
                }
            }
            // ---- alca de girar (imagem: foto e adesivo): arraste em volta do centro ----
            Item {
                id: rot
                readonly property bool can: card.w && card.w.type === "image" && ["photo", "sticker"].indexOf(DeskState.opt(card.w, "kind")) >= 0
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.top; bottomMargin: 2 }
                width: 24; height: 34
                z: 20
                opacity: rot.can && view.editable && DeskState.editing && !card.moving && (dragArea.containsMouse || rotM.containsMouse || rotM.pressed || DeskState.selected === card.wid) ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 140 } }
                Rectangle { anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom } width: 2; height: 12; color: Theme.accent }
                Rectangle {
                    width: 24; height: 24; radius: 12
                    color: rotM.pressed || rotM.containsMouse ? Theme.accent : Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.95)
                    border.width: 2; border.color: Theme.accent
                    UiIcon { anchors.centerIn: parent; name: "rotate"; size: 13; color: rotM.pressed || rotM.containsMouse ? Theme.accentText : Theme.accent }
                    UiText { visible: rotM.pressed; anchors { left: parent.right; leftMargin: 6; verticalCenter: parent.verticalCenter } text: Math.round(rotM.angle) + "°"
                        color: Theme.text; font.pixelSize: 12; font.weight: Font.Bold; style: Text.Outline; styleColor: Theme.bg }
                }
                MouseArea {
                    id: rotM
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    preventStealing: true
                    cursorShape: Qt.SizeAllCursor
                    property real angle: 0
                    onPositionChanged: m => {
                        if (!pressed) return
                        const p = mapToItem(card, m.x, m.y)
                        let a = Math.atan2(p.x - card.width / 2, card.height / 2 - p.y) * 180 / Math.PI
                        if (Math.abs(a) < 4) a = 0                                // encaixa no reto
                        angle = Math.max(-180, Math.min(180, Math.round(a)))
                        if (content.item) content.item.opts = Object.assign({}, card.w.opts || {}, { tilt: angle })   // ao vivo, sem gravar
                    }
                    onPressed: angle = card.w ? DeskState.opt(card.w, "tilt") : 0
                    onReleased: DeskState.setOpt(card.wid, "tilt", angle)
                }
            }
            // barra de ferramentas
            Row {
                anchors { right: parent.right; top: parent.top; margins: 8 }
                spacing: 6
                opacity: view.editable && DeskState.editing && !card.moving ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 160 } }
                Rectangle {
                    height: 28; width: sz.implicitWidth + 34; radius: 14
                    color: szm.containsMouse ? Theme.accent : Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.92)
                    border.width: 1; border.color: Theme.border
                    Row {
                        anchors.centerIn: parent
                        spacing: 5
                        UiIcon { name: "fullscreen"; size: 14; color: szm.containsMouse ? Theme.accentText : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                        UiText { id: sz; text: card.w ? Math.round(card.w.cols * 10) / 10 + "×" + Math.round(card.w.rows * 10) / 10 : ""; color: szm.containsMouse ? Theme.accentText : Theme.text; font.pixelSize: 12; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: szm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: DeskState.cycleSize(card.wid) }
                }
                Repeater {
                    model: [["tune", () => DeskState.selected = DeskState.selected === card.wid ? "" : card.wid, false], ["close", () => DeskState.remove(card.wid), true]]
                    delegate: Rectangle {
                        required property var modelData
                        width: 28; height: 28; radius: 14
                        color: tbm.containsMouse ? (modelData[2] ? Theme.danger : Theme.accent) : Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.92)
                        border.width: 1; border.color: Theme.border
                        UiIcon { anchors.centerIn: parent; name: modelData[0]; size: 14; color: tbm.containsMouse ? (modelData[2] ? "white" : Theme.accentText) : Theme.text }
                        MouseArea { id: tbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData[1]() }
                    }
                }
            }
        }
    }
}
