// Tamanho de um widget: cada opcao desenha a propria grade (colunas x linhas) e, com "free", ha +/- de largura e altura.
import QtQuick

Column {
    id: sp
    property var sizes: []
    property int cols: 1
    property int rows: 1
    property bool free: true
    signal picked(int c, int r)
    width: parent ? parent.width : 300
    spacing: 8

    Row {
        spacing: 8
        UiIcon { name: "resize"; size: 15; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
        UiText { text: "Tamanho"; color: Theme.text; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
        UiText { text: sp.cols + " × " + sp.rows; color: Theme.muted; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
    }
    Flow {
        width: sp.width
        spacing: 6
        Repeater {
            model: sp.sizes
            delegate: Rectangle {
                id: chip
                required property var modelData
                readonly property bool on: sp.cols === modelData[0] && sp.rows === modelData[1]
                readonly property real cell: 9
                width: Math.max(46, modelData[0] * (cell + 2) + 18); height: 3 * (cell + 2) + 22; radius: 10
                color: on ? Theme.tint(0.14) : (cm.containsMouse ? Theme.cardHi : Theme.track)
                border.width: on ? 2 : 1; border.color: on ? Theme.accent : Theme.border
                Grid {
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 7 + (3 - chip.modelData[1]) * (chip.cell + 2) / 2 }
                    columns: chip.modelData[0]
                    spacing: 2
                    Repeater {
                        model: chip.modelData[0] * chip.modelData[1]
                        Rectangle { width: chip.cell; height: chip.cell; radius: 2.5; color: chip.on ? Theme.accent : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.35) }
                    }
                }
                UiText { anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 3 } text: chip.modelData[0] + "×" + chip.modelData[1]
                    color: chip.on ? Theme.accent : Theme.muted; font.pixelSize: 10; font.weight: Font.DemiBold }
                MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sp.picked(chip.modelData[0], chip.modelData[1]) }
            }
        }
        // tamanho livre
        Repeater {
            model: sp.free ? [["cols", "Largura", "swap_horizontal"], ["rows", "Altura", "swap_vertical"]] : []
            delegate: Rectangle {
                id: fr
                required property var modelData
                height: 3 * 11 + 22; width: frow.implicitWidth + 12; radius: 10
                color: Theme.track; border.width: 1; border.color: Theme.border
                Column {
                    id: frow
                    anchors.centerIn: parent
                    spacing: 3
                    UiText { anchors.horizontalCenter: parent.horizontalCenter; text: fr.modelData[1]; color: Theme.muted; font.pixelSize: 10 }
                    Row {
                        spacing: 3
                        Repeater {
                            model: [-1, 1]
                            delegate: Rectangle {
                                required property var modelData
                                width: 24; height: 24; radius: 7
                                color: pm.containsMouse ? Theme.accent : Theme.cardHi
                                UiIcon { anchors.centerIn: parent; name: parent.modelData < 0 ? "minus" : "plus"; size: 12; color: pm.containsMouse ? Theme.accentText : Theme.text }
                                MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: fr.modelData[0] === "cols" ? sp.picked(sp.cols + parent.modelData, sp.rows) : sp.picked(sp.cols, sp.rows + parent.modelData) }
                            }
                        }
                    }
                }
            }
        }
    }
}
