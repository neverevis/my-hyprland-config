// Pagina "Barras": lista de barras, ajustes da barra escolhida e seus modulos.
import QtQuick

Item {
    id: page
    property int cur: 0
    property int openMod: -1   // modulo com o painel de opcoes aberto
    property int curSec: 0     // secao selecionada da barra
    readonly property var sections: Settings.sectionsOf(bar)
    readonly property int sec: Math.max(0, Math.min(curSec, sections.length - 1))
    readonly property int idx: Math.max(0, Math.min(cur, Settings.bars.length - 1))
    readonly property var bar: Settings.bars[idx] ?? null
    readonly property var sideNames: ({ top: "Cima", bottom: "Baixo", left: "Esquerda", right: "Direita" })

    // ---- lista de barras ----
    Column {
        id: list
        width: 170
        spacing: 8
        Text { text: "Suas barras"; color: Theme.muted; font.pixelSize: 12; font.weight: Font.DemiBold }
        Repeater {
            model: Settings.bars
            delegate: Rectangle {
                id: item
                required property int index
                required property var modelData
                width: list.width; height: 52; radius: 12
                color: page.idx === index ? Theme.cardHi : Theme.card
                border.width: 1
                border.color: page.idx === index ? Theme.accent : Theme.border
                Column {
                    anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 12 }
                    Text { text: "Barra " + (item.index + 1); color: Theme.text; font.pixelSize: 13; font.weight: Font.Medium }
                    Text { text: (page.sideNames[item.modelData.side] ?? "?") + " · " + Settings.sectionsOf(item.modelData).reduce((n, x) => n + x.modules.length, 0) + " módulo(s)"; color: Theme.muted; font.pixelSize: 11 }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { page.cur = item.index; page.curSec = 0; page.openMod = -1 } }
            }
        }
        UiButton { width: list.width; text: "+ Nova barra"; kind: "accent"; onClicked: { Settings.addBar("top"); page.cur = Settings.bars.length - 1 } }
    }

    // ---- ajustes da barra escolhida ----
    Flickable {
        id: barsFlick
        anchors { left: list.right; leftMargin: 18; right: parent.right; top: parent.top; bottom: parent.bottom }
        contentHeight: detail.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: false   // so a roda do mouse rola (arrastar nao)
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: e => { const f = barsFlick; f.contentY = Math.max(0, Math.min(Math.max(0, f.contentHeight - f.height), f.contentY - e.angleDelta.y)) }
        }

        Column {
            id: detail
            width: parent.width
            spacing: 14
            visible: !!page.bar

            Card {
                title: "Posição e tamanho"
                Row {
                    spacing: 6
                    Repeater {
                        model: [["bottom", "Baixo"], ["top", "Cima"], ["left", "Esquerda"], ["right", "Direita"]]
                        delegate: UiButton {
                            required property var modelData
                            text: modelData[1]
                            checked: page.bar && page.bar.side === modelData[0]
                            onClicked: Settings.setBar(page.idx, "side", modelData[0])
                        }
                    }
                }
                UiSwitch { label: "Esconder (aparece ao passar o mouse)"; checked: page.bar ? !!page.bar.autoHide : false; onToggled: on => Settings.setBar(page.idx, "autoHide", on) }
                Row {
                    spacing: 6
                    visible: page.bar ? !!page.bar.autoHide : false
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Espaço:"; color: Theme.text; font.pixelSize: 13; rightPadding: 6 }
                    Repeater {
                        model: [["overlay", "Sobrepor"], ["always", "Reservar"], ["follow", "Acompanhar"]]
                        delegate: UiButton {
                            required property var modelData
                            text: modelData[1]
                            checked: page.bar && (page.bar.reserve ?? "overlay") === modelData[0]
                            onClicked: Settings.setBar(page.idx, "reserve", modelData[0])
                        }
                    }
                }
                Column {
                    visible: page.bar ? !!page.bar.autoHide : false
                    width: parent.width
                    spacing: 8
                    Text { text: "Animação de esconder/mostrar"; color: Theme.text; font.pixelSize: 13 }
                    AnimPicker { target: "bars" }
                    UiSlider { label: "Esperar antes de esconder"; from: 0; to: 2000; value: Settings.hideDelay; suffix: " ms"; onMoved: v => Settings.hideDelay = v }
                }
                UiSwitch { label: "Ocupar o lado inteiro"; checked: page.bar ? page.bar.full : false; onToggled: on => Settings.setBar(page.idx, "full", on) }
                UiSlider { label: "Largura"; from: 100; to: 3000; value: page.bar ? page.bar.width : 0; suffix: " px"; onMoved: v => Settings.setBar(page.idx, "width", v) }
                UiSlider { label: "Deslocamento"; from: -1500; to: 1500; value: page.bar ? page.bar.offset : 0; suffix: " px"; onMoved: v => Settings.setBar(page.idx, "offset", v) }
                UiSlider { label: "Espessura"; from: 24; to: 90; value: page.bar ? page.bar.height : 0; suffix: " px"; onMoved: v => Settings.setBar(page.idx, "height", v) }
                Row {
                    spacing: 8
                    UiButton { text: "Remover barra"; kind: "danger"; visible: Settings.bars.length > 1; onClicked: { Settings.removeBar(page.idx); page.cur = 0 } }
                }
            }

            Card {
                title: "Seções"
                subtitle: "Cada seção é um grupo de módulos com posição própria dentro da barra."
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
                    UiButton { text: "+ Nova seção"; kind: "accent"; onClicked: { Settings.addSection(page.idx); page.curSec = page.sections.length; page.openMod = -1 } }
                }
                Row {
                    spacing: 10
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Nome"; color: Theme.text; font.pixelSize: 13; width: 90 }
                    UiField {
                        width: 200
                        text: page.sections[page.sec] ? page.sections[page.sec].name : ""
                        onEditingFinished: Settings.setSection(page.idx, page.sec, "name", text)
                    }
                }
                Row {
                    spacing: 6
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Âncora"; color: Theme.text; font.pixelSize: 13; width: 90 }
                    Repeater {
                        model: [["start", "Início"], ["center", "Centro"], ["end", "Fim"]]
                        delegate: UiButton {
                            required property var modelData
                            text: modelData[1]
                            checked: page.sections[page.sec] && (page.sections[page.sec].anchor ?? "center") === modelData[0]
                            onClicked: Settings.setSection(page.idx, page.sec, "anchor", modelData[0])
                        }
                    }
                }
                Row {
                    spacing: 6
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Conteúdo"; color: Theme.text; font.pixelSize: 13; width: 90 }
                    Repeater {
                        model: [["start", "Início"], ["center", "Centro"], ["end", "Fim"]]
                        delegate: UiButton {
                            required property var modelData
                            text: modelData[1]
                            checked: page.sections[page.sec] && (page.sections[page.sec].align ?? "center") === modelData[0]
                            onClicked: Settings.setSection(page.idx, page.sec, "align", modelData[0])
                        }
                    }
                }
                UiSlider { label: "Largura (0 = automática)"; from: 0; to: 3000; value: page.sections[page.sec] ? (page.sections[page.sec].width ?? 0) : 0; suffix: " px"; onMoved: v => Settings.setSection(page.idx, page.sec, "width", v) }
                UiSlider { label: "Deslocamento"; from: -1500; to: 1500; value: page.sections[page.sec] ? (page.sections[page.sec].offset ?? 0) : 0; suffix: " px"; onMoved: v => Settings.setSection(page.idx, page.sec, "offset", v) }
                UiSlider { label: "Espaço entre módulos"; from: 0; to: 40; value: page.sections[page.sec] ? (page.sections[page.sec].spacing ?? 14) : 14; suffix: " px"; onMoved: v => Settings.setSection(page.idx, page.sec, "spacing", v) }
                UiButton { visible: page.sections.length > 1; text: "Remover esta seção"; kind: "danger"; onClicked: { Settings.removeSection(page.idx, page.sec); page.curSec = 0; page.openMod = -1 } }
            }

            Card {
                title: "Módulos da seção"
                subtitle: "Na ordem em que aparecem."
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
                        width: parent.width
                        spacing: 6

                        Rectangle {
                            width: parent.width; height: 46; radius: 10
                            color: Theme.gl(Theme.bg, 1); border.width: 1; border.color: mrow.hasOpts && page.openMod === mrow.index ? Theme.accent : Theme.border

                            Text {
                                id: mname
                                anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                                width: 92
                                color: Theme.text; font.pixelSize: 13; font.weight: Font.Medium
                                text: (Settings.moduleTypes.find(t => t.type === mrow.mod.type) ?? { label: mrow.mod.type }).label
                            }
                            UiField {
                                anchors { left: mname.right; right: btns.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                height: 30
                                visible: mrow.hasField
                                text: mrow.mod.type === "clock" ? (mrow.mod.format ?? "") : (mrow.mod.text ?? "")
                                placeholderText: mrow.mod.type === "clock" ? "formato, ex.: ddd HH:mm" : "texto"
                                onEditingFinished: Settings.setModuleOpt(page.idx, page.sec, mrow.index, mrow.mod.type === "clock" ? "format" : "text", text)
                            }
                            Row {
                                id: btns
                                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                spacing: 4
                                UiButton { visible: mrow.hasOpts; pad: 10; text: "Opções"; checked: page.openMod === mrow.index; onClicked: page.openMod = page.openMod === mrow.index ? -1 : mrow.index }
                                UiButton { visible: page.sections.length > 1; pad: 10; text: "→ seção " + (((page.sec + 1) % page.sections.length) + 1); onClicked: { page.openMod = -1; Settings.moveModuleTo(page.idx, page.sec, mrow.index, (page.sec + 1) % page.sections.length) } }
                                UiButton { pad: 9; text: "↑"; onClicked: Settings.moveModule(page.idx, page.sec, mrow.index, -1) }
                                UiButton { pad: 9; text: "↓"; onClicked: Settings.moveModule(page.idx, page.sec, mrow.index, 1) }
                                UiButton { pad: 9; text: "✕"; kind: "danger"; onClicked: { page.openMod = -1; Settings.removeModule(page.idx, page.sec, mrow.index) } }
                            }
                        }

                        // opcoes de medidores (cpu, memoria, volume) e da bandeja
                        Rectangle {
                            id: meterBox
                            visible: (mrow.isMeter || mrow.mtype === "tray" || mrow.mtype === "palette") && page.openMod === mrow.index
                            width: parent.width
                            height: visible ? mCol.implicitHeight + 24 : 0
                            radius: 10
                            color: Theme.gl(Theme.bg, 1); border.width: 1; border.color: Theme.border
                            Column {
                                id: mCol
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
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
                                Flow {
                                    visible: mrow.mtype === "palette"
                                    width: parent.width
                                    spacing: 6
                                    Repeater {
                                        model: [["all", "Todas"], ["accents", "Só destaques"], ["surfaces", "Só superfícies"]]
                                        delegate: UiButton {
                                            required property var modelData
                                            text: modelData[1]
                                            checked: (mrow.mod.set ?? "all") === modelData[0]
                                            onClicked: mCol.set("set", modelData[0])
                                        }
                                    }
                                }

                                // ---- medidores ----
                                Text { visible: mrow.isMeter; text: "Exibição"; color: Theme.muted; font.pixelSize: 12; font.weight: Font.DemiBold }
                                Flow {
                                    visible: mrow.isMeter
                                    width: parent.width
                                    spacing: 6
                                    Repeater {
                                        model: mCol.isCpuMem ? [["text", "Texto"], ["bar", "Barra"], ["graph", "Gráfico de linha"], ["segments", "Segmentos"]] : [["text", "Texto"], ["bar", "Barra"], ["segments", "Segmentos"]]
                                        delegate: UiButton {
                                            required property var modelData
                                            text: modelData[1]
                                            checked: mCol.disp === modelData[0]
                                            onClicked: mCol.set("display", modelData[0])
                                        }
                                    }
                                }
                                Row {
                                    visible: mrow.isMeter
                                    spacing: 10
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Rótulo"; color: Theme.text; font.pixelSize: 13; width: 90 }
                                    UiField {
                                        width: 160
                                        text: mrow.mod.label ?? (mrow.mtype === "cpu" ? "CPU" : (mrow.mtype === "memory" ? "RAM" : "VOL"))
                                        placeholderText: "vazio = sem rótulo"
                                        onEditingFinished: mCol.set("label", text)
                                    }
                                }
                                UiSwitch { visible: mrow.isMeter; label: "Mostrar o valor em número"; checked: mrow.mod.showValue ?? (mCol.disp === "text"); onToggled: on => mCol.set("showValue", on) }
                                UiSlider { visible: mrow.isMeter && mCol.disp !== "text"; label: "Largura"; from: 20; to: 200; value: mrow.mod.width ?? 60; suffix: " px"; onMoved: v => mCol.set("width", v) }
                                UiSlider { visible: mrow.isMeter && mCol.disp !== "text"; label: "Altura"; from: 6; to: 40; value: mrow.mod.height ?? 16; suffix: " px"; onMoved: v => mCol.set("height", v) }
                                UiSwitch { visible: mCol.isCpuMem; label: "Cor de alerta (amarelo/vermelho)"; checked: !!mrow.mod.warn; onToggled: on => mCol.set("warn", on) }
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
                            visible: mrow.mtype === "workspaces" && page.openMod === mrow.index
                            width: parent.width
                            height: visible ? wsCol.implicitHeight + 24 : 0
                            radius: 10
                            color: Theme.gl(Theme.bg, 1); border.width: 1; border.color: Theme.border
                            Column {
                                id: wsCol
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                                spacing: 12
                                readonly property string style: mrow.mod.style ?? "numbers"
                                Text { text: "Estilo"; color: Theme.muted; font.pixelSize: 12; font.weight: Font.DemiBold }
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
                                Text { text: "Animação"; color: Theme.muted; font.pixelSize: 12; font.weight: Font.DemiBold }
                                AnimPicker { target: "workspaces" }
                                UiField {
                                    width: parent.width
                                    visible: wsCol.style === "custom"
                                    text: mrow.mod.symbols ?? ""
                                    placeholderText: "um símbolo por workspace, separados por espaço (ex.: ● ◆ ▲ ■ ★)"
                                    onEditingFinished: Settings.setModuleOpt(page.idx, page.sec, mrow.index, "symbols", text)
                                }
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
                Text { text: "Adicionar"; color: Theme.muted; font.pixelSize: 12; font.weight: Font.DemiBold }
                Flow {
                    width: parent.width
                    spacing: 6
                    Repeater {
                        model: Settings.moduleTypes
                        delegate: UiButton {
                            required property var modelData
                            text: "+ " + modelData.label
                            onClicked: Settings.addModule(page.idx, page.sec, modelData.type)
                        }
                    }
                }
            }
        }
    }
}
