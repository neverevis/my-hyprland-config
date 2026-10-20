// Pecas sem estado para compor os widgets da area de trabalho (uso: DwParts.Panel { ... }). Nenhuma tem Timer nem animacao
// propria: Panel (caixa interna por papel de cor), Chip, Badge (forma + icone), Stat, RoundBtn, Pill e Scrim.
import QtQuick
import "dwparts.js" as U

Item {
    // caixa interna: role (ver Theme.role), alpha 0..1, radius; ink = a cor do texto em cima (none = transparente)
    component Panel: Rectangle {
        property string role: "surfaceVariant"
        property real alpha: 1
        property color base: Theme.role(role)
        readonly property color ink: role === "none" ? Theme.text : Theme.role(U.inkRole(role))
        radius: 17
        color: role === "none" ? "transparent" : Qt.rgba(base.r, base.g, base.b, alpha)
    }

    // pilula com icone e/ou texto
    component Chip: Rectangle {
        id: ch
        property string text: ""
        property string icon: ""
        property color fill: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
        property color ink: Theme.text
        property real fs: 12
        implicitHeight: Math.round(fs * 2.1)
        implicitWidth: cr.implicitWidth + fs * 1.6
        radius: height / 2
        color: fill
        Row {
            id: cr
            anchors.centerIn: parent
            spacing: ch.fs * 0.4
            UiIcon { visible: ch.icon !== ""; name: ch.icon; size: Math.round(ch.fs * 1.15); color: ch.ink; anchors.verticalCenter: parent.verticalCenter }
            UiText { visible: ch.text !== ""; text: ch.text; color: ch.ink; font.pixelSize: ch.fs; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    // icone dentro de uma forma (cookie de 12 pontas por padrao, o selo do end4)
    component Badge: ShapeIcon {
        property color bg: Theme.accent
        property color fg: U.inkOn(bg)
        shape: "cookie12"
        size: 34
        padding: size * 0.18
        animated: false
        color: bg
        iconColor: fg
    }

    // numero em cima de um rotulo
    component Stat: Column {
        property string value: ""
        property string label: ""
        property color ink: Theme.text
        property real fs: 16
        UiText { anchors.horizontalCenter: parent.horizontalCenter; text: parent.value; color: parent.ink; font.pixelSize: parent.fs; font.weight: Font.Bold; font.features: { "tnum": 1 } }
        UiText { anchors.horizontalCenter: parent.horizontalCenter; text: parent.label; color: Qt.rgba(parent.ink.r, parent.ink.g, parent.ink.b, 0.6); font.pixelSize: Math.round(parent.fs * 0.62) }
    }

    // botao redondo: kind = filled | outlined | tonal
    component RoundBtn: Rectangle {
        id: rb
        property string icon: ""
        property string kind: "outlined"
        property color tone: Theme.text            // cor do contorno / do fundo (filled)
        property color ink: kind === "filled" ? U.inkOn(tone) : tone
        property real iconSize: Math.round(width * 0.45)
        signal clicked
        width: 36; height: 36; radius: width / 2
        color: kind === "filled" ? tone : kind === "tonal" ? Qt.rgba(tone.r, tone.g, tone.b, ma.containsMouse ? 0.22 : 0.12) : (ma.containsMouse ? Qt.rgba(tone.r, tone.g, tone.b, 0.1) : "transparent")
        border.width: kind === "outlined" ? Math.max(1, Math.round(width / 36)) : 0
        border.color: tone
        UiIcon { anchors.centerIn: parent; name: rb.icon; size: rb.iconSize; color: rb.ink }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: rb.clicked() }
    }

    // botao pilula (cheio): texto e icone
    component Pill: Rectangle {
        id: pl
        property string text: ""
        property string icon: ""
        property color fill: Theme.text
        property color ink: Theme.bg
        property real fs: 15
        signal clicked
        implicitHeight: 40
        implicitWidth: pr.implicitWidth + 28
        radius: height / 2
        color: Qt.rgba(fill.r, fill.g, fill.b, pm.containsMouse ? 0.88 : 1)
        Row {
            id: pr
            anchors.centerIn: parent
            spacing: pl.fs * 0.4
            UiIcon { visible: pl.icon !== ""; name: pl.icon; size: Math.round(pl.fs * 1.15); color: pl.ink; anchors.verticalCenter: parent.verticalCenter }
            UiText { visible: pl.text !== ""; text: pl.text; color: pl.ink; font.pixelSize: pl.fs; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pl.clicked() }
    }

    // veu escuro dentro do cartao
    component Scrim: Rectangle {
        property real amount: 0.1
        color: Qt.rgba(0, 0, 0, amount)
    }
}
