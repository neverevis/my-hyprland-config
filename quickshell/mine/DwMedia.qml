// Widget de midia (MPRIS): capa com forma (arredondada, circulo, flor, quadrada; pode girar como disco), titulo,
// progresso, controles, fundo com a capa desfocada e letra sincronizada (Lyrics.qml).
// 1x1: capa com o botao de tocar; 2x1/3x1: capa ao lado das informacoes; 2x2/3x2: capa em cima (+ letra).
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import "dwparts.js" as U

Item {
    id: w
    property int cols: 2
    property int rows: 1
    property var opts: ({})
    property color fg: Theme.text
    property color dim: Theme.muted
    property color ac: Theme.accent
    property color ac2: Theme.tertiary            // cor companheira (o DeskView passa a do tom escolhido)
    property color cont: Theme.primaryContainer
    property color contInk: Theme.primaryContainerInk
    property bool bare: false
    property string wid: ""
    property var comp: ({})                       // composicao vinda do cartao (caixas internas, selos, destaque, raio)
    function o(k) { return DeskState.opt({ type: "media", opts: w.opts }, k) }
    readonly property bool lyr: o("lyrics")
    onLyrChanged: lyr ? Lyrics.use() : Lyrics.release()
    Component.onCompleted: if (lyr) Lyrics.use()
    Component.onDestruction: if (lyr) Lyrics.release()

    // "so o player ativo": sem nada tocando o widget mostra "Nada tocando" (em vez do ultimo player pausado)
    readonly property var p: o("onlyActive") ? Players.playingNow : (Players.playingNow ?? Players.pick(-1))
    readonly property string art: p ? (p.trackArtUrl ?? "") : ""
    readonly property real prog: p && p.length > 0 ? Math.max(0, Math.min(1, p.position / p.length)) : 0
    Timer { interval: 1000; repeat: true; running: !!w.p && w.p.isPlaying; onTriggered: if (w.p) w.p.positionChanged() }
    // com a capa desfocada no fundo, o texto e claro
    // ---- composicao (opcao "look"): auto = a de sempre (capa em forma + info); end4/flush/full/label usam as composicoes abaixo ----
    readonly property string look: o("look")
    readonly property bool tiny: cols === 1 && rows === 1
    // modo da composicao pelo tamanho do cartao
    readonly property string mode: {
        if (look === "auto") return "plain"
        if (look === "full") return "full"
        if (look === "label") return rows >= 2 && cols >= 2 ? "label" : "side"
        if (tiny) return look === "end4" ? "full" : "top"
        if (rows === 1) return cols >= 3 ? "wide" : "side"
        if (cols >= 3 || rows >= 3) return "label"
        return "top"
    }
    readonly property real pad: mode === "plain" ? -1 : 0       // o DeskView usa como margem do conteudo (-1 = a padrao)
    readonly property real cardR: comp.radius !== undefined ? comp.radius : 20
    readonly property real u: Math.max(0.75, Math.min(1.25, Math.min(width / DeskState.pxW(cols), height / DeskState.pxH(rows))))
    readonly property bool tintOn: mode !== "plain" && o("coverTint") && art !== ""
    property color tintCol: w.comp.accent !== undefined ? w.comp.accent : w.ac
    readonly property color acc: tintOn ? tintCol : (w.comp.accent !== undefined ? w.comp.accent : w.ac)
    readonly property bool overArt: mode === "plain" && o("blurBg") && !bare && art !== ""
    readonly property color tfg: overArt ? "white" : w.fg
    readonly property color tdim: overArt ? Qt.rgba(1, 1, 1, 0.7) : w.dim

    RoundImage {
        visible: w.overArt
        x: -18; y: -18; width: parent.width + 36; height: parent.height + 36
        radius: Math.min(30, Math.min(width, height) * 0.2)
        source: w.art; sourceSize: Qt.size(128, 128)
        blur: 1; dim: 0.45
        opacity: ready ? 0.9 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }
    Column {
        visible: !w.p
        anchors.centerIn: parent
        spacing: 6
        UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "music"; size: 30; color: w.dim }
        UiText { visible: w.cols > 1; anchors.horizontalCenter: parent.horizontalCenter; text: "Nada tocando"; color: w.dim; font.pixelSize: 13 }
    }
    Component {
        id: plainC
        Item {
            id: body
            visible: !!w.p
            anchors.fill: parent
            readonly property bool tall: w.rows > 1
            readonly property bool tiny: w.cols === 1 && w.rows === 1
            readonly property bool strip: w.cols === 2 && w.rows >= 3 && !w.lyr
            readonly property bool lyrBox: w.lyr && tall && w.rows >= 2 && w.cols >= 3
            readonly property real coverS: tiny ? Math.min(width, height) : (tall ? Math.min(lyrBox ? width * 0.42 : width, strip ? height - 118 : height * (lyrBox ? 0.62 : 0.55)) : height)
            ShapedImage {
                id: cover
                width: body.coverS; height: body.coverS
                x: body.lyrBox ? 0 : (body.tall || body.tiny ? (body.width - width) / 2 : 0)
                y: body.tiny ? (body.height - height) / 2 : 0
                shape: w.o("artShape"); sides: 12
                source: w.art; sourceSize: Qt.size(384, 384)
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                NumberAnimation on spin { running: w.o("spin") && !!w.p && w.p.isPlaying; from: 0; to: 360; duration: 14000; loops: Animation.Infinite }
                Flower { anchors.fill: parent; visible: !parent.ready; shape: parent.shape; color: w.bare ? w.cont : Qt.rgba(w.ac.r, w.ac.g, w.ac.b, 0.2)
                    UiIcon { anchors.centerIn: parent; name: "music"; size: parent.width * 0.35; color: w.ac } }
            }
            ShapeIcon {
                visible: body.tiny
                anchors.centerIn: cover
                shape: "cookie12"; size: 56; padding: 14
                icon: w.p && w.p.isPlaying ? "pause" : "play"
                color: w.ac; iconColor: Theme.accentText
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (w.p) w.p.togglePlaying() }
            }
            // 2x3: faixa com titulo/artista/controles sob a capa
            Rectangle {
                visible: body.strip
                anchors { left: parent.left; right: parent.right; top: cover.bottom; topMargin: 8; bottom: parent.bottom }
                radius: 18; color: Qt.rgba(w.tfg.r, w.tfg.g, w.tfg.b, 0.08)
            }
            Column {
                id: info
                visible: !body.tiny
                readonly property bool center: body.tall && !body.lyrBox && !body.strip
                anchors {
                    left: body.tall && !body.lyrBox ? parent.left : cover.right; leftMargin: body.strip ? 12 : (body.tall && !body.lyrBox ? 0 : 16)
                    right: parent.right; rightMargin: body.strip ? 12 : 0
                    top: body.tall && !body.lyrBox ? cover.bottom : undefined; topMargin: body.strip ? 18 : 12
                    verticalCenter: body.tall && !body.lyrBox ? undefined : cover.verticalCenter
                }
                spacing: 4
                UiText { visible: w.o("titles"); width: parent.width; elide: Text.ElideRight; horizontalAlignment: info.center ? Text.AlignHCenter : Text.AlignLeft
                    text: w.p ? (w.p.trackTitle || w.p.identity) : ""; color: w.tfg; font.pixelSize: w.cols >= 3 ? 18 : 16; font.weight: Font.Bold }
                UiText { visible: w.o("titles"); width: parent.width; elide: Text.ElideRight; horizontalAlignment: info.center ? Text.AlignHCenter : Text.AlignLeft
                    // 3x1 com letra: a linha atual no lugar do artista
                    text: w.lyr && !body.tall && Lyrics.index >= 0 && !Lyrics.plain ? "♪ " + Lyrics.lines[Lyrics.index].text : (w.p ? (w.p.trackArtist || "") : "")
                    color: w.lyr && !body.tall && Lyrics.index >= 0 ? w.ac : w.tdim; font.pixelSize: 13 }
                Item { width: 1; height: 4 }
                Rectangle {
                    width: parent.width; height: 4; radius: 2
                    color: Qt.rgba(w.tfg.r, w.tfg.g, w.tfg.b, 0.18)
                    Rectangle { width: parent.width * w.prog; height: parent.height; radius: 2; color: w.ac
                        Behavior on width { NumberAnimation { duration: 900 } } }
                }
                Item { width: 1; height: 4 }
                Row {
                    visible: w.o("controls")
                    anchors.horizontalCenter: info.center ? parent.horizontalCenter : undefined
                    spacing: 6
                    Repeater {
                        model: [["prev", () => w.p.previous()], [w.p && w.p.isPlaying ? "pause" : "play", () => w.p.togglePlaying()], ["next", () => w.p.next()]]
                            .concat(w.cols >= 2 ? [["quoteClose", () => DeskState.setOpt(w.wid, "lyrics", !w.lyr)]] : [])
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool play: index === 1
                            readonly property bool lyBtn: index === 3
                            width: play ? 46 : 34; height: play ? 46 : 34; radius: width / 2
                            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                            color: play ? "transparent" : lyBtn && w.lyr ? Qt.rgba(w.ac.r, w.ac.g, w.ac.b, 0.28) : (bm.containsMouse ? Qt.rgba(w.tfg.r, w.tfg.g, w.tfg.b, 0.16) : Qt.rgba(w.tfg.r, w.tfg.g, w.tfg.b, 0.08))
                            ShapeIcon { visible: parent.play; anchors.fill: parent; shape: "cookie12"; size: parent.width; padding: 12; icon: modelData[0]; color: w.ac; iconColor: Theme.accentText }
                            UiIcon { visible: !parent.play; anchors.centerIn: parent; name: modelData[0]; size: 17; color: parent.lyBtn && w.lyr ? w.ac : w.tfg }
                            MouseArea {
                                id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                // botao direito no "proxima" volta a anterior (como no end4)
                                onClicked: m => { if (!w.p) return; if (m.button === Qt.RightButton && index === 2) w.p.previous(); else modelData[1]() }
                            }
                        }
                    }
                }
            }
            // letra (3x2 ou maior): linhas rolando, a atual em destaque
            ListView {
                id: lyrics
                visible: body.lyrBox
                anchors { left: parent.left; right: parent.right; top: cover.bottom; topMargin: 12; bottom: parent.bottom }
                clip: true
                interactive: false
                model: Lyrics.lines
                spacing: 4
                currentIndex: Math.max(0, Lyrics.index)
                highlightRangeMode: ListView.ApplyRange
                preferredHighlightBegin: height * 0.3; preferredHighlightEnd: height * 0.5
                highlightMoveDuration: 400
                delegate: UiText {
                    required property var modelData
                    required property int index
                    width: lyrics.width; wrapMode: Text.WordWrap
                    text: modelData.text
                    color: index === Lyrics.index ? w.ac : w.tdim
                    font.pixelSize: index === Lyrics.index ? 15 : 13; font.weight: index === Lyrics.index ? Font.Bold : Font.Normal
                    Behavior on color { ColorAnimation { duration: 250 } }
                }
                // buscando: blob de carregamento; sem letra: clique para tentar de novo
                LoadingBlob { visible: lyrics.count === 0 && Lyrics.status === "buscando"; anchors.centerIn: parent; size: 44; color: w.contInk; bg: w.cont }
                UiText { visible: lyrics.count === 0 && Lyrics.status !== "buscando"; anchors.centerIn: parent; text: "Sem letra para esta música\nToque para tentar de novo"; horizontalAlignment: Text.AlignHCenter; color: w.tdim; font.pixelSize: 12
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Lyrics.restart() } }
            }
        }
    }
    Loader { anchors.fill: parent; active: w.mode === "plain"; visible: !!w.p; sourceComponent: plainC }
    // ---------- pecas das composicoes ----------
    // capa colada na borda do cartao: o corte reto fica por conta do clip, so o canto de fora fica redondo (corners: all | left | top)
    component FlushArt: Item {
        id: fa
        property string corners: "all"
        property real rad: w.cardR
        readonly property real ex: corners === "left" ? rad * 2 : 0
        readonly property real ey: corners === "top" ? rad * 2 : 0
        clip: true
        RoundImage {
            width: fa.width + fa.ex; height: fa.height + fa.ey
            radius: fa.rad
            source: w.art; sourceSize: Qt.size(384, 384)
        }
        Rectangle {
            visible: w.art === ""
            width: fa.width + fa.ex; height: fa.height + fa.ey; radius: fa.rad
            color: Theme.role("surfaceLow")
            UiIcon { x: fa.width / 2 - width / 2; y: fa.height / 2 - height / 2; name: "music"; size: Math.min(fa.width, fa.height) * 0.3; color: w.dim }
        }
    }
    // botao de controle (anterior/proxima/letra)
    component Ctl: Rectangle {
        id: ct
        property string icon: ""
        property real s: 28
        property color ink: w.fg
        property bool on: false
        signal go
        signal alt
        width: s; height: s; radius: s / 2
        color: on ? Qt.rgba(w.acc.r, w.acc.g, w.acc.b, 0.28) : (cm.containsMouse ? Qt.rgba(ink.r, ink.g, ink.b, 0.16) : "transparent")
        UiIcon { anchors.centerIn: parent; name: ct.icon; size: Math.round(ct.s * 0.6); color: ct.on ? w.acc : ct.ink }
        MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: m => { if (m.button === Qt.RightButton) ct.alt(); else ct.go() } }
    }
    // linha de controles: anterior, tocar (selo na forma escolhida, ou solto), proxima e (opcional) letra; opcionalmente numa pilula
    component Ctrls: Rectangle {
        id: cr
        property color ink: w.fg
        property real s: 28
        property bool lyBtn: false
        property bool pill: w.o("controlsStyle") === "pill"
        property bool prevBtn: true
        implicitWidth: rw.implicitWidth + (pill ? s * 0.7 : 0)
        implicitHeight: pill ? s * 1.45 : s * 1.3
        radius: height / 2
        color: pill ? Qt.rgba(ink.r, ink.g, ink.b, 0.12) : "transparent"
        Row {
            id: rw
            anchors.centerIn: parent
            spacing: cr.s * 0.15
            Ctl { visible: cr.prevBtn; anchors.verticalCenter: parent.verticalCenter; s: cr.s; ink: cr.ink; icon: "prev"; onGo: if (w.p) w.p.previous(); onAlt: if (w.p) w.p.previous() }
            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: cr.s * 1.3; height: width
                DwParts.Badge {
                    visible: w.o("controlsStyle") !== "bare"
                    anchors.fill: parent
                    size: parent.width
                    shape: w.comp.badgeShape && w.comp.badgeShape !== "auto" ? w.comp.badgeShape : "cookie12"
                    bg: w.acc
                    icon: w.p && w.p.isPlaying ? "pause" : "play"
                }
                UiIcon { visible: w.o("controlsStyle") === "bare"; anchors.centerIn: parent; name: w.p && w.p.isPlaying ? "pause" : "play"; size: cr.s * 0.95; color: cr.ink }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (w.p) w.p.togglePlaying() }
            }
            Ctl { anchors.verticalCenter: parent.verticalCenter; s: cr.s; ink: cr.ink; icon: "next"; onGo: if (w.p) w.p.next(); onAlt: if (w.p) w.p.previous() }
            Ctl { visible: cr.lyBtn; anchors.verticalCenter: parent.verticalCenter; s: cr.s; ink: cr.ink; icon: "quoteClose"; on: w.lyr; onGo: DeskState.setOpt(w.wid, "lyrics", !w.lyr); onAlt: DeskState.setOpt(w.wid, "lyrics", !w.lyr) }
        }
    }
    component Prog: Rectangle {
        property color ink: w.fg
        visible: w.o("progressStyle") === "line"
        height: Math.max(2, 3 * w.u); radius: height / 2
        color: Qt.rgba(ink.r, ink.g, ink.b, 0.18)
        Rectangle { width: parent.width * w.prog; height: parent.height; radius: parent.radius; color: w.acc }
    }
    readonly property string artist: p ? (p.trackArtist || p.identity || "") : ""
    readonly property string title: p ? (p.trackTitle || "") : ""
    readonly property string lyrLine: w.lyr && Lyrics.index >= 0 && !Lyrics.plain ? "♪ " + Lyrics.lines[Lyrics.index].text : ""

    // cor dominante da capa (miniatura 8x8, so com "Cores da capa" ligado)
    Loader {
        active: w.tintOn
        sourceComponent: Item {
            Image { id: tart; visible: false; source: w.art; sourceSize: Qt.size(8, 8); asynchronous: true; onStatusChanged: if (status === Image.Ready) tgrab.requestPaint() }
            Canvas {
                id: tgrab; visible: false; width: 8; height: 8
                onPaint: {
                    const c = getContext("2d"); c.drawImage(tart, 0, 0, 8, 8)
                    const d = c.getImageData(0, 0, 8, 8).data
                    let best = null, bs = -1
                    for (let i = 0; i < d.length; i += 4) { const mx = Math.max(d[i], d[i + 1], d[i + 2]), mn = Math.min(d[i], d[i + 1], d[i + 2]); if (mx - mn > bs) { bs = mx - mn; best = [d[i], d[i + 1], d[i + 2]] } }
                    if (!best) return
                    const k = Math.max(0, 140 - Math.max(best[0], best[1], best[2]))
                    w.tintCol = Qt.rgba(Math.min(255, best[0] + k) / 255, Math.min(255, best[1] + k) / 255, Math.min(255, best[2] + k) / 255, 1)
                }
            }
        }
    }

    // ---------- composicoes ----------
    Loader {
        anchors.fill: parent
        active: w.mode !== "plain"
        visible: !!w.p
        sourceComponent: ({ full: fullC, side: sideC, top: topC, wide: wideC, label: labelC })[w.mode] ?? sideC
    }
    // capa no cartao todo, degrade escuro embaixo, controles por cima
    Component {
        id: fullC
        Item {
            FlushArt { anchors.fill: parent }
            Rectangle {
                anchors.fill: parent; radius: w.cardR
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.15) }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.9) }
                }
            }
            Column {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 10 * w.u }
                spacing: 4 * w.u
                UiText { visible: w.o("titles") && !w.tiny; width: parent.width; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                    text: w.artist; color: "white"; font.pixelSize: 16 * w.u; font.weight: Font.DemiBold }
                UiText { visible: w.o("titles") && !w.tiny; width: parent.width; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                    text: w.lyrLine !== "" ? w.lyrLine : w.title; color: Qt.rgba(1, 1, 1, 0.75); font.pixelSize: 13 * w.u }
                Prog { visible: !w.tiny && w.o("progressStyle") === "line"; width: parent.width; ink: "white" }
                Ctrls { visible: w.o("controls"); anchors.horizontalCenter: parent.horizontalCenter; ink: "white"; s: (w.tiny ? 26 : 30) * w.u; lyBtn: !w.tiny && w.cols >= 2 }
            }
        }
    }
    // 2x1: capa quadrada colada a esquerda; ao lado artista, titulo e controles
    Component {
        id: sideC
        Item {
            FlushArt { id: sa; corners: "left"; width: parent.height; height: parent.height }
            Column {
                anchors { left: sa.right; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 14 * w.u; rightMargin: 12 * w.u }
                spacing: 2 * w.u
                UiText { visible: w.o("titles"); width: parent.width; elide: Text.ElideRight; text: w.artist; color: w.fg; font.pixelSize: 15 * w.u; font.weight: Font.DemiBold }
                UiText { visible: w.o("titles"); width: parent.width; elide: Text.ElideRight; text: w.lyrLine !== "" ? w.lyrLine : w.title; color: w.lyrLine !== "" ? w.acc : w.dim; font.pixelSize: 13 * w.u }
                Item { width: 1; height: 4 * w.u }
                Prog { width: parent.width }
                Ctrls { visible: w.o("controls"); s: 26 * w.u; lyBtn: w.cols >= 2 && w.height >= 100 && w.width > 270 * w.u }
            }
        }
    }
    // 2x2: capa grande colada no topo (cantos de cima redondos), texto e controles embaixo
    Component {
        id: topC
        Item {
            readonly property real tb: (w.o("titles") ? 62 : 0) * w.u + (w.o("controls") ? 52 * w.u : 0) + 18 * w.u
            FlushArt { id: ta; corners: "top"; width: parent.width; height: Math.max(parent.width * 0.4, parent.height - parent.tb) }
            Column {
                anchors { left: parent.left; right: parent.right; top: ta.bottom; margins: 14 * w.u; topMargin: 10 * w.u }
                spacing: 2 * w.u
                UiText { visible: w.o("titles"); width: parent.width; elide: Text.ElideRight; text: w.artist; color: w.fg; font.pixelSize: 16 * w.u; font.weight: Font.DemiBold }
                UiText { visible: w.o("titles"); width: parent.width; elide: Text.ElideRight; text: w.title; color: w.dim; font.pixelSize: 13 * w.u }
                Item { width: 1; height: 4 * w.u }
                Prog { width: parent.width }
                Ctrls { visible: w.o("controls"); s: 28 * w.u; lyBtn: w.cols >= 2 }
            }
        }
    }
    // 3x1: capa quadrada colada a esquerda, texto no meio e a pilula de controles no canto de cima
    Component {
        id: wideC
        Item {
            FlushArt { id: wa; corners: "left"; width: parent.height; height: parent.height }
            Column {
                anchors { left: wa.right; right: parent.right; bottom: parent.bottom; leftMargin: 16 * w.u; rightMargin: 14 * w.u; bottomMargin: 14 * w.u }
                spacing: 2 * w.u
                UiText { visible: w.o("titles"); width: parent.width; elide: Text.ElideRight; text: w.artist; color: w.fg; font.pixelSize: 17 * w.u; font.weight: Font.DemiBold }
                UiText { visible: w.o("titles"); width: parent.width; elide: Text.ElideRight; text: w.lyrLine !== "" ? w.lyrLine : w.title; color: w.lyrLine !== "" ? w.acc : w.dim; font.pixelSize: 13 * w.u }
                Item { width: 1; height: 5 * w.u }
                Prog { width: parent.width }
            }
            Ctrls {
                visible: w.o("controls")
                anchors { top: parent.top; right: parent.right; topMargin: 10 * w.u; rightMargin: 12 * w.u }
                pill: w.o("controlsStyle") !== "bare"; prevBtn: false; s: 28 * w.u; lyBtn: true
            }
        }
    }
    // 3x2 / 2x3: cabecalho (caixa com a capinha, titulo em italico, artista e o selo de tocar) e a letra embaixo
    Component {
        id: labelC
        Item {
            readonly property real hh: 82 * w.u
            Item {
                id: hd
                width: parent.width; height: hh; clip: true
                DwParts.Panel {
                    width: parent.width; height: hd.height + w.cardR * 2
                    role: w.comp.innerRole && w.comp.innerRole !== "auto" ? w.comp.innerRole : "primaryContainer"
                    alpha: w.comp.innerAlpha > 0 ? w.comp.innerAlpha : 1
                    radius: w.cardR
                }
                DwParts.Panel { id: hp; visible: false; role: w.comp.innerRole && w.comp.innerRole !== "auto" ? w.comp.innerRole : "primaryContainer" }
                RoundImage {
                    id: la
                    x: 14 * w.u; anchors.verticalCenter: parent.verticalCenter
                    width: 54 * w.u; height: width; radius: w.comp.innerRadius > 0 ? w.comp.innerRadius : 17
                    source: w.art; sourceSize: Qt.size(160, 160)
                    Rectangle { anchors.fill: parent; visible: !parent.ready; radius: parent.radius; color: Theme.role("surfaceLow")
                        UiIcon { anchors.centerIn: parent; name: "music"; size: parent.width * 0.4; color: w.dim } }
                }
                Column {
                    anchors { left: la.right; leftMargin: 12 * w.u; right: lb.left; rightMargin: 8 * w.u; verticalCenter: parent.verticalCenter }
                    UiText { width: parent.width; elide: Text.ElideRight; text: w.title || w.artist; color: hp.ink; font.pixelSize: 15 * w.u; font.weight: Font.DemiBold; font.italic: true }
                    UiText { width: parent.width; elide: Text.ElideRight; text: w.artist; color: hp.ink; opacity: 0.65; font.pixelSize: 12 * w.u }
                }
                Ctrls { id: lb; visible: w.o("controls"); anchors { right: parent.right; rightMargin: 10 * w.u; verticalCenter: parent.verticalCenter }
                    ink: hp.ink; s: 28 * w.u; prevBtn: false; pill: false; lyBtn: true }
            }
            ListView {
                id: ly
                anchors { left: parent.left; right: parent.right; top: hd.bottom; bottom: parent.bottom; margins: 10 * w.u }
                visible: w.lyr
                clip: true; interactive: false
                model: Lyrics.lines
                spacing: 6
                currentIndex: Math.max(0, Lyrics.index)
                highlightRangeMode: ListView.ApplyRange
                preferredHighlightBegin: height * 0.3; preferredHighlightEnd: height * 0.5
                highlightMoveDuration: 400
                delegate: UiText {
                    required property var modelData
                    required property int index
                    width: ly.width; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
                    text: modelData.text
                    color: index === Lyrics.index ? w.acc : w.dim
                    font.pixelSize: (index === Lyrics.index ? 16 : 13) * w.u; font.weight: index === Lyrics.index ? Font.Bold : Font.Normal
                }
                LoadingBlob { visible: ly.count === 0 && Lyrics.status === "buscando"; anchors.centerIn: parent; size: 44; color: w.contInk; bg: w.cont }
                UiText { visible: ly.count === 0 && Lyrics.status !== "buscando"; anchors.centerIn: parent; text: "Sem letra para esta música\nToque para tentar de novo"; horizontalAlignment: Text.AlignHCenter; color: w.dim; font.pixelSize: 12
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Lyrics.restart() } }
            }
            // sem letra ligada: so o progresso e uma dica
            Column {
                visible: !w.lyr
                anchors { left: parent.left; right: parent.right; top: hd.bottom; margins: 14 * w.u; topMargin: 16 * w.u }
                spacing: 8 * w.u
                Prog { width: parent.width }
                UiText { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "Ligue a letra no botão de aspas"; color: w.dim; font.pixelSize: 12 * w.u }
            }
        }
    }
}
