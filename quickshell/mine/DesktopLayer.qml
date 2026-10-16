// Widgets da area de trabalho: uma camada acima do wallpaper e abaixo das janelas (so na tela principal).
// Clique direito num widget (ou "Editar" nas configuracoes) liga o modo de edicao: arrastar com encaixe na grade e guias
// de centro, trocar o tamanho, remover. Clique fora termina. Cada widget anima posicao, tamanho e cantos: ao aplicar
// um preset, eles deslizam e mudam de forma ate o novo lugar.
import Quickshell
import Quickshell.Wayland
import QtQuick

Scope {
    id: root
    property var geo: ({})

    PanelWindow {
        id: win
        screen: Quickshell.screens[0]
        visible: Settings.desktopOn
        anchors { left: true; right: true; top: true; bottom: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: DeskState.peek ? WlrLayer.Top : WlrLayer.Bottom
        WlrLayershell.namespace: "mine-desktop"   // regra do Hyprland: blur atras dos cartoes, sem animacao propria
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        // so os widgets pegam o mouse (fora deles, o clique vai para a area de trabalho); editando, a tela toda
        mask: DeskState.editing ? null : wmask
        Region { id: wmask }
        Component { id: regC; Region {} }
        property var regs: []
        function rebuildMask() {
            for (const r of regs) r.destroy()
            const out = []
            for (let i = 0; i < hitRep.count; i++) { const it = hitRep.itemAt(i); if (it) out.push(regC.createObject(wmask, { item: it })) }
            regs = out
            wmask.regions = out
        }

        readonly property var anim: Settings.animOf("desktop")
        // area livre: a tela menos o espaco reservado pelas barras/moldura, com margem
        readonly property real m: 22
        readonly property var z: root.geo && root.geo.zone ? root.geo.zone : ({})
        readonly property rect area: Qt.rect((z.left ?? 0) + m, (z.top ?? 0) + m,
            width - (z.left ?? 0) - (z.right ?? 0) - 2 * m, height - (z.top ?? 0) - (z.bottom ?? 0) - 2 * m)

        // lista estavel de ids: quem continua no layout nao e recriado (assim pode animar ate o novo lugar)
        ListModel { id: slots }
        function sync() {
            const ids = (Settings.desktopWidgets || []).map(w => w.id)
            for (let i = slots.count - 1; i >= 0; i--) if (!ids.includes(slots.get(i).wid)) slots.remove(i)
            const have = []
            for (let i = 0; i < slots.count; i++) have.push(slots.get(i).wid)
            for (const id of ids) if (!have.includes(id)) slots.append({ wid: id })
        }
        Connections { target: Settings; function onDesktopWidgetsChanged() { win.sync() } }
        Component.onCompleted: sync()

        // fora dos widgets, editando: clique termina a edicao
        MouseArea {
            anchors.fill: parent
            enabled: DeskState.editing
            onClicked: DeskState.editing = false
        }

        // grade de pontos (so editando)
        Canvas {
            id: grid
            anchors.fill: parent
            opacity: DeskState.editing ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 220 } }
            readonly property var deps: [win.area, Theme.text]
            onDepsChanged: requestPaint()
            onPaint: {
                const c = getContext("2d"); c.reset()
                c.fillStyle = Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.16)
                const a = win.area, st = 24
                for (let x = a.x; x <= a.x + a.width; x += st)
                    for (let y = a.y; y <= a.y + a.height; y += st) c.fillRect(x - 1, y - 1, 2, 2)
            }
        }
        // guias de centro (aparecem quando o widget arrastado encaixa no meio)
        property bool guideX: false
        property bool guideY: false
        Rectangle { visible: win.guideX && DeskState.dragging !== ""; x: win.area.x + win.area.width / 2 - 1; y: win.area.y; width: 2; height: win.area.height; color: Theme.accent; opacity: 0.8 }
        Rectangle { visible: win.guideY && DeskState.dragging !== ""; x: win.area.x; y: win.area.y + win.area.height / 2 - 1; width: win.area.width; height: 2; color: Theme.accent; opacity: 0.8 }

        // area que pega o mouse fora da edicao: os retangulos dos widgets
        Item {
            id: hits
            anchors.fill: parent
            Repeater {
                id: hitRep
                model: rep.count
                onCountChanged: Qt.callLater(win.rebuildMask)
                delegate: Item {
                    required property int index
                    readonly property Item src: rep.itemAt(index)
                    x: src ? src.x : 0; y: src ? src.y : 0
                    width: src ? src.width : 0; height: src ? src.height : 0
                }
            }
        }

        Repeater {
            id: rep
            model: slots
            delegate: Item {
                id: card
                required property string wid
                required property int index
                readonly property var w: { Settings.desktopWidgets; return DeskState.find(wid) }
                readonly property var info: w ? DeskState.info(w.type) : null
                readonly property real tw: w ? DeskState.px(w.cols) : 150
                readonly property real th: w ? DeskState.px(w.rows) : 150
                // posicao alvo (vinda das configuracoes) + deslocamento durante o arrasto
                readonly property real bx: win.area.x + (w ? w.fx : 0) * Math.max(0, win.area.width - tw)
                readonly property real by: win.area.y + (w ? w.fy : 0) * Math.max(0, win.area.height - th)
                property real ox: 0
                property real oy: 0
                property bool moving: false
                x: bx + ox; y: by + oy
                width: tw; height: th
                z: (Settings.desktopWidgets || []).findIndex(x => x.id === wid) + (moving ? 100 : 0)
                Behavior on x { enabled: !card.moving; NumberAnimation { duration: win.anim.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: win.anim.curve } }
                Behavior on y { enabled: !card.moving; NumberAnimation { duration: win.anim.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: win.anim.curve } }
                Behavior on width { NumberAnimation { duration: win.anim.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: win.anim.curve } }
                Behavior on height { NumberAnimation { duration: win.anim.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: win.anim.curve } }
                // entrada: cresce e aparece
                property real born: 0
                Component.onCompleted: born = 1
                Behavior on born { NumberAnimation { duration: win.anim.duration + 120; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                opacity: Math.min(1, born)
                scale: (0.85 + 0.15 * born) * (moving ? 1.03 : 1)
                Behavior on scale { enabled: card.born >= 1; NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                // cartao
                Rectangle {
                    id: bg
                    anchors.fill: parent
                    radius: Math.min(30, Math.min(width, height) * 0.2)
                    color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, Settings.desktopCard / 100)
                    border.width: 1
                    border.color: Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.6)
                    clip: true
                    Behavior on radius { NumberAnimation { duration: win.anim.duration } }
                    Loader {
                        id: content
                        anchors.fill: parent
                        anchors.margins: 18
                        sourceComponent: ({ clock: clockC, media: mediaC, system: systemC, calendar: calendarC, user: userC, notes: notesC })[card.w ? card.w.type : ""] ?? null
                        onLoaded: card.feed()
                    }
                }
                function feed() {
                    if (!content.item || !w) return
                    content.item.cols = w.cols; content.item.rows = w.rows; content.item.opts = w.opts || {}
                    if (content.item.wid !== undefined) content.item.wid = wid
                }
                onWChanged: feed()

                // fora da edicao: clique direito liga o modo de edicao
                MouseArea {
                    anchors.fill: parent
                    enabled: !DeskState.editing
                    acceptedButtons: Qt.RightButton
                    onClicked: DeskState.editing = true
                }

                // ---- edicao ----
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    radius: bg.radius + 3
                    color: card.moving ? Theme.tint(0.1) : "transparent"
                    border.width: 2
                    border.color: Theme.accent
                    opacity: DeskState.editing ? (dragArea.containsMouse || card.moving ? 1 : 0.55) : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                }
                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    enabled: DeskState.editing
                    hoverEnabled: true
                    preventStealing: true
                    cursorShape: card.moving ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    property real sx: 0
                    property real sy: 0
                    onPressed: m => { const p = mapToItem(win.contentItem, m.x, m.y); sx = p.x; sy = p.y; card.moving = true; DeskState.dragging = card.wid }
                    onPositionChanged: m => {
                        if (!pressed) return
                        const p = mapToItem(win.contentItem, m.x, m.y)
                        const a = win.area
                        // posicao livre, presa na area e encaixada na grade (24 px); perto do centro, gruda no centro
                        let nx = Math.max(a.x, Math.min(a.x + a.width - card.width, card.bx + p.x - sx))
                        let ny = Math.max(a.y, Math.min(a.y + a.height - card.height, card.by + p.y - sy))
                        nx = a.x + Math.round((nx - a.x) / 24) * 24
                        ny = a.y + Math.round((ny - a.y) / 24) * 24
                        const cxs = a.x + (a.width - card.width) / 2, cys = a.y + (a.height - card.height) / 2
                        win.guideX = Math.abs(nx - cxs) < 18; if (win.guideX) nx = cxs
                        win.guideY = Math.abs(ny - cys) < 18; if (win.guideY) ny = cys
                        card.ox = nx - card.bx; card.oy = ny - card.by
                    }
                    onReleased: {
                        const a = win.area
                        const fx = Math.max(0, Math.min(1, (card.bx + card.ox - a.x) / Math.max(1, a.width - card.width)))
                        const fy = Math.max(0, Math.min(1, (card.by + card.oy - a.y) / Math.max(1, a.height - card.height)))
                        DeskState.setPos(card.wid, fx, fy)
                        card.ox = 0; card.oy = 0
                        card.moving = false; DeskState.dragging = ""
                    }
                }
                // barra de ferramentas do widget
                Row {
                    anchors { right: parent.right; top: parent.top; margins: 8 }
                    spacing: 6
                    opacity: DeskState.editing && !card.moving ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    Rectangle {   // tamanho atual (clique: proximo tamanho)
                        height: 28; width: sz.implicitWidth + 34; radius: 14
                        color: szm.containsMouse ? Theme.accent : Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.9)
                        border.width: 1; border.color: Theme.border
                        Row {
                            anchors.centerIn: parent
                            spacing: 5
                            UiIcon { name: "fullscreen"; size: 14; color: szm.containsMouse ? Theme.accentText : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                            Text { id: sz; text: card.w ? card.w.cols + "×" + card.w.rows : ""; color: szm.containsMouse ? Theme.accentText : Theme.text; font.pixelSize: 12; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea { id: szm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: DeskState.cycleSize(card.wid) }
                    }
                    Rectangle {   // opcao do relogio: digital / ponteiros
                        visible: card.w && card.w.type === "clock"
                        width: 28; height: 28; radius: 14
                        color: stm.containsMouse ? Theme.accent : Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.9)
                        border.width: 1; border.color: Theme.border
                        UiIcon { anchors.centerIn: parent; name: "swap_horizontal"; size: 14; color: stm.containsMouse ? Theme.accentText : Theme.text }
                        MouseArea { id: stm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { const a = content.item ? content.item.analog : false; DeskState.setOpt(card.wid, "style", a ? "digital" : "analog") } }
                    }
                    Rectangle {   // remover
                        width: 28; height: 28; radius: 14
                        color: rmm.containsMouse ? Theme.danger : Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.9)
                        border.width: 1; border.color: Theme.border
                        UiIcon { anchors.centerIn: parent; name: "close"; size: 14; color: rmm.containsMouse ? "white" : Theme.text }
                        MouseArea { id: rmm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: DeskState.remove(card.wid) }
                    }
                }
            }
        }

        // aviso do modo de edicao
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: win.area.y + (DeskState.editing ? 0 : -60)
            Behavior on y { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
            opacity: DeskState.editing ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            width: tip.implicitWidth + 210; height: 44; radius: 22
            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.94)
            border.width: 1; border.color: Theme.border
            Row {
                anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                spacing: 10
                UiIcon { name: "dashboard"; size: 18; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                Text { id: tip; text: "Editando: arraste, troque o tamanho ou remova. Clique fora para terminar."; color: Theme.text; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
            }
            Row {
                anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                spacing: 6
                UiButton { icon: "plus"; text: "Adicionar"; kind: "ghost"; onClicked: { Settings.settingsOpen = true; Quickshell.execDetached(["qs", "-c", "mine", "ipc", "call", "settings", "go", "desktop"]) } }
                UiButton { icon: "check"; text: "Pronto"; kind: "accent"; onClicked: DeskState.editing = false }
            }
        }
    }

    Component { id: clockC; DwClock {} }
    Component { id: mediaC; DwMedia {} }
    Component { id: systemC; DwSystem {} }
    Component { id: calendarC; DwCalendar {} }
    Component { id: userC; DwUser {} }
    Component { id: notesC; DwNotes {} }
}
