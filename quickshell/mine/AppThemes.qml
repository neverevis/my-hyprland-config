// Exporta o tema do wallpaper para outros aplicativos (hoje: kitty).
//   kitty: grava ~/.config/kitty/themes/quickshell.conf (incluido no kitty.conf) e manda SIGUSR1 para recarregar as janelas abertas.
// Desligado (tema ou kitty): o arquivo fica so com um comentario e o kitty volta as cores de antes.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property bool ready: true
    readonly property string kittyFile: Quickshell.env("HOME") + "/.config/kitty/themes/quickshell.conf"
    readonly property bool kittyOn: Settings.themeOn && Settings.themeKitty && ThemeColors.m.primary !== undefined

    function kittyConf(): string {
        const m = ThemeColors.m
        let t = "# Gerado pelo Quickshell (tema do wallpaper). Nao edite a mao.\n"
        if (!kittyOn) return t
        t += "foreground " + m.onSurface + "\n"
        t += "background " + m.background + "\n"
        t += "selection_foreground " + m.onPrimaryContainer + "\n"
        t += "selection_background " + m.primaryContainer + "\n"
        t += "cursor " + m.primary + "\n"
        t += "cursor_text_color " + m.onPrimary + "\n"
        t += "url_color " + m.primary + "\n"
        t += "active_border_color " + m.primary + "\n"
        t += "inactive_border_color " + m.outlineVariant + "\n"
        t += "active_tab_foreground " + m.onPrimary + "\n"
        t += "active_tab_background " + m.primary + "\n"
        t += "inactive_tab_foreground " + m.onSurfaceVariant + "\n"
        t += "inactive_tab_background " + m.surfaceContainer + "\n"
        t += "tab_bar_background " + m.surfaceContainerLowest + "\n"
        for (let i = 0; i < 16; i++) if (m["term" + i]) t += "color" + i + " " + m["term" + i] + "\n"
        return t
    }

    readonly property string sig: kittyOn + "/" + (kittyOn ? kittyConf() : "")
    onSigChanged: timer.restart()
    FileView { id: out; path: root.kittyFile }
    Process { id: reload; command: ["pkill", "-USR1", "-x", "kitty"] }
    Timer {
        id: timer
        interval: 400
        onTriggered: { out.setText(root.kittyConf()); reload.running = false; reload.running = true }
    }
}
