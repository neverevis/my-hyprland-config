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
    property bool bare: false
    function o(k) { return DeskState.opt({ type: "weather", opts: w.opts }, k) }
    Component.onCompleted: Weather.use()
    Component.onDestruction: Weather.release()

    readonly property var n: Weather.now
    readonly property string show: { const s = o("show"); return s !== "auto" ? s : (rows > 1 ? (cols >= 3 ? "days" : "hours") : (cols >= 3 ? "hours" : "now")) }
    function t(v) { return v === undefined || v === null ? "--" : Math.round(v) + "°" }
    readonly property var loc: Qt.locale("pt_BR")

    // sem dados
    Column {
        visible: !Weather.ready
        anchors.centerIn: parent
        spacing: 6
        UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: Weather.error ? "wCloudy" : "refresh"; size: 26; color: w.dim
            RotationAnimation on rotation { running: Weather.busy; from: 0; to: 360; duration: 1200; loops: Animation.Infinite } }
        Text { visible: w.cols > 1; anchors.horizontalCenter: parent.horizontalCenter; width: w.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
            text: Weather.error || "Buscando o clima…"; color: w.dim; font.pixelSize: 12 }
    }

    Item {
        visible: Weather.ready
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
                UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: Weather.icon(w.n.code, w.n.day); size: 46; color: w.ac }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: w.t(w.n.temp); color: w.fg; font.pixelSize: 34; font.weight: Font.Bold }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Weather.place; color: w.dim; font.pixelSize: 11; width: w.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
            }
            Row {
                visible: !parent.parent.tiny
                anchors.verticalCenter: parent.verticalCenter
                spacing: 14
                UiIcon { anchors.verticalCenter: parent.verticalCenter; name: Weather.icon(w.n.code, w.n.day); size: Math.min(nowBox.height * 0.7, 72); color: w.ac }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0
                    Row {
                        spacing: 8
                        Text { text: w.t(w.n.temp); color: w.fg; font.pixelSize: Math.min(nowBox.height * 0.42, 52); font.weight: Font.Bold }
                        Column {
                            anchors.bottom: parent.bottom; anchors.bottomMargin: 6
                            Text { text: Weather.days.length ? "↑ " + w.t(Weather.days[0].max) : ""; color: w.dim; font.pixelSize: 12 }
                            Text { text: Weather.days.length ? "↓ " + w.t(Weather.days[0].min) : ""; color: w.dim; font.pixelSize: 12 }
                        }
                    }
                    Text { text: Weather.describe(w.n.code); color: w.fg; font.pixelSize: 14; font.weight: Font.Medium }
                    Row {
                        spacing: 4
                        UiIcon { name: "mapMarker"; size: 12; color: w.dim; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: Weather.place; color: w.dim; font.pixelSize: 12 }
                    }
                }
            }
            // detalhes a direita (2x1 sem previsao, ou em cima nos altos)
            Column {
                visible: w.o("details") && !parent.parent.tiny && (w.show === "now" || w.rows > 1) && nowBox.width > 300
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 4
                Repeater {
                    model: [["temperature", "Sensação " + w.t(w.n.feels)], ["humidity", (w.n.humidity ?? "--") + "% umidade"], ["wWind", Math.round(w.n.wind ?? 0) + " " + Weather.windUnit],
                            ["umbrella", (Weather.days.length ? Weather.days[0].rain : "--") + "% chuva"]]
                    delegate: Row {
                        required property var modelData
                        anchors.right: parent.right
                        spacing: 6
                        Text { text: modelData[1]; color: w.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                        UiIcon { name: modelData[0]; size: 13; color: w.ac; anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }

        // ---- previsao ----
        Row {
            id: fc
            visible: w.show !== "now" && !parent.tiny
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
                    Text { anchors.horizontalCenter: parent.horizontalCenter
                        text: w.show === "days" ? (index === 0 ? "Hoje" : w.loc.dayName(modelData.date.getDay(), Locale.ShortFormat).replace(".", "")) : Qt.formatDateTime(modelData.time, "HH'h'")
                        color: w.dim; font.pixelSize: 11; font.weight: Font.DemiBold }
                    UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: Weather.icon(modelData.code, w.show === "days" ? true : modelData.day); size: 22; color: w.ac }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: w.show === "days" ? w.t(modelData.max) : w.t(modelData.temp); color: w.fg; font.pixelSize: 13; font.weight: Font.Bold }
                    Text { visible: w.show === "days" && !fc.side; anchors.horizontalCenter: parent.horizontalCenter; text: w.t(modelData.min); color: w.dim; font.pixelSize: 11 }
                    Text { visible: !fc.side && (modelData.rain ?? 0) > 10; anchors.horizontalCenter: parent.horizontalCenter; text: modelData.rain + "%"; color: w.ac; font.pixelSize: 10 }
                }
            }
        }
    }
}
