// Visao geral dos workspaces (inspirada no overview do end4): grade de workspaces na proporcao do monitor, com as
// janelas de cada um em miniatura ao vivo (ScreencopyView) e o icone do app. Clique numa janela: vai ate ela;
// clique no fundo de um workspace: vai para ele; arraste uma janela para outro workspace: ela muda de lugar.
// Esc ou clique fora fecha. Abrir: ipc overview toggle (ou a acao "Visão geral" no launcher).
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

Scope {
    id: root
    property bool open: false
    IpcHandler {
        target: "overview"
        function toggle(): void { root.open = !root.open }
        function open(): void { root.open = true }
        function close(): void { root.open = false }
    }
    onOpenChanged: if (open) { Hyprland.refreshToplevels(); Hyprland.refreshWorkspaces() }
    function hypr(lua) { Quickshell.execDetached(["hyprctl", "eval", "hl.dispatch(" + lua + ")"]) }
    function goWs(id) { hypr('hl.dsp.focus({ workspace = ' + id + ' })'); open = false }
    function goWin(addr) { hypr('hl.dsp.focus({ window = "address:' + addr + '" })'); open = false }
    function moveWin(addr, ws) { hypr('hl.dsp.window.move({ workspace = ' + ws + ', window = "address:' + addr + '" })'); Qt.callLater(Hyprland.refreshToplevels) }

    LazyLoader {
        active: root.open

        PanelWindow {
            id: win
            anchors { left: true; right: true; top: true; bottom: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "mine-overview"
            property real k: 0
            Component.onCompleted: k = 1
            Behavior on k { MotionAnim { use: "home" } }

            readonly property var mon: Hyprland.focusedMonitor
            readonly property real mw: mon && mon.width ? mon.width : width
            readonly property real mh: mon && mon.height ? mon.height : height
            readonly property int cols: Settings.overviewCols
            readonly property int rows: Settings.overviewRows
            readonly property real gap: 16
            readonly property real cardW: Math.min((width * 0.9 - (cols - 1) * gap) / cols, ((height * 0.82 - (rows - 1) * gap) / rows) * mw / mh)
            readonly property real cardH: cardW * mh / mw
            readonly property real sc: cardW / mw
            readonly property int activeWs: mon && mon.activeWorkspace ? mon.activeWorkspace.id : 1
            readonly property int base: Math.floor((activeWs - 1) / (cols * rows)) * cols * rows   // pagina de workspaces que contem o atual
            readonly property var wins: Hyprland.toplevels.values.filter(t => t.lastIpcObject && t.lastIpcObject.workspace && t.lastIpcObject.mapped !== false)
            property string dragAddr: ""
            property int dropWs: -1

            Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.45 * Math.min(1, win.k)) }
            MouseArea { anchors.fill: parent; onClicked: root.open = false }
            Item {
                focus: true
                Keys.onEscapePressed: root.open = false
                Keys.onPressed: e => { const n = e.key - Qt.Key_1; if (n >= 0 && n < 9) { root.goWs(win.base + n + 1); e.accepted = true } }
            }

            Grid {
                id: grid
                anchors.centerIn: parent
                columns: win.cols
                spacing: win.gap
                scale: 0.92 + 0.08 * Math.min(1, win.k)
                opacity: Math.min(1, win.k * 1.5)
                Repeater {
                    model: win.cols * win.rows
                    delegate: Rectangle {
                        id: ws
                        required property int index
                        readonly property int wsId: win.base + index + 1
                        readonly property bool cur: wsId === win.activeWs
                        readonly property var mine: win.wins.filter(t => t.lastIpcObject.workspace.id === wsId)
                        width: win.cardW; height: win.cardH
                        radius: 14
                        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.82)
                        border.width: cur || win.dropWs === wsId ? 2 : 1
                        border.color: win.dropWs === wsId ? Theme.accent : cur ? Theme.tint(0.8) : Theme.border
                        clip: true
                        // wallpaper de fundo de cada workspace
                        RoundImage {
                            anchors.fill: parent; anchors.margins: 1; radius: 13
                            source: Wallpaper.current !== "" ? Wallpaper.stillUrl(Wallpaper.current) : ""
                            sourceSize: Qt.size(320, 180)
                            dim: 0.35
                            opacity: 0.85
                        }
                        UiText { anchors { left: parent.left; top: parent.top; margins: 8 } text: ws.wsId; color: ws.cur ? Theme.accent : Qt.rgba(1, 1, 1, 0.7); font.pixelSize: 13; font.weight: Font.Bold; z: 5 }
                        MouseArea { anchors.fill: parent; onClicked: root.goWs(ws.wsId) }
                        Repeater {
                            model: ws.mine
                            delegate: Rectangle {
                                id: wr
                                required property var modelData
                                readonly property var o: modelData.lastIpcObject
                                readonly property real ox: ((o.at ? o.at[0] : 0) - (win.mon ? win.mon.x : 0)) * win.sc
                                readonly property real oy: ((o.at ? o.at[1] : 0) - (win.mon ? win.mon.y : 0)) * win.sc
                                x: ox; y: oy   // arrastar quebra a ligacao; ao soltar ela volta
                                width: Math.max(20, (o.size ? o.size[0] : 100) * win.sc); height: Math.max(14, (o.size ? o.size[1] : 60) * win.sc)
                                radius: 6
                                color: Theme.card
                                border.width: wm.containsMouse ? 2 : 1; border.color: wm.containsMouse ? Theme.accent : Qt.rgba(1, 1, 1, 0.18)
                                clip: true
                                z: dm.drag.active ? 100 : 1
                                ScreencopyView {
                                    anchors.fill: parent; anchors.margins: 1
                                    captureSource: wr.modelData.wayland ?? null
                                    live: true
                                }
                                Image {
                                    anchors.centerIn: parent
                                    width: Math.min(36, parent.width * 0.4, parent.height * 0.6); height: width
                                    source: Icons.app(wr.o.class || "")
                                    sourceSize: Qt.size(72, 72)
                                    opacity: 0.9
                                }
                                MouseArea {
                                    id: dm
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    drag.target: wr
                                    cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                    onPressed: win.dragAddr = wr.o.address
                                    onPositionChanged: if (drag.active) { const p = mapToItem(grid, mouseX, mouseY); const c = Math.floor(p.x / (win.cardW + win.gap)), r = Math.floor(p.y / (win.cardH + win.gap)); win.dropWs = c >= 0 && c < win.cols && r >= 0 && r < win.rows ? win.base + r * win.cols + c + 1 : -1 }
                                    onReleased: {
                                        if (drag.active || win.dropWs > 0) { if (win.dropWs > 0 && win.dropWs !== ws.wsId) root.moveWin(wr.o.address, win.dropWs); wr.x = Qt.binding(() => wr.ox); wr.y = Qt.binding(() => wr.oy) }
                                        win.dropWs = -1; win.dragAddr = ""
                                    }
                                    onClicked: root.goWin(wr.o.address)
                                }
                                HoverHandler { id: wm }
                            }
                        }
                    }
                }
            }
            UiText {
                anchors { horizontalCenter: parent.horizontalCenter; top: grid.bottom; topMargin: 18 }
                opacity: Math.min(1, win.k)
                text: "Clique para ir · arraste uma janela para outro workspace · 1–9 escolhem · Esc fecha"
                color: Qt.rgba(1, 1, 1, 0.75); font.pixelSize: 12
            }
        }
    }
}
