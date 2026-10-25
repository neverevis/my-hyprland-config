// Previa de um widget sobre um pedaco do wallpaper atual (pagina Widgets): o proprio componente, em escala, com o
// fundo escolhido (cartao, vidro ou sem fundo). So imagem: nao recebe cliques.
import QtQuick
import QtQuick.Effects

Rectangle {
    id: pv
    property var w: null                       // { type, cols, rows, opts }
    property bool plain: false                 // sem wallpaper: so um degrade suave (galeria: varias miniaturas baratas)
    property bool async: false                 // cria o widget em segundo plano
    property bool showLabel: true
    readonly property real nw: w ? DeskState.pxW(w.cols) : 300
    readonly property real nh: w ? DeskState.pxH(w.rows) : 150
    readonly property real k: Math.min((width - 40) / nw, (height - 32) / nh, 1)
    readonly property string cardStyle: { const c = w ? DeskState.opt(w, "card") : "auto"; return c === "auto" ? Settings.desktopCardStyle : c }
    radius: 16
    clip: true
    color: Theme.track

    Loader {
        anchors.fill: parent
        active: !pv.plain
        sourceComponent: Item {
            Image {
                id: wall
                anchors.fill: parent
                source: Wallpaper.still !== "" ? "file://" + Wallpaper.still : ""
                sourceSize: Qt.size(640, 360)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
            // fonte escondida via ShaderEffectSource (uma Image com visible: false fica vazia se carregar com a pagina fechada)
            ShaderEffectSource { id: wallTex; anchors.fill: parent; sourceItem: wall; hideSource: true; visible: false }
            MultiEffect { anchors.fill: parent; source: wallTex; blurEnabled: true; blur: 0.5; blurMax: 32; brightness: -0.08 }
        }
    }
    Rectangle {
        visible: pv.plain
        anchors.fill: parent
        gradient: Gradient { orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.55) }
            GradientStop { position: 0.55; color: Qt.rgba(Theme.family("secondary").main.r, Theme.family("secondary").main.g, Theme.family("secondary").main.b, 0.45) }
            GradientStop { position: 1; color: Qt.rgba(Theme.family("tertiary").main.r, Theme.family("tertiary").main.g, Theme.family("tertiary").main.b, 0.5) } }
    }

    Item {
        anchors.centerIn: parent
        width: pv.nw; height: pv.nh
        scale: pv.k
        Rectangle {
            anchors.fill: parent
            radius: Math.min(30, Math.min(width, height) * 0.2)
            color: pv.cardStyle === "card" ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, Settings.desktopCard / 100)
                : (pv.cardStyle === "glass" || pv.cardStyle === "frost") ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, Math.max(0.32, Settings.desktopCard / 100 * 0.55)) : "transparent"
            border.width: pv.cardStyle === "none" ? 0 : 1
            border.color: Qt.rgba(1, 1, 1, 0.14)
        }
        Loader {
            anchors.fill: parent
            anchors.margins: pv.cardStyle === "none" ? 4 : 18
            asynchronous: pv.async
            sourceComponent: pv.w ? DeskWidgets.component(pv.w.type) : null
            onLoaded: {
                item.cols = Qt.binding(() => pv.w ? pv.w.cols : 1); item.rows = Qt.binding(() => pv.w ? pv.w.rows : 1)
                item.opts = Qt.binding(() => pv.w ? (pv.w.opts || {}) : {})
                if (item.bare !== undefined) item.bare = Qt.binding(() => pv.cardStyle === "none")
            }
        }
    }
    MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.AllButtons }
    Rectangle {
        visible: pv.showLabel
        anchors { left: parent.left; bottom: parent.bottom; margins: 8 }
        width: lbl.implicitWidth + 16; height: 22; radius: 11
        color: Qt.rgba(0, 0, 0, 0.45)
        UiText { id: lbl; anchors.centerIn: parent; text: "Prévia"; color: "white"; font.pixelSize: 11; font.weight: Font.Medium }
    }
}
