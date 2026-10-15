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
    function ruleLine(): string {
        return 'hl.layer_rule({ match = { namespace = "mine-frame" }, blur = ' + Settings.shellBlur
            + ", ignore_alpha = " + (Settings.shellIgnoreAlpha / 100).toFixed(2) + " })"
    }
    function content(): string {
        let t = "-- Gerado pelo Quickshell (pagina Blur da janela de configuracoes). Nao edite a mao.\n"
        if (Settings.blurManaged)
            t += "hl.config({ decoration = { blur = " + blurTable() + " } })\n"
        t += ruleLine() + "\n"
        return t
    }

    // mudancas que exigem recarregar a config (regra de camada) x mudancas ao vivo
    readonly property string ruleSig: Settings.shellBlur + "/" + Settings.shellIgnoreAlpha + "/" + Settings.blurManaged   // desligar o controle tambem recarrega (volta aos valores do HyprMod)
    readonly property string blurSig: Settings.blurManaged + "/" + blurTable()
    property string lastRule: ""
    property bool ready: false

    onRuleSigChanged: if (ready) timer.restart()
    onBlurSigChanged: if (ready) timer.restart()

    Component.onCompleted: {
        lastRule = ruleSig
        out.setText(content())
        ready = true
    }

    FileView { id: out; path: root.file }

    Process { id: runner }

    Timer {
        id: timer
        interval: 250
        onTriggered: {
            out.setText(root.content())
            if (root.ruleSig !== root.lastRule) {
                root.lastRule = root.ruleSig
                runner.command = ["hyprctl", "reload"]
                runner.running = true
            } else if (Settings.blurManaged) {
                runner.command = ["hyprctl", "eval", "hl.config({ decoration = { blur = " + root.blurTable() + " } })"]
                runner.running = true
            }
        }
    }
}
