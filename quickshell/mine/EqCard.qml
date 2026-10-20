// Equalizador e efeitos de audio pelo EasyEffects: ligar/desligar os efeitos (bypass global), escolher um preset,
// equalizador grafico de 10 bandas (preset proprio "mine-eq" via scripts/eq.py, com curvas prontas e proprias)
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
    Component.onCompleted: { refresh(); eqRun(["state"]) }
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

    // ---- equalizador de 10 bandas ----
    readonly property string eqScript: Qt.resolvedUrl("scripts/eq.py").toString().replace("file://", "")
    readonly property var freqs: ["32", "64", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
    readonly property var curves: [
        { n: "Plano", g: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] },
        { n: "Graves", g: [6, 5, 4, 2, 0, 0, 0, 0, 0, 0] },
        { n: "Agudos", g: [0, 0, 0, 0, 0, 1, 3, 5, 6, 6] },
        { n: "Vocal", g: [-2, -3, -2, 1, 4, 4, 3, 1, 0, -1] },
        { n: "Pop", g: [-1, 2, 4, 5, 3, 0, -1, -1, -1, -1] },
        { n: "Rock", g: [5, 4, 3, 1, -1, -1, 0, 2, 3, 4] },
        { n: "Jazz", g: [3, 2, 1, 2, -2, -2, 0, 1, 2, 3] },
        { n: "Clássica", g: [4, 3, 3, 2, -1, -1, 0, 2, 3, 4] }
    ]
    property var gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property int pre: 0
    property var custom: ({})
    property bool eqOn: false
    property string before: ""      // preset que estava carregado antes de mexer na curva
    function eqRead(t) {
        try {
            const d = JSON.parse(t)
            eq.gains = d.gains; eq.pre = Math.round(d.pre); eq.custom = d.custom || ({}); eq.eqOn = !!d.active
        } catch (e) {}
    }
    Process {
        id: eqProc
        stdout: StdioCollector { onStreamFinished: eq.eqRead(text) }
    }
    function eqRun(args) { eqProc.command = ["python3", eqScript].concat(args); eqProc.running = false; eqProc.running = true }
    function applyNow() {
        if (!eq.eqOn && eq.current !== "mine-eq") eq.before = eq.current
        eqRun(["apply"].concat(eq.gains.map(String), [String(eq.pre)]))
        later.interval = 900; later.restart()
    }
    Timer { id: eqDeb; interval: 350; onTriggered: eq.applyNow() }
    function setBand(i, v) {
        const g = Array.from(eq.gains); g[i] = v; eq.gains = g; eqDeb.restart()
    }
    function setCurve(g) { eq.gains = Array.from(g); eqDeb.restart() }
    property string newName: ""

    function run(args) { Quickshell.execDetached(["easyeffects"].concat(args)); later.restart() }
    Timer { id: later; interval: 900; onTriggered: eq.refresh() }

    Row {
        spacing: 8
        UiButton { visible: eq.installed && !eq.running; icon: "play"; text: "Iniciar em segundo plano"; kind: "accent"; onClicked: { Quickshell.execDetached(["easyeffects", "--service-mode", "-w"]); later.interval = 2500; later.restart() } }
        UiButton { visible: eq.running; icon: eq.bypassed ? "play" : "pause"; text: eq.bypassed ? "Ligar os efeitos" : "Desligar os efeitos"; kind: eq.bypassed ? "accent" : "ghost"; onClicked: eq.run(["-b", eq.bypassed ? "2" : "1"]) }
        UiButton { visible: eq.installed; icon: "tune"; text: "Abrir o EasyEffects"; kind: "ghost"; onClicked: Quickshell.execDetached(["easyeffects"]) }
        UiButton { visible: eq.running; icon: "close"; text: "Parar o serviço"; kind: "ghost"; onClicked: { Quickshell.execDetached(["pkill", "-x", "easyeffects"]); later.interval = 900; later.restart() } }
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

    // equalizador grafico
    UiLabel { visible: eq.running; text: "Equalizador de 10 bandas" }
    UiText { visible: eq.running; width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 12; text: eq.eqOn ? "A curva está ativa no preset \"mine-eq\". Ao mexer, ele substitui o preset carregado no EasyEffects." : "Mexer nas bandas carrega o preset \"mine-eq\" no EasyEffects (substitui o preset atual)." }
    Item {
        visible: eq.running
        width: parent.width; height: 190
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.max(2, Math.min(18, (parent.width - 10 * 34) / 9))
            Repeater {
                model: 10
                delegate: Item {
                    id: band
                    required property int index
                    width: 34; height: 190
                    readonly property real g: eq.gains[index] ?? 0
                    UiText { anchors.horizontalCenter: parent.horizontalCenter; text: (band.g > 0 ? "+" : "") + band.g; color: Theme.text; font.pixelSize: 10 }
                    Rectangle {
                        id: trk
                        x: 15; y: 18; width: 4; height: 140; radius: 2; color: Theme.track
                        Rectangle { x: 0; width: 4; radius: 2; color: Theme.accent
                            y: band.g >= 0 ? (12 - band.g) / 24 * trk.height : trk.height / 2
                            height: Math.abs(band.g) / 24 * trk.height }
                        Rectangle { x: -4; y: (12 - band.g) / 24 * trk.height - 6; width: 12; height: 12; radius: 6; color: Theme.accent }
                    }
                    MouseArea {
                        x: 0; y: 10; width: 34; height: 156
                        cursorShape: Qt.PointingHandCursor
                        function setFrom(my) { const t = Math.max(0, Math.min(1, (my - 8) / trk.height)); eq.setBand(band.index, Math.round((12 - t * 24) * 2) / 2) }
                        onPressed: m => setFrom(m.y)
                        onPositionChanged: m => { if (pressed) setFrom(m.y) }
                        onDoubleClicked: eq.setBand(band.index, 0)
                    }
                    UiText { anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom } text: eq.freqs[band.index]; color: Theme.muted; font.pixelSize: 10 }
                }
            }
        }
    }
    UiSlider { visible: eq.running; label: "Ganho geral (pré-amplificação)"; icon: "volume"; from: -12; to: 12; value: eq.pre; suffix: " dB"; onMoved: v => { eq.pre = v; eqDeb.restart() } }
    Flow {
        visible: eq.running
        width: parent.width; spacing: 6
        Repeater {
            model: eq.curves
            delegate: UiButton { required property var modelData; text: modelData.n; kind: "ghost"; onClicked: eq.setCurve(modelData.g) }
        }
        Repeater {
            model: Object.keys(eq.custom)
            delegate: UiButton { required property string modelData; icon: "sparkle"; text: modelData; kind: "ghost"; onClicked: eq.setCurve(eq.custom[modelData]) }
        }
    }
    Row {
        visible: eq.running
        spacing: 8
        UiField { id: nm; width: 180; placeholderText: "Nome da curva"; text: eq.newName; onTextEdited: eq.newName = text }
        UiButton { icon: "check"; text: "Salvar curva"; kind: "ghost"; enabled: eq.newName.trim() !== ""; onClicked: { eq.eqRun(["save", eq.newName.trim()]); eq.newName = "" } }
        UiButton { visible: eq.custom[eq.newName.trim()] !== undefined; icon: "trash"; text: "Apagar"; kind: "ghost"; onClicked: { eq.eqRun(["delete", eq.newName.trim()]); eq.newName = "" } }
    }
    Row {
        visible: eq.running && eq.eqOn
        spacing: 8
        UiButton { icon: "refresh"; text: eq.before !== "" && eq.before !== "mine-eq" ? "Voltar ao preset " + eq.before : "Zerar a curva"; kind: "ghost"
            onClicked: { if (eq.before !== "" && eq.before !== "mine-eq") { eq.eqRun(["restore", eq.before]); eq.eqOn = false } else eq.setCurve([0, 0, 0, 0, 0, 0, 0, 0, 0, 0]); eq.pre = 0; later.restart() } }
    }
}
