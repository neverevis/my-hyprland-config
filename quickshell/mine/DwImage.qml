// Imagem: foto (forma: arredondada, circulo, flor, quadrada), cartao (foto + legenda) ou adesivo (contorno branco,
// inclinado). Sem imagem escolhida: botao para escolher (navegador de imagens proprio, Pick.qml).
import QtQuick
import QtQuick.Effects

Item {
    id: w
    property int cols: 2
    property int rows: 2
    property var opts: ({})
    property string wid: ""
    property color fg: Theme.text
    property color dim: Theme.muted
    property color ac: Theme.accent
    property bool bare: false
    function o(k) { return DeskState.opt({ type: "image", opts: w.opts }, k) }
    readonly property string path: o("path")
    readonly property string kind: o("kind")

    Column {
        visible: w.path === ""
        anchors.centerIn: parent
        spacing: 8
        UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "image"; size: 34; color: w.dim }
        UiButton { anchors.horizontalCenter: parent.horizontalCenter; icon: "folderOpen"; text: "Escolher imagem"; onClicked: Pick.image("Imagem do widget", p => DeskState.setOpt(w.wid, "path", p)) }
    }

    // foto
    ShapedImage {
        visible: w.path !== "" && w.kind === "photo"
        anchors.centerIn: parent
        width: w.o("shape") === "rounded" || w.o("shape") === "square" ? parent.width : Math.min(parent.width, parent.height)
        height: w.o("shape") === "rounded" || w.o("shape") === "square" ? parent.height : width
        source: w.path !== "" ? "file://" + w.path : ""
        shape: w.o("shape")
        fit: w.o("fit")
        sourceSize: Qt.size(Math.max(256, width * 1.5), Math.max(256, height * 1.5))
    }
    // cartao com legenda
    Item {
        visible: w.path !== "" && w.kind === "card"
        anchors.fill: parent
        readonly property bool cap: w.o("caption") !== ""
        RoundImage {
            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; bottomMargin: parent.cap ? 34 : 0 }
            radius: 14
            source: w.path !== "" ? "file://" + w.path : ""
            sourceSize: Qt.size(Math.max(256, width * 1.5), Math.max(256, height * 1.5))
        }
        Text {
            visible: parent.cap
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 28; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
            text: w.o("caption"); color: w.fg; font.family: DeskWidgets.script; font.pixelSize: 20; elide: Text.ElideRight
        }
    }
    // adesivo: contorno branco + leve inclinacao + sombra
    Item {
        visible: w.path !== "" && w.kind === "sticker"
        anchors.centerIn: parent
        width: parent.width * 0.86; height: parent.height * 0.86
        rotation: w.o("tilt")
        Image {
            id: stk
            anchors.fill: parent
            source: w.path !== "" ? "file://" + w.path : ""
            fillMode: Image.PreserveAspectFit
            sourceSize: Qt.size(512, 512)
            asynchronous: true
            visible: false
            layer.enabled: true
        }
        // contorno: a silhueta (alpha) dilatada em branco por baixo da imagem
        MultiEffect {
            anchors.fill: parent
            anchors.margins: -w.o("outline")
            source: stk
            visible: w.o("outline") > 0 && stk.status === Image.Ready
            colorization: 1; colorizationColor: "white"; brightness: 1
            blurEnabled: true; blur: 0.2; blurMax: Math.max(1, w.o("outline") * 2)
            shadowEnabled: true; shadowColor: Qt.rgba(0, 0, 0, 0.45); shadowBlur: 0.6; shadowVerticalOffset: 4
        }
        MultiEffect { anchors.fill: parent; source: stk; visible: stk.status === Image.Ready }
    }
}
