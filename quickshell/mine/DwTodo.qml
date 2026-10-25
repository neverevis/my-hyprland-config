// Tarefas: lista salva no proprio widget (opts.items = [{ text, done }]). Enter adiciona, clique marca, X remove,
// "Limpar feitas" tira as concluidas. Barra de progresso opcional.
// Composicoes (opcao "look"): auto (a de sempre), end4 (cabecalho grande com +, linhas em cartoes coloridos, check redondo,
// arrastar apaga com tile vermelho) e linhas (lista solta com divisorias). Sem Loader: so muda o delegate da mesma lista.
import QtQuick
import "dwparts.js" as U

Item {
    id: w
    property int cols: 2
    property int rows: 2
    property var opts: ({})
    property string wid: ""
    property color fg: Theme.text
    property color dim: Theme.muted
    property color ac: Theme.accent
    property color ac2: Theme.tertiary            // cor companheira (o DeskView passa a do tom escolhido)
    property color cont: Theme.primaryContainer
    property color contInk: Theme.primaryContainerInk
    property bool bare: false
    property var comp: ({})                       // composicao vinda do cartao (caixas internas, selos, destaque, raio)
    function o(k) { return DeskState.opt({ type: "todo", opts: w.opts }, k) }

    // composicao: auto (a de sempre), cards (end4) ou lines
    readonly property string lk: { const l = o("look"); return l === "end4" ? "cards" : l === "lines" ? "lines" : "auto" }
    readonly property bool cards: lk === "cards"
    readonly property real pad: cards ? 14 : -1       // o DeskView usa como margem do conteudo (-1 = a padrao)
    readonly property string hdr: o("header")
    readonly property bool hasHead: !cards || hdr !== "none"
    readonly property bool entryTop: cards && hdr === "field"
    property bool adding: false
    readonly property bool entryOn: !cards || hdr !== "title" || adding
    readonly property real rowR: comp.innerRadius > 0 ? comp.innerRadius : 17
    readonly property string palette: o("rowPalette")
    readonly property bool hideDone: o("hideDone") || o("doneStyle") === "hide"
    // cor da linha i: ciclo terciaria/secundaria/primaria (end4), uma so ou sem preenchimento
    function rowRole(i) {
        if (comp.innerRole && comp.innerRole !== "auto") return comp.innerRole
        if (palette === "primary") return "primaryContainer"
        if (palette === "tertiary") return "tertiaryContainer"
        if (palette === "none") return "none"
        return ["tertiaryContainer", "secondaryContainer", "primaryContainer"][i % 3]
    }
    function rowFill(i) { const r = rowRole(i); if (r === "none") return Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.08); const c = Theme.role(r); return Qt.rgba(c.r, c.g, c.b, comp.innerAlpha > 0 ? comp.innerAlpha : 1) }
    function rowInk(i) { const r = rowRole(i); return r === "none" ? w.fg : Theme.role(U.inkRole(r)) }

    readonly property var items: opts.items ?? []
    readonly property int doneCount: items.filter(i => i.done).length
    function save(list) { if (wid === "@home") Settings.homeTodo = list; else if (wid !== "") DeskState.setOpt(wid, "items", list) }
    function add(t) { t = t.trim(); if (t) save(items.concat([{ text: t, done: false }])) }
    function toggle(i) { const l = JSON.parse(JSON.stringify(items)); l[i].done = !l[i].done; save(l) }
    function del(i) { const l = items.slice(); l.splice(i, 1); save(l) }

    Item {
        id: head
        width: parent.width
        height: w.hasHead ? (w.cards ? 36 : 22) : 0
        visible: w.hasHead
        Row {
            visible: !w.cards
            width: parent.width
            spacing: 8
            UiIcon { name: "listCheck"; size: 16; color: w.ac; anchors.verticalCenter: parent.verticalCenter }
            UiText { text: "Tarefas"; color: w.fg; font.pixelSize: 15; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
            UiText { text: w.items.length ? w.doneCount + "/" + w.items.length : ""; color: w.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; font.features: { "tnum": 1 } }
        }
        // cabecalho do end4: titulo grande, contagem e botao +
        Row {
            visible: w.cards
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            UiText { text: "Tarefas"; color: w.fg; font.pixelSize: 22; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
            UiText { text: w.items.length ? w.doneCount + "/" + w.items.length : ""; color: w.dim; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; font.features: { "tnum": 1 } }
        }
        DwParts.RoundBtn {
            visible: w.cards && w.hdr === "title"
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            width: 32; height: 32
            icon: w.adding ? "arrowLeft" : "plus"; kind: "filled"; tone: w.ac
            onClicked: { w.adding = !w.adding; if (w.adding) input.forceActiveFocus() }
        }
        UiText {
            visible: w.doneCount > 0
            anchors { right: parent.right; rightMargin: w.cards && w.hdr === "title" ? 42 : 0; verticalCenter: parent.verticalCenter }
            text: "Limpar feitas"; color: cm.containsMouse ? w.ac : w.dim; font.pixelSize: 11
            MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: w.save(w.items.filter(i => !i.done)) }
        }
    }
    Rectangle {
        id: prog
        visible: w.o("progress") && w.items.length > 0
        anchors { top: head.bottom; topMargin: 8 }
        width: parent.width; height: 4; radius: 2
        color: Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.12)
        Rectangle { width: parent.width * (w.items.length ? w.doneCount / w.items.length : 0); height: parent.height; radius: 2; color: w.ac
            Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } } }
    }
    ListView {
        id: lv
        anchors {
            top: w.entryTop && w.entryOn ? entry.bottom : (prog.visible ? prog.bottom : head.bottom); topMargin: 8
            left: parent.left; right: parent.right
            bottom: !w.entryTop && w.entryOn ? entry.top : parent.bottom; bottomMargin: !w.entryTop && w.entryOn ? 6 : 0
        }
        clip: true
        spacing: w.cards ? 8 : w.lk === "lines" ? 0 : 2
        boundsBehavior: Flickable.StopAtBounds
        model: w.items.map((it, i) => ({ text: it.text, done: it.done, i: i })).filter(x => !(w.hideDone && x.done))
        delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property bool dim: w.o("doneStyle") === "fade" && modelData.done
            width: lv.width; height: w.cards ? 52 : w.lk === "lines" ? 34 : 30
            readonly property color ink: w.cards ? w.rowInk(index) : w.fg
            // arrastar a linha para o lado mais de 70 px apaga a tarefa (o fundo avermelha ate la)
            Rectangle { visible: rowc.x !== 0 && !w.cards; anchors.fill: parent; radius: 8; color: Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, Math.min(1, Math.abs(rowc.x) / 70) * 0.35) }
            Rectangle {
                visible: rowc.x !== 0 && w.cards
                anchors.fill: parent; radius: w.rowR; color: Theme.danger
                UiIcon { anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter } name: "trash"; size: 20; color: Theme.role("onError") }
            }
            Item {
                id: rowc
                width: parent.width; height: parent.height
                opacity: (row.dim ? 0.5 : 1) * (1 - Math.min(0.6, Math.abs(rowc.x) / 140))
                Behavior on x { enabled: !rm.drag.active; NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Rectangle {
                    anchors.fill: parent
                    radius: w.cards ? w.rowR : 8
                    color: w.cards ? w.rowFill(row.index) : rm.containsMouse ? Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.07) : "transparent"
                }
                Rectangle { visible: w.lk === "lines" && row.index < lv.count - 1; anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.12) }
                UiIcon { id: box; visible: !w.cards; x: 4; anchors.verticalCenter: parent.verticalCenter; name: row.modelData.done ? "checkbox" : "checkboxEmpty"; size: 18; color: row.modelData.done ? w.ac : w.dim }
                // check do end4: redondo (ou quadrado) com contorno, marca quando feita
                Rectangle {
                    id: ck
                    visible: w.cards
                    x: 14; anchors.verticalCenter: parent.verticalCenter
                    width: 26; height: 26
                    radius: w.o("checkShape") === "square" ? 8 : 13
                    color: row.modelData.done ? row.ink : "transparent"
                    border.width: 2; border.color: row.ink
                    UiIcon { anchors.centerIn: parent; visible: row.modelData.done; name: "check"; size: 16; color: w.rowRole(row.index) === "none" ? Theme.bg : Theme.role(w.rowRole(row.index)) }
                }
                UiText {
                    anchors { left: w.cards ? ck.right : box.right; leftMargin: w.cards ? 12 : 8; right: x.left; rightMargin: 4; verticalCenter: parent.verticalCenter }
                    text: row.modelData.text; elide: Text.ElideRight
                    color: row.modelData.done ? (w.cards ? Qt.rgba(row.ink.r, row.ink.g, row.ink.b, 0.6) : w.dim) : row.ink
                    font.pixelSize: w.cards ? 15 : 13; font.strikeout: row.modelData.done && w.o("doneStyle") === "strike"
                }
                MouseArea {
                    id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    drag.target: rowc; drag.axis: Drag.XAxis; drag.minimumX: -w.width; drag.maximumX: w.cards ? 0 : w.width
                    preventStealing: drag.active
                    onClicked: w.toggle(row.modelData.i)
                    onReleased: { if (Math.abs(rowc.x) > 70) w.del(row.modelData.i); else rowc.x = 0 }
                }
                UiIcon {
                    id: x
                    anchors { right: parent.right; rightMargin: w.cards ? 14 : 6; verticalCenter: parent.verticalCenter }
                    visible: rm.containsMouse || xm.containsMouse
                    name: "close"; size: 14; color: xm.containsMouse ? (w.cards ? row.ink : Theme.danger) : (w.cards ? Qt.rgba(row.ink.r, row.ink.g, row.ink.b, 0.6) : w.dim)
                    MouseArea { id: xm; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: w.del(row.modelData.i) }
                }
            }
        }
        UiText { visible: lv.count === 0; anchors.centerIn: parent; text: w.items.length ? "Tudo feito!" : (w.adding ? "" : "Nenhuma tarefa. Toque em + para adicionar"); width: parent.width - 24; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; color: w.dim; font.pixelSize: 13 }
    }
    Rectangle {
        id: entry
        visible: w.entryOn
        anchors { left: parent.left; right: parent.right }
        anchors.top: w.entryTop ? (prog.visible ? prog.bottom : head.bottom) : undefined
        anchors.topMargin: w.entryTop ? 8 : 0
        anchors.bottom: w.entryTop ? undefined : parent.bottom
        height: w.cards ? 40 : 32; radius: w.cards ? w.rowR : 10
        color: w.cards ? Theme.role("surfaceLow") : Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.08)
        border.width: 1; border.color: input.activeFocus ? w.ac : "transparent"
        HoverHandler { onHoveredChanged: DeskState.wantKeys("todo-h-" + w.wid, hovered) }
        Component.onDestruction: { DeskState.wantKeys("todo-h-" + w.wid, false); DeskState.wantKeys("todo-f-" + w.wid, false) }
        UiIcon { id: plus; x: 12; anchors.verticalCenter: parent.verticalCenter; name: "plus"; size: 15; color: w.ac }
        TextInput {
            font.family: Theme.font
            id: input
            anchors { left: plus.right; leftMargin: 8; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            color: w.cards ? Theme.text : w.fg; font.pixelSize: w.cards ? 14 : 13; clip: true
            selectByMouse: true; selectionColor: Theme.accent
            onAccepted: { w.add(text); text = ""; if (w.cards && w.hdr === "title") w.adding = false }
            onActiveFocusChanged: DeskState.wantKeys("todo-f-" + w.wid, activeFocus)
            Keys.onEscapePressed: { input.focus = false; w.adding = false }
            UiText { visible: !input.text && !input.activeFocus; text: w.cards ? "Digite sua tarefa…" : "Nova tarefa…"; color: w.dim; font.pixelSize: input.font.pixelSize }
        }
    }
}
