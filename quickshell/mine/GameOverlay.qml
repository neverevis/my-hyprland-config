// Painel de jogo (como o overlay do end4, Super+G): uma camada por cima de tudo com mini-janelas - mira, notas,
// imagem flutuante, gravacao, volume por app e uso do sistema. Aberto: fundo escurecido, arrastar move, o alfinete
// fixa. Fechado: as fixadas continuam por cima do jogo, sem pegar o mouse (a mira sempre fica assim).
// IPC: qs -c mine ipc call overlay toggle | open | close
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick

Scope {
    id: root
    property bool open: false
    IpcHandler {
        target: "overlay"
        function toggle(): void { root.open = !root.open }
        function open(): void { root.open = true }
        function close(): void { root.open = false }
        function info(): string { return JSON.stringify({ n: root.items.length, type: typeof Settings.overlayItems, pinned: root.anyPinned }) }
    }
    readonly property var types: [
        { type: "crosshair", label: "Mira", icon: "target" },
        { type: "notes", label: "Notas", icon: "pencil" },
        { type: "image", label: "Imagem", icon: "image" },
        { type: "recorder", label: "Gravar", icon: "monitor" },
        { type: "mixer", label: "Volume por app", icon: "volume" },
        { type: "resources", label: "Sistema", icon: "chip" },
        { type: "fps", label: "Limite de FPS", icon: "lightning" }
    ]
    readonly property string notesPath: Quickshell.env("HOME") + "/.local/share/quickshell-mine/overlay-notes.txt"
    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.local/share/quickshell-mine"])
    readonly property var items: Settings.list(Settings.overlayItems)
    function find(t) { return items.find(i => i.type === t) ?? null }
    function mutate(fn) { const l = JSON.parse(JSON.stringify(items)); fn(l); Settings.overlayItems = l }
    function toggleType(t) {
        mutate(l => { const i = l.findIndex(x => x.type === t); if (i >= 0) l.splice(i, 1); else l.push({ type: t, x: 0.5, y: 0.35, pinned: t === "crosshair", opts: {} }) })
    }
    function setItem(t, patch) { mutate(l => { const i = l.findIndex(x => x.type === t); if (i >= 0) Object.assign(l[i], patch) }) }
    readonly property bool anyPinned: items.some(i => i.pinned)

    LazyLoader {
        active: root.open || root.anyPinned

        PanelWindow {
            id: win
            anchors { left: true; right: true; top: true; bottom: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : (win.clicks.length ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None)
            WlrLayershell.namespace: "mine-overlay"
            // fechado: nao pega o mouse (o jogo continua recebendo tudo), exceto as fixadas marcadas como clicaveis
            mask: root.open ? null : clickMask
            property var clicks: []
            function rebuild() {
                const l = []
                for (let i = 0; i < rep.count; i++) { const x = rep.itemAt(i); if (x && x.clickable) l.push(x) }
                clicks = l
            }
            Region {
                id: clickMask
                Region { item: win.clicks[0] ?? null }
                Region { item: win.clicks[1] ?? null }
                Region { item: win.clicks[2] ?? null }
                Region { item: win.clicks[3] ?? null }
                Region { item: win.clicks[4] ?? null }
                Region { item: win.clicks[5] ?? null }
                Region { item: win.clicks[6] ?? null }
            }
            property real k: root.open ? 1 : 0
            Behavior on k { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.45 * win.k) }
            MouseArea { anchors.fill: parent; enabled: root.open; onClicked: root.open = false }
            Item { focus: root.open; Keys.onEscapePressed: root.open = false }

            // barra do painel: liga/desliga cada mini-janela
            Rectangle {
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 30 - (1 - win.k) * 40 }
                opacity: win.k
                visible: opacity > 0.01
                width: tb.implicitWidth + 20; height: 54; radius: 27
                color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.95); border.width: 1; border.color: Theme.border
                Row {
                    id: tb
                    anchors.centerIn: parent
                    spacing: 4
                    UiIcon { name: "gamepad"; size: 18; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                    Item { width: 6; height: 1 }
                    Repeater {
                        model: root.types
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool on: !!root.find(modelData.type)
                            height: 38; width: tr.implicitWidth + 20; radius: 19
                            color: on ? Theme.accent : (tm.containsMouse ? Theme.cardHi : "transparent")
                            Row { id: tr; anchors.centerIn: parent; spacing: 6
                                UiIcon { name: modelData.icon; size: 15; color: parent.parent.on ? Theme.accentText : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                                UiText { text: modelData.label; color: parent.parent.on ? Theme.accentText : Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter } }
                            // clique direito: recentraliza a mini-janela
                            MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.RightButton; cursorShape: Qt.PointingHandCursor
                                onClicked: m => { if (m.button === Qt.RightButton) { if (parent.on) root.setItem(modelData.type, { x: 0.5, y: 0.5 }) } else root.toggleType(modelData.type) } }
                        }
                    }
                    Rectangle { width: 1; height: 26; color: Theme.border; anchors.verticalCenter: parent.verticalCenter }
                    SystemClock { id: tbClk; precision: SystemClock.Minutes }
                    UiText { text: Qt.formatTime(tbClk.date, "HH:mm"); color: Theme.text; font.pixelSize: 13; font.weight: Font.Bold; font.features: { "tnum": 1 }; anchors.verticalCenter: parent.verticalCenter; leftPadding: 6; rightPadding: 6 }
                    Rectangle {
                        height: 38; width: gr.implicitWidth + 20; radius: 19
                        color: Toggles.gameMode ? Theme.tint(0.25) : (gm.containsMouse ? Theme.cardHi : "transparent")
                        Row { id: gr; anchors.centerIn: parent; spacing: 6
                            UiIcon { name: "lightning"; size: 15; color: Toggles.gameMode ? Theme.accent : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                            UiText { text: "Modo jogo"; color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter } }
                        MouseArea { id: gm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Toggles.setGame(!Toggles.gameMode) }
                    }
                }
            }

            // mini-janelas
            Repeater {
                id: rep
                model: root.items
                onItemAdded: Qt.callLater(win.rebuild)
                onItemRemoved: Qt.callLater(win.rebuild)
                delegate: Item {
                    id: it
                    required property var modelData
                    readonly property bool clickable: !!modelData.pinned && !!modelData.click && !cross
                    readonly property bool cross: modelData.type === "crosshair"
                    readonly property bool shownNow: root.open || modelData.pinned
                    visible: shownNow
                    opacity: root.open ? 1 : (cross ? 1 : (Settings.overlayPinnedOpacity / 100))
                    width: cross ? 60 : (ld.item ? ld.item.implicitWidth + 24 : 200)
                    height: cross ? 60 : (ld.item ? ld.item.implicitHeight + (root.open ? 58 : 24) : 120)
                    x: cross ? (win.width - width) / 2 : modelData.x * (win.width - width)
                    y: cross ? (win.height - height) / 2 : modelData.y * (win.height - height)
                    // mira: so o desenho, no centro da tela
                    Item {
                        visible: it.cross
                        anchors.centerIn: parent
                        readonly property color c: Settings.overlayCrossColor
                        readonly property real s: Settings.overlayCrossSize
                        Rectangle { visible: Settings.overlayCrossStyle !== "dot"; anchors.centerIn: parent; width: parent.s; height: 2; color: parent.c }
                        Rectangle { visible: Settings.overlayCrossStyle !== "dot"; anchors.centerIn: parent; width: 2; height: parent.s; color: parent.c }
                        Rectangle { visible: Settings.overlayCrossStyle !== "cross"; anchors.centerIn: parent; width: 5; height: 5; radius: 2.5; color: parent.c }
                        Rectangle { visible: Settings.overlayCrossStyle === "circle"; anchors.centerIn: parent; width: parent.s; height: parent.s; radius: width / 2; color: "transparent"; border.width: 1.5; border.color: parent.c }
                    }
                    Rectangle {
                        visible: !it.cross
                        anchors.fill: parent
                        radius: 16
                        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.93); border.width: 1; border.color: Theme.border
                        // cabecalho (so com o painel aberto): arrastar, fixar, fechar
                        Item {
                            id: hd
                            visible: root.open
                            anchors { left: parent.left; right: parent.right; top: parent.top }
                            height: 34
                            UiText { x: 12; anchors.verticalCenter: parent.verticalCenter; text: (root.types.find(t => t.type === it.modelData.type) ?? {}).label ?? ""; color: Theme.muted; font.pixelSize: 11; font.weight: Font.DemiBold }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.SizeAllCursor
                                property point p0
                                onPressed: m => p0 = Qt.point(m.x, m.y)
                                onPositionChanged: m => {
                                    const nx = Math.max(0, Math.min(1, (it.x + m.x - p0.x) / Math.max(1, win.width - it.width)))
                                    const ny = Math.max(0, Math.min(1, (it.y + m.y - p0.y) / Math.max(1, win.height - it.height)))
                                    root.setItem(it.modelData.type, { x: nx, y: ny })
                                }
                            }
                            Row {
                                anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                                spacing: 2
                                Rectangle { visible: !it.cross; width: 26; height: 26; radius: 13; color: cn.containsMouse ? Theme.cardHi : "transparent"
                                    UiIcon { anchors.centerIn: parent; name: "target"; size: 13; color: Theme.muted }
                                    MouseArea { id: cn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.setItem(it.modelData.type, { x: 0.5, y: 0.5 }) } }
                                Rectangle { visible: it.modelData.pinned && !it.cross; width: 26; height: 26; radius: 13; color: it.modelData.click ? Theme.tint(0.25) : (ck.containsMouse ? Theme.cardHi : "transparent")
                                    UiIcon { anchors.centerIn: parent; name: "tap"; size: 13; color: it.modelData.click ? Theme.accent : Theme.muted }
                                    MouseArea { id: ck; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.setItem(it.modelData.type, { click: !it.modelData.click }) } }
                                Rectangle { width: 26; height: 26; radius: 13; color: it.modelData.pinned ? Theme.tint(0.25) : (pm.containsMouse ? Theme.cardHi : "transparent")
                                    UiIcon { anchors.centerIn: parent; name: "tag"; size: 13; color: it.modelData.pinned ? Theme.accent : Theme.muted }
                                    MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.setItem(it.modelData.type, { pinned: !it.modelData.pinned }) } }
                                Rectangle { width: 26; height: 26; radius: 13; color: cm.containsMouse ? Theme.cardHi : "transparent"
                                    UiIcon { anchors.centerIn: parent; name: "close"; size: 13; color: Theme.muted }
                                    MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleType(it.modelData.type) } }
                            }
                        }
                        Loader {
                            id: ld
                            x: 12; y: root.open ? 40 : 12
                            sourceComponent: ({ notes: notesC, image: imageC, recorder: recC, mixer: mixC, resources: resC, fps: fpsC })[it.modelData.type] ?? null
                            // painel aberto ou fixada clicavel: os controles funcionam
                            onLoaded: if (item && item.live !== undefined) item.live = Qt.binding(() => root.open || it.clickable)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: notesC
        Item {
            id: nt
            property bool live: root.open
            property string stat: ""
            implicitWidth: 260; implicitHeight: 190
            // notas num arquivo (nao no settings.json), salvas 500 ms depois da ultima tecla
            FileView {
                id: nf
                path: root.notesPath
                onLoaded: if (!te.activeFocus) te.text = text()
                onLoadFailed: if (!te.activeFocus) te.text = Settings.overlayNotes
            }
            Timer { id: deb; interval: 500; onTriggered: { nf.setText(te.text); nt.stat = "Salvo" } }
            TextEdit {
                id: te
                anchors { left: parent.left; right: parent.right; top: parent.top; bottom: sl.top; bottomMargin: 4 }
                color: Theme.text; font.pixelSize: 13; font.family: Theme.font
                wrapMode: TextEdit.Wrap; selectByMouse: true
                readOnly: !nt.live
                onTextChanged: if (activeFocus) { nt.stat = "Salvando…"; deb.restart() }
                UiText { visible: !parent.text; text: "Anotações rápidas…"; color: Theme.muted; font.pixelSize: 13 }
            }
            UiText { id: sl; anchors { right: parent.right; bottom: parent.bottom } text: nt.stat; color: Theme.muted; font.pixelSize: 10 }
        }
    }
    Component {
        id: imageC
        Item {
            readonly property string src: Settings.overlayImage
            implicitWidth: src ? Math.max(120, img.implicitWidth * Settings.overlayImageScale / 100) : 220
            implicitHeight: src ? Math.max(80, img.implicitHeight * Settings.overlayImageScale / 100) : 60
            AnimatedImage { id: img; anchors.fill: parent; visible: !!parent.src; source: parent.src ? "file://" + parent.src : ""; fillMode: Image.PreserveAspectFit; playing: true }
            // roda do mouse muda o tamanho (10 a 150 %)
            WheelHandler { enabled: !!parent.src; onWheel: e => Settings.overlayImageScale = Math.max(10, Math.min(150, Settings.overlayImageScale + (e.angleDelta.y > 0 ? 5 : -5))) }
            UiButton { visible: !parent.src || root.open; anchors.centerIn: parent; icon: "folderOpen"; text: parent.src ? "" : "Escolher imagem"; onClicked: Pick.image("Imagem flutuante", p => Settings.overlayImage = p) }
        }
    }
    Component {
        id: recC
        Column {
            id: rc
            property bool live: root.open
            spacing: 10
            Row {
                spacing: 10
                Rectangle { width: 12; height: 12; radius: 6; color: Recorder.active ? Theme.danger : Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                UiText { text: Recorder.active ? Recorder.elapsed : "Parado"; color: Theme.text; font.pixelSize: 15; font.weight: Font.Bold; font.features: { "tnum": 1 }; anchors.verticalCenter: parent.verticalCenter }
                UiButton { visible: rc.live; icon: Recorder.active ? "pause" : "monitor"; text: Recorder.active ? "Parar" : "Tela toda"; kind: Recorder.active ? "danger" : "accent"; onClicked: Recorder.active ? Recorder.stop() : Recorder.start(false) }
            }
            // capturas: fecham o painel antes (para a tela congelada nao pegar o overlay)
            Row {
                visible: rc.live
                spacing: 6
                UiButton { icon: "frame"; text: "Área"; kind: "ghost"; onClicked: { root.open = false; Capture.start("copy") } }
                UiButton { icon: "camera"; text: "Tela"; kind: "ghost"; onClicked: { root.open = false; Quickshell.execDetached(["sh", "-c", "sleep 0.3; grim - | wl-copy -t image/png"]) } }
                UiButton { icon: "monitor"; text: "Gravar área"; kind: "ghost"; onClicked: { root.open = false; Capture.start("record") } }
                UiButton { icon: "folderOpen"; kind: "ghost"; onClicked: Qt.openUrlExternally("file://" + Recorder.dir) }
            }
        }
    }
    Component {
        id: mixC
        Column {
            id: mixCol
            spacing: 8
            readonly property var streams: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioOutStream)
            PwObjectTracker { objects: mixCol.streams }
            readonly property var sink: Pipewire.defaultAudioSink
            PwObjectTracker { objects: [mixCol.sink] }
            UiSlider { width: 260; label: "Geral"; icon: mixCol.sink && mixCol.sink.audio && mixCol.sink.audio.muted ? "volumeOff" : "volume"; from: 0; to: 100; suffix: " %"
                value: mixCol.sink && mixCol.sink.audio ? Math.round(mixCol.sink.audio.volume * 100) : 0
                onMoved: v => { if (mixCol.sink && mixCol.sink.audio) mixCol.sink.audio.volume = v / 100 } }
            UiText { visible: !parent.streams.length; text: "Nenhum app tocando som"; color: Theme.muted; font.pixelSize: 12 }
            Repeater {
                model: parent.streams
                delegate: Column {
                    required property var modelData
                    width: 260; spacing: 2
                    readonly property var p: modelData.properties || {}
                    Row {
                        width: parent.width; spacing: 6
                        UiText { width: parent.width - 28; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; text: p["application.name"] || modelData.description || modelData.name; color: Theme.text; font.pixelSize: 12 }
                        UiIcon { anchors.verticalCenter: parent.verticalCenter; name: modelData.audio && modelData.audio.muted ? "volumeOff" : "volume"; size: 16; color: modelData.audio && modelData.audio.muted ? Theme.danger : Theme.muted
                            MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: { if (modelData.audio) modelData.audio.muted = !modelData.audio.muted } } }
                    }
                    UiSlider { width: parent.width; label: ""; from: 0; to: 100; suffix: " %"; value: modelData.audio ? Math.round(modelData.audio.volume * 100) : 0
                        onMoved: v => { if (modelData.audio) modelData.audio.volume = v / 100 } }
                }
            }
        }
    }
    Component {
        id: resC
        Column {
            id: rs
            spacing: 6
            property int tab: 0   // 0 CPU, 1 RAM, 2 Swap
            readonly property real swapU: SysInfo.d.swapTotal ? SysInfo.d.swapUsed / SysInfo.d.swapTotal : 0
            readonly property real val: tab === 0 ? SysInfo.cpu : tab === 1 ? SysInfo.mem : swapU
            readonly property string of: tab === 1 ? "de " + (SysInfo.d.memTotal / 1048576).toFixed(1) + " GB" : tab === 2 ? "de " + ((SysInfo.d.swapTotal || 0) / 1048576).toFixed(1) + " GB" : (SysInfo.temp !== null ? SysInfo.temp + "°C" : "")
            Component.onCompleted: SysInfo.use()
            Component.onDestruction: SysInfo.release()
            Row {
                spacing: 4
                Repeater {
                    model: ["CPU", "RAM", "Swap"]
                    delegate: Rectangle {
                        required property string modelData
                        required property int index
                        width: tl.implicitWidth + 18; height: 24; radius: 12
                        color: rs.tab === index ? Theme.accent : Theme.track
                        UiText { id: tl; anchors.centerIn: parent; text: modelData; font.pixelSize: 11; font.weight: Font.DemiBold; color: rs.tab === index ? Theme.accentText : Theme.text }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: rs.tab = index }
                    }
                }
            }
            Row {
                spacing: 8
                UiText { text: Math.round(rs.val * 100) + "%"; color: Theme.text; font.pixelSize: 26; font.weight: Font.Bold; font.features: { "tnum": 1 } }
                UiText { text: rs.of; color: Theme.muted; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            }
            MiniGraph { visible: rs.tab < 2; width: 220; height: 46; max: 1; values: rs.tab === 0 ? SysInfo.hist.cpu : SysInfo.hist.mem }
            UiText { visible: SysInfo.d.gpu; text: "GPU " + Math.round(SysInfo.gpu * 100) + "%" + (SysInfo.gpuTemp ? "  " + SysInfo.gpuTemp + "°" : ""); color: Theme.muted; font.pixelSize: 12 }
        }
    }
    Component {
        id: fpsC
        Row {
            id: fr
            property bool live: root.open
            spacing: 8
            UiField { id: fv; width: 70; placeholderText: "FPS"; enabled: fr.live; validator: IntValidator { bottom: 10; top: 1000 } }
            UiButton { enabled: fr.live; icon: "check"; text: "Aplicar"; kind: "accent"; onClicked: if (fv.text !== "") Quickshell.execDetached(["sh", "-c", 'f="$HOME/.config/MangoHud/MangoHud.conf"; mkdir -p "$(dirname "$f")"; touch "$f"; if grep -q "^fps_limit=" "$f"; then sed -i "s/^fps_limit=.*/fps_limit=$1/" "$f"; else echo "fps_limit=$1" >> "$f"; fi; pkill -SIGUSR2 mangohud', "sh", fv.text]) }
            UiText { text: "MangoHud"; color: Theme.muted; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
