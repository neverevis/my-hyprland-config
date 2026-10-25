// SetRow: linha no estilo do Windows 11 / GNOME, dentro de uma SetSection.
//   [icone num quadradinho]  Nome            [restaurar] [controle]
//                            uma linha curta
// - checked (bool) liga o interruptor no fim; a linha inteira clica e emite toggled(on).
// - filhos viram o controle do fim (UiSeg, UiButton, UiField...). link: true mostra a seta e a linha emite clicked().
// - canReset: true mostra o botao de voltar ao padrao (emite reset()) — use quando o valor difere do padrao.
// - below: conteudo largo abaixo da linha (grades, editores); sub: true para sub-linhas de um SetExpander (sem icone).
// - Regras de texto: nome com ate 3-4 palavras, descricao com 1 linha (o resto vai para um expansor ou some).
// Exemplo:  SetRow { icon: "night"; label: "Fundo OLED"; description: "Preto puro nos painéis"; checked: Settings.uiOled; onToggled: on => Settings.uiOled = on }
import QtQuick

Item {
    id: r
    readonly property bool setRow: true       // a busca da janela indexa esta linha
    property string icon
    property string label
    property string description
    property var checked: undefined
    property bool link: false
    property bool sub: false
    property bool canReset: false
    property bool divider: y > 0              // divisoria em cima (a primeira linha da caixa nao tem)
    property bool switchOnly: false           // o clique na linha emite clicked() e so o interruptor alterna (cabecalho de expansor)
    property bool rowClick: checked !== undefined || link   // a linha toda responde ao clique
    default property alias trailing: trail.data
    property alias below: belowBox.data
    readonly property bool hovered: hover.hovered
    signal toggled(bool on)
    signal clicked
    signal reset

    property real glow: 0
    function pulse() { glowAnim.restart() }

    width: parent ? parent.width : 400
    property bool headless: false             // sem a linha do nome (so o conteudo de below)
    implicitHeight: head.height + (belowBox.implicitHeight > 0 ? belowBox.implicitHeight + SetK.pad + (headless ? SetK.pad : 0) : 0)
    height: implicitHeight
    opacity: enabled ? 1 : 0.45

    // divisoria fina (so entre linhas: a primeira da caixa fica em y = 0)
    Rectangle {
        visible: r.divider
        x: r.sub || r.icon === "" ? SetK.pad : SetK.textX
        width: parent.width - x - SetK.pad
        height: 1
        color: Theme.border
        opacity: 0.55
    }
    // hover/press e o brilho da busca: pilula por dentro da caixa (nao vaza dos cantos)
    Rectangle {
        anchors { fill: parent; margins: SetK.xs }
        radius: SetK.innerRadius
        color: Theme.text
        opacity: r.glow > 0 ? 0 : (r.rowClick && r.enabled ? (ma.pressed ? 0.08 : (hover.hovered ? 0.045 : 0)) : 0)
        Behavior on opacity { NumberAnimation { duration: SetK.fast } }
    }
    Rectangle {
        anchors { fill: parent; margins: SetK.xs }
        radius: SetK.innerRadius
        color: Theme.accent
        opacity: r.glow * 0.18
    }
    HoverHandler { id: hover }

    Item {
        id: head
        width: parent.width
        visible: !r.headless
        height: r.headless ? 0 : (r.sub ? SetK.subH : (r.description !== "" ? SetK.rowHDesc : SetK.rowH))

        MouseArea {
            id: ma
            anchors.fill: parent
            enabled: r.rowClick
            cursorShape: Qt.PointingHandCursor
            onClicked: { if (r.checked !== undefined && !r.switchOnly) r.toggled(!r.checked); else r.clicked() }
        }

        Rectangle {
            id: tileBox
            visible: !r.sub && r.icon !== ""
            x: SetK.pad
            anchors.verticalCenter: parent.verticalCenter
            width: SetK.tile; height: SetK.tile; radius: 11
            color: Theme.tint(0.14)
            UiIcon { anchors.centerIn: parent; name: r.icon; size: 18; color: Theme.accent }
        }
        Column {
            anchors {
                left: parent.left
                leftMargin: r.sub ? SetK.textX : (tileBox.visible ? SetK.textX : SetK.pad)
                right: ctrl.left; rightMargin: SetK.md
                verticalCenter: parent.verticalCenter
            }
            spacing: 2
            UiText { width: parent.width; elide: Text.ElideRight; text: r.label; color: Theme.text; font.pixelSize: r.sub ? 13 : SetK.fRow; font.weight: Font.Medium }
            UiText { visible: r.description !== ""; width: parent.width; elide: Text.ElideRight; text: r.description; color: Theme.muted; font.pixelSize: SetK.fDesc }
        }
        Row {
            id: ctrl
            anchors { right: parent.right; rightMargin: SetK.pad; verticalCenter: parent.verticalCenter }
            spacing: SetK.sm
            // voltar ao padrao
            Rectangle {
                visible: r.canReset
                anchors.verticalCenter: parent.verticalCenter
                width: 28; height: 28; radius: 14
                color: rm.containsMouse ? Theme.cardHi : "transparent"
                UiIcon { anchors.centerIn: parent; name: "restore"; size: 15; color: rm.containsMouse ? Theme.text : Theme.muted }
                MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: r.reset() }
            }
            Row { id: trail; spacing: SetK.sm; anchors.verticalCenter: parent.verticalCenter }
            // interruptor
            Rectangle {
                visible: r.checked !== undefined
                anchors.verticalCenter: parent.verticalCenter
                width: 44; height: 24; radius: 12
                color: r.checked ? Theme.accent : Theme.cardHi
                border.width: 1; border.color: r.checked ? Theme.accent : Theme.border
                Behavior on color { enabled: !ThemeColors.fading; ColorAnimation { duration: SetK.fast } }
                Rectangle {
                    width: 18; height: 18; radius: 9
                    y: 3; x: r.checked ? parent.width - width - 3 : 3
                    color: r.checked ? Theme.accentText : Theme.muted
                    Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                }
                MouseArea { anchors.fill: parent; anchors.margins: -6; enabled: r.switchOnly; cursorShape: Qt.PointingHandCursor; onClicked: r.toggled(!r.checked) }
            }
            UiIcon { visible: r.link; anchors.verticalCenter: parent.verticalCenter; name: "chevRight"; size: 18; color: Theme.muted }
        }
    }
    Column {
        id: belowBox
        anchors { top: head.bottom; topMargin: r.headless ? SetK.pad : 0; left: parent.left; right: parent.right; leftMargin: SetK.pad; rightMargin: SetK.pad }
    }

    SequentialAnimation {
        id: glowAnim
        NumberAnimation { target: r; property: "glow"; to: 1; duration: 160 }
        PauseAnimation { duration: 800 }
        NumberAnimation { target: r; property: "glow"; to: 0; duration: 700; easing.type: Easing.InOutQuad }
    }
}
