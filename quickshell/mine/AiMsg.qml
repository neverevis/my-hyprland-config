// Uma mensagem do chat: o usuario fica num balao a direita; a IA e dividida em texto (Markdown), blocos de codigo
// (com Copiar) e blocos de raciocinio <think> (recolhidos). "error" e "note" sao avisos do proprio shell.
import Quickshell
import QtQuick

Item {
    id: m
    required property string role
    required property string content
    required property int index
    property bool streaming: false
    width: ListView.view ? ListView.view.width : 300
    implicitHeight: bubble.height + 6

    function parse(t) {
        const out = []
        let rest = t
        while (rest.length) {
            const th = rest.indexOf("<think>"), cd = rest.indexOf("```")
            if (th < 0 && cd < 0) { out.push({ k: "text", t: rest }); break }
            if (th >= 0 && (cd < 0 || th < cd)) {
                if (th > 0) out.push({ k: "text", t: rest.slice(0, th) })
                const e = rest.indexOf("</think>", th)
                out.push({ k: "think", t: rest.slice(th + 7, e < 0 ? rest.length : e).trim(), open: e < 0 })
                rest = e < 0 ? "" : rest.slice(e + 8)
            } else {
                if (cd > 0) out.push({ k: "text", t: rest.slice(0, cd) })
                const nl = rest.indexOf("\n", cd), e = rest.indexOf("```", cd + 3)
                const lang = nl < 0 ? "" : rest.slice(cd + 3, nl).trim()
                const body = nl < 0 ? "" : rest.slice(nl + 1, e < 0 ? rest.length : e)
                out.push({ k: "code", t: body.replace(/\n$/, ""), lang: lang, open: e < 0 })
                rest = e < 0 ? "" : rest.slice(e + 3)
            }
            rest = rest.replace(/^\n/, "")
        }
        return out.filter(s => s.t.trim() !== "" || s.k === "code")
    }
    readonly property var segs: role === "assistant" || role === "note" ? parse(content) : []

    Rectangle {
        id: bubble
        anchors.right: m.role === "user" ? parent.right : undefined
        anchors.left: m.role === "user" ? undefined : parent.left
        width: m.role === "user" ? Math.min(parent.width - 36, Math.max(60, utext.implicitWidth + 28)) : parent.width
        height: m.role === "user" ? utext.implicitHeight + 20 : col.implicitHeight + (m.role === "assistant" ? 24 : 16)
        radius: 14
        color: m.role === "user" ? Theme.accent
            : m.role === "error" ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.14)
            : m.role === "note" ? "transparent" : Theme.glc(Theme.card, 1.15)
        border.width: m.role === "assistant" || m.role === "error" ? 1 : 0
        border.color: m.role === "error" ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.5) : Theme.border

        UiText {
            id: utext
            visible: m.role === "user"
            x: 14; y: 10; width: parent.width - 28
            text: m.content; wrapMode: Text.Wrap
            color: Theme.accentText; font.pixelSize: 14
        }
        UiText {
            visible: m.role === "error"
            x: 12; y: 8; width: parent.width - 24
            text: m.content; wrapMode: Text.Wrap; color: Theme.danger; font.pixelSize: 13
        }
        Column {
            id: col
            visible: m.role === "assistant" || m.role === "note"
            x: 12; y: m.role === "assistant" ? 12 : 4; width: parent.width - 24
            spacing: 8
            UiText {   // resposta ainda vazia: pontinhos
                visible: m.role === "assistant" && m.content === ""
                text: "…"; color: Theme.muted; font.pixelSize: 14
            }
            Repeater {
                model: m.segs.length
                delegate: Loader {
                    id: sl
                    required property int index
                    readonly property var seg: m.segs[index] ?? ({ k: "text", t: "" })
                    width: col.width
                    sourceComponent: seg.k === "code" ? codeC : seg.k === "think" ? thinkC : textC
                }
            }
        }
    }

    Component {
        id: textC
        UiText {
            width: parent ? parent.width : 100
            text: parent && parent.seg ? parent.seg.t : ""
            textFormat: Text.MarkdownText
            wrapMode: Text.Wrap
            color: m.role === "note" ? Theme.muted : Theme.text
            linkColor: Theme.accent
            font.pixelSize: m.role === "note" ? 12 : 14
            font.italic: m.role === "note"
            onLinkActivated: link => Qt.openUrlExternally(link)
        }
    }
    Component {
        id: codeC
        Rectangle {
            id: cb
            readonly property var seg: parent ? parent.seg : ({ t: "", lang: "" })
            width: parent ? parent.width : 100
            height: head.height + ctext.implicitHeight + 18
            radius: 10
            color: Theme.track; border.width: 1; border.color: Theme.border
            property bool copied: false
            Item {
                id: head
                width: parent.width; height: 26
                UiText { x: 10; anchors.verticalCenter: parent.verticalCenter; text: cb.seg.lang || "código"; color: Theme.muted; font.pixelSize: 11; font.family: Theme.mono }
                Rectangle {
                    anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    width: cl.implicitWidth + 16; height: 20; radius: 8
                    color: cm.containsMouse ? Theme.cardHi : "transparent"
                    UiText { id: cl; anchors.centerIn: parent; text: cb.copied ? "Copiado" : "Copiar"; color: cb.copied ? Theme.accent : Theme.muted; font.pixelSize: 11 }
                    MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { Quickshell.clipboardText = cb.seg.t; cb.copied = true; rt.restart() } }
                    Timer { id: rt; interval: 1500; onTriggered: cb.copied = false }
                }
            }
            TextEdit {
                id: ctext
                x: 10; y: head.height; width: parent.width - 20
                readOnly: true; selectByMouse: true
                text: cb.seg.t; wrapMode: TextEdit.Wrap
                color: Theme.text; font.family: Theme.mono; font.pixelSize: 12
                selectionColor: Theme.accent; selectedTextColor: Theme.accentText
            }
        }
    }
    Component {
        id: thinkC
        Rectangle {
            id: tb
            readonly property var seg: parent ? parent.seg : ({ t: "", open: false })
            property bool shown: false
            width: parent ? parent.width : 100
            height: (tb.shown ? tcol.implicitHeight : 30) + 0
            radius: 10; clip: true
            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.05)
            Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Column {
                id: tcol
                width: parent.width
                Item {
                    width: parent.width; height: 30
                    UiIcon { x: 8; anchors.verticalCenter: parent.verticalCenter; name: "arrowDown"; size: 14; color: Theme.muted; rotation: tb.shown ? 0 : -90 }
                    UiText { x: 28; anchors.verticalCenter: parent.verticalCenter; text: tb.seg.open && m.streaming ? "Pensando…" : "Raciocínio"; color: Theme.muted; font.pixelSize: 12 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tb.shown = !tb.shown }
                }
                UiText {
                    x: 10; width: parent.width - 20
                    text: tb.seg.t; wrapMode: Text.Wrap; color: Theme.muted; font.pixelSize: 12; font.italic: true
                    bottomPadding: 8
                }
            }
        }
    }
}
