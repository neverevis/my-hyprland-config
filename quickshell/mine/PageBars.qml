// Pagina "Barras e moldura" (kit Set*): mapa ao vivo da tela no topo, a moldura (janela de configuracoes, composicao, contorno,
// curvas), as barras (escolha, estilos prontos em cartoes, posicao, esconder), secoes e modulos (cada modulo e uma linha que abre
// as opcoes dele so quando aberto), indicador de volume e detalhes/ilha. O avancado fica nos expansores.
import Quickshell
import QtQuick

SetPage {
    id: page
    title: "Barras e moldura"
    subtitle: (Settings.bars.length === 1 ? "1 barra" : Settings.bars.length + " barras") + ". O mapa mostra onde cada uma está agora."
    property var geo: ({})
    property int cur: 0
    property int openMod: -1     // modulo com o painel aberto
    property string openKind: "opts"   // "opts" (opcoes) ou "style" (pilula)
    property int curSec: 0       // secao selecionada da barra
    readonly property var secs: Settings.sectionsOf(bar)
    readonly property int sec: Math.max(0, Math.min(curSec, secs.length - 1))
    readonly property int idx: Math.max(0, Math.min(cur, Settings.bars.length - 1))
    readonly property var bar: Settings.bars[idx] ?? null
    readonly property var info: geo && geo.bars ? geo.bars[idx] : null
    readonly property var sideNames: ({ top: "Cima", bottom: "Baixo", left: "Esquerda", right: "Direita" })
    readonly property var modIcons: ({ clock: "clock", workspaces: "view_grid", window: "fullscreen", cpu: "chip", memory: "memory", volume: "volume", tray: "apps", palette: "palette", power: "power", text: "pencil",
        media: "music", weather: "wPartly", netspeed: "network", gpu: "gpuCard", temp: "temperature", updates: "download", keyboard: "keyboard",
        notifs: "bell", recorder: "monitor", utils: "frame", caffeine: "coffee", battery: "battery", bluetooth: "bluetooth", sysicons: "devices", launcher: "apps", visualizer: "wave", taskbar: "dock",
        island: "pulse", privacy: "eye", divisor: "alignVCenter", disk: "disk", swap: "swap_vertical", aiusage: "robot", avatar: "account", livewall: "wallpaper" })
    function setBar(k, v) { Settings.setBar(idx, k, v) }
    function setSec(k, v) { Settings.setSection(idx, sec, k, v) }
    readonly property var secObj: secs[sec] ?? null
    // estilos prontos: cada um e um conjunto de opcoes da barra e das secoes dela
    readonly property var styles: [["hug", "Na moldura", "frame"], ["plain", "Reta", "squareRounded"], ["float", "Solta", "cards"], ["panel", "Painel", "dock"], ["islands", "Ilhas", "dotsGrid"], ["m3", "Cores do tema", "palette"]]
    function applyStyle(id) {
        Settings.mutate(b => {
            const x = b[idx]; if (!x) return
            delete x.fillet; delete x.topRadius
            x.detached = false; x.noBg = false; x.border = false; x.shadow = false
            for (const sc of x.sections) { sc.bg = false; sc.groupStyle = "section"; sc.bgRole = ""; delete sc.bgAlpha }
            if (id === "plain") { x.fillet = 0; x.topRadius = 0 }
            else if (id === "float") { x.detached = true; x.gap = 8; x.radius = 14; x.border = true }
            else if (id === "panel") { x.detached = true; x.gap = 6; x.radius = 12; x.border = true; x.shadow = true }
            else if (id === "islands") { x.noBg = true; for (const sc of x.sections) { sc.groupStyle = "pills"; sc.bgRole = "surfaceHigh"; sc.bgAlpha = 85 } }
            else if (id === "m3") { x.noBg = true; for (const sc of x.sections) { sc.groupStyle = "pills"; sc.bgRole = "primaryContainer"; sc.bgAlpha = 100 } }
        })
    }
    // o mesmo que o estilo "abas" do end4: cada secao vira uma barrinha propria (inicio / centro / fim), presa na moldura
    function splitTabs() {
        Settings.mutate(b => {
            const x = b[idx]; if (!x) return
            const sc = x.sections, n = sc.length
            const pos = n === 1 ? [50] : n === 2 ? [0, 100] : [0, 50, 100]
            const groups = []
            if (n <= 3) sc.forEach(q => groups.push([q]))
            else groups.push([sc[0]], sc.slice(1, n - 1), [sc[n - 1]])
            const nb = groups.map((g, k) => Object.assign({}, x, { name: (x.name || "Barra") + " " + (k + 1), fit: true, full: false, pos: pos[k], corner: "", sections: g.map(q => Object.assign({}, q, { anchor: "center", offset: 0, width: 0 })) }))
            b.splice(idx, 1, ...nb)
        })
    }
    // marca as secoes na propria barra enquanto esta pagina esta aberta
    // so a pagina de verdade (a copia escondida que a busca cria para montar o indice nao mexe na depuracao)
    Binding { target: Settings; property: "barDebugBar"; value: page.idx; when: page.visible }
    Binding { target: Settings; property: "barDebugSec"; value: page.sec; when: page.visible }
    Component.onDestruction: if (page.visible) { Settings.barDebugBar = -1; Settings.barDebugSec = -1 }

    // ---- mapa da tela (parado: so muda quando a configuracao muda) ----
    preview: SetPreview {
        height: map.height + 24
        BarsMap {
            id: map
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            geo: page.geo
            selected: page.idx
            selectedSec: page.sec
            onPicked: i => { page.cur = i; page.curSec = 0; page.openMod = -1 }
        }
    }

    // ================= BARRAS =================
    SetSection {
        title: "Suas barras"; icon: "bars"
        SetBlock {
            Flow {
                width: parent.width
                spacing: SetK.sm
                Repeater {
                    model: Settings.bars.length
                    delegate: Rectangle {
                        id: item
                        required property int index
                        readonly property var bd: Settings.bars[index] ?? ({})
                        readonly property bool on: page.idx === index
                        readonly property var inf: page.geo && page.geo.bars ? page.geo.bars[index] : null
                        width: 188; height: 54; radius: 14
                        color: on ? Theme.tint(0.14) : (bm.containsMouse ? Theme.cardHi : Theme.track)
                        border.width: on ? 2 : 1
                        border.color: on ? Theme.accent : Theme.border
                        Rectangle {
                            id: prio
                            x: 10; anchors.verticalCenter: parent.verticalCenter
                            width: 26; height: 26; radius: 13
                            color: item.on ? Theme.accent : Theme.cardHi
                            UiText { anchors.centerIn: parent; text: item.index + 1; color: item.on ? Theme.accentText : Theme.muted; font.pixelSize: 12; font.weight: Font.Bold }
                        }
                        Column {
                            anchors { left: prio.right; leftMargin: 10; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                            spacing: 1
                            UiText { width: parent.width; elide: Text.ElideRight; text: item.bd.name || ("Barra " + (item.index + 1)); color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                            UiText {
                                width: parent.width; elide: Text.ElideRight
                                text: item.inf && item.inf.hidden ? "Sem espaço: escondida"
                                    : (page.sideNames[item.bd.side] ?? "—") + (item.bd.detached ? " · solta" : "") + " · " + Settings.sectionsOf(item.bd).reduce((n, x) => n + x.modules.length, 0) + (Settings.sectionsOf(item.bd).reduce((n, x) => n + x.modules.length, 0) === 1 ? " módulo" : " módulos")
                                color: item.inf && item.inf.hidden ? Theme.danger : Theme.muted; font.pixelSize: 11
                            }
                        }
                        MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { page.cur = item.index; page.curSec = 0; page.openMod = -1 } }
                    }
                }
                Rectangle {
                    width: 54; height: 54; radius: 14
                    color: am.containsMouse ? Theme.cardHi : "transparent"
                    border.width: 1; border.color: Theme.border
                    UiIcon { anchors.centerIn: parent; name: "plus"; size: 20; color: Theme.accent }
                    MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Settings.addBar("top"); page.cur = Settings.bars.length - 1 } }
                }
                Rectangle {
                    width: 54; height: 54; radius: 14
                    color: dkm.containsMouse ? Theme.cardHi : "transparent"
                    border.width: 1; border.color: Theme.border
                    UiIcon { anchors.centerIn: parent; name: "dock"; size: 20; color: Theme.accent }
                    MouseArea { id: dkm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Settings.addDock(); page.cur = Settings.bars.length - 1 } }
                }
            }
            UiText { width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: SetK.fDesc; text: "Mais (+) cria uma barra; o ícone de dock cria um dock. O número é a prioridade: se duas barras do mesmo lado querem o mesmo lugar, a de maior prioridade fica; a outra vai para o espaço livre mais perto e, sem espaço, fica escondida." }
        }
        SetRow {
            visible: Settings.bars.length > 1 && !!page.bar
            icon: "layers"; label: "Prioridade " + (page.idx + 1) + " de " + Settings.bars.length; description: "Da barra escolhida"
            UiButton { icon: "arrowUp"; kind: "ghost"; enabled: page.idx > 0; onClicked: { Settings.moveBar(page.idx, -1); page.cur = page.idx - 1 } }
            UiButton { icon: "arrowDown"; kind: "ghost"; enabled: page.idx < Settings.bars.length - 1; onClicked: { Settings.moveBar(page.idx, 1); page.cur = page.idx + 1 } }
        }
    }

    SetSection {
        visible: !!page.bar
        title: "Barra escolhida"; icon: "frame"
        SetRow {
            icon: "pencil"; label: "Nome"
            UiField { width: 200; text: page.bar ? (page.bar.name ?? "") : ""; placeholderText: "Barra " + (page.idx + 1); onEditingFinished: page.setBar("name", text.trim()) }
        }
        SetRow {
            icon: "dock"; label: "Lado da tela"
            below: SidePick { value: page.bar ? page.bar.side : ""; onPicked: v => page.setBar("side", v) }
        }
        SetChoice {
            icon: "brush"; label: "Estilo pronto"; description: "Mexe nas curvas, no fundo e nas pílulas desta barra de uma vez"
            style: "tiles"; columns: 6; thumbHeight: 52
            options: page.styles
            value: ""
            onPicked: v => page.applyStyle(v)
            thumb: Item {
                id: sg
                property var opt
                property bool on
                property bool hovered
                readonly property string m: opt ? opt[0] : "hug"
                readonly property bool det: m === "float" || m === "panel"
                readonly property bool isl: m === "islands" || m === "m3"
                Rectangle { anchors.fill: parent; anchors.margins: 4; radius: 6; color: "transparent"; border.width: 2; border.color: Theme.cardHi }
                Rectangle {   // faixa presa na moldura
                    visible: !sg.isl
                    x: sg.det ? 12 : 10; y: sg.det ? 10 : 4
                    width: parent.width - x * 2; height: 11
                    radius: sg.m === "plain" ? 0 : (sg.det ? 5 : 6)
                    color: Theme.accent
                    border.width: sg.m === "panel" ? 1 : 0; border.color: Theme.text
                }
                Row {   // pilulas
                    visible: sg.isl
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 9 }
                    spacing: 5
                    Repeater {
                        model: 3
                        delegate: Rectangle { required property int index; width: index === 1 ? 16 : 24; height: 9; radius: 4.5; color: sg.m === "m3" ? Theme.primaryContainer : Theme.surfaceHighest }
                    }
                }
            }
        }
        SetRow { icon: "cards"; label: "Solta da moldura"; description: "Flutua afastada, como uma ilha com cantos arredondados"; checked: page.bar ? !!page.bar.detached : false; onToggled: on => page.setBar("detached", on) }
        SetRow { visible: page.bar ? !page.bar.detached : true; icon: "swap_horizontal"; label: "Ocupar o lado inteiro"; description: "De uma ponta à outra da tela"; checked: page.bar ? !!page.bar.full : false; onToggled: on => page.setBar("full", on) }
        SetRow { visible: page.bar ? !page.bar.full : true; icon: "view_column"; label: "Largura do conteúdo"; description: "Cresce e encolhe com os módulos (bom para o dock)"; checked: page.bar ? !!page.bar.fit : false; onToggled: on => page.setBar("fit", on) }
        SetSlider {
            id: wSl
            visible: page.bar ? !page.bar.full && !page.bar.fit : false
            readonly property real sideLen: page.bar && (page.bar.side === "left" || page.bar.side === "right") ? (Quickshell.screens[0] ? Quickshell.screens[0].height : 1080) : (Quickshell.screens[0] ? Quickshell.screens[0].width : 1920)
            icon: "swap_horizontal"; label: "Tamanho"; description: "Em % do lado da tela"; from: 3; to: 100; unit: " %"
            value: page.bar ? Math.round(Settings.barSize(page.bar, sideLen)) : 30; onMoved: v => page.setBar("size", Math.round(v))
        }
        SetSlider {
            id: pSl
            visible: page.bar ? !page.bar.full : false
            readonly property real sideLen: wSl.sideLen
            readonly property bool vert: page.bar ? (page.bar.side === "left" || page.bar.side === "right") : false
            readonly property string msg: !page.info ? "" : (page.info.hidden ? "Sem espaço" : (page.info.corner < 0 ? (vert ? "Encostada no topo" : "Encostada à esquerda") : (page.info.corner > 0 ? (vert ? "Encostada embaixo" : "Encostada à direita") : "")))
            icon: "arrow_right"; label: "Posição"; description: msg !== "" ? msg : "Nas pontas a barra encosta no canto sozinha"; from: 0; to: 100; unit: " %"
            value: page.bar ? Math.round(Settings.barPos(page.bar, sideLen)) : 50
            onMoved: v => { page.setBar("pos", Math.round(v)); page.setBar("corner", "") }
            UiButton { icon: pSl.vert ? "arrowUp" : "arrow_left"; kind: "ghost"; onClicked: { page.setBar("pos", 0); page.setBar("corner", "") } }
            UiButton { icon: "alignCenter"; kind: "ghost"; onClicked: { page.setBar("pos", 50); page.setBar("corner", "") } }
            UiButton { icon: pSl.vert ? "arrowDown" : "arrow_right"; kind: "ghost"; onClicked: { page.setBar("pos", 100); page.setBar("corner", "") } }
        }
        SetSlider { icon: "bars"; label: "Espessura"; from: 24; to: 90; unit: " px"; value: page.bar ? page.bar.height : 0; onMoved: v => page.setBar("height", Math.round(v)) }
        SetRow { icon: "eyeOff"; label: "Sem fundo"; description: "Só os módulos, soltos na tela (combine com pílulas)"; checked: page.bar ? !!page.bar.noBg : false; onToggled: on => page.setBar("noBg", on) }
        SetExpander {
            visible: page.bar ? !!page.bar.detached : false
            icon: "cards"; label: "Barra solta"; description: "Distância, cantos, contorno e sombra"
            SetSlider { sub: true; label: "Distância da moldura"; from: 0; to: 40; unit: " px"; def: 8; value: page.bar ? (page.bar.gap ?? 8) : 8; onMoved: v => page.setBar("gap", Math.round(v)) }
            SetSlider { sub: true; label: "Arredondamento"; from: 0; to: 40; unit: " px"; def: 14; value: page.bar ? (page.bar.radius ?? 14) : 14; onMoved: v => page.setBar("radius", Math.round(v)) }
            SetRow { sub: true; label: "Contorno fino"; checked: page.bar ? !!page.bar.border : false; onToggled: on => page.setBar("border", on) }
            SetRow { sub: true; label: "Sombra"; checked: page.bar ? !!page.bar.shadow : false; onToggled: on => page.setBar("shadow", on) }
        }
        SetExpander {
            visible: page.bar ? !page.bar.detached && !page.bar.full : false
            icon: "curve"; label: "Curvas desta barra"; description: "Sem escolher, valem as da moldura"
            SetSlider { sub: true; label: "Curva da subida"; from: 0; to: 30; unit: " px"; value: page.bar ? (page.bar.fillet ?? Settings.fillet) : 0; onMoved: v => page.setBar("fillet", Math.round(v)) }
            SetSlider { sub: true; label: "Cantos do topo"; from: 0; to: 30; unit: " px"; value: page.bar ? (page.bar.topRadius ?? Settings.topRadius) : 0; onMoved: v => page.setBar("topRadius", Math.round(v)) }
            SetRow {
                sub: true; label: "Atalhos"; description: "Duas em zero: retângulo reto saindo da moldura"
                UiButton { icon: "squareRounded"; text: "Retangular"; kind: "ghost"; onClicked: { page.setBar("fillet", 0); page.setBar("topRadius", 0) } }
                UiButton { icon: "restore"; text: "Da moldura"; kind: "ghost"; enabled: page.bar ? page.bar.fillet !== undefined || page.bar.topRadius !== undefined : false
                    onClicked: Settings.mutate(b => { if (b[page.idx]) { delete b[page.idx].fillet; delete b[page.idx].topRadius } }) }
            }
        }
        SetExpander {
            icon: "eye"; label: "Esconder automaticamente"; description: "Some e reaparece quando o mouse encosta na borda"
            checked: page.bar ? !!page.bar.autoHide : false
            onToggled: on => page.setBar("autoHide", on)
            SetChoice {
                sub: true; label: "Espaço das janelas"
                options: [["overlay", "Sobrepor", "layers"], ["always", "Reservar", "dock"], ["follow", "Acompanhar", "swap_vertical"]]
                value: page.bar ? (page.bar.reserve ?? "overlay") : "overlay"; onPicked: v => page.setBar("reserve", v)
            }
            SetSlider { sub: true; label: "Esperar antes de mostrar"; from: 0; to: 1000; step: 10; unit: " ms"; def: 0; value: Settings.showDelay; onMoved: v => Settings.showDelay = Math.round(v) }
            SetSlider { sub: true; label: "Esperar antes de esconder"; from: 0; to: 2000; step: 10; unit: " ms"; def: 450; value: Settings.hideDelay; onMoved: v => Settings.hideDelay = Math.round(v) }
            SetSlider { sub: true; label: "Faixa que revela a barra"; from: 1; to: 16; unit: " px"; def: 8; value: Settings.barHoverStrip; onMoved: v => Settings.barHoverStrip = Math.round(v) }
            SetRow { sub: true; label: "Revelar em qualquer ponto da borda"; description: "A faixa corre o lado inteiro (todas as barras escondidas dele)"; checked: Settings.barEdgeReveal; onToggled: on => Settings.barEdgeReveal = on }
            SetRow { sub: true; label: "Revelar segurando a tecla Super"; description: "Precisa de uma tecla que chame: qs -c mine ipc call bar superdown (e superup)"; checked: Settings.superReveal; onToggled: on => Settings.superReveal = on }
            SetSlider { visible: Settings.superReveal; sub: true; label: "Segurar por"; from: 0; to: 600; step: 20; unit: " ms"; def: 140; value: Settings.superDelay; onMoved: v => Settings.superDelay = Math.round(v / 20) * 20 }
            lazy: Component { SetBlock { sub: true; UiLabel { text: "Animação" } AnimPicker { width: parent.width; target: "bars" } } }
        }
        SetRow {
            icon: "view_column"; label: "Dividir em 3 abas"; description: "Cada seção vira uma barrinha própria presa na moldura"
            UiButton { icon: "view_column"; text: "Dividir"; kind: "ghost"; enabled: page.secs.length > 0; onClicked: { page.splitTabs(); page.curSec = 0; page.openMod = -1 } }
        }
        SetRow {
            icon: BarState.barsOpen ? "eyeOff" : "eye"; label: "Todas as barras de uma vez"; description: "Atalho de teclado: qs -c mine ipc call bar toggle"
            UiButton { text: BarState.barsOpen ? "Esconder todas" : "Mostrar todas"; kind: BarState.barsOpen ? "ghost" : "accent"; onClicked: BarState.barsOpen = !BarState.barsOpen }
        }
        SetRow {
            visible: Settings.bars.length > 1
            icon: "trash"; label: "Remover a barra " + (page.idx + 1)
            UiButton { icon: "trash"; text: "Remover barra"; kind: "danger"; onClicked: { Settings.removeBar(page.idx); page.cur = 0 } }
        }
    }

    // ================= SECOES E MODULOS =================
    SetSection {
        visible: !!page.bar
        title: "Seções e módulos"; icon: "view_column"; subtitle: "Cada seção é um grupo de módulos com posição própria"
        SetBlock {
            Flow {
                width: parent.width
                spacing: 6
                Repeater {
                    model: page.secs.length
                    delegate: UiButton {
                        required property int index
                        text: page.secs[index] ? (page.secs[index].name || ("Seção " + (index + 1))) : ""
                        checked: page.sec === index
                        onClicked: { page.curSec = index; page.openMod = -1 }
                    }
                }
                UiButton { icon: "plus"; text: "Nova seção"; kind: "ghost"; onClicked: { Settings.addSection(page.idx); page.curSec = page.secs.length; page.openMod = -1 } }
            }
        }
        SetExpander {
            icon: "tune"; label: "Ajustes da seção"; description: "Posição, alinhamento, tamanho e fundo"
            SetRow { sub: true; label: "Nome"; UiField { width: 180; text: page.secObj ? page.secObj.name : ""; placeholderText: "Seção " + (page.sec + 1); onEditingFinished: Settings.setSection(page.idx, page.sec, "name", text) } }
            SetChoice { sub: true; label: "Posição na barra"; iconsOnly: true; options: [["start", "Início", "alignLeft"], ["center", "Centro", "alignCenter"], ["end", "Fim", "alignRight"]]; value: page.secObj ? (page.secObj.anchor ?? "center") : "center"; onPicked: v => page.setSec("anchor", v) }
            SetChoice { sub: true; label: "Alinhar os módulos"; iconsOnly: true; options: [["start", "Início", "alignLeft"], ["center", "Centro", "alignCenter"], ["end", "Fim", "alignRight"]]; value: page.secObj ? (page.secObj.align ?? "center") : "center"; onPicked: v => page.setSec("align", v) }
            SetSlider { sub: true; label: "Largura"; from: 0; to: 3000; step: 10; unit: " px"; zeroLabel: "Automática"; def: 0; value: page.secObj ? (page.secObj.width ?? 0) : 0; onMoved: v => page.setSec("width", Math.round(v)) }
            SetSlider { sub: true; label: "Deslocamento"; from: -1500; to: 1500; step: 10; unit: " px"; def: 0; value: page.secObj ? (page.secObj.offset ?? 0) : 0; onMoved: v => page.setSec("offset", Math.round(v)) }
            SetSlider { sub: true; label: "Espaço entre módulos"; from: 0; to: 40; unit: " px"; def: 14; value: page.secObj ? (page.secObj.spacing ?? 14) : 14; onMoved: v => page.setSec("spacing", Math.round(v)) }
            SetChoice { sub: true; label: "Estilo do grupo"; options: [["section", "Uma pílula", "circleOutline"], ["pills", "Uma por módulo", "dotsGrid"], ["segmented", "Segmentado", "view_column"]]; value: page.secObj ? (page.secObj.groupStyle ?? "section") : "section"; onPicked: v => page.setSec("groupStyle", v) }
            SetRow { visible: (page.secObj ? (page.secObj.groupStyle ?? "section") : "section") === "section"; sub: true; label: "Fundo em pílula"; description: "Um fundo arredondado atrás dos módulos"; checked: page.secObj ? !!page.secObj.bg : false; onToggled: on => page.setSec("bg", on) }
            SetColor {
                visible: page.secObj ? (!!page.secObj.bg || (page.secObj.groupStyle ?? "section") !== "section") : false
                sub: true; label: "Cor do fundo"; allowNone: true; note: ""
                value: page.secObj ? (page.secObj.bgRole ?? "") : ""; onPicked: v => page.setSec("bgRole", v)
            }
            SetSlider { visible: page.secObj ? (!!page.secObj.bg || (page.secObj.groupStyle ?? "section") !== "section") : false; sub: true; label: "Opacidade do fundo"; from: 4; to: 100; unit: " %"; def: 10; value: page.secObj ? (page.secObj.bgAlpha ?? 10) : 10; onMoved: v => page.setSec("bgAlpha", Math.round(v)) }
            SetRow { visible: page.secObj ? (!!page.secObj.bg || (page.secObj.groupStyle ?? "section") !== "section") : false; sub: true; label: "Contorno na cor de destaque"; checked: page.secObj ? !!page.secObj.bgBorder : false; onToggled: on => page.setSec("bgBorder", on) }
            SetRow { visible: page.secs.length > 1; sub: true; label: "Remover esta seção"; UiButton { icon: "trash"; text: "Remover seção"; kind: "danger"; onClicked: { Settings.removeSection(page.idx, page.sec); page.curSec = 0; page.openMod = -1 } } }
        }
        Repeater {
            model: page.secObj ? page.secObj.modules.length : 0
            delegate: Column {
                id: mrow
                required property int index
                readonly property var mod: (page.secObj && page.secObj.modules[index]) ?? ({})
                readonly property string mtype: mod.type ?? ""
                readonly property bool hasField: mtype === "clock" || mtype === "text"
                readonly property bool isMeter: mtype === "cpu" || mtype === "memory" || mtype === "volume" || mtype === "disk" || mtype === "swap"
                readonly property var schema: BarModules.schema(mtype)
                readonly property bool hasOpts: mtype === "workspaces" || isMeter || mtype === "tray" || mtype === "palette" || schema.length > 0
                readonly property bool optsOpen: hasOpts && page.openMod === index && page.openKind === "opts"
                readonly property bool styleOpen: page.openMod === index && page.openKind === "style"
                readonly property bool anyOpen: optsOpen || styleOpen
                width: parent.width
                function set(k, v) { Settings.setModuleOpt(page.idx, page.sec, index, k, v) }
                SetRow {
                    icon: page.modIcons[mrow.mtype] ?? "apps"
                    label: (Settings.moduleTypes.find(t => t.type === mrow.mtype) ?? { label: mrow.mtype }).label
                    divider: true
                    rowClick: mrow.hasOpts
                    below: UiField {
                        visible: mrow.hasField
                        width: parent ? parent.width : 300; height: mrow.hasField ? 34 : 0
                        text: mrow.mtype === "clock" ? (mrow.mod.format ?? "") : (mrow.mod.text ?? "")
                        placeholderText: mrow.mtype === "clock" ? "formato, ex.: ddd HH:mm" : "texto"
                        onEditingFinished: mrow.set(mrow.mtype === "clock" ? "format" : "text", text)
                    }
                    onClicked: { page.openKind = "opts"; page.openMod = mrow.optsOpen ? -1 : mrow.index }
                    UiButton { visible: mrow.hasOpts; icon: "tune"; kind: "ghost"; checked: mrow.optsOpen; onClicked: { page.openKind = "opts"; page.openMod = mrow.optsOpen ? -1 : mrow.index } }
                    UiButton { icon: "brush"; kind: "ghost"; checked: mrow.styleOpen; onClicked: { page.openKind = "style"; page.openMod = mrow.styleOpen ? -1 : mrow.index } }
                    UiButton { visible: page.secs.length > 1; icon: "swap_horizontal"; kind: "ghost"; onClicked: { page.openMod = -1; Settings.moveModuleTo(page.idx, page.sec, mrow.index, (page.sec + 1) % page.secs.length) } }
                    UiButton { icon: "arrowUp"; kind: "ghost"; enabled: mrow.index > 0; onClicked: Settings.moveModule(page.idx, page.sec, mrow.index, -1) }
                    UiButton { icon: "arrowDown"; kind: "ghost"; enabled: mrow.index < page.secObj.modules.length - 1; onClicked: Settings.moveModule(page.idx, page.sec, mrow.index, 1) }
                    UiButton { icon: "trash"; kind: "ghost"; onClicked: { page.openMod = -1; Settings.removeModule(page.idx, page.sec, mrow.index) } }
                }
                Loader {
                    active: mrow.anyOpen
                    asynchronous: true
                    width: parent.width
                    height: item ? item.height : 0
                    sourceComponent: mrow.styleOpen ? styleC : (mrow.mtype === "workspaces" ? wsC : (mrow.isMeter || mrow.mtype === "tray" || mrow.mtype === "palette") ? meterC : schemaC)
                    Component {
                        id: styleC
                        Column {
                            width: parent.width
                            SetRow { sub: true; label: "Pílula própria"; description: "Um fundo só deste módulo"; checked: mrow.mod.group ?? ((page.secObj.groupStyle ?? "section") === "pills"); onToggled: on => mrow.set("group", on) }
                            SetColor { sub: true; label: "Cor da pílula"; allowNone: true; value: mrow.mod.bgRole ?? ""; onPicked: v => mrow.set("bgRole", v) }
                            SetSlider { sub: true; label: "Opacidade"; from: 4; to: 100; unit: " %"; value: mrow.mod.bgAlpha ?? (page.secObj.bgAlpha ?? 14); onMoved: v => mrow.set("bgAlpha", Math.round(v)) }
                            SetSlider { sub: true; label: "Folga nas laterais"; from: 2; to: 24; unit: " px"; def: 9; value: mrow.mod.bgPad ?? 9; onMoved: v => mrow.set("bgPad", Math.round(v)) }
                            SetSlider { sub: true; label: "Arredondamento"; from: 0; to: 24; unit: " px"; zeroLabel: "Redonda"; def: 0; value: mrow.mod.bgRadius ?? 0; onMoved: v => mrow.set("bgRadius", v > 0 ? Math.round(v) : undefined) }
                            SetRow { sub: true; label: "Contorno"; checked: !!mrow.mod.bgBorder; onToggled: on => mrow.set("bgBorder", on) }
                            SetRow { sub: true; label: "Voltar ao padrão"; UiButton { icon: "restore"; kind: "ghost"; onClicked: Settings.mutate(b => { const m = b[page.idx].sections[page.sec].modules[mrow.index]; for (const k of ["group", "bgRole", "bgAlpha", "bgPad", "bgRadius", "bgBorder"]) delete m[k] }) } }
                        }
                    }
                    Component {
                        id: schemaC
                        SetBlock {
                            sub: true
                            OptionsForm {
                                width: parent.width
                                schema: mrow.schema
                                get: k => BarModules.value(mrow.mod, k)
                                set: (k, v) => mrow.set(k, v)
                                isShown: d => BarModules.shown(mrow.mod, d)
                            }
                        }
                    }
                    Component {
                        id: meterC
                        Column {
                            id: mc
                            width: parent.width
                            readonly property string disp: mrow.mod.display ?? "text"
                            readonly property bool isCpuMem: mrow.mtype === "cpu" || mrow.mtype === "memory" || mrow.mtype === "disk" || mrow.mtype === "swap"
                            readonly property bool isRound: disp === "ring" || disp === "disc"
                            readonly property int warnDef: ({ cpu: 90, memory: 95, disk: 90, swap: 85 })[mrow.mtype] ?? 85
                            // bandeja
                            SetSlider { visible: mrow.mtype === "tray"; sub: true; label: "Tamanho dos ícones"; from: 12; to: 32; unit: " px"; def: 18; value: mrow.mod.size ?? 18; onMoved: v => mrow.set("size", Math.round(v)) }
                            SetSlider { visible: mrow.mtype === "tray"; sub: true; label: "Espaçamento"; from: 0; to: 20; unit: " px"; def: 8; value: mrow.mod.spacing ?? 8; onMoved: v => mrow.set("spacing", Math.round(v)) }
                            // cores do tema
                            SetSlider { visible: mrow.mtype === "palette"; sub: true; label: "Tamanho das bolinhas"; from: 8; to: 28; unit: " px"; def: 14; value: mrow.mod.size ?? 14; onMoved: v => mrow.set("size", Math.round(v)) }
                            SetSlider { visible: mrow.mtype === "palette"; sub: true; label: "Espaçamento"; from: 0; to: 14; unit: " px"; def: 5; value: mrow.mod.spacing ?? 5; onMoved: v => mrow.set("spacing", Math.round(v)) }
                            SetChoice { visible: mrow.mtype === "palette"; sub: true; label: "Quais"; options: [["all", "Todas"], ["accents", "Destaques"], ["surfaces", "Superfícies"]]; value: mrow.mod.set ?? "all"; onPicked: v => mrow.set("set", v) }
                            // medidores
                            SetChoice {
                                visible: mrow.isMeter
                                sub: true; label: "Exibição"
                                style: "tiles"; minTile: 90; thumbHeight: 34
                                options: mc.isCpuMem ? [["text", "Texto", "alignLeft"], ["bar", "Barra", "bars"], ["graph", "Gráfico", "wave"], ["segments", "Segmentos", "dotsGrid"], ["ring", "Anel", "circleOutline"], ["disc", "Disco", "disc"]]
                                    : [["text", "Texto", "alignLeft"], ["bar", "Barra", "bars"], ["segments", "Segmentos", "dotsGrid"], ["slider", "Ícone + barra", "tune"], ["ring", "Anel", "circleOutline"], ["disc", "Disco", "disc"]]
                                value: mc.disp; onPicked: v => mrow.set("display", v)
                            }
                            SetRow { visible: mrow.isMeter; sub: true; label: "Rótulo"; description: "Vazio = sem rótulo"
                                UiField { width: 140; text: mrow.mod.label ?? ({ cpu: "CPU", memory: "RAM", disk: "DSK", swap: "SWP" })[mrow.mtype] ?? "VOL"; onEditingFinished: mrow.set("label", text) } }
                            SetRow { visible: mrow.isMeter; sub: true; label: "Mostrar o valor em número"; checked: mrow.mod.showValue ?? (mc.disp === "text"); onToggled: on => mrow.set("showValue", on) }
                            SetSlider { visible: mrow.isMeter && mc.disp !== "text" && !mc.isRound; sub: true; label: "Largura"; from: 20; to: 200; unit: " px"; def: 60; value: mrow.mod.width ?? 60; onMoved: v => mrow.set("width", Math.round(v)) }
                            SetSlider { visible: mrow.isMeter && mc.disp !== "text"; sub: true; label: mc.isRound ? "Tamanho" : "Altura"; from: mc.isRound ? 14 : 6; to: 40; unit: " px"; value: mrow.mod.height ?? (mc.isRound ? 22 : 16); onMoved: v => mrow.set("height", Math.round(v)) }
                            SetRow { visible: mc.isCpuMem; sub: true; label: "Cor de alerta"; description: "Amarelo e vermelho quando o uso está alto"; checked: !!mrow.mod.warn; onToggled: on => mrow.set("warn", on) }
                            SetSlider { visible: mc.isCpuMem && !!mrow.mod.warn; sub: true; label: "Vermelho a partir de"; from: 40; to: 100; step: 5; unit: " %"; value: mrow.mod.warnAt ?? mc.warnDef; onMoved: v => mrow.set("warnAt", Math.round(v / 5) * 5) }
                            SetSlider { visible: mc.isCpuMem && mc.disp === "graph"; sub: true; label: "Pontos do gráfico"; from: 10; to: 120; def: 30; value: mrow.mod.points ?? 30; onMoved: v => mrow.set("points", Math.round(v)) }
                            SetSlider { visible: mc.isCpuMem; sub: true; label: "Atualização"; from: 500; to: 5000; step: 100; unit: " ms"; value: mrow.mod.interval ?? (mc.disp === "graph" ? 1000 : 2000); onMoved: v => mrow.set("interval", Math.round(v / 100) * 100) }
                            SetSlider { visible: mrow.mtype === "volume"; sub: true; label: "Passo da roda do mouse"; from: 1; to: 20; unit: " %"; def: 5; value: mrow.mod.step ?? 5; onMoved: v => mrow.set("step", Math.round(v)) }
                            SetSlider { visible: mrow.mtype === "volume" && mc.disp === "segments"; sub: true; label: "Segmentos"; from: 4; to: 16; def: 8; value: mrow.mod.segments ?? 8; onMoved: v => mrow.set("segments", Math.round(v)) }
                            SetBlock { visible: mrow.isMeter; sub: true; ColorField { width: parent.width; label: "Cor"; value: mrow.mod.color ? mrow.mod.color : Settings.textColor; onPicked: c => mrow.set("color", c.toString()) } }
                        }
                    }
                    Component {
                        id: wsC
                        Column {
                            id: wc
                            width: parent.width
                            readonly property string style: mrow.mod.style ?? "numbers"
                            SetChoice {
                                sub: true; label: "Estilo"
                                style: "tiles"; minTile: 100; thumbHeight: 34
                                options: [["numbers", "① Números", "numeric"], ["dots", "• Pontos", "dotsGrid"], ["pills", "━ Pílulas", "pill"], ["squares", "▢ Quadrados", "squareRounded"], ["bars", "| Barras", "bars"], ["ring", "◎ Anel", "circleOutline"],
                                          ["icons", "▣ Ícone do app", "apps"], ["roman", "Ⅳ Romanos", "numeric"], ["kanji", "三 Kanji", "view_grid"], ["custom", "★ Símbolos", "flower"], ["glyphs", "◆ Ícones fixos", "tag"], ["bridge", "⬭ Pílula que viaja", "swap_horizontal"]]
                                value: wc.style; onPicked: v => mrow.set("style", v)
                            }
                            SetBlock { visible: wc.style === "custom"; sub: true; UiField { width: parent.width; text: mrow.mod.symbols ?? ""; placeholderText: "um símbolo por workspace, separados por espaço (ex.: ● ◆ ▲ ■ ★)"; onEditingFinished: mrow.set("symbols", text) } }
                            SetBlock { visible: wc.style === "glyphs"; sub: true; UiField { width: parent.width; text: mrow.mod.glyphs ?? ""; placeholderText: "nomes de ícones, um por workspace (ex.: home web music pencil image bell)"; onEditingFinished: mrow.set("glyphs", text) } }
                            SetSlider { sub: true; label: "Tamanho"; from: 10; to: 40; unit: " px"; def: 22; value: mrow.mod.size ?? 22; onMoved: v => mrow.set("size", Math.round(v)) }
                            SetSlider { sub: true; label: "Espaçamento"; from: 0; to: 24; unit: " px"; def: 6; value: mrow.mod.spacing ?? 6; onMoved: v => mrow.set("spacing", Math.round(v)) }
                            SetSlider { sub: true; label: "Quantidade fixa"; from: 0; to: 20; zeroLabel: "Automática"; def: 0; value: mrow.mod.count ?? 0; onMoved: v => mrow.set("count", Math.round(v)) }
                            SetRow { sub: true; label: "Em grupos (1-10, 11-20…)"; description: "Só o grupo do workspace atual (10 se a quantidade fixa for 0)"; checked: !!mrow.mod.paged; onToggled: on => mrow.set("paged", on) }
                            SetChoice { sub: true; label: "Números nos pontos e anéis"; options: [["hold", "Com Super"], ["always", "Sempre"], ["never", "Nunca"]]; value: mrow.mod.showNumbers ?? "hold"; onPicked: v => mrow.set("showNumbers", v) }
                            SetRow { sub: true; label: "Ícone do app maior no canto"; checked: !!mrow.mod.appIcons; onToggled: on => mrow.set("appIcons", on) }
                            SetRow { visible: !!mrow.mod.appIcons; sub: true; label: "Ícones monocromáticos"; checked: !!mrow.mod.mono; onToggled: on => mrow.set("mono", on) }
                            SetRow { sub: true; label: "Só os ocupados (e o atual)"; checked: !!mrow.mod.onlyOccupied; onToggled: on => mrow.set("onlyOccupied", on) }
                            SetRow { sub: true; label: "Roda do mouse dá a volta"; description: "Desligado, ela para nas pontas. Clique direito abre a visão geral"; checked: mrow.mod.wrap ?? true; onToggled: on => mrow.set("wrap", on) }
                            SetBlock { sub: true; ColorField { width: parent.width; label: "Cor do ativo"; value: mrow.mod.activeColor ? mrow.mod.activeColor : Settings.textColor; onPicked: c => mrow.set("activeColor", c.toString()) } }
                            SetBlock { sub: true; UiLabel { text: "Animação" } AnimPicker { width: parent.width; target: "workspaces" } }
                        }
                    }
                }
            }
        }
        SetExpander {
            icon: "plus"; label: "Adicionar módulo"; description: "Para a seção escolhida"
            lazy: Component {
                SetBlock {
                    sub: true
                    Flow {
                        width: parent.width
                        spacing: 6
                        Repeater {
                            model: Settings.moduleTypes
                            delegate: UiButton {
                                required property var modelData
                                icon: page.modIcons[modelData.type] ?? "plus"
                                text: modelData.label
                                onClicked: Settings.addModule(page.idx, page.sec, modelData.type)
                            }
                        }
                    }
                }
            }
        }
    }

    // ================= MOLDURA =================
    SetSection {
        title: "Moldura"; icon: "frame"
        SetChoice {
            icon: "window"; label: "Janela de configurações"; description: "Normal: o Hyprland cuida dela. Camada: desliza do topo do shell"
            options: [["window", "Normal", "window"], ["layer", "Camada", "layers"]]
            value: Settings.settingsWindowed ? "window" : "layer"
            onPicked: v => { const open = Settings.settingsOpen; Settings.settingsOpen = false; Settings.settingsWindowed = v === "window"; if (open) Qt.callLater(() => Settings.settingsOpen = true) }
        }
        SetChoice {
            icon: "layers"; label: "Composição"; description: "Integrado: tudo nasce da moldura. Independente: peças soltas"
            style: "tiles"; columns: 3; thumbHeight: 96
            options: [["integrated", "Integrado", "frame"], ["independent", "Independente", "cards"], ["mixed", Settings.composition === "mixed" ? "Misto (em uso)" : "Misto", "tune"]]
            value: Settings.composition
            onPicked: v => { if (v !== "mixed") Settings.applyComposition(v) }
            thumb: Item {
                id: ct
                property var opt
                property bool on
                property bool hovered
                CompPreview {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 8, (parent.height - 4) * 1.6)
                    dock: ct.opt && ct.opt[0] === "integrated" ? ({ bars: true, launcher: true, notifications: true, osd: true })
                        : ct.opt && ct.opt[0] === "independent" ? ({ bars: false, launcher: false, notifications: false, osd: false })
                        : (Settings.composition === "mixed" ? null : ({ bars: true, launcher: false, notifications: true, osd: false }))
                }
            }
        }
        SetExpander {
            icon: "tune"; label: "Parte a parte"; description: "O que sai da moldura e o que flutua"
            lazy: Component {
                Column {
                    width: parent.width
                    Repeater {
                        model: Settings.compParts
                        delegate: SetRow {
                            id: pr
                            required property var modelData
                            sub: true
                            label: modelData.label
                            description: modelData.hint ?? ""
                            readonly property bool docked: Settings.partDocked(modelData.id)
                            UiSeg {
                                options: [[true, "Na moldura", "frame"], [false, "Solto", "cards"]]
                                value: pr.docked
                                onPicked: v => Settings.setPartDocked(pr.modelData.id, v)
                            }
                            UiButton { visible: pr.modelData.page !== "frame"; icon: "chevRight"; kind: "ghost"; onClicked: Settings.settingsPage = pr.modelData.page }
                        }
                    }
                }
            }
        }
        SetRow { icon: "frame"; label: "Contorno na tela"; description: "A faixa fina em volta da tela inteira"; checked: Settings.outline; onToggled: on => Settings.outline = on }
        SetSlider { icon: "frame"; label: "Espessura do contorno"; from: 2; to: 16; unit: " px"; def: 6; value: Settings.edge; onMoved: v => Settings.edge = Math.round(v) }
        SetSlider { icon: "rounded"; label: "Cantos da tela"; from: 0; to: 40; unit: " px"; def: 16; value: Settings.cornerRadius; onMoved: v => Settings.cornerRadius = Math.round(v) }
        SetColor {
            visible: Settings.themeOn
            icon: "swatch"; label: "Cor da moldura e das barras"; allowNone: true
            roles: ["primaryContainer", "secondaryContainer", "tertiaryContainer", "surfaceHigh", "primary", "secondary", "tertiary"]
            value: Settings.frameRole; onPicked: v => Settings.frameRole = v
        }
        SetSlider { icon: "curve"; label: "Curva da subida"; description: "Como a faixa sobe até cada barra acoplada"; from: 0; to: 30; unit: " px"; def: 10; value: Settings.fillet; onMoved: v => Settings.fillet = Math.round(v) }
        SetSlider { icon: "rounded"; label: "Cantos do topo das barras"; from: 0; to: 30; unit: " px"; def: 12; value: Settings.topRadius; onMoved: v => Settings.topRadius = Math.round(v) }
        SetChoice {
            icon: "dock"; label: "Quando um painel abre"; description: "O que as barras do mesmo lado fazem"
            options: [["push", "Abrir espaço", "swap_horizontal"], ["out", "Sair", "arrow_right"], ["sink", "Recolher", "arrowDown"]]
            value: Settings.barsPanelMode; onPicked: v => Settings.barsPanelMode = v
        }
    }

    // ================= INDICADOR DE VOLUME =================
    SetSection {
        title: "Indicador de volume"; icon: "volume"; subtitle: "Aparece quando o volume ou o microfone mudam"
        SetRow { icon: "eye"; label: "Mostrar o indicador"; description: "Também com as teclas de mídia, mostrando o que toca"; checked: Settings.osdOn; onToggled: on => Settings.osdOn = on }
        SetChoice { icon: "dock"; label: "Lado"; options: [["left", "Esquerda", "alignLeft"], ["top", "Topo", "arrowUp"], ["bottom", "Base", "arrowDown"], ["right", "Direita", "alignRight"]]; value: Settings.osdSide; onPicked: v => Settings.osdSide = v }
        SetSlider { icon: "timer"; label: "Tempo na tela"; from: 600; to: 4000; step: 100; unit: " ms"; def: 1400; value: Settings.osdTimeout; onMoved: v => Settings.osdTimeout = Math.round(v / 100) * 100 }
        SetRow { icon: "play"; label: "Ver agora"; UiButton { icon: "play"; text: "Mostrar"; onClicked: Osd.preview() } }
        SetExpander { icon: "animation"; label: "Animação"; lazy: Component { SetBlock { sub: true; AnimPicker { width: parent.width; target: "osd" } } } }
    }

    // ================= DETALHES E ILHA =================
    SetSection {
        title: "Detalhes e ilha dinâmica"; icon: "info"; subtitle: "Cartões ao parar o mouse e o uso da IA"
        SetRow { icon: "info"; label: "Detalhes ao passar o mouse"; description: "Relógio, clima, sistema, música, volume e atualizações"; checked: Settings.barPopups; onToggled: on => Settings.barPopups = on }
        SetRow { icon: "tag"; label: "Dicas de texto"; description: "Balãozinho com o nome do botão, do ícone ou do app"; checked: Settings.barTips; onToggled: on => Settings.barTips = on }
        SetSlider { visible: Settings.barPopups; icon: "timer"; label: "Esperar antes de mostrar"; from: 100; to: 1500; step: 50; unit: " ms"; def: 450; value: Settings.barPopupDelay; onMoved: v => Settings.barPopupDelay = Math.round(v / 50) * 50 }
        SetExpander {
            icon: "robot"; label: "Uso da IA"; description: "Lê só os arquivos do Claude Code deste PC (~/.claude); nada vai para a internet"
            SetSlider { sub: true; label: "Limite da janela de 5 h"; from: 100; to: 5000; step: 50; unit: " mil"; def: 1000; value: Math.round(Settings.aiLimit / 1000); onMoved: v => Settings.aiLimit = Math.round(v / 50) * 50000 }
            SetSlider { sub: true; label: "Ler de novo a cada"; from: 30; to: 600; step: 10; unit: " s"; def: 60; value: Settings.aiInterval; onMoved: v => Settings.aiInterval = Math.round(v / 10) * 10 }
        }
        SetExpander {
            icon: "animation"; label: "Animações"; description: "Dos detalhes e da ilha ao mudar de forma"
            lazy: Component { SetBlock { sub: true; UiLabel { text: "Detalhes" } AnimPicker { width: parent.width; target: "popups" } UiLabel { text: "Ilha (ao mudar de forma)" } AnimPicker { width: parent.width; target: "island" } } }
        }
    }
}
