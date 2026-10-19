// Escolhe qual animacao nomeada usar num lugar (target: id em Settings.animTargets).
// Lugares que abrem e fecham tem as duas fases ("Abrir" / "Fechar"; fechar pode ser "igual a abrir").
// Recolhido mostra so a escolha atual (e o botao Testar, que abre e fecha o painel de verdade); aberto, todas as opcoes
// separadas em curvas, molas e as suas. Cada miniatura mostra a curva; passando o mouse, a bolinha anda no tempo real.
// editMode (pagina Animacoes): so lista, marca "selected" e avisa por chosen() em vez de mudar o que esta em uso.
import QtQuick

Column {
    id: root
    property string target
    property bool editMode: false
    property string selected: ""
    property bool expanded: editMode
    signal chosen(string name)
    width: parent ? parent.width : 300
    spacing: 10

    readonly property var info: Settings.targetInfo(target)
    readonly property bool phases: !editMode && !!info && !!info.phases
    property bool outPhase: false
    // nome em uso na fase mostrada ("" = fechar igual a abrir)
    readonly property string inName: Motion.nameFor(target, false)
    readonly property string outRaw: Settings.animOut[target] !== undefined ? Settings.animOut[target] : (Settings.animOutDefaults[target] ?? "")
    readonly property string current: editMode ? selected : (outPhase ? outRaw : inName)
    function pick(name) {
        if (editMode) chosen(name)
        else if (outPhase) Settings.setOut(target, name)
        else Settings.setUse(target, name)
    }
    readonly property var groups: {
        const all = Settings.allAnims()
        return [
            { label: "Curvas", items: all.filter(a => a.builtin && (a.type ?? "bezier") === "bezier") },
            { label: "Molas", items: all.filter(a => a.builtin && a.type === "spring") },
            { label: "Suas", items: all.filter(a => !a.builtin) }
        ].filter(g => g.items.length)
    }
    readonly property bool canTest: !editMode && Motion.canTest(target)

    // fase + escolha atual + acoes
    Flow {
        visible: !root.editMode
        width: parent.width
        spacing: 8
        UiSeg {
            visible: root.phases
            options: [[false, "Abrir"], [true, "Fechar"]]
            value: root.outPhase
            onPicked: v => root.outPhase = v
        }
        Option {
            a: Settings.findAnim(root.current === "" ? root.inName : root.current)
            on: true
            sameAsIn: root.outPhase && root.current === ""
            onClicked: root.expanded = !root.expanded
        }
        UiButton { icon: root.expanded ? "chevUp" : "chevDown"; text: root.expanded ? "Recolher" : "Trocar"; kind: "ghost"; onClicked: root.expanded = !root.expanded }
        UiButton { visible: root.canTest; icon: "play"; text: "Testar"; onClicked: Motion.test(root.target) }
    }

    // todas as opcoes
    Column {
        visible: root.expanded
        width: parent.width
        spacing: 8
        Option { visible: root.outPhase; sameAsIn: true; a: Settings.findAnim(root.inName); on: root.current === ""; onClicked: root.pick("") }
        Repeater {
            model: root.groups
            delegate: Column {
                id: grp
                required property var modelData
                width: root.width
                spacing: 6
                UiLabel { text: grp.modelData.label }
                Flow {
                    width: parent.width
                    spacing: 8
                    Repeater {
                        model: grp.modelData.items
                        delegate: Option {
                            required property var modelData
                            a: modelData
                            on: root.current === modelData.name
                            onClicked: root.pick(modelData.name)
                        }
                    }
                }
            }
        }
    }

    component Option: Rectangle {
        id: opt
        property var a: null
        property bool on: false
        property bool sameAsIn: false
        signal clicked
        width: 172; height: 60; radius: 12
        color: on ? Theme.tint(0.16) : (om.containsMouse ? Theme.cardHi : Theme.track)
        border.width: on ? 1.5 : 1
        border.color: on ? Theme.accent : Theme.border
        Behavior on color { ColorAnimation { duration: 120 } }
        CurveThumb {
            id: th
            x: 7; anchors.verticalCenter: parent.verticalCenter
            width: 44; height: 44
            anim: opt.a
            playing: om.containsMouse
            stroke: opt.on ? Theme.accent : Theme.text
            opacity: opt.sameAsIn ? 0.55 : 1
        }
        Column {
            anchors { left: th.right; leftMargin: 9; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            spacing: 2
            UiText { width: parent.width; elide: Text.ElideRight; text: opt.sameAsIn ? "Igual a abrir" : (opt.a ? opt.a.name : ""); color: Theme.text; font.pixelSize: 12; font.weight: opt.on ? Font.DemiBold : Font.Medium }
            UiText {
                width: parent.width; elide: Text.ElideRight
                text: !opt.a ? "" : opt.sameAsIn ? opt.a.name : (opt.a.type === "spring" ? "mola · " : "") + Motion.compile(opt.a).duration + " ms"
                color: Theme.muted; font.pixelSize: 11
            }
        }
        MouseArea { id: om; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: opt.clicked() }
    }
}
