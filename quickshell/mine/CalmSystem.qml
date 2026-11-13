// Sistema, composicao "Sereno" (a padrao): numeros grandes com um fio de uso embaixo, sem cartoes coloridos.
// Em pe (2 linhas ou mais): a primeira medida em destaque com o historico em barrinhas, as outras em linhas.
// host = o DwSystem (medidas, cores e opcoes vem dele). Uma cor so; vermelho apenas acima de 85 %.
import QtQuick

Item {
    id: c
    property Item host
    readonly property bool tall: host.rows > 1
    readonly property int count: host.shown.length
    readonly property real u: Math.max(0.72, Math.min(1.25, height / (tall ? 278 : 114)))
    function item(i) { return host.shown[i] ?? ({}) }
    function tone(d) { return host.o("warn") && d.v > 0.85 ? Theme.danger : host.ac }
    readonly property color track: Qt.rgba(host.fg.r, host.fg.g, host.fg.b, 0.12)

    component Meter: Rectangle {
        property real v: 0
        property color tone: host.ac
        height: 3; radius: 1.5; color: c.track
        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, parent.v || 0)); height: parent.height; radius: 1.5; color: parent.tone
            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        }
    }

    // ---- deitado: uma coluna por medida ----
    Row {
        visible: !c.tall
        anchors.fill: parent
        spacing: 20 * c.u
        Repeater {
            model: c.count   // modelo estavel: o array e refeito a cada segundo
            delegate: Item {
                id: col
                required property int index
                readonly property var d: c.item(index)
                width: (parent.width - (c.count - 1) * parent.spacing) / c.count
                height: parent.height
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    UiText { text: col.d.label ?? ""; color: host.dim; font.pixelSize: Math.round(12 * c.u); font.weight: Font.Medium }
                    UiText {
                        width: parent.width
                        text: col.d.t ?? ""; color: host.fg
                        font.family: Theme.fontTitle; font.pixelSize: Math.round(34 * c.u); font.weight: Font.Medium; font.features: { "tnum": 1 }
                        fontSizeMode: Text.HorizontalFit; minimumPixelSize: 12
                    }
                    Item { width: 1; height: 8 * c.u }
                    Meter { width: parent.width; v: col.d.v ?? 0; tone: c.tone(col.d) }
                }
            }
        }
    }

    // ---- em pe: destaque + linhas ----
    Item {
        visible: c.tall
        anchors.fill: parent
        readonly property var d: c.item(0)
        Column {
            id: hero
            spacing: 0
            UiText { text: parent.parent.d.label ?? ""; color: host.dim; font.pixelSize: Math.round(13 * c.u); font.weight: Font.Medium }
            UiText {
                text: parent.parent.d.t ?? ""; color: host.fg
                font.family: Theme.fontTitle; font.pixelSize: Math.round(52 * c.u); font.weight: Font.Medium; font.features: { "tnum": 1 }
            }
        }
        // historico da primeira medida (ultimas amostras), em barrinhas: sem Canvas, so retangulos
        Row {
            id: hist
            readonly property var h: parent.d.h ?? []
            readonly property int n: 24
            visible: h.length > 1
            anchors { left: hero.right; leftMargin: 16 * c.u; right: parent.right; bottom: hero.bottom; bottomMargin: 10 * c.u }
            height: 40 * c.u
            spacing: 2
            Repeater {
                model: hist.n
                delegate: Item {
                    required property int index
                    readonly property real v: { const a = hist.h, i = a.length - hist.n + index; return i >= 0 ? Math.max(0, Math.min(1, a[i] || 0)) : 0 }
                    width: (hist.width - (hist.n - 1) * 2) / hist.n
                    height: hist.height
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: Math.max(2, parent.height * parent.v); radius: 1; color: host.ac; opacity: 0.35 + 0.65 * (index / hist.n) }
                }
            }
        }
        Column {
            id: rest
            readonly property int n: Math.max(0, c.count - 1)
            anchors { left: parent.left; right: parent.right; top: hero.bottom; topMargin: 10 * c.u; bottom: parent.bottom }
            Repeater {
                model: rest.n
                delegate: Item {
                    id: r
                    required property int index
                    readonly property var d: c.item(index + 1)
                    width: rest.width
                    height: rest.height / Math.max(1, rest.n)
                    Column {
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                        spacing: 6 * c.u
                        Item {
                            width: parent.width; height: Math.round(16 * c.u)
                            UiText { anchors.verticalCenter: parent.verticalCenter; text: r.d.label ?? ""; color: host.fg; font.pixelSize: Math.round(13 * c.u); font.weight: Font.Medium }
                            UiText { anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: r.d.t ?? ""; color: host.dim; font.pixelSize: Math.round(12 * c.u); font.features: { "tnum": 1 } }
                        }
                        Meter { width: parent.width; v: r.d.v ?? 0; tone: c.tone(r.d) }
                    }
                }
            }
        }
    }
}
