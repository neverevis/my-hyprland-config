// Forma de "flor" (circulo com N petalas suaves; 0 = circulo): r(t) = R * (1 - depth * (1 - cos(N t)) / 2).
// Serve de fundo (color) ou, branca e com layer, de mascara para imagens (MultiEffect maskSource).
// shape: flower | circle | rounded | square (as outras formas tambem, para quem usa como mascara).
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

    readonly property var pts: {
        const n = 180, cx = width / 2, cy = height / 2, R = Math.min(width, height) / 2 - borderWidth / 2, out = []
        const k = Math.max(0, sides), a0 = spin * Math.PI / 180
        for (let i = 0; i <= n; i++) {
            const t = i / n * Math.PI * 2
            const r = k === 0 ? R : R * (1 - depth * (1 - Math.cos(k * (t - a0))) / 2)
            out.push(Qt.point(cx + r * Math.sin(t), cy - r * Math.cos(t)))
        }
        return out
    }
    Shape {
        anchors.fill: parent
        visible: f.shape === "flower"
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
        visible: f.shape !== "flower"
        radius: f.shape === "circle" ? Math.min(width, height) / 2 : f.shape === "rounded" ? f.radius : 0
        color: f.color
        border.width: f.borderWidth; border.color: f.border
    }
}
