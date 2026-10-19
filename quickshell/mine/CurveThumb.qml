// Miniatura de uma animacao (curva ou mola): x = tempo, y = progresso (pode passar de 0..1).
// playing: uma bolinha percorre a curva com a propria animacao, no tempo real (mesma spline que a interface usa).
import QtQuick

Item {
    id: plot
    property var anim: null
    property bool playing: false
    property color stroke: Theme.text
    property real pad: 4
    width: 46; height: 46

    readonly property var pts: anim ? Motion.points(anim, 48) : []
    readonly property real yMin: Math.min(0, ...pts.map(p => p[1]))
    readonly property real yMax: Math.max(1, ...pts.map(p => p[1]))
    function px(x) { return pad + x * (width - pad * 2) }
    function py(y) { return height - pad - (y - yMin) / Math.max(0.01, yMax - yMin) * (height - pad * 2) }

    Rectangle { anchors.fill: parent; radius: Math.min(8, width / 5); color: Qt.rgba(0, 0, 0, 0.18) }
    Canvas {
        id: cv
        anchors.fill: parent
        readonly property var deps: [plot.pts, plot.stroke, width, height]
        onDepsChanged: requestPaint()
        onPaint: {
            const c = getContext("2d"); c.reset()
            if (!plot.pts.length) return
            c.strokeStyle = Qt.rgba(1, 1, 1, 0.12); c.lineWidth = 1
            c.beginPath(); c.moveTo(plot.pad, plot.py(0)); c.lineTo(width - plot.pad, plot.py(0)); c.moveTo(plot.pad, plot.py(1)); c.lineTo(width - plot.pad, plot.py(1)); c.stroke()
            c.strokeStyle = plot.stroke; c.lineWidth = 2; c.lineCap = "round"; c.lineJoin = "round"
            c.beginPath()
            plot.pts.forEach((p, i) => i ? c.lineTo(plot.px(p[0]), plot.py(p[1])) : c.moveTo(plot.px(p[0]), plot.py(p[1])))
            c.stroke()
        }
    }
    property real tx: 0
    property real ty: 0
    readonly property var m: anim ? Motion.compile(anim) : ({ duration: 300, curve: [0, 0, 1, 1, 1, 1] })
    ParallelAnimation {
        loops: Animation.Infinite
        running: plot.playing && plot.visible
        onRunningChanged: if (!running) { plot.tx = 0; plot.ty = 0 }
        SequentialAnimation {
            NumberAnimation { target: plot; property: "tx"; from: 0; to: 1; duration: Math.max(60, plot.m.duration) }
            PauseAnimation { duration: 350 }
        }
        SequentialAnimation {
            NumberAnimation { target: plot; property: "ty"; from: 0; to: 1; duration: Math.max(60, plot.m.duration); easing.type: Easing.BezierSpline; easing.bezierCurve: plot.m.curve }
            PauseAnimation { duration: 350 }
        }
    }
    Rectangle {
        visible: plot.playing
        width: 7; height: 7; radius: 3.5
        color: Theme.accent
        border.width: 1.5; border.color: Theme.bg
        x: plot.px(plot.tx) - width / 2
        y: plot.py(plot.ty) - height / 2
    }
}
