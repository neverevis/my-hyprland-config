// Aba "IA" da barra lateral esquerda: conversa com Ollama (local), OpenAI/compativeis ou Gemini (Ai.qml).
import QtQuick
import QtQuick.Controls

Item {
    id: tab
    property bool cfg: false
    readonly property string typed: input.text
    readonly property var sugg: typed.length > 0 && typed[0] === "/" && typed.indexOf(" ") < 0
        ? Ai.commands.filter(c => c[0].indexOf(typed.toLowerCase()) === 0) : []
    function focusInput() { input.forceActiveFocus() }

    // ---- barra de estado ----
    Item {
        id: top
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 34
        Rectangle {
            anchors { left: parent.left; right: tools.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            height: 30; radius: 10; color: Theme.track; border.width: 1; border.color: Theme.border
            UiText {
                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight
                text: (Ai.backends.find(b => b[0] === Ai.backend) ?? ["", ""])[1] + (Ai.model !== "" ? "  ·  " + Ai.model : "")
                color: Theme.text; font.pixelSize: 12
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tab.cfg = !tab.cfg }
        }
        Row {
            id: tools
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 4
            UiButton { icon: "refresh"; kind: "ghost"; enabled: !Ai.busy && Ai.msgs.count > 0; onClicked: Ai.retry() }
            UiButton { icon: "trash"; kind: "ghost"; enabled: Ai.msgs.count > 0; onClicked: Ai.clear() }
            UiButton { icon: "cog"; kind: "ghost"; checked: tab.cfg; onClicked: tab.cfg = !tab.cfg }
        }
    }

    // ---- conversa ----
    ListView {
        id: list
        visible: !tab.cfg
        anchors { left: parent.left; right: parent.right; top: top.bottom; topMargin: 8; bottom: sugBox.top; bottomMargin: 6 }
        clip: true; spacing: 8
        model: Ai.msgs
        boundsBehavior: Flickable.StopAtBounds
        delegate: AiMsg { streaming: Ai.busy && index === Ai.msgs.count - 1 }
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        property bool stick: true
        onMovementEnded: stick = atYEnd
        Connections {
            target: Ai
            function onRevisionChanged() { if (list.stick || Ai.busy) Qt.callLater(list.positionViewAtEnd) }
        }
        // vazio
        Column {
            visible: Ai.msgs.count === 0
            anchors.centerIn: parent
            width: parent.width - 40
            spacing: 10
            UiIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "robot"; size: 40; color: Theme.accent }
            UiText { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "Pergunte alguma coisa"; color: Theme.text; font.pixelSize: 16; font.weight: Font.DemiBold }
            UiText {
                width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
                visible: Ai.blocker !== ""
                text: Ai.blocker; color: Theme.muted; font.pixelSize: 13
            }
            UiText {
                width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
                visible: Ai.blocker === ""
                text: "Digite / para ver os comandos (/clear, /save, /load…)."; color: Theme.muted; font.pixelSize: 12
            }
        }
    }

    // ---- configuracao ----
    Flickable {
        id: cfgV
        visible: tab.cfg
        anchors { left: parent.left; right: parent.right; top: top.bottom; topMargin: 8; bottom: sugBox.top; bottomMargin: 6 }
        contentHeight: cc.implicitHeight + 8; clip: true
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: cc
            width: cfgV.width - 4
            spacing: 10
            UiLabel { text: "Serviço" }
            UiSeg { fill: true; options: Ai.backends; value: Ai.backend; onPicked: v => { Settings.aiBackend = v; if (v === "ollama") Ai.refreshLocal() } }
            // Ollama
            Column {
                visible: Ai.backend === "ollama"; width: parent.width; spacing: 8
                UiField { width: parent.width; text: Settings.aiOllamaUrl; placeholderText: "http://localhost:11434"; onEditingFinished: { Settings.aiOllamaUrl = text.trim(); Ai.refreshLocal() } }
                UiText {
                    width: parent.width; wrapMode: Text.Wrap; font.pixelSize: 12; color: Ai.localState === "ok" ? Theme.muted : Theme.danger
                    text: Ai.localState === "down" ? "O Ollama não está rodando. Abra um terminal e rode: ollama serve"
                        : Ai.localState === "empty" ? "Nenhum modelo instalado. No terminal, rode: ollama pull <modelo>"
                        : Ai.localState === "ok" ? "Modelos instalados:" : "Os modelos aparecem ao enviar a primeira mensagem (ou em Procurar de novo)."
                }
                Flow {
                    width: parent.width; spacing: 6
                    Repeater {
                        model: Ai.localModels
                        delegate: UiButton { required property string modelData; text: modelData; checked: Settings.aiOllamaModel === modelData; onClicked: Settings.aiOllamaModel = modelData }
                    }
                }
                UiButton { text: "Procurar de novo"; icon: "refresh"; onClicked: Ai.refreshLocal() }
            }
            // OpenAI / Gemini
            Column {
                visible: Ai.backend !== "ollama"; width: parent.width; spacing: 8
                UiText { visible: Ai.backend === "openai"; text: "Endereço da API"; color: Theme.muted; font.pixelSize: 12 }
                UiField { visible: Ai.backend === "openai"; width: parent.width; text: Settings.aiOpenaiUrl; placeholderText: "https://api.openai.com/v1"; onEditingFinished: Settings.aiOpenaiUrl = text.trim() }
                UiText { text: "Modelo"; color: Theme.muted; font.pixelSize: 12 }
                UiField { width: parent.width; text: Ai.model; placeholderText: Ai.backend === "openai" ? "gpt-4o-mini" : "gemini-2.5-flash"; onEditingFinished: Ai.setModel(text.trim()) }
                UiText { text: Ai.hasKey ? "Chave de API salva (cole outra para trocar)" : "Chave de API"; color: Ai.hasKey ? Theme.accent : Theme.muted; font.pixelSize: 12 }
                Row {
                    width: parent.width; spacing: 6
                    UiField { id: keyF; width: parent.width - 80; echoMode: TextInput.Password; placeholderText: "cole a chave aqui" }
                    UiButton { text: "Salvar"; kind: "accent"; enabled: keyF.text.trim() !== ""; onClicked: { Ai.setKey(keyF.text); keyF.text = "" } }
                }
                UiText { width: parent.width; wrapMode: Text.Wrap; color: Theme.muted; font.pixelSize: 11; text: "A chave fica só neste computador (~/.local/share/quickshell-mine, permissão 600) e nunca aparece na linha de comando." }
            }
            UiSlider { width: parent.width; label: "Criatividade"; from: 0; to: 200; value: Settings.aiTemp; onMoved: v => Settings.aiTemp = v }
            UiText { text: "Instrução fixa (opcional)"; color: Theme.muted; font.pixelSize: 12 }
            UiField { width: parent.width; text: Settings.aiSystem; placeholderText: "Vazio usa a padrão, em português"; onEditingFinished: Settings.aiSystem = text }
            UiButton { text: "Voltar à conversa"; icon: "send"; kind: "accent"; onClicked: tab.cfg = false }
        }
    }

    // ---- sugestoes de comandos ----
    Rectangle {
        id: sugBox
        anchors { left: parent.left; right: parent.right; bottom: inBox.top; bottomMargin: tab.sugg.length ? 6 : 0 }
        height: tab.sugg.length ? sugCol.implicitHeight + 8 : 0
        visible: height > 0; radius: 10; color: Theme.card; border.width: 1; border.color: Theme.border
        Column {
            id: sugCol
            x: 4; y: 4; width: parent.width - 8
            Repeater {
                model: tab.sugg
                delegate: Rectangle {
                    required property var modelData
                    width: parent.width; height: 28; radius: 8
                    color: sm.containsMouse ? Theme.cardHi : "transparent"
                    UiText { x: 8; anchors.verticalCenter: parent.verticalCenter; text: modelData[0]; color: Theme.accent; font.pixelSize: 12; font.family: Theme.mono }
                    UiText { x: 78; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 86; elide: Text.ElideRight; text: modelData[1]; color: Theme.muted; font.pixelSize: 12 }
                    MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; onClicked: { input.text = modelData[0] + " "; input.cursorPosition = input.text.length; input.forceActiveFocus() } }
                }
            }
        }
    }

    // ---- entrada ----
    Rectangle {
        id: inBox
        anchors { left: parent.left; right: parent.right; bottom: foot.top; bottomMargin: 4 }
        height: Math.min(140, Math.max(44, input.contentHeight + 22)); radius: 14
        color: Theme.track; border.width: 1; border.color: input.activeFocus ? Theme.accent : Theme.border
        Flickable {
            anchors { left: parent.left; right: sendB.left; top: parent.top; bottom: parent.bottom; leftMargin: 10; rightMargin: 4; topMargin: 6; bottomMargin: 6 }
            contentHeight: input.contentHeight; clip: true
            TextArea.flickable: TextArea {
                id: input
                wrapMode: TextArea.Wrap
                color: Theme.text; font.pixelSize: 14; font.family: Theme.font
                placeholderText: "Escreva e tecle Enter (Shift+Enter quebra a linha)"; placeholderTextColor: Theme.muted
                selectionColor: Theme.accent; selectedTextColor: Theme.accentText
                background: null
                Keys.onPressed: ev => {
                    if ((ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) && !(ev.modifiers & Qt.ShiftModifier)) {
                        ev.accepted = true
                        const t = input.text; input.text = ""; Ai.send(t)
                    } else if (ev.key === Qt.Key_Tab && tab.sugg.length) {
                        ev.accepted = true; input.text = tab.sugg[0][0] + " "; input.cursorPosition = input.text.length
                    }
                }
            }
        }
        UiButton {
            id: sendB
            anchors { right: parent.right; rightMargin: 5; bottom: parent.bottom; bottomMargin: 5 }
            icon: Ai.busy ? "stopCircle" : "send"; kind: "accent"
            onClicked: { if (Ai.busy) Ai.stop(); else { const t = input.text; input.text = ""; Ai.send(t) } }
        }
    }
    UiText {
        id: foot
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 16
        text: "≈ " + (Ai.tokensIn + Ai.tokensOut) + " tokens  ·  criatividade " + (Settings.aiTemp / 100).toFixed(1)
        color: Theme.muted; font.pixelSize: 10; horizontalAlignment: Text.AlignRight
    }
}
