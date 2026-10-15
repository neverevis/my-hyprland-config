// Passa as configuracoes de blur para o Hyprland:
//   - grava ~/.config/hypr/quickshell-blur.lua (lido no login, depois do hyprland-gui.lua)
//   - aplica ao vivo com "hyprctl eval" (valores do blur) ou "hyprctl reload" (regra de camada da moldura)
// O Hyprland so tem blur/noise GLOBAIS; por moldura so da para ligar/desligar o blur e escolher o limite de alfa.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string file: Quickshell.env("HOME") + "/.config/hypr/quickshell-blur.lua"

    function blurTable(): string {
        return "{ enabled = " + Settings.blurEnabled
            + ", size = " + Settings.blurSize
            + ", passes = " + Settings.blurPasses
            + ", noise = " + (Settings.blurNoise / 1000).toFixed(3)
            + ", contrast = " + (Settings.blurContrast / 100).toFixed(2)
            + ", brightness = " + (Settings.blurBrightness / 100).toFixed(2)
            + ", vibrancy = " + (Settings.blurVibrancy / 100).toFixed(2) + " }"
    }
    // blur da moldura e das janelas de vidro do shell (configuracoes e launcher); o launcher tambem sem animacao propria do Hyprland
    function ruleLine(): string {
        const tail = ", blur = " + Settings.shellBlur + ", ignore_alpha = " + (Settings.shellIgnoreAlpha / 100).toFixed(2) + " })"
        return ["mine-frame", "mine-settings", "mine-launcher"].map(n => 'hl.layer_rule({ match = { namespace = "' + n + '" }' + tail).join("\n")
            + '\nhl.layer_rule({ match = { namespace = "mine-launcher" }, no_anim = true })'
            + '\nhl.layer_rule({ match = { namespace = "mine-notifications" }, no_anim = true })'
    }
    // bordas das janelas com as cores do tema do wallpaper (so quando ligado)
    readonly property bool themeActive: Settings.themeOn && Settings.themeBorders
    function rgb(id: string): string { return "rgb(" + ThemeColors.hexOf(id).replace("#", "") + ")" }
    function themeLua(): string {
        return 'hl.config({ general = { col = { active_border = { colors = { "' + rgb("primary") + '", "' + rgb("secondary")
            + '" }, angle = 45 }, inactive_border = "' + rgb("outline") + '" } } })'
    }
    function content(): string {
        let t = "-- Gerado pelo Quickshell (pagina Blur da janela de configuracoes). Nao edite a mao.\n"
        if (Settings.blurManaged)
            t += "hl.config({ decoration = { blur = " + blurTable() + " } })\n"
        t += ruleLine() + "\n"
        if (themeActive) t += themeLua() + "\n"
        return t
    }

    // mudancas que exigem recarregar a config (regra de camada) x mudancas ao vivo
    readonly property string ruleSig: Settings.shellBlur + "/" + Settings.shellIgnoreAlpha + "/" + Settings.blurManaged   // desligar o controle tambem recarrega (volta aos valores do HyprMod)
    readonly property string blurSig: Settings.blurManaged + "/" + blurTable()
    property string lastRule: ""
    property bool ready: false

    readonly property string themeSig: themeActive + "/" + (themeActive ? themeLua() : "")
    property bool lastTheme: false
    onThemeSigChanged: if (ready) timer.restart()
    onRuleSigChanged: if (ready) timer.restart()
    onBlurSigChanged: if (ready) timer.restart()

    Component.onCompleted: {
        lastRule = ruleSig
        lastTheme = themeActive
        out.setText(content())
        ready = true
    }

    FileView { id: out; path: root.file }

    Process { id: runner }

    Timer {
        id: timer
        interval: 250
        onTriggered: {
            if (Wallpaper.busy) { restart(); return }   // espera a transicao do wallpaper (reconfigurar o Hyprland no meio engasga)
            out.setText(root.content())
            const themeOff = root.lastTheme && !root.themeActive   // desligou o tema: volta as cores do HyprMod/Hyprland
            root.lastTheme = root.themeActive
            if (root.ruleSig !== root.lastRule || themeOff) {
                root.lastRule = root.ruleSig
                runner.command = ["hyprctl", "reload"]
                runner.running = true
            } else if (root.themeActive) {
                runner.command = ["hyprctl", "eval", root.themeLua() + (Settings.blurManaged ? "; hl.config({ decoration = { blur = " + root.blurTable() + " } })" : "")]
                runner.running = true
            } else if (Settings.blurManaged) {
                runner.command = ["hyprctl", "eval", "hl.config({ decoration = { blur = " + root.blurTable() + " } })"]
                runner.running = true
            }
        }
    }
}
