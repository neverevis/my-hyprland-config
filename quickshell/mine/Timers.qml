// Estado dos widgets de timer (por id do widget): sobrevive a recriacao do widget (preset, troca de tamanho).
// Modos: pomodoro (foco -> pausa, pausa longa a cada N ciclos), countdown, stopwatch. Ao terminar uma etapa:
// notificacao + som (alarm-clock-elapsed do tema freedesktop).
// st[id] guarda: running, startedAt (ms), base (ms ja contados antes de iniciar), phase (focus|pause|long), cycle
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property var st: ({})
    property real now: Date.now()
    Timer { interval: 250; repeat: true; running: Object.keys(root.st).some(k => root.st[k].running); onTriggered: { root.now = Date.now(); root.check() } }

    // timers que nao sao widgets da area de trabalho (ex.: o do Inicio) se registram aqui: id -> objeto com type e opts
    property var reg: ({})
    function register(id, w) { const r = Object.assign({}, reg); r[id] = w; reg = r }
    function lookup(id) { return DeskState.find(id) ?? reg[id] ?? null }
    function get(id) { return st[id] ?? { running: false, startedAt: 0, base: 0, phase: "focus", cycle: 1 } }
    function put(id, v) { const c = Object.assign({}, st); c[id] = v; st = c; saveT.restart() }
    // sobrevive a reinicios do shell: grava so quando o usuario muda algo (startedAt e hora de relogio, entao o tempo continua certo)
    Timer { id: saveT; interval: 500; onTriggered: stFile.setText(JSON.stringify(root.st)) }
    FileView {
        id: stFile
        path: Quickshell.env("HOME") + "/.cache/quickshell-mine/timers.json"
        printErrors: false
        onLoaded: { try { const d = JSON.parse(text()); if (d && typeof d === "object") root.st = d } catch (e) {} }
    }
    function elapsed(id) { const s = get(id); return s.base + (s.running ? now - s.startedAt : 0) }
    // duracao total da etapa atual (ms; 0 = cronometro)
    function total(w) {
        const o = k => DeskState.opt(w, k), s = get(w.id), m = o("mode")
        if (m === "stopwatch") return 0
        if (m === "countdown") return o("minutes") * 60000 + (s.extra ?? 0)
        return (s.phase === "focus" ? o("focus") : s.phase === "long" ? o("longPause") : o("pause")) * 60000
    }
    function start(id) { const s = Object.assign({}, get(id)); if (s.running) return; s.running = true; s.startedAt = Date.now(); now = s.startedAt; put(id, s) }
    function pause(id) { const s = Object.assign({}, get(id)); if (!s.running) return; s.base += Date.now() - s.startedAt; s.running = false; put(id, s) }
    function reset(id) { put(id, { running: false, startedAt: 0, base: 0, phase: "focus", cycle: 1 }) }
    // +N minutos na contagem regressiva (os chips +1m/+5m)
    function addMinutes(id, n) { const s = Object.assign({}, get(id)); s.extra = (s.extra ?? 0) + n * 60000; put(id, s) }
    function skip(id) { const w = lookup(id); if (w) advance(w, false) }
    function advance(w, ring) {
        const s = Object.assign({}, get(w.id)), m = DeskState.opt(w, "mode")
        if (ring && DeskState.opt(w, "notify")) {
            const msg = m === "countdown" ? "Tempo esgotado" : s.phase === "focus" ? "Hora da pausa" : "De volta ao foco"
            Quickshell.execDetached(["notify-send", "-a", "Timer", "-i", "alarm-clock", msg, m === "pomodoro" ? "Ciclo " + s.cycle : ""])
            Quickshell.execDetached(["pw-play", "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"])
        }
        if (m === "countdown") { put(w.id, { running: false, startedAt: 0, base: 0, phase: "focus", cycle: 1 }); return }
        if (s.phase === "focus") { s.phase = s.cycle % DeskState.opt(w, "cycles") === 0 ? "long" : "pause" }
        else { s.phase = "focus"; s.cycle += 1 }
        s.base = 0; s.startedAt = Date.now(); s.running = ring   // pomodoro: a proxima etapa ja comeca
        put(w.id, s)
    }
    function check() {
        for (const id in st) {
            const s = st[id]
            if (!s.running) continue
            const w = lookup(id)
            if (!w) continue
            const t = total(w)
            if (t > 0 && elapsed(id) >= t) advance(w, true)
        }
    }
}
