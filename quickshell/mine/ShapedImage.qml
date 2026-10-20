// Imagem recortada numa forma de Shapes.qml (Flower.qml como mascara, entao a troca de forma anima). fit: crop | fit.
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
    property real depth: 0.11
    property bool animated: true                       // morph ao trocar de forma
    readonly property bool morphing: msk.morphing
    property real radius: Math.min(width, height) * 0.18
    property string fit: "crop"
    property real spin: 0
    property size sourceSize: Qt.size(512, 512)
    // enquadramento (so em "crop"): zoom (1 = cobre a forma) e posicao de -1 (mostra a esquerda/topo) a 1
    property real zoom: 1
    property real offX: 0
    property real offY: 0
    readonly property bool ready: img.status === Image.Ready

    Image { id: probe; visible: false; source: img.source; sourceSize: Qt.size(64, 64); asynchronous: true }
    Item {
        id: holder
        anchors.fill: parent
        Image {
            id: img
            // crop: a imagem cobre a forma (proporcao dela) vezes o zoom, e a posicao escolhe a parte que aparece
            readonly property bool framed: si.fit !== "fit" && probe.implicitWidth > 0 && probe.implicitHeight > 0
            readonly property real ar: probe.implicitWidth / Math.max(1, probe.implicitHeight)   // proporcao medida na miniatura
            readonly property real cw: (ar > parent.width / Math.max(1, parent.height) ? parent.height * ar : parent.width) * Math.max(1, si.zoom)
            readonly property real ch: cw / Math.max(0.001, ar)
            x: framed ? (parent.width - cw) / 2 * (1 + Math.max(-1, Math.min(1, si.offX))) : 0
            y: framed ? (parent.height - ch) / 2 * (1 + Math.max(-1, Math.min(1, si.offY))) : 0
            width: framed ? cw : parent.width
            height: framed ? ch : parent.height
            rotation: si.spin
            // enquadrada: carrega no tamanho que vai aparecer (com folga), senao no tamanho pedido
            sourceSize: framed ? Qt.size(Math.min(3000, cw * 1.5), Math.min(3000, ch * 1.5)) : si.sourceSize
            fillMode: si.fit === "fit" ? Image.PreserveAspectFit : (framed ? Image.Stretch : Image.PreserveAspectCrop)
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
        depth: si.depth
        animated: si.animated
        color: "white"
    }
    // texturas (1 px no centro, coberto pelo resultado): escondem a fonte e atualizam sempre que ela muda
    ShaderEffectSource { id: imgTex; sourceItem: holder; hideSource: true; live: true; x: si.width / 2; y: si.height / 2; width: 1; height: 1 }
    ShaderEffectSource { id: mskTex; sourceItem: msk; hideSource: true; live: true; x: si.width / 2; y: si.height / 2; width: 1; height: 1 }
    MultiEffect {
        anchors.fill: parent
        source: imgTex
        visible: si.ready
        // sempre com mascara (quadrada = retangulo cheio): ligar e desligar no meio de um morph piscaria
        maskEnabled: true
        maskSource: mskTex
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
        autoPaddingEnabled: false
    }
}
