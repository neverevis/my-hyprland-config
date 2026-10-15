// Grafico de curva de bezier com pinos arrastaveis (x1,y1,x2,y2 em centesimos) e uma bolinha para a duracao.
import QtQuick
import QtQuick.Shapes

Rectangle {
    id: graph
    property int x1: 0
    property int y1: 0
    property int x2: 100
    property int y2: 100
    property int duration: 300
    property bool editable: true
    signal edited(var vals)   // { x1, y1, x2, y2, duration } (so o que mudou)

    height: 250; radius: 10
    color: Theme.bg; border.width: 1; border.color: Theme.border

    Item {
        id: cv
        anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; margins: 16; bottomMargin: 56 }
        readonly property real fx1: graph.x1 / 100
        readonly property real fy1: graph.y1 / 100
        readonly property real fx2: graph.x2 / 100
        readonly property real fy2: graph.y2 / 100
        // y vai de -50% (embaixo) a 150% (em cima); x de 0 a 100%
        function px(x) { return x * width }
        function py(y) { return height * (1 - (y + 0.5) / 2) }

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath { strokeColor: Theme.border; strokeWidth: 1; fillColor: "transparent"; startX: 0; startY: cv.py(0); PathLine { x: cv.width; y: cv.py(0) } }
            ShapePath { strokeColor: Theme.border; strokeWidth: 1; fillColor: "transparent"; startX: 0; startY: cv.py(1); PathLine { x: cv.width; y: cv.py(1) } }
            ShapePath { strokeColor: Theme.muted; strokeWidth: 1; fillColor: "transparent"; startX: cv.px(0); startY: cv.py(0); PathLine { x: cv.px(cv.fx1); y: cv.py(cv.fy1) } }
            ShapePath { strokeColor: Theme.muted; strokeWidth: 1; fillColor: "transparent"; startX: cv.px(1); startY: cv.py(1); PathLine { x: cv.px(cv.fx2); y: cv.py(cv.fy2) } }
            ShapePath {
                strokeColor: Theme.accent; strokeWidth: 3; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                startX: cv.px(0); startY: cv.py(0)
                PathCubic {
                    x: cv.px(1); y: cv.py(1)
                    control1X: cv.px(cv.fx1); control1Y: cv.py(cv.fy1)
                    control2X: cv.px(cv.fx2); control2Y: cv.py(cv.fy2)
                }
            }
        }

        Repeater {
            model: 2
            delegate: Rectangle {
                id: pin
                required property int index
                readonly property bool first: index === 0
                width: 18; height: 18; radius: 9
                color: "#ffffff"; border.width: 3; border.color: graph.editable ? Theme.accent : Theme.muted
                x: cv.px(first ? cv.fx1 : cv.fx2) - width / 2
                y: cv.py(first ? cv.fy1 : cv.fy2) - height / 2
                scale: pinMouse.pressed ? 1.2 : 1
                MouseArea {
                    id: pinMouse
                    anchors.fill: parent
                    anchors.margins: -6
                    enabled: graph.editable
                    cursorShape: graph.editable ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onPositionChanged: m => {
                        if (!pressed) return
                        const p = mapToItem(cv, m.x, m.y)
                        const vx = Math.round(Math.max(0, Math.min(1, p.x / cv.width)) * 100)
                        const vy = Math.round(Math.max(-0.5, Math.min(1.5, (1 - p.y / cv.height) * 2 - 0.5)) * 100)
                        graph.edited(pin.first ? { x1: vx, y1: vy } : { x2: vx, y2: vy })
                    }
                }
            }
        }
    }

    // eixo do tempo: arraste a bolinha para mudar a duracao (0 a 1500 ms)
    Item {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 16; bottomMargin: 14 }
        height: 30
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: Theme.cardHi }
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: tknob.x + tknob.width / 2; height: 4; radius: 2; color: graph.editable ? Theme.accent : Theme.muted }
        Rectangle {
            id: tknob
            anchors.verticalCenter: parent.verticalCenter
            width: 18; height: 18; radius: 9
            x: Math.max(0, Math.min(1, graph.duration / 1500)) * (parent.width - width)
            color: "#ffffff"; border.width: 3; border.color: graph.editable ? Theme.accent : Theme.muted
            scale: tmouse.pressed ? 1.2 : 1
        }
        Text { anchors.right: parent.right; anchors.top: parent.top; text: graph.duration + " ms"; color: Theme.muted; font.pixelSize: 12 }
        Text { anchors.left: parent.left; anchors.top: parent.top; text: "duração"; color: Theme.muted; font.pixelSize: 12 }
        MouseArea {
            id: tmouse
            anchors.fill: parent
            enabled: graph.editable
            cursorShape: graph.editable ? Qt.PointingHandCursor : Qt.ArrowCursor
            function upd(x) {
                const t = Math.max(0, Math.min(1, (x - tknob.width / 2) / (width - tknob.width)))
                graph.edited({ duration: Math.max(50, Math.round(t * 1500 / 10) * 10) })
            }
            onPressed: m => upd(m.x)
            onPositionChanged: m => { if (pressed) upd(m.x) }
        }
    }
}
