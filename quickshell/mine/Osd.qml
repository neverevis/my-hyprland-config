// Indicador rapido (OSD): aparece quando o volume ou o mudo do microfone mudam (por tecla, roda na barra, outro app...)
// e quando as teclas de midia sao usadas. Acoplado, sai da moldura como as notificacoes; solto, e uma pilula flutuante.
// IPC:  qs -c mine ipc call media toggle | next | previous | stop   (teclas de midia; mostram o que esta tocando)
//       qs -c mine ipc call osd preview
pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [root.sink, root.source] }
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: !!(sink && sink.audio && sink.audio.muted)
    readonly property bool micMuted: !!(source && source.audio && source.audio.muted)

    // o que mostrar: volume | mic | media
    property string kind: "volume"
    property bool showing: false
    property string mediaText: ""
    property string mediaIcon: "play"
    // ignora as mudancas do inicio (o PipeWire preenche os valores) e as feitas no painel Inicio (ja tem o controle na tela)
    property bool armed: false
    Timer { interval: 2500; running: true; onTriggered: root.armed = true }

    // a ilha dinamica tambem mostra volume/microfone/midia (mesmo com o indicador desligado)
    property int bump: 0
    property string bumpKind: "volume"
    function show(k) {
        if (armed) { bumpKind = k; bump++; if (k === "volume" && Settings.soundVolChange) SystemGuard.sound("volume") }
        if (!Settings.osdOn || !armed) return
        if (k !== "media" && (Settings.homeOpen || Power.locked)) return
        kind = k
        showing = true
        hideT.restart()
    }
    function preview() { const was = armed; armed = true; show("volume"); armed = was }
    Timer { id: hideT; interval: Math.max(600, Settings.osdTimeout); onTriggered: root.showing = false }

    onVolumeChanged: show("volume")
    onMutedChanged: show("volume")
    onMicMutedChanged: show("mic")

    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    function media(action) {
        const p = player
        if (!p) { mediaText = "Nada tocando"; mediaIcon = "music"; show("media"); return }
        if (action === "toggle" && p.canTogglePlaying) p.togglePlaying()
        else if (action === "next" && p.canGoNext) p.next()
        else if (action === "previous" && p.canGoPrevious) p.previous()
        else if (action === "stop" && p.canControl) p.stop()
        mediaIcon = action === "next" ? "next" : action === "previous" ? "prev" : action === "stop" ? "pause" : (p.isPlaying ? "pause" : "play")
        mediaText = p.trackTitle || p.identity || "Mídia"
        show("media")
    }
    // o titulo muda um pouco depois de pular de faixa: atualiza o texto enquanto o indicador esta aberto
    Connections {
        target: root.player
        function onTrackTitleChanged() { if (root.showing && root.kind === "media") root.mediaText = root.player.trackTitle || root.mediaText }
    }

    IpcHandler {
        target: "media"
        function toggle(): void { root.media("toggle") }
        function next(): void { root.media("next") }
        function previous(): void { root.media("previous") }
        function stop(): void { root.media("stop") }
    }
    IpcHandler {
        target: "osd"
        function preview(): void { root.preview() }
    }
}
