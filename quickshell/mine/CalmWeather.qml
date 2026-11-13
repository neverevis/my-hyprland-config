// Clima, composicao "Sereno" (a padrao): um numero grande, uma linha de texto e a previsao numa faixa, sem caixas
// internas nem selos. host = o DwWeather (dados, cores e opcoes vem dele). Um so destaque de cor: o icone de agora.
import QtQuick

Item {
    id: c
    property Item host
    readonly property var n: Weather.now
    readonly property var d0: Weather.days.length ? Weather.days[0] : null
    readonly property bool tall: host.rows > 1
    readonly property bool tiny: host.cols === 1 && host.rows === 1
    readonly property bool wide: host.cols >= 3
    readonly property real u: Math.max(0.72, Math.min(1.25, height / (tall ? 278 : 114)))
    readonly property bool strip: !tiny && host.show !== "now" && (tall || wide)
    readonly property bool byDay: host.show === "days"
    readonly property real stripW: tall ? width : width - left.width - 28 * u
    readonly property int fit: Math.max(2, Math.min(7, Math.floor(stripW / (52 * u))))
    readonly property var items: !strip ? [] : byDay ? Weather.days.slice(1, fit + 1) : Weather.hours.filter((h, i) => i > 0 && i % 3 === 0).slice(0, fit)
    readonly property string range: d0 ? "↑ " + host.t(d0.max) + "  ↓ " + host.t(d0.min) : ""
    function line(a) { return a.filter(s => s !== "").join("  ·  ") }

    // o selo do shell (forma + icone): o unico ponto de cor do cartao
    DwParts.Badge {
        anchors { right: tall || !strip ? parent.right : left.right; top: parent.top }
        shape: host.badgeShape; icon: host.nowIcon; bg: host.acc
        size: Math.round((c.tall ? 46 : c.tiny ? 28 : 36) * c.u)
    }
    Column {
        id: left
        width: c.tall || !c.strip ? parent.width : Math.min(parent.width * 0.44, 200 * c.u)
        y: c.tall ? 0 : (parent.height - height) / 2   // sem trocar ancoras: o tamanho chega depois da criacao
        spacing: 2 * c.u
        UiText {
            visible: c.tall; width: parent.width - 48 * c.u; elide: Text.ElideRight
            text: Weather.place; color: host.dim; font.pixelSize: Math.round(13 * c.u); font.weight: Font.Medium
        }
        UiText {
            text: host.t(c.n.temp); color: host.fg
            font.family: Theme.fontTitle; font.pixelSize: Math.round((c.tall ? 60 : c.tiny ? 34 : 44) * c.u); font.weight: Font.Medium; font.features: { "tnum": 1 }
            lineHeight: 0.95
        }
        UiText {
            visible: !c.tiny; width: parent.width; elide: Text.ElideRight
            text: Weather.describe(c.n.code); color: host.fg; font.pixelSize: Math.round((c.tall ? 14 : 13) * c.u); font.weight: Font.Medium
        }
        UiText {
            width: parent.width; elide: Text.ElideRight
            text: c.tiny ? Weather.place : c.tall ? c.line([c.range, "sensação " + host.t(c.n.feels)]) : c.line([Weather.place, c.range])
            color: host.dim; font.pixelSize: Math.round((c.tiny ? 11 : 12) * c.u); font.features: { "tnum": 1 }
        }
    }
    // detalhes numa linha so (icone + valor), sem caixas
    Row {
        visible: c.tall && host.o("details") && c.height > 200
        anchors { left: parent.left; top: left.bottom; topMargin: 12 * c.u }
        spacing: 14 * c.u
        Repeater {
            model: [host.allMetrics[0], host.allMetrics[1], host.allMetrics[3]]
            delegate: Row {
                required property var modelData
                spacing: 5 * c.u
                UiIcon { anchors.verticalCenter: parent.verticalCenter; name: modelData[0]; size: Math.round(14 * c.u); color: host.dim }
                UiText { anchors.verticalCenter: parent.verticalCenter; text: modelData[2]; color: host.sevColor(host.fg, modelData[3]); font.pixelSize: Math.round(12 * c.u); font.weight: Font.Medium; font.features: { "tnum": 1 } }
            }
        }
    }
    // previsao: colunas soltas separadas so por espaco; um fio fino separa do "agora"
    Rectangle {
        visible: c.strip
        x: c.tall ? 0 : left.width + 13 * c.u
        y: c.tall ? stripRow.y - 12 * c.u : 6 * c.u
        width: c.tall ? parent.width : 1
        height: c.tall ? 1 : parent.height - 12 * c.u
        color: Qt.rgba(host.fg.r, host.fg.g, host.fg.b, 0.12)
    }
    Row {
        id: stripRow
        visible: c.strip
        x: c.tall ? 0 : parent.width - c.stripW
        width: c.stripW
        y: c.tall ? parent.height - height : (parent.height - height) / 2
        Repeater {
            model: c.items
            delegate: Column {
                required property var modelData
                width: stripRow.width / Math.max(1, c.items.length)
                spacing: 4 * c.u
                UiText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: c.byDay ? modelData.date.toLocaleDateString(host.loc, "ddd").replace(".", "") : Qt.formatDateTime(modelData.time, "HH") + "h"
                    color: host.dim; font.pixelSize: Math.round(11 * c.u); font.features: { "tnum": 1 }
                }
                UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: Weather.icon(modelData.code, c.byDay ? true : modelData.day); size: Math.round(20 * c.u); color: host.fg; opacity: 0.85 }
                UiText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: host.t(c.byDay ? modelData.max : modelData.temp)
                    color: host.fg; font.pixelSize: Math.round(13 * c.u); font.weight: Font.DemiBold; font.features: { "tnum": 1 }
                }
                UiText {
                    visible: c.byDay
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: host.t(modelData.min); color: host.dim; font.pixelSize: Math.round(11 * c.u); font.features: { "tnum": 1 }
                }
            }
        }
    }
}
