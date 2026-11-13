// Calendario, composicao "Sereno" (a padrao): o dia de hoje como numero grande e o mes numa grade sem caixa.
// 1 coluna: so o dia; 2x1: o dia + a semana; 2 linhas: o mes (com o dia ao lado a partir de 3 colunas).
// host = o DwCalendar (datas, cores e opcoes vem dele). Um so destaque de cor: o dia de hoje.
import QtQuick

Item {
    id: c
    property Item host
    readonly property bool tall: host.rows > 1
    readonly property bool slim: host.cols === 1
    readonly property real u: Math.max(0.72, Math.min(1.25, height / (tall ? 278 : 114)))
    readonly property date today: host.today
    readonly property bool sideOn: !slim && (!tall || host.cols >= 3)
    function name(d, f) { return d.toLocaleDateString(host.loc, f).replace(".", "") }

    // dia de hoje: dia da semana, numero grande e mes
    Column {
        id: side
        visible: c.slim || c.sideOn
        width: c.slim ? parent.width : Math.round(96 * c.u)
        y: c.slim ? parent.height - height : (parent.height - height) / 2
        spacing: 0
        UiText { width: parent.width; elide: Text.ElideRight; text: host.cap(c.name(c.today, c.slim ? "ddd" : "dddd")); color: host.fg; font.pixelSize: Math.round(13 * c.u); font.weight: Font.Medium }
        UiText {
            text: c.today.getDate(); color: host.fg
            font.family: Theme.fontTitle; font.pixelSize: Math.round((c.tall && !c.slim ? 60 : 46) * c.u); font.weight: Font.Medium; font.features: { "tnum": 1 }
            lineHeight: 0.95
        }
        UiText { width: parent.width; elide: Text.ElideRight; text: host.cap(c.name(c.today, c.slim ? "MMM" : "MMMM")); color: host.dim; font.pixelSize: Math.round(12 * c.u) }
    }

    // 2x1: a semana de hoje
    Row {
        id: week
        visible: !c.tall && !c.slim
        x: side.width + 12 * c.u
        width: parent.width - x
        anchors.verticalCenter: parent.verticalCenter
        Repeater {
            model: 7
            delegate: Column {
                id: wd
                required property int index
                readonly property date d: new Date(c.today.getFullYear(), c.today.getMonth(), c.today.getDate() - ((c.today.getDay() - host.ws + 7) % 7) + index)
                readonly property bool isToday: d.toDateString() === c.today.toDateString()
                width: week.width / 7
                spacing: 6 * c.u
                UiText { anchors.horizontalCenter: parent.horizontalCenter; text: host.wd[wd.index]; color: host.dim; font.pixelSize: Math.round(11 * c.u) }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(wd.width - 2, Math.round(28 * c.u)); height: width; radius: width / 2
                    color: wd.isToday ? host.acc : "transparent"
                    UiText { anchors.centerIn: parent; text: wd.d.getDate(); color: wd.isToday ? host.accInk : host.dayCol(wd.d, true); font.pixelSize: Math.round(13 * c.u); font.weight: wd.isToday ? Font.DemiBold : Font.Normal; font.features: { "tnum": 1 } }
                }
            }
        }
    }

    // 2 linhas ou mais: o mes
    Item {
        visible: c.tall && !c.slim
        x: c.sideOn ? side.width + 20 * c.u : 0
        width: parent.width - x
        height: parent.height
        Item {
            id: head
            width: parent.width; height: Math.round(26 * c.u)
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6 * c.u
                UiText { text: host.cap(c.name(host.month, "MMMM")); color: host.fg; font.pixelSize: Math.round(15 * c.u); font.weight: Font.DemiBold }
                UiText { visible: host.month.getFullYear() !== c.today.getFullYear(); text: host.month.getFullYear(); color: host.dim; font.pixelSize: Math.round(15 * c.u) }
            }
            MouseArea { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: parent.width * 0.6; onClicked: host.shift = 0 }
            Row {
                anchors { right: parent.right; rightMargin: -4 * c.u; verticalCenter: parent.verticalCenter }
                Repeater {
                    model: [["chevLeft", -1], ["chevRight", 1]]
                    delegate: Rectangle {
                        required property var modelData
                        width: Math.round(26 * c.u); height: width; radius: width / 2
                        color: nm.containsMouse ? Qt.rgba(host.fg.r, host.fg.g, host.fg.b, 0.12) : "transparent"
                        UiIcon { anchors.centerIn: parent; name: modelData[0]; size: Math.round(16 * c.u); color: host.dim }
                        MouseArea { id: nm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: host.shift += modelData[1] }
                    }
                }
            }
        }
        Grid {
            id: grid
            anchors { top: head.bottom; topMargin: 8 * c.u; left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: -4 * c.u; rightMargin: -4 * c.u }
            readonly property bool wn: host.o("weekNumbers")
            columns: wn ? 8 : 7
            readonly property int lead: (host.month.getDay() - host.ws + 7) % 7
            // so as semanas que o mes ocupa (5 ou 6): sem uma fileira inteira do mes seguinte
            readonly property int weeks: Math.ceil((lead + new Date(host.month.getFullYear(), host.month.getMonth() + 1, 0).getDate()) / 7)
            readonly property real cw: width / columns
            readonly property real ch: height / (weeks + 0.8)
            Repeater {
                model: grid.columns
                delegate: Item {
                    required property int index
                    width: grid.cw; height: grid.ch * 0.8
                    UiText { anchors.centerIn: parent; text: grid.wn ? (index === 0 ? "#" : host.wd[index - 1]) : host.wd[index]; color: host.dim; font.pixelSize: Math.round(11 * c.u) }
                }
            }
            Repeater {
                model: grid.weeks * grid.columns
                delegate: Item {
                    id: cell
                    required property int index
                    readonly property int col: index % grid.columns
                    readonly property int row: Math.floor(index / grid.columns)
                    readonly property bool isWn: grid.wn && col === 0
                    readonly property date d: new Date(host.month.getFullYear(), host.month.getMonth(), row * 7 + (grid.wn ? col - 1 : col) - grid.lead + 1)
                    readonly property bool inMonth: d.getMonth() === host.month.getMonth()
                    readonly property bool isToday: d.toDateString() === c.today.toDateString()
                    width: grid.cw; height: grid.ch
                    Rectangle {
                        visible: cell.isToday && !cell.isWn
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) - 4; height: width; radius: width / 2
                        color: host.acc
                    }
                    UiText {
                        anchors.centerIn: parent
                        text: cell.isWn ? host.isoWeek(new Date(host.month.getFullYear(), host.month.getMonth(), cell.row * 7 - grid.lead + 4)) : cell.d.getDate()
                        font.pixelSize: Math.round((cell.isWn ? 10 : 13) * c.u); font.weight: cell.isToday ? Font.DemiBold : Font.Normal; font.features: { "tnum": 1 }
                        color: cell.isWn ? host.dim : cell.isToday ? host.accInk : host.dayCol(cell.d, cell.inMonth)
                    }
                }
            }
        }
    }
}
