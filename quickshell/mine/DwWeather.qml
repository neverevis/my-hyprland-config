// Widget de clima (Weather.qml). 1x1: icone e temperatura; 2x1: agora + detalhes; 3x1: + proximas horas;
// 2x2/3x2: agora em cima e previsao (horas ou dias) embaixo. opts.show escolhe o que vai na previsao.
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
    function o(k) { return DeskState.opt({ type: "weather", opts: w.opts }, k) }
    Component.onCompleted: Weather.use()
    Component.onDestruction: Weather.release()

    readonly property var n: Weather.now
    readonly property string show: { const s = o("show"); return s !== "auto" ? s : (rows > 1 ? "tiles" : (cols >= 3 ? "hours" : "now")) }
    function t(v) { return v === undefined || v === null ? "--" : Math.round(v) + "°" }
    readonly property var loc: Qt.locale("pt_BR")
    readonly property bool tilesOn: show === "tiles" && rows > 1
    function hm(d) { return d ? Qt.formatDateTime(d, "HH:mm") : "--" }
    function vis(m) { if (m === undefined || m === null) return "--"; return Weather.imperial ? (m / 1609.34).toFixed(1) + " mi" : (m >= 10000 ? Math.round(m / 1000) : (m / 1000).toFixed(1)) + " km" }
    // blocos de detalhe: icone, rotulo, valor (nascer e por do sol so nos largos)
    readonly property var metrics: {
        const d0 = Weather.days.length ? Weather.days[0] : null
        const l = [["humidity", "Umidade", (n.humidity ?? "--") + "%"], ["wRain", "Chuva", (d0 ? d0.rain : "--") + "%"],
                   ["wWind", "Vento", Math.round(n.wind ?? 0) + " " + Weather.windUnit], ["eye", "Visibilidade", vis(n.vis)]]
        if (cols >= 3) l.push(["sunrise", "Nascer do sol", hm(d0 ? d0.sunrise : null)], ["sunset", "Pôr do sol", hm(d0 ? d0.sunset : null)])
        return l
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
            UiText { anchors.verticalCenter: parent.verticalCenter; text: tl.value; color: w.fg; font.pixelSize: 12; font.weight: Font.DemiBold }
        }
        Column {
            visible: !tl.compact
            anchors.centerIn: parent
            width: parent.width - 12
            spacing: 1
            UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: tl.icon; size: Math.min(20, tl.height * 0.3); color: w.ac }
            UiText { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: tl.value; color: w.fg; font.pixelSize: Math.min(15, tl.height * 0.22); font.weight: Font.Bold }
            UiText { visible: tl.height > 58; width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: tl.label; color: w.dim; font.pixelSize: 10 }
        }
    }

    // sem dados
    Column {
        visible: !Weather.ready
        anchors.centerIn: parent
        spacing: 6
        UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: Weather.error ? "wCloudy" : "refresh"; size: 26; color: w.dim
            RotationAnimation on rotation { running: Weather.busy; from: 0; to: 360; duration: 1200; loops: Animation.Infinite } }
        UiText { visible: w.cols > 1; anchors.horizontalCenter: parent.horizontalCenter; width: w.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
            text: Weather.error || "Buscando o clima…"; color: w.dim; font.pixelSize: 12 }
    }

    // ---- estreito (1x2: agora e max/min; 1x3: + proximos dias): modos fixos, sem opcoes de conteudo ----
    readonly property bool narrow: cols === 1 && rows > 1
    Column {
        visible: Weather.ready && w.narrow
        anchors.fill: parent
        spacing: 3
        ShapeIcon { anchors.horizontalCenter: parent.horizontalCenter; shape: "cookie12"; icon: Weather.icon(w.n.code, w.n.day); size: 48; padding: 10; color: w.ac; iconColor: Theme.accentText }
        UiText { anchors.horizontalCenter: parent.horizontalCenter; text: w.t(w.n.temp); color: w.fg; font.pixelSize: 30; font.weight: Font.Bold }
        UiText { anchors.horizontalCenter: parent.horizontalCenter; width: w.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: Weather.describe(w.n.code); color: w.fg; font.pixelSize: 12; font.weight: Font.Medium }
        UiText { anchors.horizontalCenter: parent.horizontalCenter; text: Weather.days.length ? "↑ " + w.t(Weather.days[0].max) + "  ↓ " + w.t(Weather.days[0].min) : ""; color: w.dim; font.pixelSize: 11 }
        UiText { anchors.horizontalCenter: parent.horizontalCenter; width: w.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: Weather.place; color: w.dim; font.pixelSize: 11 }
        Repeater {
            model: w.rows >= 3 ? Weather.days.slice(1, 3) : []
            delegate: Row {
                required property var modelData
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6
                UiText { anchors.verticalCenter: parent.verticalCenter; text: w.loc.dayName(modelData.date.getDay(), Locale.ShortFormat).replace(".", ""); color: w.dim; font.pixelSize: 11; font.weight: Font.DemiBold }
                UiIcon { anchors.verticalCenter: parent.verticalCenter; name: Weather.icon(modelData.code, true); size: 18; color: w.ac }
                UiText { anchors.verticalCenter: parent.verticalCenter; text: w.t(modelData.max) + " " + w.t(modelData.min); color: w.fg; font.pixelSize: 11 }
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
                UiText { anchors.horizontalCenter: parent.horizontalCenter; text: w.t(w.n.temp); color: w.fg; font.pixelSize: 34; font.weight: Font.Bold }
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
                        UiText { text: w.t(w.n.temp); color: w.fg; font.pixelSize: Math.min(nowBox.height * 0.42, 52); font.weight: Font.Bold }
                        Column {
                            anchors.bottom: parent.bottom; anchors.bottomMargin: 6
                            UiText { text: Weather.days.length ? "↑ " + w.t(Weather.days[0].max) : ""; color: w.dim; font.pixelSize: 12 }
                            UiText { text: Weather.days.length ? "↓ " + w.t(Weather.days[0].min) : ""; color: w.dim; font.pixelSize: 12 }
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
                    UiText { anchors.horizontalCenter: parent.horizontalCenter; text: w.show === "days" ? w.t(modelData.max) : w.t(modelData.temp); color: w.fg; font.pixelSize: 13; font.weight: Font.Bold }
                    UiText { visible: w.show === "days" && !fc.side; anchors.horizontalCenter: parent.horizontalCenter; text: w.t(modelData.min); color: w.dim; font.pixelSize: 11 }
                    UiText { visible: !fc.side && (modelData.rain ?? 0) > 10; anchors.horizontalCenter: parent.horizontalCenter; text: modelData.rain + "%"; color: w.ac2; font.pixelSize: 10 }
                }
            }
        }
    }
}
