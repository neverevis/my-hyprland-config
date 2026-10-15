// Escolhe qual animacao nomeada usar num lugar (target: bars | picker | wallpaper | workspaces | ...).
// Cada opcao mostra a curva bezier dela; passando o mouse, uma bolinha percorre a curva no tempo real da animacao.
import QtQuick

Flow {
    id: root
    property string target
    // modo de edicao (pagina Animacoes): marca "selected" e avisa por chosen() em vez de mudar a animacao em uso
    property bool editMode: false
    property string selected: ""
    signal chosen(string name)
    width: parent ? parent.width : 300
    spacing: 8

    Repeater {
        model: Settings.allAnims()
        delegate: Rectangle {
            id: opt
            required property var modelData
            readonly property bool on: root.editMode ? root.selected === modelData.name : (Settings.animUse[root.target] ?? Settings.animDefaults[root.target]) === modelData.name
            readonly property var a: modelData
            width: 156; height: 64; radius: 12
            color: on ? Theme.tint(0.16) : (om.containsMouse ? Theme.cardHi : Theme.track)
            border.width: on ? 1.5 : 1
            border.color: on ? Theme.accent : Theme.border
            Behavior on color { ColorAnimation { duration: 120 } }

            // miniatura da curva (x = tempo, y = progresso; pode passar de 0..1 nas curvas elasticas)
            Item {
                id: plot
                x: 8; anchors.verticalCenter: parent.verticalCenter
                width: 46; height: 46
                readonly property real yMin: Math.min(0, opt.a.y1 / 100, opt.a.y2 / 100)
                readonly property real yMax: Math.max(1, opt.a.y1 / 100, opt.a.y2 / 100)
                function px(x) { return 4 + x * (width - 8) }
                function py(y) { return height - 4 - (y - yMin) / (yMax - yMin) * (height - 8) }
                Rectangle { anchors.fill: parent; radius: 8; color: Qt.rgba(0, 0, 0, 0.18) }
                Canvas {
                    id: cv
                    anchors.fill: parent
                    readonly property color stroke: opt.on ? Theme.accent : Theme.text
                    onStrokeChanged: requestPaint()
                    Connections { target: opt; function onAChanged() { cv.requestPaint() } }
                    onPaint: {
                        const c = getContext("2d"); c.reset()
                        // linhas de 0 e 1
                        c.strokeStyle = Qt.rgba(1, 1, 1, 0.12); c.lineWidth = 1
                        c.beginPath(); c.moveTo(4, plot.py(0)); c.lineTo(width - 4, plot.py(0)); c.moveTo(4, plot.py(1)); c.lineTo(width - 4, plot.py(1)); c.stroke()
                        c.strokeStyle = stroke; c.lineWidth = 2; c.lineCap = "round"
                        c.beginPath()
                        c.moveTo(plot.px(0), plot.py(0))
                        c.bezierCurveTo(plot.px(opt.a.x1 / 100), plot.py(opt.a.y1 / 100), plot.px(opt.a.x2 / 100), plot.py(opt.a.y2 / 100), plot.px(1), plot.py(1))
                        c.stroke()
                    }
                }
                // bolinha que percorre a curva com a propria animacao (x anda linear no tempo, y segue a curva)
                property real tx: 0
                property real ty: 0
                ParallelAnimation {
                    loops: Animation.Infinite
                    running: om.containsMouse
                    onRunningChanged: if (!running) { plot.tx = 0; plot.ty = 0 }
                    SequentialAnimation {
                        NumberAnimation { target: plot; property: "tx"; from: 0; to: 1; duration: Math.max(60, opt.a.duration) }
                        PauseAnimation { duration: 350 }
                    }
                    SequentialAnimation {
                        NumberAnimation { target: plot; property: "ty"; from: 0; to: 1; duration: Math.max(60, opt.a.duration); easing.type: Easing.BezierSpline; easing.bezierCurve: [opt.a.x1 / 100, opt.a.y1 / 100, opt.a.x2 / 100, opt.a.y2 / 100, 1, 1] }
                        PauseAnimation { duration: 350 }
                    }
                }
                Rectangle {
                    visible: om.containsMouse
                    width: 7; height: 7; radius: 3.5
                    color: Theme.accent
                    border.width: 1.5; border.color: Theme.bg
                    x: plot.px(plot.tx) - width / 2
                    y: plot.py(plot.ty) - height / 2
                }
            }
            Column {
                anchors { left: plot.right; leftMargin: 9; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                spacing: 2
                Text { width: parent.width; elide: Text.ElideRight; wrapMode: Text.Wrap; maximumLineCount: 2; lineHeight: 0.92; text: opt.a.name; color: Theme.text; font.pixelSize: 12; font.weight: opt.on ? Font.DemiBold : Font.Medium }
                Text { text: opt.a.duration + " ms"; color: Theme.muted; font.pixelSize: 11 }
            }
            MouseArea { id: om; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (root.editMode) root.chosen(opt.modelData.name); else Settings.setUse(root.target, opt.modelData.name) } }
        }
    }
}
