// Widget de relogio. Estilos (opts.style): digital (numeros que rolam ao trocar), analog (flor com N petalas, mostrador,
// ponteiros e data em varios estilos), daily (selo / saudacao / manuscrito / forte), pixel (matriz de pontos).
// "auto": flor nos tamanhos quadrados, digital nos outros. Frase opcional embaixo. Opcoes: ver DeskState.catalog (clock).
import Quickshell
import Quickshell.Services.UPower
import QtQuick

Item {
    id: w
    property int cols: 2
    property int rows: 1
    property var opts: ({})
    property color fg: Theme.text
    property color dim: Theme.muted
    property color ac: Theme.accent
    property color ac2: Theme.tertiary            // cor companheira (ponteiro dos minutos)
    property color cont: Theme.primaryContainer   // versao suave do tom (a flor)
    property color contInk: Theme.primaryContainerInk
    property bool bare: false
    property real posX: 0.5                       // posicao na tela (0 = esquerda, 1 = direita): alinhamento "pelo lugar"
    function o(k) { return DeskState.opt({ type: "clock", opts: w.opts }, k) }
    readonly property bool ownBackground: style === "analog"   // a flor ja e o fundo (o DeskView nao poe sombra)

    readonly property string style: { const s = o("style"); return s === "auto" ? (cols === rows ? "analog" : "digital") : s }
    readonly property bool secs: o("seconds")
    readonly property bool h12: o("h12")
    readonly property real sc: o("scale") / 100
    readonly property string fontFam: o("font") || Theme.fontNumbers
    // eixos de fontes variaveis (largura e arredondamento); fontes comuns ignoram
    readonly property var axes: { const a = {}, fw = o("fwidth"), fr = o("fround"); if (fw !== 100) a.wdth = fw; if (fr > 0) a.ROND = fr; return a }
    readonly property int alignFlag: { let a = o("align"); if (a === "auto") a = posX < 0.34 ? "left" : posX > 0.66 ? "right" : "center"
        return a === "left" ? Text.AlignLeft : a === "right" ? Text.AlignRight : Text.AlignHCenter }
    readonly property string quote: o("quote")
    readonly property real quoteH: quote !== "" ? Math.min(34, height * 0.18) : 0
    SystemClock { id: clk; precision: w.secs || w.style === "analog" ? SystemClock.Seconds : SystemClock.Minutes }
    readonly property var loc: Qt.locale("pt_BR")
    function cap(s) { return s.charAt(0).toUpperCase() + s.slice(1) }
    readonly property string hh: { const h = clk.date.getHours(); return h12 ? String((h + 11) % 12 + 1) : String(h).padStart(2, "0") }
    readonly property string mm: String(clk.date.getMinutes()).padStart(2, "0")
    readonly property string ss: String(clk.date.getSeconds()).padStart(2, "0")
    readonly property string ampm: clk.date.getHours() < 12 ? "AM" : "PM"
    readonly property string dateText: DateTime.long(clk.date)
    readonly property string greet: { const h = clk.date.getHours(); return h < 5 ? "Boa noite" : h < 12 ? "Bom dia" : h < 18 ? "Boa tarde" : "Boa noite" }

    readonly property real bodyH: height - quoteH
    property bool locked: false            // o DeskView avisa quando este relogio esta na tela de bloqueio
    // linha de status: so na tela de bloqueio
    Row {
        visible: w.locked
        anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.topMargin: -2
        spacing: 5; z: 4
        UiIcon { name: "lock"; size: 13; color: w.dim; anchors.verticalCenter: parent.verticalCenter }
        UiText { text: "Bloqueado"; color: w.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
    }

    // dados do estilo diario: clima (so busca enquanto esse estilo esta em uso) e bateria
    readonly property bool wantWx: style === "daily"
    property bool wxOn: false
    onWantWxChanged: syncWx()
    Component.onCompleted: syncWx()
    Component.onDestruction: if (wxOn) Weather.release()
    function syncWx() { if (wantWx && !wxOn) { wxOn = true; Weather.use() } else if (!wantWx && wxOn) { wxOn = false; Weather.release() } }
    readonly property var bat: UPower.displayDevice
    readonly property bool hasBat: !!bat && bat.ready && bat.isLaptopBattery
    readonly property string wxDesc: Weather.ready ? Weather.describe(Weather.now.code).toLowerCase() : ""
    readonly property string wxSentence: Weather.ready ? "Agora " + wxDesc + " com umidade de " + Weather.now.humidity + "% e vento de " + Math.round(Weather.now.wind) + " " + Weather.windUnit + "." : ""
    readonly property string wxTemp: Weather.ready ? Math.round(Weather.now.temp) + "°" : ""

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
        readonly property int al: w.alignFlag
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
                UiText { visible: w.h12; text: " " + w.ampm; color: w.dim; font.family: w.fontFam; font.pixelSize: dig.fs * 0.3; font.weight: Font.DemiBold; anchors.baseline: parent.bottom; anchors.baselineOffset: -dig.fs * 0.18 }
            }
            Row {
                visible: dig.vert
                anchors.horizontalCenter: dig.al === Text.AlignHCenter ? parent.horizontalCenter : undefined
                anchors.right: dig.al === Text.AlignRight ? parent.right : undefined
                Repeater { model: w.mm.split(""); delegate: Roll { required property var modelData; ch: modelData; size: dig.fs; tint: w.ac } }
            }
            UiText {
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
        property string fam: w.fontFam
        property int wt: w.o("weight")
        property string prev: ch
        property real k: 1
        width: Math.max(cur.implicitWidth, old.implicitWidth); height: cur.implicitHeight * 0.92
        clip: true
        onChChanged: { if (w.o("animate") && w.style !== "pixel") { prev = old.text; k = 0; rollA.restart() } else old.text = ch }
        NumberAnimation { id: rollA; target: rl; property: "k"; from: 0; to: 1; duration: 420; easing.type: Easing.OutCubic; onFinished: old.text = rl.ch }
        UiText { id: old; text: rl.ch; y: -rl.k * rl.height * 0.9; opacity: 1 - rl.k; color: rl.tint; font.family: rl.fam; font.pixelSize: rl.size; font.weight: rl.wt; font.features: { "tnum": 1 }; font.variableAxes: w.axes; visible: rl.k < 1 }
        UiText { id: cur; text: rl.ch; y: (1 - rl.k) * rl.height * 0.9; opacity: rl.k; color: rl.tint; font.family: rl.fam; font.pixelSize: rl.size; font.weight: rl.wt; font.features: { "tnum": 1 }; font.variableAxes: w.axes }
    }

    // ================= flor (analogico) =================
    Item {
        id: an
        visible: w.style === "analog"
        width: parent.width; height: w.bodyH
        readonly property real d: Math.min(width, height) * Math.min(1, 0.9 * w.sc + 0.1)
        // como no relogio do end4: a flor no tom suave, marcas no texto sobre ele, horas no destaque, minutos na companheira
        readonly property color body: w.bare ? w.cont : Qt.rgba(w.ac.r, w.ac.g, w.ac.b, 0.14)
        readonly property color ink: w.bare ? w.contInk : Qt.tint(w.ac, Qt.rgba(1, 1, 1, 0.35))
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
            // disco com as 12 marcas no meio (como o "hour marks" do end4): cresce ao ligar
            Item {
                id: marks
                readonly property bool on: w.o("hourMarks")
                property real k: on ? 1 : 0
                Behavior on k { MotionAnim { use: "desktop" } }
                visible: k > 0.01
                opacity: k
                width: face.width * 0.59 * (1.6 - 0.6 * k); height: width
                anchors.centerIn: parent
                Rectangle {
                    anchors.fill: parent; radius: width / 2
                    color: an.ink
                    Repeater {
                        model: 12
                        Item {
                            required property int index
                            anchors.fill: parent
                            rotation: index * 30
                            Rectangle {
                                x: parent.width * 0.06; anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * 0.09; height: Math.max(2, parent.width * 0.03); radius: height / 2
                                color: Qt.tint(an.ink, Qt.rgba(an.body.r, an.body.g, an.body.b, 0.5))
                            }
                        }
                    }
                }
            }
            // horas no meio (numeros que rolam): menores quando ha o disco de marcas, na cor de contraste dele
            Column {
                id: mid
                readonly property bool on: w.o("centerTime")
                property real k: on ? 1 : 0
                Behavior on k { MotionAnim { use: "desktop" } }
                visible: k > 0.01
                opacity: k
                scale: 1.4 - 0.4 * k
                anchors.centerIn: parent
                spacing: -fs * 0.1
                readonly property real fs: face.width * (marks.on ? 0.15 : 0.25)
                readonly property color col: marks.on ? an.body : an.ink
                Repeater {
                    model: [w.hh, w.mm]
                    delegate: Row {
                        required property var modelData
                        required property int index
                        anchors.horizontalCenter: parent.horizontalCenter
                        Repeater {
                            model: modelData.split("")
                            delegate: Roll { required property var modelData; ch: modelData; size: mid.fs; tint: mid.col; fam: w.o("font") || Theme.font; wt: Font.Black }
                        }
                    }
                }
            }
            // data no mostrador (lado das 3 horas; com as horas no meio vai para baixo)
            Rectangle {
                readonly property string ds: w.o("dateStyle")
                readonly property bool low: mid.on
                visible: ds !== "hide" && ds !== "bubble" && ds !== "border" && face.width > 110
                x: ds === "rect" ? face.width * 0.8 : (low ? face.width / 2 - width / 2 : face.width * 0.62)
                y: ds === "rect" ? face.height / 2 - height / 2 : (low ? face.height * (marks.on ? 0.87 : 0.78) - height / 2 : face.height / 2 - height / 2)
                width: ds === "rect" ? face.width * 0.13 : dtx.implicitWidth + face.width * 0.06
                height: ds === "rect" ? face.width * 0.2 : face.width * 0.13
                radius: height * 0.3
                color: ds === "rect" ? w.ac : Qt.rgba(w.ac.r, w.ac.g, w.ac.b, 0.28)
                UiText {
                    id: dtx
                    anchors.centerIn: parent
                    text: parent.ds === "rect" ? String(clk.date.getDate()).padStart(2, "0") : w.cap(clk.date.toLocaleDateString(w.loc, "ddd")).replace(".", "") + " " + clk.date.getDate()
                    color: parent.ds === "rect" ? Theme.accentText : an.ink
                    font.pixelSize: face.width * 0.065; font.weight: Font.Bold
                }
            }
            // bolha: dia num pentagono (canto de cima, a esquerda) e mes numa pilula (baixo, a direita); crescem ao ligar
            Item {
                id: bub
                readonly property bool on: w.o("dateStyle") === "bubble" && face.width > 110
                property real k: on ? 1 : 0
                Behavior on k { MotionAnim { use: "desktop" } }
                visible: k > 0.01
                anchors.fill: parent
                Flower {
                    shape: "pentagon"; color: Theme.tertiaryContainer
                    width: face.width * 0.24 * bub.k; height: width
                    x: face.width * 0.2; y: face.width * 0.22
                    UiText { anchors.centerIn: parent; text: String(clk.date.getDate()); color: Theme.tertiaryContainerInk; font.pixelSize: face.width * 0.095 * bub.k; font.weight: Font.Bold }
                }
                Flower {
                    shape: "pill"; color: Theme.secondaryContainer
                    width: face.width * 0.3 * bub.k; height: face.width * 0.17 * bub.k
                    x: face.width * 0.55; y: face.width * 0.66
                    UiText { anchors.centerIn: parent; text: String(clk.date.getMonth() + 1).padStart(2, "0"); color: Theme.secondaryContainerInk; font.pixelSize: face.width * 0.085 * bub.k; font.weight: Font.Bold }
                }
            }
            // borda: "ddd dd" letra a letra em volta do mostrador, girando junto com os segundos
            Item {
                id: bord
                readonly property bool on: w.o("dateStyle") === "border" && face.width > 110
                property real k: on ? 1 : 0
                Behavior on k { MotionAnim { use: "desktop" } }
                visible: k > 0.01
                opacity: k
                anchors.fill: parent
                rotation: w.secs ? face.sA : 0
                readonly property string txt: (w.cap(clk.date.toLocaleDateString(w.loc, "ddd")).replace(".", "") + " " + String(clk.date.getDate()).padStart(2, "0")).toUpperCase()
                Repeater {
                    model: bord.txt.split("")
                    delegate: Item {
                        required property var modelData
                        required property int index
                        width: 0; height: 0
                        x: face.width / 2; y: face.height / 2
                        rotation: (index - (bord.txt.length - 1) / 2) * 12
                        UiText {
                            x: -width / 2; y: -face.width * (0.455 + 0.03 * (1 - bord.k))
                            text: modelData; color: an.ink; font.pixelSize: face.width * 0.06; font.weight: Font.Bold
                        }
                    }
                }
            }
            component Hand: Item {
                id: hd
                property real target: 0                 // angulo certo agora (0..360)
                property real angle: 0                  // angulo mostrado: anima 300 ms pelo caminho mais curto (sem dar a volta no 360 -> 0)
                property real unw: 0
                property bool ready: false
                property real len: 0.6
                property real thick: 6
                property color col: an.ink
                property bool hollow: false
                property bool tail: false
                onTargetChanged: { unw += ((target - unw) % 360 + 540) % 360 - 180; angle = unw }
                Component.onCompleted: { unw = target; angle = target; ready = true }
                Behavior on angle { enabled: hd.ready; NumberAnimation { duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }
                Behavior on thick { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on col { ColorAnimation { duration: 250 } }
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
                target: face.hA; len: 0.5
                thick: st === "classic" ? face.width * 0.035 : face.width * 0.085
                hollow: st === "hollow"
                col: st === "classic" ? w.fg : w.ac
            }
            Hand {
                readonly property string st: w.o("minuteHand")
                visible: st !== "hide"
                target: face.mA; len: 0.72
                thick: ({ classic: 0.025, thin: 0.018, medium: 0.045, bold: 0.07 })[st] * face.width
                col: st === "classic" ? w.fg : w.ac2
            }
            Hand {
                readonly property string st: w.o("secondHand")
                visible: w.secs && (st === "line" || st === "classic")
                target: face.sA; len: 0.8; thick: Math.max(1.5, face.width * 0.012); tail: st === "classic"
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
        readonly property int al: w.alignFlag
        // unidade: tudo no bloco e medido em u (cabe no tamanho do widget)
        readonly property real u: Math.max(0.3, Math.min(height / (v === "bold" ? 150 : 132), width / (v === "bold" ? 300 : 250))) * w.sc
        readonly property string wday: w.cap(clk.date.toLocaleDateString(w.loc, "dddd"))
        readonly property string timeS: w.hh + ":" + w.mm + (w.h12 ? " " + w.ampm : "")
        readonly property string greetS: w.greet + ", " + Profile.name.split(" ")[0]
        readonly property bool wxOk: Weather.ready
        readonly property var wx: wxOk ? Weather.now : ({})
        Item {
            id: blk
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(parent.width, col.implicitWidth)
            height: col.implicitHeight
            x: dl.al === Text.AlignHCenter ? (parent.width - width) / 2 : dl.al === Text.AlignRight ? parent.width - width : 0
            Column {
                id: col
                spacing: 4 * dl.u

                // ---------- selo ----------
                Row {
                    visible: dl.v === "badge"
                    spacing: 10 * dl.u
                    ShapeIcon { visible: dl.wxOk; anchors.verticalCenter: parent.verticalCenter; shape: "cookie12"; icon: Weather.icon(dl.wx.code, dl.wx.day); size: 50 * dl.u; padding: 12 * dl.u; color: w.ac; iconColor: Theme.accentText }
                    UiText { anchors.verticalCenter: parent.verticalCenter; text: String(clk.date.getDate()).padStart(2, "0"); color: w.fg; font.family: w.fontFam; font.pixelSize: 44 * dl.u; font.weight: Font.Bold }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        UiText { text: w.cap(clk.date.toLocaleDateString(w.loc, "ddd")).replace(".", ""); color: w.ac; font.family: w.fontFam; font.pixelSize: 17 * dl.u; font.weight: Font.Bold }
                        UiText { text: w.cap(clk.date.toLocaleDateString(w.loc, "MMMM")); color: w.dim; font.family: w.fontFam; font.pixelSize: 14 * dl.u }
                    }
                }
                UiText { visible: dl.v === "badge"; text: dl.greetS; color: w.fg; font.family: w.fontFam; font.pixelSize: 19 * dl.u; font.weight: Font.Light }
                UiText { visible: dl.v === "badge" && dl.wxOk; width: Math.min(270 * dl.u, implicitWidth); wrapMode: Text.WordWrap
                    text: w.wxSentence; color: w.dim; font.family: w.fontFam; font.pixelSize: 12 * dl.u }
                Row {
                    visible: dl.v === "badge"
                    spacing: 8 * dl.u
                    ShapeIcon { anchors.verticalCenter: parent.verticalCenter; shape: "cookie9"; icon: "clockOutline"; size: 32 * dl.u; padding: 7 * dl.u; color: w.cont; iconColor: w.contInk }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        height: 32 * dl.u; width: bt.implicitWidth + 26 * dl.u; radius: height / 2; color: w.ac
                        UiText { id: bt; anchors.centerIn: parent; text: dl.timeS; color: Theme.accentText; font.family: w.fontFam; font.pixelSize: 19 * dl.u; font.weight: Font.Bold; font.features: { "tnum": 1 } }
                    }
                }

                // ---------- saudacao ----------
                UiText { visible: dl.v === "morning"; text: dl.greetS; color: w.ac; font.family: DeskWidgets.script; font.pixelSize: 44 * dl.u; font.italic: true }
                UiText { visible: dl.v === "morning"; width: Math.min(290 * dl.u, implicitWidth); wrapMode: Text.WordWrap
                    text: ("Hoje é " + clk.date.toLocaleDateString(w.loc, "dddd, d 'de' MMMM") + (dl.wxOk ? ", com " + w.wxDesc : "")).toUpperCase()
                    color: w.dim; font.family: w.fontFam; font.pixelSize: 11 * dl.u; font.weight: Font.Medium; font.letterSpacing: 1.2 * dl.u }
                Rectangle { visible: dl.v === "morning"; width: 64 * dl.u; height: Math.max(1, 2 * dl.u); radius: 1; color: Qt.rgba(w.ac.r, w.ac.g, w.ac.b, 0.6) }
                UiText { visible: dl.v === "morning" && w.hasBat; text: "Bateria " + Math.round((w.bat?.percentage ?? 0) * 100) + "%"; color: w.dim; font.family: w.fontFam; font.pixelSize: 12 * dl.u }
                Row {
                    visible: dl.v === "morning"
                    spacing: 10 * dl.u
                    ShapeIcon { anchors.verticalCenter: parent.verticalCenter; shape: "cookie9"; icon: "clockOutline"; size: 34 * dl.u; padding: 8 * dl.u; color: w.cont; iconColor: w.contInk }
                    UiText { anchors.verticalCenter: parent.verticalCenter; text: dl.timeS; color: w.fg; font.family: w.fontFam; font.pixelSize: 26 * dl.u; font.weight: w.o("weight"); font.letterSpacing: 2 * dl.u; font.features: { "tnum": 1 }; font.variableAxes: w.axes }
                }

                // ---------- manuscrito ----------
                Row {
                    visible: dl.v === "script"
                    spacing: 8 * dl.u
                    ShapeIcon { anchors.verticalCenter: parent.verticalCenter; shape: "cookie9"; icon: "clockOutline"; size: 32 * dl.u; padding: 7 * dl.u; color: w.cont; iconColor: w.contInk }
                    UiText { anchors.verticalCenter: parent.verticalCenter; text: dl.timeS; color: w.fg; font.family: w.fontFam; font.pixelSize: 24 * dl.u; font.weight: Font.DemiBold; font.features: { "tnum": 1 } }
                }
                UiText { visible: dl.v === "script"; text: dl.wday.split("-")[0] + "."; color: w.ac; font.family: DeskWidgets.script; font.pixelSize: 62 * dl.u; font.italic: true }
                Rectangle {
                    visible: dl.v === "script" && w.o("date")
                    height: 26 * dl.u; width: sdt.implicitWidth + 24 * dl.u; radius: height / 2; color: w.cont
                    UiText { id: sdt; anchors.centerIn: parent; text: clk.date.toLocaleDateString(w.loc, "d MMM yyyy").replace(".", "."); color: w.contInk; font.family: w.fontFam; font.pixelSize: 13 * dl.u; font.weight: Font.Medium }
                }
                UiText { visible: dl.v === "script" && dl.wxOk; width: Math.min(260 * dl.u, implicitWidth); wrapMode: Text.WordWrap
                    text: w.wxSentence; color: w.dim; font.family: w.fontFam; font.pixelSize: 11 * dl.u }

                // ---------- forte: cartao colorido ----------
                Rectangle {
                    visible: dl.v === "bold"
                    width: 290 * dl.u; height: 138 * dl.u; radius: 28 * dl.u; color: w.ac
                    readonly property color ink: Theme.accentText
                    Column {
                        anchors { left: parent.left; leftMargin: 20 * dl.u; verticalCenter: parent.verticalCenter }
                        spacing: -2 * dl.u
                        UiText { text: String(clk.date.getDate()).padStart(2, "0"); color: parent.parent.ink; font.family: w.fontFam; font.pixelSize: 22 * dl.u; font.weight: Font.Medium }
                        UiText { text: clk.date.toLocaleDateString(w.loc, "MMM").replace(".", "").toUpperCase() + "."; color: parent.parent.ink; font.family: w.fontFam; font.pixelSize: 60 * dl.u; font.weight: Font.Black }
                        UiText { text: "Hoje é " + dl.wday.toLowerCase(); color: Qt.rgba(parent.parent.ink.r, parent.parent.ink.g, parent.parent.ink.b, 0.75); font.family: w.fontFam; font.pixelSize: 13 * dl.u }
                    }
                    Column {
                        anchors { right: parent.right; rightMargin: 18 * dl.u; verticalCenter: parent.verticalCenter }
                        spacing: 2 * dl.u
                        UiText { visible: dl.wxOk; anchors.right: parent.right; text: w.wxTemp; color: parent.parent.ink; font.family: w.fontFam; font.pixelSize: 30 * dl.u; font.weight: Font.Bold }
                        UiText { visible: dl.wxOk; anchors.right: parent.right; text: w.cap(w.wxDesc); color: Qt.rgba(parent.parent.ink.r, parent.parent.ink.g, parent.parent.ink.b, 0.75); font.family: w.fontFam; font.pixelSize: 11 * dl.u }
                        UiText { anchors.right: parent.right; text: dl.timeS; color: parent.parent.ink; font.family: w.fontFam; font.pixelSize: 24 * dl.u; font.weight: Font.Bold; font.features: { "tnum": 1 } }
                        Rectangle { anchors.right: parent.right; width: 34 * dl.u; height: Math.max(1, 3 * dl.u); radius: 2; color: Qt.rgba(parent.parent.ink.r, parent.parent.ink.g, parent.parent.ink.b, 0.6) }
                    }
                }
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
        readonly property bool vert: { const ori = w.o("orientation"); return ori === "vertical" ? true : ori === "horizontal" ? false : w.rows > w.cols }
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
    // digital: texto solto; flor e pixel: pilula com aspas (como o chip do end4)
    readonly property bool quoteChip: style === "analog" || style === "pixel"
    Rectangle {
        visible: w.quote !== "" && w.quoteChip
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
        height: w.quoteH
        width: Math.min(parent.width, qrow.implicitWidth + 24)
        radius: height / 2
        color: Theme.secondaryContainer
        Row {
            id: qrow
            anchors.centerIn: parent
            spacing: 6
            UiIcon { anchors.verticalCenter: parent.verticalCenter; name: "quoteClose"; size: Math.max(11, w.quoteH * 0.45); color: Theme.secondaryContainerInk }
            UiText {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, w.width - 60)
                text: w.quote; color: Theme.secondaryContainerInk
                font.family: w.o("quoteFont") ? w.fontFam : Theme.font
                font.pixelSize: Math.max(11, w.quoteH * 0.42); font.italic: true
                elide: Text.ElideRight
            }
        }
    }
    UiText {
        visible: w.quote !== "" && !w.quoteChip
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: w.quoteH
        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
        text: w.quote
        color: w.dim
        font.family: w.o("quoteFont") ? w.fontFam : Theme.font
        font.pixelSize: Math.max(11, w.quoteH * 0.5); font.italic: true
        elide: Text.ElideRight
    }
}
