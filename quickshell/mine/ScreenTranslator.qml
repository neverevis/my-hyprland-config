// Traducao de tela no lugar: congela o monitor focado, le o texto por paragrafo (tesseract) e traduz cada trecho (trans),
// desenhando a traducao sobre o texto original. Arrastar move, roda do mouse da zoom (0,1x a 5x), Esc fecha.
// IPC: qs -c mine ipc call screentranslator translate | close
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

Scope {
    id: root
    property bool open: false
    property bool busy: false
    property string status: ""
    property var boxes: []
    property var imgSize: [1, 1]
    property string monitor: ""
    readonly property string file: Quickshell.env("HOME") + "/.cache/quickshell-mine/screentr.png"
    readonly property string script: Qt.resolvedUrl("scripts/capture.py").toString().replace("file://", "")

    function start() {
        if (busy || open) return
        Settings.launcherOpen = false; Settings.homeOpen = false; Settings.wpPickerOpen = false
        monitor = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
        boxes = []; status = "Lendo o texto da tela…"; busy = true
        grab.command = ["sh", "-c", 'mkdir -p "$(dirname "$1")"; sleep 0.15; grim ' + (monitor ? '-o "$2" ' : "") + '"$1"', "sh", file, monitor]
        grab.running = true
    }
    function close() { open = false }
    Process {
        id: grab
        onExited: code => {
            if (code !== 0) { root.busy = false; return }
            root.open = true
            ocr.command = ["python3", root.script, "ocrboxes", root.file, Settings.translateTarget || "pt"]
            ocr.running = true
        }
    }
    Process {
        id: ocr
        stdout: StdioCollector { id: ocrOut }
        onExited: {
            root.busy = false
            try {
                const r = JSON.parse(ocrOut.text)
                root.boxes = r.boxes; root.imgSize = r.size
                root.status = !r.boxes.length ? "Nenhum texto encontrado" : (r.translated ? r.msg + " traduzidos" : "Não consegui traduzir (sem internet?)")
            } catch (e) { root.status = "Falhou ao ler a tela" }
        }
    }
    IpcHandler {
        target: "screentranslator"
        function translate(): void { root.open ? root.close() : root.start() }
        function close(): void { root.close() }
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            id: win
            anchors { left: true; right: true; top: true; bottom: true }
            color: "black"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "mine-screentr"
            screen: Quickshell.screens.find(s => s.name === root.monitor) ?? null
            property bool showOrig: false

            Item {
                id: stage
                width: win.width; height: win.height
                transformOrigin: Item.TopLeft
                Image { anchors.fill: parent; source: "file://" + root.file + "?" + Date.now(); cache: false; smooth: true }
                Repeater {
                    model: root.boxes
                    delegate: Rectangle {
                        required property var modelData
                        readonly property real f: stage.width / Math.max(1, root.imgSize[0])
                        x: (modelData.x - 3) * f; y: (modelData.y - 2) * f
                        width: (modelData.w + 6) * f; height: (modelData.h + 4) * f
                        radius: 3
                        color: modelData.bg
                        visible: !win.showOrig
                        UiText {
                            anchors.fill: parent; anchors.margins: 1
                            text: modelData.tr
                            color: modelData.fg
                            wrapMode: Text.WordWrap
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: Math.max(7, Math.min(40, parent.height / Math.max(1, modelData.lines) * 0.82))
                            fontSizeMode: Text.Fit; minimumPixelSize: 6
                        }
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                property point p0
                property point s0
                onPressed: m => { p0 = Qt.point(m.x, m.y); s0 = Qt.point(stage.x, stage.y) }
                onPositionChanged: m => { if (pressed) { stage.x = s0.x + m.x - p0.x; stage.y = s0.y + m.y - p0.y } }
                onWheel: w => {
                    const z0 = stage.scale, z1 = Math.max(0.1, Math.min(5, z0 * (w.angleDelta.y > 0 ? 1.12 : 1 / 1.12)))
                    // mantem o ponto sob o cursor parado
                    stage.x = w.x - (w.x - stage.x) * z1 / z0
                    stage.y = w.y - (w.y - stage.y) * z1 / z0
                    stage.scale = z1
                }
            }
            Rectangle {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 34 }
                width: tbRow.implicitWidth + 24; height: 48; radius: 24
                color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.95); border.width: 1; border.color: Theme.border
                Row {
                    id: tbRow
                    anchors.centerIn: parent; spacing: 10
                    LoadingBlob { visible: root.busy; size: 22; anchors.verticalCenter: parent.verticalCenter }
                    UiIcon { visible: !root.busy; name: "translate"; size: 18; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                    UiText { text: root.status; color: Theme.text; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                    UiButton { visible: !root.busy && root.boxes.length > 0; text: win.showOrig ? "Ver tradução" : "Ver original"; kind: "ghost"; onClicked: win.showOrig = !win.showOrig }
                    UiButton { text: "Ajustar"; kind: "ghost"; onClicked: { stage.x = 0; stage.y = 0; stage.scale = 1 } }
                    UiButton { icon: "close"; kind: "ghost"; onClicked: root.close() }
                }
            }
            Item { focus: true; Keys.onEscapePressed: root.close(); Keys.onPressed: e => { if (e.key === Qt.Key_O) { win.showOrig = !win.showOrig; e.accepted = true } } }
        }
    }
}
