// Miniatura de um visual: wallpaper, moldura, barras e widgets nos lugares deles (desenhada, nao e captura de tela).
// O que o visual nao guarda aparece como esta agora (ex.: um layout pronto mostra as barras atuais).
import QtQuick

Item {
    id: lp
    property var look: ({})
    readonly property real k: width / 1920
    function v(key) { return lp.look && lp.look[key] !== undefined ? lp.look[key] : Settings[key] }
    readonly property real edge: Math.max(1.5, (v("edge") ?? 6) * k)
    readonly property real corner: (v("cornerRadius") ?? 16) * k
    readonly property color frameCol: (lp.look && lp.look.themeOn === false) ? (lp.look.userBarColor || Settings.userBarColor) : Theme.bg
    readonly property color acc: (lp.look && lp.look.themeOn === false && lp.look.userAccent) ? lp.look.userAccent : Theme.accent
    height: width * 9 / 16

    Rectangle { anchors.fill: parent; radius: 10; color: Theme.bg }
    RoundImage {
        anchors.fill: parent; radius: 10
        source: { const p = lp.look && lp.look.wallpaper ? lp.look.wallpaper : Wallpaper.current; return p ? Wallpaper.stillUrl(p) : "" }
        sourceSize: Qt.size(384, 216)
        dim: 0.15
    }
    // moldura (borda da tela com o canto arredondado por dentro)
    Rectangle {
        visible: lp.v("outline") !== false
        anchors.fill: parent
        radius: 10
        color: "transparent"
        border.width: lp.edge; border.color: lp.frameCol
    }
    // barras
    Repeater {
        model: lp.v("bars") || []
        delegate: Rectangle {
            id: br
            required property var modelData
            readonly property string side: modelData.side || "bottom"
            readonly property bool vert: side === "left" || side === "right"
            readonly property real span: vert ? lp.height : lp.width
            readonly property real len: modelData.full ? span : Math.max(10, Settings.barSize(modelData, vert ? 1080 : 1920) / 100 * span)
            readonly property real along: modelData.full ? 0 : Settings.barPos(modelData, vert ? 1080 : 1920) / 100 * (span - len)
            readonly property bool det: !!modelData.detached
            readonly property real th: Math.max(3, (modelData.height ?? 30) * lp.k)
            readonly property real gap: det ? (modelData.gap ?? 8) * lp.k + lp.edge : 0
            width: vert ? th : len
            height: vert ? len : th
            x: vert ? (side === "left" ? gap : lp.width - th - gap) : along
            y: vert ? along : (side === "top" ? gap : lp.height - th - gap)
            radius: det ? Math.min(th / 2, (modelData.radius ?? 14) * lp.k) : Math.min(th / 2, 4)
            color: lp.frameCol
            // pontinhos de modulos
            Row {
                visible: !br.vert
                anchors.centerIn: parent
                spacing: Math.max(2, br.len * 0.04)
                Repeater { model: Math.min(6, Math.max(1, Math.floor(br.len / 18))); delegate: Rectangle { width: Math.max(2, br.th * 0.28); height: width; radius: width / 2; color: index === 0 ? lp.acc : Qt.rgba(1, 1, 1, 0.5) } }
            }
        }
    }
    // widgets
    Repeater {
        model: lp.v("desktopWidgets") || []
        delegate: Rectangle {
            required property var modelData
            readonly property real aw: (1920 - 44) * lp.k
            readonly property real ah: (1080 - 80) * lp.k
            width: DeskState.px(modelData.cols) * lp.k; height: DeskState.px(modelData.rows) * lp.k
            x: 22 * lp.k + (modelData.fx ?? 0) * (aw - width)
            y: 40 * lp.k + (modelData.fy ?? 0) * (ah - height)
            radius: Math.min(width, height) * 0.2
            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.82)
            border.width: 1; border.color: Qt.rgba(lp.acc.r, lp.acc.g, lp.acc.b, 0.6)
            UiIcon { anchors.centerIn: parent; name: DeskState.info(modelData.type).icon; size: Math.max(7, Math.min(parent.width, parent.height) * 0.45); color: lp.acc }
        }
    }
}
