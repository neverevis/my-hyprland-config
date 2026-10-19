// Seletor segmentado: options = [[valor, rotulo, icone?], ...]; a opcao escolhida ganha uma pilula que desliza.
// fill: true estica para a largura do pai (cada opcao com a mesma largura).
import QtQuick

Rectangle {
    id: s
    property var options: []
    property var value
    property bool fill: false
    signal picked(var v)

    readonly property int cur: options.findIndex(o => o[0] === value)
    width: fill && parent ? parent.width : row.implicitWidth + 8
    height: 36
    radius: 10
    color: Theme.track
    border.width: 1
    border.color: Theme.border

    Rectangle {
        id: pill
        readonly property Item it: (rep.count, s.cur >= 0 ? rep.itemAt(s.cur) : null)
        visible: !!it
        x: it ? row.x + it.x : 4
        width: it ? it.width : 0
        y: 4; height: parent.height - 8; radius: 7
        color: Theme.accent
        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }

    Row {
        id: row
        x: 4; y: 4
        height: parent.height - 8
        Repeater {
            id: rep
            model: s.options
            delegate: Item {
                id: opt
                required property var modelData
                required property int index
                readonly property bool on: index === s.cur
                width: s.fill ? (s.width - 8) / Math.max(1, s.options.length) : content.implicitWidth + 26
                height: row.height
                Rectangle { anchors.fill: parent; radius: 7; color: Theme.cardHi; opacity: !opt.on && ma.containsMouse ? 0.7 : 0; Behavior on opacity { NumberAnimation { duration: 120 } } }
                Row {
                    id: content
                    anchors.centerIn: parent
                    spacing: 6
                    UiIcon {
                        visible: !!opt.modelData[2]
                        anchors.verticalCenter: parent.verticalCenter
                        name: opt.modelData[2] ?? ""
                        size: 16
                        color: opt.on ? Theme.accentText : (ma.containsMouse ? Theme.text : Theme.muted)
                    }
                    UiText {
                        visible: String(opt.modelData[1]) !== ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: opt.modelData[1]
                        font.pixelSize: 13
                        font.weight: opt.on ? Font.DemiBold : Font.Medium
                        color: opt.on ? Theme.accentText : (ma.containsMouse ? Theme.text : Theme.muted)
                    }
                }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: s.picked(opt.modelData[0]) }
            }
        }
    }
}
