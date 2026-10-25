// SetExpander: linha que abre e mostra opcoes secundarias por baixo (o jeito de esconder o que e avancado).
// Filhos: sub-linhas (SetRow { sub: true }, SetSlider { sub: true }...) ou um SetBlock com conteudo livre.
// Os filhos existem sempre (leves; a busca encontra e abre o expansor); para conteudo pesado (editores, previas,
// listas grandes) use lazy: Component { ... } — so e criado com o expansor aberto.
// checked (bool) poe um interruptor no cabecalho (toggled(on)); o clique na linha so abre e fecha.
// Exemplo:  SetExpander { icon: "tune"; label: "Avançado"; description: "Separar fundo e conteúdo"; SetRow { sub: true; ... } }
import QtQuick

Column {
    id: ex
    readonly property bool setRow: true
    readonly property bool expander: true
    property string icon
    property string label
    property string description
    property bool open: false
    property var checked: undefined
    property Component lazy: null
    default property alias content: inner.data
    signal toggled(bool on)
    function pulse() { hdr.pulse() }

    width: parent ? parent.width : 400
    opacity: enabled ? 1 : 0.45

    SetRow {
        id: hdr
        icon: ex.icon
        label: ex.label
        description: ex.description
        checked: ex.checked
        switchOnly: true
        divider: ex.y > 0
        rowClick: true
        onClicked: ex.open = !ex.open
        onToggled: on => ex.toggled(on)
        UiIcon {
            name: "chevDown"; size: 20; color: Theme.muted
            rotation: ex.open ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: SetK.base; easing.type: Easing.OutCubic } }
        }
    }
    Item {
        id: clipper
        width: parent.width
        height: ex.open ? body.implicitHeight : 0
        visible: height > 0.5
        clip: true
        Behavior on height { NumberAnimation { duration: SetK.base; easing.type: Easing.BezierSpline; easing.bezierCurve: SetK.ease } }
        Column {
            id: body
            width: parent.width
            // divisoria entre o cabecalho e as sub-linhas
            Rectangle { x: SetK.pad; width: parent.width - SetK.pad * 2; height: 1; color: Theme.border; opacity: 0.55 }
            Column { id: inner; width: parent.width }
            Loader {
                width: parent.width
                active: ex.open && ex.lazy !== null
                sourceComponent: ex.lazy
            }
        }
    }
}
