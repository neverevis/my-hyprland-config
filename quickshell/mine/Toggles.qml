// Botoes rapidos do painel Inicio (a lista em uso fica em Settings.homeToggles; escolha e ordem na pagina Inicio).
// "wifi" e "bt" sao desenhados pelo proprio Inicio (dependem dos dispositivos que ele acompanha); os outros vem daqui:
// id, rotulo, icone, sub() (texto embaixo), on() (aceso?), click().
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root
    // modo jogo: sem animacoes, blur e sombras no Hyprland (desligar recarrega a config)
    property bool gameMode: false
    function setGame(on) {
        gameMode = on
        if (on) Quickshell.execDetached(["hyprctl", "eval", "hl.config({ animations = { enabled = false }, decoration = { blur = { enabled = false }, shadow = { enabled = false } } })"])
        else Quickshell.execDetached(["hyprctl", "reload"])
    }

    readonly property var all: [
        { id: "wifi", label: "Wi-Fi", icon: "wifi", builtin: true },
        { id: "bt", label: "Bluetooth", icon: "bluetooth", builtin: true },
        { id: "dnd", label: "Não perturbe", icon: "bellSleep", sub: () => Settings.notifDnd ? "Ligado" : "Desligado", on: () => Settings.notifDnd, click: () => Settings.notifDnd = !Settings.notifDnd },
        { id: "profile", label: "Energia", icon: "balance", builtin: true },
        { id: "dark", label: "Modo escuro", icon: "night", sub: () => Settings.themeMode === "auto" ? "Automático" : (Settings.themeModeEff === "dark" ? "Ligado" : "Desligado"), on: () => Settings.themeModeEff === "dark", click: () => Settings.themeMode = Settings.themeModeEff === "dark" ? "light" : "dark" },
        { id: "glass", label: "Vidro", icon: "glass", sub: () => Settings.glass ? Settings.glassOpacityEff + "% de opacidade" : "Desligado", on: () => Settings.glass, click: () => Settings.glass = !Settings.glass },
        { id: "caffeine", label: "Manter acordado", icon: "coffee", sub: () => Idle.paused ? "Sem bloqueio automático" : "Normal", on: () => Idle.paused, click: () => Idle.paused = !Idle.paused },
        { id: "mic", label: "Microfone", icon: "mic", sub: () => Osd.micMuted ? "Mudo" : "Ligado", on: () => !Osd.micMuted, click: () => { if (Osd.source && Osd.source.audio) Osd.source.audio.muted = !Osd.source.audio.muted } },
        { id: "record", label: "Gravar tela", icon: "monitor", sub: () => Recorder.active ? "Gravando " + Recorder.elapsed : "Parado", on: () => Recorder.active, click: () => { Settings.homeOpen = false; Recorder.toggle(false) } },
        { id: "shot", label: "Captura", icon: "frame", sub: () => "Escolher área", on: () => false, click: () => { Settings.homeOpen = false; Actions.run("shot") } },
        { id: "picker", label: "Pegar cor", icon: "palette", sub: () => "Conta-gotas", on: () => false, click: () => { Settings.homeOpen = false; Actions.run("picker") } },
        { id: "widgets", label: "Widgets", icon: "dashboard", sub: () => Settings.desktopOn ? "Na área de trabalho" : "Escondidos", on: () => Settings.desktopOn, click: () => Settings.desktopOn = !Settings.desktopOn },
        { id: "game", label: "Modo jogo", icon: "gamepad", sub: () => root.gameMode ? "Sem efeitos do Hyprland" : "Desligado", on: () => root.gameMode, click: () => root.setGame(!root.gameMode) },
        { id: "wallpaper", label: "Wallpaper", icon: "wallpaper", sub: () => "Próximo", on: () => false, click: () => Wallpaper.step(1) },
        { id: "night", label: "Luz noturna", icon: "night", sub: () => !NightLight.available ? "Instale o hyprsunset" : NightLight.active ? Settings.nightTemp + " K" : (Settings.nightAuto ? Settings.nightFrom + "–" + Settings.nightTo : "Desligada"), on: () => NightLight.active, click: () => NightLight.toggle() },
        { id: "antiflash", label: "Contra clarão", icon: "sun", sub: () => Settings.antiFlash ? "Escurece telas muito claras" : "Desligado", on: () => Settings.antiFlash, click: () => Settings.antiFlash = !Settings.antiFlash },
        { id: "overlay", label: "Painel de jogo", icon: "gamepad", sub: () => "Mira, notas, sistema", on: () => false, click: () => { Settings.homeOpen = false; Quickshell.execDetached(["qs", "-c", "mine", "ipc", "call", "overlay", "toggle"]) } },
        { id: "ocr", label: "Copiar texto", icon: "textBox", sub: () => "Da tela (OCR)", on: () => false, click: () => { Settings.homeOpen = false; Capture.start("ocr") } }
    ]
    function find(id) { return all.find(t => t.id === id) ?? null }
}
