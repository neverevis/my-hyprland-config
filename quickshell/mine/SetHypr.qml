// SetHypr: linhas do kit (SetSlider, SetRow, SetChoice) geradas a partir das opcoes do HyprConf (grupo inteiro ou lista de chaves).
// Cada linha le o valor atual do Hyprland e grava como override (HyprConf.set); a busca da janela indexa as linhas normalmente.
// changed = quantas deste conjunto foram trocadas; restore() volta todas ao que esta nos arquivos do Hyprland.
// Exemplo:  SetHypr { group: "layout" }   ou   SetHypr { keys: ["general:gaps_in", "general:gaps_out"]; sub: true }
import QtQuick

Column {
    id: h
    property string group: ""
    property var keys: []
    property bool sub: false
    // fracoes (opacidade etc.) trabalham em % no controle e em 0..1 no Hyprland
    readonly property var opts: keys.length ? keys.map(k => HyprConf.opt(k)).filter(o => o) : HyprConf.options.filter(o => o.group === group)
    readonly property int changed: opts.filter(o => HyprConf.overridden(o.key)).length
    function restore() { for (const o of opts) HyprConf.reset(o.key) }
    readonly property var iconOf: ({
        "general:gaps_in": "view_grid", "general:gaps_out": "fullscreen", "general:gaps_workspaces": "swap_horizontal", "general:border_size": "frame",
        "decoration:rounding": "rounded", "decoration:rounding_power": "curve", "decoration:active_opacity": "opacity", "decoration:inactive_opacity": "opacity",
        "decoration:dim_inactive": "night", "decoration:dim_strength": "night", "decoration:shadow:enabled": "layers", "decoration:shadow:range": "resize",
        "decoration:shadow:render_power": "blur", "general:resize_on_border": "resize", "general:extend_border_grab_area": "cursorMove",
        "general:layout": "view_column", "input:kb_layout": "keyboard", "input:kb_variant": "keyboard", "input:kb_options": "swap_horizontal",
        "input:numlock_by_default": "numeric", "input:repeat_delay": "timer", "input:repeat_rate": "speed", "input:sensitivity": "speed",
        "input:accel_profile": "gauge", "input:follow_mouse": "tap", "input:natural_scroll": "swap_vertical", "input:left_handed": "mouse",
        "cursor:inactive_timeout": "eyeOff", "cursor:hide_on_key_press": "eyeOff", "misc:vrr": "monitor", "animations:enabled": "animation"
    })
    width: parent ? parent.width : 400

    Repeater {
        model: h.opts
        delegate: Loader {
            id: ld
            required property var modelData
            required property int index
            readonly property var o: modelData
            readonly property bool scaled: !!(o.pct || o.float)
            visible: !o.when || !!HyprConf.value(o.when)
            width: parent.width
            sourceComponent: o.type === "slider" ? cSlider : o.type === "switch" ? cSwitch : o.type === "seg" ? cSeg : cText
        }
    }

    Component {
        id: cSlider
        SetSlider {
            readonly property var o: parent.o
            readonly property bool pct: !!o.pct
            icon: h.sub ? "" : (h.iconOf[o.key] ?? "tune")
            sub: h.sub; divider: parent.index > 0
            label: o.label
            from: pct ? o.from * 100 : o.from; to: pct ? o.to * 100 : o.to
            step: pct ? 1 : (o.step ?? 1)
            unit: pct ? " %" : (o.suffix ?? "")
            value: { const v = HyprConf.value(o.key); return v === undefined ? from : (pct ? Math.round(v * 100) : v) }
            onMoved: v => HyprConf.set(o.key, pct ? v / 100 : v)
        }
    }
    Component {
        id: cSwitch
        SetRow {
            readonly property var o: parent.o
            icon: h.sub ? "" : (h.iconOf[o.key] ?? "tune")
            sub: h.sub; divider: parent.index > 0
            label: o.label
            checked: !!HyprConf.value(o.key)
            onToggled: on => HyprConf.set(o.key, on)
        }
    }
    Component {
        id: cSeg
        SetChoice {
            readonly property var o: parent.o
            icon: h.sub ? "" : (h.iconOf[o.key] ?? "tune")
            sub: h.sub; divider: parent.index > 0
            label: o.label
            options: o.options
            value: HyprConf.value(o.key)
            onPicked: v => HyprConf.set(o.key, v)
        }
    }
    Component {
        id: cText
        SetRow {
            readonly property var o: parent.o
            icon: h.sub ? "" : (h.iconOf[o.key] ?? "tune")
            sub: h.sub; divider: parent.index > 0
            label: o.label
            UiField { width: 180; text: String(HyprConf.value(o.key) ?? ""); onEditingFinished: HyprConf.set(o.key, text.trim()) }
        }
    }
}
