// Widget de timer (estado em Timers.qml): pomodoro, contagem regressiva ou cronometro. Anel de progresso,
// tempo grande, etapa e botoes (iniciar/pausar, zerar, pular etapa no pomodoro).
// Composicoes (opcao "look"): auto (a de sempre), end4/cards (um cartao por timer com selo, tempo e rotulo; o fundo enche com
// o progresso; end4 usa terciaria/secundaria/primaria) e compacto (uma caixa so). Cada uma e um Component num Loader.
import QtQuick
import "dwparts.js" as U

Item {
    id: w
    property int cols: 2
    property int rows: 1
    property var opts: ({})
    property string wid: ""
    property color fg: Theme.text
    property color dim: Theme.muted
    property color ac: Theme.accent
    property color ac2: Theme.tertiary            // cor companheira (o DeskView passa a do tom escolhido)
    property color cont: Theme.primaryContainer
    property color contInk: Theme.primaryContainerInk
    property bool bare: false
    property var comp: ({})                       // composicao vinda do cartao (caixas internas, selos, destaque, raio)
    readonly property var me: ({ id: wid, type: "timer", opts: opts })
    function o(k) { return DeskState.opt(me, k) }
    onMeChanged: if (wid !== "" && !DeskState.find(wid)) Timers.register(wid, me)

    readonly property var s: (Timers.st, Timers.get(wid))
    readonly property real el: (Timers.now, Timers.elapsed(wid))
    readonly property real tot: Timers.total(me)
    readonly property real remain: tot > 0 ? Math.max(0, tot - el) : el
    readonly property real frac: tot > 0 ? Math.min(1, el / tot) : (el / 60000) % 1
    function fmt(ms) { const t = Math.round(ms / 1000), h = Math.floor(t / 3600), m = Math.floor(t % 3600 / 60), sec = t % 60
        return (h > 0 ? h + ":" + String(m).padStart(2, "0") : String(m).padStart(2, "0")) + ":" + String(sec).padStart(2, "0") }
    readonly property string phaseLabel: o("mode") === "stopwatch" ? "Cronômetro" : o("mode") === "countdown" ? "Regressivo"
        : (s.phase === "focus" ? "Foco" : s.phase === "long" ? "Pausa longa" : "Pausa") + " · ciclo " + s.cycle
    readonly property color phaseCol: o("mode") === "pomodoro" && s.phase !== "focus" ? w.ac2 : w.ac

    // modo "all": tres tiles (pomodoro, cronometro, regressivo), cada um com o proprio estado em Timers (ids wid:p / wid:s / wid:c)
    readonly property bool all: o("mode") === "all"
    // composicao
    readonly property string lk: { const l = o("look"); return l === "end4" || l === "cards" || l === "compact" ? l : "auto" }
    readonly property bool cardsLook: lk === "end4" || lk === "cards"
    readonly property bool compactLook: lk === "compact"
    readonly property real pad: cardsLook || compactLook ? 14 : -1       // o DeskView usa como margem do conteudo (-1 = a padrao)
    // quantos cartoes: os tres no modo "all"; senao so o do modo escolhido (nos looks de cartao); estavel (so muda com as opcoes)
    readonly property int tileCount: all ? 3 : cardsLook ? 1 : 0
    readonly property bool showRing: tileCount === 0 && !compactLook
    function kindAt(i) { return all ? kinds[i] : kinds.find(k => k[0] === o("mode")) ?? kinds[0] }
    function innerRole(def) { return comp.innerRole && comp.innerRole !== "auto" ? comp.innerRole : def }
    function innerAlpha(def) { return comp.innerAlpha > 0 ? comp.innerAlpha : def }
    function innerRad(def) { return comp.innerRadius > 0 ? comp.innerRadius : def }
    readonly property bool vert: o("flip") || (rows > cols)
    readonly property var kinds: [["pomodoro", ":p", "flower", "Foco", "tertiary"], ["stopwatch", ":s", "sunny", "Cronômetro", "secondary"], ["countdown", ":c", "bun", "Regressivo", "primary"]]
    function subMe(k) { return { id: wid + k[1], type: "timer", opts: Object.assign({}, opts, { mode: k[0] }) } }
    function regAll() { if (wid === "") return; for (const k of kinds) Timers.register(wid + k[1], subMe(k)) }
    onOptsChanged: regAll()
    onWidChanged: regAll()
    Component.onCompleted: regAll()
    // clique direito num tile zera o timer dele (o DeskView pergunta antes de abrir o menu; Ctrl+direito abre o menu)
    function rightClick(x, y): bool {
        if (tileCount === 0) return false
        const it = tiles.childAt(x - tiles.x, y - tiles.y)
        if (!it || it.sid === undefined) return false
        Timers.reset(it.sid); return true
    }

    component Tile: Rectangle {
        id: t
        required property var k
        readonly property string sid: w.all ? w.wid + k[1] : w.wid
        readonly property var ts: (Timers.st, Timers.get(sid))
        readonly property real tel: (Timers.now, Timers.elapsed(sid))
        readonly property real ttot: Timers.total(w.all ? w.subMe(k) : w.me)
        readonly property real trem: ttot > 0 ? Math.max(0, ttot - tel) : tel
        readonly property bool pomo: k[0] === "pomodoro"
        readonly property bool compact: height < 100
        // look de cartao: papel da cor do cartao (end4 = uma cor por tipo; cards = o tom escolhido) e progresso 0..1
        readonly property string role: !w.cardsLook ? "" : w.innerRole(w.lk === "end4" ? k[4] + "Container" : "")
        readonly property color base: role === "none" ? "transparent" : role !== "" ? Theme.role(role) : w.cont
        readonly property color ink: role === "none" ? w.fg : role !== "" ? Theme.role(U.inkRole(role)) : w.contInk
        readonly property real tfrac: ttot > 0 ? Math.min(1, tel / ttot) : (tel / 60000) % 1
        radius: w.cardsLook ? w.innerRad(23) : 22
        color: w.cardsLook ? Qt.rgba(base.r, base.g, base.b, w.innerAlpha(1)) : Qt.rgba(w.fg.r, w.fg.g, w.fg.b, tm.containsMouse ? 0.12 : 0.07)
        Behavior on color { ColorAnimation { duration: 150 } }
        MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: ts.running ? Timers.pause(sid) : Timers.start(sid) }
        // progresso: o fundo enche da esquerda para a direita (so em pixels inteiros, muda raramente)
        Rectangle {
            visible: w.cardsLook && t.ts.running || (w.cardsLook && t.tel > 0)
            width: Math.round(t.width * t.tfrac); height: t.height; radius: t.radius
            color: Qt.rgba(t.ink.r, t.ink.g, t.ink.b, 0.12)
        }
        // cartao (end4): selo + tempo + rotulo (+ chips +1m/+5m no regressivo); em cartao largo vira uma linha
        Loader {
            active: w.cardsLook; anchors.fill: parent
            sourceComponent: Component {
            Item {
                id: cc
                readonly property bool wide: width > height * 1.5
                readonly property string kc: t.k[4]
                readonly property color bcol: Theme.role(kc)
                readonly property real bs: Math.max(26, Math.min(34, height - 20))
                readonly property bool chips: t.k[0] === "countdown" && w.o("chips") && (wide ? width > 230 : height >= 130)
                DwParts.Badge {
                    id: bdg
                    x: 14; y: cc.wide ? (cc.height - height) / 2 : 14
                    size: cc.bs
                    shape: w.comp.badgeShape && w.comp.badgeShape !== "auto" ? w.comp.badgeShape : t.k[2]
                    icon: t.ts.running ? "pause" : (t.pomo ? "target" : t.k[0] === "stopwatch" ? "stopwatch" : "timer")
                    bg: w.lk === "end4" ? cc.bcol : t.ink
                    fg: w.lk === "end4" ? Theme.role(U.inkRole(cc.kc)) : t.base
                }
                Column {
                    x: cc.wide ? bdg.x + bdg.width + 12 : 14
                    anchors { bottom: cc.wide ? undefined : parent.bottom; bottomMargin: 12; verticalCenter: cc.wide ? parent.verticalCenter : undefined }
                    width: cc.wide ? Math.min(implicitWidth, cc.width * 0.45) : parent.width - 20
                    spacing: -2
                    UiText { text: w.fmt(t.trem); color: t.ink; font.pixelSize: Math.max(15, Math.min(24, t.width * 0.19)); font.weight: Font.Bold; font.features: { "tnum": 1 } }
                    UiText { text: t.pomo ? (t.ts.phase === "focus" ? "Foco" : "Pausa") : t.k[3]; color: Qt.rgba(t.ink.r, t.ink.g, t.ink.b, 0.6); font.pixelSize: 11 }
                }
                Row {
                    visible: cc.chips
                    anchors { right: parent.right; rightMargin: 12; top: cc.wide ? undefined : parent.top; topMargin: 14; verticalCenter: cc.wide ? parent.verticalCenter : undefined }
                    spacing: 4
                    Repeater {
                        model: [1, 5]
                        delegate: DwParts.Chip {
                            required property int modelData
                            text: "+" + modelData + "m"; fs: 11
                            fill: Qt.rgba(t.ink.r, t.ink.g, t.ink.b, 0.15); ink: t.ink
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Timers.addMinutes(t.sid, modelData) }
                        }
                    }
                }
            }
            }
        }
        Column {
            visible: !w.cardsLook
            anchors.centerIn: parent
            spacing: 4
            ShapeIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                shape: k[2]; size: Math.max(28, Math.min(t.width * 0.42, t.height * (t.compact ? 0.5 : 0.36), 56)); padding: size * 0.24
                icon: t.ts.running ? "pause" : (t.pomo ? "target" : k[0] === "stopwatch" ? "stopwatch" : "timer")
                color: t.ts.running ? w.ac : w.cont; iconColor: t.ts.running ? Theme.accentText : w.contInk
            }
            UiText { anchors.horizontalCenter: parent.horizontalCenter; text: w.fmt(t.trem); color: w.fg; font.pixelSize: Math.max(14, Math.min(26, t.width * 0.2)); font.weight: Font.Bold; font.features: { "tnum": 1 } }
            UiText { anchors.horizontalCenter: parent.horizontalCenter; visible: !t.compact || t.k[0] !== "countdown"; text: t.pomo ? (t.ts.phase === "focus" ? "Foco" : "Pausa") : k[3]; color: w.dim; font.pixelSize: 11 }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: t.k[0] === "countdown" && !t.compact
                spacing: 4
                Repeater {
                    model: [1, 5]
                    delegate: Rectangle {
                        required property int modelData
                        width: 34; height: 20; radius: 10
                        color: cm.containsMouse ? Qt.rgba(w.ac.r, w.ac.g, w.ac.b, 0.3) : Qt.rgba(w.ac.r, w.ac.g, w.ac.b, 0.16)
                        UiText { anchors.centerIn: parent; text: "+" + modelData + "m"; color: w.fg; font.pixelSize: 11; font.weight: Font.DemiBold }
                        MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Timers.addMinutes(t.sid, modelData) }
                    }
                }
            }
        }
    }
    Item {
        id: tiles
        visible: w.tileCount > 0
        anchors.fill: parent
        Repeater {
            model: w.tileCount                    // estavel: so muda com o modo/look
            delegate: Tile {
                required property int index
                k: w.kindAt(index)
                readonly property real gap: 8
                readonly property int n: w.tileCount
                width: w.vert ? tiles.width : (tiles.width - (n - 1) * gap) / n
                height: w.vert ? (tiles.height - (n - 1) * gap) / n : tiles.height
                x: w.vert ? 0 : index * (width + gap)
                y: w.vert ? index * (height + gap) : 0
            }
        }
    }

    readonly property bool tiny: cols === 1 && rows === 1
    readonly property real ringS: tiny ? Math.min(width, height) : (rows > 1 ? Math.min(width, height * 0.66) : height)
    Item {
        id: ring
        visible: w.showRing
        width: w.ringS; height: w.ringS
        x: w.tiny || w.rows > 1 ? (w.width - width) / 2 : 0
        Canvas {
            id: cv
            anchors.fill: parent
            readonly property var deps: [w.frac, w.phaseCol, width, w.fg]
            onDepsChanged: requestPaint()
            onPaint: {
                const c = getContext("2d"); c.reset()
                const r = width / 2 - 5
                c.lineWidth = Math.max(4, width * 0.05); c.lineCap = "round"
                c.strokeStyle = Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.12)
                c.beginPath(); c.arc(width / 2, height / 2, r, 0, Math.PI * 2); c.stroke()
                c.strokeStyle = w.phaseCol
                c.beginPath(); c.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.max(0.002, w.frac)); c.stroke()
            }
        }
        Column {
            anchors.centerIn: parent
            UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: w.o("mode") === "pomodoro" ? (w.s.phase === "focus" ? "target" : "coffee") : (w.o("mode") === "stopwatch" ? "stopwatch" : "timer"); size: ring.width * 0.14; color: w.phaseCol }
            UiText { anchors.horizontalCenter: parent.horizontalCenter; visible: w.tiny || w.rows > 1; text: w.fmt(w.remain); color: w.fg; font.pixelSize: ring.width * 0.2; font.weight: Font.Bold; font.features: { "tnum": 1 } }
        }
        MouseArea { anchors.fill: parent; visible: w.tiny; cursorShape: Qt.PointingHandCursor; onClicked: w.s.running ? Timers.pause(w.wid) : Timers.start(w.wid) }
    }
    Column {
        visible: !w.tiny && w.showRing
        anchors { left: w.rows > 1 ? parent.left : ring.right; leftMargin: w.rows > 1 ? 0 : 16; right: parent.right
                  top: w.rows > 1 ? ring.bottom : undefined; topMargin: 8; verticalCenter: w.rows > 1 ? undefined : ring.verticalCenter }
        spacing: 4
        UiText { visible: w.rows === 1; text: w.fmt(w.remain); color: w.fg; font.pixelSize: Math.min(40, w.height * 0.36); font.weight: Font.Bold; font.features: { "tnum": 1 } }
        UiText { width: parent.width; horizontalAlignment: w.rows > 1 ? Text.AlignHCenter : Text.AlignLeft; text: w.phaseLabel; color: w.dim; font.pixelSize: 12 }
        // voltas do cronometro: as 3 ultimas (a mais nova em cima), com a diferenca para a anterior
        Column {
            visible: w.rows > 1 && w.o("mode") === "stopwatch" && lapList.length > 0
            anchors.horizontalCenter: parent.horizontalCenter
            readonly property var lapList: (Timers.st, Array.from(Timers.get(w.wid).laps ?? []))
            id: lapCol
            spacing: 1
            Repeater {
                model: lapCol.visible ? lapCol.lapList.slice(-3).reverse().map((v, i, a) => { const n = lapCol.lapList.length - i, prev = n > 1 ? lapCol.lapList[n - 2] : 0; return { n: n, d: v - prev, t: v } }) : []
                delegate: UiText { required property var modelData; text: "#" + modelData.n + "   +" + w.fmt(modelData.d) + "   " + w.fmt(modelData.t); color: w.dim; font.pixelSize: 11; font.features: { "tnum": 1 } }
            }
        }
        Row {
            anchors.horizontalCenter: w.rows > 1 ? parent.horizontalCenter : undefined
            spacing: 6
            Repeater {
                model: [[w.s.running ? "pause" : "play", () => w.s.running ? Timers.pause(w.wid) : Timers.start(w.wid), true],
                        ["refresh", () => Timers.reset(w.wid), false]].concat(w.o("mode") === "pomodoro" ? [["next", () => Timers.skip(w.wid), false]] : w.o("mode") === "stopwatch" ? [["flag", () => Timers.lap(w.wid), false]] : [])
                delegate: Rectangle {
                    required property var modelData
                    width: modelData[2] ? 40 : 32; height: 32; radius: 16
                    color: modelData[2] ? w.phaseCol : (bm.containsMouse ? Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.16) : Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.08))
                    UiIcon { anchors.centerIn: parent; name: modelData[0]; size: 16; color: modelData[2] ? Theme.accentText : w.fg }
                    MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData[1]() }
                }
            }
        }
    }

    // ---- compacto: uma caixa com selo, tempo, etapa e botoes ----
    Loader { active: w.compactLook; anchors.fill: parent; sourceComponent: compactC }
    Component {
        id: compactC
        DwParts.Panel {
            id: pn
            role: w.innerRole("primaryContainer"); alpha: w.innerAlpha(1); radius: w.innerRad(23)
            readonly property bool wide: width > height * 1.4
            readonly property color pc: w.phaseCol
            readonly property real bs: Math.max(30, Math.min(48, (wide ? height : height * 0.3) - 14))
            DwParts.Badge {
                id: cb
                x: 14; y: pn.wide ? (pn.height - height) / 2 : 12
                size: pn.bs
                shape: w.comp.badgeShape && w.comp.badgeShape !== "auto" ? w.comp.badgeShape : (w.o("mode") === "stopwatch" ? "sunny" : w.o("mode") === "countdown" ? "bun" : "flower")
                icon: w.o("mode") === "pomodoro" ? (w.s.phase === "focus" ? "target" : "coffee") : w.o("mode") === "stopwatch" ? "stopwatch" : "timer"
                bg: pn.ink; fg: pn.base
            }
            Column {
                x: pn.wide ? cb.x + cb.width + 12 : 14
                anchors { verticalCenter: pn.wide ? parent.verticalCenter : undefined; bottom: pn.wide ? undefined : btns.top; bottomMargin: 4 }
                width: pn.wide ? parent.width - x - btns.width - 24 : parent.width - 28
                spacing: -2
                UiText { text: w.fmt(w.remain); color: pn.ink; font.pixelSize: Math.min(34, pn.height * (pn.wide ? 0.36 : 0.2)); font.weight: Font.Bold; font.features: { "tnum": 1 } }
                UiText { width: parent.width; text: w.phaseLabel; elide: Text.ElideRight; color: Qt.rgba(pn.ink.r, pn.ink.g, pn.ink.b, 0.6); font.pixelSize: 11 }
            }
            Row {
                id: btns
                anchors { right: parent.right; rightMargin: 12; verticalCenter: pn.wide ? parent.verticalCenter : undefined; bottom: pn.wide ? undefined : parent.bottom; bottomMargin: 12 }
                spacing: 6
                DwParts.RoundBtn { width: 34; height: 34; icon: w.s.running ? "pause" : "play"; kind: "filled"; tone: pn.ink; onClicked: w.s.running ? Timers.pause(w.wid) : Timers.start(w.wid) }
                DwParts.RoundBtn { visible: !(!pn.wide && w.cols < 2); width: 34; height: 34; icon: "refresh"; kind: "outlined"; tone: pn.ink; onClicked: Timers.reset(w.wid) }
            }
        }
    }
}
