// Conversor de imagens: solte imagens no widget (ou clique para escolher uma) e elas viram PNG, JPG, WEBP, AVIF ou PDF
// (scripts/convert.py, Pillow). Formato, qualidade, pasta de saida e manter o original: opcoes do widget. Clique num
// resultado abre a pasta dele. Nunca sobrescreve; sem "manter o original", ele vai para a lixeira.
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: w
    property int cols: 2
    property int rows: 2
    property var opts: ({})
    property string wid: ""
    property color fg: Theme.text
    property color dim: Theme.muted
    property color ac: Theme.accent
    property color ac2: Theme.tertiary            // cor companheira (o DeskView passa a do tom escolhido)
    property color cont: Theme.primaryContainer
    property color contInk: Theme.primaryContainerInk
    property bool bare: false
    function o(k) { return DeskState.opt({ type: "convert", opts: w.opts }, k) }

    readonly property string script: Qt.resolvedUrl("scripts/convert.py").toString().replace("file://", "")
    readonly property var formats: ["png", "jpg", "webp", "avif", "bmp", "tiff", "pdf"]
    readonly property var imgExt: ["png", "jpg", "jpeg", "webp", "avif", "bmp", "gif", "tif", "tiff", "tga", "ico"]
    property string status: "idle"        // idle | busy | done | error
    property var results: []              // ultimas conversoes [{ in, out, ok, err }]
    readonly property bool small: cols * rows <= 1

    function convert(paths) {
        const files = paths.filter(p => imgExt.indexOf(p.split(".").pop().toLowerCase()) >= 0)
        if (!files.length) { status = "error"; results = [{ ok: false, err: "Nenhuma imagem nos arquivos soltos." }]; back.restart(); return }
        if (proc.running) return
        status = "busy"; results = []
        proc.command = ["python3", script, o("format"), String(o("quality")), o("where"), o("keep") ? "1" : "0", o("merge") && o("format") === "pdf" && files.length > 1 ? "merge" : "single"].concat(files)
        proc.running = true
    }
    Process {
        id: proc
        stdout: SplitParser { onRead: line => { try { w.results = w.results.concat([JSON.parse(line)]) } catch (e) {} } }
        onExited: code => {
            w.status = code === 0 && w.results.some(r => r.ok) ? "done" : "error"
            const ok = w.results.filter(r => r.ok).length
            if (ok) Quickshell.execDetached(["notify-send", "-a", "Conversor", "-i", w.results.find(r => r.ok).out, ok + (ok > 1 ? " imagens convertidas" : " imagem convertida"), w.results.find(r => r.ok).out.replace(/\/[^/]*$/, "")])
            back.restart()
        }
    }
    Timer { id: back; interval: 9000; onTriggered: if (w.status !== "busy") w.status = "idle" }

    // ---- area de soltar ----
    Rectangle {
        id: zone
        anchors.fill: parent
        radius: Math.min(22, Math.min(width, height) * 0.16)
        color: drop.containsDrag ? Qt.rgba(w.ac.r, w.ac.g, w.ac.b, 0.18) : Qt.rgba(w.fg.r, w.fg.g, w.fg.b, zm.containsMouse ? 0.07 : 0.03)
        border.width: 2
        border.color: drop.containsDrag ? w.ac : Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.18)
        Behavior on color { ColorAnimation { duration: 160 } }
        // borda tracejada desenhada por cima (Rectangle nao faz tracejado)
        Canvas {
            anchors.fill: parent
            visible: !drop.containsDrag
            readonly property var deps: [w.fg, width, height, zone.radius]
            onDepsChanged: requestPaint()
            onPaint: {
                const c = getContext("2d"); c.reset()
                c.strokeStyle = Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.35); c.lineWidth = 2; c.setLineDash([6, 6])
                const r = zone.radius, W = width - 2, H = height - 2
                c.beginPath(); c.roundedRect(1, 1, W, H, r, r); c.stroke()
            }
        }
        MouseArea {
            id: zm
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Pick.image("Imagem para converter", p => w.convert([p]))
        }
        DropArea {
            id: drop
            anchors.fill: parent
            keys: ["text/uri-list"]
            onDropped: d => { if (d.hasUrls) { w.convert(d.urls.map(u => decodeURIComponent(u.toString().replace(/^file:\/\//, "")))); d.acceptProposedAction() } }
        }
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - 24
        spacing: w.small ? 4 : 10
        // icone que pula ao arrastar por cima / gira convertendo
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: w.small ? 38 : 54; height: width; radius: width * 0.32
            color: w.status === "error" ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.2) : Qt.rgba(w.ac.r, w.ac.g, w.ac.b, 0.2)
            scale: drop.containsDrag ? 1.15 : 1
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
            LoadingBlob { anchors.centerIn: parent; size: parent.width; visible: w.status === "busy"; running: visible; color: w.ac; bg: "transparent"; showBg: false }
            UiIcon {
                visible: w.status !== "busy"
                anchors.centerIn: parent
                name: w.status === "busy" ? "refresh" : w.status === "done" ? "check" : w.status === "error" ? "info" : "fileSwap"
                size: parent.width * 0.48
                color: w.status === "error" ? Theme.danger : w.ac
                
            }
        }
        UiText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            text: drop.containsDrag ? "Solte para converter em " + w.o("format").toUpperCase()
                : w.status === "busy" ? "Convertendo…"
                : w.status === "done" ? (w.results.filter(r => r.ok).length + " pronta(s)" + (w.results.some(r => !r.ok) ? ", " + w.results.filter(r => !r.ok).length + " com erro" : ""))
                : w.status === "error" ? (w.results.length && w.results[0].err ? w.results[0].err : "Não deu para converter")
                : w.small ? w.o("format").toUpperCase() : "Solte imagens aqui"
            color: w.status === "error" ? Theme.danger : w.fg
            font.pixelSize: w.small ? 12 : 15; font.weight: Font.DemiBold
        }
        // formatos: troca rapida sem abrir as opcoes
        Row {
            visible: !w.small && w.status !== "busy"
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4
            Repeater {
                model: w.formats
                delegate: Rectangle {
                    required property string modelData
                    readonly property bool on: w.o("format") === modelData
                    width: fl.implicitWidth + 14; height: 22; radius: 11
                    color: on ? w.ac : (fm.containsMouse ? Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.12) : Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.06))
                    UiText { id: fl; anchors.centerIn: parent; text: modelData.toUpperCase(); color: parent.on ? Theme.accentText : w.dim; font.pixelSize: 10; font.weight: Font.Bold }
                    MouseArea { id: fm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (w.wid !== "") DeskState.setOpt(w.wid, "format", modelData) }
                }
            }
        }
        // ultimos resultados (clique abre a pasta)
        Column {
            visible: w.rows >= 2 && w.status === "done"
            width: parent.width
            spacing: 2
            Repeater {
                model: w.results.filter(r => r.ok).slice(-3)
                delegate: Rectangle {
                    required property var modelData
                    width: parent.width; height: 24; radius: 8
                    color: rm.containsMouse ? Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.1) : "transparent"
                    Row {
                        anchors { left: parent.left; leftMargin: 8; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        spacing: 6
                        UiIcon { name: "folderOpen"; size: 13; color: w.ac; anchors.verticalCenter: parent.verticalCenter }
                        UiText { width: parent.width - 20; elide: Text.ElideMiddle; text: modelData.out.split("/").pop(); color: w.dim; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["xdg-open", modelData.out.replace(/\/[^/]*$/, "")]) }
                }
            }
        }
    }
}
