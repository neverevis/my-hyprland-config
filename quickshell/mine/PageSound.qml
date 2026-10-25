// Pagina "Som" (kit Set*): saida (cartoes dos dispositivos, volume, mudo), entrada (dispositivo, volume e medidor ao vivo),
// volume de cada aplicativo (a mesma logica do painel Inicio), limite de volume e sons do shell (vieram de Energia e sessao)
// e o equalizador (veio de Paineis). O medidor do microfone so roda com a pagina visivel (scripts/miclevel.py).
// Modo de teste (SysAct.dry): trocar o dispositivo padrao so e logado.
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

SetPage {
    id: page
    title: "Som"
    subtitle: "Saídas, entradas, volume por aplicativo, sons do shell e equalizador"
    readonly property bool live: visible && Settings.settingsOpen
    onLiveChanged: if (live) SysAct.check()

    // ---- dados (iguais aos do painel Inicio) ----
    readonly property var nodes: Pipewire.nodes.values
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinks: nodes.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: nodes.filter(n => n.audio && !n.isSink && !n.isStream)
    function isMeter(n) { const p = n.properties || {}; return (p["application.name"] || p["node.name"] || "") === "pw-cat" }   // o nosso medidor
    readonly property var streams: nodes.filter(n => n.audio && n.isStream && n.type === PwNodeType.AudioOutStream && !isMeter(n))
    readonly property var inStreams: nodes.filter(n => n.audio && n.isStream && n.type === PwNodeType.AudioInStream && !isMeter(n))
    PwObjectTracker { objects: page.live ? page.nodes.filter(n => n.audio) : [] }
    function nodeName(n) { return n ? (n.description || n.nickname || n.name || "Dispositivo sem nome") : "" }
    function appLabel(n) {
        const p = n.properties || {}
        const base = p["application.name"] || n.description || n.name || "App"
        return base + (p["media.name"] ? " • " + p["media.name"] : "")
    }
    function appIcon(n) {
        const p = n.properties || {}
        return Icons.path(p["application.icon-name"] || "", "") || Icons.app(p["application.process.binary"] || p["application.name"] || p["node.name"] || "")
    }
    function volIcon(a) { return !a || a.muted ? "volumeOff" : (a.volume > 0.66 ? "volume" : (a.volume > 0.25 ? "volumeMed" : "volumeLow")) }
    // tipo do dispositivo pelo nome: icone e rotulo curto
    function kindOf(n, input) {
        const s = ((n.name || "") + " " + (n.description || "")).toLowerCase()
        if (/hdmi|displayport|\bdp\b/.test(s)) return { icon: "monitor", label: "HDMI / DisplayPort" }
        if (/bluez/.test(s)) return { icon: "headphones", label: "Bluetooth" }
        if (/headset|headphone|fone/.test(s)) return { icon: "headphones", label: "Fones" }
        if (/usb/.test(s)) return { icon: input ? "mic" : "speaker", label: "USB" }
        if (/analog/.test(s)) return { icon: input ? "mic" : "speaker", label: "Analógico" }
        return { icon: input ? "mic" : "speaker", label: input ? "Entrada" : "Saída" }
    }
    function setDefault(n, input) {
        if (!SysAct.real("som: padrao " + (input ? "entrada " : "saida ") + nodeName(n))) return
        if (input) Pipewire.preferredDefaultAudioSource = n; else Pipewire.preferredDefaultAudioSink = n
    }

    // cartao de um dispositivo: icone por tipo, nome, marca de atual
    component DevCard: Rectangle {
        id: dc
        property var node
        property bool input: false
        readonly property bool current: input ? page.source === node : page.sink === node
        readonly property var kind: page.kindOf(node, input)
        width: 168; height: 84; radius: SetK.innerRadius
        color: current ? Theme.tint(0.16) : (hv.hovered ? Theme.cardHi : Theme.track)
        border.width: current ? 1 : 0; border.color: Theme.accent
        HoverHandler { id: hv }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.setDefault(dc.node, dc.input) }
        Rectangle {
            id: tile
            x: SetK.md; y: SetK.md; width: 30; height: 30; radius: 9
            color: dc.current ? Theme.accent : Theme.cardHi
            UiIcon { anchors.centerIn: parent; name: dc.kind.icon; size: 17; color: dc.current ? Theme.accentText : Theme.text }
        }
        UiText { anchors { left: tile.right; leftMargin: SetK.sm; right: ck.left; rightMargin: SetK.xs; verticalCenter: tile.verticalCenter } text: dc.kind.label; color: Theme.muted; font.pixelSize: 11; elide: Text.ElideRight }
        UiIcon { id: ck; visible: dc.current; anchors { right: parent.right; rightMargin: SetK.md; verticalCenter: tile.verticalCenter } name: "check"; size: 16; color: Theme.accent }
        UiText {
            anchors { left: parent.left; leftMargin: SetK.md; right: parent.right; rightMargin: SetK.md; top: tile.bottom; topMargin: SetK.sm }
            text: page.nodeName(dc.node); color: Theme.text; font.pixelSize: 12; font.weight: Font.Medium
            wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
        }
    }

    // ---- saida ----
    SetSection {
        title: "Saída"; icon: "speaker"
        subtitle: page.sink ? page.nodeName(page.sink) : "Nenhuma saída de som encontrada"
        SetRow { visible: page.sinks.length === 0; icon: "info"; label: "Sem saída de som"; description: "O PipeWire não listou nenhuma; confira se o serviço (pipewire e wireplumber) está rodando" }
        SetBlock {
            visible: page.sinks.length > 0
            Flow {
                width: parent.width; spacing: SetK.sm
                Repeater {
                    model: ScriptModel { values: page.sinks; objectProp: "id" }
                    delegate: DevCard { required property var modelData; node: modelData } }
            }
        }
        SetSlider {
            readonly property var a: page.sink ? page.sink.audio : null
            icon: page.volIcon(a); label: "Volume"; from: 0; to: Settings.volGuard ? Math.max(30, Settings.volMax) : 100; unit: " %"
            value: a ? Math.round(a.volume * 100) : 0
            onMoved: v => { if (a) { a.volume = v / 100; if (a.muted && v > 0) a.muted = false } }
        }
        SetRow {
            readonly property var a: page.sink ? page.sink.audio : null
            icon: "volumeOff"; label: "Silenciar a saída"; checked: !!a && a.muted
            onToggled: on => { if (a) a.muted = on }
        }
    }

    // ---- entrada ----
    SetSection {
        title: "Entrada"; icon: "mic"
        subtitle: page.source ? page.nodeName(page.source) : "Nenhum microfone encontrado"
        SetRow { visible: page.sources.length === 0; icon: "info"; label: "Sem microfone"; description: "Conecte um microfone; se já estiver conectado, confira o PipeWire" }
        SetBlock {
            visible: page.sources.length > 0
            Flow {
                width: parent.width; spacing: SetK.sm
                Repeater {
                    model: ScriptModel { values: page.sources; objectProp: "id" }
                    delegate: DevCard { required property var modelData; node: modelData; input: true } }
            }
        }
        SetSlider {
            readonly property var a: page.source ? page.source.audio : null
            icon: a && a.muted ? "micOff" : "mic"; label: "Volume do microfone"; from: 0; to: 100; unit: " %"
            value: a ? Math.round(a.volume * 100) : 0
            onMoved: v => { if (a) { a.volume = v / 100; if (a.muted && v > 0) a.muted = false } }
        }
        SetRow {
            readonly property var a: page.source ? page.source.audio : null
            icon: "micOff"; label: "Silenciar o microfone"; checked: !!a && a.muted
            onToggled: on => { if (a) a.muted = on }
        }
        // medidor ao vivo: um pw-cat + script so enquanto a pagina esta visivel e o microfone nao esta mudo
        SetBlock {
            id: meter
            visible: !!page.source
            property int level: 0
            property bool fail: false
            readonly property bool on: page.live && !!page.source && !(page.source.audio && page.source.audio.muted)
            onOnChanged: if (!on) level = 0
            Process {
                id: meterProc
                running: meter.on
                onRunningChanged: if (running) meter.fail = false
                onExited: code => { if (meter.on && code !== 0) meter.fail = true }
                command: ["sh", "-c", 'exec pw-cat --record --rate 8000 --channels 1 --format s16 --latency 100ms - 2>/dev/null | exec python3 "$1"', "sh", Qt.resolvedUrl("scripts/miclevel.py").toString().replace("file://", "")]
                stdout: SplitParser { onRead: line => meter.level = Math.max(0, Math.min(100, parseInt(line) || 0)) }
            }
            Item {
                width: parent.width; height: 20
                UiText { id: mlbl; anchors.verticalCenter: parent.verticalCenter; text: meter.fail ? "Medidor indisponível (precisa do pw-cat, do pipewire)" : meter.on ? "Nível ao vivo" : "Microfone mudo"; color: Theme.muted; font.pixelSize: SetK.fDesc }
                Rectangle {
                    anchors { left: mlbl.right; leftMargin: SetK.md; right: parent.right; verticalCenter: parent.verticalCenter }
                    height: 8; radius: 4; color: Theme.track; border.width: 1; border.color: Theme.border
                    Rectangle {
                        width: parent.width * meter.level / 100; height: parent.height; radius: 4
                        color: meter.level > 85 ? Theme.danger : Theme.accent
                    }
                }
            }
        }
        SetRow { visible: page.inStreams.length > 0; icon: "info"; label: page.inStreams.length === 1 ? "1 aplicativo usando o microfone" : page.inStreams.length + " aplicativos usando o microfone"
            description: page.inStreams.map(n => page.appLabel(n).split(" • ")[0]).join(", ") }
    }

    // ---- por aplicativo ----
    SetSection {
        title: "Volume por aplicativo"; icon: "apps"
        subtitle: page.streams.length === 0 ? "Nenhum aplicativo tocando som agora" : "Clique no ícone para silenciar"
        SetBlock {
            visible: page.streams.length > 0
            Repeater {
                model: ScriptModel { values: page.streams; objectProp: "id" }
                delegate: HomeSlider {
                    required property var modelData
                    readonly property var a: modelData.audio
                    label: page.appLabel(modelData)
                    iconSource: page.appIcon(modelData)
                    icon: page.volIcon(a)
                    value: a ? a.volume : 0
                    muted: !!a && a.muted
                    onMoved: v => { if (a) { a.volume = v; if (a.muted && v > 0) a.muted = false } }
                    onIconClicked: if (a) a.muted = !a.muted
                }
            }
        }
        SetRow { icon: "cog"; label: "Mixer completo"; description: "Abre o aplicativo de volume do sistema"; link: true; onClicked: AppCmds.run("mixer") }
    }

    // ---- limite e sons do shell (vieram de Energia e sessao; mesmas chaves) ----
    SetSection {
        title: "Volume e sons"; icon: "volume"
        SetRow { icon: "shield"; label: "Limitar o volume"; description: "Nunca passa do teto e um salto grande de uma vez é contido"; checked: Settings.volGuard; onToggled: on => Settings.volGuard = on }
        SetSlider { visible: Settings.volGuard; sub: true; label: "Teto"; from: 30; to: 150; unit: " %"; value: Settings.volMax; onMoved: v => Settings.volMax = Math.round(v) }
        SetSlider { visible: Settings.volGuard; sub: true; label: "Maior aumento de uma vez"; from: 0; to: 50; unit: " %"; zeroLabel: "Sem limite"; value: Settings.volJump; onMoved: v => Settings.volJump = Math.round(v) }
        SetRow { icon: "speaker"; label: "Sons do shell"; description: "Notificação nova, captura de tela e erro"; checked: Settings.sounds; onToggled: on => Settings.sounds = on }
        SetSlider { visible: Settings.sounds; sub: true; label: "Volume dos sons"; from: 10; to: 100; unit: " %"; value: Settings.soundVolume; onMoved: v => Settings.soundVolume = Math.round(v) }
        SetRow { visible: Settings.sounds; sub: true; label: "Clique ao mudar o volume"; checked: Settings.soundVolChange; onToggled: on => Settings.soundVolChange = on }
        SetRow { icon: "volume"; label: "Indicador de volume nas barras"; description: "Aparência do módulo de volume"; link: true; onClicked: { Settings.settingsReveal = "Indicador de volume"; Settings.settingsPage = "bars" } }
    }

    // ---- equalizador (veio de Paineis) ----
    SetSection {
        title: "Equalizador"; icon: "wave"; subtitle: "Efeitos de áudio pelo EasyEffects"
        SetExpander {
            icon: "wave"; label: "Equalizador e presets"; description: "Ligar efeitos, preset e 10 bandas"
            lazy: Component { SetBlock { sub: true; EqCard { width: parent.width } } }
        }
    }
}
