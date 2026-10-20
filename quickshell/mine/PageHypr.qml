// Pagina "Hyprland": janelas (espacos, borda, cantos, opacidade), sombra e foco, layout, teclado, mouse, sistema,
// monitor (resolucao e escala, com volta automatica), apps ao iniciar e a lista de atalhos. So o que voce muda vira
// override (HyprConf.qml); o resto continua vindo dos seus arquivos do Hyprland.
import Quickshell
import Quickshell.Io
import QtQuick

Column {
    id: page
    spacing: 14
    Component.onCompleted: HyprConf.refresh()

    function formSchema(gid) {
        return HyprConf.options.filter(o => o.group === gid).map(o => {
            const d = Object.assign({}, o)
            // fracoes (opacidade, velocidade do mouse): o controle trabalha em inteiros, entao vai em % (x100)
            if (o.pct || o.float) { d.from = o.from * 100; d.to = o.to * 100; d.step = o.float ? Math.max(1, (o.step ?? 0.01) * 100) : 1; d.suffix = " %" }
            if (o.type === "text") d.enterOnly = true
            return d
        })
    }
    function count(gid) { return HyprConf.options.filter(o => o.group === gid && HyprConf.overridden(o.key)).length }

    Card {
        icon: "window"
        title: "Hyprland"
        subtitle: "As mudanças valem na hora e ficam salvas (num arquivo do shell que o Hyprland lê por último). \"Restaurar\" volta ao que está nos seus arquivos do Hyprland."
        Row {
            spacing: 8
            UiButton { icon: "refresh"; text: "Ler os valores de novo"; kind: "ghost"; onClicked: HyprConf.refresh() }
            UiButton { icon: "restore"; text: "Restaurar tudo"; kind: "ghost"; visible: Object.keys(HyprConf.cfg).length > 0 || !!(Settings.hyprMonitor || {}).output; onClicked: { HyprConf.resetAll(); refreshT.restart() } }
            UiText { anchors.verticalCenter: parent.verticalCenter; text: Object.keys(HyprConf.cfg).length + " opção(ões) trocada(s)"; color: Theme.muted; font.pixelSize: 12 }
        }
    }
    Timer { id: refreshT; interval: 900; onTriggered: HyprConf.refresh() }

    Repeater {
        model: HyprConf.groups.filter(g => g.id !== "system")
        delegate: Card {
            id: grpCard
            required property var modelData
            icon: modelData.icon
            title: modelData.label
            subtitle: page.count(modelData.id) ? page.count(modelData.id) + " trocada(s) aqui" : ""
            OptionsForm {
                width: parent.width
                schema: page.formSchema(grpCard.modelData.id)
                get: k => { const o = HyprConf.opt(k), v = HyprConf.value(k); return o && (o.pct || o.float) && v !== undefined ? Math.round(v * 100) : v }
                set: (k, v) => { const o = HyprConf.opt(k); HyprConf.set(k, o && (o.pct || o.float) ? v / 100 : v) }
                isShown: d => !d.when || !!HyprConf.value(d.when)
            }
            UiButton { visible: page.count(grpCard.modelData.id) > 0; icon: "restore"; text: "Restaurar " + grpCard.modelData.label.toLowerCase(); kind: "ghost"
                onClicked: { for (const o of HyprConf.options) if (o.group === grpCard.modelData.id) HyprConf.reset(o.key); refreshT.restart() } }
        }
    }

    // ---- monitor: troca e pergunta se ficou bom (volta sozinha em 15 s) ----
    Card {
        id: monCard
        icon: "monitor"
        title: "Monitor"
        subtitle: "Resolução, taxa de atualização e escala. Se a tela ficar estranha, ela volta sozinha em 15 segundos."
        readonly property var mon: HyprConf.monitors[0] ?? null
        property var before: null
        property int secsLeft: 0
        Timer { id: confirmT; interval: 1000; repeat: true; running: monCard.secsLeft > 0; onTriggered: { monCard.secsLeft--; if (monCard.secsLeft === 0) monCard.revert() } }
        function apply(patch) {
            if (!mon) return
            before = JSON.parse(JSON.stringify(Settings.hyprMonitor || {}))
            Settings.hyprMonitor = Object.assign({ output: mon.name, mode: mon.mode, scale: mon.scale }, Settings.hyprMonitor || {}, patch)
            secsLeft = 15
            refreshT.restart()
        }
        function revert() { secsLeft = 0; Settings.hyprMonitor = before || ({}); before = null; refreshT.restart() }
        Rectangle {
            visible: monCard.secsLeft > 0
            width: parent.width; height: 52; radius: 14
            color: Theme.tint(0.14); border.width: 1; border.color: Theme.accent
            UiText { x: 16; anchors.verticalCenter: parent.verticalCenter; text: "Ficou bom? Volta em " + monCard.secsLeft + " s."; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
            Row {
                anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                spacing: 6
                UiButton { icon: "check"; text: "Manter"; kind: "accent"; onClicked: { monCard.secsLeft = 0; monCard.before = null } }
                UiButton { icon: "restore"; text: "Voltar"; kind: "ghost"; onClicked: monCard.revert() }
            }
        }
        UiText { visible: !!monCard.mon; text: monCard.mon ? monCard.mon.name + "  ·  " + monCard.mon.mode + "  ·  escala " + monCard.mon.scale : ""; color: Theme.muted; font.pixelSize: 12 }
        UiLabel { text: "Resolução e taxa" }
        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                // uma por resolucao/taxa arredondada (sem as quase iguais)
                model: { const seen = {}, out = []; for (const m of (monCard.mon ? monCard.mon.modes : [])) { const k = m.replace(/\.\d+Hz$/, ""); if (!seen[k]) { seen[k] = 1; out.push(m) } } return out.slice(0, 16) }
                delegate: UiButton {
                    required property string modelData
                    text: modelData.replace(/(\d+)\.\d+Hz$/, "$1 Hz").replace("@", "  ")
                    kind: monCard.mon && monCard.mon.mode === modelData ? "accent" : "ghost"
                    onClicked: monCard.apply({ mode: modelData })
                }
            }
        }
        UiLabel { text: "Escala" }
        UiSeg {
            options: [[1, "100%"], [1.25, "125%"], [1.5, "150%"], [1.75, "175%"], [2, "200%"]]
            value: monCard.mon ? monCard.mon.scale : 1
            onPicked: v => monCard.apply({ scale: v })
        }
        UiLabel { text: "Orientação" }
        UiSeg {
            options: [[0, "Normal"], [1, "90°"], [2, "180°"], [3, "270°"]]
            value: monCard.mon ? (Settings.hyprMonitor && Settings.hyprMonitor.transform !== undefined ? Settings.hyprMonitor.transform : monCard.mon.transform) : 0
            onPicked: v => monCard.apply({ transform: v })
        }
    }

    // ---- apps ao iniciar ----
    Card {
        icon: "rocket"
        title: "Apps ao iniciar"
        subtitle: "Comandos que o Hyprland roda ao entrar na sessão (além dos que já estão nos seus arquivos)."
        Repeater {
            model: Settings.list(Settings.hyprAutostart)
            delegate: Rectangle {
                required property string modelData
                required property int index
                width: parent.width; height: 40; radius: 10; color: Theme.track
                UiText { x: 12; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 60; elide: Text.ElideRight; text: modelData; color: Theme.text; font.pixelSize: 12; font.family: Theme.mono }
                UiButton { anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter } icon: "trash"; kind: "danger"
                    onClicked: { const l = Settings.list(Settings.hyprAutostart); l.splice(index, 1); Settings.hyprAutostart = l } }
            }
        }
        Row {
            spacing: 8
            UiField { id: asF; width: 420; placeholderText: "Comando (ex.: discord --start-minimized)"; onAccepted: asB.clicked() }
            UiButton { id: asB; icon: "plus"; text: "Adicionar"; onClicked: { const c = asF.text.trim(); if (!c) return; Settings.hyprAutostart = (Settings.list(Settings.hyprAutostart)).concat([c]); asF.text = "" } }
        }
    }

    // ---- sistema ----
    Card {
        icon: "cog"
        title: "Sistema"
        subtitle: page.count("system") ? page.count("system") + " trocada(s) aqui" : ""
        OptionsForm {
            width: parent.width
            schema: page.formSchema("system")
            get: k => HyprConf.value(k)
            set: (k, v) => HyprConf.set(k, v)
        }
    }

    // ---- atalhos ----
    Card {
        id: kbCard
        icon: "keyboard"
        title: "Atalhos"
        subtitle: "Lidos dos seus arquivos do Hyprland. No launcher, digite < para buscar um atalho."
        property var binds: []
        Process {
            running: true
            command: ["python3", Qt.resolvedUrl("scripts/keybinds.py").toString().replace("file://", "")]
            stdout: StdioCollector { onStreamFinished: { try { kbCard.binds = JSON.parse(text) } catch (e) {} } }
        }
        UiField { id: kbF; width: parent.width; placeholderText: "Buscar atalho…" }
        Repeater {
            model: kbCard.binds.filter(b => { const q = kbF.text.toLowerCase(); return !q || (b.label + " " + b.keys + " " + b.section).toLowerCase().includes(q) }).slice(0, 60)
            delegate: Item {
                required property var modelData
                width: parent.width; height: 32
                UiText { anchors.verticalCenter: parent.verticalCenter; width: parent.width - kr.width - 12; elide: Text.ElideRight; text: modelData.label; color: Theme.text; font.pixelSize: 13 }
                Row {
                    id: kr
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: 4
                    Repeater {
                        model: modelData.keys.split(" + ")
                        delegate: Rectangle {
                            required property string modelData
                            height: 22; width: Math.max(22, kt.implicitWidth + 12); radius: 6; color: Theme.track; border.width: 1; border.color: Theme.border
                            UiText { id: kt; anchors.centerIn: parent; text: modelData; color: Theme.text; font.pixelSize: 11; font.weight: Font.DemiBold }
                        }
                    }
                }
            }
        }
    }
}
