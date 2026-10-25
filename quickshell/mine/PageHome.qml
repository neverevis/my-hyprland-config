// Painel "Inicio" (secoes do kit dentro da pagina Paineis): botoes rapidos, faixa, controles, midia, posicao e animacao do painel (Super).
import QtQuick

Column {
    spacing: SetK.xl

    SetSection {
        title: "Painel Início"; icon: "dashboard"; subtitle: "Início, mídia, notificações, agenda, áudio, sistema e conexões. Abre com Super"
        SetRow { icon: "play"; label: "Abrir o painel"; UiButton { icon: "play"; text: "Abrir"; kind: "accent"; onClicked: Settings.homeOpen = true } }
        SetSlider { icon: "view_column"; label: "Colunas dos botões rápidos"; from: 1; to: 8; def: 6; value: Settings.homeColumns; onMoved: v => Settings.homeColumns = Math.max(1, Math.min(8, Math.round(v))) }
        SetExpander {
            icon: "tune"; label: "Botões rápidos"; description: "Escolha, ordene e dê tamanho de 1 a 3 colunas"
            lazy: Component {
                SetBlock {
                    sub: true
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
                                width: 200; height: 44; radius: 12
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
                                        width: 24; height: 24; radius: 6; color: sm.containsMouse ? Theme.cardHi : "transparent"
                                        UiText { anchors.centerIn: parent; text: chip.on ? chip.lst[chip.pos].size : ""; color: Theme.accent; font.pixelSize: 13; font.weight: Font.Bold }
                                        MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: { const l = Toggles.norm(Settings.homeToggles); l[chip.pos].size = l[chip.pos].size % 3 + 1; Settings.homeToggles = l } }
                                    }
                                    Repeater {
                                        model: [["chevLeft", -1], ["chevRight", 1]]
                                        delegate: Rectangle {
                                            required property var modelData
                                            width: 24; height: 24; radius: 6; color: am.containsMouse ? Theme.cardHi : "transparent"
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
            }
        }
        SetRow { icon: "grid"; label: "Botões só com ícone"; description: "Uma fileira compacta, sem nome nem estado"; checked: Settings.homeToggleStyle === "compact"; onToggled: on => Settings.homeToggleStyle = on ? "compact" : "tiles" }
        SetRow { icon: "image"; label: "Faixa com foto e relógio"; checked: Settings.homeBanner; onToggled: on => Settings.homeBanner = on }
        SetRow {
            visible: Settings.homeBanner
            sub: true; label: "Foto da faixa"; description: Settings.homeBannerImage === "" ? "Usa o wallpaper" : "Foto própria"
            UiButton { icon: "image"; text: "Escolher"; onClicked: Pick.image("Foto da faixa do Início", p => Settings.homeBannerImage = p) }
            UiButton { visible: Settings.homeBannerImage !== ""; icon: "close"; kind: "ghost"; onClicked: Settings.homeBannerImage = "" }
        }
        SetRow { icon: "volume"; label: "Controle de volume"; checked: Settings.homeSliderVol; onToggled: on => Settings.homeSliderVol = on }
        SetRow { icon: "mic"; label: "Controle do microfone"; checked: Settings.homeSliderMic; onToggled: on => Settings.homeSliderMic = on }
    }

    SetSection {
        title: "Mídia"; icon: "music"
        SetRow { icon: "cards"; label: "Esconder players repetidos"; description: "Tira o playerctld e cópias do mesmo navegador"; checked: Settings.mediaDedupe; onToggled: on => Settings.mediaDedupe = on }
        SetRow {
            icon: "music"; label: "Player preferido"; description: "Parte do nome, ex.: spotify"
            UiField { width: 180; text: Settings.mediaPreferred; placeholderText: "spotify"; onEditingFinished: Settings.mediaPreferred = text.trim() }
        }
    }

    SetSection {
        title: "Posição"; icon: "dock"
        SetRow { icon: "frame"; label: "Acoplado à moldura"; description: "Sai da borda como uma barra. Desligado, flutua no centro"; checked: Settings.homeDocked; onToggled: on => Settings.homeDocked = on }
        SetRow { visible: Settings.homeDocked; icon: "dock"; label: "Lado da tela"; below: SidePick { value: Settings.homeSide; onPicked: v => Settings.homeSide = v } }
        SetSlider { visible: Settings.homeDocked; icon: "swap_horizontal"; label: "Deslocamento"; from: -1000; to: 1000; step: 10; unit: " px"; def: 0; value: Settings.homeOffset; onMoved: v => Settings.homeOffset = Math.round(v) }
        SetSlider { icon: "rounded"; label: "Arredondamento"; from: 0; to: 40; unit: " px"; def: 14; value: Settings.homeRadius; onMoved: v => Settings.homeRadius = Math.round(v) }
        SetSlider { visible: Settings.homeDocked; icon: "curve"; label: "Curva ao encontrar a moldura"; from: 0; to: 40; unit: " px"; def: 13; value: Settings.homeFillet; onMoved: v => Settings.homeFillet = Math.round(v) }
        SetExpander { icon: "animation"; label: "Animação"; lazy: Component { SetBlock { sub: true; AnimPicker { width: parent.width; target: "home" } } } }
    }
}
