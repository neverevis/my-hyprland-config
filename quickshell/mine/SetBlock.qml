// SetBlock: conteudo livre dentro da caixa de uma SetSection ou de um SetExpander (editores, grades, textos de ajuda),
// com as mesmas margens e a mesma divisoria das linhas. Use so quando nenhuma linha do kit serve.
import QtQuick

Item {
    id: b
    default property alias content: col.data
    property int spacing: SetK.md
    property bool sub: false   // dentro de um expansor: alinha com o texto das linhas
    width: parent ? parent.width : 400
    implicitHeight: col.implicitHeight + SetK.pad * 2 - 4
    height: implicitHeight
    Rectangle { visible: b.y > 0; x: SetK.pad; width: parent.width - SetK.pad * 2; height: 1; color: Theme.border; opacity: 0.55 }
    Column {
        id: col
        x: b.sub ? SetK.textX : SetK.pad
        y: SetK.pad - 2
        width: parent.width - x - SetK.pad
        spacing: b.spacing
    }
}
