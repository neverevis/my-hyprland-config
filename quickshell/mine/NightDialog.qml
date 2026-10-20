// Janelinha da luz noturna (abre pelo clique direito no botao do Inicio): ligar agora, horario, temperatura (1200-6500 K,
// ao vivo pelo hyprsunset), brilho (gamma) e protecao contra clarao. Os mesmos ajustes ficam na pagina Inicio das configuracoes.
import QtQuick

Item {
    id: dlg
    signal closeRequested()
    implicitHeight: col.implicitHeight + 32

    Column {
        id: col
        x: 16; y: 14
        width: parent.width - 32
        spacing: 8
        Row {
            width: parent.width
            spacing: 8
            UiIcon { name: "night"; size: 18; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
            UiText { text: "Luz noturna"; color: Theme.text; font.pixelSize: 16; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 80 }
            UiButton { icon: "close"; kind: "ghost"; onClicked: dlg.closeRequested() }
        }
        UiText { visible: !NightLight.available; width: parent.width; text: "Precisa do hyprsunset (sudo pacman -S hyprsunset)."; color: Theme.muted; font.pixelSize: 12; wrapMode: Text.WordWrap }
        UiSwitch { icon: "night"; label: "Ligar agora"; checked: NightLight.active; onToggled: on => { if (on !== NightLight.active) NightLight.toggle() } }
        UiSwitch { icon: "auto"; label: "Automática"; description: Settings.nightAuto ? "Das " + Settings.nightFrom + " às " + Settings.nightTo : "Liga sozinha no horário"; checked: Settings.nightAuto; onToggled: on => Settings.nightAuto = on }
        Row {
            visible: Settings.nightAuto
            spacing: 10
            UiText { anchors.verticalCenter: parent.verticalCenter; text: "Das"; color: Theme.text; font.pixelSize: 13 }
            UiField { width: 80; text: Settings.nightFrom; horizontalAlignment: Text.AlignHCenter; onEditingFinished: if (/^\d{1,2}:\d{2}$/.test(text)) Settings.nightFrom = text }
            UiText { anchors.verticalCenter: parent.verticalCenter; text: "às"; color: Theme.text; font.pixelSize: 13 }
            UiField { width: 80; text: Settings.nightTo; horizontalAlignment: Text.AlignHCenter; onEditingFinished: if (/^\d{1,2}:\d{2}$/.test(text)) Settings.nightTo = text }
        }
        UiSlider { icon: "thermo"; label: "Temperatura (menor = mais quente)"; from: 1200; to: 6500; value: Settings.nightTemp; suffix: " K"; onMoved: v => Settings.nightTemp = Math.round(v / 100) * 100 }
        UiSlider { icon: "sun"; label: "Brilho (gamma)"; from: 25; to: 100; value: Settings.nightGamma; suffix: " %"; onMoved: v => NightLight.setGamma(v) }
        UiSwitch { icon: "glass"; label: "Proteção contra clarão"; description: "Escurece a tela quando fica toda branca de repente."; checked: Settings.antiFlash; onToggled: on => Settings.antiFlash = on }
        UiSlider { visible: Settings.antiFlash; label: "Força da proteção"; from: 0; to: 100; value: Settings.antiFlashStrength; suffix: " %"; onMoved: v => Settings.antiFlashStrength = Math.round(v) }
    }
}
