// Luz noturna (hyprsunset: tela mais quente) com horario automatico, e protecao contra clarao (shader de tela do
// Hyprland: quando a imagem inteira fica muito clara de repente - site branco, tela de carregamento - ela escurece um
// pouco, sem mexer nas telas escuras). Liga/desliga pelo Inicio, pelo launcher ou pela pagina Inicio.
// IPC: qs -c mine ipc call night toggle | on | off | flash
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    // ---- luz noturna ----
    property bool manual: false                 // ligada na mao (fora do horario)
    property bool suppressed: false             // desligada na mao dentro do horario (volta no dia seguinte)
    property date now: new Date()
    Timer { interval: 30000; repeat: true; running: true; onTriggered: root.now = new Date() }
    function mins(t) { const p = String(t).split(":"); return (+p[0] || 0) * 60 + (+p[1] || 0) }
    readonly property bool inSchedule: {
        const n = now.getHours() * 60 + now.getMinutes(), a = mins(Settings.nightFrom), b = mins(Settings.nightTo)
        return a <= b ? (n >= a && n < b) : (n >= a || n < b)
    }
    onInScheduleChanged: suppressed = false
    readonly property bool active: manual || (Settings.nightAuto && inSchedule && !suppressed)
    function toggle() {
        if (active) { manual = false; if (Settings.nightAuto && inSchedule) suppressed = true }
        else { suppressed = false; manual = true }
    }
    readonly property bool available: check.ok
    Process { id: check; running: true; command: ["sh", "-c", "command -v hyprsunset"]; property bool ok: false; onExited: code => ok = code === 0 }
    Process {
        id: sunset
        running: root.active && check.ok
        command: ["hyprsunset", "-t", String(Settings.nightTemp)]
    }
    onActiveChanged: if (!active) Quickshell.execDetached(["pkill", "-x", "hyprsunset"])
    // trocar a temperatura com ela ligada: reinicia o hyprsunset
    Connections { target: Settings; function onNightTempChanged() { if (sunset.running) { sunset.running = false; Qt.callLater(() => sunset.running = root.active && check.ok) } } }

    // ---- protecao contra clarao ----
    readonly property string shaderFile: Quickshell.env("HOME") + "/.cache/quickshell-mine/antiflash.glsl"
    FileView { id: shaderOut; path: root.shaderFile }
    function shaderSrc() {
        const thr = 0.55 - Settings.antiFlashStrength * 0.002   // forca 0..100: comeca a escurecer mais cedo e mais forte
        const k = 0.6 + Settings.antiFlashStrength * 0.012
        return "#version 300 es\nprecision highp float;\nin vec2 v_texcoord;\nuniform sampler2D tex;\nout vec4 fragColor;\n"
            + "void main() {\n    vec4 c = texture(tex, v_texcoord);\n    vec3 sum = vec3(0.0);\n"
            + "    for (int i = 0; i < 8; i++) for (int j = 0; j < 8; j++) {\n"
            + "        vec2 p = (vec2(float(i), float(j)) + 0.5 + 0.3 * vec2(fract(sin(float(i * 8 + j) * 12.9898) * 43758.5), fract(sin(float(i * 8 + j) * 78.233) * 43758.5)) - 0.15) / 8.0;\n"
            + "        sum += texture(tex, p).rgb;\n    }\n"
            + "    float b = dot(sum / 64.0, vec3(0.2126, 0.7152, 0.0722));\n"
            + "    float o = clamp((b - " + thr.toFixed(3) + ") * " + k.toFixed(3) + ", 0.0, 0.6);\n"
            + "    fragColor = vec4(mix(c.rgb, vec3(0.0), o), c.a);\n}\n"
    }
    function applyFlash() {
        if (Settings.antiFlash) {
            shaderOut.setText(shaderSrc())
            Quickshell.execDetached(["hyprctl", "eval", 'hl.config({ decoration = { screen_shader = "' + shaderFile + '" } })'])
        } else Quickshell.execDetached(["hyprctl", "eval", 'hl.config({ decoration = { screen_shader = "" } })'])
    }
    Connections { target: Settings; function onAntiFlashChanged() { root.applyFlash() } function onAntiFlashStrengthChanged() { if (Settings.antiFlash) flashT.restart() } }
    Timer { id: flashT; interval: 400; onTriggered: root.applyFlash() }
    Component.onCompleted: if (Settings.antiFlash) applyFlash()

    IpcHandler {
        target: "night"
        function toggle(): void { root.toggle() }
        function on(): void { root.suppressed = false; root.manual = true }
        function off(): void { root.manual = false; if (root.inSchedule) root.suppressed = true }
        function flash(): void { Settings.antiFlash = !Settings.antiFlash }
        function status(): string { return JSON.stringify({ active: root.active, schedule: root.inSchedule, hyprsunset: check.ok, flash: Settings.antiFlash }) }
    }
}
