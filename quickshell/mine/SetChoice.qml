// SetChoice: escolher uma opcao entre poucas. options = [[valor, rotulo, icone], ...] (como o UiSeg); picked(v).
// - style "seg" (padrao): seletor segmentado no fim da linha. iconsOnly: so os icones (rotulo vira dica de busca).
// - style "tiles": grade de cartoes visuais abaixo do nome (miniatura + rotulo, borda e selo no escolhido).
//   thumb: Component da miniatura; a raiz dele declara  property var opt; property bool on; property bool hovered
//   (opt = a opcao, hovered = mouse em cima: anime SO enquanto hovered). Sem thumb, mostra o icone grande.
//   label vazio tira a linha do nome (so a grade). minTile/thumbHeight ajustam a grade.
// Exemplo:  SetChoice { icon: "themeAuto"; label: "Modo"; style: "tiles"; options: [["dark", "Escuro", "night"], ["light", "Claro", "sun"]]
//                       value: Settings.themeMode; onPicked: v => Settings.themeMode = v }
import QtQuick

SetRow {
    id: c
    property var options: []
    property var value
    property string style: "seg"
    property bool iconsOnly: false
    property Component thumb: null
    property int minTile: 116
    property int thumbHeight: 58
    property int columns: 0
    signal picked(var v)

    readonly property bool tiles: style === "tiles"
    readonly property bool noHead: tiles && label === ""
    headless: noHead

    // seletor segmentado no fim da linha
    UiSeg {
        visible: !c.tiles
        options: c.iconsOnly ? c.options.map(o => [o[0], "", o[2]]) : c.options
        value: c.value
        onPicked: v => c.picked(v)
    }

    below: Grid {
        id: grid
        visible: c.tiles
        width: parent ? parent.width : 300
        readonly property int gap: SetK.sm
        readonly property int cols: c.columns > 0 ? c.columns : Math.max(2, Math.min(c.options.length, Math.floor((width + gap) / (c.minTile + gap))))
        readonly property real tw: (width - gap * (cols - 1)) / cols
        columns: cols
        spacing: gap
        Repeater {
            model: c.tiles ? c.options : []
            delegate: Item {
                id: tile
                required property var modelData
                readonly property bool on: c.value === modelData[0]
                width: grid.tw
                height: c.thumbHeight + 30
                Rectangle {
                    id: frame
                    width: parent.width; height: c.thumbHeight
                    radius: 12
                    color: tile.on ? Theme.tint(0.16) : Theme.track
                    border.width: tile.on ? 2 : 1
                    border.color: tile.on ? Theme.accent : (tm.containsMouse ? Theme.tint(0.5) : Theme.border)
                    clip: true
                    scale: tm.pressed ? 0.97 : 1
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    UiIcon {
                        visible: !c.thumb
                        anchors.centerIn: parent
                        name: tile.modelData[2] ?? ""
                        size: 22
                        color: tile.on ? Theme.accent : (tm.containsMouse ? Theme.text : Theme.muted)
                    }
                    Loader {
                        id: th
                        anchors.fill: parent
                        anchors.margins: 2
                        active: !!c.thumb
                        sourceComponent: c.thumb
                    }
                    Binding { target: th.item; property: "opt"; value: tile.modelData; when: !!th.item }
                    Binding { target: th.item; property: "on"; value: tile.on; when: !!th.item }
                    Binding { target: th.item; property: "hovered"; value: tm.containsMouse; when: !!th.item }
                    Rectangle {
                        visible: tile.on
                        anchors { right: parent.right; top: parent.top; margins: 6 }
                        width: 18; height: 18; radius: 9; color: Theme.accent
                        UiIcon { anchors.centerIn: parent; name: "check"; size: 12; color: Theme.accentText }
                    }
                }
                UiText {
                    anchors { top: frame.bottom; topMargin: 6; left: parent.left; right: parent.right }
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: tile.modelData[1]
                    color: tile.on ? Theme.text : Theme.muted
                    font.pixelSize: SetK.fDesc
                    font.weight: tile.on ? Font.DemiBold : Font.Medium
                }
                MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: c.picked(tile.modelData[0]) }
            }
        }
    }
}
