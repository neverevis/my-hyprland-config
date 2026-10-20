// Botoes rapidos do painel Inicio (a lista em uso fica em Settings.homeToggles; escolha e ordem na pagina Inicio).
// "wifi" e "bt" sao desenhados pelo proprio Inicio (dependem dos dispositivos que ele acompanha); os outros vem daqui:
// id, rotulo, icone, sub() (texto embaixo), on() (aceso?), click().
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    // modo jogo: sem animacoes, blur e sombras no Hyprland (desligar recarrega a config)
    property bool gameMode: false
    function setGame(on) {
        gameMode = on
        if (on) Quickshell.execDetached(["hyprctl", "eval", "hl.config({ animations = { enabled = false }, decoration = { blur = { enabled = false }, shadow = { enabled = false }, rounding = 0 }, general = { gaps_in = 0, gaps_out = 0, border_size = 1, allow_tearing = true } })"])
        else Quickshell.execDetached(["hyprctl", "reload"])
    }

    // EasyEffects rodando? (so confere com o painel Inicio aberto)
    property bool eeRunning: false
    property bool eeInstalled: false
    Process { id: eeCheck; running: true; command: ["sh", "-c", "command -v easyeffects >/dev/null || exit 2; pgrep -x easyeffects >/dev/null"]; onExited: code => { root.eeInstalled = code !== 2; root.eeRunning = code === 0 } }
    Timer { interval: 4000; repeat: true; running: Settings.homeOpen; onTriggered: { eeCheck.running = false; eeCheck.running = true } }
    function eeToggle() {
        if (eeRunning) Quickshell.execDetached(["pkill", "-x", "easyeffects"])
        else Quickshell.execDetached(["easyeffects", "--hide-window", "--service-mode"])
        eeRunning = !eeRunning
        eeLater.restart()
    }
    Timer { id: eeLater; interval: 2500; onTriggered: { eeCheck.running = false; eeCheck.running = true } }

    // tudo o que os textos e estados dependem (o Inicio le isto dentro dos bindings para se atualizar)
    function deps() { return [Recorder.elapsed, Idle.paused, Settings.notifDnd, Settings.desktopOn, root.gameMode, Osd.micMuted, Osd.muted, Osd.volume,
        root.eeRunning, Vpn.connected, Vpn.busy, Vpn.profiles.length, Wallpaper.videoPaused, Wallpaper.current, NightLight.active, Settings.nightGamma, Settings.nightTemp] }

    // campos de cada botao: id, label, icon (iconNow() = icone que muda), sub(), on(), click(); opcionais:
    //   alt = clique direito / seta ("tab:<aba do Inicio>", "dialog:night" ou uma funcao), avail() = existe neste PC, tip() = dica
    readonly property var all: [
        { id: "wifi", label: "Wi-Fi", icon: "wifi", builtin: true, alt: "tab:net" },
        { id: "bt", label: "Bluetooth", icon: "bluetooth", builtin: true, alt: "tab:bt" },
        { id: "dnd", label: "Não perturbe", icon: "bellSleep", sub: () => Settings.notifDnd ? "Ligado" : "Desligado", on: () => Settings.notifDnd, click: () => Settings.notifDnd = !Settings.notifDnd },
        { id: "profile", label: "Energia", icon: "balance", builtin: true },
        { id: "dark", label: "Modo escuro", icon: "night", sub: () => Settings.themeMode === "auto" ? "Automático" : (Settings.themeModeEff === "dark" ? "Ligado" : "Desligado"), on: () => Settings.themeModeEff === "dark", click: () => Settings.themeMode = Settings.themeModeEff === "dark" ? "light" : "dark" },
        { id: "glass", label: "Vidro", icon: "glass", sub: () => Settings.glass ? Settings.glassOpacityEff + "% de opacidade" : "Desligado", on: () => Settings.glass, click: () => Settings.glass = !Settings.glass },
        { id: "caffeine", label: "Manter acordado", icon: "coffee", sub: () => Idle.paused ? "Sem bloqueio automático" : "Normal", on: () => Idle.paused, click: () => Idle.paused = !Idle.paused },
        { id: "vpn", label: "VPN", icon: "shield", iconNow: () => Vpn.connected ? "shieldLock" : "shield", sub: () => Vpn.connected ? Vpn.activeProfile.name : (Vpn.has ? (Vpn.selectedProfile ? Vpn.selectedProfile.name : "Desligada") : "Nenhum perfil"), on: () => Vpn.connected, click: () => { if (!Vpn.toggle()) Quickshell.execDetached(["qs", "-c", "mine", "ipc", "call", "home", "go", "vpn"]) }, alt: "tab:vpn" },
        { id: "mic", label: "Microfone", icon: "mic", sub: () => Osd.micMuted ? "Mudo" : "Ligado", on: () => !Osd.micMuted, click: () => { if (Osd.source && Osd.source.audio) Osd.source.audio.muted = !Osd.source.audio.muted }, alt: "tab:audio" },
        { id: "audio", label: "Som", icon: "volume", iconNow: () => Osd.muted ? "volumeOff" : (Osd.volume > 0.66 ? "volume" : (Osd.volume > 0.25 ? "volumeMed" : "volumeLow")), sub: () => Osd.muted ? "Mudo" : Math.round(Osd.volume * 100) + "%", on: () => !Osd.muted, click: () => { if (Osd.sink && Osd.sink.audio) Osd.sink.audio.muted = !Osd.sink.audio.muted }, alt: "tab:audio" },
        { id: "easyeffects", label: "EasyEffects", icon: "equalizer", sub: () => !root.eeInstalled ? "Não instalado" : (root.eeRunning ? "Ligado" : "Desligado"), on: () => root.eeRunning, click: () => root.eeToggle(), alt: () => Quickshell.execDetached(["easyeffects"]), avail: () => root.eeInstalled },
        { id: "livewall", label: "Wallpaper animado", icon: "wallpaper", iconNow: () => Wallpaper.videoPaused ? "play" : "pause", sub: () => !Wallpaper.isVideo(Wallpaper.current) ? "Sem vídeo agora" : (Wallpaper.videoPaused ? "Pausado" : "Tocando"), on: () => Wallpaper.isVideo(Wallpaper.current) && !Wallpaper.videoPaused, click: () => Wallpaper.videoPaused = !Wallpaper.videoPaused, avail: () => Wallpaper.isVideo(Wallpaper.current) },
        { id: "record", label: "Gravar tela", icon: "monitor", sub: () => Recorder.active ? "Gravando " + Recorder.elapsed : "Parado", on: () => Recorder.active, click: () => { Settings.homeOpen = false; Recorder.toggle(false) } },
        { id: "shot", label: "Captura", icon: "frame", sub: () => "Escolher área", on: () => false, click: () => { Settings.homeOpen = false; Actions.run("shot") } },
        { id: "picker", label: "Pegar cor", icon: "palette", sub: () => "Conta-gotas", on: () => false, click: () => { Settings.homeOpen = false; Actions.run("picker") } },
        { id: "widgets", label: "Widgets", icon: "dashboard", sub: () => Settings.desktopOn ? "Na área de trabalho" : "Escondidos", on: () => Settings.desktopOn, click: () => Settings.desktopOn = !Settings.desktopOn },
        { id: "game", label: "Modo jogo", icon: "gamepad", sub: () => root.gameMode ? "Sem efeitos do Hyprland" : "Desligado", on: () => root.gameMode, click: () => root.setGame(!root.gameMode) },
        { id: "wallpaper", label: "Wallpaper", icon: "wallpaper", sub: () => "Próximo", on: () => false, click: () => Wallpaper.step(1) },
        { id: "night", label: "Luz noturna", icon: "night", sub: () => !NightLight.available ? "Instale o hyprsunset" : NightLight.active ? Settings.nightTemp + " K" : (Settings.nightAuto ? Settings.nightFrom + "–" + Settings.nightTo : "Desligada"), on: () => NightLight.active, click: () => NightLight.toggle(), alt: "dialog:night", avail: () => NightLight.available },
        { id: "antiflash", label: "Contra clarão", icon: "sun", sub: () => Settings.antiFlash ? "Escurece telas muito claras" : "Desligado", on: () => Settings.antiFlash, click: () => Settings.antiFlash = !Settings.antiFlash, alt: "dialog:night" },
        { id: "overlay", label: "Painel de jogo", icon: "gamepad", sub: () => "Mira, notas, sistema", on: () => false, click: () => { Settings.homeOpen = false; Quickshell.execDetached(["qs", "-c", "mine", "ipc", "call", "overlay", "toggle"]) } },
        { id: "ocr", label: "Copiar texto", icon: "textBox", sub: () => "Da tela (OCR)", on: () => false, click: () => { Settings.homeOpen = false; Capture.start("ocr") } }
    ]
    function find(id) { return all.find(t => t.id === id) ?? null }
    // lista salva (ids ou { id, size }) -> [{ id, size }]; so os que existem. Tamanho 1 = so o icone, 2 = icone + nome + estado, 3 = largo
    function norm(list) {
        return Settings.list(list).map(e => typeof e === "string" ? { id: e, size: 2 } : { id: String(e.id), size: Math.max(1, Math.min(3, Math.round(e.size || 2))) }).filter(e => find(e.id))
    }
    // botoes em linhas: cada um ocupa "size" unidades e a linha fecha quando passa de "cols"
    function rows(list, cols) {
        const out = []; let cur = [], used = 0
        const compact = Settings.homeToggleStyle === "compact"   // estilo classico: so icones
        norm(list).forEach((e, i) => {
            if (compact) e.size = 1
            const w = Math.min(e.size, cols)
            if (used + w > cols && cur.length) { out.push(cur); cur = []; used = 0 }
            cur.push({ id: e.id, size: e.size, w: w, idx: i }); used += w
        })
        if (cur.length) out.push(cur)
        return out
    }
}
