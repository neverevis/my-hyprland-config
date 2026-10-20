// Detalhes ao passar o mouse nos modulos da barra (BarState.pop): um cartao que nasce do lado da barra, perto do
// modulo. Relogio -> calendario do mes; clima -> agora e proximas horas; cpu/memoria/gpu/temperatura/rede -> sistema;
// musica -> capa e controles; volume -> saida, volume e microfone; privacidade -> quem usa o microfone/tela;
// atualizacoes -> quantas (pacman e AUR) e o botao de atualizar; cpu/memoria/disco/swap -> uso e GB de cada um;
// dica de texto (tip) -> um balao pequeno com o nome do botao. Reaproveita os widgets da area de trabalho.
// Animacao: "Detalhes ao passar o mouse" (pagina Animacoes). Desligar: pagina Barras (ou opcao popup de cada modulo).
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
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
    // o cartao de recursos precisa dos dados do SysInfo enquanto esta aberto
    property bool usingInfo: false
    onShownChanged: {
        const need = !!shown && shown.kind === "resources"
        if (need && !usingInfo) { SysInfo.use(); usingInfo = true }
        else if (!need && usingInfo) { SysInfo.release(); usingInfo = false }
    }
    readonly property int todoPending: Settings.list(Settings.homeTodo).filter(i => !i.done).length

    LazyLoader {
        active: !!root.shown

        PanelWindow {
            id: win
            anchors { left: true; right: true; top: true; bottom: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "mine-popup"
            // dicas de texto nao pegam o mouse (nao atrapalham o clique no botao); os cartoes de detalhes pegam
            mask: win.kind === "tip" ? tipMask : cardMask
            Region { id: cardMask; item: card }
            Region { id: tipMask }

            readonly property var p: root.shown
            readonly property string kind: p ? p.kind : ""
            readonly property string side: p ? p.side : "bottom"
            readonly property var r: p ? p.rect : ({ x: 0, y: 0, w: 0, h: 0 })
            // medida da dica: largura natural (ate 280 px) e altura com quebra de linha
            readonly property string tipText: p && p.text ? p.text : ""
            TextMetrics { id: tmet; text: win.tipText; font.pixelSize: 12; font.family: Theme.font }
            UiText { id: tmeas; visible: false; text: win.tipText; width: Math.min(Math.ceil(tmet.advanceWidth) + 2, 280); wrapMode: Text.WordWrap; font.pixelSize: 12 }
            readonly property size sz: ({ tip: Qt.size(tmeas.width + 28, tmeas.implicitHeight + 18),
                                          resources: Qt.size(340, 4 * 27 + 3 * 12 + 34),
                                          calendar: Qt.size(320, 358 + (root.todoPending > 0 ? 30 + 18 * Math.min(3, root.todoPending) : 0)), weather: Qt.size(380, 250), system: Qt.size(360, 250), media: Qt.size(400, 210),
                                          volume: Qt.size(320, 170), privacy: Qt.size(300, 120), updates: Qt.size(300, 178),
                                          windows: Qt.size(Math.min(width - 40, Math.max(1, p && p.wins ? p.wins.length : 1) * 232 + 22), 196) })[kind] ?? Qt.size(300, 150)
            readonly property real gap: kind === "tip" ? 8 : 12
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
                radius: win.kind === "tip" ? 12 : 20
                color: Theme.gl(Theme.bg, 1.25)
                border.width: 1; border.color: Theme.border
                opacity: Math.min(1, root.k * 1.4)
                scale: 0.96 + 0.04 * Math.min(1, root.k)
                transformOrigin: win.side === "bottom" ? Item.Bottom : win.side === "top" ? Item.Top : win.side === "left" ? Item.Left : Item.Right
                HoverHandler { onHoveredChanged: BarState.popHover = hovered }
                Loader {
                    anchors { fill: parent; leftMargin: win.kind === "tip" ? 14 : 16; rightMargin: win.kind === "tip" ? 14 : 16; topMargin: win.kind === "tip" ? 9 : 16; bottomMargin: win.kind === "tip" ? 9 : 16 }
                    sourceComponent: ({ tip: tipC, resources: resC, calendar: calC, weather: weatherC, system: sysC, media: mediaC, volume: volC, privacy: privC, updates: updC, windows: winsC })[win.kind] ?? null
                }
            }
        }
    }

    Component {
        id: tipC
        UiText { text: root.shown ? root.shown.text : ""; color: Theme.text; font.pixelSize: 12; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
    }
    Component {
        id: calC
        Column {
            spacing: 8
            SystemClock { id: clk; precision: SystemClock.Seconds }
            UiText { text: DateTime.time(clk.date, true); color: Theme.text; font.pixelSize: 26; font.weight: Font.Bold; font.features: { "tnum": 1 } }
            UiText { text: { const s = clk.date.toLocaleDateString(Qt.locale("pt_BR"), "dddd, d 'de' MMMM 'de' yyyy"); return s.charAt(0).toUpperCase() + s.slice(1) } color: Theme.muted; font.pixelSize: 12 }
            DwCalendar { width: parent.width; height: 230; cols: 2; rows: 2; opts: ({}) }
            // tarefas pendentes (Agenda do Inicio) e ha quanto tempo o PC esta ligado
            Column {
                visible: root.todoPending > 0
                width: parent.width
                spacing: 2
                UiText { text: root.todoPending + (root.todoPending === 1 ? " tarefa pendente" : " tarefas pendentes"); color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold }
                Repeater {
                    model: Settings.list(Settings.homeTodo).filter(i => !i.done).slice(0, 3)
                    delegate: UiText { required property var modelData; width: parent.width; elide: Text.ElideRight; text: "•  " + modelData.text; color: Theme.muted; font.pixelSize: 12 }
                }
            }
            FileView { id: upf; path: "/proc/uptime" }
            Timer { interval: 30000; repeat: true; running: true; triggeredOnStart: true; onTriggered: upf.reload() }
            UiText {
                readonly property int sec: { const t = upf.text(); return t ? Math.floor(parseFloat(t.split(" ")[0])) : -1 }
                visible: sec >= 0
                color: Theme.muted; font.pixelSize: 12
                text: { const d = Math.floor(sec / 86400), h = Math.floor(sec % 86400 / 3600), m = Math.floor(sec % 3600 / 60); return "Ligado há " + (d > 0 ? d + " d " : "") + (h > 0 || d > 0 ? h + " h " : "") + m + " min" }
            }
        }
    }
    // uso de memoria, CPU, swap e disco com os GB (dados do SysInfo, que roda so enquanto o cartao esta aberto)
    Component {
        id: resC
        Column {
            id: rc
            spacing: 12
            readonly property var d: SysInfo.d
            readonly property var rows: {
                const dk = SysInfo.disks.length ? SysInfo.disks[0] : null
                return [
                    { icon: "memory", label: "Memória", v: d.memTotal ? d.memUsed / d.memTotal : 0, sub: d.memTotal ? SysInfo.bytes(d.memUsed) + " / " + SysInfo.bytes(d.memTotal) : "--" },
                    { icon: "chip", label: "Processador", v: (d.cpu ?? 0) / 100, sub: d.cpu !== undefined ? Math.round(d.cpu) + " %" + (d.cpuTemp ? " · " + d.cpuTemp + "°" : "") : "--" },
                    { icon: "swap_vertical", label: "Swap", v: d.swapTotal ? d.swapUsed / d.swapTotal : 0, sub: d.swapTotal ? SysInfo.bytes(d.swapUsed) + " / " + SysInfo.bytes(d.swapTotal) : (d.memTotal ? "sem swap" : "--") },
                    { icon: "disk", label: dk ? "Disco " + dk.mount : "Disco", v: dk ? dk.used / dk.total : 0, sub: dk ? SysInfo.bytes(dk.used) + " / " + SysInfo.bytes(dk.total) : "--" }
                ]
            }
            Repeater {
                model: rc.rows
                delegate: Column {
                    required property var modelData
                    width: rc.width
                    spacing: 5
                    Item {
                        width: parent.width; height: 16
                        Row { spacing: 6
                            UiIcon { name: modelData.icon; size: 14; color: modelData.v > 0.9 ? Theme.danger : Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                            UiText { text: modelData.label; color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter } }
                        UiText { anchors.right: parent.right; text: modelData.sub; color: Theme.muted; font.pixelSize: 12; font.features: { "tnum": 1 } }
                    }
                    Rectangle {
                        width: parent.width; height: 6; radius: 3; color: Theme.track
                        Rectangle { width: Math.max(parent.height, parent.width * Math.min(1, modelData.v)); height: parent.height; radius: 3; color: modelData.v > 0.9 ? Theme.danger : Theme.accent
                            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } } }
                    }
                }
            }
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
            UiText { text: SystemGuard.checking ? "Procurando atualizações…" : SystemGuard.updates > 0 ? SystemGuard.updates + (SystemGuard.updates === 1 ? " atualização" : " atualizações") : "Sistema em dia"; color: Theme.text; font.pixelSize: 14; font.weight: Font.Bold }
            UiText { visible: SystemGuard.updates > 0 && Settings.updAur; text: SystemGuard.updRepo + " do pacman · " + SystemGuard.updAurN + " do AUR"; color: Theme.muted; font.pixelSize: 12 }
            UiText { width: 260; wrapMode: Text.WordWrap; text: "Atualizar abre o terminal (pede a sua senha lá) e avisa quando termina."; color: Theme.muted; font.pixelSize: 12 }
            Row {
                spacing: 8
                UiButton { icon: "download"; text: "Atualizar agora"; kind: "accent"; onClicked: { BarState.pop = null; SystemGuard.runUpdate() } }
                UiButton { icon: "refresh"; text: "Verificar"; kind: "ghost"; enabled: !SystemGuard.checking; onClicked: SystemGuard.checkUpdates() }
            }
        }
    }
}
