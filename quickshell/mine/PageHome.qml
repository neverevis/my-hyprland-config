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
        subtitle: "Cada botão ocupa de 1 a 3 colunas (1 = só o ícone). Clique para ligar ou tirar; as setas mudam a ordem e o número muda o tamanho. No painel, o lápis do cartão do usuário edita direto, e o clique direito abre o menu do botão."
        UiSlider { icon: "view_column"; label: "Colunas"; from: 1; to: 8; value: Settings.homeColumns; onMoved: v => Settings.homeColumns = Math.max(1, Math.min(8, Math.round(v))) }
        Flow {
            width: parent.width
            spacing: 8
            Repeater {
                model: Toggles.all
                delegate: Rectangle {
                    id: chip
                    required property var modelData
                    readonly property var lst: Toggles.norm(Settings.homeToggles)
                    readonly property int pos: lst.findIndex(e => e.id === modelData.id)
                    readonly property bool on: pos >= 0
                    width: 220; height: 48; radius: 12
                    color: on ? Theme.tint(0.16) : (tm.containsMouse ? Theme.cardHi : Theme.track)
                    border.width: on ? 1.5 : 1; border.color: on ? Theme.accent : Theme.border
                    UiIcon { id: ti; x: 12; anchors.verticalCenter: parent.verticalCenter; name: modelData.icon; size: 17; color: parent.on ? Theme.accent : Theme.muted }
                    UiText { anchors { left: ti.right; leftMargin: 10; right: arrows.left; verticalCenter: parent.verticalCenter } text: (parent.on ? (parent.pos + 1) + ". " : "") + modelData.label; color: Theme.text; font.pixelSize: 13; elide: Text.ElideRight }
                    MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { const l = Toggles.norm(Settings.homeToggles); const i = chip.pos; if (i >= 0) l.splice(i, 1); else l.push({ id: modelData.id, size: 2 }); Settings.homeToggles = l } }
                    Row {
                        id: arrows
                        visible: chip.on
                        anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                        Rectangle {
                            width: 22; height: 22; radius: 6; color: sm.containsMouse ? Theme.cardHi : "transparent"
                            UiText { anchors.centerIn: parent; text: chip.on ? chip.lst[chip.pos].size : ""; color: Theme.accent; font.pixelSize: 13; font.weight: Font.Bold }
                            MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { const l = Toggles.norm(Settings.homeToggles); l[chip.pos].size = l[chip.pos].size % 3 + 1; Settings.homeToggles = l } }
                        }
                        Repeater {
                            model: [["chevLeft", -1], ["chevRight", 1]]
                            delegate: Rectangle {
                                required property var modelData
                                width: 22; height: 22; radius: 6; color: am.containsMouse ? Theme.cardHi : "transparent"
                                UiIcon { anchors.centerIn: parent; name: modelData[0]; size: 13; color: Theme.muted }
                                MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { const l = Toggles.norm(Settings.homeToggles), i = chip.pos, j = i + modelData[1]; if (j < 0 || j >= l.length) return; const t = l[i]; l[i] = l[j]; l[j] = t; Settings.homeToggles = l } }
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
        subtitle: !NightLight.available ? "Precisa do hyprsunset (sudo pacman -S hyprsunset)." : (NightLight.active ? "Ligada agora (" + Settings.nightTemp + " K)." : "Desligada agora.") + " Também abre pelo clique direito no botão Luz noturna do painel."
        UiButton { icon: NightLight.active ? "sun" : "night"; text: NightLight.active ? "Desligar agora" : "Ligar agora"; kind: NightLight.active ? "ghost" : "accent"; onClicked: NightLight.toggle() }
        UiSlider { icon: "thermo"; label: "Temperatura (menor = mais quente)"; from: 1200; to: 6500; value: Settings.nightTemp; suffix: " K"; onMoved: v => Settings.nightTemp = Math.round(v / 100) * 100 }
        UiSlider { icon: "sun"; label: "Brilho (gamma)"; from: 25; to: 100; value: Settings.nightGamma; suffix: " %"; onMoved: v => NightLight.setGamma(v) }
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
        icon: "tune"
        title: "Início e mídia"
        subtitle: "O que aparece na aba Início e como escolher o player."
        UiSwitch { label: "Faixa com foto e relógio"; checked: Settings.homeBanner; onToggled: on => Settings.homeBanner = on }
        Row {
            spacing: 8
            UiButton { icon: "image"; text: Settings.homeBannerImage === "" ? "Foto própria da faixa…" : "Trocar a foto da faixa…"; onClicked: Pick.image("Foto da faixa do Início", p => Settings.homeBannerImage = p) }
            UiButton { visible: Settings.homeBannerImage !== ""; icon: "close"; text: "Usar o wallpaper"; kind: "ghost"; onClicked: Settings.homeBannerImage = "" }
        }
        UiSwitch { label: "Botões rápidos só com ícone"; description: "Estilo clássico: uma fileira compacta, sem nome nem estado."; checked: Settings.homeToggleStyle === "compact"; onToggled: on => Settings.homeToggleStyle = on ? "compact" : "tiles" }
        UiSwitch { label: "Controle de volume"; checked: Settings.homeSliderVol; onToggled: on => Settings.homeSliderVol = on }
        UiSwitch { label: "Controle do microfone"; checked: Settings.homeSliderMic; onToggled: on => Settings.homeSliderMic = on }
        UiSwitch { label: "Esconder players repetidos"; description: "Tira o playerctld e cópias do mesmo navegador."; checked: Settings.mediaDedupe; onToggled: on => Settings.mediaDedupe = on }
        UiText { text: "Player preferido"; color: Theme.muted; font.pixelSize: 12 }
        UiField { placeholderText: "parte do nome, ex.: spotify"; text: Settings.mediaPreferred; onEditingFinished: Settings.mediaPreferred = text.trim() }
        UiSwitch { label: "Barra lateral esquerda saindo da moldura"; description: "Desligado, ela flutua. Abre com a ação \"Barra lateral esquerda\" (ou um canto ativo)."; checked: Settings.leftDocked; onToggled: on => Settings.leftDocked = on }
    }

    Card {
        icon: "arrow_top_left"
        title: "Cantos ativos"
        subtitle: "Encostar o mouse num canto da tela faz uma ação."
        UiSwitch { label: "Agir no clique"; description: "Em vez de só encostar o mouse no canto."; checked: Settings.hotCornerClick; onToggled: on => Settings.hotCornerClick = on }
        UiSlider { visible: !Settings.hotCornerClick; label: "Esperar antes de agir"; from: 0; to: 1000; value: Settings.hotCornerDelay; suffix: " ms"; onMoved: v => Settings.hotCornerDelay = Math.round(v / 50) * 50 }
        UiSlider { label: "Largura da zona"; from: 1; to: 250; value: Settings.hotCornerW; suffix: " px"; onMoved: v => Settings.hotCornerW = Math.round(v) }
        UiSlider { label: "Altura da zona"; from: 1; to: 60; value: Settings.hotCornerH; suffix: " px"; onMoved: v => Settings.hotCornerH = Math.round(v) }
        UiSwitch { label: "Esconder em tela cheia"; description: "Sem as zonas quando uma janela está em tela cheia (jogos, vídeos)."; checked: Settings.hotCornerHideFs; onToggled: on => Settings.hotCornerHideFs = on }
        UiSwitch { label: "Mostrar as zonas"; description: "Pinta a área de cada canto ativo para você ver onde ela fica."; checked: Settings.hotCornerVisualize; onToggled: on => Settings.hotCornerVisualize = on }
        UiSwitch { label: "Roda do mouse nos cantos de baixo"; description: "Esquerda muda o brilho da tela (só em telas com backlight), direita muda o volume."; checked: Settings.hotCornerWheel; onToggled: on => Settings.hotCornerWheel = on }
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
