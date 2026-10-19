// Imagem: foto (recortada numa das formas de Shapes.qml), cartao (foto + legenda) ou adesivo (contorno branco,
// inclinado). Enquadramento: zoom e posicao (opcoes, ou a roda do mouse editando). Soltar uma imagem troca a do
// widget. Sem imagem escolhida: botao para escolher (navegador de imagens proprio, Pick.qml).
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
    property color ac2: Theme.tertiary            // cor companheira (o DeskView passa a do tom escolhido)
    property color cont: Theme.primaryContainer
    property color contInk: Theme.primaryContainerInk
    property bool bare: false
    function o(k) { return DeskState.opt({ type: "image", opts: w.opts }, k) }
    readonly property string path: o("path")
    readonly property string kind: o("kind")
    readonly property string shape: o("shape")
    readonly property bool boxy: shape === "rounded" || shape === "square"
    readonly property var imgExt: ["png", "jpg", "jpeg", "webp", "avif", "bmp", "gif", "tif", "tiff", "svg"]

    // soltar uma imagem troca a do widget
    DropArea {
        id: drop
        anchors.fill: parent
        keys: ["text/uri-list"]
        onDropped: d => {
            if (!d.hasUrls || w.wid === "") return
            const p = decodeURIComponent(d.urls[0].toString().replace(/^file:\/\//, ""))
            if (w.imgExt.indexOf(p.split(".").pop().toLowerCase()) >= 0) { DeskState.setOpt(w.wid, "path", p); d.acceptProposedAction() }
        }
    }
    Rectangle {
        anchors.fill: parent; radius: 16; z: 5
        visible: drop.containsDrag
        color: Qt.rgba(w.ac.r, w.ac.g, w.ac.b, 0.25); border.width: 2; border.color: w.ac
        UiText { anchors.centerIn: parent; text: "Soltar para trocar"; color: w.fg; font.pixelSize: 14; font.weight: Font.Bold }
    }
    // editando com este widget aberto: a roda do mouse da zoom na foto
    WheelHandler {
        enabled: DeskState.editing && DeskState.selected === w.wid && w.wid !== "" && (w.kind === "photo" || w.kind === "card")
        onWheel: e => DeskState.setOpt(w.wid, "zoom", Math.max(100, Math.min(400, Math.round(w.o("zoom") + e.angleDelta.y / 12))))
    }

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
        width: w.boxy ? parent.width : Math.min(parent.width, parent.height)
        height: w.boxy ? parent.height : width
        source: w.path !== "" ? "file://" + w.path : ""
        shape: w.shape
        sides: w.o("sides")
        fit: w.o("fit")
        zoom: w.o("zoom") / 100; offX: w.o("panX") / 100; offY: w.o("panY") / 100
        rotation: w.o("tilt")
        Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        sourceSize: Qt.size(Math.max(256, width * 1.5), Math.max(256, height * 1.5))
    }
    // cartao com legenda
    Item {
        visible: w.path !== "" && w.kind === "card"
        anchors.fill: parent
        readonly property bool cap: w.o("caption") !== ""
        ShapedImage {
            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; bottomMargin: parent.cap ? 34 : 0 }
            shape: "rounded"; radius: 14
            source: w.path !== "" ? "file://" + w.path : ""
            fit: w.o("fit")
            zoom: w.o("zoom") / 100; offX: w.o("panX") / 100; offY: w.o("panY") / 100
            sourceSize: Qt.size(Math.max(256, width * 1.5), Math.max(256, height * 1.5))
        }
        UiText {
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
        Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
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
