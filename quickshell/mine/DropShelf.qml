// Prateleira de arquivos (como o "dropover" do end4): um cartao na lateral da tela onde voce solta arquivos vindos de
// qualquer app e depois arrasta de volta para outro lugar (outro app, outra pasta). A lista fica salva ate limpar.
// Abrir: acao "Prateleira de arquivos" no launcher, ou qs -c mine ipc call shelf toggle.
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: root
    property bool open: false
    IpcHandler {
        target: "shelf"
        function toggle(): void { root.open = !root.open }
        function open(): void { root.open = true }
        function close(): void { root.open = false }
    }
    readonly property var files: Settings.list(Settings.shelfFiles)
    function add(urls) {
        const l = files.slice()
        for (const u of urls) { const p = decodeURIComponent(String(u).replace(/^file:\/\//, "")); if (p && l.indexOf(p) < 0) l.push(p) }
        Settings.shelfFiles = l
    }
    function remove(p) { Settings.shelfFiles = files.filter(x => x !== p) }
    function isImage(p) { return /\.(png|jpe?g|webp|gif|bmp|svg|avif)$/i.test(p) }
    function iconOf(p) {
        const e = p.split(".").pop().toLowerCase()
        return ({ pdf: "application-pdf", zip: "package-x-generic", gz: "package-x-generic", mp4: "video-x-generic", mkv: "video-x-generic", mp3: "audio-x-generic",
                  flac: "audio-x-generic", txt: "text-x-generic", md: "text-x-generic", doc: "x-office-document", docx: "x-office-document", odt: "x-office-document" })[e] ?? (p.indexOf(".") < 0 ? "folder" : "text-x-generic")
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            id: win
            anchors { right: true; top: true; bottom: true }
            implicitWidth: 300
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "mine-shelf"
            mask: Region { item: card }
            property real k: 0
            Component.onCompleted: k = 1
            Behavior on k { MotionAnim { use: "home" } }

            Rectangle {
                id: card
                anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 16 - (1 - win.k) * 40 }
                width: 268; height: Math.min(parent.height - 120, Math.max(220, list.contentHeight + 120))
                radius: 22
                color: Theme.gl(Theme.bg, 1.2)
                border.width: drop.containsDrag ? 2 : 1; border.color: drop.containsDrag ? Theme.accent : Theme.border
                opacity: win.k
                DropArea {
                    id: drop
                    anchors.fill: parent
                    keys: ["text/uri-list"]
                    onDropped: d => { if (d.hasUrls) { root.add(d.urls); d.acceptProposedAction() } }
                }
                Row {
                    id: head
                    x: 16; y: 14
                    spacing: 8
                    UiIcon { name: "layers"; size: 17; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                    UiText { text: "Prateleira"; color: Theme.text; font.pixelSize: 15; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                    UiText { text: root.files.length ? root.files.length + " item(ns)" : ""; color: Theme.muted; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                }
                UiButton { anchors { right: parent.right; top: parent.top; margins: 8 } icon: "close"; kind: "ghost"; onClicked: root.open = false }
                UiText {
                    visible: !root.files.length
                    anchors.centerIn: parent
                    width: parent.width - 40; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                    text: "Solte arquivos aqui.\nDepois arraste daqui para onde quiser."
                    color: Theme.muted; font.pixelSize: 13
                }
                ListView {
                    id: list
                    anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: foot.top; margins: 10; topMargin: 12 }
                    clip: true
                    spacing: 4
                    model: root.files
                    delegate: Rectangle {
                        id: row
                        required property string modelData
                        width: ListView.view.width; height: 46; radius: 12
                        color: rm.containsMouse ? Theme.cardHi : Theme.track
                        // arrastar para fora: leva o arquivo (uri-list) para o app que receber
                        Drag.active: rm.drag.active
                        Drag.dragType: Drag.Automatic
                        Drag.supportedActions: Qt.CopyAction
                        Drag.mimeData: ({ "text/uri-list": "file://" + encodeURI(row.modelData) + "\r\n" })
                        Item {
                            id: ic
                            x: 8; anchors.verticalCenter: parent.verticalCenter
                            width: 30; height: 30
                            RoundImage { anchors.fill: parent; radius: 6; visible: root.isImage(row.modelData); source: visible ? "file://" + row.modelData : ""; sourceSize: Qt.size(60, 60) }
                            Image { anchors.fill: parent; visible: !root.isImage(row.modelData); source: Icons.path(root.iconOf(row.modelData), "text-x-generic"); sourceSize: Qt.size(60, 60) }
                        }
                        Column {
                            anchors { left: ic.right; leftMargin: 10; right: xb.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
                            UiText { width: parent.width; elide: Text.ElideMiddle; text: row.modelData.split("/").pop(); color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold }
                            UiText { width: parent.width; elide: Text.ElideMiddle; text: row.modelData.replace(/\/[^/]*$/, "").replace(Quickshell.env("HOME"), "~"); color: Theme.muted; font.pixelSize: 10 }
                        }
                        MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; drag.target: dummy; cursorShape: Qt.OpenHandCursor
                            onDoubleClicked: Qt.openUrlExternally("file://" + row.modelData) }
                        Item { id: dummy }
                        UiIcon { id: xb; anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter } name: "close"; size: 13; color: xm.containsMouse ? Theme.danger : Theme.muted
                            MouseArea { id: xm; anchors.fill: parent; anchors.margins: -5; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.remove(row.modelData) } }
                    }
                }
                Row {
                    id: foot
                    anchors { left: parent.left; bottom: parent.bottom; margins: 10 }
                    spacing: 6
                    visible: root.files.length > 0
                    UiButton { icon: "cards"; text: "Copiar caminhos"; kind: "ghost"; onClicked: Quickshell.clipboardText = root.files.join("\n") }
                    UiButton { icon: "broom"; text: "Limpar"; kind: "ghost"; onClicked: Settings.shelfFiles = [] }
                }
            }
        }
    }
}
