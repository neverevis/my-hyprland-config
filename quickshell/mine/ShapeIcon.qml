// Icone dentro de uma forma (o MaterialShapeWrappedMaterialSymbol do end4): fundo Flower + UiIcon no centro.
// A forma anima (morph) quando shape muda. size = lado do quadrado; padding = folga entre o icone e a borda.
import QtQuick

Item {
    id: si
    property string shape: "clover4"
    property string icon: ""
    property real size: 40
    property real padding: 8
    property int sides: 12                      // so "flower"
    property real depth: 0.11
    property color color: Theme.secondaryContainer
    property color iconColor: Theme.secondaryContainerInk
    property real iconSize: Math.max(8, size - padding * 2)
    property real spin: 0                       // gira so a forma
    property bool animated: true
    readonly property alias morphing: bg.morphing
    implicitWidth: size
    implicitHeight: size

    Flower {
        id: bg
        anchors.fill: parent
        shape: si.shape; sides: si.sides; depth: si.depth
        color: si.color
        spin: si.spin
        animated: si.animated
    }
    UiIcon {
        anchors.centerIn: parent
        name: si.icon
        size: Math.round(si.iconSize)
        color: si.iconColor
    }
}
