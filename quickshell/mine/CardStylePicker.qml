// Escolha do fundo do widget em miniaturas: cada opcao desenha um cartao pequeno sobre um "wallpaper" de faixas.
import QtQuick

Flow {
    id: cs
    property string value: "auto"
    property bool withAuto: true
    signal picked(string v)
    spacing: 6
    Repeater {
        model: cs.withAuto ? [["auto", "Padrão"], ["card", "Cartão"], ["glass", "Vidro"], ["frost", "Fosco"], ["none", "Sem fundo"]] : [["card", "Cartão"], ["glass", "Vidro"], ["frost", "Fosco"], ["none", "Sem fundo"]]
        delegate: Rectangle {
            id: tile
            required property var modelData
            readonly property bool on: cs.value === modelData[0]
            readonly property string st: modelData[0]
            width: cs.withAuto ? (cs.width - 4 * 6) / 5 : (cs.width - 3 * 6) / 4
            height: 62; radius: 10
            color: on ? Theme.tint(0.14) : (tm.containsMouse ? Theme.cardHi : Theme.track)
            border.width: on ? 2 : 1; border.color: on ? Theme.accent : Theme.border
            // mini wallpaper
            Rectangle {
                id: wall
                x: 5; y: 5; width: parent.width - 10; height: 32; radius: 6; clip: true
                gradient: Gradient { orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.85) }
                    GradientStop { position: 0.5; color: Theme.family("secondary").main }
                    GradientStop { position: 1; color: Theme.family("tertiary").main } }
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.64; height: 20; radius: 5
                    visible: tile.st !== "none"
                    color: tile.st === "glass" ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.34)
                        : tile.st === "frost" ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.48)
                        : Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.92)
                    border.width: 1
                    border.color: tile.st === "glass" ? Qt.rgba(1, 1, 1, 0.5) : tile.st === "frost" ? Qt.rgba(1, 1, 1, 0.3) : Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, 0.8)
                    // fosco: faixas desfocadas por baixo do cartao
                    Rectangle { visible: tile.st === "frost"; anchors { fill: parent; margins: 3 } radius: 3; color: Qt.rgba(1, 1, 1, 0.12) }
                    Rectangle { x: 5; y: parent.height / 2 - 1; width: parent.width * 0.5; height: 2; radius: 1; color: Theme.text; opacity: 0.7 }
                }
                // sem fundo: so o texto solto
                Rectangle { visible: tile.st === "none"; anchors.centerIn: parent; width: parent.width * 0.4; height: 3; radius: 1.5; color: "white" }
            }
            UiText { anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 4 } text: tile.modelData[1]
                color: tile.on ? Theme.accent : Theme.muted; font.pixelSize: 11; font.weight: Font.DemiBold }
            MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: cs.picked(tile.modelData[0]) }
        }
    }
}
