// Imagem recortada numa forma: flower | circle | rounded | square (Flower.qml como mascara). fit: crop | fit.
// spin gira a imagem dentro da forma (capa como disco). Mesmo esquema do RoundImage.
import QtQuick
import QtQuick.Effects

Item {
    id: si
    property alias source: img.source
    property string shape: "rounded"
    property int sides: 10
    property real radius: Math.min(width, height) * 0.18
    property string fit: "crop"
    property real spin: 0
    property size sourceSize: Qt.size(512, 512)
    readonly property bool ready: img.status === Image.Ready

    Item {
        id: holder
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Image {
            id: img
            anchors.centerIn: parent
            width: parent.width; height: parent.height
            rotation: si.spin
            sourceSize: si.sourceSize
            fillMode: si.fit === "fit" ? Image.PreserveAspectFit : Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            mipmap: true
        }
    }
    Flower {
        id: msk
        anchors.fill: parent
        visible: false
        layer.enabled: true
        shape: si.shape
        sides: si.sides
        radius: si.radius
        color: "white"
    }
    MultiEffect {
        anchors.fill: parent
        source: holder
        visible: si.ready
        maskEnabled: si.shape !== "square"
        maskSource: msk
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
        autoPaddingEnabled: false
    }
}
