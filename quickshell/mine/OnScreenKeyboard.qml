// Teclado na tela (layout ABNT2 pt-BR ou US) preso na borda de baixo. As teclas saem por ydotool (Ydotool.qml); a janela
// nao toma o foco do teclado, entao o que voce digita vai para o app que estava em uso.
// Shift: um toque vale para a proxima tecla, dois toques seguidos travam (caps). Ctrl/Alt/Win/AltGr ficam armados ate a proxima tecla.
// IPC: qs -c mine ipc call osk toggle | open | close
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "oskLayouts.js" as Lay

Scope {
    id: root
    property bool open: false
    property bool alive: false
    onOpenChanged: {
        if (open) { closeT.stop(); alive = true; Ydotool.check() }
        else { Ydotool.releaseAll(); closeT.restart() }
    }
    Timer { id: closeT; interval: 320; onTriggered: root.alive = false }
    Component.onCompleted: if (Settings.oskPinned) open = true
    IpcHandler {
        target: "osk"
        function toggle(): void { root.open = !root.open }
        function open(): void { root.open = true }
        function close(): void { root.open = false }
    }

    LazyLoader {
        active: root.alive

        PanelWindow {
            id: win
            anchors { left: true; right: true; bottom: true }
            implicitHeight: bg.height + 24
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "mine-osk"
            exclusionMode: Settings.oskPinned ? ExclusionMode.Auto : ExclusionMode.Ignore
            exclusiveZone: Settings.oskPinned ? bg.height + 24 : 0
            mask: Region { item: bg }

            property int shiftMode: 0     // 0 solto, 1 uma tecla, 2 travado
            property var mods: []         // modificadores armados (codigos)
            property real lastShift: 0
            readonly property bool upper: shiftMode > 0
            property real k: 0
            Component.onCompleted: k = 1
            Connections { target: root; function onOpenChanged() { win.k = root.open ? 1 : 0 } }
            Behavior on k { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

            function press(key) {
                if (key.t === "shift") {
                    const now = Date.now()
                    if (shiftMode === 2) shiftMode = 0
                    else if (shiftMode === 1 && now - lastShift < 450) shiftMode = 2
                    else shiftMode = shiftMode === 1 ? 0 : 1
                    lastShift = now
                    return
                }
                if (key.t === "caps") { shiftMode = shiftMode === 2 ? 0 : 2; return }
                if (key.t === "mod") {
                    const i = mods.indexOf(key.c)
                    const m = mods.slice(); if (i >= 0) m.splice(i, 1); else m.push(key.c)
                    mods = m
                    return
                }
                const m = mods.slice()
                if (upper) m.unshift(42)
                Ydotool.tap(key.c, m)
                mods = []
                if (shiftMode === 1) shiftMode = 0
            }

            Rectangle {
                id: bg
                anchors.horizontalCenter: parent.horizontalCenter
                y: win.height - height - 12 + (1 - win.k) * (height + 20)
                width: Math.min(parent.width - 24, 1180)
                height: col.implicitHeight + 28 + (Ydotool.ready ? 0 : 30)
                radius: 22
                color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.96)
                border.width: 1; border.color: Theme.border
                opacity: Math.min(1, win.k * 2)

                Column {
                    id: col
                    x: 14; y: 14; width: parent.width - 28
                    spacing: 6
                    // aviso quando o daemon do ydotool nao esta rodando
                    Rectangle {
                        visible: !Ydotool.ready
                        width: parent.width; height: 24; radius: 12
                        color: Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.25)
                        UiText { anchors.centerIn: parent; text: "O ydotoold não está rodando: as teclas não serão enviadas (systemctl --user enable --now ydotool)"; color: Theme.text; font.pixelSize: 11 }
                    }
                    // barra: layout, fixar, fechar
                    Item {
                        width: parent.width; height: 26
                        UiIcon { name: "keyboard"; size: 16; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                        Row {
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            spacing: 6
                            Repeater {
                                model: Lay.names()
                                delegate: Rectangle {
                                    required property var modelData
                                    height: 24; width: lt.implicitWidth + 16; radius: 12
                                    color: Settings.oskLayout === modelData[0] ? Theme.accent : Theme.track
                                    UiText { id: lt; anchors.centerIn: parent; text: modelData[1]; font.pixelSize: 11; color: Settings.oskLayout === modelData[0] ? Theme.accentText : Theme.text }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings.oskLayout = modelData[0] }
                                }
                            }
                            Rectangle { height: 24; width: 24; radius: 12; color: Settings.oskPinned ? Theme.tint(0.3) : Theme.track
                                UiIcon { anchors.centerIn: parent; name: Settings.oskPinned ? "pin" : "pinOff"; size: 13; color: Settings.oskPinned ? Theme.accent : Theme.muted }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings.oskPinned = !Settings.oskPinned } }
                            Rectangle { height: 24; width: 24; radius: 12; color: Theme.track
                                UiIcon { anchors.centerIn: parent; name: "keyboardClose"; size: 14; color: Theme.muted }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.open = false } }
                        }
                    }
                    Repeater {
                        model: Lay.get(Settings.oskLayout)
                        delegate: Row {
                            id: kr
                            required property var modelData
                            required property int index
                            spacing: 5
                            readonly property var keys: Array.from(modelData)
                            readonly property real tot: keys.reduce((a, x) => a + x.w, 0)
                            readonly property real unit: (col.width - (keys.length - 1) * spacing) / tot
                            Repeater {
                                model: kr.keys
                                delegate: Rectangle {
                                    id: key
                                    required property var modelData
                                    readonly property bool armed: (modelData.t === "mod" && win.mods.indexOf(modelData.c) >= 0) || (modelData.t === "shift" && win.shiftMode > 0) || (modelData.t === "caps" && win.shiftMode === 2)
                                    width: modelData.w * kr.unit; height: kr.index === 0 ? 30 : 44
                                    radius: 10
                                    color: armed ? Theme.accent : (km.pressed ? Theme.tint(0.3) : (km.containsMouse ? Theme.cardHi : Theme.track))
                                    border.width: 1; border.color: Theme.border
                                    UiIcon { visible: key.modelData.ic !== ""; anchors.centerIn: parent; name: key.modelData.ic; size: 18; color: key.armed ? Theme.accentText : Theme.text }
                                    UiText {
                                        visible: key.modelData.ic === ""
                                        anchors.centerIn: parent
                                        text: win.upper ? key.modelData.s : key.modelData.l
                                        color: key.armed ? Theme.accentText : Theme.text
                                        font.pixelSize: key.modelData.l.length > 1 ? 11 : 16
                                    }
                                    MouseArea { id: km; anchors.fill: parent; hoverEnabled: true; onClicked: win.press(key.modelData) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
