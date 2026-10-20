// Widget de notas: varias notas salvas no proprio widget (opts.notes = [{ id, text }]; o antigo opts.text vira a primeira).
// Com altura 2+ mostra a lista (linhas coloridas, arraste para a esquerda apaga) e o + vira o cartao para o editor
// (animacao de virar). Com altura 1 abre direto a primeira nota, como o bloco unico de antes.
import QtQuick

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
    function o(k) { return DeskState.opt({ type: "notes", opts: w.opts }, k) }

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
        NumberAnimation { target: face; property: "xs"; to: 0; duration: 75; easing.type: Easing.InQuad }
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
            width: parent.width; height: 28
            Row {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter
                UiIcon { name: "pencil"; size: 16; color: w.ac; anchors.verticalCenter: parent.verticalCenter }
                UiText { text: w.o("title"); color: w.fg; font.pixelSize: 15; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
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
            clip: true; spacing: 6
            boundsBehavior: Flickable.StopAtBounds
            model: w.inEditor ? [] : w.notes
            delegate: Item {
                id: row
                required property var modelData
                required property int index
                width: lv.width; height: 44
                readonly property color tone: index % 3 === 0 ? w.ac : index % 3 === 1 ? w.ac2 : w.contInk
                Rectangle {
                    id: rb
                    width: parent.width; height: parent.height; radius: 14
                    color: Qt.rgba(row.tone.r, row.tone.g, row.tone.b, rm.containsMouse ? 0.28 : 0.18)
                    opacity: 1 - Math.min(0.6, -rb.x / width)
                    Behavior on x { enabled: !drag.active; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    UiText {
                        anchors { left: parent.left; right: parent.right; leftMargin: 14; rightMargin: 14; verticalCenter: parent.verticalCenter }
                        text: row.modelData.text.split("\n")[0] || "Nota vazia"
                        elide: Text.ElideRight; color: row.modelData.text ? w.fg : w.dim; font.pixelSize: 13
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

        // editor
        Flickable {
            id: fl
            visible: w.inEditor
            anchors { top: head.bottom; topMargin: 10; left: parent.left; right: parent.right; bottom: parent.bottom }
            contentHeight: ed.contentHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            TextEdit {
                id: ed
                width: fl.width
                height: Math.max(fl.height, contentHeight)   // o bloco inteiro aceita o clique (nao so a primeira linha)
                wrapMode: TextEdit.Wrap
                color: w.fg; font.pixelSize: w.o("size"); font.family: w.o("mono") ? Theme.mono : Theme.font
                selectionColor: Theme.accent; selectedTextColor: Theme.accentText
                selectByMouse: true
                function load() { const n = w.notes.find(x => x.id === w.shown); text = n ? n.text : "" }
                // o texto so vem das opcoes ao abrir a nota (e quando muda por fora, sem estar editando): digitar nao e interrompido
                Component.onCompleted: load()
                onTextChanged: if (activeFocus) saveT.restart()
                // a area de trabalho so recebe teclado quando um campo pede (mouse em cima ou escrevendo)
                onActiveFocusChanged: { DeskState.wantKeys("notes-f-" + w.wid, activeFocus); if (!activeFocus && w.shown !== "") w.setText(w.shown, text) }
                Keys.onEscapePressed: ed.focus = false
                UiText { visible: !ed.text && !ed.activeFocus; text: "Clique para escrever…"; color: w.dim; font.pixelSize: ed.font.pixelSize }
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
