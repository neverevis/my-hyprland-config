// Widget de relogio. 1x1: ponteiros (ou digital em pe); 2x1/3x1: hora grande e data; 2x2: ponteiros grandes + data.
// opts.style: "digital" | "analog" (padrao: analogico no 1x1 e 2x2, digital nos outros); opts.seconds: ponteiro de segundos
import Quickshell
import QtQuick

Item {
    id: w
    property int cols: 2
    property int rows: 1
    property var opts: ({})
    readonly property bool analog: (opts.style ?? ((cols === rows) ? "analog" : "digital")) === "analog"
    readonly property bool secs: opts.seconds ?? true
    SystemClock { id: clk; precision: w.analog && w.secs ? SystemClock.Seconds : SystemClock.Minutes }
    readonly property string dateText: { const s = clk.date.toLocaleDateString(Qt.locale("pt_BR"), "dddd, d 'de' MMMM"); return s.charAt(0).toUpperCase() + s.slice(1) }

    // ---- digital ----
    Column {
        visible: !w.analog
        anchors.centerIn: parent
        spacing: w.rows > 1 ? 6 : 0
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: w.cols === 1 && w.rows === 1 ? Qt.formatDateTime(clk.date, "HH\nmm") : Qt.formatDateTime(clk.date, "HH:mm")
            horizontalAlignment: Text.AlignHCenter
            lineHeight: 0.85
            font.features: { "tnum": 1 }
            font.pixelSize: w.cols === 1 ? 46 : (w.rows > 1 ? 96 : (w.cols >= 3 ? 76 : 64))
            font.weight: Font.Bold; font.letterSpacing: -2
            color: Theme.text
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: w.cols > 1
            text: w.dateText
            font.pixelSize: w.rows > 1 ? 17 : 14; font.weight: Font.Medium
            color: Theme.accent
        }
    }

    // ---- ponteiros ----
    Item {
        visible: w.analog
        anchors.fill: parent
        Item {
            id: face
            readonly property real d: Math.min(w.width, w.height - (w.rows > 1 ? 34 : 0))
            width: d; height: d
            anchors.horizontalCenter: parent.horizontalCenter
            y: (w.height - (w.rows > 1 ? 34 : 0) - d) / 2
            Rectangle { anchors.fill: parent; radius: width / 2; color: Theme.tint(0.08); border.width: 1; border.color: Theme.tint(0.25) }
            Canvas {
                id: marks
                anchors.fill: parent
                readonly property var deps: [Theme.text, Theme.accent, width]
                onDepsChanged: requestPaint()
                onPaint: {
                    const c = getContext("2d"); c.reset()
                    const r = width / 2
                    for (let i = 0; i < 12; i++) {
                        const a = i / 12 * Math.PI * 2, big = i % 3 === 0
                        c.strokeStyle = big ? Theme.text : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.35)
                        c.lineWidth = big ? 3 : 2; c.lineCap = "round"
                        c.beginPath()
                        c.moveTo(r + Math.sin(a) * (r - 8), r - Math.cos(a) * (r - 8))
                        c.lineTo(r + Math.sin(a) * (r - (big ? 18 : 13)), r - Math.cos(a) * (r - (big ? 18 : 13)))
                        c.stroke()
                    }
                }
            }
            component Hand: Rectangle {
                property real angle: 0
                property real len: 0.6
                width: 4; height: face.d / 2 * len
                radius: width / 2
                x: face.d / 2 - width / 2; y: face.d / 2 - height
                transformOrigin: Item.Bottom
                rotation: angle
                antialiasing: true
            }
            Hand { width: 6; len: 0.5; color: Theme.text; angle: (clk.date.getHours() % 12 + clk.date.getMinutes() / 60) * 30 }
            Hand { width: 4; len: 0.72; color: Theme.text; angle: (clk.date.getMinutes() + clk.date.getSeconds() / 60) * 6 }
            Hand { visible: w.secs; width: 2; len: 0.8; color: Theme.accent; angle: clk.date.getSeconds() * 6
                Behavior on angle { enabled: clk.date.getSeconds() !== 0; NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 2 } } }
            Rectangle { anchors.centerIn: parent; width: 12; height: 12; radius: 6; color: Theme.accent; border.width: 3; border.color: Theme.bg }
        }
        Text {
            visible: w.rows > 1
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
            text: Qt.formatDateTime(clk.date, "HH:mm") + "  ·  " + w.dateText
            font.pixelSize: 14; font.weight: Font.Medium
            color: Theme.muted
        }
    }
}
