// Pagina "Monitores" (kit Set*): disposicao das telas (previa em escala; clique escolhe a tela), resolucao, taxa, escala,
// giro e posicao de cada monitor (lidos do hyprctl), com a pergunta "ficou bom?" de 15 s (logica em Displays.qml; veio de Janelas,
// mesmas chaves + Settings.hyprMonitors por monitor), brilho (brightnessctl ou ddcutil), luz noturna e taxa variavel (VRR).
// Nada roda com a pagina fechada. Modo de teste (SysAct.dry): mudancas de monitor, VRR e brilho so sao logados.
import Quickshell
import Quickshell.Io
import QtQuick

SetPage {
    id: page
    title: "Monitores"
    subtitle: "Resolução, escala, posição, brilho e luz noturna das telas"
    readonly property bool live: visible && Settings.settingsOpen
    onLiveChanged: {
        if (live) { SysAct.check(); Displays.use(); HyprConf.refresh(); Brightness.refresh(); ddcProbe.running = true }
        else { Displays.release(); if (Displays.secsLeft > 0) Displays.revert() }
    }
    Component.onDestruction: { if (live) Displays.release(); if (Displays.secsLeft > 0) Displays.revert() }

    readonly property var mons: Displays.mons
    property string selName: ""
    readonly property var sel: mons.find(m => m.name === selName) ?? mons.find(m => m.focused) ?? mons[0] ?? null
    readonly property var others: sel ? mons.filter(m => m.name !== sel.name) : []

    // resolucoes e taxas a partir de availableModes ("1920x1080@60.00Hz")
    function parseMode(m) { const r = /^(\d+x\d+)@([\d.]+)Hz$/.exec(m); return r ? { res: r[1], hz: parseFloat(r[2]), raw: m } : null }
    readonly property var parsed: sel ? sel.modes.map(parseMode).filter(x => x) : []
    readonly property string curRes: sel ? sel.w + "x" + sel.h : ""
    readonly property real curHz: sel ? parseFloat(sel.mode.split("@")[1]) : 0
    readonly property var resList: { const seen = {}, out = []; for (const m of parsed) if (!seen[m.res]) { seen[m.res] = 1; out.push(m.res) } return out.slice(0, 14) }
    // uma taxa por valor arredondado (a lista do Hyprland repete 59.94 / 60.00)
    readonly property var hzList: { const seen = {}, out = []; for (const m of parsed) if (m.res === curRes) { const k = Math.round(m.hz); if (!seen[k]) { seen[k] = 1; out.push({ hz: k, raw: m.raw }) } } return out }
    function pickRes(res) {
        if (!sel || res === curRes) return
        const c = parsed.filter(m => m.res === res)
        const same = c.find(m => Math.round(m.hz) === Math.round(curHz))
        const best = same ?? c.reduce((a, b) => (b.hz > a.hz ? b : a), c[0])
        Displays.apply(sel.name, { mode: best.raw })
    }
    readonly property var scaleOpts: {
        const o = [1, 1.25, 1.5, 1.75, 2]
        if (sel && o.indexOf(sel.scale) < 0) { o.push(Math.round(sel.scale * 100) / 100); o.sort((a, b) => a - b) }
        return o.map(v => [v, Math.round(v * 100) + "%"])
    }

    // ---- previa: retangulos em escala (logicos), clique escolhe ----
    preview: SetPreview {
        height: 190
        Item {
            id: stage
            anchors.fill: parent
            readonly property real pad: 18
            readonly property real minX: page.mons.reduce((a, m) => Math.min(a, m.x), 1e9)
            readonly property real minY: page.mons.reduce((a, m) => Math.min(a, m.y), 1e9)
            readonly property real bw: Math.max(1, page.mons.reduce((a, m) => Math.max(a, m.x + m.lw), -1e9) - minX)
            readonly property real bh: Math.max(1, page.mons.reduce((a, m) => Math.max(a, m.y + m.lh), -1e9) - minY)
            readonly property real k: Math.min((width - pad * 2) / bw, (height - pad * 2) / bh)
            readonly property real ox: (width - bw * k) / 2
            readonly property real oy: (height - bh * k) / 2
            Repeater {
                model: page.mons
                delegate: Rectangle {
                    id: mr
                    required property var modelData
                    readonly property bool cur: page.sel && page.sel.name === modelData.name
                    x: stage.ox + (modelData.x - stage.minX) * stage.k
                    y: stage.oy + (modelData.y - stage.minY) * stage.k
                    width: Math.max(40, modelData.lw * stage.k) - 3; height: Math.max(28, modelData.lh * stage.k) - 3
                    radius: 8
                    color: cur ? Theme.tint(0.2) : Theme.card
                    border.width: cur ? 2 : 1; border.color: cur ? Theme.accent : Theme.border
                    opacity: modelData.disabled ? 0.45 : 1
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.selName = mr.modelData.name }
                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 8
                        spacing: 1
                        UiText { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: mr.modelData.name; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                        UiText { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: mr.modelData.w + "×" + mr.modelData.h + " · " + Math.round(parseFloat(mr.modelData.mode.split("@")[1])) + " Hz"; color: Theme.muted; font.pixelSize: 11; font.features: { "tnum": 1 } }
                    }
                }
            }
            UiText { visible: page.mons.length === 0; anchors.centerIn: parent; text: "Lendo os monitores…"; color: Theme.muted; font.pixelSize: 13 }
        }
    }

    // ---- pergunta de 15 s ----
    SetSection {
        visible: Displays.secsLeft > 0
        title: ""
        SetRow {
            icon: "timer"; label: "Ficou bom? Volta em " + Displays.secsLeft + " s"; description: SysAct.dry ? "Modo de teste: nada foi mudado de verdade" : "Se a tela ficar estranha, ela volta sozinha"
            UiButton { icon: "check"; text: "Manter"; kind: "accent"; onClicked: Displays.keep() }
            UiButton { icon: "restore"; text: "Voltar"; kind: "ghost"; onClicked: Displays.revert() }
        }
    }

    // ---- a tela escolhida ----
    SetSection {
        title: "Tela"; icon: "monitor"
        subtitle: page.sel ? page.sel.name + (page.sel.desc !== "" ? " · " + page.sel.desc : "") + " · " + page.sel.w + "×" + page.sel.h + " · escala " + Math.round(page.sel.scale * 100) + "%" : "Nenhum monitor encontrado"
        SetRow { visible: SysAct.dry; icon: "info"; label: "Modo de teste"; description: "Nenhuma mudança é gravada nem aplicada; só aparece no log" }
        SetBlock {
            visible: !!page.sel
            UiText { text: "Resolução"; color: Theme.text; font.pixelSize: SetK.fRow; font.weight: Font.Medium }
            Flow {
                width: parent.width; spacing: SetK.sm
                Repeater {
                    model: page.resList
                    delegate: UiButton { required property string modelData; text: modelData.replace("x", " × "); kind: modelData === page.curRes ? "accent" : "ghost"; onClicked: page.pickRes(modelData) }
                }
            }
            UiText { text: "Taxa de atualização"; color: Theme.text; font.pixelSize: SetK.fRow; font.weight: Font.Medium; topPadding: SetK.xs }
            Flow {
                width: parent.width; spacing: SetK.sm
                Repeater {
                    model: page.hzList
                    delegate: UiButton { required property var modelData; text: modelData.hz + " Hz"; kind: modelData.hz === Math.round(page.curHz) ? "accent" : "ghost"; onClicked: Displays.apply(page.sel.name, { mode: modelData.raw }) }
                }
            }
        }
        SetChoice {
            visible: !!page.sel
            icon: "resize"; label: "Escala"
            options: page.scaleOpts
            value: page.sel ? Math.round(page.sel.scale * 100) / 100 : 1
            onPicked: v => Displays.apply(page.sel.name, { scale: v })
        }
        SetChoice {
            visible: !!page.sel
            icon: "rotate"; label: "Orientação"
            options: [[0, "Normal"], [1, "90°"], [2, "180°"], [3, "270°"]]
            value: page.sel ? page.sel.transform : 0
            onPicked: v => Displays.apply(page.sel.name, { transform: v })
        }
    }

    // ---- posicao (so com mais de uma tela) ----
    SetSection {
        visible: page.others.length > 0
        title: "Posição"; icon: "view_grid"
        subtitle: page.sel ? page.sel.name + " está em " + page.sel.x + ", " + page.sel.y : ""
        Repeater {
            model: page.others
            delegate: SetRow {
                id: pr
                required property var modelData
                icon: "monitor"; label: "Em relação a " + modelData.name
                function put(x, y) { Displays.apply(page.sel.name, { x: Math.round(x), y: Math.round(y) }) }
                UiButton { text: "Esquerda"; kind: "ghost"; onClicked: pr.put(pr.modelData.x - page.sel.lw, pr.modelData.y) }
                UiButton { text: "Direita"; kind: "ghost"; onClicked: pr.put(pr.modelData.x + pr.modelData.lw, pr.modelData.y) }
                UiButton { text: "Acima"; kind: "ghost"; onClicked: pr.put(pr.modelData.x, pr.modelData.y - page.sel.lh) }
                UiButton { text: "Abaixo"; kind: "ghost"; onClicked: pr.put(pr.modelData.x, pr.modelData.y + pr.modelData.lh) }
            }
        }
        SetRow {
            icon: "cursorMove"; label: "Posição exata"; description: "Em pixels, a partir do canto da primeira tela"
            UiField { id: px; width: 70; horizontalAlignment: Text.AlignHCenter; placeholderText: "x"; text: page.sel ? String(page.sel.x) : ""; validator: IntValidator {} }
            UiField { id: py; width: 70; horizontalAlignment: Text.AlignHCenter; placeholderText: "y"; text: page.sel ? String(page.sel.y) : ""; validator: IntValidator {} }
            UiButton { text: "Aplicar"; kind: "accent"; onClicked: Displays.apply(page.sel.name, { x: parseInt(px.text) || 0, y: parseInt(py.text) || 0 }) }
        }
    }

    // ---- brilho (brightnessctl na tela interna, ou ddcutil nas externas) ----
    property bool ddc: false
    property real ddcValue: 50
    Process { id: ddcProbe; command: ["sh", "-c", "command -v ddcutil >/dev/null && ddcutil getvcp 10 --terse 2>/dev/null | head -1"]
        stdout: StdioCollector { onStreamFinished: { const f = text.trim().split(/\s+/); if (f[0] === "VCP" && f.length >= 5) { page.ddc = true; page.ddcValue = parseInt(f[3]) / Math.max(1, parseInt(f[4])) * 100 } } } }
    Timer { id: ddcT; interval: 450; onTriggered: if (SysAct.real("brilho ddcutil " + Math.round(page.ddcValue))) Quickshell.execDetached(["ddcutil", "setvcp", "10", String(Math.round(page.ddcValue))]) }
    SetSection {
        title: "Brilho"; icon: "sun"
        subtitle: Brightness.available ? "Tela interna (brightnessctl)" : page.ddc ? "Monitor externo (ddcutil)" : "Sem controle de brilho"
        SetSlider {
            visible: Brightness.available
            icon: "sun"; label: "Brilho da tela"; from: 1; to: 100; unit: " %"
            value: Math.round(Brightness.value * 100)
            onMoved: v => { if (SysAct.real("brilho " + v)) Brightness.set(v / 100) }
        }
        SetSlider {
            visible: !Brightness.available && page.ddc
            icon: "sun"; label: "Brilho do monitor"; from: 0; to: 100; unit: " %"
            value: Math.round(page.ddcValue)
            onMoved: v => { page.ddcValue = v; ddcT.restart() }
        }
        SetRow {
            visible: !Brightness.available && !page.ddc
            icon: "info"; label: "Sem controle de brilho"; description: "Monitores externos precisam do ddcutil (e do módulo i2c-dev); telas de notebook, do brightnessctl"
        }
    }

    // ---- luz noturna (os ajustes completos ficam em Paineis) ----
    SetSection {
        title: "Luz noturna"; icon: "night"
        subtitle: !NightLight.available ? "Precisa do hyprsunset (sudo pacman -S hyprsunset)" : NightLight.active ? "Ligada agora (" + Settings.nightTemp + " K)" : "Desligada agora"
        SetRow {
            icon: "night"; label: "Luz noturna"; description: "Tela mais quente para a noite"
            checked: NightLight.active
            onToggled: on => { if (NightLight.active !== on) NightLight.toggle() }
        }
        SetRow {
            icon: "tune"; label: "Temperatura e horário"; description: "Ficam em Painéis, Luz noturna"; link: true
            onClicked: { Settings.settingsSub = "more"; Settings.settingsReveal = "Luz noturna"; Settings.settingsPage = "panels" }
        }
    }

    // ---- taxa variavel ----
    SetSection {
        title: "Taxa variável"; icon: "monitor"
        subtitle: "VRR / FreeSync: a tela segue a taxa do jogo (precisa de monitor compatível)"
        SetChoice {
            icon: "monitor"; label: "VRR"
            options: [[0, "Desligada"], [1, "Sempre"], [2, "Só em tela cheia"]]
            value: HyprConf.value("misc:vrr") ?? 0
            onPicked: v => { if (SysAct.real("vrr " + v)) HyprConf.set("misc:vrr", v) }
        }
    }
}
