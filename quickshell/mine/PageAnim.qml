// Pagina "Animacoes": biblioteca de animacoes nomeadas (curva de bezier + duracao); onde cada uma e usada se escolhe
// na pagina de cada coisa. O editor toca a curva em loop (bolinha com rastro) e as demonstracoes mostram a curva em uso.
import Quickshell
import QtQuick

Column {
    id: page
    spacing: 14

    property string sel: "Padrão"
    readonly property var cur: Settings.findAnim(sel) ?? Settings.builtinAnims[0]
    readonly property bool locked: !!cur.builtin
    function set(vals) { if (!page.locked) Settings.setAnimMany(page.cur.name, vals) }
    readonly property string css: "cubic-bezier(" + [cur.x1, cur.y1, cur.x2, cur.y2].map(v => (v / 100).toFixed(2)).join(", ") + ")"
    // onde esta animacao esta em uso
    readonly property var usedIn: Settings.animTargets.filter(t => (Settings.animUse[t.id] ?? Settings.animDefaults[t.id]) === cur.name)
    property string toast: ""
    Timer { id: toastT; interval: 1800; onTriggered: page.toast = "" }
    function say(s) { toast = s; toastT.restart() }

    Card {
        icon: "animation"
        title: "Animações"
        subtitle: "As do sistema (não editáveis) e as suas. Passe o mouse para ver a curva andando; clique para abrir."
        AnimPicker { editMode: true; selected: page.sel; onChosen: n => page.sel = n }
        UiButton { icon: "plus"; text: "Nova animação"; kind: "ghost"; onClicked: page.sel = Settings.addAnim(page.cur) }
    }

    Card {
        icon: page.locked ? "lock" : "curve"
        title: page.cur.name
        subtitle: page.locked ? "Animação do sistema: dá para ver e testar. Para mudar, duplique e edite a cópia." : "Arraste os pinos (Shift encaixa de 5 em 5). A bolinha mostra a animação acontecendo."

        // nome + onde e usada
        Row {
            width: parent.width
            spacing: 10
            visible: !page.locked
            UiIcon { name: "pencil"; size: 15; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "Nome"; color: Theme.text; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
            UiField { width: 240; text: page.cur.name; onEditingFinished: page.sel = Settings.renameAnim(page.cur.name, text) }
        }
        Flow {
            width: parent.width
            spacing: 6
            Text { text: page.usedIn.length ? "Em uso em:" : "Ainda não está em uso"; color: Theme.muted; font.pixelSize: 12; height: 24; verticalAlignment: Text.AlignVCenter }
            Repeater {
                model: page.usedIn
                delegate: Rectangle {
                    required property var modelData
                    height: 24; width: ul.implicitWidth + 16; radius: 12
                    color: Theme.tint(0.14); border.width: 1; border.color: Theme.tint(0.4)
                    Text { id: ul; anchors.centerIn: parent; text: modelData.label; color: Theme.text; font.pixelSize: 11 }
                }
            }
        }

        CurveEditor {
            id: ed
            width: parent.width
            x1: page.cur.x1; y1: page.cur.y1; x2: page.cur.x2; y2: page.cur.y2; duration: page.cur.duration
            editable: !page.locked
            playing: playBtn.on
            speed: slowBtn.on ? 0.25 : 1
            onEdited: vals => page.set(vals)
            // texto CSS no canto
            Rectangle {
                anchors { right: parent.right; top: parent.top; margins: 10 }
                width: cssT.implicitWidth + 16; height: 24; radius: 8
                color: Theme.card; border.width: 1; border.color: Theme.border
                Text { id: cssT; anchors.centerIn: parent; text: page.css; color: Theme.muted; font.pixelSize: 11; font.family: "monospace" }
            }
        }

        // controles da reproducao + CSS
        Flow {
            width: parent.width
            spacing: 6
            UiButton { id: playBtn; property bool on: true; icon: on ? "pause" : "play"; text: on ? "Pausar" : "Tocar em loop"; kind: on ? "accent" : "normal"; onClicked: on = !on }
            UiButton { icon: "refresh"; text: "Do início"; kind: "ghost"; onClicked: { playBtn.on = true; ed.replay() } }
            UiButton { id: slowBtn; property bool on: false; icon: "timer"; text: "Câmera lenta"; checked: on; onClicked: on = !on }
            UiButton { icon: "cards"; text: "Copiar CSS"; kind: "ghost"; onClicked: { Quickshell.clipboardText = page.css; page.say("Copiado: " + page.css) } }
            UiButton {
                visible: !page.locked
                icon: "send"; text: "Colar CSS"; kind: "ghost"
                onClicked: {
                    const n = (Quickshell.clipboardText.match(/-?\d*\.?\d+/g) || []).map(parseFloat)
                    if (n.length < 4) { page.say("A área de transferência não tem um cubic-bezier(…)"); return }
                    const cx = v => Math.round(Math.max(0, Math.min(1, v)) * 100), cy = v => Math.round(Math.max(-0.5, Math.min(1.5, v)) * 100)
                    page.set({ x1: cx(n[0]), y1: cy(n[1]), x2: cx(n[2]), y2: cy(n[3]) })
                    page.say("Curva colada")
                }
            }
            Text { visible: page.toast !== ""; text: page.toast; color: Theme.accent; font.pixelSize: 12; height: 36; verticalAlignment: Text.AlignVCenter }
        }

        // valores exatos
        Row {
            spacing: 8
            Repeater {
                model: [["x1", "X1", false], ["y1", "Y1", true], ["x2", "X2", false], ["y2", "Y2", true]]
                delegate: Row {
                    required property var modelData
                    spacing: 5
                    Text { text: modelData[1]; color: Theme.muted; font.pixelSize: 12; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                    UiField {
                        width: 66
                        enabled: !page.locked
                        text: (page.cur[modelData[0]] / 100).toFixed(2)
                        onEditingFinished: {
                            const v = parseFloat(text.replace(",", "."))
                            if (isNaN(v)) { text = (page.cur[modelData[0]] / 100).toFixed(2); return }
                            const lim = modelData[2] ? [-0.5, 1.5] : [0, 1]
                            const o = {}; o[modelData[0]] = Math.round(Math.max(lim[0], Math.min(lim[1], v)) * 100)
                            page.set(o)
                        }
                    }
                }
            }
        }
        UiSlider { label: "Duração"; icon: "timer"; from: 50; to: 1500; value: page.cur.duration; suffix: " ms"; onMoved: v => { if (!page.locked) page.set({ duration: Math.round(v / 10) * 10 }) } }

        // modelos prontos (so nas suas)
        UiLabel { visible: !page.locked; text: "Começar de um modelo" }
        Flow {
            visible: !page.locked
            width: parent.width
            spacing: 6
            Repeater {
                model: [["Suave", 25, 10, 25, 100], ["Entrada", 42, 0, 100, 100], ["Saída", 0, 0, 58, 100], ["Entrada e saída", 42, 0, 58, 100],
                        ["Desacelera forte", 5, 70, 10, 100], ["Volta (back)", 34, 156, 64, 100], ["Mola", 20, 150, 45, 90], ["Antecipa", 36, -40, 60, 100]]
                delegate: UiButton {
                    required property var modelData
                    text: modelData[0]; kind: "ghost"
                    onClicked: page.set({ x1: modelData[1], y1: modelData[2], x2: modelData[3], y2: modelData[4] })
                }
            }
        }

        Flow {
            width: parent.width
            spacing: 6
            UiButton { icon: "cards"; text: page.locked ? "Duplicar para editar" : "Duplicar"; kind: page.locked ? "accent" : "normal"; onClicked: page.sel = Settings.addAnim(page.cur) }
            UiButton { visible: !page.locked; icon: "trash"; text: "Excluir"; kind: "danger"; onClicked: { const n = page.cur.name; page.sel = "Padrão"; Settings.removeAnim(n) } }
        }
    }

    // ---------- demonstracoes: a curva aplicada a coisas de verdade (mesmo relogio do editor) ----------
    Card {
        icon: "play"
        title: "Em ação"
        subtitle: "A mesma animação movendo, crescendo e abrindo um painel. A sombra mostra como seria em linha reta."
        Row {
            id: demos
            width: parent.width
            spacing: 10
            readonly property real dw: (width - 20) / 3
            readonly property real e: ed.e
            readonly property real t: ed.t

            // deslizar
            Rectangle {
                width: demos.dw; height: 150; radius: 12
                color: Theme.track; border.width: 1; border.color: Theme.border
                clip: true
                Text { x: 12; y: 10; text: "Deslizar"; color: Theme.muted; font.pixelSize: 11; font.weight: Font.DemiBold }
                Rectangle { x: 16; width: parent.width - 32; y: parent.height / 2 + 2; height: 4; radius: 2; color: Theme.cardHi }
                Rectangle {   // sombra linear
                    width: 30; height: 30; radius: 9
                    y: parent.height / 2 - 13
                    x: 16 + demos.t * (parent.width - 32 - width)
                    color: "transparent"; border.width: 1.5; border.color: Qt.rgba(1, 1, 1, 0.25)
                }
                Rectangle {
                    width: 30; height: 30; radius: 9
                    y: parent.height / 2 - 13
                    x: 16 + demos.e * (parent.width - 32 - width)
                    color: Theme.accent
                }
            }
            // crescer
            Rectangle {
                width: demos.dw; height: 150; radius: 12
                color: Theme.track; border.width: 1; border.color: Theme.border
                clip: true
                Text { x: 12; y: 10; text: "Crescer"; color: Theme.muted; font.pixelSize: 11; font.weight: Font.DemiBold }
                Rectangle {
                    anchors.centerIn: parent; anchors.verticalCenterOffset: 8
                    width: 70; height: 70; radius: 18
                    color: "transparent"; border.width: 1.5; border.color: Qt.rgba(1, 1, 1, 0.18)
                    scale: 0.3 + 0.7 * demos.t
                }
                Rectangle {
                    anchors.centerIn: parent; anchors.verticalCenterOffset: 8
                    width: 70; height: 70; radius: 18
                    color: Theme.accent
                    opacity: Math.max(0, Math.min(1, demos.e * 2))
                    scale: Math.max(0, 0.3 + 0.7 * demos.e)
                    UiIcon { anchors.centerIn: parent; name: "apps"; size: 30; color: Theme.accentText }
                }
            }
            // painel saindo da moldura
            Rectangle {
                width: demos.dw; height: 150; radius: 12
                color: Theme.track; border.width: 1; border.color: Theme.border
                clip: true
                Text { x: 12; y: 10; text: "Painel"; color: Theme.muted; font.pixelSize: 11; font.weight: Font.DemiBold }
                Item {
                    id: scr
                    anchors { fill: parent; margins: 14; topMargin: 30 }
                    Rectangle { anchors.fill: parent; radius: 8; color: "transparent"; border.width: 4; border.color: Theme.card }   // moldura
                    // o painel cresce da borda de baixo (pode passar do ponto nas curvas elasticas)
                    Rectangle {
                        readonly property real full: scr.height * 0.62
                        width: scr.width * 0.6; height: 4 + (full - 4) * Math.max(0, demos.e)
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                        radius: 8
                        color: Theme.card
                        Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 8; color: Theme.card }
                        Column {
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                            spacing: 5
                            opacity: Math.max(0, Math.min(1, demos.e * 4 - 1))
                            Repeater { model: 3; delegate: Rectangle { required property int index; width: parent.width * (index === 0 ? 0.7 : 1); height: 6; radius: 3; color: index === 0 ? Theme.accent : Theme.cardHi } }
                        }
                    }
                }
            }
        }
    }
}
