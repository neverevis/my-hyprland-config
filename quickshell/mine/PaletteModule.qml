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

    readonly property int total: ids.length * dot + Math.max(0, ids.length - 1) * gap
    implicitWidth: vertical ? dot : total
    implicitHeight: vertical ? total : dot

    Repeater {
        model: root.ids
        delegate: Rectangle {
            required property int index
            required property string modelData
            x: root.vertical ? 0 : index * (root.dot + root.gap)
            y: root.vertical ? index * (root.dot + root.gap) : 0
            width: root.dot; height: root.dot; radius: root.dot / 2
            color: ThemeColors.of(modelData)
        }
    }
}
