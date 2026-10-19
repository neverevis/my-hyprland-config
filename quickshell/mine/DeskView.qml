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
    readonly property var wanted: (Settings.desktopWidgets || []).filter(w => !view.lockMode || DeskState.opt(w, "lock")).map(w => w.id)
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
            readonly property real tw: w ? DeskState.px(w.cols) : 150
            readonly property real th: w ? DeskState.px(w.rows) : 150
            readonly property var pos: w ? (DeskState.auto, DeskState.posOf(w)) : ({ fx: 0, fy: 0 })
            readonly property real bx: view.area.x + pos.fx * Math.max(0, view.area.width - tw)
            readonly property real by: view.area.y + pos.fy * Math.max(0, view.area.height - th)
            property real ox: 0
            property real oy: 0
            property bool moving: false
            x: bx + ox; y: by + oy
            width: tw; height: th
            z: (Settings.desktopWidgets || []).findIndex(x => x.id === wid) + (moving ? 100 : 0) + (DeskState.selected === wid ? 50 : 0)
            Behavior on x { enabled: !card.moving; MotionAnim { use: "desktop" } }
            Behavior on y { enabled: !card.moving; MotionAnim { use: "desktop" } }
            Behavior on width { MotionAnim { use: "desktop" } }
            Behavior on height { MotionAnim { use: "desktop" } }
            property real born: 0
            Component.onCompleted: born = 1
            Behavior on born { NumberAnimation { duration: Motion.durationOf("desktop", false) + 120; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
            opacity: Math.min(1, born)
            scale: (0.85 + 0.15 * born) * (moving ? 1.03 : 1)
            Behavior on scale { enabled: card.born >= 1; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

            // ---- cores do conteudo ----
            readonly property real lum: { const a = DeskState.auto[wid]; return a && a.lum !== undefined ? a.lum : 0.3 }
            readonly property string fgMode: w ? DeskState.opt(w, "fg") : "auto"
            readonly property bool bare: cardStyle === "none"
            readonly property bool light: lum > 0.62 && !view.darkBg   // wallpaper claro embaixo: texto escuro
            readonly property color fgT: fgMode === "custom" ? (w ? DeskState.opt(w, "fgColor") : "white")
                : fgMode === "theme" ? Theme.text
                : bare ? (lum > 0.62 && !view.darkBg ? "#16151b" : "#f6f3fa") : Theme.text
            // cores que o conteudo usa: animadas (o tema troca passo a passo; a cor pelo brilho do wallpaper chega um pouco
            // depois da troca de wallpaper e antes pulava de uma vez entre claro e escuro)
            property color fg: fgT
            property color ac: acT
            Behavior on fg { ColorAnimation { duration: 700; easing.type: Easing.OutCubic } }
            Behavior on ac { ColorAnimation { duration: 700; easing.type: Easing.OutCubic } }
            readonly property color dim: Qt.rgba(fg.r, fg.g, fg.b, 0.68)
            readonly property color acT: bare && fgMode === "auto" ? (lum > 0.62 && !view.darkBg ? Qt.darker(Theme.accent, 1.8) : Qt.lighter(Theme.accent, 1.1)) : Theme.accent

            Rectangle {
                id: bg
                anchors.fill: parent
                radius: Math.min(30, Math.min(width, height) * 0.2)
                color: card.cardStyle === "card" ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, Settings.desktopCard / 100)
                    : card.cardStyle === "glass" ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, Math.max(0.32, Settings.desktopCard / 100 * 0.55))
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
                    layer.effect: MultiEffect { shadowEnabled: true; shadowColor: card.light ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(0, 0, 0, 0.65); shadowBlur: card.light ? 0.3 : 0.6; shadowVerticalOffset: card.light ? 0 : 1; blurMax: 24 }
                }
            }
            function feed() {
                const it = content.item
                if (!it || !w) return
                it.cols = w.cols; it.rows = w.rows; it.opts = w.opts || {}
                if (it.wid !== undefined) it.wid = wid
                if (it.fg !== undefined) { it.fg = Qt.binding(() => card.fg); it.dim = Qt.binding(() => card.dim); it.ac = Qt.binding(() => card.ac) }
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
                cursorShape: DeskState.locked ? Qt.PointingHandCursor : (card.moving ? Qt.ClosedHandCursor : Qt.OpenHandCursor)
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
                        Text { id: sz; text: card.w ? card.w.cols + "×" + card.w.rows : ""; color: szm.containsMouse ? Theme.accentText : Theme.text; font.pixelSize: 12; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
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
