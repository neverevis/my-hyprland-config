// Mapa ao vivo da tela: a moldura e todas as barras (posicao real, vinda da geometria). Clique numa barra para escolher.
// A barra escolhida aparece em destaque com as secoes dela; barras sem espaco aparecem tracejadas.
import Quickshell
import QtQuick

Item {
    id: map
    property var geo
    property int selected: 0
    property int selectedSec: -1
    signal picked(int i)

    readonly property var scr: Quickshell.screens[0]
    readonly property real sw: scr ? scr.width : 1920
    readonly property real sh: scr ? scr.height : 1080
    readonly property real k: Math.min(width / sw, 190 / sh)
    height: sh * k + 8

    Rectangle {
        id: screenBox
        anchors.horizontalCenter: parent.horizontalCenter
        width: map.sw * map.k; height: map.sh * map.k
        radius: 10
        color: Theme.track
        border.width: 1; border.color: Theme.border
        clip: true
        // wallpaper bem apagado ao fundo
        Image {
            anchors.fill: parent
            source: Wallpaper.current !== "" ? "file://" + Wallpaper.current : ""
            sourceSize: Qt.size(480, 270)
            fillMode: Image.PreserveAspectCrop
            opacity: 0.22
            asynchronous: true
        }
        // moldura (faixa fina)
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: Math.max(1, Settings.edge * map.k)
            border.color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.35)
            radius: 10
        }
        Repeater {
            model: Settings.bars.length
            delegate: Item {
                id: bi
                required property int index
                readonly property var info: map.geo && map.geo.bars ? map.geo.bars[index] : null
                readonly property bool on: map.selected === index
                readonly property var b: Settings.bars[index] ?? ({})
                visible: !!info
                // retangulo real da barra (a solta fica afastada da borda)
                readonly property real d0: info && info.detached ? info.v0 : 0
                readonly property real d1: info ? info.t : 0
                readonly property bool vert: info ? info.vertical : false
                x: !info ? 0 : (info.side === "right" ? (map.sw - d1) * map.k : (info.side === "left" ? d0 * map.k : info.lo * map.k))
                y: !info ? 0 : (info.side === "bottom" ? (map.sh - d1) * map.k : (info.side === "top" ? d0 * map.k : info.lo * map.k))
                width: !info ? 0 : (vert ? (d1 - d0) * map.k : (info.hi - info.lo) * map.k)
                height: !info ? 0 : (vert ? (info.hi - info.lo) * map.k : (d1 - d0) * map.k)
                z: on ? 2 : 1
                Rectangle {
                    anchors.fill: parent
                    radius: Math.min(width, height) / 3
                    color: bi.info && bi.info.hidden ? "transparent" : (bi.on ? Theme.accent : (bm.containsMouse ? Theme.cardHi : Theme.card))
                    border.width: bi.on ? 0 : 1
                    border.color: bi.info && bi.info.hidden ? Theme.danger : Theme.border
                    opacity: bi.info && bi.info.hidden ? 0.8 : 1
                    Behavior on color { ColorAnimation { duration: 140 } }
                }
                // numero de prioridade
                Rectangle {
                    anchors.centerIn: parent
                    width: 15; height: 15; radius: 7.5
                    color: bi.on ? Theme.accentText : Theme.bg
                    UiText { anchors.centerIn: parent; text: bi.index + 1; color: bi.on ? Theme.accent : Theme.muted; font.pixelSize: 9; font.weight: Font.Bold }
                }
                MouseArea { id: bm; anchors.fill: parent; anchors.margins: -3; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: map.picked(bi.index) }
            }
        }
    }
}
