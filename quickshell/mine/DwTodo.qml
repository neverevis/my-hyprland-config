// Tarefas: lista salva no proprio widget (opts.items = [{ text, done }]). Enter adiciona, clique marca, X remove,
// "Limpar feitas" tira as concluidas. Barra de progresso opcional.
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
    function o(k) { return DeskState.opt({ type: "todo", opts: w.opts }, k) }

    readonly property var items: opts.items ?? []
    readonly property int doneCount: items.filter(i => i.done).length
    function save(list) { if (wid === "@home") Settings.homeTodo = list; else if (wid !== "") DeskState.setOpt(wid, "items", list) }
    function add(t) { t = t.trim(); if (t) save(items.concat([{ text: t, done: false }])) }
    function toggle(i) { const l = JSON.parse(JSON.stringify(items)); l[i].done = !l[i].done; save(l) }
    function del(i) { const l = items.slice(); l.splice(i, 1); save(l) }

    Row {
        id: head
        width: parent.width
        spacing: 8
        UiIcon { name: "listCheck"; size: 16; color: w.ac; anchors.verticalCenter: parent.verticalCenter }
        UiText { text: "Tarefas"; color: w.fg; font.pixelSize: 15; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
        UiText { text: w.items.length ? w.doneCount + "/" + w.items.length : ""; color: w.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
    }
    UiText {
        visible: w.doneCount > 0
        anchors { right: parent.right; verticalCenter: head.verticalCenter }
        text: "Limpar feitas"; color: cm.containsMouse ? w.ac : w.dim; font.pixelSize: 11
        MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: w.save(w.items.filter(i => !i.done)) }
    }
    Rectangle {
        id: prog
        visible: w.o("progress") && w.items.length > 0
        anchors { top: head.bottom; topMargin: 8 }
        width: parent.width; height: 4; radius: 2
        color: Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.12)
        Rectangle { width: parent.width * (w.items.length ? w.doneCount / w.items.length : 0); height: parent.height; radius: 2; color: w.ac
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } } }
    }
    ListView {
        id: lv
        anchors { top: prog.visible ? prog.bottom : head.bottom; topMargin: 8; left: parent.left; right: parent.right; bottom: entry.top; bottomMargin: 6 }
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: w.items.map((it, i) => ({ text: it.text, done: it.done, i: i })).filter(x => !(w.o("hideDone") && x.done))
        delegate: Item {
            id: row
            required property var modelData
            width: lv.width; height: 30
            // arrastar a linha para o lado mais de 70 px apaga a tarefa (o fundo avermelha ate la)
            Rectangle { anchors.fill: parent; radius: 8; color: Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, Math.min(1, Math.abs(rowc.x) / 70) * 0.35); visible: rowc.x !== 0 }
            Item {
                id: rowc
                width: parent.width; height: parent.height
                opacity: 1 - Math.min(0.6, Math.abs(rowc.x) / 140)
                Behavior on x { enabled: !rm.drag.active; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Rectangle { anchors.fill: parent; radius: 8; color: rm.containsMouse ? Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.07) : "transparent" }
                UiIcon { id: box; x: 4; anchors.verticalCenter: parent.verticalCenter; name: row.modelData.done ? "checkbox" : "checkboxEmpty"; size: 18; color: row.modelData.done ? w.ac : w.dim }
                UiText {
                    anchors { left: box.right; leftMargin: 8; right: x.left; rightMargin: 4; verticalCenter: parent.verticalCenter }
                    text: row.modelData.text; elide: Text.ElideRight
                    color: row.modelData.done ? w.dim : w.fg; font.pixelSize: 13; font.strikeout: row.modelData.done
                }
                MouseArea {
                    id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    drag.target: rowc; drag.axis: Drag.XAxis; drag.minimumX: -w.width; drag.maximumX: w.width
                    preventStealing: drag.active
                    onClicked: w.toggle(row.modelData.i)
                    onReleased: { if (Math.abs(rowc.x) > 70) w.del(row.modelData.i); else rowc.x = 0 }
                }
                UiIcon {
                    id: x
                    anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    visible: rm.containsMouse || xm.containsMouse
                    name: "close"; size: 14; color: xm.containsMouse ? Theme.danger : w.dim
                    MouseArea { id: xm; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: w.del(row.modelData.i) }
                }
            }
        }
        UiText { visible: lv.count === 0; anchors.centerIn: parent; text: w.items.length ? "Tudo feito!" : "Nada por aqui"; color: w.dim; font.pixelSize: 13 }
    }
    Rectangle {
        id: entry
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 32; radius: 10
        color: Qt.rgba(w.fg.r, w.fg.g, w.fg.b, 0.08)
        border.width: 1; border.color: input.activeFocus ? w.ac : "transparent"
        HoverHandler { onHoveredChanged: DeskState.wantKeys("todo-h-" + w.wid, hovered) }
        Component.onDestruction: { DeskState.wantKeys("todo-h-" + w.wid, false); DeskState.wantKeys("todo-f-" + w.wid, false) }
        UiIcon { id: plus; x: 9; anchors.verticalCenter: parent.verticalCenter; name: "plus"; size: 15; color: w.ac }
        TextInput {
            font.family: Theme.font
            id: input
            anchors { left: plus.right; leftMargin: 8; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            color: w.fg; font.pixelSize: 13; clip: true
            selectByMouse: true; selectionColor: Theme.accent
            onAccepted: { w.add(text); text = "" }
            onActiveFocusChanged: DeskState.wantKeys("todo-f-" + w.wid, activeFocus)
            Keys.onEscapePressed: input.focus = false
            UiText { visible: !input.text && !input.activeFocus; text: "Nova tarefa…"; color: w.dim; font.pixelSize: 13 }
        }
    }
}
