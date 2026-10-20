// Aba "Tradutor" da barra lateral esquerda: entrada e saida lado a lado (em coluna), troca de idiomas, colar, copiar e
// abrir no Google Tradutor. Usa o translate-shell (trans); espera 300 ms depois de parar de digitar.
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls

Item {
    id: tab
    readonly property var langs: [["auto", "Detectar"], ["pt", "Português"], ["en", "Inglês"], ["es", "Espanhol"], ["fr", "Francês"], ["de", "Alemão"],
        ["it", "Italiano"], ["ja", "Japonês"], ["ko", "Coreano"], ["zh", "Chinês"], ["ru", "Russo"], ["ar", "Árabe"], ["hi", "Hindi"], ["tr", "Turco"],
        ["nl", "Holandês"], ["pl", "Polonês"], ["uk", "Ucraniano"], ["sv", "Sueco"], ["el", "Grego"], ["he", "Hebraico"], ["id", "Indonésio"],
        ["vi", "Vietnamita"], ["th", "Tailandês"], ["fa", "Persa"], ["la", "Latim"]]
    function nameOf(c) { return (langs.find(l => l[0] === c) ?? [c, c])[1] }
    property string pick: ""           // "" | "src" | "tgt"
    property string out: ""
    property string err: ""
    property bool queued: false

    function swap() {
        if (Settings.trSource === "auto") return
        const s = Settings.trSource; Settings.trSource = Settings.trTarget; Settings.trTarget = s
        if (out !== "") { const t = out; input.text = t }
    }
    function run() {
        if (input.text.trim() === "") { out = ""; err = ""; return }
        if (proc.running) { queued = true; return }
        const c = ["trans", "-e", Settings.trEngine, "-4", "-brief", "-no-bidi"]
        if (Settings.trSource !== "auto") c.push("-s", Settings.trSource)
        c.push("-t", Settings.trTarget, input.text)
        proc.command = c; err = ""; proc.running = true
    }
    Timer { id: deb; interval: 300; onTriggered: tab.run() }
    Process {
        id: proc
        stdout: StdioCollector { onStreamFinished: tab.out = text.trim() }
        stderr: StdioCollector { onStreamFinished: tab.err = text.trim().split("\n")[0].slice(0, 160) }
        onExited: { if (tab.queued) { tab.queued = false; tab.run() } else if (tab.out === "" && tab.err === "") tab.err = "Não consegui traduzir. Veja a internet." }
    }
    Connections { target: Settings; function onTrTargetChanged() { deb.restart() } function onTrSourceChanged() { deb.restart() } function onTrEngineChanged() { deb.restart() } }

    // ---- idiomas ----
    Item {
        id: bar
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 34
        Rectangle {
            id: sb
            anchors { left: parent.left; right: sw.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
            height: 32; radius: 10; color: tab.pick === "src" ? Theme.cardHi : Theme.track; border.width: 1; border.color: Theme.border
            UiText { anchors.centerIn: parent; text: tab.nameOf(Settings.trSource); color: Theme.text; font.pixelSize: 13 }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tab.pick = tab.pick === "src" ? "" : "src" }
        }
        UiButton { id: sw; anchors.centerIn: parent; icon: "swap_horizontal"; kind: "ghost"; enabled: Settings.trSource !== "auto"; onClicked: tab.swap() }
        Rectangle {
            anchors { left: sw.right; leftMargin: 6; right: parent.right; verticalCenter: parent.verticalCenter }
            height: 32; radius: 10; color: tab.pick === "tgt" ? Theme.cardHi : Theme.track; border.width: 1; border.color: Theme.border
            UiText { anchors.centerIn: parent; text: tab.nameOf(Settings.trTarget); color: Theme.text; font.pixelSize: 13 }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tab.pick = tab.pick === "tgt" ? "" : "tgt" }
        }
    }

    // ---- entrada ----
    Rectangle {
        id: inBox
        anchors { left: parent.left; right: parent.right; top: bar.bottom; topMargin: 8 }
        height: (parent.height - bar.height - 8 - 8 - 34 - 8) / 2
        radius: 14; color: Theme.track; border.width: 1; border.color: input.activeFocus ? Theme.accent : Theme.border
        Flickable {
            anchors { fill: parent; margins: 8; bottomMargin: 34 }
            contentHeight: input.contentHeight; clip: true
            TextArea.flickable: TextArea {
                id: input
                wrapMode: TextArea.Wrap
                color: Theme.text; font.pixelSize: 15; font.family: Theme.font
                placeholderText: "Digite ou cole o texto"; placeholderTextColor: Theme.muted
                selectionColor: Theme.accent; selectedTextColor: Theme.accentText
                background: null
                onTextChanged: deb.restart()
            }
        }
        Row {
            anchors { right: parent.right; rightMargin: 6; bottom: parent.bottom; bottomMargin: 4 }
            spacing: 2
            UiButton { icon: "copy"; text: "Colar"; kind: "ghost"; implicitHeight: 28; onClicked: input.text = Quickshell.clipboardText ?? "" }
            UiButton { icon: "close"; kind: "ghost"; implicitHeight: 28; enabled: input.text !== ""; onClicked: { input.text = ""; tab.out = "" } }
        }
        UiText {
            anchors { left: parent.left; leftMargin: 12; bottom: parent.bottom; bottomMargin: 10 }
            text: input.text.length + " letras"; color: Theme.muted; font.pixelSize: 11
        }
    }

    // ---- saida ----
    Rectangle {
        id: outBox
        anchors { left: parent.left; right: parent.right; top: inBox.bottom; topMargin: 8; bottom: eng.top; bottomMargin: 8 }
        radius: 14; color: Theme.glc(Theme.card, 1.15); border.width: 1; border.color: Theme.border
        Flickable {
            anchors { fill: parent; margins: 12; bottomMargin: 34 }
            contentHeight: ot.implicitHeight; clip: true
            UiText {
                id: ot
                width: parent.width
                text: tab.err !== "" && tab.out === "" ? tab.err : tab.out
                color: tab.err !== "" && tab.out === "" ? Theme.danger : Theme.text
                wrapMode: Text.Wrap; font.pixelSize: 15
            }
        }
        LoadingBlob { visible: proc.running; running: visible; size: 22; anchors { left: parent.left; leftMargin: 10; bottom: parent.bottom; bottomMargin: 8 } }
        Row {
            anchors { right: parent.right; rightMargin: 6; bottom: parent.bottom; bottomMargin: 4 }
            spacing: 2
            UiButton { icon: "openNew"; text: "Google"; kind: "ghost"; implicitHeight: 28; enabled: input.text !== ""
                onClicked: Qt.openUrlExternally("https://translate.google.com/?sl=" + Settings.trSource + "&tl=" + Settings.trTarget + "&text=" + encodeURIComponent(input.text) + "&op=translate") }
            UiButton { icon: "copy"; text: "Copiar"; kind: "ghost"; implicitHeight: 28; enabled: tab.out !== ""; onClicked: Quickshell.clipboardText = tab.out }
        }
    }

    // ---- motor ----
    UiSeg {
        id: eng
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 34; fill: true
        options: [["google", "Google"], ["bing", "Bing"], ["yandex", "Yandex"], ["apertium", "Apertium"]]
        value: Settings.trEngine
        onPicked: v => Settings.trEngine = v
    }

    // ---- seletor de idioma (cobre as caixas) ----
    Rectangle {
        visible: tab.pick !== ""
        anchors { left: parent.left; right: parent.right; top: bar.bottom; topMargin: 6; bottom: parent.bottom }
        radius: 14; color: Theme.bg; border.width: 1; border.color: Theme.border
        Flickable {
            anchors { fill: parent; margins: 10 }
            contentHeight: fl.implicitHeight; clip: true
            Flow {
                id: fl
                width: parent.width; spacing: 6
                Repeater {
                    model: tab.langs.filter(l => tab.pick === "src" || l[0] !== "auto")
                    delegate: UiButton {
                        required property var modelData
                        text: modelData[1]
                        checked: (tab.pick === "src" ? Settings.trSource : Settings.trTarget) === modelData[0]
                        onClicked: { if (tab.pick === "src") Settings.trSource = modelData[0]; else Settings.trTarget = modelData[0]; tab.pick = "" }
                    }
                }
            }
        }
    }
}
