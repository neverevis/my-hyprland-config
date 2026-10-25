// Painel "Tela e cantos" (secoes do kit dentro da pagina Paineis): visao geral (grade de workspaces), barra lateral esquerda,
// luz noturna, protecao contra clarao, cantos ativos e equalizador.
import QtQuick

Column {
    spacing: SetK.xl

    SetSection {
        title: "Visão geral"; icon: "layers"; subtitle: "A grade de workspaces (ação Visão geral ou ipc overview toggle)"
        SetRow { icon: "layers"; label: "Ligada"; checked: Settings.overviewOn; onToggled: on => Settings.overviewOn = on }
        SetSlider { icon: "view_grid"; label: "Linhas"; from: 1; to: 4; def: 2; ticks: true; value: Settings.overviewRows; onMoved: v => Settings.overviewRows = Math.round(v) }
        SetSlider { icon: "view_column"; label: "Colunas"; from: 1; to: 8; def: 5; ticks: true; value: Settings.overviewCols; onMoved: v => Settings.overviewCols = Math.round(v) }
        SetSlider { icon: "resize"; label: "Tamanho de cada workspace"; from: 0; to: 40; unit: " %"; zeroLabel: "Automático"; def: 0; value: Settings.overviewScale; onMoved: v => Settings.overviewScale = Math.round(v) }
        SetExpander {
            icon: "swap_horizontal"; label: "Ordem da grade"
            SetRow { sub: true; label: "Da direita para a esquerda"; checked: Settings.overviewRtl; onToggled: v => Settings.overviewRtl = v }
            SetRow { sub: true; label: "De baixo para cima"; checked: Settings.overviewBtt; onToggled: v => Settings.overviewBtt = v }
        }
    }

    SetSection {
        title: "Barra lateral esquerda"; icon: "dock"
        SetRow { icon: "frame"; label: "Saindo da moldura"; description: "Desligado, flutua. Abre pela ação Barra lateral esquerda ou um canto ativo"; checked: Settings.leftDocked; onToggled: on => Settings.leftDocked = on }
    }

    SetSection {
        title: "Luz noturna"; icon: "night"
        subtitle: !NightLight.available ? "Precisa do hyprsunset (sudo pacman -S hyprsunset)" : (NightLight.active ? "Ligada agora (" + Settings.nightTemp + " K)" : "Desligada agora")
        SetRow {
            icon: NightLight.active ? "sun" : "night"; label: NightLight.active ? "Desligar agora" : "Ligar agora"; description: "Também pelo clique direito no botão Luz noturna do painel"
            UiButton { text: NightLight.active ? "Desligar" : "Ligar"; kind: NightLight.active ? "ghost" : "accent"; onClicked: NightLight.toggle() }
        }
        SetSlider { icon: "thermo"; label: "Temperatura"; description: "Menor = mais quente"; from: 1200; to: 6500; step: 100; unit: " K"; def: 4500; value: Settings.nightTemp; onMoved: v => Settings.nightTemp = Math.round(v / 100) * 100 }
        SetSlider { icon: "sun"; label: "Brilho (gamma)"; from: 25; to: 100; unit: " %"; def: 100; value: Settings.nightGamma; onMoved: v => NightLight.setGamma(Math.round(v)) }
        SetRow { icon: "timer"; label: "Ligar sozinha no horário"; checked: Settings.nightAuto; onToggled: on => Settings.nightAuto = on }
        SetRow {
            visible: Settings.nightAuto
            sub: true; label: "Das … às …"
            UiField { width: 70; text: Settings.nightFrom; horizontalAlignment: Text.AlignHCenter; onEditingFinished: if (/^\d{1,2}:\d{2}$/.test(text)) Settings.nightFrom = text }
            UiText { text: "às"; color: Theme.muted; font.pixelSize: 13 }
            UiField { width: 70; text: Settings.nightTo; horizontalAlignment: Text.AlignHCenter; onEditingFinished: if (/^\d{1,2}:\d{2}$/.test(text)) Settings.nightTo = text }
        }
    }

    SetSection {
        title: "Proteção contra clarão"; icon: "sun"
        SetRow { icon: "sun"; label: "Ligada"; description: "Se a tela inteira clareia de repente (site branco), ela escurece um pouco"; checked: Settings.antiFlash; onToggled: on => Settings.antiFlash = on }
        SetSlider { visible: Settings.antiFlash; icon: "gauge"; label: "Força"; from: 0; to: 100; unit: " %"; def: 50; value: Settings.antiFlashStrength; onMoved: v => Settings.antiFlashStrength = Math.round(v) }
    }

    SetSection {
        title: "Cantos ativos"; icon: "arrow_top_left"; subtitle: "Encostar o mouse num canto da tela faz uma ação"
        SetRow { icon: "cursorMove"; label: "Agir no clique"; description: "Em vez de só encostar o mouse"; checked: Settings.hotCornerClick; onToggled: on => Settings.hotCornerClick = on }
        SetSlider { visible: !Settings.hotCornerClick; icon: "timer"; label: "Esperar antes de agir"; from: 0; to: 1000; step: 50; unit: " ms"; def: 250; value: Settings.hotCornerDelay; onMoved: v => Settings.hotCornerDelay = Math.round(v / 50) * 50 }
        SetRow { icon: "fullscreen"; label: "Esconder em tela cheia"; description: "Sem as zonas em jogos e vídeos"; checked: Settings.hotCornerHideFs; onToggled: on => Settings.hotCornerHideFs = on }
        SetRow { icon: "volume"; label: "Roda do mouse nos cantos de baixo"; description: "Esquerda muda o brilho (só com backlight), direita o volume"; checked: Settings.hotCornerWheel; onToggled: on => Settings.hotCornerWheel = on }
        SetExpander {
            icon: "tune"; label: "Zonas"; description: "Tamanho e visualização"
            SetSlider { sub: true; label: "Largura da zona"; from: 1; to: 250; unit: " px"; def: 4; value: Settings.hotCornerW; onMoved: v => Settings.hotCornerW = Math.round(v) }
            SetSlider { sub: true; label: "Altura da zona"; from: 1; to: 60; unit: " px"; def: 4; value: Settings.hotCornerH; onMoved: v => Settings.hotCornerH = Math.round(v) }
            SetRow { sub: true; label: "Mostrar as zonas"; description: "Pinta a área de cada canto"; checked: Settings.hotCornerVisualize; onToggled: on => Settings.hotCornerVisualize = on }
        }
        SetExpander {
            icon: "arrow_top_left"; label: "Ação de cada canto"
            lazy: Component {
                SetBlock {
                    sub: true
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
            }
        }
    }

    SetSection {
        title: "Equalizador"; icon: "wave"; subtitle: "Efeitos de áudio pelo EasyEffects"
        SetExpander {
            icon: "wave"; label: "Equalizador e presets"; description: "Ligar efeitos, preset e 10 bandas"
            lazy: Component { SetBlock { sub: true; EqCard { width: parent.width } } }
        }
    }
}
