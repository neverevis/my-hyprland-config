// Widget de calendario. 2x2: o mes inteiro (setas trocam o mes); 2x1: a semana atual; 1x1: o dia de hoje bem grande.
import Quickshell
import QtQuick

Item {
    id: w
    property int cols: 2
    property int rows: 2
    property var opts: ({})
    SystemClock { id: clk; precision: SystemClock.Minutes }
    readonly property date today: clk.date
    property int shift: 0   // meses a partir do atual
    readonly property date month: new Date(today.getFullYear(), today.getMonth() + shift, 1)
    readonly property var loc: Qt.locale("pt_BR")
    function cap(s) { return s.charAt(0).toUpperCase() + s.slice(1) }
    readonly property var wd: ["D", "S", "T", "Q", "Q", "S", "S"]

    // 1x1
    Column {
        visible: w.cols === 1
        anchors.centerIn: parent
        spacing: 0
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: w.cap(w.today.toLocaleDateString(w.loc, "dddd")); color: Theme.accent; font.pixelSize: 14; font.weight: Font.DemiBold }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: w.today.getDate(); color: Theme.text; font.pixelSize: 64; font.weight: Font.Bold; lineHeight: 0.9 }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: w.cap(w.today.toLocaleDateString(w.loc, "MMMM")); color: Theme.muted; font.pixelSize: 13 }
    }

    // 2x1: semana
    Column {
        visible: w.cols > 1 && w.rows === 1
        anchors.fill: parent
        spacing: 10
        Text { text: w.cap(w.today.toLocaleDateString(w.loc, "MMMM 'de' yyyy")); color: Theme.text; font.pixelSize: 16; font.weight: Font.Bold }
        Row {
            width: parent.width
            readonly property real cw: width / 7
            Repeater {
                model: 7
                delegate: Column {
                    required property int index
                    readonly property date d: new Date(w.today.getFullYear(), w.today.getMonth(), w.today.getDate() - w.today.getDay() + index)
                    readonly property bool isToday: index === w.today.getDay()
                    width: parent.cw
                    spacing: 6
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: w.wd[index]; color: Theme.muted; font.pixelSize: 11; font.weight: Font.DemiBold }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 32; height: 32; radius: 16
                        color: parent.isToday ? Theme.accent : "transparent"
                        Text { anchors.centerIn: parent; text: parent.parent.d.getDate(); color: parent.parent.isToday ? Theme.accentText : Theme.text; font.pixelSize: 14; font.weight: parent.parent.isToday ? Font.Bold : Font.Medium }
                    }
                }
            }
        }
    }

    // 2x2: mes
    Item {
        visible: w.rows > 1
        anchors.fill: parent
        Item {
            id: head
            width: parent.width; height: 30
            Text { anchors.verticalCenter: parent.verticalCenter; text: w.cap(w.month.toLocaleDateString(w.loc, "MMMM")) + (w.month.getFullYear() !== w.today.getFullYear() ? " " + w.month.getFullYear() : ""); color: Theme.text; font.pixelSize: 17; font.weight: Font.Bold }
            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 2
                Repeater {
                    model: [["chevLeft", -1], ["chevRight", 1]]
                    delegate: Rectangle {
                        required property var modelData
                        width: 26; height: 26; radius: 13
                        color: nm.containsMouse ? Theme.cardHi : "transparent"
                        UiIcon { anchors.centerIn: parent; name: modelData[0]; size: 16; color: Theme.muted }
                        MouseArea { id: nm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: w.shift += modelData[1] }
                    }
                }
            }
            MouseArea { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } width: 140; onClicked: w.shift = 0 }
        }
        Grid {
            anchors { top: head.bottom; topMargin: 6; left: parent.left; right: parent.right; bottom: parent.bottom }
            columns: 7
            readonly property real cw: width / 7
            readonly property real ch: height / 7
            Repeater {
                model: 7
                delegate: Item { required property int index; width: parent.cw; height: parent.ch
                    Text { anchors.centerIn: parent; text: w.wd[index]; color: Theme.muted; font.pixelSize: 11; font.weight: Font.DemiBold } }
            }
            Repeater {
                model: 42
                delegate: Item {
                    required property int index
                    readonly property date d: new Date(w.month.getFullYear(), w.month.getMonth(), index - w.month.getDay() + 1)
                    readonly property bool inMonth: d.getMonth() === w.month.getMonth()
                    readonly property bool isToday: d.toDateString() === w.today.toDateString()
                    width: parent.cw; height: parent.ch
                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) - 4; height: width; radius: width / 2
                        color: parent.isToday ? Theme.accent : "transparent"
                    }
                    Text { anchors.centerIn: parent; text: parent.d.getDate(); font.pixelSize: 12; font.weight: parent.isToday ? Font.Bold : Font.Normal
                        color: parent.isToday ? Theme.accentText : (parent.inMonth ? Theme.text : Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.45)) }
                }
            }
        }
    }
}
