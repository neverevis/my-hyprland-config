// Escolha do lado da tela com miniaturas: cada opcao desenha uma telinha com a faixa no lado correspondente.
import QtQuick

Row {
    id: sp
    property var sides: ["bottom", "top", "left", "right"]
    property string value
    signal picked(string v)
    spacing: 8

    readonly property var names: ({ top: "Cima", bottom: "Baixo", left: "Esquerda", right: "Direita" })

    Repeater {
        model: sp.sides
        delegate: Rectangle {
            id: t
            required property string modelData
            readonly property bool on: sp.value === modelData
            readonly property bool vert: modelData === "left" || modelData === "right"
            width: 84; height: 74; radius: 12
            color: on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14) : (m.containsMouse ? Theme.cardHi : Theme.track)
            border.width: 1
            border.color: on ? Theme.accent : Theme.border
            Behavior on color { enabled: !ThemeColors.fading; ColorAnimation { duration: 140 } }

            Rectangle {
                id: scr
                anchors.horizontalCenter: parent.horizontalCenter
                y: 11; width: 48; height: 32; radius: 6
                color: "transparent"
                border.width: 1.5
                border.color: t.on ? Theme.accent : Theme.muted
                Rectangle {
                    width: t.vert ? 6 : parent.width - 14
                    height: t.vert ? parent.height - 12 : 6
                    radius: 2
                    x: t.modelData === "left" ? 4 : (t.modelData === "right" ? parent.width - width - 4 : (parent.width - width) / 2)
                    y: t.modelData === "top" ? 4 : (t.modelData === "bottom" ? parent.height - height - 4 : (parent.height - height) / 2)
                    color: t.on ? Theme.accent : Theme.muted
                }
            }
            UiText {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 8 }
                text: sp.names[t.modelData] ?? t.modelData
                font.pixelSize: 12
                font.weight: t.on ? Font.DemiBold : Font.Normal
                color: t.on ? Theme.text : Theme.muted
            }
            MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sp.picked(t.modelData) }
        }
    }
}
