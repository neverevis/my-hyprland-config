// Launcher de aplicativos: painel de vidro no centro (ou no topo) com busca; apps ordenados por uso.
// Abra/feche com:  qs -c mine ipc call launcher toggle     (Super + Space no Hyprland)
// Setas / Ctrl+N / Ctrl+P escolhem, Enter abre, Esc fecha. Configuracoes: pagina "Launcher".
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

Scope {
    id: root
    property var geo: ({ launcher: null })   // resultado de Geometry.compute (vem do shell.qml)
    readonly property bool open: Settings.launcherOpen   // pedido do usuario
    property bool alive: false                            // janela existe (fica ate a animacao de saida terminar)
    property string query: ""

    IpcHandler {
        target: "launcher"
        function toggle(): void { Settings.launcherOpen = !Settings.launcherOpen }
        function open(): void { Settings.launcherOpen = true }
        function close(): void { Settings.launcherOpen = false }
    }
    onOpenChanged: {
        if (open) { closeTimer.stop(); Settings.wpPickerOpen = false; Settings.settingsOpen = false; Settings.homeOpen = false; query = ""; alive = true }
        else closeTimer.restart()
    }
    Timer { id: closeTimer; interval: 480; onTriggered: root.alive = false }

    // ---- tamanho do conteudo (compartilhado: a moldura acoplada cresce ate ele) ----
    readonly property var list: root.results(root.query)
    readonly property int rows: Math.max(3, Settings.launcherRows)
    readonly property real rowH: Math.max(40, Settings.launcherIcon + 20)
    readonly property real shown: Math.min(list.length, rows)
    readonly property real contentTarget: 64 + (shown > 0 ? shown * rowH + 16 : 0)
    property real contentH: contentTarget
    Behavior on contentH { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    onContentHChanged: BarState.launcherDepth = contentH
    Component.onCompleted: BarState.launcherDepth = contentH

    // ---- busca ----
    function rank(e, q) {
        const n = (e.name ?? "").toLowerCase()
        let s = 0
        if (n === q) s = 1000
        else if (n.startsWith(q)) s = 800 - n.length
        else if (n.includes(" " + q)) s = 600 - n.length
        else if (n.includes(q)) s = 500 - n.indexOf(q)
        else {
            let i = 0, gaps = 0, last = -1
            for (const ch of q) {   // subsequencia (ex.: "ffx" -> Firefox)
                const j = n.indexOf(ch, i)
                if (j < 0) { i = -1; break }
                if (last >= 0) gaps += j - last - 1
                last = j; i = j + 1
            }
            if (i >= 0) s = 300 - gaps
            else {
                const extra = ((e.genericName ?? "") + " " + (e.comment ?? "") + " " + (e.keywords ?? []).join(" ")).toLowerCase()
                if (extra.includes(q)) s = 150
            }
        }
        return s
    }
    function results(query) {
        const q = query.trim().toLowerCase()
        const usage = Settings.launcherUsage ?? {}
        const apps = DesktopEntries.applications.values.filter(e => !e.noDisplay)
        const scored = []
        for (const e of apps) {
            const boost = Math.min(usage[e.id] ?? 0, 30) * 4
            if (q === "") scored.push({ e: e, s: boost })
            else { const r = rank(e, q); if (r > 0) scored.push({ e: e, s: r + boost }) }
        }
        scored.sort((a, b) => b.s - a.s || (a.e.name ?? "").localeCompare(b.e.name ?? ""))
        return scored.map(x => x.e)
    }
    function launch(e) {
        if (!e) return
        const u = Object.assign({}, Settings.launcherUsage ?? {})
        u[e.id] = (u[e.id] ?? 0) + 1
        Settings.launcherUsage = u
        e.execute()
        Settings.launcherOpen = false
    }

    LazyLoader {
        active: root.alive

        PanelWindow {
            id: win
            anchors { left: true; right: true; top: true; bottom: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "mine-launcher"   // regra de blur/sem animacao do Hyprland

            // ---- geometria ----
            readonly property bool docked: Settings.launcherDocked
            readonly property string side: Settings.launcherSide
            readonly property bool vert: side === "left" || side === "right"
            readonly property real e: Settings.edge
            readonly property real cw: Math.min(Settings.launcherWidth, width - 100)   // largura do conteudo
            readonly property real ch: root.contentH                                    // altura do conteudo
            // progresso: acoplado = o da moldura (BarState); flutuante = proprio, mesma animacao
            property real fprog: root.open ? 1 : 0
            Behavior on fprog {
                NumberAnimation {
                    duration: Settings.animOf("launcher").duration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Settings.animOf("launcher").curve
                }
            }
            readonly property real pp: docked ? BarState.launcherProg : fprog

            readonly property var pk: root.geo.launcher
            // acoplado: retangulo do conteudo dentro da "barra" calculada pela moldura
            readonly property rect dbox: !pk ? Qt.rect(0, 0, 0, 0) : (
                side === "top" ? Qt.rect(pk.rect.x, pk.rect.y + e + 8, pk.rect.w, ch)
                : side === "bottom" ? Qt.rect(pk.rect.x, pk.rect.y + 12, pk.rect.w, ch)
                : side === "left" ? Qt.rect(pk.rect.x + e + 8, pk.rect.y, cw, pk.rect.h)
                : Qt.rect(pk.rect.x + 12, pk.rect.y, cw, pk.rect.h))
            // flutuante: centro ou topo, com leve subida
            readonly property rect fbox: Qt.rect((width - cw) / 2, (Settings.launcherPos === "top" ? 110 : (height - ch) / 2 - 60) + (1 - Math.min(1, pp)) * 18, cw, ch)
            readonly property rect box: docked ? dbox : fbox

            // acoplado: parte visivel do painel (cresce da borda) recorta o conteudo, que sobe junto
            readonly property real fullDepth: docked && pk ? pk.t : 0
            readonly property real vis: docked ? Math.max(0, Math.min(fullDepth, e + (fullDepth - e) * pp)) : 0
            readonly property rect clipR: !docked || !pk ? Qt.rect(0, 0, 0, 0)
                : side === "top" ? Qt.rect(pk.rect.x, 0, pk.rect.w, vis)
                : side === "bottom" ? Qt.rect(pk.rect.x, height - vis, pk.rect.w, vis)
                : side === "left" ? Qt.rect(0, pk.rect.y, vis, pk.rect.h)
                : Qt.rect(width - vis, pk.rect.y, vis, pk.rect.h)
            readonly property real lag: docked ? fullDepth - vis : 0

            MouseArea { anchors.fill: parent; onClicked: Settings.launcherOpen = false }

            Item {
                id: holder
                x: win.docked ? win.clipR.x : 0
                y: win.docked ? win.clipR.y : 0
                width: win.docked ? win.clipR.width : win.width
                height: win.docked ? win.clipR.height : win.height
                clip: win.docked
                MouseArea { anchors.fill: parent; visible: win.docked }   // clique no painel nao fecha

                Item {
                    id: inner
                    x: -holder.x + (win.side === "left" ? -win.lag : (win.side === "right" ? win.lag : 0))
                    y: -holder.y + (win.side === "top" ? -win.lag : (win.side === "bottom" ? win.lag : 0))
                    width: win.width; height: win.height
                    opacity: win.docked ? Math.max(0, Math.min(1, win.pp * 1.4 - 0.2)) : Math.max(0, Math.min(1, win.pp * 1.6))

                    // ---- painel (conteudo) ----
                    Rectangle {
                        id: panel
                        x: win.box.x; y: win.box.y
                        width: win.box.width; height: win.box.height
                        radius: win.docked ? 0 : Settings.launcherRadius
                        color: win.docked ? "transparent" : Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, Settings.glass ? Math.min(1, Settings.glassOpacity / 100 + 0.08) : 1)
                        border.width: win.docked ? 0 : 1; border.color: Theme.border
                        scale: win.docked ? 1 : 0.94 + 0.06 * Math.min(1, win.pp)
                        transformOrigin: Item.Top
                        clip: true
                        MouseArea { anchors.fill: parent }

                        // ---- campo de busca ----
                        Item {
                            id: bar
                            anchors { left: parent.left; right: parent.right; top: parent.top }
                            height: 64
                            Rectangle {
                                anchors { fill: parent; margins: 10 }
                                radius: Math.max(8, Settings.launcherRadius - 8)
                                color: Settings.glass ? Qt.rgba(Theme.card.r, Theme.card.g, Theme.card.b, 0.7) : Theme.card
                            }
                            Text {
                                id: glyph
                                anchors { left: parent.left; leftMargin: 28; verticalCenter: parent.verticalCenter }
                                text: "⌕"; color: Theme.accent; font.pixelSize: 22
                            }
                            TextInput {
                                id: input
                                anchors { left: glyph.right; leftMargin: 12; right: parent.right; rightMargin: 24; verticalCenter: parent.verticalCenter }
                                color: Theme.text; font.pixelSize: 16
                                selectionColor: Theme.accent; selectedTextColor: Theme.accentText
                                clip: true
                                focus: true
                                Component.onCompleted: forceActiveFocus()
                                onTextChanged: { root.query = text; view.currentIndex = 0 }
                                Text { visible: input.text === ""; anchors.verticalCenter: parent.verticalCenter; text: "Buscar aplicativos…"; color: Theme.muted; font.pixelSize: 16 }

                                Keys.onEscapePressed: Settings.launcherOpen = false
                                Keys.onDownPressed: view.currentIndex = Math.min(view.count - 1, view.currentIndex + 1)
                                Keys.onUpPressed: view.currentIndex = Math.max(0, view.currentIndex - 1)
                                Keys.onTabPressed: view.currentIndex = (view.currentIndex + 1) % Math.max(1, view.count)
                                Keys.onReturnPressed: root.launch(root.list[view.currentIndex])
                                Keys.onEnterPressed: root.launch(root.list[view.currentIndex])
                                Keys.onPressed: e => {
                                    if (e.modifiers & Qt.ControlModifier) {
                                        if (e.key === Qt.Key_N || e.key === Qt.Key_J) { view.currentIndex = Math.min(view.count - 1, view.currentIndex + 1); e.accepted = true }
                                        else if (e.key === Qt.Key_P || e.key === Qt.Key_K) { view.currentIndex = Math.max(0, view.currentIndex - 1); e.accepted = true }
                                    }
                                }
                            }
                        }

                        // ---- resultados ----
                        ListView {
                            id: view
                            anchors { left: parent.left; right: parent.right; top: bar.bottom; bottom: parent.bottom; leftMargin: 10; rightMargin: 10; bottomMargin: 10 }
                            model: root.list
                            clip: true
                            interactive: false
                            currentIndex: 0
                            highlightMoveDuration: 90
                            boundsBehavior: Flickable.StopAtBounds
                            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                            WheelHandler {
                                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                onWheel: e => { view.contentY = Math.max(0, Math.min(Math.max(0, view.contentHeight - view.height), view.contentY - e.angleDelta.y)) }
                            }

                            delegate: Rectangle {
                                id: row
                                required property int index
                                required property var modelData
                                readonly property bool cur: ListView.isCurrentItem
                                width: ListView.view.width
                                height: root.rowH
                                radius: Math.max(8, Settings.launcherRadius - 8)
                                color: cur ? Theme.cardHi : "transparent"
                                Rectangle {
                                    visible: row.cur
                                    width: 3; height: parent.height * 0.5; radius: 2; color: Theme.accent
                                    anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                                }
                                Image {
                                    id: ico
                                    anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                                    width: Settings.launcherIcon; height: width
                                    sourceSize: Qt.size(width * 2, height * 2)
                                    source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                                    asynchronous: true
                                    smooth: true
                                }
                                Column {
                                    anchors { left: ico.right; leftMargin: 14; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                                    spacing: 1
                                    Text { width: parent.width; text: row.modelData.name; color: Theme.text; font.pixelSize: 15; font.weight: Font.Medium; elide: Text.ElideRight }
                                    Text {
                                        visible: text !== ""
                                        width: parent.width
                                        text: row.modelData.comment || row.modelData.genericName || ""
                                        color: Theme.muted; font.pixelSize: 12; elide: Text.ElideRight
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: view.currentIndex = row.index
                                    onClicked: root.launch(row.modelData)
                                }
                            }
                        }

                        Text {
                            visible: root.list.length === 0 && input.text !== ""
                            anchors { horizontalCenter: parent.horizontalCenter; top: bar.bottom; topMargin: 6 }
                            text: "Nada encontrado"; color: Theme.muted; font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }
}
