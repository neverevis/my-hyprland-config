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
        return ["mine-frame", "mine-settings", "mine-launcher", "mine-launcher-docked"].map(n => 'hl.layer_rule({ match = { namespace = "' + n + '" }' + tail).join("\n")
            + '\nhl.layer_rule({ match = { namespace = "mine-launcher-docked" }, no_anim = true })'
            + '\nhl.layer_rule({ match = { namespace = "mine-notifications" }, no_anim = true })'
            + '\nhl.layer_rule({ match = { namespace = "mine-settings" }, no_anim = true })'
            + '\nhl.layer_rule({ match = { namespace = "mine-power" }, blur = true, ignore_alpha = 0.0 })'
            + '\nhl.layer_rule({ match = { namespace = "mine-power" }, no_anim = true })'
            + '\nhl.layer_rule({ match = { namespace = "mine-lock-preview" }, no_anim = true })'
            + '\nhl.layer_rule({ match = { namespace = "mine-home" }, no_anim = true })'
            + '\nhl.layer_rule({ match = { namespace = "mine-desktop" }, blur = true, ignore_alpha = 0.3 })'
            + '\nhl.layer_rule({ match = { namespace = "mine-desktop" }, no_anim = true })'
            + '\nhl.layer_rule({ match = { namespace = "mine-wallpaper-picker" }, no_anim = true })'
            + '\nhl.layer_rule({ match = { namespace = "mine-osd" }, blur = true, ignore_alpha = 0.3 })'
            + '\nhl.layer_rule({ match = { namespace = "mine-osd" }, no_anim = true })'
            + floatRules()
    }
    // paineis soltos (fora da moldura) tem fundo proprio: ganham o blur do Hyprland so nesse modo
    function floatRules(): string {
        const r = []
        if (!Settings.homeDocked) r.push("mine-home")
        if (!Settings.wpPickerDocked) r.push("mine-wallpaper-picker")
        if (!Settings.notifDocked) r.push("mine-notifications")
        return r.map(n => '\nhl.layer_rule({ match = { namespace = "' + n + '" }, blur = true, ignore_alpha = 0.3 })').join("")
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
        const anim = Motion.hyprLua()
        if (anim !== "") t += "-- animacoes das janelas (pagina Animacoes: o Hyprland segue o shell)\n" + anim + "\n"
        return t
    }

    // mudancas que exigem recarregar a config (regra de camada) x mudancas ao vivo
    readonly property string ruleSig: Settings.shellBlur + "/" + Settings.shellIgnoreAlpha + "/" + Settings.blurManaged + "/" + floatRules()   // desligar o controle tambem recarrega (volta aos valores do HyprMod)
    readonly property string blurSig: Settings.blurManaged + "/" + blurTable()
    property string lastRule: ""
    property bool ready: false

    // animacoes: aplicadas ao vivo (hyprctl eval); desligar recarrega a config (volta ao hyprland/animations.lua)
    readonly property string animSig: Motion.hyprLua()
    property bool lastAnim: false
    onAnimSigChanged: if (ready) timer.restart()

    readonly property string themeSig: themeActive + "/" + (themeActive ? themeLua() : "")
    property bool lastTheme: false
    onThemeSigChanged: if (ready) timer.restart()
    onRuleSigChanged: if (ready) timer.restart()
    onBlurSigChanged: if (ready) timer.restart()

    Component.onCompleted: {
        lastRule = ruleSig
        lastTheme = themeActive
        lastAnim = animSig !== ""
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
            const animOff = root.lastAnim && root.animSig === ""
            root.lastAnim = root.animSig !== ""
            if (root.ruleSig !== root.lastRule || themeOff || animOff) {
                root.lastRule = root.ruleSig
                runner.command = ["hyprctl", "reload"]
                runner.running = true
            } else {
                const parts = []
                if (root.themeActive) parts.push(root.themeLua())
                if (Settings.blurManaged) parts.push("hl.config({ decoration = { blur = " + root.blurTable() + " } })")
                if (root.animSig !== "") parts.push(root.animSig)
                if (parts.length) {
                    runner.command = ["hyprctl", "eval", parts.join("\n")]
                    runner.running = true
                }
            }
        }
    }
}
