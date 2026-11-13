// Midia, composicao "Sereno" (a padrao): capa de canto arredondado, titulo, artista, um fio de progresso e tres botoes.
// Sem nada tocando o desenho e o mesmo (a capa vira um quadro vazio), em vez de um icone solto no meio do cartao.
// host = o DwMedia (player, capa, cores e opcoes vem dele). Um so destaque de cor: o botao de tocar.
import QtQuick

Item {
    id: c
    property Item host
    readonly property var p: host.p
    readonly property bool tall: host.rows > 1
    readonly property bool tiny: host.cols === 1 && host.rows === 1
    readonly property real u: Math.max(0.72, Math.min(1.25, height / (tall ? 278 : 114)))
    readonly property bool ctl: host.o("controls") && !!p && !tiny
    readonly property real footH: (host.o("titles") ? 44 : 0) * u + (ctl ? 52 : 14) * u
    function clock(s) { s = Math.max(0, Math.round(s || 0)); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0") }

    // capa (ou o quadro vazio)
    Rectangle {
        id: art
        width: c.tall ? parent.width : height
        height: c.tall ? parent.height - c.footH : parent.height
        radius: Math.round(16 * c.u)
        color: Qt.rgba(host.fg.r, host.fg.g, host.fg.b, 0.08)
        UiIcon { visible: !img.ready; anchors.centerIn: parent; name: "music"; size: Math.round(Math.min(parent.width, parent.height) * 0.3); color: host.dim }
        RoundImage {
            id: img
            anchors.fill: parent
            radius: art.radius
            source: host.art; sourceSize: Qt.size(512, 512)
            opacity: ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        }
        MouseArea { anchors.fill: parent; enabled: !!c.p; cursorShape: Qt.PointingHandCursor; onClicked: c.p.togglePlaying() }
    }
    Item {
        id: info
        visible: !c.tiny
        x: c.tall ? 0 : art.width + 16 * c.u
        y: c.tall ? art.height + 12 * c.u : 0
        width: parent.width - x
        height: parent.height - y
        Column {
            visible: host.o("titles")
            width: parent.width
            y: c.tall ? 0 : 2 * c.u
            spacing: 2 * c.u
            UiText {
                width: parent.width; elide: Text.ElideRight
                text: c.p ? (host.title || "Sem título") : "Nada tocando"
                color: host.fg; font.pixelSize: Math.round(15 * c.u); font.weight: Font.DemiBold
            }
            UiText {
                width: parent.width; elide: Text.ElideRight
                text: c.p ? (host.lyrLine !== "" ? host.lyrLine : host.artist) : "Nenhum player aberto"
                color: host.dim; font.pixelSize: Math.round(12 * c.u)
            }
        }
        // progresso: um fio; o tempo aparece ao lado dos botoes
        Rectangle {
            id: bar
            visible: !!c.p
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: c.ctl ? 42 * c.u : 0 }
            height: 3; radius: 1.5
            color: Qt.rgba(host.fg.r, host.fg.g, host.fg.b, 0.14)
            Rectangle {
                width: parent.width * host.prog; height: parent.height; radius: 1.5; color: host.fg
                Behavior on width { NumberAnimation { duration: 900 } }
            }
        }
        Row {
            visible: c.ctl
            anchors { left: parent.left; leftMargin: -6 * c.u; bottom: parent.bottom }
            spacing: 2 * c.u
            Repeater {
                model: ["prev", c.p && c.p.isPlaying ? "pause" : "play", "next"]
                delegate: Rectangle {
                    id: b
                    required property string modelData
                    required property int index
                    readonly property bool main: index === 1
                    width: Math.round(32 * c.u); height: width; radius: width / 2
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    color: main ? host.acc : bm.containsMouse ? Qt.rgba(host.fg.r, host.fg.g, host.fg.b, 0.12) : "transparent"
                    scale: bm.pressed ? 0.94 : 1
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 120 } }
                    UiIcon { anchors.centerIn: parent; name: b.modelData; size: Math.round(17 * c.u); color: b.main ? Theme.accentText : host.fg }
                    MouseArea {
                        id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (!c.p) return; if (b.index === 0) c.p.previous(); else if (b.index === 1) c.p.togglePlaying(); else c.p.next() }
                    }
                }
            }
        }
        UiText {
            visible: c.ctl && !!c.p && c.p.length > 0 && info.width > 170 * c.u
            anchors { right: parent.right; bottom: parent.bottom; bottomMargin: 9 * c.u }
            text: c.p ? c.clock(c.p.position) + " / " + c.clock(c.p.length) : ""
            color: host.dim; font.pixelSize: Math.round(11 * c.u); font.features: { "tnum": 1 }
        }
    }
}
