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
        { type: "resources", label: "Sistema", icon: "chip" }
    ]
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
            WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.namespace: "mine-overlay"
            // fechado: nao pega o mouse (o jogo continua recebendo tudo)
            mask: root.open ? null : noInput
            Region { id: noInput }
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
                            MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleType(modelData.type) }
                        }
                    }
                    Rectangle { width: 1; height: 26; color: Theme.border; anchors.verticalCenter: parent.verticalCenter }
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
                model: root.items
                delegate: Item {
                    id: it
                    required property var modelData
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
                            sourceComponent: ({ notes: notesC, image: imageC, recorder: recC, mixer: mixC, resources: resC })[it.modelData.type] ?? null
                        }
                    }
                }
            }
        }
    }

    Component {
        id: notesC
        Rectangle {
            implicitWidth: 260; implicitHeight: 160
            color: "transparent"
            TextEdit {
                anchors.fill: parent
                text: Settings.overlayNotes
                color: Theme.text; font.pixelSize: 13; font.family: Theme.font
                wrapMode: TextEdit.Wrap; selectByMouse: true
                readOnly: !root.open
                onTextChanged: if (activeFocus) Settings.overlayNotes = text
                UiText { visible: !parent.text; text: "Anotações rápidas…"; color: Theme.muted; font.pixelSize: 13 }
            }
        }
    }
    Component {
        id: imageC
        Item {
            readonly property string src: Settings.overlayImage
            implicitWidth: src ? Math.max(120, img.implicitWidth * Settings.overlayImageScale / 100) : 220
            implicitHeight: src ? Math.max(80, img.implicitHeight * Settings.overlayImageScale / 100) : 60
            Image { id: img; anchors.fill: parent; visible: !!parent.src; source: parent.src ? "file://" + parent.src : ""; fillMode: Image.PreserveAspectFit; sourceSize: Qt.size(1200, 1200) }
            UiButton { visible: !parent.src || root.open; anchors.centerIn: parent; icon: "folderOpen"; text: parent.src ? "" : "Escolher imagem"; onClicked: Pick.image("Imagem flutuante", p => Settings.overlayImage = p) }
        }
    }
    Component {
        id: recC
        Row {
            spacing: 10
            Rectangle { width: 12; height: 12; radius: 6; color: Recorder.active ? Theme.danger : Theme.muted; anchors.verticalCenter: parent.verticalCenter }
            UiText { text: Recorder.active ? Recorder.elapsed : "Parado"; color: Theme.text; font.pixelSize: 15; font.weight: Font.Bold; font.features: { "tnum": 1 }; anchors.verticalCenter: parent.verticalCenter }
            UiButton { visible: root.open; icon: Recorder.active ? "pause" : "monitor"; text: Recorder.active ? "Parar" : "Gravar"; kind: Recorder.active ? "danger" : "accent"; onClicked: Recorder.active ? Recorder.stop() : Recorder.start(false) }
        }
    }
    Component {
        id: mixC
        Column {
            id: mixCol
            spacing: 8
            readonly property var streams: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioOutStream)
            PwObjectTracker { objects: mixCol.streams }
            UiText { visible: !parent.streams.length; text: "Nenhum app tocando som"; color: Theme.muted; font.pixelSize: 12 }
            Repeater {
                model: parent.streams
                delegate: Column {
                    required property var modelData
                    width: 260; spacing: 2
                    readonly property var p: modelData.properties || {}
                    UiText { width: parent.width; elide: Text.ElideRight; text: p["application.name"] || modelData.description || modelData.name; color: Theme.text; font.pixelSize: 12 }
                    UiSlider { width: parent.width; label: ""; from: 0; to: 100; suffix: " %"; value: modelData.audio ? Math.round(modelData.audio.volume * 100) : 0
                        onMoved: v => { if (modelData.audio) modelData.audio.volume = v / 100 } }
                }
            }
        }
    }
    Component {
        id: resC
        Column {
            spacing: 4
            Component.onCompleted: SysInfo.use()
            Component.onDestruction: SysInfo.release()
            Repeater {
                model: [["CPU", Math.round(SysInfo.cpu * 100) + "%" + (SysInfo.temp !== null ? "  " + SysInfo.temp + "°" : "")], ["RAM", Math.round(SysInfo.mem * 100) + "%"],
                        ["GPU", SysInfo.d.gpu ? Math.round(SysInfo.gpu * 100) + "%" + (SysInfo.gpuTemp ? "  " + SysInfo.gpuTemp + "°" : "") : "--"]]
                delegate: Row {
                    required property var modelData
                    spacing: 10
                    UiText { width: 40; text: modelData[0]; color: Theme.muted; font.pixelSize: 12; font.weight: Font.DemiBold }
                    UiText { text: modelData[1]; color: Theme.text; font.pixelSize: 13; font.weight: Font.Bold; font.features: { "tnum": 1 } }
                }
            }
        }
    }
}
