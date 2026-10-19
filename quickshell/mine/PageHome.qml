// Pagina "Inicio": posicao e animacao do painel Inicio (Super).
import QtQuick

Column {
    spacing: 14

    Card {
        icon: "dashboard"
        title: "Painel Início"
        subtitle: "Abas de início, mídia, notificações, agenda, áudio, sistema e conexões. Abra com Super (sozinho)."
        UiButton { icon: "play"; text: "Abrir o painel"; kind: "accent"; onClicked: Settings.homeOpen = true }
    }
    Card {
        icon: "tune"
        title: "Botões rápidos"
        subtitle: "Até 9, na ordem escolhida. Clique para ligar ou tirar; as setas mudam a ordem."
        Flow {
            width: parent.width
            spacing: 8
            Repeater {
                model: Toggles.all
                delegate: Rectangle {
                    required property var modelData
                    readonly property int pos: (Settings.homeToggles || []).indexOf(modelData.id)
                    readonly property bool on: pos >= 0
                    width: 190; height: 48; radius: 12
                    color: on ? Theme.tint(0.16) : (tm.containsMouse ? Theme.cardHi : Theme.track)
                    border.width: on ? 1.5 : 1; border.color: on ? Theme.accent : Theme.border
                    UiIcon { id: ti; x: 12; anchors.verticalCenter: parent.verticalCenter; name: modelData.icon; size: 17; color: parent.on ? Theme.accent : Theme.muted }
                    Text { anchors { left: ti.right; leftMargin: 10; right: arrows.left; verticalCenter: parent.verticalCenter } text: (parent.on ? (parent.pos + 1) + ". " : "") + modelData.label; color: Theme.text; font.pixelSize: 13; elide: Text.ElideRight }
                    MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { const l = (Settings.homeToggles || []).slice(); const i = l.indexOf(modelData.id); if (i >= 0) l.splice(i, 1); else if (l.length < 9) l.push(modelData.id); Settings.homeToggles = l } }
                    Row {
                        id: arrows
                        visible: parent.on
                        anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                        Repeater {
                            model: [["chevLeft", -1], ["chevRight", 1]]
                            delegate: Rectangle {
                                required property var modelData
                                width: 22; height: 22; radius: 6; color: am.containsMouse ? Theme.cardHi : "transparent"
                                UiIcon { anchors.centerIn: parent; name: modelData[0]; size: 13; color: Theme.muted }
                                MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { const l = (Settings.homeToggles || []).slice(), i = parent.parent.parent.pos, j = i + modelData[1]; if (j < 0 || j >= l.length) return; const t = l[i]; l[i] = l[j]; l[j] = t; Settings.homeToggles = l } }
                            }
                        }
                    }
                }
            }
        }
    }
    Card {
        icon: "dock"
        title: "Posição"
        UiSwitch { label: "Acoplado à moldura"; description: "Sai da borda da tela como uma barra. Desligado, flutua no centro."; checked: Settings.homeDocked; onToggled: on => Settings.homeDocked = on }
        SidePick { visible: Settings.homeDocked; value: Settings.homeSide; onPicked: v => Settings.homeSide = v }
        UiSlider { visible: Settings.homeDocked; label: "Deslocamento"; from: -1000; to: 1000; value: Settings.homeOffset; suffix: " px"; onMoved: v => Settings.homeOffset = Math.round(v) }
        UiSlider { visible: Settings.homeDocked; label: "Curva ao encontrar a moldura"; from: 0; to: 40; value: Settings.homeFillet; suffix: " px"; onMoved: v => Settings.homeFillet = Math.round(v) }
        UiSlider { label: "Arredondamento"; from: 0; to: 40; value: Settings.homeRadius; suffix: " px"; onMoved: v => Settings.homeRadius = Math.round(v) }
    }
    Card {
        icon: "animation"
        title: "Animação"
        AnimPicker { target: "home" }
    }
}
