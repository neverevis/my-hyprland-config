// Modulo de workspaces com varios estilos. Opcoes (em "opts"):
//   style: numbers | dots | pills | squares | bars | ring | icons | roman | kanji | custom | glyphs | bridge (pilula que viaja)
//   size (px), spacing (px), anim (ms), count (0 = so os que existem), onlyOccupied (esconde vazios),
//   symbols ("a b c ..." para "custom"), activeColor (#rrggbb; vazio = cor do texto), wrap (a roda volta do ultimo ao primeiro; padrao ligado)
//   paged (grupos de 'count', ex.: 1-10, 11-20), showNumbers (hold = pontos viram numeros com Super; always; never), appIcons (+ mono),
//   glyphs (nomes de icones por workspace, para o estilo glyphs), hoverWins (cartao com os icones das janelas ao passar o mouse; padrao ligado)
// Clique vai para o workspace; botao direito abre a visao geral; a roda do mouse passa para o proximo/anterior.
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects

Item {
    id: root
    property var opts: ({})
    property bool vertical: false
    property string side: "bottom"
    property point origin: Qt.point(0, 0)
    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight
    readonly property real gap: opts.spacing ?? 6
    // numeros: sempre, ou so enquanto o Super esta segurado (estilos pontos / anel)
    readonly property bool showNum: opts.showNumbers === "always" || (opts.showNumbers !== "never" && BarState.superDown)
    readonly property var glyphList: (opts.glyphs ?? "home web music pencil image bell monitor wave chip cloud").trim().split(/\s+/).filter(x => x.length > 0)
    // workspace especial aberto (scratchpad): vira uma pilula com o nome
    readonly property var mon: Hyprland.focusedMonitor
    readonly property string special: { const o = mon ? mon.lastIpcObject : null; const n = o && o.specialWorkspace ? (o.specialWorkspace.name ?? "") : ""; return n.replace(/^special:/, "") }

    readonly property string style: opts.style ?? "numbers"
    readonly property real size: opts.size ?? 22
    readonly property int animMs: Motion.durationOf("workspaces", false)
    readonly property color base: Settings.textColor
    // ativo: a cor escolhida no modulo; sem escolha, usa o destaque do tema (se ligado) ou a cor do texto
    readonly property color accentCol: opts.activeColor ? opts.activeColor : (Settings.themeOn ? ThemeColors.primary : Settings.textColor)
    // texto sobre o ativo (estilo numeros/capsulas): contraste com a cor ativa
    readonly property color accentInk: opts.activeColor ? Settings.barColor : (Settings.themeOn ? ThemeColors.primaryInk : Settings.barColor)
    readonly property var symbols: (opts.symbols ?? "").trim().split(/\s+/).filter(s => s.length > 0)
    readonly property var kanji: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十"]
    readonly property var roman: ["Ⅰ", "Ⅱ", "Ⅲ", "Ⅳ", "Ⅴ", "Ⅵ", "Ⅶ", "Ⅷ", "Ⅸ", "Ⅹ", "Ⅺ", "Ⅻ", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX"]


    // roda do mouse em cima dos workspaces: vai para o proximo / anterior
    function go(ws) { Quickshell.execDetached(["hyprctl", "eval", "hl.dispatch(hl.dsp.focus({ workspace = \"" + ws + "\" }))"]) }
    WheelHandler {
        property real acc: 0
        onWheel: e => {
            acc += e.angleDelta.y
            if (Math.abs(acc) < 100) return
            // passa pelos workspaces que o modulo mostra (com wrap: do ultimo volta ao primeiro; sem, para nas pontas)
            const cur = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
            const i = root.ids.indexOf(cur), n = root.ids.length
            if (n > 0) {
                const j = (i < 0 ? 0 : i) + (acc < 0 ? 1 : -1)
                if (root.opts.wrap === false) root.go(root.ids[Math.max(0, Math.min(n - 1, j))])
                else root.go(root.ids[(j + n) % n])
            }
            acc = 0
        }
    }

    // estado de cada workspace mostrado: [{id, active, occupied, cls}]  (cls = classe do app principal)
    readonly property var entries: {
        const byId = {}
        for (const w of Hyprland.workspaces.values) if (w.id > 0) byId[w.id] = w
        const focused = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
        let ids = Object.keys(byId).map(Number)
        const n = opts.paged ? (opts.count > 0 ? opts.count : 10) : (opts.count ?? 0)
        if (n > 0) {
            ids = []
            const g0 = opts.paged ? Math.floor((Math.max(1, focused) - 1) / n) * n : 0
            for (let i = 1; i <= n; i++) ids.push(g0 + i)
        }
        if (focused > 0 && !opts.paged && ids.indexOf(focused) < 0) ids.push(focused)
        ids.sort((a, b) => a - b)
        const out = ids.map(id => {
            const tl = byId[id] ? byId[id].toplevels.values : []
            const top = opts.appIcons ? tl.reduce((b, t) => { const z = t.lastIpcObject && t.lastIpcObject.size ? t.lastIpcObject.size[0] * t.lastIpcObject.size[1] : 0; return !b || z > b.z ? { t: t, z: z } : b }, null) : null
            const act = top ? top.t : (tl.find(t => t.activated) ?? tl[0])
            return { id: id, active: id === focused, occupied: tl.length > 0, cls: act && act.lastIpcObject ? (act.lastIpcObject.class ?? "") : "" }
        })
        return opts.onlyOccupied ? out.filter(x => x.active || x.occupied) : out
    }

    // a lista de ids so muda quando entra/sai um workspace: assim os itens NAO sao recriados ao trocar de workspace
    // (recriar zeraria as animacoes de esticar/encolher)
    property var ids: []
    function syncIds() {
        const n = entries.map(e => e.id)
        if (JSON.stringify(n) !== JSON.stringify(ids)) ids = n
    }
    onEntriesChanged: syncIds()
    Component.onCompleted: syncIds()

    readonly property real step: size + gap
    readonly property int actIdx: { const f = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1; return Math.max(0, ids.indexOf(f)) }
    // estilo bridge: ocupados viram pilulas que se juntam; o ativo e uma pilula que estica ate o novo workspace (dois indices, um rapido e um lento)
    property real i1: actIdx
    property real i2: actIdx
    Behavior on i1 { NumberAnimation { duration: Math.max(1, root.animMs * 0.3); easing.type: Easing.OutCubic } }
    Behavior on i2 { NumberAnimation { duration: Math.max(1, root.animMs); easing.type: Easing.OutCubic } }
    Item {
        visible: root.style === "bridge"
        width: grid.width; height: grid.height
        Repeater {
            model: root.style === "bridge" ? root.ids : []
            delegate: Rectangle {
                required property int index
                required property int modelData
                readonly property var me: root.entries.find(e => e.id === modelData)
                readonly property var nx: root.entries.find(e => e.id === root.ids[index + 1])
                readonly property bool occ: !!me && me.occupied
                readonly property real ext: occ && !!nx && nx.occupied ? root.gap : 0
                visible: occ
                x: root.vertical ? 0 : index * root.step
                y: root.vertical ? index * root.step : 0
                width: root.vertical ? root.size : root.size + ext
                height: root.vertical ? root.size + ext : root.size
                radius: root.size / 2
                color: Qt.rgba(root.base.r, root.base.g, root.base.b, 0.18)
            }
        }
        Rectangle {
            readonly property real a: Math.min(root.i1, root.i2)
            readonly property real b: Math.max(root.i1, root.i2)
            x: root.vertical ? 0 : a * root.step
            y: root.vertical ? a * root.step : 0
            width: root.vertical ? root.size : (b - a) * root.step + root.size
            height: root.vertical ? (b - a) * root.step + root.size : root.size
            radius: root.size / 2
            color: root.accentCol
            Behavior on color { enabled: !ThemeColors.fading; ColorAnimation { duration: root.animMs } }
        }
    }
    onActIdxChanged: { i1 = actIdx; i2 = actIdx }

    Grid {
        id: grid
        spacing: root.gap
        columns: root.vertical ? 1 : 99

    Repeater {
        model: root.ids
        delegate: Item {
            id: cell
            required property int modelData
            readonly property var st: root.entries.find(e => e.id === modelData) ?? { id: modelData, active: false, occupied: false, cls: "" }
            readonly property bool active: st.active
            readonly property bool occupied: st.occupied
            readonly property real s: root.size
            readonly property string sty: root.style
            readonly property bool textual: sty === "numbers" || sty === "roman" || sty === "kanji" || sty === "custom" || sty === "bridge"
            readonly property bool showNum: root.showNum && (sty === "dots" || sty === "ring")

            // tamanho do item conforme o estilo (a ativa estica; as outras encolhem)
            readonly property real along: sty === "pills" ? (active ? s * 2.0 : s * 0.5)
                : sty === "bars" ? (active ? s * 1.3 : s * 0.7)
                : sty === "dots" ? s * 0.62          // pontos/anel/icones: a celula e fixa; a forma escala a partir do centro
                : sty === "ring" ? s * 0.95
                : sty === "icons" || sty === "glyphs" ? s * 1.15
                : s
            readonly property real across: sty === "pills" ? s * 0.5 : sty === "bars" ? s * 0.18 : sty === "dots" ? along
                : sty === "ring" || sty === "icons" || sty === "glyphs" ? along : s
            implicitWidth: root.vertical ? across : along
            implicitHeight: root.vertical ? along : across
            // tamanho da forma (escala a partir do centro da celula)
            readonly property real shapeTarget: sty === "dots" ? (showNum ? s * 0.8 : active ? s * 0.62 : s * 0.42)
                : sty === "ring" ? (active ? s * 0.95 : s * 0.75)
                : sty === "icons" || sty === "glyphs" ? (active ? s * 1.15 : s * 0.9) : 0
            property real shape: shapeTarget
            Behavior on shape { MotionAnim { use: "workspaces" } }
            Behavior on implicitWidth { MotionAnim { use: "workspaces" } }
            Behavior on implicitHeight { MotionAnim { use: "workspaces" } }

            readonly property string label: {
                const i = modelData
                if (sty === "roman") return root.roman[i - 1] ?? String(i)
                if (sty === "kanji") return root.kanji[i - 1] ?? String(i)
                if (sty === "custom") return root.symbols[i - 1] ?? String(i)
                return String(i)
            }

            // forma preenchida / contornada (numeros, pontos, pilulas, quadrados, barras)
            Rectangle {
                anchors.centerIn: parent
                width: cell.sty === "dots" ? cell.shape : parent.width
                height: cell.sty === "dots" ? cell.shape : parent.height
                visible: cell.sty === "numbers" || cell.sty === "dots" || cell.sty === "pills" || cell.sty === "squares" || cell.sty === "bars"
                radius: cell.sty === "squares" ? cell.s * 0.28 : Math.min(width, height) / 2
                readonly property bool outlined: cell.sty === "numbers" || cell.sty === "squares"
                color: cell.active ? root.accentCol : (outlined ? "transparent" : (cell.occupied ? root.base : "transparent"))
                border.width: cell.active ? 0 : (cell.occupied && !outlined ? 0 : 1)
                border.color: root.base
                opacity: cell.active ? 1 : (cell.occupied ? 0.85 : 0.4)
                Behavior on color { enabled: !ThemeColors.fading; ColorAnimation { duration: root.animMs } }
                Behavior on opacity { MotionAnim { use: "workspaces" } }
            }

            // anel: contorno grosso no ativo, com um pontinho no centro nos ocupados
            Rectangle {
                anchors.centerIn: parent
                width: cell.shape; height: cell.shape
                visible: cell.sty === "ring"
                radius: width / 2
                color: "transparent"
                border.width: cell.active ? Math.max(2, cell.s * 0.14) : Math.max(1, cell.s * 0.07)
                border.color: cell.active ? root.accentCol : root.base
                opacity: cell.active ? 1 : (cell.occupied ? 0.8 : 0.4)
                Behavior on border.width { MotionAnim { use: "workspaces" } }
                Behavior on opacity { MotionAnim { use: "workspaces" } }
                Rectangle {
                    anchors.centerIn: parent
                    readonly property real d: cell.active ? parent.width * 0.38 : (cell.occupied ? parent.width * 0.26 : 0)
                    width: d; height: d; radius: d / 2
                    color: cell.active ? root.accentCol : root.base
                    Behavior on width { MotionAnim { use: "workspaces" } }
                    Behavior on height { MotionAnim { use: "workspaces" } }
                }
            }

            // icone do app principal do workspace (sem app: um pontinho)
            Item {
                anchors.centerIn: parent
                width: cell.shape; height: cell.shape
                visible: cell.sty === "icons"
                readonly property string cls: cell.st.cls
                readonly property var entry: cls !== "" ? DesktopEntries.heuristicLookup(cls) : null
                readonly property string iconUrl: cls === "" ? "" : Icons.path(entry && entry.icon ? entry.icon : cls, "")
                opacity: cell.active ? 1 : 0.55
                Behavior on opacity { MotionAnim { use: "workspaces" } }
                Image {
                    anchors.fill: parent
                    visible: parent.iconUrl !== ""
                    source: parent.iconUrl
                    sourceSize: Qt.size(64, 64)
                    smooth: true
                    fillMode: Image.PreserveAspectFit
                }
                Rectangle {   // sem app / sem icone
                    anchors.centerIn: parent
                    visible: parent.iconUrl === ""
                    width: cell.s * (cell.occupied ? 0.4 : 0.22); height: width; radius: width / 2
                    color: cell.active ? root.accentCol : root.base
                    opacity: cell.occupied || cell.active ? 1 : 0.5
                }
                Rectangle {   // marca do workspace ativo
                    visible: cell.active
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: -3 }
                    width: parent.width * 0.4; height: 2; radius: 1
                    color: root.accentCol
                }
            }

            UiText {
                anchors.centerIn: parent
                visible: cell.textual
                text: cell.label
                font.pixelSize: cell.sty === "numbers" || cell.sty === "bridge" ? cell.s * 0.5 : cell.s * 0.72
                font.bold: cell.active
                color: cell.sty === "numbers" || cell.sty === "bridge" ? (cell.active ? (cell.sty === "bridge" ? root.accentInk : root.accentInk) : root.base) : (cell.active ? root.accentCol : root.base)
                opacity: cell.active ? 1 : (cell.occupied ? 0.8 : 0.4)
                Behavior on opacity { MotionAnim { use: "workspaces" } }
            }
            // numero dentro dos quadrados
            UiText {
                anchors.centerIn: parent
                visible: cell.sty === "squares"
                text: cell.label
                font.pixelSize: cell.s * 0.5
                color: cell.active ? root.accentInk : root.base
                opacity: cell.active ? 1 : (cell.occupied ? 0.8 : 0.4)
            }

            // um icone fixo por workspace (opcao glyphs)
            UiIcon {
                visible: cell.sty === "glyphs"
                anchors.centerIn: parent
                size: cell.shape
                name: root.glyphList[(cell.modelData - 1) % Math.max(1, root.glyphList.length)] ?? "circleOutline"
                color: cell.active ? root.accentCol : root.base
                opacity: cell.active ? 1 : (cell.occupied ? 0.8 : 0.4)
                Behavior on opacity { MotionAnim { use: "workspaces" } }
            }
            // numero dentro dos pontos / aneis (Super segurado ou sempre)
            UiText {
                anchors.centerIn: parent
                visible: cell.showNum
                text: cell.label
                font.pixelSize: cell.s * 0.46; font.weight: Font.DemiBold
                color: cell.sty === "dots" ? (cell.active ? root.accentInk : Settings.barColor) : (cell.active ? root.accentCol : root.base)
            }
            // icone do app maior do workspace, no canto (opcao appIcons)
            Image {
                readonly property string cls: cell.st.cls
                readonly property var entry: cls !== "" ? DesktopEntries.heuristicLookup(cls) : null
                visible: !!root.opts.appIcons && cell.sty !== "icons" && source != ""
                source: cls === "" ? "" : Icons.path(entry && entry.icon ? entry.icon : cls, "")
                width: cell.s * (root.showNum || BarState.superDown ? 0.4 : 0.55); height: width
                sourceSize: Qt.size(48, 48); smooth: true
                anchors { right: parent.right; bottom: parent.bottom; rightMargin: -width * 0.25; bottomMargin: -width * 0.25 }
                opacity: cell.active ? 1 : 0.8
                layer.enabled: !!root.opts.mono
                layer.effect: MultiEffect { colorization: 1; colorizationColor: root.base; brightness: 0.35 }
            }

            scale: wm.containsMouse && !cell.active ? 1.12 : 1
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            MouseArea {
                id: wm
                anchors.fill: parent
                anchors.margins: -2
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: m => { BarState.popLeave(); if (m.button === Qt.RightButton) Actions.run("overview"); else root.go(cell.modelData) }
                // passar o mouse: cartao com os icones das janelas deste workspace (BarPopup "wsicons"; so existe enquanto aberto)
                onContainsMouseChanged: {
                    if (!containsMouse) { BarState.popLeave(); return }
                    if (root.opts.hoverWins === false || !cell.st.occupied) return
                    const ws = Hyprland.workspaces.values.find(w => w.id === cell.modelData)
                    if (!ws) return
                    const wins = ws.toplevels.values.map(t => ({ cls: t.lastIpcObject ? (t.lastIpcObject.class ?? "") : "", title: t.title ?? "" }))
                    const p = cell.mapToItem(null, 0, 0)
                    BarState.popEnter({ kind: "wsicons", wsid: cell.modelData, wins: wins, side: root.side, opts: ({}),
                                        rect: { x: p.x + root.origin.x, y: p.y + root.origin.y, w: cell.width, h: cell.height } })
                }
            }
        }
    }
        // workspace especial aberto
        Rectangle {
            visible: root.special !== ""
            width: sp.implicitWidth + 14; height: root.size * 0.9; radius: height / 2
            color: root.accentCol
            UiText { id: sp; anchors.centerIn: parent; text: root.special; color: root.accentInk; font.pixelSize: root.size * 0.45; font.weight: Font.DemiBold }
        }
    }
}
