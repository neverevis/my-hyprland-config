// Equalizador e efeitos de audio pelo EasyEffects: ligar/desligar os efeitos (bypass global), escolher um preset
// e abrir o app para editar (os presets sao criados e salvos la).
import Quickshell
import Quickshell.Io
import QtQuick

Card {
    id: eq
    icon: "wave"
    title: "Equalizador (EasyEffects)"
    subtitle: !installed ? "Precisa do EasyEffects (sudo pacman -S easyeffects)." : !running ? "O EasyEffects não está rodando." : (bypassed ? "Efeitos desligados." : "Efeitos ligados" + (current ? " · " + current : "") + ".")
    property bool installed: true
    property bool running: false
    property bool bypassed: false
    property var presets: []
    property string current: ""
    function refresh() { st.running = false; st.running = true }
    Component.onCompleted: refresh()
    Process {
        id: st
        command: ["sh", "-c", 'command -v easyeffects >/dev/null || { echo NOEE; exit; }; pgrep -x easyeffects >/dev/null && echo RUN; easyeffects -b 3 2>/dev/null | tail -1; echo "--"; easyeffects -p 2>/dev/null; echo "--"; easyeffects -a output 2>/dev/null | tail -1']
        stdout: StdioCollector { onStreamFinished: {
            const t = text
            eq.installed = t.indexOf("NOEE") < 0
            eq.running = t.indexOf("RUN") >= 0
            const parts = t.split("--")
            eq.bypassed = /^\s*1\s*$/m.test(parts[0] || "")
            const out = (parts[1] || "").split("\n").find(l => /output/i.test(l)) || ""
            eq.presets = out.replace(/^[^:]*:/, "").split(",").map(x => x.trim()).filter(x => x)
            eq.current = (parts[2] || "").trim()
        } }
    }
    function run(args) { Quickshell.execDetached(["easyeffects"].concat(args)); later.restart() }
    Timer { id: later; interval: 900; onTriggered: eq.refresh() }

    Row {
        spacing: 8
        UiButton { visible: eq.installed && !eq.running; icon: "play"; text: "Iniciar em segundo plano"; kind: "accent"; onClicked: { Quickshell.execDetached(["easyeffects", "--service-mode", "-w"]); later.interval = 2500; later.restart() } }
        UiButton { visible: eq.running; icon: eq.bypassed ? "play" : "pause"; text: eq.bypassed ? "Ligar os efeitos" : "Desligar os efeitos"; kind: eq.bypassed ? "accent" : "ghost"; onClicked: eq.run(["-b", eq.bypassed ? "2" : "1"]) }
        UiButton { visible: eq.installed; icon: "tune"; text: "Abrir o EasyEffects"; kind: "ghost"; onClicked: Quickshell.execDetached(["easyeffects"]) }
        UiButton { icon: "refresh"; kind: "ghost"; onClicked: eq.refresh() }
    }
    UiLabel { visible: eq.running; text: "Presets" }
    UiText { visible: eq.running && !eq.presets.length; width: parent.width; wrapMode: Text.WordWrap; text: "Nenhum preset ainda: crie no EasyEffects (equalizador, compressor, reforço de graves...) e salve com um nome."; color: Theme.muted; font.pixelSize: 12 }
    Flow {
        visible: eq.running
        width: parent.width; spacing: 6
        Repeater {
            model: eq.presets
            delegate: UiButton { required property string modelData; text: modelData; kind: eq.current === modelData ? "accent" : "ghost"; onClicked: eq.run(["-l", modelData]) }
        }
    }
}
