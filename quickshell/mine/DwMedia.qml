// Widget de midia (MPRIS): capa desfocada ao fundo, capa, titulo, artista, progresso e controles.
// 1x1: capa com o botao de tocar; 2x1/3x1: capa ao lado das informacoes; 2x2: capa grande em cima.
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Item {
    id: w
    property int cols: 2
    property int rows: 1
    property var opts: ({})
    readonly property var p: Mpris.players.values.find(x => x.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property string art: p ? (p.trackArtUrl ?? "") : ""
    readonly property real prog: p && p.length > 0 ? Math.max(0, Math.min(1, p.position / p.length)) : 0
    Timer { interval: 1000; repeat: true; running: !!w.p && w.p.isPlaying; onTriggered: if (w.p) w.p.positionChanged() }

    // fundo: a capa bem desfocada e escura (o cartao ganha a cor da musica)
    RoundImage {
        x: -16; y: -16; width: parent.width + 32; height: parent.height + 32
        radius: Math.min(30, Math.min(width, height) * 0.2)
        source: w.art; sourceSize: Qt.size(128, 128)
        blur: 1; dim: 0.45
        opacity: ready ? 0.9 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    // sem player
    Column {
        visible: !w.p
        anchors.centerIn: parent
        spacing: 6
        UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "music"; size: 30; color: Theme.muted }
        Text { visible: w.cols > 1; anchors.horizontalCenter: parent.horizontalCenter; text: "Nada tocando"; color: Theme.muted; font.pixelSize: 13 }
    }

    Item {
        visible: !!w.p
        anchors.fill: parent
        readonly property bool tall: w.rows > 1
        readonly property bool tiny: w.cols === 1 && w.rows === 1

        RoundImage {
            id: cover
            readonly property real s: parent.tiny ? Math.min(parent.width, parent.height) : (parent.tall ? Math.min(parent.width, parent.height * 0.55) : parent.height)
            width: s; height: s
            x: parent.tall || parent.tiny ? (parent.width - s) / 2 : 0
            y: parent.tiny ? (parent.height - s) / 2 : 0
            radius: 16
            source: w.art; sourceSize: Qt.size(256, 256)
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Rectangle { anchors.fill: parent; radius: 16; visible: !parent.ready; color: Theme.tint(0.15)
                UiIcon { anchors.centerIn: parent; name: "music"; size: parent.width * 0.35; color: Theme.accent } }
        }
        // 1x1: botao de tocar por cima da capa
        Rectangle {
            visible: parent.tiny
            anchors.centerIn: cover
            width: 52; height: 52; radius: 26
            color: Qt.rgba(0, 0, 0, 0.5)
            UiIcon { anchors.centerIn: parent; name: w.p && w.p.isPlaying ? "pause" : "play"; size: 26; color: "white" }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (w.p) w.p.togglePlaying() }
        }

        Column {
            visible: !parent.tiny
            anchors {
                left: parent.tall ? parent.left : cover.right; leftMargin: parent.tall ? 0 : 16
                right: parent.right
                top: parent.tall ? cover.bottom : undefined; topMargin: 12
                verticalCenter: parent.tall ? undefined : parent.verticalCenter
            }
            spacing: 4
            Text { width: parent.width; elide: Text.ElideRight; horizontalAlignment: parent.parent.tall ? Text.AlignHCenter : Text.AlignLeft
                text: w.p ? (w.p.trackTitle || w.p.identity) : ""; color: "white"; font.pixelSize: w.cols >= 3 ? 18 : 16; font.weight: Font.Bold }
            Text { width: parent.width; elide: Text.ElideRight; horizontalAlignment: parent.parent.tall ? Text.AlignHCenter : Text.AlignLeft
                text: w.p ? (w.p.trackArtist || "") : ""; color: Qt.rgba(1, 1, 1, 0.7); font.pixelSize: 13 }
            Item { width: 1; height: 6 }
            Rectangle {   // progresso
                width: parent.width; height: 4; radius: 2
                color: Qt.rgba(1, 1, 1, 0.18)
                Rectangle { width: parent.width * w.prog; height: parent.height; radius: 2; color: Theme.accent
                    Behavior on width { NumberAnimation { duration: 900 } } }
            }
            Item { width: 1; height: 4 }
            Row {
                anchors.horizontalCenter: parent.parent.tall ? parent.horizontalCenter : undefined
                spacing: 6
                Repeater {
                    model: [["prev", () => w.p.previous()], [w.p && w.p.isPlaying ? "pause" : "play", () => w.p.togglePlaying()], ["next", () => w.p.next()]]
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: index === 1 ? 40 : 34; height: width; radius: width / 2
                        color: index === 1 ? Theme.accent : (bm.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08))
                        UiIcon { anchors.centerIn: parent; name: modelData[0]; size: index === 1 ? 20 : 17; color: index === 1 ? Theme.accentText : "white" }
                        MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (w.p) modelData[1]() }
                    }
                }
            }
        }
    }
}
