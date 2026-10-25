// Pagina "Animacoes" (kit Set*): o centro do sistema de animacoes.
//  Previa: editor da curva/mola escolhida + demos (deslizar, crescer, painel). So tocam com o mouse em cima ou em "Tocar em loop".
//  Biblioteca em cartoes com a miniatura de cada curva; editor em controles deslizantes; velocidade geral; e onde cada animacao e usada.
import Quickshell
import QtQuick

SetPage {
    id: page
    title: "Animações"
    subtitle: "Curvas e molas de tudo o que se move"

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
    // nomes das animacoes: so muda quando uma entra, sai ou e renomeada (editar valores nao recria os cartoes)
    property var names: []
    function syncNames() { const n = Settings.allAnims().map(a => a.name); if (n.join("|") !== names.join("|")) names = n }
    Connections { target: Settings; function onAnimCfgChanged() { page.syncNames() } }
    Component.onCompleted: syncNames()
    property string openRow: ""
    property bool loop: false
    property bool slow: false
    property string toast: ""
    Timer { id: toastT; interval: 1800; onTriggered: page.toast = "" }
    function say(s) { toast = s; toastT.restart() }
    function newSpring() { page.sel = Settings.addAnim({ name: "Mola", type: "spring", mass: 1, stiffness: 238, dampening: 24 }) }
    function newCurve() { page.sel = Settings.addAnim({ name: "Curva", x1: 5, y1: 70, x2: 10, y2: 100, duration: 300 }) }

    // ---- previa: editor + demos ----
    preview: SetPreview {
        id: prev
        height: 300
        CurveEditor {
            id: ed
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: Math.round(parent.width * 0.56)
            anim: page.cur
            editable: !page.locked
            playing: page.loop || prev.hovered
            speed: page.slow ? 0.25 : 1
            onEdited: vals => page.set(vals)
            Rectangle {   // CSS (curvas) ou resumo da mola, no canto
                anchors { right: parent.right; top: parent.top; margins: 10 }
                width: cssT.implicitWidth + 16; height: 24; radius: 8
                color: Theme.card; border.width: 1; border.color: Theme.border
                UiText {
                    id: cssT; anchors.centerIn: parent; color: Theme.muted; font.pixelSize: 11; font.family: Theme.mono
                    text: page.isSpring ? "massa " + (page.cur.mass ?? 1) + " · rigidez " + (page.cur.stiffness ?? 0) + " · amort. " + (page.cur.dampening ?? 0) : page.css
                }
            }
        }
        Column {
            id: demos
            anchors { left: ed.right; leftMargin: 10; right: parent.right; rightMargin: 10; top: parent.top; topMargin: 10; bottom: parent.bottom; bottomMargin: 10 }
            spacing: 8
            readonly property real bh: (height - 16) / 3
            readonly property real e: ed.e
            readonly property real t: ed.t
            Rectangle {   // deslizar
                width: parent.width; height: demos.bh; radius: 12
                color: Theme.card; border.width: 1; border.color: Theme.border; clip: true
                UiText { x: 12; y: 8; text: "Deslizar"; color: Theme.muted; font.pixelSize: 11; font.weight: Font.DemiBold }
                Rectangle { x: 16; width: parent.width - 32; y: parent.height * 0.62; height: 4; radius: 2; color: Theme.cardHi }
                Rectangle { width: 24; height: 24; radius: 8; y: parent.height * 0.62 - 10; x: 16 + demos.t * (parent.width - 32 - width); color: "transparent"; border.width: 1.5; border.color: Qt.rgba(1, 1, 1, 0.25) }
                Rectangle { width: 24; height: 24; radius: 8; y: parent.height * 0.62 - 10; x: 16 + demos.e * (parent.width - 32 - width); color: Theme.accent }
            }
            Rectangle {   // crescer
                width: parent.width; height: demos.bh; radius: 12
                color: Theme.card; border.width: 1; border.color: Theme.border; clip: true
                UiText { x: 12; y: 8; text: "Crescer"; color: Theme.muted; font.pixelSize: 11; font.weight: Font.DemiBold }
                Rectangle { anchors.centerIn: parent; anchors.verticalCenterOffset: 8; width: 46; height: 46; radius: 12; color: "transparent"; border.width: 1.5; border.color: Qt.rgba(1, 1, 1, 0.18); scale: 0.3 + 0.7 * demos.t }
                Rectangle {
                    anchors.centerIn: parent; anchors.verticalCenterOffset: 8
                    width: 46; height: 46; radius: 12; color: Theme.accent
                    opacity: Math.max(0, Math.min(1, demos.e * 2)); scale: Math.max(0, 0.3 + 0.7 * demos.e)
                    UiIcon { anchors.centerIn: parent; name: "apps"; size: 22; color: Theme.accentText }
                }
            }
            Rectangle {   // painel da moldura
                width: parent.width; height: demos.bh; radius: 12
                color: Theme.card; border.width: 1; border.color: Theme.border; clip: true
                UiText { x: 12; y: 8; text: "Painel"; color: Theme.muted; font.pixelSize: 11; font.weight: Font.DemiBold }
                Item {
                    id: scr
                    anchors { fill: parent; margins: 10; topMargin: 26 }
                    Rectangle { anchors.fill: parent; radius: 6; color: "transparent"; border.width: 3; border.color: Theme.cardHi }
                    Rectangle {
                        readonly property real full: scr.height * 0.7
                        width: scr.width * 0.5; height: 3 + (full - 3) * Math.max(0, demos.e)
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                        radius: 6; color: Theme.cardHi
                        Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 6; color: Theme.cardHi }
                    }
                }
            }
        }
    }

    // ---- biblioteca: cartoes com a miniatura de cada animacao ----
    SetSection {
        title: "Biblioteca"; icon: "animation"; subtitle: "Escolha uma para ver e editar; passe o mouse para ver andando"
        SetExpander {
            icon: page.isSpring ? "wave" : "curve"; label: page.cur.name; description: page.locked ? "Do sistema (só leitura): duplique para editar" : (page.isSpring ? "Mola" : "Curva") + " sua"
            open: true
            lazy: Component {
                Column {
                    width: parent ? parent.width : 300
                    Repeater {
                        model: [["Curvas", "bcurve"], ["Molas", "bspring"], ["Suas curvas", "curve"], ["Suas molas", "spring"]]
                        delegate: SetChoice {
                            id: grp
                            required property var modelData
                            width: parent ? parent.width : 300
                            readonly property var opts: page.names.filter(n => {
                                const a = Settings.findAnim(n)
                                if (!a) return false
                                const k = (a.builtin ? "b" : "") + (a.type === "spring" ? "spring" : "curve")
                                return k === grp.modelData[1]
                            }).map(n => [n, n, "curve"])
                            visible: opts.length > 0
                            sub: true
                            label: modelData[0]
                            style: "tiles"; minTile: 92; thumbHeight: 52
                            options: opts
                            value: page.sel
                            onPicked: v => page.sel = v
                            thumb: Item {
                                id: th
                                property var opt
                                property bool on
                                property bool hovered
                                readonly property var a: opt ? Settings.findAnim(opt[0]) : null
                                CurveThumb { anchors.centerIn: parent; width: Math.min(parent.width, parent.height) - 4; height: width; pad: 4; anim: th.a; stroke: th.on ? Theme.accent : Theme.muted; playing: th.hovered }
                            }
                        }
                    }
                }
            }
        }
        SetRow {
            icon: "plus"; label: "Criar e duplicar"
            UiButton { icon: "curve"; text: "Curva"; kind: "ghost"; onClicked: page.newCurve() }
            UiButton { icon: "wave"; text: "Mola"; kind: "ghost"; onClicked: page.newSpring() }
            UiButton { icon: "cards"; text: page.locked ? "Duplicar para editar" : "Duplicar"; kind: page.locked ? "accent" : "ghost"; onClicked: page.sel = Settings.addAnim(page.cur) }
            UiButton { visible: !page.locked; icon: "trash"; kind: "danger"; onClicked: { const n = page.cur.name; page.sel = "Padrão"; Settings.removeAnim(n) } }
        }
    }

    // ---- editor ----
    SetSection {
        title: "Ajustes da animação"; icon: page.locked ? "lock" : "tune"
        subtitle: page.locked ? "Animação do sistema: dá para ver e testar" : page.isSpring ? "Rigidez acelera, amortecimento segura o balanço, massa dá peso" : "Arraste os pinos no gráfico (Shift encaixa de 5 em 5)"
        SetRow {
            visible: !page.locked
            icon: "pencil"; label: "Nome e tipo"
            UiField { width: 160; text: page.cur.name; onEditingFinished: page.sel = Settings.renameAnim(page.cur.name, text) }
            UiSeg {
                options: [["bezier", "Curva", "curve"], ["spring", "Mola", "wave"]]
                value: page.isSpring ? "spring" : "bezier"
                onPicked: v => {
                    if (v === "spring") page.set({ type: "spring", mass: page.cur.mass ?? 1, stiffness: page.cur.stiffness ?? 238, dampening: page.cur.dampening ?? 24 })
                    else page.set({ type: "bezier", x1: page.cur.x1 ?? 5, y1: page.cur.y1 ?? 70, x2: page.cur.x2 ?? 10, y2: page.cur.y2 ?? 100, duration: page.cur.duration ?? page.comp.duration })
                }
            }
        }
        SetSlider { visible: !page.isSpring; icon: "timer"; label: "Duração"; from: 50; to: 1500; step: 10; unit: " ms"; def: 300; enabled: !page.locked; value: page.cur.duration ?? 300; onMoved: v => page.set({ duration: Math.round(v / 10) * 10 }) }
        SetSlider { visible: page.isSpring; icon: "speed"; label: "Rigidez"; description: "Mais alta = mais rápida"; from: 20; to: 1000; enabled: !page.locked; value: page.cur.stiffness ?? 200; onMoved: v => page.set({ stiffness: Math.round(v) }) }
        SetSlider { visible: page.isSpring; icon: "wave"; label: "Amortecimento"; description: "Mais baixo = balança mais"; from: 2; to: 80; enabled: !page.locked; value: Math.round(page.cur.dampening ?? 20); onMoved: v => page.set({ dampening: Math.round(v) }) }
        SetSlider { visible: page.isSpring; icon: "gauge"; label: "Massa"; description: "Em décimos (10 = 1,0)"; from: 5; to: 40; enabled: !page.locked; value: Math.round((page.cur.mass ?? 1) * 10); onMoved: v => page.set({ mass: Math.round(v) / 10 }) }
        SetBlock {
            Flow {
                width: parent.width
                spacing: 8
                Repeater {
                    model: [
                        ["timer", "Duração", () => page.comp.duration + " ms"],
                        ["check", "Parece pronta em", () => Math.round(ed.ready * page.comp.duration) + " ms"],
                        ["arrowUp", "Passa do ponto", () => page.comp.overshoot > 0.5 ? Math.round(page.comp.overshoot) + "%" : "não"],
                        ["wave", "Balanços", () => page.isSpring ? String(page.comp.swings) : "—"],
                        ["speed", "Com a velocidade geral", () => Motion.speed === 1 ? "igual" : Math.round(page.comp.duration / Motion.speed) + " ms"]
                    ]
                    delegate: Rectangle {
                        id: stat
                        required property var modelData
                        height: 40; width: sc.implicitWidth + 24; radius: 10
                        color: Theme.track; border.width: 1; border.color: Theme.border
                        Row {
                            id: sc
                            anchors.centerIn: parent
                            spacing: 8
                            UiIcon { name: stat.modelData[0]; size: 14; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                UiText { text: stat.modelData[1]; color: Theme.muted; font.pixelSize: 10 }
                                UiText { text: stat.modelData[2](); color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                            }
                        }
                    }
                }
            }
            Flow {
                width: parent.width
                spacing: 6
                UiText { text: page.usedIn.length ? "Em uso em:" : "Ainda não está em uso"; color: Theme.muted; font.pixelSize: 12; height: 24; verticalAlignment: Text.AlignVCenter }
                Repeater {
                    model: page.usedIn
                    delegate: Rectangle {
                        required property var modelData
                        height: 24; width: ul.implicitWidth + 16; radius: 12
                        color: Theme.tint(0.14); border.width: 1; border.color: Theme.tint(0.4)
                        UiText { id: ul; anchors.centerIn: parent; text: modelData.label; color: Theme.text; font.pixelSize: 11 }
                    }
                }
            }
        }
        SetRow {
            icon: "play"; label: "Reprodução"; description: page.toast !== "" ? page.toast : "Também toca com o mouse sobre a prévia"
            UiButton { icon: page.loop ? "pause" : "play"; text: page.loop ? "Pausar" : "Em loop"; kind: page.loop ? "accent" : "normal"; onClicked: page.loop = !page.loop }
            UiButton { icon: "refresh"; kind: "ghost"; onClicked: { page.loop = true; ed.replay() } }
            UiButton { icon: "timer"; text: "Lenta"; checked: page.slow; onClicked: page.slow = !page.slow }
        }
        SetExpander {
            visible: !page.isSpring
            icon: "curve"; label: "Valores exatos e CSS"; description: "X1, Y1, X2, Y2 e cubic-bezier"
            SetBlock {
                sub: true
                Row {
                    spacing: 8
                    Repeater {
                        model: [["x1", "X1", false], ["y1", "Y1", true], ["x2", "X2", false], ["y2", "Y2", true]]
                        delegate: Row {
                            required property var modelData
                            spacing: 5
                            UiText { text: modelData[1]; color: Theme.muted; font.pixelSize: 12; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
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
                Row {
                    spacing: 6
                    UiButton { icon: "cards"; text: "Copiar CSS"; kind: "ghost"; onClicked: { Quickshell.clipboardText = page.css; page.say("Copiado: " + page.css) } }
                    UiButton {
                        visible: !page.locked
                        icon: "send"; text: "Colar CSS"; kind: "ghost"
                        onClicked: {
                            const n = (Quickshell.clipboardText.match(/-?\d*\.?\d+/g) || []).map(parseFloat)
                            if (n.length < 4) { page.say("A área de transferência não tem um cubic-bezier(…)"); return }
                            const cx = v => Math.round(Math.max(0, Math.min(1, v)) * 100), cy = v => Math.round(Math.max(-0.5, Math.min(1.5, v)) * 100)
                            page.set({ x1: cx(n[0]), y1: cy(n[1]), x2: cx(n[2]), y2: cy(n[3]) })
                            page.say("Curva colada")
                        }
                    }
                }
            }
        }
        SetExpander {
            visible: !page.locked
            icon: "layers"; label: "Começar de um modelo"; description: page.isSpring ? "Molas prontas" : "Curvas prontas"
            lazy: Component {
                SetBlock {
                    sub: true
                    Flow {
                        width: parent.width
                        spacing: 6
                        Repeater {
                            model: page.isSpring ? [["Firme", 1, 400, 40], ["Padrão do Hyprland", 1, 238, 24.2], ["Macia", 1, 170, 26], ["Elástica", 1, 320, 15], ["Quique", 1, 420, 11], ["Pesada", 2.5, 260, 40], ["Gelatina", 1, 120, 6]]
                                : [["Suave", 25, 10, 25, 100], ["Entrada", 42, 0, 100, 100], ["Saída", 0, 0, 58, 100], ["Entrada e saída", 42, 0, 58, 100],
                                   ["Desacelera forte", 5, 70, 10, 100], ["Ênfase (saída)", 30, 0, 80, 15], ["Volta (back)", 34, 156, 64, 100], ["Antecipa", 36, -40, 60, 100]]
                            delegate: UiButton {
                                required property var modelData
                                text: modelData[0]; kind: "ghost"
                                onClicked: page.isSpring ? page.set({ mass: modelData[1], stiffness: modelData[2], dampening: modelData[3] }) : page.set({ x1: modelData[1], y1: modelData[2], x2: modelData[3], y2: modelData[4] })
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- troca de workspace: estilo proprio, vale mesmo com o Hyprland usando o animations.lua dele ----
    readonly property var wsOpts: [["", "Do Hyprland", "cog"], ["slide", "Deslizar", "arrow_right"], ["slidevert", "Vertical", "arrowDown"],
        ["slidefade 20%", "Deslizar + fade", "arrow_right"], ["slidefadevert 20%", "Vertical + fade", "arrowDown"], ["fade", "Fade", "opacity"], ["none", "Nenhuma", "close"]]
    readonly property string ws: (Settings.animCfg ?? {}).ws ?? ""
    // wallpapers de verdade nas miniaturas: o atual e o proximo da lista
    readonly property string thA: Wallpaper.current !== "" ? Wallpaper.stillUrl(Wallpaper.current) : ""
    readonly property string thB: {
        const fl = Wallpaper.files
        if (!fl || fl.length < 2) return thA
        let i = 0
        for (let k = 0; k < fl.length; k++) if (fl[k].path === Wallpaper.current) { i = k; break }
        return Wallpaper.stillUrl(fl[(i + 1) % fl.length].path)
    }
    SetSection {
        title: "Troca de workspace"; icon: "swap_horizontal"; subtitle: "Como a tela muda ao ir para outro workspace. Passe o mouse para ver"
        SetChoice {
            label: ""
            style: "tiles"; minTile: 96; thumbHeight: 54
            options: page.wsOpts
            value: page.ws
            onPicked: v => Settings.setAnimCfg({ ws: v })
            thumb: Item {
                id: wt
                property var opt
                property bool on
                property bool hovered
                readonly property string st: opt ? opt[0] : ""
                readonly property bool vert: st.indexOf("vert") >= 0
                readonly property bool fades: st.indexOf("fade") >= 0
                readonly property real far: st === "fade" || st === "none" ? 0 : fades ? 0.2 : 1   // quanto anda (fracao da tela)
                UiIcon { visible: wt.st === ""; anchors.centerIn: parent; name: "cog"; size: 20; color: wt.on ? Theme.accent : Theme.muted }
                Item {
                    id: wd
                    visible: wt.st !== ""
                    anchors.fill: parent
                    clip: true
                    property real p: 0.5   // parado no meio da troca; com o mouse em cima, ensaia em loop
                    NumberAnimation on p { running: wt.hovered && wt.st !== ""; from: 0; to: 1; duration: 1200; loops: Animation.Infinite; easing.type: Easing.InOutCubic; onRunningChanged: if (!running) wd.p = 0.5 }
                    Rectangle { anchors.fill: parent; radius: 9; color: Theme.track }
                    Repeater {
                        model: 2   // 0 = workspace que sai, 1 = o que entra
                        delegate: Rectangle {
                            required property int index
                            readonly property real t: index === 0 ? -wd.p : 1 - wd.p   // posicao relativa: 0 = na tela
                            width: wd.width; height: wd.height; radius: 9
                            color: Theme.track
                            clip: true
                            Image {
                                anchors.fill: parent
                                source: index === 0 ? page.thA : page.thB; sourceSize: Qt.size(192, 108)
                                fillMode: Image.PreserveAspectCrop; asynchronous: true; smooth: true
                            }
                            x: wt.vert ? 0 : t * wd.width * wt.far
                            y: wt.vert ? t * wd.height * wt.far : 0
                            opacity: wt.st === "none" ? ((index === 1) === (wd.p >= 0.5) ? 1 : 0) : wt.fades ? 1 - Math.abs(t) : 1
                            // janelinhas de cada workspace
                            Rectangle { x: 6; y: 6; width: parent.width * (index === 0 ? 0.42 : 0.6) - 9; height: parent.height - 12; radius: 4; color: "white"; opacity: 0.3; border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.4) }
                            Rectangle { x: parent.width * (index === 0 ? 0.42 : 0.6) + 3; y: 6; width: parent.width * (index === 0 ? 0.58 : 0.4) - 9; height: index === 0 ? parent.height - 12 : (parent.height - 15) / 2; radius: 4; color: "white"; opacity: 0.25; border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.4) }
                            Rectangle { visible: index === 1; x: parent.width * 0.6 + 3; y: 9 + (parent.height - 15) / 2; width: parent.width * 0.4 - 9; height: (parent.height - 15) / 2; radius: 4; color: "white"; opacity: 0.25; border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.4) }
                        }
                    }
                }
            }
        }
        SetSlider {
            enabled: page.ws !== "" && page.ws !== "none"
            icon: "timer"; label: "Duração"
            description: page.ws === "" ? "Escolha um estilo para ajustar" : (page.ws !== "none" && !((Settings.animCfg ?? {}).wsMs > 0)) ? "A de \"Trocar de workspace\" em Onde cada animação é usada (" + Motion.durationOf("hyprWorkspaces", false) + " ms)" : ""
            from: 0; to: 1500; step: 25; unit: " ms"; zeroLabel: "Auto"; def: 0
            value: (Settings.animCfg ?? {}).wsMs ?? 0
            onMoved: v => Settings.setAnimCfg({ wsMs: Math.round(v / 25) * 25 })
        }
    }

    // ---- velocidade ----
    SetSection {
        title: "Velocidade"; icon: "speed"; subtitle: "Acelera ou desacelera tudo de uma vez, inclusive as janelas se o Hyprland segue o shell"
        SetSlider {
            icon: "speed"; label: "Velocidade geral"; from: 25; to: 300; step: 5; unit: " %"; def: 100
            value: Math.round(Motion.speed * 100)
            onMoved: v => Settings.setAnimCfg({ speed: Math.round(v / 5) * 5 / 100 })
        }
        SetChoice {
            icon: "timer"; label: "Atalhos"
            options: [[50, "Calma"], [100, "Normal"], [150, "Ágil"], [200, "Rápida"]]
            value: Math.round(Motion.speed * 100)
            onPicked: v => Settings.setAnimCfg({ speed: v / 100 })
        }
    }

    // ---- onde cada uma e usada: um expansor por grupo; as linhas so existem com o grupo aberto ----
    SetSection {
        title: "Onde cada animação é usada"; icon: "layers"; subtitle: "Abra um grupo, clique num lugar e troque a animação de abrir e de fechar"
        Repeater {
            model: Settings.animGroups
            delegate: SetExpander {
                id: grp
                required property var modelData
                readonly property bool isHypr: modelData.id === "hypr"
                icon: modelData.icon; label: modelData.label
                description: isHypr ? (page.hypr ? "O Hyprland segue estas animações" : "Desligado: as janelas usam o animations.lua do Hyprland") : Settings.animTargets.filter(t => t.group === modelData.id).length + " lugares"
                checked: isHypr ? page.hypr : undefined
                onToggled: on => Settings.setAnimCfg({ hypr: on })
                lazy: Component {
                    Column {
                        width: parent.width
                        SetChoice {
                            visible: grp.isHypr && page.hypr; sub: true; label: "Janelas"
                            options: Settings.hyprStyleOptions.windows
                            value: (Settings.animCfg.hyprStyle ?? {}).windows ?? Settings.hyprStyleDefaults.windows
                            onPicked: v => { const st = Object.assign({}, Settings.animCfg.hyprStyle ?? {}); st.windows = v; Settings.setAnimCfg({ hyprStyle: st }) }
                        }
                        SetChoice {
                            visible: grp.isHypr && page.hypr; sub: true; label: "Camadas"
                            options: Settings.hyprStyleOptions.layers
                            value: (Settings.animCfg.hyprStyle ?? {}).layers ?? Settings.hyprStyleDefaults.layers
                            onPicked: v => { const st = Object.assign({}, Settings.animCfg.hyprStyle ?? {}); st.layers = v; Settings.setAnimCfg({ hyprStyle: st }) }
                        }
                        Repeater {
                            model: Settings.animTargets.filter(t => t.group === grp.modelData.id)
                            delegate: Column {
                                id: row
                                required property var modelData
                                readonly property bool open: page.openRow === modelData.id
                                width: parent.width
                                opacity: grp.isHypr && !page.hypr ? 0.45 : 1
                                SetRow {
                                    sub: true; divider: true; rowClick: true
                                    label: row.modelData.label
                                    onClicked: page.openRow = row.open ? "" : row.modelData.id
                                    Chip { phase: "abrir"; visible: !!row.modelData.phases; name: Motion.nameFor(row.modelData.id, false) }
                                    Chip { phase: row.modelData.phases ? "fechar" : ""; name: Motion.nameFor(row.modelData.id, !!row.modelData.phases) }
                                    UiButton { visible: Motion.canTest(row.modelData.id); icon: "play"; kind: "ghost"; onClicked: Motion.test(row.modelData.id) }
                                    UiIcon { name: "chevDown"; size: 18; color: Theme.muted; rotation: row.open ? 180 : 0 }
                                }
                                Loader {
                                    active: row.open
                                    asynchronous: true
                                    width: parent.width
                                    height: item ? item.height : 0
                                    sourceComponent: SetBlock { sub: true; AnimPicker { width: parent.width; target: row.modelData.id; expanded: true } }
                                }
                            }
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
            UiText { visible: ch.phase !== ""; text: ch.phase; color: Theme.muted; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
            UiText { text: ch.name; color: Theme.text; font.pixelSize: 11; font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea { id: chm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.sel = ch.name }
    }
}
