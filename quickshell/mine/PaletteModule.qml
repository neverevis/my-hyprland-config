// Modulo de barra: bolinhas com as cores do tema (da paleta atual).
import QtQuick

Item {
    id: root
    property var opts: ({})
    property bool vertical: false
    readonly property int dot: opts.size ?? 14
    readonly property int gap: opts.spacing ?? 5
    readonly property var ids: ({
        all: ["primary", "primaryContainer", "secondary", "secondaryContainer", "tertiary", "tertiaryContainer", "background", "surface", "surfaceHigh", "outline", "text", "muted", "error"],
        accents: ["primary", "secondary", "tertiary", "error"],
        surfaces: ["background", "surface", "surfaceHigh", "outline", "muted", "text"]
    })[opts.set ?? "all"]

    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight

    Grid {
        id: grid
        spacing: root.gap
        rows: root.vertical ? 99 : 1
        columns: root.vertical ? 1 : 99
        Repeater {
            model: root.ids
            delegate: Rectangle {
                required property string modelData
                width: root.dot; height: root.dot; radius: root.dot / 2
                color: ThemeColors.of(modelData)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.22)
            }
        }
    }
}
