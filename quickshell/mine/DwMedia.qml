// Widget de midia (MPRIS): capa com forma (arredondada, circulo, flor, quadrada; pode girar como disco), titulo,
// progresso, controles, fundo com a capa desfocada e letra sincronizada (Lyrics.qml).
// 1x1: capa com o botao de tocar; 2x1/3x1: capa ao lado das informacoes; 2x2/3x2: capa em cima (+ letra).
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Item {
    id: w
    property int cols: 2
    property int rows: 1
    property var opts: ({})
    property color fg: Theme.text
    property color dim: Theme.muted
    property color ac: Theme.accent
    property color ac2: Theme.tertiary            // cor companheira (o DeskView passa a do tom escolhido)
    property color cont: Theme.primaryContainer
    property color contInk: Theme.primaryContainerInk
    property bool bare: false
    function o(k) { return DeskState.opt({ type: "media", opts: w.opts }, k) }
    readonly property bool lyr: o("lyrics")
    onLyrChanged: lyr ? Lyrics.use() : Lyrics.release()
    Component.onCompleted: if (lyr) Lyrics.use()
    Component.onDestruction: if (lyr) Lyrics.release()

    readonly property var p: Mpris.players.values.find(x => x.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property string art: p ? (p.trackArtUrl ?? "") : ""
    readonly property real prog: p && p.length > 0 ? Math.max(0, Math.min(1, p.position / p.length)) : 0
    Timer { interval: 1000; repeat: true; running: !!w.p && w.p.isPlaying; onTriggered: if (w.p) w.p.positionChanged() }
    // com a capa desfocada no fundo, o texto e claro
    readonly property bool overArt: o("blurBg") && !bare && art !== ""
    readonly property color tfg: overArt ? "white" : w.fg
    readonly property color tdim: overArt ? Qt.rgba(1, 1, 1, 0.7) : w.dim

    RoundImage {
        visible: w.overArt
        x: -18; y: -18; width: parent.width + 36; height: parent.height + 36
        radius: Math.min(30, Math.min(width, height) * 0.2)
        source: w.art; sourceSize: Qt.size(128, 128)
        blur: 1; dim: 0.45
        opacity: ready ? 0.9 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }
    Column {
        visible: !w.p
        anchors.centerIn: parent
        spacing: 6
        UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "music"; size: 30; color: w.dim }
        UiText { visible: w.cols > 1; anchors.horizontalCenter: parent.horizontalCenter; text: "Nada tocando"; color: w.dim; font.pixelSize: 13 }
    }
    Item {
        id: body
        visible: !!w.p
        anchors.fill: parent
        readonly property bool tall: w.rows > 1
        readonly property bool tiny: w.cols === 1 && w.rows === 1
        readonly property bool lyrBox: w.lyr && tall && w.rows >= 2 && w.cols >= 3
        readonly property real coverS: tiny ? Math.min(width, height) : (tall ? Math.min(lyrBox ? width * 0.42 : width, height * (lyrBox ? 0.62 : 0.55)) : height)
        ShapedImage {
            id: cover
            width: body.coverS; height: body.coverS
            x: body.lyrBox ? 0 : (body.tall || body.tiny ? (body.width - width) / 2 : 0)
            y: body.tiny ? (body.height - height) / 2 : 0
            shape: w.o("artShape"); sides: 12
            source: w.art; sourceSize: Qt.size(384, 384)
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            NumberAnimation on spin { running: w.o("spin") && !!w.p && w.p.isPlaying; from: 0; to: 360; duration: 14000; loops: Animation.Infinite }
            Flower { anchors.fill: parent; visible: !parent.ready; shape: parent.shape; color: w.bare ? w.cont : Qt.rgba(w.ac.r, w.ac.g, w.ac.b, 0.2)
                UiIcon { anchors.centerIn: parent; name: "music"; size: parent.width * 0.35; color: w.ac } }
        }
        Rectangle {
            visible: body.tiny
            anchors.centerIn: cover
            width: 52; height: 52; radius: 26
            color: Qt.rgba(0, 0, 0, 0.5)
            UiIcon { anchors.centerIn: parent; name: w.p && w.p.isPlaying ? "pause" : "play"; size: 26; color: "white" }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (w.p) w.p.togglePlaying() }
        }
        Column {
            id: info
            visible: !body.tiny
            readonly property bool center: body.tall && !body.lyrBox
            anchors {
                left: body.tall && !body.lyrBox ? parent.left : cover.right; leftMargin: body.tall && !body.lyrBox ? 0 : 16
                right: parent.right
                top: body.tall && !body.lyrBox ? cover.bottom : undefined; topMargin: 12
                verticalCenter: body.tall && !body.lyrBox ? undefined : cover.verticalCenter
            }
            spacing: 4
            UiText { visible: w.o("titles"); width: parent.width; elide: Text.ElideRight; horizontalAlignment: info.center ? Text.AlignHCenter : Text.AlignLeft
                text: w.p ? (w.p.trackTitle || w.p.identity) : ""; color: w.tfg; font.pixelSize: w.cols >= 3 ? 18 : 16; font.weight: Font.Bold }
            UiText { visible: w.o("titles"); width: parent.width; elide: Text.ElideRight; horizontalAlignment: info.center ? Text.AlignHCenter : Text.AlignLeft
                // 3x1 com letra: a linha atual no lugar do artista
                text: w.lyr && !body.tall && Lyrics.index >= 0 && !Lyrics.plain ? "♪ " + Lyrics.lines[Lyrics.index].text : (w.p ? (w.p.trackArtist || "") : "")
                color: w.lyr && !body.tall && Lyrics.index >= 0 ? w.ac : w.tdim; font.pixelSize: 13 }
            Item { width: 1; height: 4 }
            Rectangle {
                width: parent.width; height: 4; radius: 2
                color: Qt.rgba(w.tfg.r, w.tfg.g, w.tfg.b, 0.18)
                Rectangle { width: parent.width * w.prog; height: parent.height; radius: 2; color: w.ac
                    Behavior on width { NumberAnimation { duration: 900 } } }
            }
            Item { width: 1; height: 4 }
            Row {
                visible: w.o("controls")
                anchors.horizontalCenter: info.center ? parent.horizontalCenter : undefined
                spacing: 6
                Repeater {
                    model: [["prev", () => w.p.previous()], [w.p && w.p.isPlaying ? "pause" : "play", () => w.p.togglePlaying()], ["next", () => w.p.next()]]
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: index === 1 ? 40 : 34; height: width; radius: width / 2
                        color: index === 1 ? w.ac : (bm.containsMouse ? Qt.rgba(w.tfg.r, w.tfg.g, w.tfg.b, 0.16) : Qt.rgba(w.tfg.r, w.tfg.g, w.tfg.b, 0.08))
                        UiIcon { anchors.centerIn: parent; name: modelData[0]; size: index === 1 ? 20 : 17; color: index === 1 ? Theme.accentText : w.tfg }
                        MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (w.p) modelData[1]() }
                    }
                }
            }
        }
        // letra (3x2 ou maior): linhas rolando, a atual em destaque
        ListView {
            id: lyrics
            visible: body.lyrBox
            anchors { left: parent.left; right: parent.right; top: cover.bottom; topMargin: 12; bottom: parent.bottom }
            clip: true
            interactive: false
            model: Lyrics.lines
            spacing: 4
            currentIndex: Math.max(0, Lyrics.index)
            highlightRangeMode: ListView.ApplyRange
            preferredHighlightBegin: height * 0.3; preferredHighlightEnd: height * 0.5
            highlightMoveDuration: 400
            delegate: UiText {
                required property var modelData
                required property int index
                width: lyrics.width; wrapMode: Text.WordWrap
                text: modelData.text
                color: index === Lyrics.index ? w.ac : w.tdim
                font.pixelSize: index === Lyrics.index ? 15 : 13; font.weight: index === Lyrics.index ? Font.Bold : Font.Normal
                Behavior on color { ColorAnimation { duration: 250 } }
            }
            UiText { visible: lyrics.count === 0; anchors.centerIn: parent; text: Lyrics.status === "buscando" ? "Buscando a letra…" : "Sem letra para esta música"; color: w.tdim; font.pixelSize: 12 }
        }
    }
}
