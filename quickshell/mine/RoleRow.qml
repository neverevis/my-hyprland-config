// Escolha de uma cor da paleta do tema (bordas do Hyprland, barras...): bolinhas com o nome embaixo.
// value = id do papel (ver ThemeColors.roles); allowNone acrescenta "Nenhuma" (valor "").
import QtQuick

Column {
    id: rr
    property string label: ""
    property string value: "primary"
    property bool allowNone: false
    property var roles: ["primary", "secondary", "tertiary", "primaryContainer", "secondaryContainer", "tertiaryContainer", "outline", "surfaceHigh", "text"]
    signal picked(string v)
    width: parent ? parent.width : 400
    spacing: 6

    UiText { visible: rr.label !== ""; text: rr.label; color: Theme.text; font.pixelSize: 13 }
    Flow {
        width: rr.width
        spacing: 4
        Repeater {
            model: (rr.allowNone ? [""] : []).concat(rr.roles)
            delegate: Item {
                id: it
                required property string modelData
                readonly property bool sel: rr.value === modelData
                readonly property var info: ThemeColors.roles.find(x => x.id === modelData)
                width: 76; height: 50
                Rectangle {
                    id: dot
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 3; width: 24; height: 24; radius: 12
                    color: it.modelData === "" ? "transparent" : ThemeColors.of(it.modelData)
                    border.width: it.modelData === "" ? 1.5 : 1; border.color: it.modelData === "" ? Theme.muted : Qt.rgba(1, 1, 1, 0.15)
                    Rectangle { visible: it.modelData === ""; anchors.centerIn: parent; width: parent.width * 0.8; height: 1.5; rotation: -45; color: Theme.muted }
                    Rectangle { anchors.fill: parent; anchors.margins: -4; radius: width / 2; color: "transparent"; border.width: 2; border.color: it.sel ? Theme.accent : (rm.containsMouse ? Theme.border : "transparent") }
                }
                UiText {
                    anchors { horizontalCenter: parent.horizontalCenter; top: dot.bottom; topMargin: 6 }
                    width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                    text: it.modelData === "" ? "Nenhuma" : (it.info ? it.info.label : it.modelData)
                    color: it.sel ? Theme.text : Theme.muted; font.pixelSize: 10
                }
                MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: rr.picked(it.modelData) }
            }
        }
    }
}
