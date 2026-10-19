// Imagem recortada numa forma: flower | circle | rounded | square (Flower.qml como mascara). fit: crop | fit.
// spin gira a imagem dentro da forma (capa como disco). Mesmo esquema do RoundImage.
// A imagem e a mascara viram texturas por ShaderEffectSource (hideSource), nao por camadas escondidas: a camada de um
// item com visible: false ficava vazia quando a imagem carregava com um pai invisivel (a foto do perfil sumia, o
// wallpaper centralizado nao aparecia).
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
        shape: si.shape
        sides: si.sides
        radius: si.radius
        color: "white"
    }
    // texturas (1 px no centro, coberto pelo resultado): escondem a fonte e atualizam sempre que ela muda
    ShaderEffectSource { id: imgTex; sourceItem: holder; hideSource: true; live: true; x: si.width / 2; y: si.height / 2; width: 1; height: 1 }
    ShaderEffectSource { id: mskTex; sourceItem: msk; hideSource: true; live: true; x: si.width / 2; y: si.height / 2; width: 1; height: 1 }
    MultiEffect {
        anchors.fill: parent
        source: imgTex
        visible: si.ready
        maskEnabled: si.shape !== "square"
        maskSource: mskTex
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
        autoPaddingEnabled: false
    }
}
