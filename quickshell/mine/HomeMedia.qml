// Aba "Midia": capa grande, faixa, barra de progresso (arrastavel), controles e escolha do player.
import Quickshell.Services.Mpris
import QtQuick

Item {
    id: pg
    property var home
    readonly property var pl: home.player

    Timer { interval: 1000; repeat: true; running: !!pg.pl && pg.pl.isPlaying; onTriggered: pg.pl.positionChanged() }

    HomeCard {
        id: card
        anchors.fill: parent
        anchors.bottomMargin: pg.home.players.length > 1 ? 52 : 0

        RoundImage {   // capa desfocada de fundo
            parent: card
            x: 1; y: 1; width: card.width - 2; height: card.height - 2; radius: 13
            visible: !!pg.pl
            source: pg.pl ? pg.pl.trackArtUrl : ""
            sourceSize: Qt.size(300, 300)
            blur: 1; dim: 0.6
        }

        Column {
            visible: !pg.pl
            anchors.centerIn: parent
            spacing: 10
            UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "music"; size: 46; color: Theme.muted }
            UiText { anchors.horizontalCenter: parent.horizontalCenter; text: "Nada tocando"; color: Theme.muted; font.pixelSize: 14 }
        }

        Item {
            visible: !!pg.pl
            anchors.fill: parent
            anchors.margins: 6

            RoundImage {
                id: art
                anchors.horizontalCenter: parent.horizontalCenter
                y: 4
                width: Math.min(220, parent.height - 190); height: width; radius: 16
                source: pg.pl ? pg.pl.trackArtUrl : ""
                sourceSize: Qt.size(440, 440)
            }
            Rectangle { visible: !art.ready; anchors.fill: art; radius: 16; color: Theme.track; UiIcon { anchors.centerIn: parent; name: "music"; size: 56; color: Theme.muted } }

            Column {
                id: info
                anchors { top: art.bottom; topMargin: 16; left: parent.left; right: parent.right }
                spacing: 3
                UiText { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: pg.pl ? pg.pl.trackTitle : ""; color: "white"; font.pixelSize: 17; font.weight: Font.Bold; elide: Text.ElideRight }
                UiText { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: pg.pl ? [pg.pl.trackArtist, pg.pl.trackAlbum].filter(x => !!x).join(" · ") : ""; color: Qt.rgba(1, 1, 1, 0.72); font.pixelSize: 13; elide: Text.ElideRight }
            }

            // ---- progresso ----
            Item {
                id: prog
                anchors { top: info.bottom; topMargin: 16; left: parent.left; right: parent.right; leftMargin: 24; rightMargin: 24 }
                height: 34
                visible: !!pg.pl && pg.pl.lengthSupported && pg.pl.length > 0
                property real dragV: -1
                readonly property real r: dragV >= 0 ? dragV : (pg.pl && pg.pl.length > 0 ? Math.max(0, Math.min(1, pg.pl.position / pg.pl.length)) : 0)
                Item {
                    id: bar
                    width: parent.width; height: 16
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; radius: 3; color: Qt.rgba(1, 1, 1, 0.18) }
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Math.max(6, parent.width * prog.r); height: 6; radius: 3; color: Theme.accent }
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; x: parent.width * prog.r - 7; width: 14; height: 14; radius: 7; color: "white"; visible: pg.pl && pg.pl.canSeek }
                    MouseArea {
                        anchors.fill: parent; anchors.margins: -6
                        enabled: !!pg.pl && pg.pl.canSeek
                        cursorShape: Qt.PointingHandCursor
                        function at(x) { return Math.max(0, Math.min(1, (x - 6) / bar.width)) }
                        onPressed: m => prog.dragV = at(m.x)
                        onPositionChanged: m => { if (pressed) prog.dragV = at(m.x) }
                        onReleased: { pg.pl.position = prog.dragV * pg.pl.length; prog.dragV = -1 }
                    }
                }
                UiText { anchors { left: parent.left; bottom: parent.bottom } text: pg.home.fmt(prog.r * (pg.pl ? pg.pl.length : 0)); color: Qt.rgba(1, 1, 1, 0.7); font.pixelSize: 11 }
                UiText { anchors { right: parent.right; bottom: parent.bottom } text: pg.pl ? pg.home.fmt(pg.pl.length) : ""; color: Qt.rgba(1, 1, 1, 0.7); font.pixelSize: 11 }
            }

            // ---- controles ----
            Row {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 4 }
                spacing: 14
                component CBtn: Rectangle {
                    id: cb
                    property string icon
                    property bool main: false
                    property bool active: false
                    signal clicked()
                    anchors.verticalCenter: parent.verticalCenter
                    width: main ? 56 : 40; height: width; radius: main ? 18 : 20
                    color: main ? Theme.accent : (cbm.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent")
                    UiIcon { anchors.centerIn: parent; name: cb.icon; size: cb.main ? 26 : 20; color: cb.main ? Theme.accentText : (cb.active ? Theme.accent : "white") }
                    MouseArea { id: cbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cb.clicked() }
                }
                CBtn {
                    icon: "shuffle"; visible: !!pg.pl && pg.pl.shuffleSupported; active: !!pg.pl && pg.pl.shuffle
                    onClicked: pg.pl.shuffle = !pg.pl.shuffle
                }
                CBtn { icon: "prev"; onClicked: if (pg.pl && pg.pl.canGoPrevious) pg.pl.previous() }
                CBtn { main: true; icon: pg.pl && pg.pl.isPlaying ? "pause" : "play"; onClicked: if (pg.pl && pg.pl.canTogglePlaying) pg.pl.togglePlaying() }
                CBtn { icon: "next"; onClicked: if (pg.pl && pg.pl.canGoNext) pg.pl.next() }
                CBtn {
                    visible: !!pg.pl && pg.pl.loopSupported
                    icon: pg.pl && pg.pl.loopState === MprisLoopState.None ? "repeatOff" : "repeat"
                    active: !!pg.pl && pg.pl.loopState !== MprisLoopState.None
                    onClicked: pg.pl.loopState = pg.pl.loopState === MprisLoopState.None ? MprisLoopState.Playlist : (pg.pl.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None)
                }
            }
        }
    }

    // ---- escolha do player (so com mais de um) ----
    Flow {
        visible: pg.home.players.length > 1
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 42
        spacing: 6
        Repeater {
            model: pg.home.players
            delegate: UiButton {
                required property var modelData
                required property int index
                icon: modelData.isPlaying ? "play" : "pause"
                text: modelData.identity || ("Player " + (index + 1))
                checked: pg.pl === modelData
                onClicked: pg.home.playerPick = index
            }
        }
    }
}
