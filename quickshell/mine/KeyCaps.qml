// KeyCaps: mostra uma combinacao no formato do Hyprland ("SUPER + SHIFT + S") como teclas: [Super] [Shift] [S].
// combo vazio mostra "Sem tecla". dim: deixa apagado (atalho desligado ou substituido).
import QtQuick

Row {
    id: kc
    property string combo
    property bool dim: false
    property int capH: 24
    spacing: 4
    opacity: dim ? 0.45 : 1

    readonly property var names: ({
        SUPER: "Super", SUPER_L: "Super", SUPER_R: "Super", WIN: "Super", SHIFT: "Shift", CTRL: "Ctrl", CONTROL: "Ctrl", ALT: "Alt",
        Period: ".", Comma: ",", grave: "`", Equal: "=", Minus: "-", Space: "Espaço", Delete: "Del", BackSpace: "⌫", Backspace: "⌫",
        Print: "Print", TAB: "Tab", Tab: "Tab", Return: "Enter", ESCAPE: "Esc", Escape: "Esc", Prior: "PgUp", Next: "PgDn", Page_Up: "PgUp", Page_Down: "PgDn",
        Left: "←", Right: "→", Up: "↑", Down: "↓", Home: "Home", End: "End", Insert: "Ins",
        Slash: "/", Semicolon: ";", Apostrophe: "'", bracketleft: "[", bracketright: "]", backslash: "\\",
        mouse_up: "Scroll ↑", mouse_down: "Scroll ↓", XF86AudioPlay: "Play", XF86AudioPause: "Pause", XF86AudioNext: "Próxima", XF86AudioPrev: "Anterior",
        XF86AudioStop: "Stop", XF86AudioMute: "Mudo", XF86AudioRaiseVolume: "Vol +", XF86AudioLowerVolume: "Vol -",
        XF86MonBrightnessUp: "Brilho +", XF86MonBrightnessDown: "Brilho -", XF86AudioMicMute: "Mic"
    })
    function label(t) {
        if (names[t] !== undefined) return names[t]
        if (names[t.toUpperCase()] !== undefined) return names[t.toUpperCase()]
        if (t.startsWith("XF86")) return t.slice(4)
        return t.length === 1 ? t.toUpperCase() : t
    }
    readonly property var parts: combo === "" ? [] : combo.split("+").map(s => s.trim()).filter(s => s !== "")

    UiText { visible: kc.parts.length === 0; anchors.verticalCenter: parent.verticalCenter; text: "Sem tecla"; color: Theme.muted; font.pixelSize: 12 }
    Repeater {
        model: kc.parts
        delegate: Rectangle {
            required property string modelData
            height: kc.capH; width: Math.max(kc.capH, kt.implicitWidth + 14); radius: 7
            color: Theme.track; border.width: 1; border.color: Theme.border
            // base mais grossa: cara de tecla
            Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 4; rightMargin: 4 } height: 2; radius: 1; color: Theme.border; opacity: 0.9 }
            UiText { id: kt; anchors.centerIn: parent; anchors.verticalCenterOffset: -1; text: kc.label(parent.modelData); color: Theme.text; font.pixelSize: 11; font.weight: Font.DemiBold }
        }
    }
}
