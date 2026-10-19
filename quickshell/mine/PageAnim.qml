// Pagina "Animacoes": o centro do sistema de animacoes.
//  1. Onde cada uma e usada: todos os lugares (paineis, barras, area de trabalho e janelas do Hyprland), com abrir/fechar
//     e um botao que testa de verdade.
//  2. Velocidade de tudo; o Hyprland pode seguir as mesmas animacoes (curvas e molas viram config do Hyprland).
//  3. Biblioteca + editor: curvas de bezier (pinos) e molas (rigidez, amortecimento, massa), tocando em loop com rastro.
//  4. Em acao: a animacao do editor movendo, crescendo e abrindo um painel.
import Quickshell
import QtQuick

Column {
    id: page
    spacing: 14

    property string sel: "Padrão"
    readonly property var cur: Settings.findAnim(sel) ?? Settings.builtinAnims[0]
    readonly property bool locked: !!cur.builtin
    readonly property bool isSpring: cur.type === "spring"
    readonly property var comp: Motion.compile(cur)
    function set(vals) { if (!page.locked) Settings.setAnimMany(page.cur.name, vals) }
    readonly property string css: "cubic-bezier(" + [cur.x1, cur.y1, cur.x2, cur.y2].map(v => ((v ?? 0) / 100).toFixed(2)).join(", ") + ")"
    // onde esta animacao esta em uso (abrir ou fechar)
    readonly property var usedIn: Settings.animTargets.filter(t => Motion.nameFor(t.id, false) === cur.name || (t.phases && Motion.nameFor(t.id, true) === cur.name))
    readonly property bool hypr: !!(Settings.animCfg && Settings.animCfg.hypr)
    property string openRow: ""
    property string toast: ""
    Timer { id: toastT; interval: 1800; onTriggered: page.toast = "" }
    function say(s) { toast = s; toastT.restart() }
    function newSpring() { page.sel = Settings.addAnim({ name: "Mola", type: "spring", mass: 1, stiffness: 238, dampening: 24 }) }
    function newCurve() { page.sel = Settings.addAnim({ name: "Curva", x1: 5, y1: 70, x2: 10, y2: 100, duration: 300 }) }

    // ---------- 1. onde cada uma e usada ----------
    Card {
        icon: "layers"
        title: "Onde cada animação é usada"
        subtitle: "Clique num lugar para trocar a animação de abrir e de fechar. “▶” abre e fecha a coisa de verdade; clicar no nome de uma animação abre ela no editor."
        Repeater {
            model: Settings.animGroups
            delegate: Column {
                id: grp
                required property var modelData
                readonly property bool isHypr: modelData.id === "hypr"
                width: parent.width
                spacing: 6
                Row {
                    width: parent.width
                    spacing: 8
                    UiIcon { name: grp.modelData.icon; size: 15; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                    UiLabel { text: grp.modelData.label; anchors.verticalCenter: parent.verticalCenter }
                }
                // Hyprland: liga/desliga e estilos
                Rectangle {
                    visible: grp.isHypr
                    width: parent.width; height: hyCol.implicitHeight + 24; radius: 12
                    color: page.hypr ? Theme.tint(0.10) : Theme.track
                    border.width: 1; border.color: page.hypr ? Theme.tint(0.4) : Theme.border
                    Column {
                        id: hyCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                        spacing: 10
                        UiSwitch {
                            label: "O Hyprland segue estas animações"
                            description: page.hypr ? "As janelas usam as curvas e molas daqui (aplicado na hora). Desligar volta ao seu hyprland/animations.lua."
                                                   : "Desligado: as janelas usam o hyprland/animations.lua. Ligue para editar tudo aqui, com mola de verdade."
                            icon: "window"
                            checked: page.hypr
                            onToggled: on => Settings.setAnimCfg({ hypr: on })
                        }
                        Flow {
                            visible: page.hypr
                            width: parent.width
                            spacing: 14
                            Repeater {
                                model: [["windows", "Janelas"], ["workspaces", "Workspaces"], ["layers", "Camadas"]]
                                delegate: Column {
                                    required property var modelData
                                    spacing: 4
                                    Text { text: modelData[1]; color: Theme.muted; font.pixelSize: 11; font.weight: Font.DemiBold }
                                    UiSeg {
                                        options: Settings.hyprStyleOptions[modelData[0]]
                                        value: (Settings.animCfg.hyprStyle ?? {})[modelData[0]] ?? Settings.hyprStyleDefaults[modelData[0]]
                                        onPicked: v => { const st = Object.assign({}, Settings.animCfg.hyprStyle ?? {}); st[modelData[0]] = v; Settings.setAnimCfg({ hyprStyle: st }) }
                                    }
                                }
                            }
                        }
                    }
                }
                Repeater {
                    model: Settings.animTargets.filter(t => t.group === grp.modelData.id)
                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        readonly property bool open: page.openRow === modelData.id
                        readonly property bool dim: grp.isHypr && !page.hypr
                        width: grp.width
                        height: rowHead.height + (open ? pick.implicitHeight + 14 : 0)
                        radius: 12
                        clip: true
                        color: open ? Theme.cardHi : (rm.containsMouse ? Qt.rgba(Theme.cardHi.r, Theme.cardHi.g, Theme.cardHi.b, 0.6) : "transparent")
                        border.width: open ? 1 : 0; border.color: Theme.border
                        opacity: dim ? 0.45 : 1
                        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Item {
                            id: rowHead
                            width: parent.width; height: 48
                            MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.openRow = row.open ? "" : row.modelData.id }
                            Text {
                                anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter; right: chips.left; rightMargin: 10 }
                                elide: Text.ElideRight
                                text: row.modelData.label; color: Theme.text; font.pixelSize: 13
                            }
                            Row {
                                id: chips
                                anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                                spacing: 6
                                Chip { phase: "abrir"; visible: !!row.modelData.phases; name: Motion.nameFor(row.modelData.id, false) }
                                Chip { phase: row.modelData.phases ? "fechar" : ""; name: Motion.nameFor(row.modelData.id, !!row.modelData.phases) }
                                UiButton { visible: Motion.canTest(row.modelData.id); icon: "play"; kind: "ghost"; onClicked: Motion.test(row.modelData.id) }
                                UiIcon { anchors.verticalCenter: parent.verticalCenter; name: row.open ? "chevUp" : "chevDown"; size: 16; color: Theme.muted }
                            }
                        }
                        AnimPicker {
                            id: pick
                            visible: row.open
                            x: 12; y: rowHead.height
                            width: row.width - 24
                            target: row.modelData.id
                            expanded: true
                        }
                    }
                }
            }
        }
    }

    // ---------- 2. velocidade ----------
    Card {
        icon: "speed"
        title: "Velocidade"
        subtitle: "Acelera ou desacelera tudo de uma vez (inclusive as janelas, quando o Hyprland segue o shell). As molas ficam mais firmes, sem mudar o jeito."
        UiSlider {
            label: "Velocidade geral"; icon: "speed"
            from: 25; to: 300
            value: Math.round(Motion.speed * 100)
            suffix: " %"
            onMoved: v => Settings.setAnimCfg({ speed: Math.round(v / 5) * 5 / 100 })
        }
        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: [[50, "Calma"], [100, "Normal"], [150, "Ágil"], [200, "Rápida"]]
                delegate: UiButton {
                    required property var modelData
                    text: modelData[1]; kind: "ghost"
                    checked: Math.round(Motion.speed * 100) === modelData[0]
                    onClicked: Settings.setAnimCfg({ speed: modelData[0] / 100 })
                }
            }
        }
    }

    // ---------- 3. biblioteca ----------
    Card {
        icon: "animation"
        title: "Biblioteca"
        subtitle: "As do sistema (não editáveis) e as suas. Passe o mouse para ver andando; clique para abrir no editor."
        AnimPicker { editMode: true; selected: page.sel; onChosen: n => page.sel = n }
        Row {
            spacing: 8
            UiButton { icon: "curve"; text: "Nova curva"; kind: "ghost"; onClicked: page.newCurve() }
            UiButton { icon: "wave"; text: "Nova mola"; kind: "ghost"; onClicked: page.newSpring() }
        }
    }

    // ---------- 4. editor ----------
    Card {
        icon: page.locked ? "lock" : (page.isSpring ? "wave" : "curve")
        title: page.cur.name
        subtitle: page.locked ? "Animação do sistema: dá para ver e testar. Para mudar, duplique e edite a cópia."
                 : page.isSpring ? "Uma mola de verdade: o tempo sai da física. Rigidez acelera, amortecimento segura o balanço, massa dá peso."
                 : "Arraste os pinos (Shift encaixa de 5 em 5). A bolinha mostra a animação acontecendo."

        Row {
            width: parent.width
            spacing: 10
            visible: !page.locked
            UiIcon { name: "pencil"; size: 15; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Nome"; color: Theme.text; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
            UiField { width: 240; text: page.cur.name; onEditingFinished: page.sel = Settings.renameAnim(page.cur.name, text) }
            UiSeg {
                options: [["bezier", "Curva", "curve"], ["spring", "Mola", "wave"]]
                value: page.isSpring ? "spring" : "bezier"
                onPicked: v => {
                    if (v === "spring") page.set({ type: "spring", mass: page.cur.mass ?? 1, stiffness: page.cur.stiffness ?? 238, dampening: page.cur.dampening ?? 24 })
                    else page.set({ type: "bezier", x1: page.cur.x1 ?? 5, y1: page.cur.y1 ?? 70, x2: page.cur.x2 ?? 10, y2: page.cur.y2 ?? 100, duration: page.cur.duration ?? page.comp.duration })
                }
            }
        }
        Flow {
            width: parent.width
            spacing: 6
            Text { text: page.usedIn.length ? "Em uso em:" : "Ainda não está em uso"; color: Theme.muted; font.pixelSize: 12; height: 24; verticalAlignment: Text.AlignVCenter }
            Repeater {
                model: page.usedIn
                delegate: Rectangle {
                    required property var modelData
                    height: 24; width: ul.implicitWidth + 16; radius: 12
                    color: Theme.tint(0.14); border.width: 1; border.color: Theme.tint(0.4)
                    Text { id: ul; anchors.centerIn: parent; text: modelData.label; color: Theme.text; font.pixelSize: 11 }
                }
            }
        }

        CurveEditor {
            id: ed
            width: parent.width
            anim: page.cur
            editable: !page.locked
            playing: playBtn.on
            speed: slowBtn.on ? 0.25 : 1
            onEdited: vals => page.set(vals)
            Rectangle {   // CSS (curvas) ou resumo da mola, no canto
                anchors { right: parent.right; top: parent.top; margins: 10 }
                width: cssT.implicitWidth + 16; height: 24; radius: 8
                color: Theme.card; border.width: 1; border.color: Theme.border
                Text {
                    id: cssT; anchors.centerIn: parent; color: Theme.muted; font.pixelSize: 11; font.family: "monospace"
                    text: page.isSpring ? "massa " + (page.cur.mass ?? 1) + " · rigidez " + (page.cur.stiffness ?? 0) + " · amortecimento " + (page.cur.dampening ?? 0) : page.css
                }
            }
        }

        // leitura rapida
        Flow {
            width: parent.width
            spacing: 8
            Repeater {
                model: [
                    ["timer", "Duração", page.comp.duration + " ms"],
                    ["check", "Parece pronta em", Math.round(ed.ready * page.comp.duration) + " ms"],
                    ["arrowUp", "Passa do ponto", page.comp.overshoot > 0.5 ? Math.round(page.comp.overshoot) + "%" : "não"],
                    ["wave", "Balanços", page.isSpring ? String(page.comp.swings) : "—"],
                    ["speed", "Com a velocidade geral", Motion.speed === 1 ? "igual" : Math.round(page.comp.duration / Motion.speed) + " ms"]
                ]
                delegate: Rectangle {
                    required property var modelData
                    height: 40; width: sc.implicitWidth + 24; radius: 10
                    color: Theme.track; border.width: 1; border.color: Theme.border
                    Row {
                        id: sc
                        anchors.centerIn: parent
                        spacing: 8
                        UiIcon { name: modelData[0]; size: 14; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text { text: modelData[1]; color: Theme.muted; font.pixelSize: 10 }
                            Text { text: modelData[2]; color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                        }
                    }
                }
            }
        }

        // reproducao
        Flow {
            width: parent.width
            spacing: 6
            UiButton { id: playBtn; property bool on: true; icon: on ? "pause" : "play"; text: on ? "Pausar" : "Tocar em loop"; kind: on ? "accent" : "normal"; onClicked: on = !on }
            UiButton { icon: "refresh"; text: "Do início"; kind: "ghost"; onClicked: { playBtn.on = true; ed.replay() } }
            UiButton { id: slowBtn; property bool on: false; icon: "timer"; text: "Câmera lenta"; checked: on; onClicked: on = !on }
            UiButton { visible: !page.isSpring; icon: "cards"; text: "Copiar CSS"; kind: "ghost"; onClicked: { Quickshell.clipboardText = page.css; page.say("Copiado: " + page.css) } }
            UiButton {
                visible: !page.locked && !page.isSpring
                icon: "send"; text: "Colar CSS"; kind: "ghost"
                onClicked: {
                    const n = (Quickshell.clipboardText.match(/-?\d*\.?\d+/g) || []).map(parseFloat)
                    if (n.length < 4) { page.say("A área de transferência não tem um cubic-bezier(…)"); return }
                    const cx = v => Math.round(Math.max(0, Math.min(1, v)) * 100), cy = v => Math.round(Math.max(-0.5, Math.min(1.5, v)) * 100)
                    page.set({ x1: cx(n[0]), y1: cy(n[1]), x2: cx(n[2]), y2: cy(n[3]) })
                    page.say("Curva colada")
                }
            }
            Text { visible: page.toast !== ""; text: page.toast; color: Theme.accent; font.pixelSize: 12; height: 36; verticalAlignment: Text.AlignVCenter }
        }

        // ---- curva: valores exatos e duracao ----
        Row {
            visible: !page.isSpring
            spacing: 8
            Repeater {
                model: [["x1", "X1", false], ["y1", "Y1", true], ["x2", "X2", false], ["y2", "Y2", true]]
                delegate: Row {
                    required property var modelData
                    spacing: 5
                    Text { text: modelData[1]; color: Theme.muted; font.pixelSize: 12; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                    UiField {
                        width: 66
                        enabled: !page.locked
                        text: ((page.cur[modelData[0]] ?? 0) / 100).toFixed(2)
                        onEditingFinished: {
                            const v = parseFloat(text.replace(",", "."))
                            if (isNaN(v)) { text = ((page.cur[modelData[0]] ?? 0) / 100).toFixed(2); return }
                            const lim = modelData[2] ? [-0.5, 1.5] : [0, 1]
                            const o = {}; o[modelData[0]] = Math.round(Math.max(lim[0], Math.min(lim[1], v)) * 100)
                            page.set(o)
                        }
                    }
                }
            }
        }
        UiSlider { visible: !page.isSpring; label: "Duração"; icon: "timer"; from: 50; to: 1500; value: page.cur.duration ?? 300; suffix: " ms"; onMoved: v => { if (!page.locked) page.set({ duration: Math.round(v / 10) * 10 }) } }

        // ---- mola: fisica ----
        UiSlider { visible: page.isSpring; label: "Rigidez (mais alta = mais rápida)"; icon: "speed"; from: 20; to: 1000; value: page.cur.stiffness ?? 200; onMoved: v => page.set({ stiffness: v }) }
        UiSlider { visible: page.isSpring; label: "Amortecimento (mais baixo = balança mais)"; icon: "wave"; from: 2; to: 80; value: Math.round(page.cur.dampening ?? 20); onMoved: v => page.set({ dampening: v }) }
        UiSlider { visible: page.isSpring; label: "Massa (×10)"; icon: "gauge"; from: 5; to: 40; value: Math.round((page.cur.mass ?? 1) * 10); onMoved: v => page.set({ mass: v / 10 }) }

        // modelos prontos (so nas suas)
        UiLabel { visible: !page.locked; text: "Começar de um modelo" }
        Flow {
            visible: !page.locked && !page.isSpring
            width: parent.width
            spacing: 6
            Repeater {
                model: [["Suave", 25, 10, 25, 100], ["Entrada", 42, 0, 100, 100], ["Saída", 0, 0, 58, 100], ["Entrada e saída", 42, 0, 58, 100],
                        ["Desacelera forte", 5, 70, 10, 100], ["Ênfase (saída)", 30, 0, 80, 15], ["Volta (back)", 34, 156, 64, 100], ["Antecipa", 36, -40, 60, 100]]
                delegate: UiButton {
                    required property var modelData
                    text: modelData[0]; kind: "ghost"
                    onClicked: page.set({ x1: modelData[1], y1: modelData[2], x2: modelData[3], y2: modelData[4] })
                }
            }
        }
        Flow {
            visible: !page.locked && page.isSpring
            width: parent.width
            spacing: 6
            Repeater {
                model: [["Firme", 1, 400, 40], ["Padrão do Hyprland", 1, 238, 24.2], ["Macia", 1, 170, 26], ["Elástica", 1, 320, 15], ["Quique", 1, 420, 11], ["Pesada", 2.5, 260, 40], ["Gelatina", 1, 120, 6]]
                delegate: UiButton {
                    required property var modelData
                    text: modelData[0]; kind: "ghost"
                    onClicked: page.set({ mass: modelData[1], stiffness: modelData[2], dampening: modelData[3] })
                }
            }
        }

        Flow {
            width: parent.width
            spacing: 6
            UiButton { icon: "cards"; text: page.locked ? "Duplicar para editar" : "Duplicar"; kind: page.locked ? "accent" : "normal"; onClicked: page.sel = Settings.addAnim(page.cur) }
            UiButton { visible: !page.locked; icon: "trash"; text: "Excluir"; kind: "danger"; onClicked: { const n = page.cur.name; page.sel = "Padrão"; Settings.removeAnim(n) } }
        }
    }

    // ---------- 5. demonstracoes: a curva aplicada a coisas de verdade (mesmo relogio do editor) ----------
    Card {
        icon: "play"
        title: "Em ação"
        subtitle: "A mesma animação movendo, crescendo e abrindo um painel da moldura. A sombra mostra como seria em linha reta."
        Row {
            id: demos
            width: parent.width
            spacing: 10
            readonly property real dw: (width - 20) / 3
            readonly property real e: ed.e
            readonly property real t: ed.t

            Rectangle {
                width: demos.dw; height: 150; radius: 12
                color: Theme.track; border.width: 1; border.color: Theme.border
                clip: true
                Text { x: 12; y: 10; text: "Deslizar"; color: Theme.muted; font.pixelSize: 11; font.weight: Font.DemiBold }
                Rectangle { x: 16; width: parent.width - 32; y: parent.height / 2 + 2; height: 4; radius: 2; color: Theme.cardHi }
                Rectangle {
                    width: 30; height: 30; radius: 9
                    y: parent.height / 2 - 13
                    x: 16 + demos.t * (parent.width - 32 - width)
                    color: "transparent"; border.width: 1.5; border.color: Qt.rgba(1, 1, 1, 0.25)
                }
                Rectangle {
                    width: 30; height: 30; radius: 9
                    y: parent.height / 2 - 13
                    x: 16 + demos.e * (parent.width - 32 - width)
                    color: Theme.accent
                }
            }
            Rectangle {
                width: demos.dw; height: 150; radius: 12
                color: Theme.track; border.width: 1; border.color: Theme.border
                clip: true
                Text { x: 12; y: 10; text: "Crescer"; color: Theme.muted; font.pixelSize: 11; font.weight: Font.DemiBold }
                Rectangle {
                    anchors.centerIn: parent; anchors.verticalCenterOffset: 8
                    width: 70; height: 70; radius: 18
                    color: "transparent"; border.width: 1.5; border.color: Qt.rgba(1, 1, 1, 0.18)
                    scale: 0.3 + 0.7 * demos.t
                }
                Rectangle {
                    anchors.centerIn: parent; anchors.verticalCenterOffset: 8
                    width: 70; height: 70; radius: 18
                    color: Theme.accent
                    opacity: Math.max(0, Math.min(1, demos.e * 2))
                    scale: Math.max(0, 0.3 + 0.7 * demos.e)
                    UiIcon { anchors.centerIn: parent; name: "apps"; size: 30; color: Theme.accentText }
                }
            }
            Rectangle {
                width: demos.dw; height: 150; radius: 12
                color: Theme.track; border.width: 1; border.color: Theme.border
                clip: true
                Text { x: 12; y: 10; text: "Painel"; color: Theme.muted; font.pixelSize: 11; font.weight: Font.DemiBold }
                Item {
                    id: scr
                    anchors { fill: parent; margins: 14; topMargin: 30 }
                    Rectangle { anchors.fill: parent; radius: 8; color: "transparent"; border.width: 4; border.color: Theme.card }
                    Rectangle {
                        readonly property real full: scr.height * 0.62
                        width: scr.width * 0.6; height: 4 + (full - 4) * Math.max(0, demos.e)
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                        radius: 8
                        color: Theme.card
                        Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 8; color: Theme.card }
                        Column {
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                            spacing: 5
                            opacity: Math.max(0, Math.min(1, demos.e * 4 - 1))
                            Repeater { model: 3; delegate: Rectangle { required property int index; width: parent.width * (index === 0 ? 0.7 : 1); height: 6; radius: 3; color: index === 0 ? Theme.accent : Theme.cardHi } }
                        }
                    }
                }
            }
        }
    }

    // nome de uma animacao com a miniatura; clicar abre no editor
    component Chip: Rectangle {
        id: ch
        property string name
        property string phase: ""
        readonly property var a: Settings.findAnim(name)
        height: 30; width: chRow.implicitWidth + 14; radius: 9
        color: chm.containsMouse ? Theme.tint(0.18) : Theme.track
        border.width: 1; border.color: page.sel === name ? Theme.accent : Theme.border
        Row {
            id: chRow
            anchors.centerIn: parent
            spacing: 6
            CurveThumb { width: 20; height: 20; pad: 2; anim: ch.a; stroke: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
            Text { visible: ch.phase !== ""; text: ch.phase; color: Theme.muted; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
            Text { text: ch.name; color: Theme.text; font.pixelSize: 11; font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea { id: chm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.sel = ch.name }
    }
}
