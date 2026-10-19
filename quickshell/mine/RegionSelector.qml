// Seletor de area do shell (Capture.qml): a tela congelada, escurecida fora da selecao. Arrastar escolhe uma area
// (retangulo ou circulo); clicar numa janela escolhe a janela inteira (ela acende ao passar o mouse); linhas-guia
// acompanham o cursor. Embaixo: a acao (Copiar, Texto, Traduzir, Anotar, Buscar, Gravar), a forma e "Tela inteira".
// Teclas: 1-6 trocam a acao, C alterna circulo, Enter/Espaco = tela inteira, Esc cancela.
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

Scope {
    LazyLoader {
        active: Capture.open

        PanelWindow {
            id: win
            anchors { left: true; right: true; top: true; bottom: true }
            color: "black"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "mine-region"

            readonly property var mon: Hyprland.focusedMonitor
            property point a: Qt.point(-1, -1)
            property point b: Qt.point(-1, -1)
            property bool dragging: false
            property real mx: -1
            property real my: -1
            readonly property rect sel: dragging || (a.x >= 0 && b.x >= 0) ? Qt.rect(Math.min(a.x, b.x), Math.min(a.y, b.y), Math.abs(b.x - a.x), Math.abs(b.y - a.y)) : Qt.rect(0, 0, 0, 0)
            readonly property bool hasSel: sel.width > 6 && sel.height > 6
            // janela sob o cursor (do workspace atual)
            readonly property var winRect: {
                if (dragging || mx < 0 || !mon) return null
                const ws = mon.activeWorkspace ? mon.activeWorkspace.id : -1
                let best = null
                for (const t of Hyprland.toplevels.values) {
                    const o = t.lastIpcObject
                    if (!o || !o.at || !o.workspace || o.workspace.id !== ws) continue
                    const x = o.at[0] - mon.x, y = o.at[1] - mon.y
                    if (mx >= x && mx <= x + o.size[0] && my >= y && my <= y + o.size[1]) {
                        const r = Qt.rect(x, y, o.size[0], o.size[1])
                        if (!best || (o.floating && !best.f)) best = { r: r, f: !!o.floating }
                    }
                }
                return best ? best.r : null
            }
            readonly property rect shown: hasSel ? sel : (winRect ?? Qt.rect(0, 0, 0, 0))
            readonly property bool any: shown.width > 0
            property real k: 0
            Component.onCompleted: k = 1
            Behavior on k { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            Image {
                anchors.fill: parent
                source: Capture.frozen !== "" ? "file://" + Capture.frozen + "?" + Date.now() : ""
                cache: false
                smooth: true
            }
            // escuro fora da selecao (4 faixas)
            readonly property color dimC: Qt.rgba(0, 0, 0, 0.45 * k)
            Rectangle { x: 0; y: 0; width: parent.width; height: win.any ? win.shown.y : parent.height; color: win.dimC }
            Rectangle { visible: win.any; x: 0; y: win.shown.y + win.shown.height; width: parent.width; height: parent.height - y; color: win.dimC }
            Rectangle { visible: win.any; x: 0; y: win.shown.y; width: win.shown.x; height: win.shown.height; color: win.dimC }
            Rectangle { visible: win.any; x: win.shown.x + win.shown.width; y: win.shown.y; width: parent.width - x; height: win.shown.height; color: win.dimC }
            // contorno (retangulo ou circulo)
            Rectangle {
                visible: win.any
                x: win.shown.x; y: win.shown.y; width: win.shown.width; height: win.shown.height
                color: "transparent"
                radius: Capture.shape === "circle" && win.hasSel ? Math.min(width, height) / 2 : 6
                border.width: 2; border.color: Theme.accent
                Rectangle {
                    visible: win.hasSel
                    anchors { left: parent.left; bottom: parent.top; bottomMargin: 6 }
                    width: szT.implicitWidth + 12; height: 22; radius: 7; color: Theme.accent
                    UiText { id: szT; anchors.centerIn: parent; text: Math.round(win.sel.width) + " × " + Math.round(win.sel.height); color: Theme.accentText; font.pixelSize: 11; font.weight: Font.Bold }
                }
            }
            // linhas-guia
            Rectangle { visible: !win.dragging && win.mx >= 0; x: win.mx; y: 0; width: 1; height: parent.height; color: Qt.rgba(1, 1, 1, 0.35) }
            Rectangle { visible: !win.dragging && win.mx >= 0; x: 0; y: win.my; width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.35) }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.CrossCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onPositionChanged: m => { win.mx = m.x; win.my = m.y; if (win.dragging) win.b = Qt.point(m.x, m.y) }
                onPressed: m => { if (m.button === Qt.RightButton) { Capture.close(); return } win.a = Qt.point(m.x, m.y); win.b = win.a; win.dragging = true }
                onReleased: m => {
                    if (!win.dragging) return
                    win.dragging = false
                    win.b = Qt.point(m.x, m.y)
                    if (win.hasSel) Capture.run(win.sel.x, win.sel.y, win.sel.width, win.sel.height)
                    else if (win.winRect) { const r = win.winRect; Capture.run(r.x, r.y, r.width, r.height) }
                    else { win.a = Qt.point(-1, -1); win.b = win.a }
                }
            }

            // ---- barra de acoes ----
            Rectangle {
                id: bar
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 40 - (1 - win.k) * 30 }
                width: barRow.implicitWidth + 16; height: 52; radius: 26
                color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.94)
                border.width: 1; border.color: Theme.border
                opacity: win.k
                HoverHandler { id: barHover }
                Row {
                    id: barRow
                    anchors.centerIn: parent
                    spacing: 4
                    Repeater {
                        model: Capture.actions
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool on: Capture.action === modelData.id
                            height: 38; width: ar.implicitWidth + 22; radius: 19
                            color: on ? Theme.accent : (am.containsMouse ? Theme.cardHi : "transparent")
                            Row {
                                id: ar
                                anchors.centerIn: parent
                                spacing: 6
                                UiIcon { name: modelData.icon; size: 15; color: parent.parent.on ? Theme.accentText : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                                UiText { text: modelData.label; color: parent.parent.on ? Theme.accentText : Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Capture.action = modelData.id }
                        }
                    }
                    Rectangle { width: 1; height: 26; color: Theme.border; anchors.verticalCenter: parent.verticalCenter }
                    Rectangle {
                        height: 38; width: 38; radius: 19
                        color: Capture.shape === "circle" ? Theme.tint(0.2) : (cm.containsMouse ? Theme.cardHi : "transparent")
                        UiIcon { anchors.centerIn: parent; name: Capture.shape === "circle" ? "target" : "frame"; size: 16; color: Theme.text }
                        MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Capture.shape = Capture.shape === "circle" ? "rect" : "circle" }
                    }
                    Rectangle {
                        height: 38; width: fr.implicitWidth + 22; radius: 19
                        color: fm.containsMouse ? Theme.cardHi : "transparent"
                        Row { id: fr; anchors.centerIn: parent; spacing: 6
                            UiIcon { name: "fullscreen"; size: 15; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
                            UiText { text: "Tela inteira"; color: Theme.text; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter } }
                        MouseArea { id: fm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Capture.run(0, 0, win.width, win.height) }
                    }
                }
            }
            UiText {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: bar.top; bottomMargin: 10 }
                opacity: win.k * 0.9
                text: (Capture.actions.find(x => x.id === Capture.action) ?? {}).hint + "  ·  arraste uma área ou clique numa janela  ·  Esc cancela"
                color: "white"; font.pixelSize: 12
                style: Text.Outline; styleColor: Qt.rgba(0, 0, 0, 0.6)
            }

            Item {
                focus: true
                Keys.onEscapePressed: Capture.close()
                Keys.onPressed: e => {
                    const n = e.key - Qt.Key_1
                    if (n >= 0 && n < Capture.actions.length) { Capture.action = Capture.actions[n].id; e.accepted = true }
                    else if (e.key === Qt.Key_C) { Capture.shape = Capture.shape === "circle" ? "rect" : "circle"; e.accepted = true }
                    else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) { Capture.run(0, 0, win.width, win.height); e.accepted = true }
                }
            }
        }
    }
}
