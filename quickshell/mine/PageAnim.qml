// Pagina "Animação": biblioteca de animacoes nomeadas (curva de bezier + duracao) (onde cada uma e usada se escolhe na pagina de cada coisa).
import QtQuick

Column {
    id: page
    spacing: 14

    property string sel: "Padrão"
    readonly property var cur: Settings.findAnim(sel) ?? Settings.builtinAnims[0]
    readonly property bool locked: !!cur.builtin

    Card {
        icon: "animation"
        title: "Animações"
        subtitle: "As do sistema (não editáveis) e as suas. Escolha uma para ver ou editar."
        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: Settings.allAnims()
                delegate: UiButton {
                    required property var modelData
                    text: modelData.name
                    checked: page.sel === modelData.name
                    onClicked: page.sel = modelData.name
                }
            }
            UiButton { icon: "plus"; text: "Nova animação"; kind: "ghost"; onClicked: page.sel = Settings.addAnim(page.cur) }
        }
    }

    Card {
        icon: page.locked ? "lock" : "curve"
        title: page.cur.name
        subtitle: page.locked ? "Animação do sistema: não dá para editar. Duplique para criar a sua." : "Arraste os pinos para desenhar a curva e a bolinha de baixo para a duração."

        CurveEditor {
            width: parent.width
            x1: page.cur.x1; y1: page.cur.y1; x2: page.cur.x2; y2: page.cur.y2; duration: page.cur.duration
            editable: !page.locked
            onEdited: vals => Settings.setAnimMany(page.cur.name, vals)
        }

        Row {
            visible: !page.locked
            spacing: 10
            Text { anchors.verticalCenter: parent.verticalCenter; text: "Nome"; color: Theme.text; font.pixelSize: 13; width: 60 }
            UiField {
                width: 220
                text: page.cur.name
                onEditingFinished: page.sel = Settings.renameAnim(page.cur.name, text)
            }
        }

        // teste: a bolinha anda com a curva e a duracao desta animacao
        Item {
            width: parent.width; height: 34
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; radius: 3; color: Theme.cardHi }
            Rectangle {
                id: dot
                property real t: 0
                anchors.verticalCenter: parent.verticalCenter
                x: t * (parent.width - width)
                width: 22; height: 22; radius: 11
                color: Theme.accent
                NumberAnimation on t {
                    id: anim
                    running: false
                    from: 0; to: 1
                    duration: page.cur.duration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [page.cur.x1 / 100, page.cur.y1 / 100, page.cur.x2 / 100, page.cur.y2 / 100, 1, 1]
                }
            }
        }
        Flow {
            width: parent.width
            spacing: 6
            UiButton { icon: "play"; text: "Testar"; kind: "accent"; onClicked: { anim.stop(); anim.start() } }
            UiButton { icon: "cards"; text: "Duplicar"; onClicked: page.sel = Settings.addAnim(page.cur) }
            UiButton { visible: !page.locked; icon: "trash"; text: "Excluir"; kind: "danger"; onClicked: { const n = page.cur.name; page.sel = "Padrão"; Settings.removeAnim(n) } }
        }
    }
}
