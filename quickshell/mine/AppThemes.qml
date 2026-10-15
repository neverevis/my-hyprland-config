// Exporta o tema do wallpaper para outros aplicativos: kitty, GTK e Brave.
//   kitty: grava ~/.config/kitty/themes/quickshell.conf (incluido no kitty.conf) e manda SIGUSR1 para recarregar as janelas abertas.
//   GTK: grava quickshell.css em ~/.config/gtk-3.0 e gtk-4.0 (importado pelo gtk.css) e ajusta o esquema claro/escuro.
//   Brave: grava a cor-semente na politica gerenciada (/etc/brave/policies/managed/caelestia.json, que e seu); o Brave aplica ao vivo.
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

    readonly property string home: Quickshell.env("HOME")
    readonly property bool gtkOn: Settings.themeOn && Settings.themeGtk && ThemeColors.m.primary !== undefined
    readonly property bool braveOn: Settings.themeOn && Settings.themeBrave && ThemeColors.m.primary !== undefined
    readonly property string bravePolicy: "/etc/brave/policies/managed/caelestia.json"

    function gtkCss(): string {
        const m = ThemeColors.m
        let t = "/* Gerado pelo Quickshell (tema do wallpaper). Nao edite a mao. */\n"
        if (!gtkOn) return t
        const d = (n, c) => "@define-color " + n + " " + c + ";\n"
        t += d("accent_color", m.primary) + d("accent_bg_color", m.primary) + d("accent_fg_color", m.onPrimary)
        t += d("destructive_color", m.error) + d("destructive_bg_color", m.error) + d("destructive_fg_color", m.onError)
        t += d("error_color", m.error) + d("error_bg_color", m.error) + d("error_fg_color", m.onError)
        t += d("window_bg_color", m.surface) + d("window_fg_color", m.onSurface)
        t += d("view_bg_color", m.surface) + d("view_fg_color", m.onSurface)
        t += d("headerbar_bg_color", m.surfaceContainer) + d("headerbar_fg_color", m.onSurface)
        t += d("headerbar_border_color", m.outlineVariant) + d("headerbar_backdrop_color", m.surface)
        t += d("card_bg_color", m.surfaceContainer) + d("card_fg_color", m.onSurface)
        t += d("dialog_bg_color", m.surfaceContainerHigh) + d("dialog_fg_color", m.onSurface)
        t += d("popover_bg_color", m.surfaceContainerHigh) + d("popover_fg_color", m.onSurface)
        t += d("sidebar_bg_color", m.surfaceContainerLow) + d("sidebar_fg_color", m.onSurface)
        t += d("sidebar_backdrop_color", m.surface) + d("sidebar_border_color", m.outlineVariant)
        t += d("secondary_sidebar_bg_color", m.surface) + d("secondary_sidebar_fg_color", m.onSurface)
        t += d("theme_selected_bg_color", m.primary) + d("theme_selected_fg_color", m.onPrimary)
        t += d("theme_bg_color", m.surface) + d("theme_fg_color", m.onSurface)
        t += d("theme_base_color", m.surface) + d("theme_text_color", m.onSurface)
        return t
    }
    function braveJson(): string {
        return JSON.stringify({ BrowserThemeColor: ThemeColors.m._source ?? ThemeColors.m.primary, BrowserColorScheme: Settings.themeModeEff === "light" ? "light" : "dark" })
    }

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
    readonly property string gtkSig: gtkOn + "/" + (gtkOn ? gtkCss() : "") + Settings.themeModeEff
    readonly property string braveSig: braveOn + "/" + (braveOn ? braveJson() : "")
    onSigChanged: timer.restart()
    onGtkSigChanged: gtkTimer.restart()
    onBraveSigChanged: braveTimer.restart()
    FileView { id: out; path: root.kittyFile }
    Process { id: reload; command: ["pkill", "-USR1", "-x", "kitty"] }
    Timer {
        id: timer
        interval: 400
        onTriggered: {
            if (Wallpaper.busy) { restart(); return }   // espera a transicao do wallpaper acabar (o recarregamento dos apps engasga a animacao)
            out.setText(root.kittyConf()); reload.running = false; reload.running = true
        }
    }

    FileView { id: gtk3; path: root.home + "/.config/gtk-3.0/quickshell.css" }
    FileView { id: gtk4; path: root.home + "/.config/gtk-4.0/quickshell.css" }
    Process { id: scheme }
    Timer {
        id: gtkTimer
        interval: 400
        property string lastScheme: ""
        onTriggered: {
            if (Wallpaper.busy) { restart(); return }
            const css = root.gtkCss()
            gtk3.setText(css); gtk4.setText(css)
            const sc = Settings.themeModeEff === "light" ? "prefer-light" : "prefer-dark"
            if (root.gtkOn && sc !== lastScheme) {   // so quando muda: avisar a troca faz todos os apps GTK/Qt recarregarem o tema
                lastScheme = sc
                scheme.command = ["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", Settings.themeModeEff === "light" ? "prefer-light" : "prefer-dark"]
                scheme.running = false; scheme.running = true
            }
        }
    }

    Process { id: brave }   // grava no lugar (o arquivo e seu, mas a pasta e do root: setText cria arquivo temporario e falharia)
    Timer {
        id: braveTimer
        interval: 150
        onTriggered: {
            if (Wallpaper.busy) { restart(); return }
            if (!root.braveOn) return
            // o Brave (Chromium) so aplica uma politica alterada depois de 5 s sem novas mudancas no arquivo: o atraso e dele
            brave.command = ["sh", "-c", "printf '%s' \"$1\" > \"$2\"", "sh", root.braveJson(), root.bravePolicy]
            brave.running = false; brave.running = true
        }
    }
}
