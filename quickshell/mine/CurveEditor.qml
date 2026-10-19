// Editor/visualizador de uma animacao: curva de bezier (x1,y1,x2,y2 em centesimos; y de -50% a 150%) ou mola.
// Grade, area sob a curva, pinos arrastaveis so nas curvas (Shift: encaixa de 5 em 5) e, tocando, uma bolinha que
// rola pela curva deixando rastro. Uma marca mostra quando a animacao ja "parece pronta" (a menos de 2% do fim).
// "t" (tempo, 0..1) e "e" (valor) ficam expostos para outras previas usarem o mesmo relogio.
import QtQuick

Rectangle {
    id: graph
    property var anim: ({ x1: 0, y1: 0, x2: 100, y2: 100, duration: 300 })
    readonly property bool spring: anim && anim.type === "spring"
    readonly property int x1: anim.x1 ?? 0
    readonly property int y1: anim.y1 ?? 0
    readonly property int x2: anim.x2 ?? 100
    readonly property int y2: anim.y2 ?? 100
    readonly property var comp: Motion.compile(anim)
    readonly property int duration: comp.duration
    property bool editable: true
    property bool playing: true       // reproduz em loop
    property real speed: 1            // 0.25 = camera lenta
    signal edited(var vals)           // { x1, y1, x2, y2 } (so o que mudou)

    function ease(t) { return comp.sample(t) }
    readonly property var pts: Motion.points(anim, 160)
    // quando fica a menos de 2% do fim e nao sai mais
    readonly property real ready: {
        for (let i = pts.length - 1; i >= 0; i--) if (Math.abs(1 - pts[i][1]) > 0.02) return pts[Math.min(pts.length - 1, i + 1)][0]
        return 0
    }

    // relogio compartilhado: t anda linear no tempo; e = curva(t)
    property real t: 0
    readonly property real e: ease(t)
    SequentialAnimation {
        id: clock
        running: graph.playing && graph.visible
        loops: Animation.Infinite
        NumberAnimation { target: graph; property: "t"; from: 0; to: 1; duration: Math.max(50, graph.duration / graph.speed) }
        PauseAnimation { duration: 650 }
        ScriptAction { script: { graph.t = 0; trail.pts = []; trail.requestPaint() } }
        PauseAnimation { duration: 150 }
    }
    onPlayingChanged: if (!playing) { t = 0; trail.pts = []; trail.requestPaint() }
    function replay() { trail.pts = []; clock.restart() }

    height: 300; radius: 14
    color: Theme.bg; border.width: 1; border.color: Theme.border

    Item {
        id: cv
        anchors { fill: parent; margins: 18; leftMargin: 44; bottomMargin: 30 }
        readonly property real fx1: graph.x1 / 100
        readonly property real fy1: graph.y1 / 100
        readonly property real fx2: graph.x2 / 100
        readonly property real fy2: graph.y2 / 100
        // y vai de -50% (embaixo) a 150% (em cima); x de 0 a 100%
        function px(x) { return x * width }
        function py(y) { return height * (1 - (y + 0.5) / 2) }

        // grade, area e curva
        Canvas {
            id: base
            anchors.fill: parent
            readonly property var deps: [graph.pts, graph.spring, Theme.accent, Theme.border, width, height]
            onDepsChanged: requestPaint()
            onPaint: {
                const c = getContext("2d"); c.reset()
                const W = width
                c.lineWidth = 1
                // grade: quartos do tempo e do progresso
                for (let i = 0; i <= 4; i++) {
                    c.strokeStyle = Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, i === 0 || i === 4 ? 0.9 : 0.45)
                    c.beginPath(); c.moveTo(cv.px(i / 4), cv.py(-0.5)); c.lineTo(cv.px(i / 4), cv.py(1.5)); c.stroke()
                }
                for (const y of [-0.5, 0, 0.25, 0.5, 0.75, 1, 1.5]) {
                    const main = y === 0 || y === 1
                    c.strokeStyle = Qt.rgba(Theme.border.r, Theme.border.g, Theme.border.b, main ? 1 : 0.35)
                    c.setLineDash(main ? [] : [3, 4])
                    c.beginPath(); c.moveTo(0, cv.py(y)); c.lineTo(W, cv.py(y)); c.stroke()
                }
                // linha reta (linear) de referencia
                c.strokeStyle = Qt.rgba(1, 1, 1, 0.12); c.setLineDash([5, 5])
                c.beginPath(); c.moveTo(cv.px(0), cv.py(0)); c.lineTo(cv.px(1), cv.py(1)); c.stroke()
                c.setLineDash([])
                const curve = () => graph.pts.forEach((p, i) => i ? c.lineTo(cv.px(p[0]), cv.py(Math.max(-0.5, Math.min(1.5, p[1])))) : c.moveTo(cv.px(p[0]), cv.py(p[1])))
                // area sob a curva (ate o 0)
                const g = c.createLinearGradient(0, cv.py(1.2), 0, cv.py(0))
                g.addColorStop(0, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.28))
                g.addColorStop(1, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.02))
                c.fillStyle = g
                c.beginPath(); curve(); c.lineTo(cv.px(1), cv.py(0)); c.closePath(); c.fill()
                // alavancas (so curvas)
                if (!graph.spring) {
                    c.strokeStyle = Qt.rgba(1, 1, 1, 0.35); c.lineWidth = 1.5
                    c.beginPath(); c.moveTo(cv.px(0), cv.py(0)); c.lineTo(cv.px(cv.fx1), cv.py(cv.fy1)); c.moveTo(cv.px(1), cv.py(1)); c.lineTo(cv.px(cv.fx2), cv.py(cv.fy2)); c.stroke()
                }
                // curva
                c.strokeStyle = Theme.accent; c.lineWidth = 3; c.lineCap = "round"; c.lineJoin = "round"
                c.beginPath(); curve(); c.stroke()
            }
        }
        // rotulos dos eixos
        Repeater {
            model: [[-0.5, "-50%"], [0, "0"], [0.5, "50%"], [1, "100%"], [1.5, "150%"]]
            delegate: UiText {
                required property var modelData
                x: -width - 8; y: cv.py(modelData[0]) - height / 2
                text: modelData[1]; color: Theme.muted; font.pixelSize: 10
            }
        }
        UiText { anchors { right: parent.right; top: parent.bottom; topMargin: 7 } text: graph.duration + " ms"; color: Theme.muted; font.pixelSize: 10 }
        UiText { anchors { left: parent.left; top: parent.bottom; topMargin: 7 } text: "0"; color: Theme.muted; font.pixelSize: 10 }
        UiText { anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 7 } text: "tempo"; color: Theme.muted; font.pixelSize: 10 }

        // "parece pronta": a partir daqui o movimento restante e imperceptivel
        Rectangle {
            visible: graph.ready > 0.02 && graph.ready < 0.97
            x: cv.px(graph.ready); width: 1; height: parent.height
            color: Qt.rgba(1, 1, 1, 0.22)
            Rectangle {
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
                width: rdy.implicitWidth + 10; height: 18; radius: 6
                color: Theme.card; border.width: 1; border.color: Theme.border
                UiText { id: rdy; anchors.centerIn: parent; text: "pronta em " + Math.round(graph.ready * graph.duration) + " ms"; color: Theme.muted; font.pixelSize: 10 }
            }
        }
        // linha do tempo e rastro da bolinha
        Rectangle {
            visible: graph.playing && graph.t > 0
            x: cv.px(graph.t); width: 1.5; height: parent.height
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45)
        }
        Rectangle {   // nivel atual do valor (linha horizontal ate a bolinha)
            visible: graph.playing && graph.t > 0
            y: cv.py(graph.e); height: 1; width: cv.px(graph.t)
            color: Qt.rgba(1, 1, 1, 0.14)
        }
        Canvas {
            id: trail
            anchors.fill: parent
            property var pts: []
            Connections {
                target: graph
                function onTChanged() {
                    if (!graph.playing || graph.t <= 0) return
                    trail.pts.push([cv.px(graph.t), cv.py(graph.e)])
                    if (trail.pts.length > 40) trail.pts.shift()
                    trail.requestPaint()
                }
            }
            onPaint: {
                const c = getContext("2d"); c.reset()
                const n = pts.length
                c.lineCap = "round"
                for (let i = 1; i < n; i++) {
                    const k = i / n
                    c.strokeStyle = Qt.rgba(1, 1, 1, 0.55 * k * k)
                    c.lineWidth = 1 + 5 * k
                    c.beginPath(); c.moveTo(pts[i - 1][0], pts[i - 1][1]); c.lineTo(pts[i][0], pts[i][1]); c.stroke()
                }
            }
        }
        Rectangle {   // a bolinha
            visible: graph.playing && graph.t > 0
            width: 14; height: 14; radius: 7
            x: cv.px(graph.t) - width / 2; y: cv.py(graph.e) - height / 2
            color: "white"
            border.width: 3; border.color: Theme.accent
        }

        // pinos (so curvas)
        Repeater {
            model: graph.spring ? 0 : 2
            delegate: Item {
                id: pin
                required property int index
                readonly property bool first: index === 0
                readonly property int vx: first ? graph.x1 : graph.x2
                readonly property int vy: first ? graph.y1 : graph.y2
                width: 20; height: 20
                x: cv.px(vx / 100) - width / 2
                y: cv.py(vy / 100) - height / 2
                Rectangle {
                    anchors.fill: parent; radius: 10
                    color: Theme.bg; border.width: 3; border.color: graph.editable ? Theme.accent : Theme.muted
                    scale: pinMouse.pressed ? 1.25 : (pinMouse.containsMouse ? 1.1 : 1)
                    Behavior on scale { NumberAnimation { duration: 110 } }
                    Rectangle { anchors.centerIn: parent; width: 6; height: 6; radius: 3; color: graph.editable ? Theme.accent : Theme.muted }
                }
                // valor enquanto arrasta / passa o mouse
                Rectangle {
                    visible: pinMouse.pressed || pinMouse.containsMouse
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.top; bottomMargin: 6 }
                    width: tip.implicitWidth + 12; height: 20; radius: 6
                    color: Theme.card; border.width: 1; border.color: Theme.border
                    UiText { id: tip; anchors.centerIn: parent; text: (pin.vx / 100).toFixed(2) + ", " + (pin.vy / 100).toFixed(2); color: Theme.text; font.pixelSize: 10; font.family: "monospace" }
                }
                MouseArea {
                    id: pinMouse
                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    enabled: graph.editable
                    cursorShape: graph.editable ? (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.ArrowCursor
                    onPositionChanged: m => {
                        if (!pressed) return
                        const p = mapToItem(cv, m.x, m.y)
                        const snap = (m.modifiers & Qt.ShiftModifier) ? 5 : 1
                        const vx = Math.round(Math.max(0, Math.min(1, p.x / cv.width)) * 100 / snap) * snap
                        const vy = Math.round(Math.max(-0.5, Math.min(1.5, (1 - p.y / cv.height) * 2 - 0.5)) * 100 / snap) * snap
                        graph.edited(pin.first ? { x1: vx, y1: vy } : { x2: vx, y2: vy })
                    }
                }
            }
        }
    }
}
