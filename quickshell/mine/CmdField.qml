// Campo de comando com ajuda: botao "Escolher app" (CmdBelow.qml abre a lista) e aviso quando o programa nao existe.
// Uso numa SetRow: CmdField { id: f; ... }  e  below: CmdBelow { f: f }.  A checagem roda so quando o texto muda (400 ms de pausa).
import Quickshell
import Quickshell.Io
import QtQuick

Row {
    id: root
    property alias text: fld.text
    property alias placeholderText: fld.placeholderText
    property alias field: fld
    property int fieldWidth: 240
    property bool picking: false
    property string missing: ""          // nome do programa que nao foi achado ("" = tudo certo)
    signal accepted
    signal committed                     // enter, sair do campo ou escolher um app
    spacing: SetK.sm

    function setCommand(c) { fld.text = c; root.picking = false; root.committed() }
    function firstWord(t) {
        const w = String(t).trim().split(/\s+/)
        for (const x of w) { if (/^[A-Za-z_][A-Za-z0-9_]*=/.test(x)) continue; return x.replace(/^["']|["']$/g, "") }
        return ""
    }
    UiField {
        id: fld
        width: root.fieldWidth
        onTextChanged: chkTimer.restart()
        onAccepted: { root.accepted(); root.committed() }
        onEditingFinished: root.committed()
    }
    UiButton { text: "Escolher app"; icon: "apps"; kind: "ghost"; checked: root.picking; onClicked: root.picking = !root.picking }
    Timer { id: chkTimer; interval: 400; onTriggered: { const w = root.firstWord(fld.text); if (w === "") root.missing = ""; else { chk.word = w; chk.running = false; chk.running = true } } }
    Process {
        id: chk
        property string word: ""
        command: ["sh", "-c", 'command -v -- "$1" >/dev/null 2>&1', "sh", chk.word]
        onExited: code => root.missing = code === 0 ? "" : chk.word
    }
}
