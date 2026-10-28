// Barra de icones da maquete do terminal. "Pecas": icones que arrastam para a maquete (e voltam para ca para sair); os que ja estao em
// uso ficam preenchidos com um ponto. "Ajustes": botoes que abrem um popover pequeno ancorado no botao (so existe aberto: Loader).
import Quickshell
import QtQuick

Rectangle {
    id: tb
    property var ctl
    width: parent ? parent.width : 600
    height: body.implicitHeight + SetK.md * 2
    radius: SetK.innerRadius + 2
    color: Theme.track
    border.width: 1
    border.color: root_dropHint ? Theme.accent : Theme.border
    readonly property bool root_dropHint: ctl && ctl.dragging && !ctl.dTray && ctl.inRect(tb, ctl.dX, ctl.dY)

    readonly property var promptPieces: TermPrompt.pieces.map(p => [p.k, "prompt", p.icon, p.label]).concat([["err", "flag", "info", "Erro do último comando"]])
    readonly property var fetchPieces: TermFetch.catalog.map(c => [c.k, "fetch", c.icon, c.label]).concat([["image", "image", "image", "Imagem"]])
    readonly property var tweaks: [
        ["terminal", "console", "Terminal padrão"], ["font", "font", "Fonte e tamanho"], ["cursor", "cursorMove", "Cursor"],
        ["opacity", "opacity", "Transparência"], ["pad", "frame", "Margem"], ["bg", "images", "Imagem de fundo"],
        ["sym", "palette", "Símbolo e cor do prompt"], ["dir", "folderOpen", "Estilo da pasta"], ["lines", "alignLeft", "Linhas do prompt"],
        ["use", "tune", "Usar prompt e boas-vindas do shell"], ["imgsize", "resize", "Tamanho da imagem"]
    ]
    function used(g, k) {
        if (g === "prompt") return Terminal.starship && TermPrompt.on && TermPrompt.get(k)
        if (g === "flag") return TermPrompt.get("err")
        if (k === "image") return TermFetch.image !== ""
        return TermFetch.get(k) === true
    }

    // ---- popover aberto ----
    property string openKey: ""
    property string shownKey: ""
    property real ax: 0
    property real ay: 0
    property real fade: openKey !== "" ? 1 : 0
    Behavior on fade { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    function toggle(key, btn) {
        if (openKey === key) { openKey = ""; return }
        const p = btn.mapToItem(tb, btn.width / 2, btn.height)
        ax = p.x; ay = p.y; shownKey = key; openKey = key
    }
    z: 10

    // peca ou ajuste: botao redondo com tooltip local
    component TBtn: Item {
        id: bt
        property string icon
        property string tip
        property bool on: false       // peca em uso
        property bool open: false     // popover aberto
        property string group
        property string key
        property bool piece: true
        signal tap
        width: 38; height: 38
        z: da.containsMouse ? 20 : 0
        opacity: tb.ctl && tb.ctl.dragging && tb.ctl.dKey === key && tb.ctl.dTray ? 0.35 : 1
        Rectangle {
            anchors.fill: parent; radius: 12
            color: bt.open || bt.on ? Theme.tint(0.16) : da.containsMouse ? Theme.cardHi : "transparent"
            border.width: bt.on || bt.open ? 1 : 0; border.color: Theme.tint(0.5)
            scale: da.pressed ? 0.97 : 1
            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 120 } }
            UiIcon { anchors.centerIn: parent; name: bt.icon; size: 19; color: bt.on || bt.open ? Theme.accent : Theme.muted }
            Rectangle { visible: bt.on; x: parent.width - 11; y: 5; width: 6; height: 6; radius: 3; color: Theme.accent }
        }
        TermDrag { id: da; anchors.fill: parent; ctl: tb.ctl; group: bt.group; key: bt.key; tray: true; canDrag: bt.piece; onTap: bt.tap() }
        Rectangle {
            visible: da.containsMouse && !da.moved && !(tb.ctl && tb.ctl.dragging)
            x: Math.max(-bt.x + 4, Math.min((bt.width - width) / 2, tb.width - bt.x - width - 4)); y: bt.height + 6
            width: tipT.implicitWidth + 16; height: 26; radius: 8
            color: Theme.cardHi; border.width: 1; border.color: Theme.border
            UiText { id: tipT; anchors.centerIn: parent; text: bt.tip; color: Theme.text; font.pixelSize: 12 }
        }
    }

    Column {
        id: body
        x: SetK.md; y: SetK.md; width: parent.width - SetK.md * 2
        spacing: SetK.sm

        UiText { text: "Peças (arraste para a maquete)"; color: Theme.muted; font.pixelSize: SetK.fDesc; font.weight: Font.DemiBold }
        Row {
            visible: Terminal.starship; spacing: SetK.sm
            UiText { width: 84; height: 38; verticalAlignment: Text.AlignVCenter; text: "Prompt"; color: Theme.muted; font.pixelSize: SetK.fDesc }
            Flow {
                width: body.width - 84 - SetK.sm; spacing: 6
                Repeater {
                    model: tb.promptPieces
                    delegate: TBtn { required property var modelData; key: modelData[0]; group: modelData[1]; icon: modelData[2]; tip: modelData[3]
                                     on: tb.used(group, key); onTap: tb.ctl.toolClick(group, key) }
                }
            }
        }
        Row {
            visible: Terminal.fastfetch; spacing: SetK.sm
            UiText { width: 84; height: 38; verticalAlignment: Text.AlignVCenter; text: "Boas-vindas"; color: Theme.muted; font.pixelSize: SetK.fDesc }
            Flow {
                width: body.width - 84 - SetK.sm; spacing: 6
                Repeater {
                    model: tb.fetchPieces
                    delegate: TBtn { required property var modelData; key: modelData[0]; group: modelData[1]; icon: modelData[2]; tip: modelData[3]
                                     on: tb.used(group, key); onTap: tb.ctl.toolClick(group, key) }
                }
            }
        }
        Rectangle { width: parent.width; height: 1; color: Theme.border; opacity: 0.6 }
        UiText { text: "Ajustes"; color: Theme.muted; font.pixelSize: SetK.fDesc; font.weight: Font.DemiBold }
        Flow {
            width: parent.width; spacing: 6
            Repeater {
                model: tb.tweaks
                delegate: TBtn {
                    id: tw
                    required property var modelData
                    piece: false; key: modelData[0]; icon: modelData[1]; tip: modelData[2]
                    open: tb.openKey === key
                    onTap: tb.toggle(key, tw)
                }
            }
        }
    }

    // clicar fora fecha (o clique nao passa adiante)
    MouseArea { enabled: tb.openKey !== ""; x: -4000; y: -4000; width: 8000; height: 8000; z: 40; onPressed: tb.openKey = "" }

    Loader {
        id: popL
        active: tb.openKey !== "" || tb.fade > 0.01
        z: 50
        readonly property real pw: 344
        x: Math.max(0, Math.min(tb.ax - pw / 2, tb.width - pw)); y: tb.ay + 8
        width: pw
        opacity: tb.fade
        transform: Scale { origin.x: tb.ax - popL.x; origin.y: -8; xScale: 0.96 + 0.04 * tb.fade; yScale: 0.96 + 0.04 * tb.fade }
        sourceComponent: pop
        onLoaded: item.forceActiveFocus()
    }

    // moldura do popover + o conteudo do ajuste aberto
    Component {
        id: pop
        Rectangle {
            id: pp
            implicitHeight: pcol.implicitHeight + 28
            radius: 16
            color: Theme.gl(Theme.bg, 1)
            border.width: 1; border.color: Theme.border
            focus: true
            Keys.onEscapePressed: tb.openKey = ""
            MouseArea { anchors.fill: parent }
            Column {
                id: pcol
                x: 16; y: 14; width: parent.width - 32; spacing: 12
                UiText { text: tb.tweaks.find(t => t[0] === tb.shownKey)?.[2] ?? ""; color: Theme.text; font.pixelSize: 14; font.weight: Font.DemiBold }
                Loader { width: parent.width; sourceComponent: ({ terminal: cTerm, font: cFont, cursor: cCursor, opacity: cOpacity, pad: cPad, bg: cBg, sym: cSym, dir: cDir, lines: cLines, use: cUse, imgsize: cImgSize })[tb.shownKey] ?? null }
            }
        }
    }

    Component {
        id: cTerm
        Flow {
            spacing: 8
            Repeater {
                model: [["", "Automático", "auto", "usa o " + Terminal.autoName]].concat(Terminal.installed.map(id => { const t = Terminal.info(id); return [id, t.name, t.icon, ""] }))
                delegate: Rectangle {
                    id: tl
                    required property var modelData
                    readonly property bool sel: (Settings.defaultTerminal || "") === modelData[0]
                    width: 94; height: 78; radius: 12
                    color: sel ? Theme.tint(0.16) : tm.containsMouse ? Theme.cardHi : Theme.card
                    border.width: 1; border.color: sel ? Theme.accent : Theme.border
                    scale: tm.pressed ? 0.97 : 1
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                    Column {
                        anchors.centerIn: parent; spacing: 5
                        Item {
                            width: 30; height: 30; anchors.horizontalCenter: parent.horizontalCenter
                            UiIcon { visible: tl.modelData[0] === ""; anchors.centerIn: parent; name: "auto"; size: 24; color: tl.sel ? Theme.accent : Theme.muted }
                            Image { visible: tl.modelData[0] !== ""; anchors.centerIn: parent; width: 28; height: 28; sourceSize: Qt.size(56, 56); fillMode: Image.PreserveAspectFit
                                    source: tl.modelData[0] !== "" ? Icons.path(tl.modelData[2], "utilities-terminal") : "" }
                        }
                        UiText { anchors.horizontalCenter: parent.horizontalCenter; text: tl.modelData[1]; color: tl.sel ? Theme.accent : Theme.text; font.pixelSize: 12 }
                    }
                    MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.defaultTerminal = tl.modelData[0] }
                }
            }
            UiText { width: parent.width; wrapMode: Text.WordWrap; text: "Automático usa o " + Terminal.autoName + ". Vale para o launcher e os botões do shell."; color: Theme.muted; font.pixelSize: 12 }
        }
    }
    Component {
        id: cFont
        Column {
            spacing: 10
            UiText { visible: !Terminal.lookOk; width: parent.width; wrapMode: Text.WordWrap; text: "Por enquanto só o kitty e o foot têm estas opções"; color: Theme.muted; font.pixelSize: 12 }
            OptionsForm {
                visible: Terminal.lookOk; width: parent.width
                schema: [{ key: "font", label: "Fonte", icon: "font", type: "font" }]
                get: k => Terminal.look("font") || ""
                set: (k, v) => Terminal.setLook("font", v || undefined)
            }
            UiSlider { visible: Terminal.lookOk; width: parent.width; label: "Tamanho"; icon: "textSize"; from: 6; to: 32; suffix: " pt"; value: Terminal.look("fontSize") ?? 12; onMoved: v => Terminal.setLook("fontSize", v) }
        }
    }
    Component {
        id: cCursor
        Column {
            spacing: 12
            UiText { visible: !Terminal.lookOk; width: parent.width; wrapMode: Text.WordWrap; text: "Por enquanto só o kitty e o foot têm estas opções"; color: Theme.muted; font.pixelSize: 12 }
            UiSeg { visible: Terminal.lookOk; fill: true; value: Terminal.look("cursor") || "block"; options: [["beam", "Barra"], ["block", "Bloco"], ["underline", "Sublinhado"]]; onPicked: v => Terminal.setLook("cursor", v) }
            UiSwitch { visible: Terminal.lookOk; label: "Piscar"; icon: "pulse"; checked: Terminal.look("blink") === true; onToggled: on => Terminal.setLook("blink", on) }
        }
    }
    Component {
        id: cOpacity
        Column {
            spacing: 10
            UiSlider { visible: Terminal.lookOk; width: parent.width; label: "Transparência"; icon: "opacity"; from: 0; to: 80; suffix: " %"; value: 100 - (Terminal.look("opacity") ?? 100); onMoved: v => Terminal.setLook("opacity", 100 - v) }
            UiText { width: parent.width; wrapMode: Text.WordWrap; text: Terminal.lookOk ? "Do fundo do terminal; o texto continua nítido" : "Por enquanto só o kitty e o foot têm estas opções"; color: Theme.muted; font.pixelSize: 12 }
        }
    }
    Component {
        id: cPad
        Column {
            spacing: 10
            UiSlider { visible: Terminal.lookOk; width: parent.width; label: "Margem interna"; icon: "frame"; from: 0; to: 60; suffix: " px"; value: Terminal.look("pad") ?? 0; onMoved: v => Terminal.setLook("pad", v) }
            UiText { visible: !Terminal.lookOk; width: parent.width; wrapMode: Text.WordWrap; text: "Por enquanto só o kitty e o foot têm estas opções"; color: Theme.muted; font.pixelSize: 12 }
        }
    }
    Component {
        id: cBg
        Column {
            spacing: 12
            UiText { visible: !Terminal.hasImage; width: parent.width; wrapMode: Text.WordWrap; text: "O " + Terminal.termName + " não tem imagem de fundo"; color: Theme.muted; font.pixelSize: 12 }
            UiText { visible: Terminal.hasImage; width: parent.width; elide: Text.ElideMiddle; text: (Terminal.look("image") || "") === "" ? "Nenhuma imagem" : (Terminal.look("image") || "").split("/").pop(); color: Theme.muted; font.pixelSize: 12 }
            Row {
                visible: Terminal.hasImage; spacing: 8
                UiButton { icon: "folderOpen"; text: "Escolher"; onClicked: Pick.image("Imagem de fundo do terminal", p => Terminal.setLook("image", p)) }
                UiButton { visible: (Terminal.look("image") || "") !== ""; icon: "trash"; text: "Remover"; kind: "ghost"; onClicked: Terminal.setLook("image", "") }
            }
            UiLabel { visible: Terminal.hasImage; text: "Preenchimento" }
            UiSeg { visible: Terminal.hasImage; fill: true; value: Terminal.look("layout") || "tile"; options: [["fill", "Preencher"], ["fit", "Ajustar"], ["center", "Centro"], ["tile", "Repetir"]]; onPicked: v => Terminal.setLook("layout", v) }
            UiSlider { visible: Terminal.hasImage; width: parent.width; label: "Escurecer"; icon: "night"; from: 0; to: 100; suffix: " %"; value: Terminal.look("tint") ?? 0; onMoved: v => Terminal.setLook("tint", v) }
        }
    }
    Component {
        id: cSym
        Column {
            spacing: 12
            UiLabel { text: "Símbolo" }
            UiSeg { fill: true; value: TermPrompt.get("sym"); options: [["❯", "❯"], ["$", "$"], ["›", "›"], ["λ", "λ"], ["➜", "➜"]]; onPicked: v => TermPrompt.set("sym", v) }
            UiLabel { text: "Cor (vem do tema)" }
            UiSeg { fill: true; value: TermPrompt.get("color"); options: [["accent", "Destaque"], ["secondary", "Secundária"], ["tertiary", "Terciária"]]; onPicked: v => TermPrompt.set("color", v) }
        }
    }
    Component {
        id: cDir
        Column {
            spacing: 10
            UiSeg { fill: true; value: TermPrompt.get("dirStyle"); options: [["name", "Só o nome"], ["short", "Curto"], ["full", "Completo"]]; onPicked: v => TermPrompt.set("dirStyle", v) }
            UiText { width: parent.width; wrapMode: Text.WordWrap; text: "O caminho curto mostra até 3 níveis"; color: Theme.muted; font.pixelSize: 12 }
        }
    }
    Component {
        id: cLines
        Column {
            spacing: 14
            UiSwitch { label: "Em duas linhas"; description: "O símbolo vai para a linha de baixo"; checked: TermPrompt.get("two"); onToggled: on => TermPrompt.set("two", on) }
            UiSwitch { label: "Linha em branco entre comandos"; checked: TermPrompt.get("gap"); onToggled: on => TermPrompt.set("gap", on) }
        }
    }
    Component {
        id: cUse
        Column {
            spacing: 14
            UiSwitch { visible: Terminal.starship; label: "Prompt montado aqui"; description: "Desligado, vale o seu ~/.config/starship.toml"; checked: TermPrompt.on; onToggled: on => TermPrompt.set("on", on) }
            UiSwitch { visible: Terminal.fastfetch; label: "Boas-vindas montadas aqui"; description: TermFetch.on ? "Desligue para voltar às suas boas-vindas de antes" : "Mudar a imagem ou os itens liga sozinho"; checked: TermFetch.on; onToggled: on => TermFetch.set("on", on) }
            UiText { visible: !Terminal.starship && !Terminal.fastfetch; width: parent.width; wrapMode: Text.WordWrap; text: "Faltam o starship e o fastfetch (veja “Ferramentas que faltam” abaixo)"; color: Theme.muted; font.pixelSize: 12 }
            UiText { width: parent.width; wrapMode: Text.WordWrap; text: "Vale para terminais novos (o fish lê isto ao abrir)"; color: Theme.muted; font.pixelSize: 12 }
        }
    }
    Component {
        id: cImgSize
        Column {
            spacing: 10
            UiSlider { width: parent.width; label: "Largura da imagem"; icon: "resize"; from: 0; to: 60; suffix: " col."; value: TermFetch.imgSize
                       onMoved: v => TermFetch.set("imgSize", v === 0 ? undefined : Math.max(10, v)) }
            UiText { width: parent.width; wrapMode: Text.WordWrap; text: "0 é automático. Também dá para puxar os cantos da imagem na maquete."; color: Theme.muted; font.pixelSize: 12 }
        }
    }
}
