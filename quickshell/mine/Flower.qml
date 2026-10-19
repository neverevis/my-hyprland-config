// Forma de "flor" (circulo com N petalas suaves; 0 = circulo): r(t) = R * (1 - depth * (1 - cos(N t)) / 2).
// Serve de fundo (color) ou, branca e com layer, de mascara para imagens (MultiEffect maskSource).
// shape: flower | circle | rounded | square e as outras de Shapes.qml (coracao, trevo, gema, sol...).
import QtQuick
import QtQuick.Shapes

Item {
    id: f
    property string shape: "flower"
    property int sides: 12
    property real depth: 0.11
    property color color: "white"
    property color border: "transparent"
    property real borderWidth: 0
    property real radius: Math.min(width, height) * 0.22   // so "rounded"
    property real spin: 0                                  // graus

    readonly property bool box: Shapes.isBox(shape)
    readonly property var pts: {
        if (box) return []
        const cx = width / 2, cy = height / 2, R = Math.min(width, height) / 2 - borderWidth / 2
        const a0 = spin * Math.PI / 180, ca = Math.cos(a0), sa = Math.sin(a0)
        const p = Shapes.pts(shape, sides, depth).map(q => Qt.point(cx + R * (q[0] * ca - q[1] * sa), cy + R * (q[0] * sa + q[1] * ca)))
        if (p.length) p.push(p[0])
        return p
    }
    Shape {
        anchors.fill: parent
        visible: !f.box
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: f.color
            strokeColor: f.borderWidth > 0 ? f.border : "transparent"
            strokeWidth: f.borderWidth
            PathPolyline { path: f.pts }
        }
    }
    Rectangle {
        anchors.fill: parent
        visible: f.box
        radius: f.shape === "circle" ? Math.min(width, height) / 2 : f.shape === "rounded" ? f.radius : 0
        color: f.color
        border.width: f.borderWidth; border.color: f.border
    }
}
