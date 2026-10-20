// Widget de calendario. 2x2/3x2: o mes inteiro (setas trocam o mes; clique no titulo volta para hoje);
// 2x1: a semana atual; 1x1: o dia de hoje bem grande. Opcoes: semana comeca no domingo ou segunda,
// fins de semana destacados, numero da semana (ISO).
import Quickshell
import QtQuick

Item {
    id: w
    property int cols: 2
    property int rows: 2
    property var opts: ({})
    property color fg: Theme.text
    property color dim: Theme.muted
    property color ac: Theme.accent
    property color ac2: Theme.tertiary            // cor companheira (o DeskView passa a do tom escolhido)
    property color cont: Theme.primaryContainer
    property color contInk: Theme.primaryContainerInk
    property bool bare: false
    function o(k) { return DeskState.opt({ type: "calendar", opts: w.opts }, k) }
    SystemClock { id: clk; precision: SystemClock.Minutes }
    readonly property date today: clk.date
    property int shift: 0
    WheelHandler { acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad; onWheel: e => w.shift += e.angleDelta.y > 0 ? -1 : 1 }   // roda: troca de mes
    readonly property date month: new Date(today.getFullYear(), today.getMonth() + shift, 1)
    readonly property var loc: Qt.locale("pt_BR")
    function cap(s) { return s.charAt(0).toUpperCase() + s.slice(1) }
    readonly property int ws: o("weekStart")
    readonly property var wd: { const n = ["D", "S", "T", "Q", "Q", "S", "S"]; return n.slice(ws).concat(n.slice(0, ws)) }
    function weekend(d) { return d.getDay() === 0 || d.getDay() === 6 }
    function isoWeek(d) { const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate())); const day = t.getUTCDay() || 7; t.setUTCDate(t.getUTCDate() + 4 - day); const y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1)); return Math.ceil(((t - y0) / 86400000 + 1) / 7) }
    function dayCol(d, inMonth) { const base = w.o("weekends") && weekend(d) ? Qt.tint(w.fg, Qt.rgba(w.ac2.r, w.ac2.g, w.ac2.b, 0.7)) : w.fg; return inMonth ? base : Qt.rgba(base.r, base.g, base.b, 0.35) }

    // 1x1: cracha com a faixa colorida (MES + dia da semana) e o dia grande
    Item {
        visible: w.cols === 1
        anchors.fill: parent
        Rectangle {
            id: band
            width: parent.width; height: parent.height * 0.36
            color: w.ac
            topLeftRadius: w.bare ? 18 : 0; topRightRadius: w.bare ? 18 : 0
            Row {
                anchors.centerIn: parent
                spacing: 6
                UiText { text: w.today.toLocaleDateString(w.loc, "MMM").replace(".", "").toUpperCase(); color: Theme.accentText; font.pixelSize: 15; font.weight: Font.Bold; font.letterSpacing: 1 }
                UiText { text: w.today.toLocaleDateString(w.loc, "ddd").replace(".", "").toUpperCase(); color: Qt.rgba(Theme.accentText.r, Theme.accentText.g, Theme.accentText.b, 0.7); font.pixelSize: 15; font.weight: Font.DemiBold; font.letterSpacing: 1 }
            }
        }
        UiText {
            anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter; verticalCenterOffset: band.height / 2 }
            text: w.today.getDate(); color: w.fg; font.pixelSize: Math.min(60, (parent.height - band.height) * 0.9); font.weight: Font.Bold
        }
    }

    // 2x1: semana
    Column {
        visible: w.cols > 1 && w.rows === 1
        anchors.fill: parent
        spacing: 10
        Rectangle {
            height: 28; width: ptxt.implicitWidth + 28; radius: 14
            color: w.ac
            UiText { id: ptxt; anchors.centerIn: parent; text: w.cap(w.today.toLocaleDateString(w.loc, "MMMM yyyy")) + (w.o("weekNumbers") ? "  ·  semana " + w.isoWeek(w.today) : ""); color: Theme.accentText; font.pixelSize: 14; font.weight: Font.Bold }
        }
        Row {
            width: parent.width
            readonly property real cw: width / 7
            Repeater {
                model: 7
                delegate: Column {
                    required property int index
                    readonly property date d: new Date(w.today.getFullYear(), w.today.getMonth(), w.today.getDate() - ((w.today.getDay() - w.ws + 7) % 7) + index)
                    readonly property bool isToday: d.toDateString() === w.today.toDateString()
                    width: parent.cw
                    spacing: 6
                    UiText { anchors.horizontalCenter: parent.horizontalCenter; text: w.wd[index]; color: w.dim; font.pixelSize: 11; font.weight: Font.DemiBold }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 32; height: 32; radius: 16
                        color: parent.isToday ? w.ac : "transparent"
                        UiText { anchors.centerIn: parent; text: parent.parent.d.getDate(); color: parent.parent.isToday ? Theme.accentText : w.dayCol(parent.parent.d, true); font.pixelSize: 14; font.weight: parent.parent.isToday ? Font.Bold : Font.Medium }
                    }
                }
            }
        }
    }

    // painel lateral (3x2 ou maior): icone em gema, mes, dia da semana e o dia grande
    Column {
        id: side
        readonly property bool on: w.cols >= 3 && w.rows >= 2
        visible: on
        width: 104
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        spacing: 2
        ShapeIcon { shape: "gem"; icon: "calendar"; size: 46; padding: 11; color: w.ac; iconColor: Theme.accentText }
        Item { width: 1; height: 6 }
        UiText { text: w.today.toLocaleDateString(w.loc, "MMMM").toUpperCase(); color: w.dim; font.pixelSize: 12; font.weight: Font.DemiBold; font.letterSpacing: 1 }
        UiText { text: w.cap(w.today.toLocaleDateString(w.loc, "dddd")); color: w.fg; font.pixelSize: 17; font.weight: Font.Medium }
        UiText { text: w.today.getDate(); color: w.ac; font.pixelSize: 58; font.weight: Font.Bold; lineHeight: 0.9 }
    }

    // mes
    Item {
        visible: w.rows > 1
        anchors { fill: parent; leftMargin: side.on ? side.width + 12 : 0 }
        Item {
            id: head
            width: parent.width; height: 30
            UiText { anchors.verticalCenter: parent.verticalCenter; text: w.cap(w.month.toLocaleDateString(w.loc, "MMMM")) + (w.month.getFullYear() !== w.today.getFullYear() ? " " + w.month.getFullYear() : ""); color: w.fg; font.pixelSize: 17; font.weight: Font.Bold }
            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 2
                Repeater {
                    model: [["chevLeft", -1], ["chevRight", 1]]
                    delegate: Rectangle {
                        required property var modelData
                        width: 26; height: 26; radius: 13
                        color: nm.containsMouse ? Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.12) : "transparent"
                        UiIcon { anchors.centerIn: parent; name: modelData[0]; size: 16; color: w.dim }
                        MouseArea { id: nm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: w.shift += modelData[1] }
                    }
                }
            }
            MouseArea { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: 140; onClicked: w.shift = 0 }
        }
        Grid {
            id: grid
            anchors { top: head.bottom; topMargin: 6; left: parent.left; right: parent.right; bottom: parent.bottom }
            readonly property bool wn: w.o("weekNumbers")
            columns: wn ? 8 : 7
            readonly property real cw: width / columns
            readonly property real ch: height / 7
            readonly property int lead: (w.month.getDay() - w.ws + 7) % 7
            Repeater {
                model: grid.columns
                delegate: Item { required property int index; width: grid.cw; height: grid.ch
                    UiText { anchors.centerIn: parent; text: grid.wn ? (index === 0 ? "#" : w.wd[index - 1]) : w.wd[index]; color: w.dim; font.pixelSize: 11; font.weight: Font.DemiBold } }
            }
            Repeater {
                model: 6 * grid.columns
                delegate: Item {
                    required property int index
                    readonly property int col: index % grid.columns
                    readonly property int row: Math.floor(index / grid.columns)
                    readonly property bool isWn: grid.wn && col === 0
                    readonly property int di: row * 7 + (grid.wn ? col - 1 : col)
                    readonly property date d: new Date(w.month.getFullYear(), w.month.getMonth(), di - grid.lead + 1)
                    readonly property bool inMonth: d.getMonth() === w.month.getMonth()
                    readonly property bool isToday: d.toDateString() === w.today.toDateString()
                    width: grid.cw; height: grid.ch
                    Rectangle {
                        visible: !parent.isWn
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) - 4; height: width; radius: width / 2
                        color: parent.isToday ? w.ac : "transparent"
                    }
                    UiText {
                        anchors.centerIn: parent
                        text: parent.isWn ? w.isoWeek(new Date(w.month.getFullYear(), w.month.getMonth(), parent.row * 7 - grid.lead + 4)) : parent.d.getDate()
                        font.pixelSize: parent.isWn ? 10 : 12; font.weight: parent.isToday ? Font.Bold : Font.Normal
                        color: parent.isWn ? w.dim : parent.isToday ? Theme.accentText : w.dayCol(parent.d, parent.inMonth)
                    }
                }
            }
        }
    }
}
