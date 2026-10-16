// Widget do usuario: foto, saudacao, nome e tempo ligado. 1x1: so a foto e a saudacao; 3x1: tambem a data.
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: w
    property int cols: 2
    property int rows: 1
    property var opts: ({})
    SystemClock { id: clk; precision: SystemClock.Minutes }
    readonly property string greet: { const h = clk.date.getHours(); return h < 5 ? "Boa noite" : h < 12 ? "Bom dia" : h < 18 ? "Boa tarde" : "Boa noite" }
    property string up: ""
    FileView { id: upf; path: "/proc/uptime"; onLoaded: {
        const s = parseFloat(text().split(" ")[0]) || 0, h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60)
        w.up = h > 0 ? h + " h " + m + " min" : m + " min" } }
    Timer { interval: 60000; repeat: true; running: true; triggeredOnStart: true; onTriggered: upf.reload() }

    Column {
        visible: w.cols === 1
        anchors.centerIn: parent
        spacing: 8
        Avatar { anchors.horizontalCenter: parent.horizontalCenter; size: 74; ring: 3 }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: w.greet; color: Theme.text; font.pixelSize: 14; font.weight: Font.Bold }
    }
    Row {
        visible: w.cols > 1
        anchors.verticalCenter: parent.verticalCenter
        spacing: 16
        Avatar { anchors.verticalCenter: parent.verticalCenter; size: Math.min(w.height - 8, 96); ring: 3 }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            Text { text: w.greet + ","; color: Theme.muted; font.pixelSize: 14 }
            Text { text: Profile.name; color: Theme.text; font.pixelSize: 24; font.weight: Font.Bold }
            Row {
                spacing: 6
                UiIcon { name: "clock"; size: 13; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "Ligado há " + w.up; color: Theme.muted; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
    Column {
        visible: w.cols >= 3
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        Text { anchors.right: parent.right; text: Qt.formatDateTime(clk.date, "HH:mm"); color: Theme.text; font.pixelSize: 34; font.weight: Font.Bold }
        Text { anchors.right: parent.right; text: { const s = clk.date.toLocaleDateString(Qt.locale("pt_BR"), "ddd, d MMM"); return s.charAt(0).toUpperCase() + s.slice(1) } color: Theme.accent; font.pixelSize: 13 }
    }
}
