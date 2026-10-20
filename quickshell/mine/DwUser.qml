// Widget do usuario: foto (circulo, flor ou arredondada), saudacao, nome e uma linha de informacao (tempo ligado,
// usuario@maquina ou sistema e kernel). 1x1: foto e saudacao; 3x1: tambem a hora e a data; 2x2: tudo empilhado.
import Quickshell
import Quickshell.Io
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
    function o(k) { return DeskState.opt({ type: "user", opts: w.opts }, k) }
    SystemClock { id: clk; precision: SystemClock.Minutes }
    readonly property string greet: { const h = clk.date.getHours(); return h < 5 ? "Boa noite" : h < 12 ? "Bom dia" : h < 18 ? "Boa tarde" : "Boa noite" }
    property string up: ""
    property int upD: 0
    property int upH: 0
    property int upM: 0
    Component.onCompleted: Weather.use()
    // frase do tempo (pt-BR) a partir do codigo WMO
    readonly property string quip: {
        if (!Weather.ready || Weather.now.code === undefined) return ""
        const c = Number(Weather.now.code)
        return c === 0 ? "dia bom para sair" : c <= 3 ? "um pouco nublado" : c <= 48 ? "neblina por aí" : c <= 67 || (c >= 80 && c <= 82) ? "chovendo, hora do café"
            : c <= 77 || c <= 86 ? "nevando por aí" : "tempestade, melhor ficar em casa"
    }
    property string kernel: ""
    property string host: ""
    FileView { id: upf; path: "/proc/uptime"; onLoaded: {
        const s = parseFloat(text().split(" ")[0]) || 0, h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60)
        w.upD = Math.floor(h / 24); w.upH = h % 24; w.upM = m
        w.up = h > 0 ? h + " h " + m + " min" : m + " min" } }
    FileView { path: "/proc/sys/kernel/osrelease"; onLoaded: w.kernel = text().trim() }
    FileView { path: "/proc/sys/kernel/hostname"; onLoaded: w.host = text().trim() }
    Timer { interval: 60000; repeat: true; running: true; triggeredOnStart: true; onTriggered: upf.reload() }
    readonly property string infoText: ({ uptime: "Ligado há " + up, host: Profile.user + "@" + host, kernel: "Arch Linux · " + kernel, none: "" })[o("info")] ?? ""
    readonly property string infoIcon: ({ uptime: "clock", host: "account", kernel: "arch", none: "" })[o("info")] ?? ""

    readonly property bool statsOn: rows > 2 && o("info") === "uptime"
    readonly property bool btnOn: cols > 1 && rows > 1 && o("buttons")
    component Face: Item {
        property real s: 74
        width: s; height: s
        ShapedImage {
            anchors.fill: parent
            shape: w.o("avatarShape"); sides: 10
            source: Profile.face
            sourceSize: Qt.size(256, 256)
        }
        Flower { anchors.fill: parent; shape: w.o("avatarShape"); sides: 10; color: "transparent"; border: w.ac; borderWidth: 2.5 }
    }

    Column {
        visible: w.cols === 1 || w.rows > 1
        anchors.centerIn: parent
        spacing: 8
        Face { anchors.horizontalCenter: parent.horizontalCenter; s: Math.min(w.width * 0.7, w.height * (w.rows > 2 ? 0.3 : w.btnOn ? 0.32 : w.rows > 1 ? 0.45 : 0.6)) }
        UiText { visible: w.o("greeting"); anchors.horizontalCenter: parent.horizontalCenter; text: w.greet + (w.rows > 1 ? "," : ""); color: w.rows > 1 ? w.dim : w.fg; font.pixelSize: 14; font.weight: Font.Bold }
        UiText { visible: w.rows > 1; anchors.horizontalCenter: parent.horizontalCenter; text: Profile.name; color: w.fg; font.pixelSize: 22; font.weight: Font.Bold }
        UiText { visible: w.cols === 1 && w.rows > 1; anchors.horizontalCenter: parent.horizontalCenter; text: "Hoje • " + clk.date.toLocaleDateString(Qt.locale("pt_BR"), "ddd d MMM"); color: w.dim; font.pixelSize: 12 }
        Row {
            visible: w.rows > 1 && w.infoText !== "" && !w.statsOn
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            UiIcon { name: w.infoIcon; size: 13; color: w.ac; anchors.verticalCenter: parent.verticalCenter }
            UiText { text: w.infoText; color: w.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
        }
        Row {
            visible: w.rows > 1 && w.quip !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            UiIcon { name: Weather.icon(Weather.now.code, Weather.now.day); size: 13; color: w.ac; anchors.verticalCenter: parent.verticalCenter }
            UiText { text: "• " + w.quip; color: w.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
        }
        // tempo ligado em dias / horas / minutos
        Row {
            visible: w.statsOn
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12
            Repeater {
                model: [[w.upD, "dias"], [w.upH, "horas"], [w.upM, "min"]]
                delegate: Row {
                    required property var modelData
                    required property int index
                    spacing: 12
                    Rectangle { visible: index > 0; width: 1; height: 28; anchors.verticalCenter: parent.verticalCenter; color: Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.18) }
                    Column {
                        UiText { anchors.horizontalCenter: parent.horizontalCenter; text: String(modelData[0]); color: w.fg; font.pixelSize: 20; font.weight: Font.Bold; font.features: { "tnum": 1 } }
                        UiText { anchors.horizontalCenter: parent.horizontalCenter; text: modelData[1]; color: w.dim; font.pixelSize: 10 }
                    }
                }
            }
        }
        // atalhos: bloquear, configuracoes e energia
        Row {
            visible: w.btnOn
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            UiButton { text: "Bloquear"; icon: "lock"; kind: "accent"; onClicked: Power.lock() }
            UiButton { icon: "cog"; onClicked: Settings.settingsOpen = true }
            UiButton { icon: "power"; onClicked: Power.menuOpen = true }
        }
    }
    Row {
        visible: w.cols > 1 && w.rows === 1
        anchors.verticalCenter: parent.verticalCenter
        spacing: 16
        Face { anchors.verticalCenter: parent.verticalCenter; s: Math.min(w.height - 8, 96) }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            UiText { visible: w.o("greeting"); text: w.greet + ","; color: w.dim; font.pixelSize: 14 }
            UiText { text: Profile.name; color: w.fg; font.pixelSize: 24; font.weight: Font.Bold }
            Row {
                visible: w.infoText !== ""
                spacing: 6
                UiIcon { name: w.infoIcon; size: 13; color: w.ac; anchors.verticalCenter: parent.verticalCenter }
                UiText { text: w.infoText; color: w.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
    Column {
        visible: w.cols >= 3 && w.rows === 1
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        UiText { anchors.right: parent.right; text: Qt.formatDateTime(clk.date, "HH:mm"); color: w.fg; font.pixelSize: 34; font.weight: Font.Bold }
        UiText { anchors.right: parent.right; text: { const s = clk.date.toLocaleDateString(Qt.locale("pt_BR"), "ddd, d MMM"); return s.charAt(0).toUpperCase() + s.slice(1) } color: w.ac; font.pixelSize: 13 }
    }
}
