// Imagem com cantos arredondados, desfoque e escurecimento opcionais (sem mexer na saturacao).
import QtQuick
import QtQuick.Effects

Item {
    id: ri
    property alias source: img.source
    property real radius: 12
    property real blur: 0          // 0..1
    property real dim: 0           // 0..1: camada preta por cima
    property size sourceSize: Qt.size(256, 256)
    readonly property bool ready: img.status === Image.Ready
    readonly property int status: img.status

    Image {
        id: img
        anchors.fill: parent
        sourceSize: ri.sourceSize
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }
    Item {
        id: msk
        anchors.fill: parent
        layer.enabled: true
        visible: false
        Rectangle { anchors.fill: parent; radius: ri.radius; color: "white" }
    }
    MultiEffect {
        anchors.fill: parent
        source: img
        visible: ri.ready
        maskEnabled: true
        maskSource: msk
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
        autoPaddingEnabled: false
        blurEnabled: ri.blur > 0
        blur: ri.blur
        blurMax: 48
    }
    Rectangle { anchors.fill: parent; radius: ri.radius; color: "black"; opacity: ri.dim; visible: ri.dim > 0 && ri.ready }
}
