// Pagina "Barras": escolha da barra (no topo), ajustes da barra escolhida, secoes e modulos.
import Quickshell
import QtQuick

Column {
    id: page
    spacing: 14
    property var geo: ({})
    property int cur: 0
    property int openMod: -1   // modulo com o painel de opcoes aberto
    property int curSec: 0     // secao selecionada da barra
    readonly property var sections: Settings.sectionsOf(bar)
    readonly property int sec: Math.max(0, Math.min(curSec, sections.length - 1))
    readonly property int idx: Math.max(0, Math.min(cur, Settings.bars.length - 1))
    readonly property var bar: Settings.bars[idx] ?? null
    readonly property var sideNames: ({ top: "Cima", bottom: "Baixo", left: "Esquerda", right: "Direita" })
    readonly property var modIcons: ({ clock: "clock", workspaces: "view_grid", window: "fullscreen", cpu: "chip", memory: "memory", volume: "volume", tray: "apps", palette: "palette", power: "power", text: "pencil" })
    function setBar(k, v) { Settings.setBar(idx, k, v) }
    // marca as secoes na propria barra enquanto esta pagina esta aberta
    // so a pagina de verdade (a copia escondida que a busca cria para montar o indice nao mexe na depuracao)
    Binding { target: Settings; property: "barDebugBar"; value: page.idx; when: page.visible }
    Binding { target: Settings; property: "barDebugSec"; value: page.sec; when: page.visible }
    Component.onDestruction: if (page.visible) { Settings.barDebugBar = -1; Settings.barDebugSec = -1 }

    // ---- mapa da tela + escolha da barra ----
    Card {
        icon: "monitor"
        title: "Suas barras"
        subtitle: "O mapa mostra onde cada uma está agora. Clique numa barra (no mapa ou nos cartões) para editar. O número é a prioridade."
        BarsMap {
            width: parent.width
            geo: page.geo
            selected: page.idx
            onPicked: i => { page.cur = i; page.curSec = 0; page.openMod = -1 }
        }
        Flow {
            width: parent.width
            spacing: 8
            Repeater {
                model: Settings.bars
                delegate: Rectangle {
                    id: item
                    required property int index
                    required property var modelData
                    readonly property bool on: page.idx === index
                    readonly property var info: page.geo && page.geo.bars ? page.geo.bars[index] : null
                    width: 196; height: 58; radius: 14
                    color: on ? Theme.tint(0.14) : (bm.containsMouse ? Theme.cardHi : Theme.gl(Theme.card, 1))
                    border.width: 1
                    border.color: on ? Theme.accent : Theme.border
                    Rectangle {   // prioridade
                        id: prio
                        x: 10; anchors.verticalCenter: parent.verticalCenter
                        width: 26; height: 26; radius: 13
                        color: item.on ? Theme.accent : Theme.track
                        Text { anchors.centerIn: parent; text: item.index + 1; color: item.on ? Theme.accentText : Theme.muted; font.pixelSize: 12; font.weight: Font.Bold }
                    }
                    Column {
                        anchors { left: prio.right; leftMargin: 10; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        spacing: 1
                        Text { width: parent.width; elide: Text.ElideRight; text: item.modelData.name || ("Barra " + (item.index + 1)); color: Theme.text; font.pixelSize: 13; font.weight: Font.DemiBold }
                        Text {
                            width: parent.width; elide: Text.ElideRight
                            text: item.info && item.info.hidden ? "Sem espaço: escondida"
                                : (page.sideNames[item.modelData.side] ?? "?") + (item.modelData.detached ? " · solta" : "") + " · " + Settings.sectionsOf(item.modelData).reduce((n, x) => n + x.modules.length, 0) + " módulos"
                            color: item.info && item.info.hidden ? Theme.danger : Theme.muted; font.pixelSize: 11
                        }
                    }
                    MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { page.cur = item.index; page.curSec = 0; page.openMod = -1 } }
                }
            }
            Rectangle {
                width: 120; height: 58; radius: 14
                color: am.containsMouse ? Theme.cardHi : "transparent"
                border.width: 1; border.color: Theme.border
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    UiIcon { name: "plus"; size: 18; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Nova barra"; color: Theme.text; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Settings.addBar("top"); page.cur = Settings.bars.length - 1 } }
            }
        }
        // prioridade da barra escolhida
        Row {
            visible: Settings.bars.length > 1 && !!page.bar
            spacing: 8
            UiIcon { name: "layers"; size: 15; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Prioridade " + (page.idx + 1) + " de " + Settings.bars.length; color: Theme.text; font.pixelSize: 13 }
            UiButton { icon: "arrowUp"; text: "Subir"; kind: "ghost"; enabled: page.idx > 0; onClicked: { Settings.moveBar(page.idx, -1); page.cur = page.idx - 1 } }
            UiButton { icon: "arrowDown"; text: "Descer"; kind: "ghost"; enabled: page.idx < Settings.bars.length - 1; onClicked: { Settings.moveBar(page.idx, 1); page.cur = page.idx + 1 } }
        }
        Text {
            visible: Settings.bars.length > 1
            width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 12
            text: "Quando duas barras do mesmo lado querem o mesmo lugar, a de maior prioridade fica onde você colocou; a outra vai para o espaço livre mais perto, encolhe se precisar e, sem espaço nenhum, fica escondida."
        }
    }

    Card {
        visible: !!page.bar
        icon: "frame"
        title: "Posição e tamanho"
        subtitle: "Lado, tamanho e posição em porcentagem do lado da tela. Nas pontas a barra encosta no canto sozinha."
        readonly property var info: page.geo && page.geo.bars ? page.geo.bars[page.idx] : null
        Row {
            width: parent.width
            spacing: 10
            UiIcon { name: "pencil"; size: 15; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Nome"; color: Theme.text; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
            UiField {
                width: Math.min(280, parent.width - 80)
                text: page.bar ? (page.bar.name ?? "") : ""
                placeholderText: "Barra " + (page.idx + 1)
                onEditingFinished: page.setBar("name", text.trim())
            }
        }
        SidePick { value: page.bar ? page.bar.side : ""; onPicked: v => page.setBar("side", v) }
        UiLabel { text: "Estilo" }
        UiSeg {
            options: [["frame", "Na moldura", "frame"], ["detached", "Solta", "cards"]]
            value: page.bar && page.bar.detached ? "detached" : "frame"
            onPicked: v => page.setBar("detached", v === "detached")
        }
        Text {
            width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 12
            text: page.bar && page.bar.detached ? "A barra flutua afastada da moldura, como uma ilha, com os cantos arredondados." : "A barra sai da moldura, emendada nela pelas curvas."
        }
        UiSwitch { visible: page.bar ? !page.bar.detached : true; label: "Ocupar o lado inteiro"; description: "A barra vai de uma ponta à outra da tela."; checked: page.bar ? !!page.bar.full : false; onToggled: on => page.setBar("full", on) }
        Column {
            visible: page.bar ? !page.bar.full : true
            width: parent.width
            spacing: 12
            readonly property real sideLen: page.bar && (page.bar.side === "left" || page.bar.side === "right") ? (Quickshell.screens[0] ? Quickshell.screens[0].height : 1080) : (Quickshell.screens[0] ? Quickshell.screens[0].width : 1920)
            readonly property real size: page.bar ? Settings.barSize(page.bar, sideLen) : 30
            readonly property real pos: page.bar ? Settings.barPos(page.bar, sideLen) : 50
            readonly property bool vert: page.bar ? (page.bar.side === "left" || page.bar.side === "right") : false
            UiSlider { label: "Largura"; icon: "swap_horizontal"; from: 3; to: 100; value: Math.round(parent.size); suffix: " %"; onMoved: v => page.setBar("size", v) }
            UiSlider { label: "Posição"; icon: "arrow_right"; from: 0; to: 100; value: Math.round(parent.pos); suffix: " %"; onMoved: v => { page.setBar("pos", v); page.setBar("corner", "") } }
            Row {
                spacing: 6
                readonly property var info: page.geo && page.geo.bars ? page.geo.bars[page.idx] : null
                UiButton { icon: parent.parent.vert ? "arrowUp" : "arrow_left"; text: parent.parent.vert ? "No topo" : "No início"; kind: "ghost"; onClicked: { page.setBar("pos", 0); page.setBar("corner", "") } }
                UiButton { icon: "alignCenter"; text: "Centro"; kind: "ghost"; onClicked: { page.setBar("pos", 50); page.setBar("corner", "") } }
                UiButton { icon: parent.parent.vert ? "arrowDown" : "arrow_right"; text: parent.parent.vert ? "Embaixo" : "No fim"; kind: "ghost"; onClicked: { page.setBar("pos", 100); page.setBar("corner", "") } }
                Rectangle {   // estado atual (vindo da geometria)
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property string msg: !parent.info ? "" : (parent.info.hidden ? "Sem espaço" : (parent.info.corner < 0 ? (parent.parent.vert ? "Encostada no topo" : "Encostada à esquerda") : (parent.info.corner > 0 ? (parent.parent.vert ? "Encostada embaixo" : "Encostada à direita") : "")))
                    visible: msg !== ""
                    width: st.implicitWidth + 18; height: 26; radius: 13
                    color: parent.info && parent.info.hidden ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.18) : Theme.tint(0.18)
                    Text { id: st; anchors.centerIn: parent; text: parent.msg; color: parent.parent.info && parent.parent.info.hidden ? Theme.danger : Theme.accent; font.pixelSize: 11; font.weight: Font.DemiBold }
                }
            }
        }
        UiSlider { label: "Espessura"; icon: "bars"; from: 24; to: 90; value: page.bar ? page.bar.height : 0; suffix: " px"; onMoved: v => page.setBar("height", v) }
        UiSlider { visible: page.bar ? !!page.bar.detached : false; label: "Distância da moldura"; icon: "dock"; from: 0; to: 40; value: page.bar ? (page.bar.gap ?? 8) : 8; suffix: " px"; onMoved: v => page.setBar("gap", v) }
        UiSlider { visible: page.bar ? !!page.bar.detached : false; label: "Arredondamento"; icon: "curve"; from: 0; to: 40; value: page.bar ? (page.bar.radius ?? 14) : 14; suffix: " px"; onMoved: v => page.setBar("radius", v) }
    }

    Card {
        visible: !!page.bar
        icon: "eye"
        title: "Esconder"
        subtitle: "A barra some e reaparece quando o mouse encosta na borda."
        UiSwitch { label: "Esconder automaticamente"; checked: page.bar ? !!page.bar.autoHide : false; onToggled: on => page.setBar("autoHide", on) }
        Column {
            visible: page.bar ? !!page.bar.autoHide : false
            width: parent.width
            spacing: 12
            UiLabel { text: "Espaço das janelas" }
            UiSeg {
                fill: true
                options: [["overlay", "Sobrepor", "layers"], ["always", "Reservar", "dock"], ["follow", "Acompanhar", "swap_vertical"]]
                value: page.bar ? (page.bar.reserve ?? "overlay") : "overlay"
                onPicked: v => page.setBar("reserve", v)
            }
            Text {
                width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 12
                text: ({ overlay: "A barra aparece por cima das janelas.", always: "As janelas sempre deixam o espaço da barra livre.", follow: "As janelas abrem espaço só enquanto a barra está visível." })[page.bar ? (page.bar.reserve ?? "overlay") : "overlay"]
            }
            UiSlider { label: "Esperar antes de mostrar"; from: 0; to: 1000; value: Settings.showDelay; suffix: " ms"; onMoved: v => Settings.showDelay = v }
            UiSlider { label: "Esperar antes de esconder"; from: 0; to: 2000; value: Settings.hideDelay; suffix: " ms"; onMoved: v => Settings.hideDelay = v }
            UiLabel { text: "Animação" }
            AnimPicker { target: "bars" }
        }
    }

    Card {
        icon: "dock"
        title: "Quando um painel abre"
        subtitle: "O que as barras do mesmo lado fazem quando o launcher, o seletor de wallpaper ou o Início saem da moldura. Vale para todas as barras."
        UiSeg {
            fill: true
            options: [["push", "Abrir espaço", "swap_horizontal"], ["out", "Sair pela borda", "arrow_right"], ["sink", "Recolher", "arrowDown"]]
            value: Settings.barsPanelMode
            onPicked: v => Settings.barsPanelMode = v
        }
        Text {
            width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 12
            text: ({ push: "As barras deslizam só até encostar no painel e continuam visíveis. Se não houver espaço, saem pela borda.",
                     out: "As barras deslizam pela borda até sair da tela e voltam quando o painel fecha.",
                     sink: "As barras que estão no caminho recolhem para dentro da moldura." })[Settings.barsPanelMode] ?? ""
        }
    }

    Card {
        visible: !!page.bar
        icon: "view_column"
        title: "Seções"
        subtitle: "Cada seção é um grupo de módulos com posição própria. Enquanto esta página está aberta, as seções aparecem marcadas na própria barra (a escolhida em destaque)."
        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: page.sections.length
                delegate: UiButton {
                    required property int index
                    text: page.sections[index] ? (page.sections[index].name || ("Seção " + (index + 1))) : ""
                    checked: page.sec === index
                    onClicked: { page.curSec = index; page.openMod = -1 }
                }
            }
            UiButton { icon: "plus"; text: "Nova seção"; kind: "ghost"; onClicked: { Settings.addSection(page.idx); page.curSec = page.sections.length; page.openMod = -1 } }
        }
        Row {
            spacing: 12
            width: parent.width
            Column {
                spacing: 8
                width: (parent.width - 12) / 2
                UiLabel { text: "Nome" }
                UiField {
                    width: parent.width
                    text: page.sections[page.sec] ? page.sections[page.sec].name : ""
                    placeholderText: "Seção " + (page.sec + 1)
                    onEditingFinished: Settings.setSection(page.idx, page.sec, "name", text)
                }
            }
            Column {
                spacing: 8
                width: (parent.width - 12) / 2
                UiLabel { text: "Posição na barra" }
                UiSeg {
                    fill: true
                    options: [["start", "", "alignLeft"], ["center", "", "alignCenter"], ["end", "", "alignRight"]]
                    value: page.sections[page.sec] ? (page.sections[page.sec].anchor ?? "center") : "center"
                    onPicked: v => Settings.setSection(page.idx, page.sec, "anchor", v)
                }
            }
        }
        UiLabel { text: "Alinhamento dos módulos dentro da seção" }
        UiSeg {
            options: [["start", "Início", "alignLeft"], ["center", "Centro", "alignCenter"], ["end", "Fim", "alignRight"]]
            value: page.sections[page.sec] ? (page.sections[page.sec].align ?? "center") : "center"
            onPicked: v => Settings.setSection(page.idx, page.sec, "align", v)
        }
        UiSlider { label: "Largura (0 = automática)"; from: 0; to: 3000; value: page.sections[page.sec] ? (page.sections[page.sec].width ?? 0) : 0; suffix: " px"; onMoved: v => Settings.setSection(page.idx, page.sec, "width", v) }
        UiSlider { label: "Deslocamento"; from: -1500; to: 1500; value: page.sections[page.sec] ? (page.sections[page.sec].offset ?? 0) : 0; suffix: " px"; onMoved: v => Settings.setSection(page.idx, page.sec, "offset", v) }
        UiSlider { label: "Espaço entre módulos"; from: 0; to: 40; value: page.sections[page.sec] ? (page.sections[page.sec].spacing ?? 14) : 14; suffix: " px"; onMoved: v => Settings.setSection(page.idx, page.sec, "spacing", v) }
        UiButton { visible: page.sections.length > 1; icon: "trash"; text: "Remover esta seção"; kind: "danger"; onClicked: { Settings.removeSection(page.idx, page.sec); page.curSec = 0; page.openMod = -1 } }
    }

    Card {
        visible: !!page.bar
        icon: "apps"
        title: "Módulos da seção"
        subtitle: "Na ordem em que aparecem na barra."
        Repeater {
            model: page.sections[page.sec] ? page.sections[page.sec].modules.length : 0
            delegate: Column {
                id: mrow
                required property int index
                readonly property var mod: page.sections[page.sec].modules[index] ?? ({})
                readonly property bool hasField: mod.type === "clock" || mod.type === "text"
                readonly property string mtype: mod.type
                readonly property bool isMeter: mtype === "cpu" || mtype === "memory" || mtype === "volume"
                readonly property bool hasOpts: mtype === "workspaces" || isMeter || mtype === "tray" || mtype === "palette"
                readonly property bool optsOpen: hasOpts && page.openMod === index
                width: parent.width
                spacing: 6

                Rectangle {
                    width: parent.width; height: 48; radius: 12
                    color: Theme.track; border.width: 1; border.color: mrow.optsOpen ? Theme.accent : Theme.border

                    Rectangle {
                        id: mic
                        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                        width: 32; height: 32; radius: 9
                        color: Theme.tint(0.14)
                        UiIcon { anchors.centerIn: parent; name: page.modIcons[mrow.mtype] ?? "apps"; size: 17; color: Theme.accent }
                    }
                    Text {
                        id: mname
                        anchors { left: mic.right; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        width: 96
                        color: Theme.text; font.pixelSize: 13; font.weight: Font.Medium
                        text: (Settings.moduleTypes.find(t => t.type === mrow.mod.type) ?? { label: mrow.mod.type }).label
                    }
                    UiField {
                        anchors { left: mname.right; right: btns.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        height: 32
                        visible: mrow.hasField
                        text: mrow.mod.type === "clock" ? (mrow.mod.format ?? "") : (mrow.mod.text ?? "")
                        placeholderText: mrow.mod.type === "clock" ? "formato, ex.: ddd HH:mm" : "texto"
                        onEditingFinished: Settings.setModuleOpt(page.idx, page.sec, mrow.index, mrow.mod.type === "clock" ? "format" : "text", text)
                    }
                    Row {
                        id: btns
                        anchors { right: parent.right; rightMargin: 7; verticalCenter: parent.verticalCenter }
                        spacing: 4
                        UiButton { visible: mrow.hasOpts; icon: "tune"; text: "Opções"; pad: 10; checked: mrow.optsOpen; onClicked: page.openMod = mrow.optsOpen ? -1 : mrow.index }
                        UiButton { visible: page.sections.length > 1; icon: "swap_horizontal"; pad: 10; text: "Seção " + (((page.sec + 1) % page.sections.length) + 1); onClicked: { page.openMod = -1; Settings.moveModuleTo(page.idx, page.sec, mrow.index, (page.sec + 1) % page.sections.length) } }
                        UiButton { icon: "arrowUp"; kind: "ghost"; enabled: mrow.index > 0; onClicked: Settings.moveModule(page.idx, page.sec, mrow.index, -1) }
                        UiButton { icon: "arrowDown"; kind: "ghost"; enabled: mrow.index < page.sections[page.sec].modules.length - 1; onClicked: Settings.moveModule(page.idx, page.sec, mrow.index, 1) }
                        UiButton { icon: "trash"; kind: "danger"; onClicked: { page.openMod = -1; Settings.removeModule(page.idx, page.sec, mrow.index) } }
                    }
                }

                // opcoes de medidores (cpu, memoria, volume), da bandeja e das cores
                Rectangle {
                    visible: (mrow.isMeter || mrow.mtype === "tray" || mrow.mtype === "palette") && mrow.optsOpen
                    width: parent.width
                    height: visible ? mCol.implicitHeight + 28 : 0
                    radius: 12
                    color: Theme.track; border.width: 1; border.color: Theme.border
                    Column {
                        id: mCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                        spacing: 12
                        readonly property string disp: mrow.mod.display ?? "text"
                        readonly property bool isCpuMem: mrow.mtype === "cpu" || mrow.mtype === "memory"
                        function set(k, v) { Settings.setModuleOpt(page.idx, page.sec, mrow.index, k, v) }

                        // ---- bandeja ----
                        UiSlider { visible: mrow.mtype === "tray"; label: "Tamanho dos ícones"; from: 12; to: 32; value: mrow.mod.size ?? 18; suffix: " px"; onMoved: v => mCol.set("size", v) }
                        UiSlider { visible: mrow.mtype === "tray"; label: "Espaçamento"; from: 0; to: 20; value: mrow.mod.spacing ?? 8; suffix: " px"; onMoved: v => mCol.set("spacing", v) }

                        // ---- cores do tema ----
                        UiSlider { visible: mrow.mtype === "palette"; label: "Tamanho das bolinhas"; from: 8; to: 28; value: mrow.mod.size ?? 14; suffix: " px"; onMoved: v => mCol.set("size", v) }
                        UiSlider { visible: mrow.mtype === "palette"; label: "Espaçamento"; from: 0; to: 14; value: mrow.mod.spacing ?? 5; suffix: " px"; onMoved: v => mCol.set("spacing", v) }
                        UiSeg {
                            visible: mrow.mtype === "palette"
                            options: [["all", "Todas"], ["accents", "Só destaques"], ["surfaces", "Só superfícies"]]
                            value: mrow.mod.set ?? "all"
                            onPicked: v => mCol.set("set", v)
                        }

                        // ---- medidores ----
                        UiLabel { visible: mrow.isMeter; text: "Exibição" }
                        UiSeg {
                            visible: mrow.isMeter
                            options: mCol.isCpuMem ? [["text", "Texto"], ["bar", "Barra"], ["graph", "Gráfico"], ["segments", "Segmentos"]] : [["text", "Texto"], ["bar", "Barra"], ["segments", "Segmentos"], ["slider", "Ícone + barra"]]
                            value: mCol.disp
                            onPicked: v => mCol.set("display", v)
                        }
                        Row {
                            visible: mrow.isMeter
                            spacing: 10
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "Rótulo"; color: Theme.text; font.pixelSize: 13; width: 90 }
                            UiField {
                                width: 180
                                text: mrow.mod.label ?? (mrow.mtype === "cpu" ? "CPU" : (mrow.mtype === "memory" ? "RAM" : "VOL"))
                                placeholderText: "vazio = sem rótulo"
                                onEditingFinished: mCol.set("label", text)
                            }
                        }
                        UiSwitch { visible: mrow.isMeter; label: "Mostrar o valor em número"; checked: mrow.mod.showValue ?? (mCol.disp === "text"); onToggled: on => mCol.set("showValue", on) }
                        UiSlider { visible: mrow.isMeter && mCol.disp !== "text"; label: "Largura"; from: 20; to: 200; value: mrow.mod.width ?? 60; suffix: " px"; onMoved: v => mCol.set("width", v) }
                        UiSlider { visible: mrow.isMeter && mCol.disp !== "text"; label: "Altura"; from: 6; to: 40; value: mrow.mod.height ?? 16; suffix: " px"; onMoved: v => mCol.set("height", v) }
                        UiSwitch { visible: mCol.isCpuMem; label: "Cor de alerta"; description: "Fica amarelo e vermelho quando o uso está alto."; checked: !!mrow.mod.warn; onToggled: on => mCol.set("warn", on) }
                        UiSlider { visible: mCol.isCpuMem && mCol.disp === "graph"; label: "Pontos do gráfico"; from: 10; to: 120; value: mrow.mod.points ?? 30; onMoved: v => mCol.set("points", v) }
                        UiSlider { visible: mCol.isCpuMem; label: "Atualização"; from: 500; to: 5000; value: mrow.mod.interval ?? (mCol.disp === "graph" ? 1000 : 2000); suffix: " ms"; onMoved: v => mCol.set("interval", Math.round(v / 100) * 100) }
                        UiSlider { visible: mrow.mtype === "volume"; label: "Passo da roda do mouse"; from: 1; to: 20; value: mrow.mod.step ?? 5; suffix: " %"; onMoved: v => mCol.set("step", v) }
                        UiSlider { visible: mrow.mtype === "volume" && mCol.disp === "segments"; label: "Quantidade de segmentos"; from: 4; to: 16; value: mrow.mod.segments ?? 8; onMoved: v => mCol.set("segments", v) }
                        ColorField {
                            visible: mrow.isMeter
                            label: "Cor"
                            value: mrow.mod.color ? mrow.mod.color : Settings.textColor
                            onPicked: c => mCol.set("color", c.toString())
                        }
                    }
                }

                // opcoes do modulo de workspaces
                Rectangle {
                    visible: mrow.mtype === "workspaces" && mrow.optsOpen
                    width: parent.width
                    height: visible ? wsCol.implicitHeight + 28 : 0
                    radius: 12
                    color: Theme.track; border.width: 1; border.color: Theme.border
                    Column {
                        id: wsCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                        spacing: 12
                        readonly property string style: mrow.mod.style ?? "numbers"
                        UiLabel { text: "Estilo" }
                        Flow {
                            width: parent.width
                            spacing: 6
                            Repeater {
                                model: [["numbers", "① Números"], ["dots", "• Pontos"], ["pills", "━ Pílulas"], ["squares", "▢ Quadrados"], ["bars", "| Barras"], ["ring", "◎ Anel"], ["icons", "▣ Ícone do app"], ["roman", "Ⅳ Romanos"], ["kanji", "三 Kanji"], ["custom", "★ Símbolos"]]
                                delegate: UiButton {
                                    required property var modelData
                                    text: modelData[1]
                                    checked: wsCol.style === modelData[0]
                                    onClicked: Settings.setModuleOpt(page.idx, page.sec, mrow.index, "style", modelData[0])
                                }
                            }
                        }
                        UiField {
                            width: parent.width
                            visible: wsCol.style === "custom"
                            text: mrow.mod.symbols ?? ""
                            placeholderText: "um símbolo por workspace, separados por espaço (ex.: ● ◆ ▲ ■ ★)"
                            onEditingFinished: Settings.setModuleOpt(page.idx, page.sec, mrow.index, "symbols", text)
                        }
                        UiLabel { text: "Animação" }
                        AnimPicker { target: "workspaces" }
                        UiSlider { label: "Tamanho"; from: 10; to: 40; value: mrow.mod.size ?? 22; suffix: " px"; onMoved: v => Settings.setModuleOpt(page.idx, page.sec, mrow.index, "size", v) }
                        UiSlider { label: "Espaçamento"; from: 0; to: 24; value: mrow.mod.spacing ?? 6; suffix: " px"; onMoved: v => Settings.setModuleOpt(page.idx, page.sec, mrow.index, "spacing", v) }
                        UiSlider { label: "Quantidade fixa (0 = automática)"; from: 0; to: 10; value: mrow.mod.count ?? 0; onMoved: v => Settings.setModuleOpt(page.idx, page.sec, mrow.index, "count", v) }
                        UiSwitch { label: "Só os ocupados (e o atual)"; checked: !!mrow.mod.onlyOccupied; onToggled: on => Settings.setModuleOpt(page.idx, page.sec, mrow.index, "onlyOccupied", on) }
                        ColorField {
                            label: "Cor do ativo"
                            value: mrow.mod.activeColor ? mrow.mod.activeColor : Settings.textColor
                            onPicked: c => Settings.setModuleOpt(page.idx, page.sec, mrow.index, "activeColor", c.toString())
                        }
                    }
                }
            }
        }
        UiLabel { text: "Adicionar módulo" }
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

    Row {
        visible: Settings.bars.length > 1
        UiButton { icon: "trash"; text: "Remover a barra " + (page.idx + 1); kind: "danger"; onClicked: { Settings.removeBar(page.idx); page.cur = 0 } }
    }
}
