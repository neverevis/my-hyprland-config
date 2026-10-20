// Barra lateral esquerda: abas na lateral (IA, Tradutor, Midia). Painel flutuante colado na borda esquerda.
// Ctrl+O alarga/estreita, Ctrl+PgUp/PgDn troca de aba, Esc fecha.
// IPC:  qs -c mine ipc call left toggle | open | close | go <aba> | ask <palavra>
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick

Scope {
    id: root
    readonly property bool open: Settings.leftOpen
    property bool alive: false
    property string tab: "ai"
    property var geo: ({ left: null })        // resultado de Geometry.compute (vem do shell.qml)
    property alias wide: wideProxy.v
    QtObject { id: wideProxy; property bool v: BarState.leftWide; onVChanged: BarState.leftWide = v }

    readonly property var tabs: [
        { id: "ai", label: "Inteligência", icon: "robot" },
        { id: "tr", label: "Tradutor", icon: "translate" },
        { id: "media", label: "Mídia", icon: "music" }
    ]
    IpcHandler {
        target: "left"
        function toggle(): void { Settings.leftOpen = !Settings.leftOpen }
        function open(): void { Settings.leftOpen = true }
        function close(): void { Settings.leftOpen = false }
        function go(t: string): void { root.tab = t; Settings.leftOpen = true }
        function ask(t: string): void { root.tab = "ai"; Settings.leftOpen = true; Ai.send(t) }   // diagnostico (sem espacos)
        function state(): string { return JSON.stringify({ open: Settings.leftOpen, tab: root.tab, wide: root.wide, backend: Ai.backend, model: Ai.model, local: Ai.localState, blocker: Ai.blocker, msgs: Ai.msgs.count, busy: Ai.busy }) }
    }
    onOpenChanged: {
        if (open) { closeTimer.stop(); Settings.launcherOpen = false; Settings.wpPickerOpen = false; Settings.homeOpen = false; alive = true }
        else closeTimer.restart()
    }
    Timer { id: closeTimer; interval: Motion.durationOf("home", true) + 120; onTriggered: root.alive = false }

    function fmt(sec) { sec = Math.max(0, Math.floor(sec || 0)); return Math.floor(sec / 60) + ":" + ("0" + (sec % 60)).slice(-2) }
    // midia (a aba usa o mesmo HomeMedia do painel Inicio)
    readonly property var players: Players.list
    property int playerPick: -1
    readonly property var player: Players.pick(playerPick)

    LazyLoader {
        active: true

        PanelWindow {
            id: win
            mask: root.alive ? null : noInput
            Region { id: noInput }
            Component.onCompleted: contentItem.visible = Qt.binding(() => root.alive)
            Connections { target: root; function onAliveChanged() { if (root.alive) panel.forceActiveFocus() } }
            anchors { left: true; right: true; top: true; bottom: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.alive ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            WlrLayershell.namespace: "mine-left"

            // ---- geometria (mesmo esquema do Inicio; lado fixo: esquerda) ----
            readonly property bool docked: Settings.leftDocked
            readonly property real e: Settings.edge
            readonly property real cw: BarState.leftW
            readonly property real ch: Math.min(BarState.leftH, height - 140)
            property real fprog: root.open ? 1 : 0
            Behavior on fprog { id: fpB; MotionAnim { use: "home"; out: fpB.targetValue < 0.5 } }
            readonly property real pp: docked ? BarState.leftProg : fprog
            readonly property var pk: root.geo.left
            readonly property rect dbox: !pk ? Qt.rect(0, 0, 0, 0) : Qt.rect(pk.rect.x + e + 8, pk.rect.y + (pk.rect.h - ch) / 2, cw, ch)
            readonly property rect fbox: Qt.rect(e + 8, e + 8, Math.min(cw, width - 60), height - 2 * (e + 8))
            readonly property rect box: docked ? dbox : fbox
            readonly property real fullDepth: docked && pk ? pk.t : 0
            readonly property real vis: docked ? Math.max(0, e + (fullDepth - e) * pp) : 0
            readonly property rect clipR: !docked || !pk ? Qt.rect(0, 0, 0, 0) : Qt.rect(0, pk.rect.y, vis, pk.rect.h)
            readonly property real lag: docked ? fullDepth - vis : 0

            MouseArea { anchors.fill: parent; onClicked: Settings.leftOpen = false }

            Item {
                id: holder
                x: win.docked ? win.clipR.x : 0
                y: win.docked ? win.clipR.y : 0
                width: win.docked ? win.clipR.width : win.width
                height: win.docked ? win.clipR.height : win.height
                clip: win.docked
                MouseArea { anchors.fill: parent; visible: win.docked }

            Item {
                id: inner
                x: -holder.x - win.lag + (win.docked ? 0 : -(1 - win.pp) * 40)
                y: -holder.y
                width: win.width; height: win.height
                opacity: win.docked ? Math.max(0, Math.min(1, win.pp * 4)) : Math.max(0, Math.min(1, win.pp * 1.6))

            Rectangle {
                id: panel
                x: win.box.x; y: win.box.y
                width: win.box.width; height: win.box.height
                radius: win.docked ? 0 : Settings.homeRadius + 6
                color: win.docked ? "transparent" : Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, Settings.glass ? Math.min(1, Settings.glassOpacityEff / 100 + 0.08) : 1)
                border.width: win.docked ? 0 : 1; border.color: Theme.border
                focus: true
                Keys.onEscapePressed: Settings.leftOpen = false
                Keys.onPressed: ev => {
                    const i = root.tabs.findIndex(t => t.id === root.tab), n = root.tabs.length
                    if ((ev.modifiers & Qt.ControlModifier) && ev.key === Qt.Key_O) { root.wide = !root.wide; ev.accepted = true }
                    else if ((ev.modifiers & Qt.ControlModifier) && ev.key === Qt.Key_PageDown) { root.tab = root.tabs[(i + 1) % n].id; ev.accepted = true }
                    else if ((ev.modifiers & Qt.ControlModifier) && ev.key === Qt.Key_PageUp) { root.tab = root.tabs[(i + n - 1) % n].id; ev.accepted = true }
                }
                MouseArea { anchors.fill: parent }

                Rectangle {
                    id: rail
                    x: 12; y: 12; width: 56; height: parent.height - 24
                    radius: 16; color: Theme.glc(Theme.card, 1.15); border.width: 1; border.color: Theme.border
                    Column {
                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 7 }
                        spacing: 6
                        Repeater {
                            model: root.tabs
                            delegate: Rectangle {
                                id: rt
                                required property var modelData
                                readonly property bool on: root.tab === modelData.id
                                width: 42; height: 42; radius: 12
                                color: on ? Theme.accent : (rtm.containsMouse ? Theme.cardHi : "transparent")
                                Behavior on color { enabled: !ThemeColors.fading; ColorAnimation { duration: 140 } }
                                UiIcon { anchors.centerIn: parent; name: rt.modelData.icon; size: 20; color: rt.on ? Theme.accentText : (rtm.containsMouse ? Theme.text : Theme.muted) }
                                MouseArea { id: rtm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.tab = rt.modelData.id }
                            }
                        }
                    }
                    Rectangle {   // alargar / estreitar
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 7 }
                        width: 42; height: 42; radius: 12
                        color: wm.containsMouse ? Theme.cardHi : "transparent"
                        UiIcon { anchors.centerIn: parent; name: "swap_horizontal"; size: 20; color: root.wide ? Theme.accent : (wm.containsMouse ? Theme.text : Theme.muted) }
                        MouseArea { id: wm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.wide = !root.wide }
                    }
                }

                Item {
                    id: header
                    anchors { left: rail.right; leftMargin: 14; right: parent.right; rightMargin: 12; top: parent.top; topMargin: 12 }
                    height: 36
                    UiText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: (root.tabs.find(t => t.id === root.tab) ?? root.tabs[0]).label
                        color: Theme.text; font.pixelSize: 18; font.weight: Font.Bold
                    }
                    UiButton { anchors { right: parent.right; verticalCenter: parent.verticalCenter } icon: "close"; kind: "ghost"; onClicked: Settings.leftOpen = false }
                }

                Loader {
                    id: pageL
                    anchors { left: rail.right; leftMargin: 12; right: parent.right; rightMargin: 12; top: header.bottom; topMargin: 10; bottom: parent.bottom; bottomMargin: 12 }
                    sourceComponent: ({ ai: pAi, tr: pTr, media: pMedia })[root.tab] ?? pAi
                    opacity: 0
                    onLoaded: fadeIn.restart()
                    NumberAnimation { id: fadeIn; target: pageL; property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
                }
                Component { id: pAi; LeftAi { } }
                Component { id: pTr; LeftTranslator { } }
                Component { id: pMedia; HomeMedia { home: root } }
            }
            }
            }
        }
    }
}
