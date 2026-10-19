// Widget de relogio. Estilos (opts.style): digital (numeros que rolam ao trocar), analog (flor com N petalas, mostrador,
// ponteiros e data em varios estilos), daily (selo / saudacao / manuscrito / forte), pixel (matriz de pontos).
// "auto": flor nos tamanhos quadrados, digital nos outros. Frase opcional embaixo. Opcoes: ver DeskState.catalog (clock).
import Quickshell
import QtQuick

Item {
    id: w
    property int cols: 2
    property int rows: 1
    property var opts: ({})
    property color fg: Theme.text
    property color dim: Theme.muted
    property color ac: Theme.accent
    property bool bare: false
    function o(k) { return DeskState.opt({ type: "clock", opts: w.opts }, k) }

    readonly property string style: { const s = o("style"); return s === "auto" ? (cols === rows ? "analog" : "digital") : s }
    readonly property bool secs: o("seconds")
    readonly property bool h12: o("h12")
    readonly property real sc: o("scale") / 100
    readonly property string fontFam: o("font") || Qt.application.font.family
    readonly property string quote: o("quote")
    readonly property real quoteH: quote !== "" ? Math.min(34, height * 0.18) : 0
    SystemClock { id: clk; precision: w.secs || w.style === "analog" ? SystemClock.Seconds : SystemClock.Minutes }
    readonly property var loc: Qt.locale("pt_BR")
    function cap(s) { return s.charAt(0).toUpperCase() + s.slice(1) }
    readonly property string hh: { const h = clk.date.getHours(); return h12 ? String((h + 11) % 12 + 1) : String(h).padStart(2, "0") }
    readonly property string mm: String(clk.date.getMinutes()).padStart(2, "0")
    readonly property string ss: String(clk.date.getSeconds()).padStart(2, "0")
    readonly property string ampm: clk.date.getHours() < 12 ? "AM" : "PM"
    readonly property string dateText: cap(clk.date.toLocaleDateString(loc, "dddd, d 'de' MMMM"))
    readonly property string greet: { const h = clk.date.getHours(); return h < 5 ? "Boa noite" : h < 12 ? "Bom dia" : h < 18 ? "Boa tarde" : "Boa noite" }

    readonly property real bodyH: height - quoteH

    // ================= digital =================
    Item {
        id: dig
        visible: w.style === "digital"
        width: parent.width; height: w.bodyH
        readonly property bool vert: w.o("vertical")
        readonly property bool showSecs: w.secs && !vert && w.cols >= 2
        readonly property string line1: vert ? w.hh : w.hh + ":" + w.mm + (showSecs ? ":" + w.ss : "")
        readonly property real dateH: w.o("date") && w.rows * w.cols > 1 ? Math.max(14, height * (vert ? 0.12 : 0.17)) : 0
        readonly property real fs: (vert ? Math.min((height - dateH) / 2.1, width / 1.5) : Math.min((height - dateH) * 0.92, width / (line1.length * 0.6 + (w.h12 ? 1.4 : 0)))) * w.sc
        readonly property int al: { const a = w.o("align"); return a === "left" ? Text.AlignLeft : a === "right" ? Text.AlignRight : Text.AlignHCenter }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: 0
            Row {
                anchors.horizontalCenter: dig.al === Text.AlignHCenter ? parent.horizontalCenter : undefined
                anchors.right: dig.al === Text.AlignRight ? parent.right : undefined
                spacing: 0
                Repeater {
                    model: dig.line1.split("")
                    delegate: Roll { required property var modelData; ch: modelData; size: dig.fs }
                }
                Text { visible: w.h12; text: " " + w.ampm; color: w.dim; font.family: w.fontFam; font.pixelSize: dig.fs * 0.3; font.weight: Font.DemiBold; anchors.baseline: parent.bottom; anchors.baselineOffset: -dig.fs * 0.18 }
            }
            Row {
                visible: dig.vert
                anchors.horizontalCenter: dig.al === Text.AlignHCenter ? parent.horizontalCenter : undefined
                anchors.right: dig.al === Text.AlignRight ? parent.right : undefined
                Repeater { model: w.mm.split(""); delegate: Roll { required property var modelData; ch: modelData; size: dig.fs; tint: w.ac } }
            }
            Text {
                visible: dig.dateH > 0
                width: parent.width
                horizontalAlignment: dig.al
                text: w.dateText
                color: w.ac
                font.family: w.fontFam; font.pixelSize: dig.dateH * 0.8 * Math.min(1.2, w.sc); font.weight: Font.Medium
                elide: Text.ElideRight
            }
        }
    }
    // digito que rola para cima ao trocar
    component Roll: Item {
        id: rl
        property string ch: "0"
        property real size: 40
        property color tint: w.fg
        property string prev: ch
        property real k: 1
        width: Math.max(cur.implicitWidth, old.implicitWidth); height: cur.implicitHeight * 0.92
        clip: true
        onChChanged: { if (w.o("animate") && w.style !== "pixel") { prev = old.text; k = 0; rollA.restart() } else old.text = ch }
        NumberAnimation { id: rollA; target: rl; property: "k"; from: 0; to: 1; duration: 420; easing.type: Easing.OutCubic; onFinished: old.text = rl.ch }
        Text { id: old; text: rl.ch; y: -rl.k * rl.height * 0.9; opacity: 1 - rl.k; color: rl.tint; font.family: w.fontFam; font.pixelSize: rl.size; font.weight: w.o("weight"); font.features: { "tnum": 1 }; visible: rl.k < 1 }
        Text { id: cur; text: rl.ch; y: (1 - rl.k) * rl.height * 0.9; opacity: rl.k; color: rl.tint; font.family: w.fontFam; font.pixelSize: rl.size; font.weight: w.o("weight"); font.features: { "tnum": 1 } }
    }

    // ================= flor (analogico) =================
    Item {
        id: an
        visible: w.style === "analog"
        width: parent.width; height: w.bodyH
        readonly property real d: Math.min(width, height) * Math.min(1, 0.9 * w.sc + 0.1)
        readonly property color body: w.bare ? Qt.tint(Theme.bg, Qt.rgba(w.ac.r, w.ac.g, w.ac.b, 0.32)) : Qt.rgba(w.ac.r, w.ac.g, w.ac.b, 0.14)
        readonly property color ink: Qt.tint(w.ac, Qt.rgba(1, 1, 1, 0.35))
        Item {
            id: face
            width: an.d; height: an.d
            anchors.centerIn: parent
            Flower {
                anchors.fill: parent
                sides: w.o("sides")
                color: an.body
                RotationAnimation on spin { running: w.o("rotate") && an.visible; from: 0; to: 360; duration: 40000; loops: Animation.Infinite }
            }
            // mostrador
            Canvas {
                id: dial
                anchors.fill: parent
                readonly property string mode: w.o("dial")
                readonly property var deps: [mode, an.ink, w.fg, width]
                onDepsChanged: requestPaint()
                onPaint: {
                    const c = getContext("2d"); c.reset()
                    const r = width / 2, R = r * 0.8
                    if (mode === "none") return
                    for (let i = 0; i < 60; i++) {
                        const a = i / 60 * Math.PI * 2, hour = i % 5 === 0, big = i % 15 === 0
                        const sx = Math.sin(a), cy = -Math.cos(a)
                        if (mode === "dots" && hour) {
                            c.fillStyle = big ? an.ink : Qt.rgba(an.ink.r, an.ink.g, an.ink.b, 0.6)
                            c.beginPath(); c.arc(r + sx * R, r + cy * R, big ? r * 0.045 : r * 0.03, 0, Math.PI * 2); c.fill()
                        } else if (mode === "lines" || mode === "full") {
                            if (mode === "full" && hour) continue
                            c.strokeStyle = Qt.rgba(an.ink.r, an.ink.g, an.ink.b, hour ? 0.9 : 0.35)
                            c.lineWidth = hour ? r * 0.035 : r * 0.015; c.lineCap = "round"
                            const r0 = hour ? R - r * 0.1 : R - r * 0.04
                            c.beginPath(); c.moveTo(r + sx * r0, r + cy * r0); c.lineTo(r + sx * R, r + cy * R); c.stroke()
                        }
                        if ((mode === "numbers" && big) || (mode === "full" && hour)) {
                            const n = i === 0 ? 12 : i / 5
                            c.fillStyle = an.ink
                            c.font = "bold " + Math.round(r * (mode === "full" ? 0.16 : 0.22)) + "px sans-serif"
                            c.textAlign = "center"; c.textBaseline = "middle"
                            const rn = mode === "full" ? R - r * 0.02 : R - r * 0.04
                            c.fillText(String(n), r + sx * rn, r + cy * rn)
                        }
                    }
                }
            }
            // data no mostrador (lado das 3 horas)
            Rectangle {
                readonly property string ds: w.o("dateStyle")
                visible: ds !== "hide" && face.width > 110
                x: face.width * 0.62; y: face.height / 2 - height / 2
                width: ds === "bubble" ? face.width * 0.2 : dtx.implicitWidth + face.width * 0.06
                height: ds === "bubble" ? width : face.width * 0.13
                radius: ds === "bubble" ? width / 2 : height * 0.3
                color: ds === "border" ? "transparent" : (ds === "rect" ? w.ac : Qt.rgba(w.ac.r, w.ac.g, w.ac.b, 0.28))
                border.width: ds === "border" ? Math.max(1.5, face.width * 0.012) : 0
                border.color: an.ink
                Text {
                    id: dtx
                    anchors.centerIn: parent
                    text: parent.ds === "bubble" ? String(clk.date.getDate()) : w.cap(clk.date.toLocaleDateString(w.loc, "ddd")).replace(".", "") + " " + clk.date.getDate()
                    color: parent.ds === "rect" ? Theme.accentText : an.ink
                    font.pixelSize: face.width * (parent.ds === "bubble" ? 0.09 : 0.065); font.weight: Font.Bold
                }
            }
            component Hand: Item {
                id: hd
                property real angle: 0
                property real len: 0.6
                property real thick: 6
                property color col: an.ink
                property bool hollow: false
                property bool tail: false
                width: thick; height: face.width / 2 * len + (tail ? face.width * 0.08 : 0)
                x: face.width / 2 - width / 2; y: face.width / 2 - face.width / 2 * len
                transformOrigin: Item.Top
                transform: Rotation { origin.x: hd.width / 2; origin.y: face.width / 2 * hd.len; angle: hd.angle }
                Rectangle { anchors.fill: parent; radius: width / 2; color: hd.hollow ? "transparent" : hd.col; border.width: hd.hollow ? Math.max(2, hd.thick * 0.22) : 0; border.color: hd.col; antialiasing: true }
            }
            readonly property real hA: (clk.date.getHours() % 12 + clk.date.getMinutes() / 60) * 30
            readonly property real mA: (clk.date.getMinutes() + clk.date.getSeconds() / 60) * 6
            readonly property real sA: clk.date.getSeconds() * 6
            Hand {
                readonly property string st: w.o("hourHand")
                visible: st !== "hide"
                angle: face.hA; len: 0.5
                thick: st === "classic" ? face.width * 0.035 : face.width * 0.085
                hollow: st === "hollow"
                col: st === "classic" ? w.fg : w.ac
            }
            Hand {
                readonly property string st: w.o("minuteHand")
                visible: st !== "hide"
                angle: face.mA; len: 0.72
                thick: ({ classic: 0.025, thin: 0.018, medium: 0.045, bold: 0.07 })[st] * face.width
                col: st === "classic" ? w.fg : an.ink
            }
            Hand {
                readonly property string st: w.o("secondHand")
                visible: w.secs && (st === "line" || st === "classic")
                angle: face.sA; len: 0.8; thick: Math.max(1.5, face.width * 0.012); tail: st === "classic"
                col: w.ac
            }
            // segundos como bolinha andando na borda
            Rectangle {
                visible: w.secs && w.o("secondHand") === "dot"
                readonly property real rr: face.width * 0.4
                width: face.width * 0.05; height: width; radius: width / 2
                color: w.ac
                x: face.width / 2 + Math.sin(face.sA * Math.PI / 180) * rr - width / 2
                y: face.width / 2 - Math.cos(face.sA * Math.PI / 180) * rr - height / 2
            }
            Rectangle { anchors.centerIn: parent; width: face.width * 0.06; height: width; radius: width / 2; color: w.ac; border.width: width * 0.25; border.color: an.body }
        }
    }

    // ================= diario =================
    Item {
        id: dl
        visible: w.style === "daily"
        width: parent.width; height: w.bodyH
        readonly property string v: w.o("variant")
        readonly property real fs: Math.min(height * 0.5, width / 4.2) * w.sc
        readonly property int al: { const a = w.o("align"); return a === "left" ? Text.AlignLeft : a === "right" ? Text.AlignRight : Text.AlignHCenter }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: dl.fs * 0.06
            // selo com o dia da semana
            Rectangle {
                visible: dl.v === "badge"
                anchors.horizontalCenter: dl.al === Text.AlignHCenter ? parent.horizontalCenter : undefined
                anchors.right: dl.al === Text.AlignRight ? parent.right : undefined
                height: dl.fs * 0.34; width: bt.implicitWidth + height; radius: height / 2
                color: w.ac
                Text { id: bt; anchors.centerIn: parent; text: w.cap(clk.date.toLocaleDateString(w.loc, "dddd")); color: Theme.accentText; font.family: w.fontFam; font.pixelSize: parent.height * 0.55; font.weight: Font.Bold }
            }
            Text {
                visible: dl.v === "morning"
                width: parent.width; horizontalAlignment: dl.al
                text: w.greet + ", " + Profile.name.split(" ")[0]
                color: w.dim; font.family: w.fontFam; font.pixelSize: dl.fs * 0.26; font.weight: Font.Medium; elide: Text.ElideRight
            }
            Text {
                visible: dl.v === "bold"
                width: parent.width; horizontalAlignment: dl.al
                text: clk.date.toLocaleDateString(w.loc, "dddd").toUpperCase()
                color: "transparent"; style: Text.Outline; styleColor: w.ac
                font.family: w.fontFam; font.pixelSize: dl.fs * 0.55; font.weight: Font.Black; font.letterSpacing: dl.fs * 0.02
                fontSizeMode: Text.HorizontalFit; minimumPixelSize: 10
            }
            Text {
                width: parent.width; horizontalAlignment: dl.al
                text: w.hh + ":" + w.mm + (w.h12 ? " " + w.ampm : "")
                color: w.fg
                font.family: dl.v === "script" ? DeskWidgets.script : w.fontFam
                font.pixelSize: dl.v === "script" ? dl.fs * 1.15 : dl.fs; font.weight: dl.v === "script" ? Font.Normal : w.o("weight")
                font.features: { "tnum": 1 }
            }
            Text {
                visible: w.o("date")
                width: parent.width; horizontalAlignment: dl.al
                text: dl.v === "script" ? clk.date.toLocaleDateString(w.loc, "d 'de' MMMM") : w.dateText
                color: dl.v === "badge" ? w.dim : w.ac
                font.family: dl.v === "script" ? DeskWidgets.script : w.fontFam
                font.pixelSize: dl.fs * (dl.v === "script" ? 0.36 : 0.24); font.weight: Font.Medium
                elide: Text.ElideRight
            }
        }
    }

    // ================= pixel =================
    Item {
        id: px
        visible: w.style === "pixel"
        width: parent.width; height: w.bodyH
        readonly property var glyphs: ({
            "0": ["01110", "10001", "10011", "10101", "11001", "10001", "01110"], "1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
            "2": ["01110", "10001", "00001", "00010", "00100", "01000", "11111"], "3": ["11111", "00010", "00100", "00010", "00001", "10001", "01110"],
            "4": ["00010", "00110", "01010", "10010", "11111", "00010", "00010"], "5": ["11111", "10000", "11110", "00001", "00001", "10001", "01110"],
            "6": ["00110", "01000", "10000", "11110", "10001", "10001", "01110"], "7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
            "8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"], "9": ["01110", "10001", "10001", "01111", "00001", "00010", "01100"],
            ":": ["0", "1", "1", "0", "1", "1", "0"] })
        readonly property bool vert: w.rows > w.cols
        readonly property var lines: vert ? [w.hh, w.mm] : [w.hh + ":" + w.mm]
        readonly property real ps: Math.min(w.o("pixelSize") * w.sc, vert ? height / 17 : Math.min(height / 8, width / ((lines[0].length - 1) * 6.2 + 2)))
        Column {
            anchors.centerIn: parent
            spacing: px.ps * 1.4
            Repeater {
                model: px.lines
                delegate: Row {
                    id: lineRow
                    required property var modelData
                    required property int index
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: px.ps * 1.0
                    Repeater {
                        model: modelData.split("")
                        delegate: Grid {
                            required property var modelData
                            readonly property var g: px.glyphs[modelData] ?? px.glyphs["0"]
                            columns: g[0].length
                            spacing: px.ps * 0.18
                            Repeater {
                                model: parent.g.join("").split("")
                                delegate: Rectangle {
                                    required property var modelData
                                    width: px.ps * 0.82; height: width; radius: width * 0.3
                                    color: modelData === "1" ? (lineRow.index === 1 ? w.ac : w.fg) : Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.07)
                                    Behavior on color { enabled: w.o("animate"); ColorAnimation { duration: 260 } }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ================= frase =================
    Text {
        visible: w.quote !== ""
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: w.quoteH
        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
        text: w.quote
        color: w.dim
        font.family: w.o("quoteFont") ? w.fontFam : Qt.application.font.family
        font.pixelSize: Math.max(11, w.quoteH * 0.5); font.italic: true
        elide: Text.ElideRight
    }
}
