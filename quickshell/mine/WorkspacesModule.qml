// Modulo de workspaces com varios estilos. Opcoes (em "opts"):
//   style: numbers | dots | pills | squares | bars | ring | icons | roman | kanji | custom
//   size (px), spacing (px), anim (ms), count (0 = so os que existem), onlyOccupied (esconde vazios),
//   symbols ("a b c ..." para "custom"), activeColor (#rrggbb; vazio = cor do texto)
import Quickshell
import Quickshell.Hyprland
import QtQuick

Grid {
    id: root
    property var opts: ({})
    property bool vertical: false

    readonly property string style: opts.style ?? "numbers"
    readonly property real size: opts.size ?? 22
    readonly property int animMs: Settings.animOf("workspaces").duration
    readonly property var animCurve: Settings.animOf("workspaces").curve
    readonly property color base: Settings.textColor
    // ativo: a cor escolhida no modulo; sem escolha, usa o destaque do tema (se ligado) ou a cor do texto
    readonly property color accentCol: opts.activeColor ? opts.activeColor : (Settings.themeOn ? ThemeColors.primary : Settings.textColor)
    // texto sobre o ativo (estilo numeros/capsulas): contraste com a cor ativa
    readonly property color onAccent: opts.activeColor ? Settings.barColor : (Settings.themeOn ? ThemeColors.onPrimary : Settings.barColor)
    readonly property var symbols: (opts.symbols ?? "").trim().split(/\s+/).filter(s => s.length > 0)
    readonly property var kanji: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
    readonly property var roman: ["Ⅰ", "Ⅱ", "Ⅲ", "Ⅳ", "Ⅴ", "Ⅵ", "Ⅶ", "Ⅷ", "Ⅸ", "Ⅹ"]

    spacing: opts.spacing ?? 6
    columns: vertical ? 1 : 99

    // estado de cada workspace mostrado: [{id, active, occupied, cls}]  (cls = classe do app principal)
    readonly property var entries: {
        const byId = {}
        for (const w of Hyprland.workspaces.values) if (w.id > 0) byId[w.id] = w
        const focused = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
        let ids = Object.keys(byId).map(Number)
        const n = opts.count ?? 0
        if (n > 0) { ids = []; for (let i = 1; i <= n; i++) ids.push(i) }
        if (focused > 0 && ids.indexOf(focused) < 0) ids.push(focused)
        ids.sort((a, b) => a - b)
        const out = ids.map(id => {
            const tl = byId[id] ? byId[id].toplevels.values : []
            const top = tl.find(t => t.activated) ?? tl[0]
            return { id: id, active: id === focused, occupied: tl.length > 0, cls: top && top.lastIpcObject ? (top.lastIpcObject.class ?? "") : "" }
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
            readonly property bool textual: sty === "numbers" || sty === "roman" || sty === "kanji" || sty === "custom"

            // tamanho do item conforme o estilo (a ativa estica; as outras encolhem)
            readonly property real along: sty === "pills" ? (active ? s * 2.0 : s * 0.5)
                : sty === "bars" ? (active ? s * 1.3 : s * 0.7)
                : sty === "dots" ? s * 0.62          // pontos/anel/icones: a celula e fixa; a forma escala a partir do centro
                : sty === "ring" ? s * 0.95
                : sty === "icons" ? s * 1.15
                : s
            readonly property real across: sty === "pills" ? s * 0.5 : sty === "bars" ? s * 0.18 : sty === "dots" ? along
                : sty === "ring" || sty === "icons" ? along : s
            implicitWidth: root.vertical ? across : along
            implicitHeight: root.vertical ? along : across
            // tamanho da forma (escala a partir do centro da celula)
            readonly property real shapeTarget: sty === "dots" ? (active ? s * 0.62 : s * 0.42)
                : sty === "ring" ? (active ? s * 0.95 : s * 0.75)
                : sty === "icons" ? (active ? s * 1.15 : s * 0.9) : 0
            property real shape: shapeTarget
            Behavior on shape { NumberAnimation { duration: root.animMs; easing.type: Easing.BezierSpline; easing.bezierCurve: root.animCurve } }
            Behavior on implicitWidth { NumberAnimation { duration: root.animMs; easing.type: Easing.BezierSpline; easing.bezierCurve: root.animCurve } }
            Behavior on implicitHeight { NumberAnimation { duration: root.animMs; easing.type: Easing.BezierSpline; easing.bezierCurve: root.animCurve } }

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
                Behavior on color { ColorAnimation { duration: root.animMs } }
                Behavior on opacity { NumberAnimation { duration: root.animMs; easing.type: Easing.BezierSpline; easing.bezierCurve: root.animCurve } }
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
                Behavior on border.width { NumberAnimation { duration: root.animMs; easing.type: Easing.BezierSpline; easing.bezierCurve: root.animCurve } }
                Behavior on opacity { NumberAnimation { duration: root.animMs; easing.type: Easing.BezierSpline; easing.bezierCurve: root.animCurve } }
                Rectangle {
                    anchors.centerIn: parent
                    readonly property real d: cell.active ? parent.width * 0.38 : (cell.occupied ? parent.width * 0.26 : 0)
                    width: d; height: d; radius: d / 2
                    color: cell.active ? root.accentCol : root.base
                    Behavior on width { NumberAnimation { duration: root.animMs; easing.type: Easing.BezierSpline; easing.bezierCurve: root.animCurve } }
                    Behavior on height { NumberAnimation { duration: root.animMs; easing.type: Easing.BezierSpline; easing.bezierCurve: root.animCurve } }
                }
            }

            // icone do app principal do workspace (sem app: um pontinho)
            Item {
                anchors.centerIn: parent
                width: cell.shape; height: cell.shape
                visible: cell.sty === "icons"
                readonly property string cls: cell.st.cls
                readonly property var entry: cls !== "" ? DesktopEntries.heuristicLookup(cls) : null
                readonly property string iconUrl: cls === "" ? "" : Quickshell.iconPath(entry && entry.icon ? entry.icon : cls.toLowerCase(), true)
                opacity: cell.active ? 1 : 0.55
                Behavior on opacity { NumberAnimation { duration: root.animMs; easing.type: Easing.BezierSpline; easing.bezierCurve: root.animCurve } }
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

            Text {
                anchors.centerIn: parent
                visible: cell.textual
                text: cell.label
                font.pixelSize: cell.sty === "numbers" ? cell.s * 0.5 : cell.s * 0.72
                font.bold: cell.active
                color: cell.sty === "numbers" ? (cell.active ? root.onAccent : root.base) : (cell.active ? root.accentCol : root.base)
                opacity: cell.active ? 1 : (cell.occupied ? 0.8 : 0.4)
                Behavior on opacity { NumberAnimation { duration: root.animMs; easing.type: Easing.BezierSpline; easing.bezierCurve: root.animCurve } }
            }
            // numero dentro dos quadrados
            Text {
                anchors.centerIn: parent
                visible: cell.sty === "squares"
                text: cell.label
                font.pixelSize: cell.s * 0.5
                color: cell.active ? root.onAccent : root.base
                opacity: cell.active ? 1 : (cell.occupied ? 0.8 : 0.4)
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -2
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["hyprctl", "eval", "hl.dispatch(hl.dsp.focus({ workspace = \"" + cell.modelData + "\" }))"])
            }
        }
    }
}
