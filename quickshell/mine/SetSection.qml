// SetSection: um grupo de opcoes com cabecalho pequeno (icone + nome) e uma caixa arredondada com as linhas dentro.
// As linhas (SetRow, SetSlider, SetChoice, SetColor, SetExpander, SetBlock) ficam empilhadas com divisorias finas.
// boxed: false tira a caixa (para grades de botoes/atalhos que ja sao blocos proprios).
// title/subtitle tambem alimentam a busca e os atalhos da janela; pulse() acende a caixa (resultado da busca).
// Exemplo:  SetSection { title: "Transparência"; icon: "opacity"; SetRow { label: "Vidro"; checked: Settings.glass; onToggled: on => Settings.glass = on } }
import QtQuick

Column {
    id: sec
    property string title
    property string subtitle: ""
    property string icon
    property bool boxed: true
    default property alias content: rows.data
    property real glow: 0
    function pulse() { glowAnim.restart() }

    width: parent ? parent.width : 400
    spacing: SetK.sm + 2

    Row {
        visible: sec.title !== ""
        spacing: SetK.sm
        leftPadding: SetK.xs
        UiIcon { visible: sec.icon !== ""; name: sec.icon; size: 15; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
        UiText { text: sec.title; color: Theme.text; font.pixelSize: SetK.fSection; font.weight: Font.DemiBold; font.letterSpacing: 0.2; anchors.verticalCenter: parent.verticalCenter }
    }
    Rectangle {
        width: parent.width
        height: rows.implicitHeight
        radius: SetK.boxRadius
        color: sec.boxed ? Qt.rgba(Theme.card.r, Theme.card.g, Theme.card.b, Math.max(0.8, Theme.glc(Theme.card, 1).a)) : "transparent"   // piso 0.8: contraste do texto no vidro
        border.width: sec.boxed ? 1 + sec.glow : (sec.glow > 0.01 ? 1 + sec.glow : 0)
        border.color: sec.glow > 0.01 ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35 + 0.65 * sec.glow) : Theme.border
        Column { id: rows; width: parent.width }
    }
    SequentialAnimation {
        id: glowAnim
        NumberAnimation { target: sec; property: "glow"; to: 1; duration: 160 }
        PauseAnimation { duration: 700 }
        NumberAnimation { target: sec; property: "glow"; to: 0; duration: 700; easing.type: Easing.InOutQuad }
    }
}
