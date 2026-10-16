// Visual de um medidor (CPU, memoria, volume): texto, barra, grafico de linha ou segmentos.
//   display: text | bar | graph | segments
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
    property int segments: 8
    property bool dim: false            // ex.: volume mudo

    readonly property color tint: warn && value > 0.85 ? Theme.danger : (warn && value > 0.65 ? (Settings.themeOn ? ThemeColors.tertiary : "#e0af68") : col)
    readonly property bool graphic: display !== "text"
    // tamanho do grafico (na lateral: limitado para caber na espessura da barra; ele fica em pe)
    readonly property real gw: vertical ? Math.min(w, 48) : w
    readonly property real gh: vertical ? Math.min(h, 16) : h

    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight

    // na barra lateral: rotulo e valor menores (cabem na espessura) e o grafico fica de pe
    Grid {
        id: grid
        spacing: m.vertical ? 3 : 6
        columns: m.vertical ? 1 : 99
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        Text {
            visible: m.label !== ""
            text: m.label
            color: Settings.textColor; font.pixelSize: m.vertical ? 9 : 14
            font.weight: m.vertical ? Font.DemiBold : Font.Normal
            font.letterSpacing: m.vertical ? 0.5 : 0
            opacity: m.graphic ? 0.7 : 1
        }

        Item {   // caixa do grafico: deitada na horizontal, em pe na lateral
            visible: m.graphic
            width: m.graphic ? (m.vertical ? m.gh : m.gw) : 0
            height: m.graphic ? (m.vertical ? m.gw : m.gh) : 0
        Item {
            anchors.centerIn: parent
            width: m.vertical ? parent.height : parent.width
            height: m.vertical ? parent.width : parent.height
            rotation: m.vertical ? -90 : 0   // cresce de baixo para cima
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

        Text {
            visible: m.showValue
            text: m.valueText
            color: m.graphic ? Settings.textColor : m.col; font.pixelSize: m.vertical ? 11 : 14
            font.weight: m.vertical ? Font.DemiBold : Font.Normal   // so texto: o proprio valor leva a cor de destaque
        }
    }
}
