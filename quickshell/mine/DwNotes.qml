// Widget de notas: um bloco de texto que fica salvo (no proprio widget, em opts.text). 1x1: so as primeiras linhas.
import QtQuick

Item {
    id: w
    property int cols: 2
    property int rows: 2
    property var opts: ({})
    property string wid: ""

    Row {
        id: head
        spacing: 8
        UiIcon { name: "pencil"; size: 16; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
        Text { text: "Notas"; color: Theme.text; font.pixelSize: 15; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
    }
    Flickable {
        id: fl
        anchors { top: head.bottom; topMargin: 10; left: parent.left; right: parent.right; bottom: parent.bottom }
        contentHeight: ed.contentHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        TextEdit {
            id: ed
            width: fl.width
            wrapMode: TextEdit.Wrap
            color: Theme.text; font.pixelSize: 14
            selectionColor: Theme.accent; selectedTextColor: Theme.accentText
            // o texto so vem das opcoes ao abrir (e quando muda por fora, sem estar editando): digitar nao e interrompido
            Component.onCompleted: text = w.opts.text ?? ""
            onTextChanged: if (activeFocus) saveT.restart()
            Text { visible: !ed.text && !ed.activeFocus; text: "Clique para escrever…"; color: Theme.muted; font.pixelSize: 14 }
            onCursorRectangleChanged: { if (cursorRectangle.y + cursorRectangle.height > fl.contentY + fl.height) fl.contentY = cursorRectangle.y + cursorRectangle.height - fl.height }
        }
    }
    onOptsChanged: if (!ed.activeFocus && (opts.text ?? "") !== ed.text) ed.text = opts.text ?? ""
    Timer { id: saveT; interval: 700; onTriggered: if (w.wid !== "") DeskState.setOpt(w.wid, "text", ed.text) }
}
