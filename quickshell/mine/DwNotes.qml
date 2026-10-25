// Widget de notas: varias notas salvas no proprio widget (opts.notes = [{ id, text }]; o antigo opts.text vira a primeira).
// Com altura 2+ mostra a lista (linhas coloridas, arraste para a esquerda apaga) e o + vira o cartao para o editor
// (animacao de virar). Com altura 1 abre direto a primeira nota, como o bloco unico de antes.
// Composicoes (opcao "look"): auto (a de sempre), end4 (titulo grande + botao redondo, linhas em cartoes de 55 px que ciclam
// primaria/secundaria/terciaria, editor em caixa) e linhas (lista solta com divisorias).
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
    function o(k) { return DeskState.opt({ type: "notes", opts: w.opts }, k) }

    // composicao: auto, cards (end4) ou lines
    readonly property string lk: { const l = o("look"); return l === "end4" ? "cards" : l === "lines" ? "lines" : "auto" }
    readonly property bool cards: lk === "cards"
    readonly property real pad: cards ? 14 : -1       // o DeskView usa como margem do conteudo (-1 = a padrao)
    readonly property real rowR: comp.innerRadius > 0 ? comp.innerRadius : 17
    function rowRole(i) {
        if (comp.innerRole && comp.innerRole !== "auto") return comp.innerRole
        const p = o("rowPalette")
        if (p === "primary") return "primaryContainer"
        if (p === "tertiary") return "tertiaryContainer"
        if (p === "none") return "none"
        return ["primaryContainer", "secondaryContainer", "tertiaryContainer"][i % 3]
    }
    function rowFill(i) { const r = rowRole(i); if (r === "none") return Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.08); const c = Theme.role(r); return Qt.rgba(c.r, c.g, c.b, comp.innerAlpha > 0 ? comp.innerAlpha : 1) }
    function rowInk(i) { const r = rowRole(i); return r === "none" ? w.fg : Theme.role(U.inkRole(r)) }

    readonly property var notes: {
        const l = Settings.list(opts.notes).map(n => ({ id: n.id, text: n.text ?? "" }))
        if (l.length === 0 && (opts.text ?? "") !== "") l.push({ id: "n0", text: opts.text })
        return l
    }
    readonly property bool single: rows < 2
    property string cur: ""                          // nota aberta no editor ("" = lista)
    readonly property string shown: single ? (notes.length ? notes[0].id : "n0") : cur
    readonly property bool inEditor: single || cur !== ""
    function save(l) { if (wid !== "") DeskState.setOpt(wid, "notes", l) }
    function setText(id, t) {
        const l = notes.slice(); const i = l.findIndex(n => n.id === id)
        if (i >= 0) l[i] = { id: id, text: t }; else l.push({ id: id, text: t })
        save(l)
    }
    function addNote() {
        const id = "n" + Date.now().toString(36)
        flipTo(() => { cur = id })
    }
    function closeEditor() {
        if (!single && cur !== "") {   // nota nova que ficou vazia nao fica na lista
            const n = notes.find(x => x.id === cur)
            if (!n || n.text === "") save(notes.filter(x => x.id !== cur))
        }
        flipTo(() => { cur = "" })
    }
    function remove(id) { save(notes.filter(n => n.id !== id)) }

    // virar o cartao: escala X 1 -> 0, troca o estado, 0 -> 1 (150 ms no total)
    property var pending: null
    function flipTo(fn) { pending = fn; flipA.restart() }
    SequentialAnimation {
        id: flipA
        NumberAnimation { target: face; property: "xs"; to: 0; duration: 75; easing.type: Easing.OutQuad }
        ScriptAction { script: { if (w.pending) w.pending(); w.pending = null } }
        NumberAnimation { target: face; property: "xs"; to: 1; duration: 75; easing.type: Easing.OutQuad }
    }

    Item {
        id: face
        anchors.fill: parent
        property real xs: 1
        transform: Scale { origin.x: face.width / 2; origin.y: face.height / 2; xScale: face.xs }

        Item {
            id: head
            width: parent.width; height: w.cards ? 36 : 28
            Row {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter
                UiIcon { visible: !w.cards; name: "pencil"; size: 16; color: w.ac; anchors.verticalCenter: parent.verticalCenter }
                UiText { text: w.o("title"); color: w.fg; font.pixelSize: w.cards ? 22 : 15; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
            }
            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 6
                Rectangle {
                    visible: w.inEditor && !w.single
                    width: 28; height: 28; radius: 14
                    color: dm.containsMouse ? Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.16) : Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.08)
                    UiIcon { anchors.centerIn: parent; name: "trash"; size: 15; color: w.fg }
                    MouseArea { id: dm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { const id = w.cur; w.flipTo(() => { w.remove(id); w.cur = "" }) } }
                }
                Rectangle {
                    visible: !w.single
                    width: 28; height: 28; radius: 14
                    color: w.inEditor ? (bm.containsMouse ? Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.16) : Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.08)) : w.ac
                    UiIcon { anchors.centerIn: parent; name: w.inEditor ? "arrowLeft" : "plus"; size: 16; color: w.inEditor ? w.fg : Theme.accentText }
                    MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: w.inEditor ? w.closeEditor() : w.addNote() }
                }
            }
        }

        // lista
        ListView {
            id: lv
            visible: !w.inEditor
            anchors { top: head.bottom; topMargin: 10; left: parent.left; right: parent.right; bottom: parent.bottom }
            clip: true; spacing: w.cards ? 8 : w.lk === "lines" ? 0 : (w.rows >= 3 ? 9 : 6)
            boundsBehavior: Flickable.StopAtBounds
            model: w.inEditor ? [] : w.notes
            // linha discreta no fim: mesma acao do botao +, para o espaco livre parecer proposital
            footer: Item {
                width: lv.width; height: w.notes.length > 0 && w.rows >= 2 ? 52 : 0
                visible: height > 0
                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 9 }
                    height: 40; radius: w.cards ? w.rowR : 14
                    color: fm.containsMouse ? Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.08) : "transparent"
                    border.width: 1; border.color: Qt.rgba(w.fg.r, w.fg.g, w.fg.b, fm.containsMouse ? 0.3 : 0.16)
                    Row {
                        anchors.centerIn: parent; spacing: 6
                        UiIcon { name: "plus"; size: 14; color: w.dim; anchors.verticalCenter: parent.verticalCenter }
                        UiText { text: "Nova nota"; color: w.dim; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { id: fm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: w.addNote() }
                }
            }
            delegate: Item {
                id: row
                required property var modelData
                required property int index
                width: lv.width; height: w.cards ? 55 : w.lk === "lines" ? 40 : (w.rows >= 3 ? 50 : 44)
                readonly property color tone: index % 3 === 0 ? w.ac : index % 3 === 1 ? w.ac2 : w.contInk
                readonly property color ink: w.cards ? w.rowInk(index) : w.fg
                readonly property var lines: row.modelData.text.split("\n").filter(l => l.trim() !== "")
                // end4: arrastar mostra o tile de erro por baixo
                Rectangle {
                    visible: w.cards && rb.x < 0
                    anchors.fill: parent; radius: w.rowR; color: Theme.danger
                    UiIcon { anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter } name: "trash"; size: 20; color: Theme.role("onError") }
                }
                Rectangle {
                    id: rb
                    width: parent.width; height: parent.height; radius: w.cards ? w.rowR : w.lk === "lines" ? 0 : 14
                    color: w.cards ? w.rowFill(row.index) : w.lk === "lines" ? (rm.containsMouse ? Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.07) : "transparent") : Qt.rgba(row.tone.r, row.tone.g, row.tone.b, rm.containsMouse ? 0.28 : 0.18)
                    opacity: 1 - Math.min(0.6, -rb.x / width)
                    Behavior on x { enabled: !drag.active; NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    Rectangle { visible: w.lk === "lines" && row.index < lv.count - 1; anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.12) }
                    UiText {
                        visible: !w.cards
                        anchors { left: parent.left; right: parent.right; leftMargin: 14; rightMargin: 14; verticalCenter: parent.verticalCenter }
                        text: row.modelData.text.split("\n")[0] || "Nota vazia"
                        elide: Text.ElideRight; color: row.modelData.text ? w.fg : w.dim; font.pixelSize: 13
                    }
                    // end4: primeira linha como titulo e a segunda como previa
                    Column {
                        visible: w.cards
                        anchors { left: parent.left; right: parent.right; leftMargin: 16; rightMargin: 16; verticalCenter: parent.verticalCenter }
                        UiText { width: parent.width; text: row.lines[0] ?? "Nota vazia"; elide: Text.ElideRight; color: row.ink; font.pixelSize: 15; font.weight: Font.DemiBold }
                        UiText { visible: row.lines.length > 1; width: parent.width; text: row.lines[1] ?? ""; elide: Text.ElideRight; color: Qt.rgba(row.ink.r, row.ink.g, row.ink.b, 0.65); font.pixelSize: 12 }
                    }
                    MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { const id = row.modelData.id; w.flipTo(() => { w.cur = id }) } }
                    DragHandler {
                        id: drag
                        target: rb; yAxis.enabled: false; xAxis.minimum: -row.width; xAxis.maximum: 0
                        onActiveChanged: if (!active) { if (rb.x < -row.width * 0.4) w.remove(row.modelData.id); else rb.x = 0 }
                    }
                }
            }
            UiText { visible: w.notes.length === 0; anchors.centerIn: parent; text: "Nenhuma nota. Toque no +"; color: w.dim; font.pixelSize: 13 }
        }

        // editor (end4: dentro de uma caixa)
        Rectangle {
            visible: w.cards && w.inEditor
            anchors { top: head.bottom; topMargin: 10; left: parent.left; right: parent.right; bottom: parent.bottom }
            radius: w.rowR; color: Theme.role("surfaceLow")
        }
        Flickable {
            id: fl
            visible: w.inEditor
            anchors { top: head.bottom; topMargin: w.cards ? 22 : 10; left: parent.left; right: parent.right; bottom: parent.bottom
                      leftMargin: w.cards ? 14 : 0; rightMargin: w.cards ? 14 : 0; bottomMargin: w.cards ? 12 : 0 }
            contentHeight: ed.contentHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            TextEdit {
                id: ed
                width: fl.width
                height: Math.max(fl.height, contentHeight)   // o bloco inteiro aceita o clique (nao so a primeira linha)
                wrapMode: TextEdit.Wrap
                color: w.fg; font.pixelSize: w.o("size"); font.family: w.o("mono") ? Theme.mono : Theme.fontReading
                selectionColor: Theme.accent; selectedTextColor: Theme.accentText
                selectByMouse: true
                function load() { const n = w.notes.find(x => x.id === w.shown); text = n ? n.text : "" }
                // o texto so vem das opcoes ao abrir a nota (e quando muda por fora, sem estar editando): digitar nao e interrompido
                Component.onCompleted: load()
                onTextChanged: if (activeFocus) saveT.restart()
                // a area de trabalho so recebe teclado quando um campo pede (mouse em cima ou escrevendo)
                onActiveFocusChanged: { DeskState.wantKeys("notes-f-" + w.wid, activeFocus); if (!activeFocus && w.shown !== "") w.setText(w.shown, text) }
                Keys.onEscapePressed: ed.focus = false
                UiText { visible: !ed.text && !ed.activeFocus; width: ed.width; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight; text: "Clique para escrever…"; color: w.dim; font.pixelSize: ed.font.pixelSize }
                onCursorRectangleChanged: { if (cursorRectangle.y + cursorRectangle.height > fl.contentY + fl.height) fl.contentY = cursorRectangle.y + cursorRectangle.height - fl.height }
            }
        }
    }
    onShownChanged: ed.load()
    onInEditorChanged: if (inEditor) ed.forceActiveFocus()
    HoverHandler { onHoveredChanged: DeskState.wantKeys("notes-h-" + w.wid, hovered) }
    Component.onDestruction: { DeskState.wantKeys("notes-h-" + w.wid, false); DeskState.wantKeys("notes-f-" + w.wid, false) }
    onNotesChanged: if (!ed.activeFocus) ed.load()
    Timer { id: saveT; interval: 700; onTriggered: if (w.shown !== "") w.setText(w.shown, ed.text) }
}
