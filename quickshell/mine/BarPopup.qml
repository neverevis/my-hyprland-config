// Detalhes ao passar o mouse nos modulos da barra (BarState.pop): um cartao que nasce do lado da barra, perto do
// modulo. Relogio -> calendario do mes; clima -> agora e proximas horas; cpu/memoria/gpu/temperatura/rede -> sistema;
// musica -> capa e controles; volume -> saida, volume e microfone; privacidade -> quem usa o microfone/tela;
// atualizacoes -> quantas e o botao de atualizar. Reaproveita os widgets da area de trabalho.
// Animacao: "Detalhes ao passar o mouse" (pagina Animacoes). Desligar: pagina Barras (ou opcao popup de cada modulo).
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Hyprland
import QtQuick

Scope {
    id: root
    readonly property var pop: BarState.pop
    property var shown: null        // o que esta desenhado (fica durante a animacao de saida)
    property real k: 0
    Behavior on k { MotionAnim { use: "popups"; out: root.k > 0.5 && !root.pop } }
    onPopChanged: { if (pop) { shown = pop; k = 1 } else k = 0 }
    onKChanged: if (k <= 0.001 && !pop) shown = null

    LazyLoader {
        active: !!root.shown

        PanelWindow {
            id: win
            anchors { left: true; right: true; top: true; bottom: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "mine-popup"
            mask: Region { item: card }

            readonly property var p: root.shown
            readonly property string kind: p ? p.kind : ""
            readonly property string side: p ? p.side : "bottom"
            readonly property var r: p ? p.rect : ({ x: 0, y: 0, w: 0, h: 0 })
            readonly property size sz: ({ calendar: Qt.size(320, 330), weather: Qt.size(380, 250), system: Qt.size(360, 250), media: Qt.size(400, 210),
                                          volume: Qt.size(320, 170), privacy: Qt.size(300, 120), updates: Qt.size(300, 130),
                                          windows: Qt.size(Math.min(width - 40, Math.max(1, p && p.wins ? p.wins.length : 1) * 232 + 22), 196) })[kind] ?? Qt.size(300, 150)
            readonly property real gap: 12
            readonly property real cx: Math.max(12, Math.min(width - sz.width - 12, r.x + r.w / 2 - sz.width / 2))
            readonly property real cy: Math.max(12, Math.min(height - sz.height - 12, r.y + r.h / 2 - sz.height / 2))
            readonly property real tx: side === "left" ? r.x + r.w + gap : side === "right" ? r.x - sz.width - gap : cx
            readonly property real ty: side === "top" ? r.y + r.h + gap : side === "bottom" ? r.y - sz.height - gap : cy
            // nasce do lado da barra
            readonly property real off: (1 - root.k) * 14

            Rectangle {
                id: card
                x: win.tx + (win.side === "left" ? -win.off : win.side === "right" ? win.off : 0)
                y: win.ty + (win.side === "top" ? -win.off : win.side === "bottom" ? win.off : 0)
                width: win.sz.width; height: win.sz.height
                radius: 20
                color: Theme.gl(Theme.bg, 1.25)
                border.width: 1; border.color: Theme.border
                opacity: Math.min(1, root.k * 1.4)
                scale: 0.96 + 0.04 * Math.min(1, root.k)
                transformOrigin: win.side === "bottom" ? Item.Bottom : win.side === "top" ? Item.Top : win.side === "left" ? Item.Left : Item.Right
                HoverHandler { onHoveredChanged: BarState.popHover = hovered }
                Loader {
                    anchors { fill: parent; margins: 16 }
                    sourceComponent: ({ calendar: calC, weather: weatherC, system: sysC, media: mediaC, volume: volC, privacy: privC, updates: updC, windows: winsC })[win.kind] ?? null
                }
            }
        }
    }

    Component {
        id: calC
        Column {
            spacing: 8
            SystemClock { id: clk; precision: SystemClock.Seconds }
            UiText { text: Qt.formatDateTime(clk.date, Settings.clock24 ? "HH:mm:ss" : "h:mm:ss AP"); color: Theme.text; font.pixelSize: 26; font.weight: Font.Bold; font.features: { "tnum": 1 } }
            UiText { text: { const s = clk.date.toLocaleDateString(Qt.locale("pt_BR"), "dddd, d 'de' MMMM 'de' yyyy"); return s.charAt(0).toUpperCase() + s.slice(1) } color: Theme.muted; font.pixelSize: 12 }
            DwCalendar { width: parent.width; height: 230; cols: 2; rows: 2; opts: ({}) }
        }
    }
    Component { id: weatherC; DwWeather { cols: 3; rows: 2; opts: ({}) } }
    Component { id: sysC; DwSystem { cols: 3; rows: 2; opts: ({ look: "bars" }) } }
    Component { id: mediaC; DwMedia { cols: 3; rows: 2; opts: ({}) } }
    Component {
        id: volC
        Column {
            id: volCol
            spacing: 12
            readonly property var sink: Pipewire.defaultAudioSink
            readonly property var src: Pipewire.defaultAudioSource
            PwObjectTracker { objects: [volCol.sink, volCol.src] }
            Row {
                spacing: 10
                UiIcon { name: "speaker"; size: 18; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                UiText { width: 240; elide: Text.ElideRight; text: parent.parent.sink ? (parent.parent.sink.description || parent.parent.sink.nickname || parent.parent.sink.name) : "Sem saída"; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
            }
            UiSlider {
                label: "Volume"; from: 0; to: 100; suffix: " %"
                value: parent.sink && parent.sink.audio ? Math.round(parent.sink.audio.volume * 100) : 0
                onMoved: v => { if (parent.sink && parent.sink.audio) parent.sink.audio.volume = v / 100 }
            }
            Row {
                spacing: 8
                UiButton { icon: Osd.muted ? "volumeOff" : "volume"; text: Osd.muted ? "Sem som" : "Som"; kind: Osd.muted ? "accent" : "ghost"; onClicked: if (parent.parent.sink && parent.parent.sink.audio) parent.parent.sink.audio.muted = !parent.parent.sink.audio.muted }
                UiButton { icon: Osd.micMuted ? "micOff" : "mic"; text: Osd.micMuted ? "Microfone mudo" : "Microfone"; kind: Osd.micMuted ? "accent" : "ghost"; onClicked: if (parent.parent.src && parent.parent.src.audio) parent.parent.src.audio.muted = !parent.parent.src.audio.muted }
            }
        }
    }
    Component {
        id: privC
        Column {
            id: privCol
            spacing: 8
            readonly property var streams: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioInStream || n.type === PwNodeType.VideoSource)
            PwObjectTracker { objects: privCol.streams }
            function appOf(n) { const p = n.properties || {}; return p["application.name"] || p["node.name"] || n.name || "?" }
            UiText { text: "Em uso agora"; color: Theme.text; font.pixelSize: 14; font.weight: Font.Bold }
            Repeater {
                model: parent.streams.filter(n => !/cava|quickshell|pavucontrol|peak|monitor/i.test(parent.appOf(n)))
                delegate: Row {
                    required property var modelData
                    spacing: 8
                    UiIcon { name: modelData.type === PwNodeType.VideoSource ? "monitor" : "mic"; size: 15; color: Theme.danger }
                    UiText { text: parent.parent.appOf(modelData); color: Theme.text; font.pixelSize: 12 }
                }
            }
        }
    }
    // miniaturas das janelas de um app do dock (ao vivo); clique foca, X fecha
    Component {
        id: winsC
        Row {
            spacing: 12
            Repeater {
                model: root.shown && root.shown.wins ? root.shown.wins : []
                delegate: Column {
                    id: wc
                    required property var modelData
                    spacing: 6
                    readonly property var o: modelData.lastIpcObject || {}
                    Row {
                        spacing: 6
                        width: 220
                        UiText { width: 190; elide: Text.ElideRight; text: wc.modelData.title || root.shown.title; color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold }
                        Rectangle {
                            width: 20; height: 20; radius: 10; color: xm.containsMouse ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.25) : "transparent"
                            UiIcon { anchors.centerIn: parent; name: "close"; size: 12; color: xm.containsMouse ? Theme.danger : Theme.muted }
                            MouseArea { id: xm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { Quickshell.execDetached(["hyprctl", "eval", 'hl.dispatch(hl.dsp.window.close({ window = "address:' + wc.o.address + '" }))']); BarState.pop = null } }
                        }
                    }
                    Rectangle {
                        width: 220; height: 140; radius: 12; color: Theme.card; clip: true
                        border.width: tm.containsMouse ? 2 : 1; border.color: tm.containsMouse ? Theme.accent : Theme.border
                        ScreencopyView {
                            anchors.fill: parent; anchors.margins: 2
                            captureSource: wc.modelData.wayland ?? null
                            live: true
                        }
                        MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { Quickshell.execDetached(["hyprctl", "eval", 'hl.dispatch(hl.dsp.focus({ window = "address:' + wc.o.address + '" }))']); BarState.pop = null } }
                    }
                }
            }
        }
    }
    Component {
        id: updC
        Column {
            spacing: 10
            UiText { text: "Atualizações do sistema"; color: Theme.text; font.pixelSize: 14; font.weight: Font.Bold }
            UiText { width: 260; wrapMode: Text.WordWrap; text: "Clique no módulo para abrir o pacman num terminal (pede a sua senha lá)."; color: Theme.muted; font.pixelSize: 12 }
            UiButton { icon: "download"; text: "Atualizar agora"; kind: "accent"; onClicked: { BarState.pop = null; Quickshell.execDetached(["kitty", "--hold", "sh", "-c", "sudo pacman -Syu"]) } }
        }
    }
}
