// Visual de um medidor (CPU, memoria, disco, swap, volume): texto, barra, grafico de linha, segmentos, anel (contorno
// fino com o icone no meio) ou disco (setor cheio).
//   display: text | bar | graph | segments | ring | disc
import QtQuick
import QtQuick.Shapes

Item {
    id: m
    property real value: 0              // 0..1
    property string valueText: ""
    property string label: ""
    property string display: "text"
    property var history: []            // 0..1, mais antigo primeiro (grafico)
    property bool vertical: false
    property bool showValue: display === "text"
    property real w: 60
    property real h: 16
    property color col: Settings.textColor
    property bool warn: false           // amarelo/vermelho quando alto
    property real warnAt: 85            // % em que fica vermelho (amarelo 20 pontos antes)
    property string icon: ""            // icone no meio do anel / disco
    property int segments: 8
    property bool dim: false            // ex.: volume mudo
    property bool present: true         // false: o medidor some e nao ocupa lugar (ex.: swap em PC sem swap)

    readonly property color tint: warn && value * 100 > warnAt ? Theme.danger : (warn && value * 100 > warnAt - 20 ? (Settings.themeOn ? ThemeColors.tertiary : "#e0af68") : col)
    readonly property bool graphic: display !== "text"
    readonly property bool round: display === "ring" || display === "disc"
    readonly property real dia: Math.max(14, Math.min(h, vertical ? 26 : 40))
    // tamanho do grafico (na lateral: limitado para caber na espessura da barra; ele fica em pe)
    readonly property real gw: round ? dia : (vertical ? Math.min(w, 48) : w)
    readonly property real gh: round ? dia : (vertical ? Math.min(h, 16) : h)
    property real shownValue: Math.max(0, Math.min(1, value))
    Behavior on shownValue { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    visible: present
    implicitWidth: present ? grid.implicitWidth : 0
    implicitHeight: present ? grid.implicitHeight : 0

    // na barra lateral: rotulo e valor menores (cabem na espessura) e o grafico fica de pe
    Grid {
        id: grid
        spacing: m.vertical ? 3 : 6
        columns: m.vertical ? 1 : 99
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        UiText {
            visible: m.label !== ""
            text: m.label
            color: Settings.textColor; font.pixelSize: m.vertical ? 9 : 14
            font.weight: m.vertical ? Font.DemiBold : Font.Normal
            font.letterSpacing: m.vertical ? 0.5 : 0
            opacity: m.graphic ? 0.7 : 1
        }

        Item {   // caixa do grafico: deitada na horizontal, em pe na lateral
            visible: m.graphic
            width: m.graphic ? (m.vertical && !m.round ? m.gh : m.gw) : 0
            height: m.graphic ? (m.vertical && !m.round ? m.gw : m.gh) : 0
        Item {
            anchors.centerIn: parent
            width: m.vertical && !m.round ? parent.height : parent.width
            height: m.vertical && !m.round ? parent.width : parent.height
            rotation: m.vertical && !m.round ? -90 : 0   // cresce de baixo para cima
            opacity: m.dim ? 0.35 : 1

            // barra
            Rectangle {
                visible: m.display === "bar"
                anchors.fill: parent
                radius: height / 2
                color: Qt.rgba(m.col.r, m.col.g, m.col.b, 0.2)
                Rectangle {
                    width: Math.max(parent.height, parent.width * Math.max(0, Math.min(1, m.value)))
                    height: parent.height; radius: height / 2
                    color: m.tint
                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }
            }

            // segmentos (tipo equalizador)
            Row {
                visible: m.display === "segments"
                anchors.fill: parent
                spacing: 2
                Repeater {
                    model: m.segments
                    delegate: Rectangle {
                        required property int index
                        readonly property bool on: (index + 1) <= Math.round(m.value * m.segments)
                        width: (m.gw - (m.segments - 1) * 2) / m.segments
                        height: m.gh * (0.4 + 0.6 * (index + 1) / m.segments)
                        anchors.bottom: parent.bottom
                        radius: 1.5
                        color: on ? m.tint : Qt.rgba(m.col.r, m.col.g, m.col.b, 0.2)
                    }
                }
            }

            // anel (arco fino + icone no meio) e disco (setor cheio)
            Item {
                id: rg
                visible: m.round
                anchors.fill: parent
                readonly property real d: Math.min(width, height)
                readonly property real sw: m.display === "ring" ? Math.max(2, d * 0.13) : 0
                readonly property real rad: (d - sw) / 2
                readonly property real cx: width / 2
                readonly property real cy: height / 2
                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {   // trilho
                        fillColor: m.display === "disc" ? Qt.rgba(m.col.r, m.col.g, m.col.b, 0.2) : "transparent"
                        strokeColor: m.display === "ring" ? Qt.rgba(m.col.r, m.col.g, m.col.b, 0.22) : "transparent"
                        strokeWidth: rg.sw
                        capStyle: ShapePath.RoundCap
                        startX: rg.cx; startY: rg.cy - rg.rad
                        PathAngleArc { centerX: rg.cx; centerY: rg.cy; radiusX: rg.rad; radiusY: rg.rad; startAngle: -90; sweepAngle: 359.9 }
                    }
                    ShapePath {   // valor (disco: parte do centro e vira um setor)
                        fillColor: m.display === "disc" ? Qt.rgba(m.tint.r, m.tint.g, m.tint.b, 0.55) : "transparent"
                        strokeColor: m.display === "ring" ? m.tint : "transparent"
                        strokeWidth: rg.sw
                        capStyle: ShapePath.RoundCap
                        startX: m.display === "disc" ? rg.cx : rg.cx; startY: m.display === "disc" ? rg.cy : rg.cy - rg.rad
                        PathLine { x: rg.cx; y: rg.cy - rg.rad }
                        PathAngleArc { centerX: rg.cx; centerY: rg.cy; radiusX: rg.rad; radiusY: rg.rad; startAngle: -90; sweepAngle: Math.max(0.6, 359.9 * m.shownValue) }
                    }
                }
                UiIcon { anchors.centerIn: parent; visible: m.icon !== ""; name: m.icon; size: Math.round(rg.d * 0.5); color: Settings.textColor }
            }

            // grafico de linha com area
            Shape {
                id: gshape
                visible: m.display === "graph"
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                readonly property var pts: {
                    const h = m.history, n = h.length
                    if (n < 2) return []
                    const out = []
                    for (let i = 0; i < n; i++) out.push(Qt.point(i / (n - 1) * m.gw, m.gh - Math.max(0, Math.min(1, h[i])) * (m.gh - 2) - 1))
                    return out
                }
                ShapePath {   // area
                    fillColor: Qt.rgba(m.tint.r, m.tint.g, m.tint.b, 0.25)
                    strokeColor: "transparent"
                    PathPolyline { path: gshape.pts.length ? gshape.pts.concat([Qt.point(m.gw, m.gh), Qt.point(0, m.gh)]) : [Qt.point(0, m.gh), Qt.point(1, m.gh)] }
                }
                ShapePath {   // linha
                    fillColor: "transparent"
                    strokeColor: m.tint
                    strokeWidth: 1.6
                    joinStyle: ShapePath.RoundJoin
                    PathPolyline { path: gshape.pts.length ? gshape.pts : [Qt.point(0, m.gh), Qt.point(1, m.gh)] }
                }
            }
        }
        }

        UiText {
            visible: m.showValue
            text: m.valueText
            color: m.graphic ? Settings.textColor : m.col; font.pixelSize: m.vertical ? 11 : 14
            font.weight: m.vertical ? Font.DemiBold : Font.Normal   // so texto: o proprio valor leva a cor de destaque
        }
    }
}
