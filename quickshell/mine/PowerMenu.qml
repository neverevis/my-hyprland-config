// Menu de energia: tela cheia com fundo escurecido (e desfocado pelo Hyprland), foto, saudacao e as acoes.
// Teclado: setas/Tab escolhem, Enter confirma, letras (B S L R D) vao direto, Esc fecha.
// Sair/Reiniciar/Desligar pedem confirmacao: contagem de 3 s (clique de novo = agora; Esc ou clique fora = cancela).
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: root
    readonly property bool open: Power.menuOpen
    property bool alive: false
    onOpenChanged: {
        if (open) { closeTimer.stop(); Settings.launcherOpen = false; Settings.wpPickerOpen = false; Settings.homeOpen = false; alive = true }
        else closeTimer.restart()
    }
    Timer { id: closeTimer; interval: Settings.animOf("power").duration + 120; onTriggered: root.alive = false }

    LazyLoader {
        active: root.alive

        PanelWindow {
            id: win
            anchors { left: true; right: true; top: true; bottom: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.namespace: "mine-power"   // regras do Hyprland: blur na tela toda, sem animacao propria (a animacao e daqui)
            mask: Region { item: root.open ? catcher : null }

            readonly property var anim: Settings.animOf("power")
            property real p: 0   // 0 = fechado, 1 = aberto (segue a curva escolhida em Animacoes)
            Component.onCompleted: p = Qt.binding(() => root.open ? 1 : 0)
            Behavior on p { NumberAnimation { duration: win.anim.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: win.anim.curve } }

            property int sel: 0
            property string pending: ""     // acao esperando a contagem
            property real count: 0          // 0..1 da contagem
            onVisibleChanged: if (!visible) pending = ""
            Connections { target: root; function onOpenChanged() { if (!root.open) win.pending = ""; else win.sel = 0 } }

            function act(i) {
                const a = Power.actions[i]
                sel = i
                if (!a.confirm) { pending = ""; Power.run(a.id); return }
                if (pending === a.id) { pending = ""; Power.run(a.id); return }   // segundo clique: agora
                pending = a.id
                countAnim.restart()
            }
            NumberAnimation {
                id: countAnim
                target: win; property: "count"; from: 0; to: 1; duration: 3000
                onFinished: if (win.pending !== "") { const id = win.pending; win.pending = ""; Power.run(id) }
            }
            onPendingChanged: if (pending === "") { countAnim.stop(); count = 0 }

            // tempo ligado
            FileView { id: upf; path: "/proc/uptime" }
            Timer { interval: 30000; running: root.open; repeat: true; triggeredOnStart: true; onTriggered: upf.reload() }
            readonly property string uptime: {
                const s = parseFloat(upf.text().split(" ")[0]) || 0
                const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60)
                return h > 0 ? h + " h " + m + " min" : m + " min"
            }
            SystemClock { id: clk; precision: SystemClock.Minutes }
            readonly property string greet: { const h = clk.date.getHours(); return h < 5 ? "Boa noite" : h < 12 ? "Bom dia" : h < 18 ? "Boa tarde" : "Boa noite" }

            // fundo: escurece (o blur vem do Hyprland); clique fora fecha (ou cancela a contagem)
            Rectangle {
                id: catcher
                anchors.fill: parent
                color: "black"
                opacity: 0.5 * Math.min(1, win.p)
                MouseArea { anchors.fill: parent; onClicked: { if (win.pending !== "") win.pending = ""; else Power.menuOpen = false } }
            }

            Item {
                id: stage
                anchors.fill: parent
                focus: true
                Keys.onPressed: e => {
                    const n = Power.actions.length
                    if (e.key === Qt.Key_Escape) { if (win.pending !== "") win.pending = ""; else Power.menuOpen = false }
                    else if (e.key === Qt.Key_Left || e.key === Qt.Key_Backtab || (e.key === Qt.Key_Tab && (e.modifiers & Qt.ShiftModifier))) { win.pending = ""; win.sel = (win.sel + n - 1) % n }
                    else if (e.key === Qt.Key_Right || e.key === Qt.Key_Tab) { win.pending = ""; win.sel = (win.sel + 1) % n }
                    else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) win.act(win.sel)
                    else {
                        const i = Power.actions.findIndex(a => a.key === e.text.toUpperCase())
                        if (i >= 0) win.act(i); else return
                    }
                    e.accepted = true
                }

                Column {
                    id: col
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: (1 - win.p) * 40
                    opacity: Math.max(0, Math.min(1, win.p * 1.5))
                    spacing: 34

                    // foto + saudacao
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 12
                        Avatar {
                            anchors.horizontalCenter: parent.horizontalCenter
                            size: 104; ring: 3
                            scale: 0.85 + 0.15 * win.p
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: win.greet + ", " + Profile.name
                            color: "white"; font.pixelSize: 26; font.weight: Font.Bold
                        }
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 6
                            UiIcon { name: "clock"; size: 14; color: Qt.rgba(1, 1, 1, 0.7); anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Ligado há " + win.uptime; color: Qt.rgba(1, 1, 1, 0.7); font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }

                    // acoes
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 14
                        Repeater {
                            model: Power.actions
                            delegate: Item {
                                id: cell
                                required property var modelData
                                required property int index
                                readonly property bool cur: win.sel === index
                                readonly property bool waiting: win.pending === modelData.id
                                readonly property bool danger: modelData.id === "poweroff"
                                readonly property color tone: danger ? Theme.danger : Theme.accent
                                width: 124; height: 140

                                // entrada em cascata: cada botao entra um pouco depois do anterior, com a mesma curva
                                property real k: 0
                                Behavior on k { NumberAnimation { duration: win.anim.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: win.anim.curve } }
                                Timer { interval: 40 + cell.index * 45; running: root.open; onTriggered: cell.k = 1 }
                                Connections { target: root; function onOpenChanged() { if (!root.open) cell.k = 0 } }

                                Rectangle {
                                    id: card
                                    width: parent.width; height: parent.height
                                    y: (1 - cell.k) * 36 - (cm.containsMouse || cell.cur ? 4 : 0)
                                    opacity: Math.max(0, Math.min(1, cell.k * 1.6))
                                    scale: (cm.pressed ? 0.96 : 1) * (0.9 + 0.1 * cell.k)
                                    Behavior on y { enabled: cell.k >= 1; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                    radius: 26
                                    color: cell.waiting ? Qt.rgba(cell.tone.r, cell.tone.g, cell.tone.b, 0.28)
                                        : (cell.cur || cm.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.07))
                                    border.width: cell.cur || cell.waiting ? 2 : 1
                                    border.color: cell.cur || cell.waiting ? cell.tone : Qt.rgba(1, 1, 1, 0.12)
                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    // icone (com o anel da contagem em volta)
                                    Item {
                                        id: ic
                                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 20 }
                                        width: 60; height: 60
                                        Rectangle {
                                            anchors.fill: parent; radius: 30
                                            color: cell.cur || cm.containsMouse || cell.waiting ? cell.tone : Qt.rgba(1, 1, 1, 0.1)
                                            Behavior on color { ColorAnimation { duration: 140 } }
                                        }
                                        UiIcon {
                                            anchors.centerIn: parent
                                            name: cell.modelData.icon; size: 28
                                            color: cell.cur || cm.containsMouse || cell.waiting ? Theme.accentText : "white"
                                        }
                                        Canvas {
                                            id: ringC
                                            anchors.fill: parent; anchors.margins: -6
                                            visible: cell.waiting
                                            readonly property real v: cell.waiting ? win.count : 0
                                            onVChanged: requestPaint()
                                            onPaint: {
                                                const c = getContext("2d"); c.reset()
                                                c.lineWidth = 3; c.lineCap = "round"
                                                c.strokeStyle = Qt.rgba(1, 1, 1, 0.18)
                                                c.beginPath(); c.arc(width / 2, height / 2, width / 2 - 2, 0, Math.PI * 2); c.stroke()
                                                c.strokeStyle = cell.tone
                                                c.beginPath(); c.arc(width / 2, height / 2, width / 2 - 2, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * (1 - v)); c.stroke()
                                            }
                                        }
                                    }
                                    Text {
                                        anchors { horizontalCenter: parent.horizontalCenter; top: ic.bottom; topMargin: 12 }
                                        text: cell.waiting ? Math.max(1, Math.ceil(3 - win.count * 3)) + " s" : cell.modelData.label
                                        color: "white"; font.pixelSize: 14; font.weight: Font.DemiBold
                                    }
                                    Rectangle {   // atalho de teclado
                                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 10 }
                                        width: 20; height: 18; radius: 5
                                        color: Qt.rgba(1, 1, 1, 0.08)
                                        Text { anchors.centerIn: parent; text: cell.modelData.key; color: Qt.rgba(1, 1, 1, 0.55); font.pixelSize: 10; font.weight: Font.Bold }
                                    }
                                    MouseArea {
                                        id: cm
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: if (win.pending === "") win.sel = cell.index
                                        onClicked: win.act(cell.index)
                                    }
                                }
                            }
                        }
                    }

                    // dica / confirmacao
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        readonly property var pa: Power.actions.find(a => a.id === win.pending)
                        text: pa ? pa.verb + "… clique de novo para agora · Esc cancela" : "← → escolhe · Enter confirma · Esc fecha"
                        color: pa ? "white" : Qt.rgba(1, 1, 1, 0.5)
                        font.pixelSize: 13
                    }
                }
            }
        }
    }
}
