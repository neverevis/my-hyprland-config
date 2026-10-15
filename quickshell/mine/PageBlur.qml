// Pagina "Blur": blur global do Hyprland e ajustes so da moldura do Quickshell.
import QtQuick

Column {
    spacing: 14

    Card {
        title: "Blur do Hyprland"
        subtitle: "Vale para TODAS as janelas, inclusive a moldura: o Hyprland só aceita um valor global de tamanho, passes e ruído."
        UiSwitch { label: "Controlar o blur por aqui"; checked: Settings.blurManaged; onToggled: on => Settings.blurManaged = on }
        Column {
            width: parent.width
            spacing: 14
            enabled: Settings.blurManaged
            opacity: enabled ? 1 : 0.45
            UiSwitch { label: "Blur ligado"; checked: Settings.blurEnabled; onToggled: on => Settings.blurEnabled = on }
            UiSlider { label: "Tamanho"; from: 1; to: 20; value: Settings.blurSize; onMoved: v => Settings.blurSize = v }
            UiSlider { label: "Passes (qualidade)"; from: 1; to: 8; value: Settings.blurPasses; onMoved: v => Settings.blurPasses = v }
            UiSlider { label: "Ruído (noise)"; from: 0; to: 100; value: Settings.blurNoise; suffix: " ‰"; onMoved: v => Settings.blurNoise = v }
            UiSlider { label: "Contraste"; from: 0; to: 200; value: Settings.blurContrast; suffix: " %"; onMoved: v => Settings.blurContrast = v }
            UiSlider { label: "Brilho"; from: 0; to: 200; value: Settings.blurBrightness; suffix: " %"; onMoved: v => Settings.blurBrightness = v }
            UiSlider { label: "Vibração de cor"; from: 0; to: 100; value: Settings.blurVibrancy; suffix: " %"; onMoved: v => Settings.blurVibrancy = v }
        }
    }

    Card {
        title: "Blur só da moldura"
        subtitle: "Ajustes que valem apenas para a moldura e as barras do Quickshell. A intensidade do desfoque segue o blur do Hyprland acima."
        UiSwitch { label: "Desfocar o fundo da moldura"; checked: Settings.shellBlur; onToggled: on => Settings.shellBlur = on }
        UiSlider { label: "Limite de transparência"; from: 0; to: 90; value: Settings.shellIgnoreAlpha; suffix: " %"; onMoved: v => Settings.shellIgnoreAlpha = v }
        UiSlider { label: "Grão próprio (noise)"; from: 0; to: 20; value: Settings.shellGrain; suffix: " %"; onMoved: v => Settings.shellGrain = v }
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            color: Theme.muted; font.pixelSize: 12
            text: "O grão próprio é desenhado pelo Quickshell por cima da moldura, então pode ser diferente do ruído das janelas. A transparência da moldura fica em Aparência > Vidro."
        }
    }
}
