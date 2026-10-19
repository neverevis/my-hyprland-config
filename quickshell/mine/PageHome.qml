// Pagina "Inicio": botoes rapidos, posicao e animacao do painel Inicio (Super), luz noturna, protecao contra clarao
// e cantos ativos da tela.
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
        subtitle: "Até " + Settings.homeCols * 3 + " (" + Settings.homeCols + " colunas × 3 linhas), na ordem escolhida. Clique para ligar ou tirar; as setas mudam a ordem."
        UiSeg { options: [[2, "2 colunas"], [3, "3 colunas"], [4, "4 colunas"]]; value: Settings.homeCols; onPicked: v => Settings.homeCols = v }
        Flow {
            width: parent.width
            spacing: 8
            Repeater {
                model: Toggles.all
                delegate: Rectangle {
                    required property var modelData
                    readonly property int pos: Settings.list(Settings.homeToggles).indexOf(modelData.id)
                    readonly property bool on: pos >= 0
                    width: 190; height: 48; radius: 12
                    color: on ? Theme.tint(0.16) : (tm.containsMouse ? Theme.cardHi : Theme.track)
                    border.width: on ? 1.5 : 1; border.color: on ? Theme.accent : Theme.border
                    UiIcon { id: ti; x: 12; anchors.verticalCenter: parent.verticalCenter; name: modelData.icon; size: 17; color: parent.on ? Theme.accent : Theme.muted }
                    UiText { anchors { left: ti.right; leftMargin: 10; right: arrows.left; verticalCenter: parent.verticalCenter } text: (parent.on ? (parent.pos + 1) + ". " : "") + modelData.label; color: Theme.text; font.pixelSize: 13; elide: Text.ElideRight }
                    MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { const l = Settings.list(Settings.homeToggles); const i = l.indexOf(modelData.id); if (i >= 0) l.splice(i, 1); else if (l.length < Settings.homeCols * 3) l.push(modelData.id); Settings.homeToggles = l } }
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
                                    onClicked: { const l = Settings.list(Settings.homeToggles), i = parent.parent.parent.pos, j = i + modelData[1]; if (j < 0 || j >= l.length) return; const t = l[i]; l[i] = l[j]; l[j] = t; Settings.homeToggles = l } }
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

    Card {
        icon: "night"
        title: "Luz noturna"
        subtitle: !NightLight.available ? "Precisa do hyprsunset (sudo pacman -S hyprsunset)." : NightLight.active ? "Ligada agora (" + Settings.nightTemp + " K)." : "Desligada agora."
        UiButton { icon: NightLight.active ? "sun" : "night"; text: NightLight.active ? "Desligar agora" : "Ligar agora"; kind: NightLight.active ? "ghost" : "accent"; onClicked: NightLight.toggle() }
        UiSlider { label: "Temperatura (menor = mais quente)"; from: 2500; to: 6000; value: Settings.nightTemp; suffix: " K"; onMoved: v => Settings.nightTemp = Math.round(v / 100) * 100 }
        UiSwitch { label: "Ligar sozinha no horário"; checked: Settings.nightAuto; onToggled: on => Settings.nightAuto = on }
        Row {
            visible: Settings.nightAuto
            spacing: 10
            UiText { anchors.verticalCenter: parent.verticalCenter; text: "Das"; color: Theme.text; font.pixelSize: 13 }
            UiField { width: 80; text: Settings.nightFrom; horizontalAlignment: Text.AlignHCenter; onEditingFinished: if (/^\d{1,2}:\d{2}$/.test(text)) Settings.nightFrom = text }
            UiText { anchors.verticalCenter: parent.verticalCenter; text: "às"; color: Theme.text; font.pixelSize: 13 }
            UiField { width: 80; text: Settings.nightTo; horizontalAlignment: Text.AlignHCenter; onEditingFinished: if (/^\d{1,2}:\d{2}$/.test(text)) Settings.nightTo = text }
        }
    }

    Card {
        icon: "sun"
        title: "Proteção contra clarão"
        subtitle: "Quando a tela inteira fica muito clara de repente (site branco, tela de carregamento), ela escurece um pouco. Telas escuras não mudam."
        UiSwitch { label: "Ligada"; checked: Settings.antiFlash; onToggled: on => Settings.antiFlash = on }
        UiSlider { visible: Settings.antiFlash; label: "Força"; from: 0; to: 100; value: Settings.antiFlashStrength; suffix: " %"; onMoved: v => Settings.antiFlashStrength = Math.round(v) }
    }

    Card {
        icon: "arrow_top_left"
        title: "Cantos ativos"
        subtitle: "Encostar o mouse num canto da tela faz uma ação."
        UiSlider { label: "Esperar antes de agir"; from: 0; to: 1000; value: Settings.hotCornerDelay; suffix: " ms"; onMoved: v => Settings.hotCornerDelay = Math.round(v / 50) * 50 }
        Repeater {
            model: [["tl", "Canto de cima, esquerda"], ["tr", "Canto de cima, direita"], ["bl", "Canto de baixo, esquerda"], ["br", "Canto de baixo, direita"]]
            delegate: Column {
                required property var modelData
                width: parent.width; spacing: 6
                UiText { text: modelData[1]; color: Theme.text; font.pixelSize: 13 }
                Flow {
                    width: parent.width; spacing: 4
                    Repeater {
                        model: HotCorners.actions
                        delegate: UiButton {
                            required property var modelData
                            readonly property string corner: parent.parent.modelData[0]
                            text: modelData[1]
                            kind: (Settings.hotCorners || {})[corner] === modelData[0] || (!(Settings.hotCorners || {})[corner] && modelData[0] === "") ? "accent" : "ghost"
                            onClicked: { const c = Object.assign({}, Settings.hotCorners || {}); c[corner] = modelData[0]; Settings.hotCorners = c }
                        }
                    }
                }
            }
        }
    }

    EqCard { width: parent.width }
}
