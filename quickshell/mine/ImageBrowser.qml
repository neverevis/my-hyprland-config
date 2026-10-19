// Navegador de imagens proprio (sem abrir outro programa): atalhos de pastas, caminho, busca, ordenacao e miniaturas.
// Clique numa imagem escolhe; clique numa pasta entra. Teclado: setas, Enter, Backspace (sobe), Ctrl+F (busca), Esc.
import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel

Item {
    id: br
    signal chosen(string path)
    signal canceled()

    readonly property string home: Quickshell.env("HOME")
    property string dir: home + "/Imagens"
    property string query: ""
    property bool byTime: false
    readonly property var exts: ["png", "jpg", "jpeg", "webp", "bmp", "gif", "avif", "tif", "tiff"]

    readonly property var places: [
        { label: "Imagens", icon: "image", path: home + "/Imagens" },
        { label: "Wallpapers", icon: "wallpaper", path: Wallpaper.dir },
        { label: "Capturas", icon: "frame", path: home + "/Imagens/Screenshots" },
        { label: "Downloads", icon: "download", path: home + "/Downloads" },
        { label: "Área de trabalho", icon: "desktop", path: home + "/Área de trabalho" },
        { label: "Pasta pessoal", icon: "folderHome", path: home }
    ]

    // miniaturas em cache (~/.cache/thumbnails/large): geradas em segundo plano ao entrar numa pasta
    readonly property string thumbDir: home + "/.cache/thumbnails/large/"
    readonly property string py: home + "/.local/share/quickshell-mine/venv/bin/python"
    readonly property string thumbScript: Qt.resolvedUrl("scripts/thumbs.py").toString().replace("file://", "")
    signal thumbReady(string path)
    function thumbOf(path) { return thumbDir + Qt.md5("file://" + path.split("/").map(encodeURIComponent).join("/")) + ".png" }
    onDirChanged: genThumbs()
    function genThumbs() { thumbs.running = false; thumbs.command = ["nice", "-n", "10", py, thumbScript, dir]; thumbs.running = true }
    Process {
        id: thumbs
        stdout: SplitParser { onRead: line => br.thumbReady(line) }
    }
    Component.onCompleted: genThumbs()

    function go(p) { if (!p) return; dir = p.replace(/\/+$/, "") || "/"; query = ""; search.text = ""; grid.currentIndex = 0 }
    function up() { if (dir === "/") return; go(dir.substring(0, dir.lastIndexOf("/")) || "/") }
    function open(i) {
        if (i < 0 || i >= fm.count) return
        if (fm.get(i, "fileIsDir")) go(fm.get(i, "filePath"))
        else chosen(fm.get(i, "filePath"))
    }
    function focusGrid() { grid.forceActiveFocus() }

    FolderListModel {
        id: fm
        folder: "file://" + br.dir
        showDirs: true
        showDirsFirst: true
        showDotAndDotDot: false
        showHidden: false
        caseSensitive: false
        sortField: br.byTime ? FolderListModel.Time : FolderListModel.Name
        sortReversed: false
        // a busca vira parte do filtro (vale so para os arquivos; as pastas continuam aparecendo)
        nameFilters: br.exts.map(e => "*" + br.query + "*." + e)
    }

    // ---------- atalhos ----------
    Column {
        id: side
        width: 176
        anchors { top: parent.top; bottom: parent.bottom }
        spacing: 3
        UiLabel { text: "Lugares"; leftPadding: 10; bottomPadding: 4 }
        Repeater {
            model: br.places
            delegate: Rectangle {
                required property var modelData
                readonly property bool on: br.dir === modelData.path
                width: side.width; height: 36; radius: 10
                color: on ? Theme.tint(0.2) : (pm.containsMouse ? Theme.cardHi : "transparent")
                Behavior on color { ColorAnimation { duration: 120 } }
                Row {
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    spacing: 10
                    UiIcon { name: modelData.icon; size: 17; color: on ? Theme.accent : Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                    UiText { text: modelData.label; color: on ? Theme.text : Theme.muted; font.pixelSize: 13; font.weight: on ? Font.DemiBold : Font.Normal; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: br.go(modelData.path) }
            }
        }
    }

    // ---------- barra de cima: voltar, caminho, busca, ordem ----------
    Item {
        id: top
        anchors { left: side.right; leftMargin: 16; right: parent.right; top: parent.top }
        height: 38
        UiButton { id: upBtn; anchors.verticalCenter: parent.verticalCenter; icon: "arrowLeft"; kind: "ghost"; enabled: br.dir !== "/"; onClicked: br.up() }
        // caminho clicavel (cada pasta leva de volta a ela)
        Flickable {
            id: crumbs
            anchors { left: upBtn.right; leftMargin: 6; right: searchBox.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
            height: 30
            contentWidth: crumbRow.width
            clip: true
            interactive: false
            contentX: Math.max(0, contentWidth - width)
            Row {
                id: crumbRow
                height: parent.height
                spacing: 2
                Repeater {
                    model: {
                        const rel = br.dir.startsWith(br.home) ? br.dir.slice(br.home.length) : br.dir
                        const base = br.dir.startsWith(br.home) ? br.home : ""
                        const parts = rel.split("/").filter(x => x !== "")
                        const out = br.dir.startsWith(br.home) ? [{ label: "Início", path: br.home }] : [{ label: "/", path: "/" }]
                        let acc = base
                        for (const p of parts) { acc += "/" + p; out.push({ label: p, path: acc }) }
                        return out
                    }
                    delegate: Row {
                        required property var modelData
                        required property int index
                        height: crumbRow.height
                        spacing: 2
                        UiIcon { visible: index > 0; name: "chevRight"; size: 14; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: ct.implicitWidth + 14; height: 26; radius: 8
                            color: cm.containsMouse ? Theme.cardHi : "transparent"
                            UiText { id: ct; anchors.centerIn: parent; text: modelData.label; color: modelData.path === br.dir ? Theme.text : Theme.muted; font.pixelSize: 13; font.weight: modelData.path === br.dir ? Font.DemiBold : Font.Normal }
                            MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: br.go(modelData.path) }
                        }
                    }
                }
            }
        }
        Rectangle {
            id: searchBox
            anchors { right: sortBtn.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            width: 200; height: 34; radius: 10
            color: Theme.track
            border.width: 1; border.color: search.activeFocus ? Theme.accent : Theme.border
            UiIcon { id: sIco; anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter } name: "search"; size: 16; color: Theme.muted }
            TextInput {
                font.family: Theme.font
                id: search
                anchors { left: sIco.right; leftMargin: 8; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                color: Theme.text; font.pixelSize: 13
                selectionColor: Theme.accent; selectedTextColor: Theme.accentText
                clip: true
                onTextChanged: { br.query = text.replace(/[*?\[\]]/g, ""); grid.currentIndex = 0 }
                Keys.onDownPressed: br.focusGrid()
                Keys.onReturnPressed: { br.focusGrid(); br.open(grid.currentIndex) }
                Keys.onEscapePressed: { if (text !== "") text = ""; else br.focusGrid() }
                UiText { visible: !search.text; anchors.verticalCenter: parent.verticalCenter; text: "Buscar nesta pasta"; color: Theme.muted; font.pixelSize: 13 }
            }
        }
        UiButton { id: sortBtn; anchors { right: parent.right; verticalCenter: parent.verticalCenter } icon: br.byTime ? "sortTime" : "sortName"; text: br.byTime ? "Recentes" : "Nome"; kind: "ghost"; onClicked: br.byTime = !br.byTime }
    }

    // ---------- grade ----------
    GridView {
        id: grid
        anchors { left: side.right; leftMargin: 16; right: parent.right; top: top.bottom; topMargin: 12; bottom: parent.bottom }
        clip: true
        focus: true
        model: fm
        readonly property int cols: Math.max(1, Math.floor(width / 132))
        cellWidth: Math.floor(width / cols); cellHeight: cellWidth + 22
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: 400
        keyNavigationWraps: false
        highlightMoveDuration: 0
        Keys.onReturnPressed: br.open(currentIndex)
        Keys.onEnterPressed: br.open(currentIndex)
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Backspace) { br.up(); e.accepted = true }
            else if (e.key === Qt.Key_F && (e.modifiers & Qt.ControlModifier)) { search.forceActiveFocus(); e.accepted = true }
            else if (e.key === Qt.Key_Escape) { br.canceled(); e.accepted = true }
            else if (e.text !== "" && /[\w\-. ]/.test(e.text) && !(e.modifiers & Qt.ControlModifier)) { search.text += e.text; search.forceActiveFocus(); e.accepted = true }
        }
        Rectangle {   // barra de rolagem fina
            visible: grid.contentHeight > grid.height
            anchors.right: parent.right
            y: grid.visibleArea.yPosition * grid.height
            width: 4; radius: 2
            height: Math.max(30, grid.visibleArea.heightRatio * grid.height)
            color: Theme.border
        }

        delegate: Item {
            id: cell
            required property int index
            required property string fileName
            required property string filePath
            required property bool fileIsDir
            width: grid.cellWidth; height: grid.cellHeight
            readonly property bool cur: grid.currentIndex === index && grid.activeFocus
            readonly property bool hov: ma.containsMouse

            Rectangle {
                id: tile
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 4 }
                width: grid.cellWidth - 12; height: width; radius: 14
                color: cell.fileIsDir ? (cell.hov ? Theme.cardHi : Theme.card) : Theme.track
                border.width: cell.cur || cell.hov ? 2 : 0
                border.color: Theme.accent
                scale: ma.pressed ? 0.96 : (cell.hov ? 1.03 : 1)
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                UiIcon {
                    visible: cell.fileIsDir
                    anchors.centerIn: parent
                    name: cell.hov ? "folderOpen" : "folderPlain"; size: Math.round(tile.width * 0.42)
                    color: Theme.accent
                }
                RoundImage {
                    id: thumb
                    visible: !cell.fileIsDir
                    anchors.fill: parent; anchors.margins: 2
                    radius: 12
                    // primeiro a miniatura do cache; se ainda nao existir, a imagem original ate a miniatura ficar pronta
                    property bool cached: true
                    source: cell.fileIsDir ? "" : "file://" + (cached ? br.thumbOf(cell.filePath) : cell.filePath)
                    sourceSize: Qt.size(240, 240)
                    onStatusChanged: if (status === Image.Error && cached) Qt.callLater(() => cached = false)
                    opacity: ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    Connections { target: br; function onThumbReady(path) { if (path === cell.filePath && !thumb.cached) thumb.cached = true } }
                }
            }
            UiText {
                anchors { top: tile.bottom; topMargin: 5; horizontalCenter: parent.horizontalCenter }
                width: tile.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideMiddle
                text: cell.fileName
                color: cell.cur || cell.hov ? Theme.text : Theme.muted
                font.pixelSize: 11
            }
            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { grid.currentIndex = cell.index; br.open(cell.index) }
            }
        }

        // pasta vazia / carregando
        Column {
            anchors.centerIn: parent
            visible: fm.status === FolderListModel.Ready && fm.count === 0
            spacing: 8
            UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "images"; size: 40; color: Theme.muted }
            UiText { anchors.horizontalCenter: parent.horizontalCenter; text: br.query !== "" ? "Nenhuma imagem com “" + br.query + "”" : "Nenhuma imagem nesta pasta"; color: Theme.muted; font.pixelSize: 13 }
        }
    }
}
