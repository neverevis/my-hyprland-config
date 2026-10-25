// Volume do PipeWire. Clique = mudo; roda = ajusta.
// Opcoes: display (text|bar|segments|ring|disc), label, showValue, width, height, color, step (%), segments
import Quickshell.Services.Pipewire
import QtQuick

MeterView {
    id: root
    property var opts: ({})
    readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    display: opts.display ?? "text"
    label: opts.label ?? "VOL"
    showValue: opts.showValue ?? (display === "text")
    w: opts.width ?? 60
    h: opts.height ?? (round ? 22 : 16)
    icon: audio && audio.muted ? "volumeOff" : "volume"
    col: opts.color ? opts.color : (Settings.themeOn ? ThemeColors.primary : Settings.textColor)   // sem cor escolhida: destaque do tema (se ligado)
    segments: opts.segments ?? 8
    value: audio && !audio.muted ? Math.min(1, audio.volume) : 0
    dim: !!(audio && audio.muted)
    valueText: audio ? (audio.muted ? "mudo" : Math.round(audio.volume * 100) + "%") : "--"

    scale: vm.pressed ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Rectangle {   // fundo suave ao passar o mouse
        z: -1
        anchors { fill: parent; leftMargin: -6; rightMargin: -6; topMargin: -3; bottomMargin: -3 }
        radius: 8
        color: Qt.rgba(Settings.textColor.r, Settings.textColor.g, Settings.textColor.b, vm.containsMouse ? 0.12 : 0)
        Behavior on color { ColorAnimation { duration: 140 } }
    }
    MouseArea {
        id: vm
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.audio) root.audio.muted = !root.audio.muted
        onWheel: w => {
            if (!root.audio) return
            const st = (root.opts.step ?? 5) / 100
            root.audio.volume = Math.max(0, Math.min(1, root.audio.volume + (w.angleDelta.y > 0 ? st : -st)))
        }
    }
}
