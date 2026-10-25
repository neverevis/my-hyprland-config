// Widget de clima (Weather.qml). 1x1: icone e temperatura; 2x1: agora + detalhes; 3x1: + proximas horas;
// 2x2/3x2: agora em cima e previsao (horas ou dias) embaixo. opts.show escolhe o que vai na previsao.
// Composicoes (opcao "look"): atual (acima), end4 (selo + blocos em caixas, um layout por tamanho) e destaque (temperatura
// grande + selo). Cada uma e um Component num Loader: so a ativa existe.
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
    property color ac2: Theme.tertiary            // cor companheira (o DeskView passa a do tom escolhido)
    property color cont: Theme.primaryContainer
    property color contInk: Theme.primaryContainerInk
    property bool bare: false
    property var comp: ({})                       // composicao vinda do cartao (caixas internas, selos, destaque)
    function o(k) { return DeskState.opt({ type: "weather", opts: w.opts }, k) }
    Component.onCompleted: Weather.use()
    Component.onDestruction: Weather.release()

    readonly property var n: Weather.now
    readonly property string show: { const s = o("show"); return s !== "auto" ? s : (rows > 1 ? "tiles" : (cols >= 3 ? "hours" : "now")) }
    function t(v) { return v === undefined || v === null ? "—" : Math.round(v) + "°" }
    readonly property var loc: Qt.locale("pt_BR")
    readonly property bool tilesOn: show === "tiles" && rows > 1
    function hm(d) { return d ? Qt.formatDateTime(d, "HH:mm") : "—" }
    function vis(m) { if (m === undefined || m === null) return "—"; return Weather.imperial ? SysInfo.num(m / 1609.34, 1) + " mi" : (m >= 10000 ? Math.round(m / 1000) : SysInfo.num(m / 1000, 1)) + " km" }
    // blocos de detalhe: icone, rotulo, valor (nascer e por do sol so nos largos)
    // [icone, rotulo, valor, gravidade 0..1 (cor do valor nas composicoes novas)]
    readonly property var allMetrics: {
        const d0 = Weather.days.length ? Weather.days[0] : null
        const kmh = (n.wind ?? 0) * (Weather.imperial ? 1.609 : 1), rain = d0 ? d0.rain : 0
        return [["humidity", "Umidade", (n.humidity ?? "—") + "%", 0], ["wWind", "Vento", Math.round(n.wind ?? 0) + " " + Weather.windUnit, Math.max(0, Math.min(1, (kmh - 25) / 45))],
                ["eye", "Visibilidade", vis(n.vis), n.vis !== undefined && n.vis < 3000 ? 0.7 : 0], ["wRain", "Chuva", (d0 ? d0.rain : "—") + "%", Math.max(0, Math.min(1, (rain - 40) / 50))],
                ["sunrise", "Nascer do sol", hm(d0 ? d0.sunrise : null), 0], ["sunset", "Pôr do sol", hm(d0 ? d0.sunset : null), 0]]
    }
    readonly property var metrics: {
        const a = allMetrics, l = [a[0], a[3], a[1], a[2]]
        if (cols >= 3) l.push(a[4], a[5])
        return l
    }

    // ---- composicao ----
    readonly property bool narrow: cols === 1 && rows > 1
    readonly property string lk: { const l = o("look"); return l === "auto" || narrow ? "plain" : l }
    readonly property string mode: cols === 1 && rows === 1 ? "1x1" : rows === 1 ? (cols >= 3 ? "1x3" : "1x2") : (cols >= 3 || rows >= 3) ? "2x3" : "2x2"
    readonly property real pad: lk === "plain" ? -1 : (lk === "end4" && mode === "1x2") ? 10 : 14
    function innerRole(def) { return comp.innerRole && comp.innerRole !== "auto" ? comp.innerRole : def }
    function innerAlpha(def) { return comp.innerAlpha > 0 ? comp.innerAlpha : def }
    function innerRad(def) { return comp.innerRadius > 0 ? comp.innerRadius : def }
    readonly property color acc: comp.accent !== undefined ? comp.accent : ac
    readonly property string badgeShape: comp.badgeShape && comp.badgeShape !== "auto" ? comp.badgeShape : "cookie12"
    readonly property string nowIcon: Weather.icon(n.code, n.day)
    function sevColor(base, sev) { return sev > 0 ? Qt.tint(base, Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.85 * sev)) : base }
    // bloco de detalhe do end4: caixa (surfaceVariant) com icone na cor de destaque; compact = so icone e valor
    component E4Tile: DwParts.Panel {
        id: et
        property string icon: ""
        property string label: ""
        property string value: ""
        property real sev: 0
        property real u: 1
        property bool compact: false
        role: w.innerRole("surfaceVariant"); alpha: w.innerAlpha(1)
        radius: Math.min(height / 2, w.innerRad(23) * u)
        readonly property color vcol: w.sevColor(ink, sev)
        Row {
            visible: et.compact
            anchors.centerIn: parent
            spacing: 5 * et.u
            UiIcon { anchors.verticalCenter: parent.verticalCenter; name: et.icon; size: Math.round(16 * et.u); color: w.acc }
            UiText { anchors.verticalCenter: parent.verticalCenter; text: et.value; color: et.vcol; font.pixelSize: Math.round(14 * et.u); font.weight: Font.DemiBold; font.features: { "tnum": 1 } }
        }
        Row {
            visible: !et.compact
            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 10 * et.u; right: parent.right; rightMargin: 6 * et.u }
            spacing: 8 * et.u
            UiIcon { anchors.verticalCenter: parent.verticalCenter; name: et.icon; size: Math.round(20 * et.u); color: w.acc }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 28 * et.u
                UiText { width: parent.width; elide: Text.ElideRight; text: et.label; color: Qt.rgba(et.ink.r, et.ink.g, et.ink.b, 0.7); font.pixelSize: Math.round(11 * et.u) }
                UiText { width: parent.width; elide: Text.ElideRight; text: et.value; color: et.vcol; font.pixelSize: Math.round(15 * et.u); font.weight: Font.DemiBold; font.features: { "tnum": 1 } }
            }
        }
    }
    component E4Badge: DwParts.Badge {
        shape: w.badgeShape; icon: w.nowIcon; bg: w.acc
    }

    // bloco de detalhe (a "surfaceVariant" arredondada do end4); compact = so icone e valor
    component Tile: Rectangle {
        id: tl
        property string icon: ""
        property string label: ""
        property string value: ""
        property bool compact: false
        radius: Math.min(18, Math.min(width, height) * 0.3)
        color: Qt.rgba(w.fg.r, w.fg.g, w.fg.b, w.bare ? 0.1 : 0.07)
        Row {
            visible: tl.compact
            anchors.centerIn: parent
            spacing: 5
            UiIcon { anchors.verticalCenter: parent.verticalCenter; name: tl.icon; size: 14; color: w.ac }
            UiText { anchors.verticalCenter: parent.verticalCenter; text: tl.value; color: w.fg; font.pixelSize: 12; font.weight: Font.DemiBold; font.features: { "tnum": 1 } }
        }
        Column {
            visible: !tl.compact
            anchors.centerIn: parent
            width: parent.width - 12
            spacing: 1
            UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: tl.icon; size: Math.min(20, tl.height * 0.3); color: w.ac }
            UiText { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: tl.value; color: w.fg; font.pixelSize: Math.min(15, tl.height * 0.22); font.weight: Font.Bold; font.features: { "tnum": 1 } }
            UiText { visible: tl.height > 58; width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: tl.label; color: w.dim; font.pixelSize: 11 }
        }
    }

    // sem dados
    Column {
        visible: !Weather.ready
        anchors.centerIn: parent
        spacing: 6
        UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: Weather.error ? "wCloudy" : "refresh"; size: 26; color: w.dim
            RotationAnimation on rotation { running: Weather.busy && !Weather.ready && w.visible; from: 0; to: 360; duration: 1200; loops: Animation.Infinite } }
        UiText { visible: w.cols > 1; anchors.horizontalCenter: parent.horizontalCenter; width: w.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
            text: Weather.error ? Weather.error : (Weather.busy ? "Buscando o clima…" : "Sem dados do clima. Confira a cidade nas opções."); color: w.dim; font.pixelSize: 12 }
    }


    Loader {
        anchors.fill: parent
        active: Weather.ready
        sourceComponent: ({ plain: plainC, end4: e4C, hero: heroC })[w.lk] ?? plainC
    }
    // falha ao atualizar com dados antigos na tela: avisa dentro do widget e quando funcionou pela ultima vez
    UiText {
        visible: Weather.ready && Weather.error !== "" && w.cols > 1
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 6 }
        horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; maximumLineCount: 1
        text: "Sem conexão · atualizado às " + Qt.formatDateTime(Weather.updated, "HH:mm")
        color: w.dim; font.pixelSize: 11
    }

    // ---- end4: um layout por tamanho ----
    Component {
        id: e4C
        Loader {
            sourceComponent: ({ "1x1": m11C, "1x2": m12C, "2x2": m22C, "1x3": m13C, "2x3": m23C })[w.mode]
        }
    }
    Component {
        id: m11C
        Item {
            id: m
            readonly property real u: Math.max(0.3, Math.min(width / 104, height / 92))
            E4Badge { anchors { right: parent.right; top: parent.top } size: 34 * m.u }
            Column {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                spacing: -2 * m.u
                UiText { text: w.t(w.n.temp); color: w.fg; font.pixelSize: Math.round(32 * m.u); font.weight: Font.Bold; font.features: { "tnum": 1 } }
                UiText { width: parent.width; elide: Text.ElideRight; text: Weather.place; color: w.dim; font.pixelSize: Math.round(14 * m.u) }
            }
        }
    }
    Component {
        id: m12C
        Item {
            id: m
            readonly property real u: Math.max(0.3, Math.min(width / 256, height / 100))
            DwParts.Panel {
                id: lp
                width: 100 * m.u; height: parent.height
                role: "bg"; alpha: 0.25; radius: Math.min(24 * m.u, height / 2)
                Column {
                    anchors.centerIn: parent
                    spacing: 4 * m.u
                    E4Badge { anchors.horizontalCenter: parent.horizontalCenter; size: 34 * m.u }
                    UiText { anchors.horizontalCenter: parent.horizontalCenter; text: w.t(w.n.temp); color: w.fg; font.pixelSize: Math.round(24 * m.u); font.weight: Font.Bold; font.features: { "tnum": 1 } }
                }
            }
            Item {
                x: lp.width + 12 * m.u; width: parent.width - x - 4 * m.u; height: parent.height
                Column {
                    width: parent.width
                    y: 4 * m.u
                    UiText { width: parent.width; elide: Text.ElideRight; text: Weather.place; color: w.fg; font.pixelSize: Math.round(15 * m.u); font.weight: Font.DemiBold }
                    UiText { width: parent.width; elide: Text.ElideRight; text: Weather.describe(w.n.code); color: w.dim; font.pixelSize: Math.round(12 * m.u) }
                }
                Row {
                    anchors { bottom: parent.bottom; bottomMargin: 2 * m.u }
                    width: parent.width; spacing: 6 * m.u
                    Repeater {
                        model: [w.allMetrics[0], w.allMetrics[1]]
                        delegate: E4Tile { required property var modelData; width: (parent.width - 6 * m.u) / 2; height: 40 * m.u; u: m.u; compact: true; icon: modelData[0]; value: modelData[2]; sev: modelData[3] }
                    }
                }
            }
        }
    }
    Component {
        id: m22C
        Item {
            id: m
            readonly property real u: Math.max(0.3, Math.min(width / 248, height / 224))
            Row {
                id: h22
                spacing: 10 * m.u
                E4Badge { anchors.verticalCenter: parent.verticalCenter; size: 44 * m.u }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    UiText { text: w.t(w.n.temp); color: w.acc; font.pixelSize: Math.round(30 * m.u); font.weight: Font.Bold; font.features: { "tnum": 1 } }
                    UiText { text: Weather.describe(w.n.code); color: w.dim; font.pixelSize: Math.round(12 * m.u) }
                }
            }
            Row {
                id: c22
                y: h22.height + 6 * m.u
                spacing: 4 * m.u
                UiIcon { name: "mapMarker"; size: Math.round(15 * m.u); color: w.acc; anchors.verticalCenter: parent.verticalCenter }
                UiText { text: Weather.place; color: w.fg; font.pixelSize: Math.round(13 * m.u); anchors.verticalCenter: parent.verticalCenter }
            }
            Grid {
                y: c22.y + c22.height + 10 * m.u
                width: parent.width; height: parent.height - y
                columns: 2; spacing: 10 * m.u
                Repeater {
                    model: w.allMetrics.slice(0, 4)
                    delegate: E4Tile { required property var modelData; width: (parent.width - parent.spacing) / 2; height: (parent.height - parent.spacing) / 2; u: m.u; icon: modelData[0]; label: modelData[1]; value: modelData[2]; sev: modelData[3] }
                }
            }
        }
    }
    Component {
        id: m13C
        Item {
            id: m
            readonly property real u: Math.max(0.3, Math.min(width / 392, height / 92))
            Row {
                spacing: 12 * m.u
                UiText { text: w.t(w.n.temp); color: w.fg; font.pixelSize: Math.round(40 * m.u); font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter; font.features: { "tnum": 1 } }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    UiText { text: Weather.describe(w.n.code); color: w.fg; font.pixelSize: Math.round(16 * m.u) }
                    UiText { text: Weather.place; color: w.dim; font.pixelSize: Math.round(13 * m.u) }
                }
            }
            E4Badge { anchors { right: parent.right; top: parent.top } size: 36 * m.u }
            Row {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                spacing: 8 * m.u
                Repeater {
                    model: w.allMetrics.slice(0, 4)
                    delegate: E4Tile { required property var modelData; width: (parent.width - 24 * m.u) / 4; height: 40 * m.u; u: m.u; compact: true; icon: modelData[0]; value: modelData[2]; sev: modelData[3] }
                }
            }
        }
    }
    Component {
        id: m23C
        Item {
            id: m
            readonly property real u: Math.max(0.3, Math.min(width / 392, height / 224))
            Row {
                id: h23
                width: parent.width
                spacing: 18 * m.u
                Column {
                    UiText { text: w.t(w.n.temp); color: w.acc; font.pixelSize: Math.round(44 * m.u); font.weight: Font.Bold; font.features: { "tnum": 1 } }
                    Row {
                        spacing: 4 * m.u
                        UiIcon { name: "mapMarker"; size: Math.round(14 * m.u); color: w.acc; anchors.verticalCenter: parent.verticalCenter }
                        UiText { text: Weather.place; color: w.fg; font.pixelSize: Math.round(13 * m.u); anchors.verticalCenter: parent.verticalCenter }
                    }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    UiText { text: Weather.describe(w.n.code); color: w.fg; font.pixelSize: Math.round(16 * m.u) }
                    UiText { text: "Sensação " + w.t(w.n.feels); color: w.dim; font.pixelSize: Math.round(13 * m.u) }
                }
            }
            E4Badge { anchors { right: parent.right; top: parent.top } size: 44 * m.u }
            Grid {
                y: h23.height + 12 * m.u
                width: parent.width; height: parent.height - y
                columns: 3; spacing: 10 * m.u
                Repeater {
                    model: w.allMetrics
                    delegate: E4Tile { required property var modelData; width: (parent.width - 2 * parent.spacing) / 3; height: (parent.height - parent.spacing) / 2; u: m.u; radius: Math.min(height / 2, 18 * m.u); icon: modelData[0]; label: modelData[1]; value: modelData[2]; sev: modelData[3] }
                }
            }
        }
    }

    // ---- destaque: temperatura grande, selo grande e blocos embaixo ----
    Component {
        id: heroC
        Loader {
            sourceComponent: w.mode === "1x1" ? m11C : heroBody
        }
    }
    Component {
        id: heroBody
        Item {
            id: hb
            readonly property bool tall: w.rows > 1
            readonly property real u: Math.max(0.3, tall ? Math.min(width / 300, height / 230) : Math.min(width / 392, height / 110))
            readonly property int nT: !tall ? (w.cols >= 3 ? 4 : 0) : w.cols >= 3 ? 6 : 4
            Row {
                id: hh
                width: parent.width
                spacing: 14 * hb.u
                UiText { id: ht; text: w.t(w.n.temp); color: w.acc; font.pixelSize: Math.round((hb.tall ? 60 : 50) * hb.u); font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter; font.features: { "tnum": 1 } }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - ht.implicitWidth - hbg.width - 28 * hb.u
                    UiText { width: parent.width; elide: Text.ElideRight; text: Weather.describe(w.n.code); color: w.fg; font.pixelSize: Math.round(16 * hb.u); font.weight: Font.Medium }
                    UiText { width: parent.width; elide: Text.ElideRight; text: Weather.place; color: w.dim; font.pixelSize: Math.round(13 * hb.u) }
                    UiText { visible: hb.tall; width: parent.width; elide: Text.ElideRight; text: Weather.days.length ? "↑ " + w.t(Weather.days[0].max) + "  ↓ " + w.t(Weather.days[0].min) + "  ·  sensação " + w.t(w.n.feels) : ""; color: w.dim; font.pixelSize: Math.round(12 * hb.u); font.features: { "tnum": 1 } }
                }
                E4Badge { id: hbg; anchors.verticalCenter: parent.verticalCenter; size: (hb.tall ? 72 : 56) * hb.u }
            }
            Grid {
                visible: hb.nT > 0
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: hb.tall ? Math.min(parent.height - hh.height - 10 * hb.u, 120 * hb.u) : 40 * hb.u
                columns: hb.tall ? (hb.nT === 6 ? 3 : 2) : hb.nT; spacing: 8 * hb.u
                Repeater {
                    model: w.allMetrics.slice(0, hb.nT)
                    delegate: E4Tile {
                        required property var modelData
                        width: (parent.width - (parent.columns - 1) * parent.spacing) / parent.columns
                        height: (parent.height - (hb.tall ? Math.ceil(hb.nT / parent.columns) - 1 : 0) * parent.spacing) / (hb.tall ? Math.ceil(hb.nT / parent.columns) : 1)
                        u: hb.u; compact: !hb.tall; icon: modelData[0]; label: modelData[1]; value: modelData[2]; sev: modelData[3]
                    }
                }
            }
        }
    }

    // ---- atual ----
    Component {
        id: plainC
        Item {
            // ---- estreito (1x2: agora e max/min; 1x3: + proximos dias): modos fixos, sem opcoes de conteudo ----
            Column {
                visible: Weather.ready && w.narrow
                anchors.fill: parent
                spacing: 3
                ShapeIcon { anchors.horizontalCenter: parent.horizontalCenter; shape: "cookie12"; icon: Weather.icon(w.n.code, w.n.day); size: 48; padding: 10; color: w.ac; iconColor: Theme.accentText }
                UiText { anchors.horizontalCenter: parent.horizontalCenter; text: w.t(w.n.temp); color: w.fg; font.pixelSize: 30; font.weight: Font.Bold; font.features: { "tnum": 1 } }
                UiText { anchors.horizontalCenter: parent.horizontalCenter; width: w.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: Weather.describe(w.n.code); color: w.fg; font.pixelSize: 12; font.weight: Font.Medium }
                UiText { anchors.horizontalCenter: parent.horizontalCenter; text: Weather.days.length ? "↑ " + w.t(Weather.days[0].max) + "  ↓ " + w.t(Weather.days[0].min) : ""; color: w.dim; font.pixelSize: 11; font.features: { "tnum": 1 } }
                UiText { anchors.horizontalCenter: parent.horizontalCenter; width: w.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: Weather.place; color: w.dim; font.pixelSize: 11 }
                Repeater {
                    model: w.rows >= 3 ? Weather.days.slice(1, 3) : []
                    delegate: Row {
                        required property var modelData
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6
                        UiText { anchors.verticalCenter: parent.verticalCenter; text: w.loc.dayName(modelData.date.getDay(), Locale.ShortFormat).replace(".", ""); color: w.dim; font.pixelSize: 11; font.weight: Font.DemiBold }
                        UiIcon { anchors.verticalCenter: parent.verticalCenter; name: Weather.icon(modelData.code, true); size: 18; color: w.ac }
                        UiText { anchors.verticalCenter: parent.verticalCenter; text: w.t(modelData.max) + " " + w.t(modelData.min); color: w.fg; font.pixelSize: 11; font.features: { "tnum": 1 } }
                    }
                }
            }

            Item {
                visible: Weather.ready && !w.narrow
                anchors.fill: parent
                readonly property bool tiny: w.cols === 1 && w.rows === 1
                readonly property real topH: w.rows > 1 ? height * 0.5 : height

                // ---- agora ----
                Item {
                    id: nowBox
                    width: parent.width; height: parent.topH
                    Column {   // 1x1
                        visible: parent.parent.tiny
                        anchors.centerIn: parent
                        spacing: 2
                        ShapeIcon { anchors.horizontalCenter: parent.horizontalCenter; shape: "cookie12"; icon: Weather.icon(w.n.code, w.n.day); size: 52; padding: 11; color: w.ac; iconColor: Theme.accentText }
                        UiText { anchors.horizontalCenter: parent.horizontalCenter; text: w.t(w.n.temp); color: w.fg; font.pixelSize: 34; font.weight: Font.Bold; font.features: { "tnum": 1 } }
                        UiText { anchors.horizontalCenter: parent.horizontalCenter; text: Weather.place; color: w.dim; font.pixelSize: 11; width: w.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
                    }
                    Row {
                        visible: !parent.parent.tiny
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 14
                        ShapeIcon { anchors.verticalCenter: parent.verticalCenter; shape: "cookie12"; icon: Weather.icon(w.n.code, w.n.day); size: Math.min(nowBox.height * 0.7, 72); padding: size * 0.22; color: w.ac; iconColor: Theme.accentText }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0
                            Row {
                                spacing: 8
                                UiText { text: w.t(w.n.temp); color: w.fg; font.pixelSize: Math.min(nowBox.height * 0.42, 52); font.weight: Font.Bold; font.features: { "tnum": 1 } }
                                Column {
                                    anchors.bottom: parent.bottom; anchors.bottomMargin: 6
                                    UiText { text: Weather.days.length ? "↑ " + w.t(Weather.days[0].max) : ""; color: w.dim; font.pixelSize: 12; font.features: { "tnum": 1 } }
                                    UiText { text: Weather.days.length ? "↓ " + w.t(Weather.days[0].min) : ""; color: w.dim; font.pixelSize: 12; font.features: { "tnum": 1 } }
                                }
                            }
                            UiText { text: Weather.describe(w.n.code); color: w.fg; font.pixelSize: 14; font.weight: Font.Medium }
                            UiText { visible: w.rows > 1; text: "Sensação " + w.t(w.n.feels); color: w.dim; font.pixelSize: 12 }
                            Row {
                                spacing: 4
                                UiIcon { name: "mapMarker"; size: 12; color: w.dim; anchors.verticalCenter: parent.verticalCenter }
                                UiText { text: Weather.place; color: w.dim; font.pixelSize: 12 }
                            }
                        }
                    }
                    // detalhes a direita (2x1 sem previsao, ou em cima nos altos sem blocos): quatro blocos pequenos
                    Grid {
                        visible: w.o("details") && !parent.parent.tiny && !w.tilesOn && (w.show === "now" || w.rows > 1) && nowBox.width > 300
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        columns: 2; spacing: 6
                        Repeater {
                            model: w.metrics.slice(0, 4)
                            delegate: Tile { required property var modelData; width: 88; height: 34; compact: true; icon: modelData[0]; value: modelData[2] }
                        }
                    }
                }

                // ---- blocos de detalhe (2x2: 4, 3x2: 6) ----
                Grid {
                    visible: w.tilesOn
                    y: parent.topH + 6
                    width: parent.width; height: parent.height - parent.topH - 6
                    columns: w.cols >= 3 ? 3 : 2
                    spacing: 8
                    readonly property int rowsN: Math.ceil(w.metrics.length / columns)
                    Repeater {
                        model: w.metrics
                        delegate: Tile {
                            required property var modelData
                            width: (parent.width - parent.spacing * (parent.columns - 1)) / parent.columns
                            height: (parent.height - parent.spacing * (parent.rowsN - 1)) / parent.rowsN
                            icon: modelData[0]; label: modelData[1]; value: modelData[2]
                        }
                    }
                }

                // ---- previsao ----
                Row {
                    id: fc
                    visible: w.show !== "now" && !w.tilesOn && !parent.tiny
                    readonly property bool side: w.rows === 1
                    x: side ? parent.width - width : 0
                    y: side ? (parent.height - height) / 2 : parent.topH + 6
                    width: side ? Math.min(parent.width * 0.55, count * 58) : parent.width
                    height: side ? parent.height * 0.9 : parent.height - parent.topH - 6
                    readonly property int fit: Math.max(3, Math.floor((side ? w.width * 0.55 : w.width) / 58))
                    readonly property var items: w.show === "days" ? Weather.days.slice(0, fit) : Weather.hours.filter((h, i) => i % (w.rows > 1 ? 2 : 3) === 0).slice(0, fit)
                    readonly property int count: items.length
                    Repeater {
                        model: fc.items
                        delegate: Column {
                            required property var modelData
                            required property int index
                            width: fc.width / Math.max(1, fc.count)
                            spacing: 4
                            anchors.verticalCenter: parent.verticalCenter
                            UiText { anchors.horizontalCenter: parent.horizontalCenter
                                text: w.show === "days" ? (index === 0 ? "Hoje" : w.loc.dayName(modelData.date.getDay(), Locale.ShortFormat).replace(".", "")) : Qt.formatDateTime(modelData.time, "HH'h'")
                                color: w.dim; font.pixelSize: 11; font.weight: Font.DemiBold }
                            UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: Weather.icon(modelData.code, w.show === "days" ? true : modelData.day); size: 22; color: w.ac }
                            UiText { anchors.horizontalCenter: parent.horizontalCenter; text: w.show === "days" ? w.t(modelData.max) : w.t(modelData.temp); color: w.fg; font.pixelSize: 13; font.weight: Font.Bold; font.features: { "tnum": 1 } }
                            UiText { visible: w.show === "days" && !fc.side; anchors.horizontalCenter: parent.horizontalCenter; text: w.t(modelData.min); color: w.dim; font.pixelSize: 11; font.features: { "tnum": 1 } }
                            UiText { visible: !fc.side && (modelData.rain ?? 0) > 10; anchors.horizontalCenter: parent.horizontalCenter; text: modelData.rain + "%"; color: w.ac2; font.pixelSize: 11; font.features: { "tnum": 1 } }
                        }
                    }
                }
            }
        }
    }
}
