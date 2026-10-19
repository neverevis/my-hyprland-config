// Janela do indicador rapido (Osd.qml): volume, microfone e midia.
// Acoplado: o bloco sai da moldura (a moldura desenha o fundo, aqui so o conteudo, revelado conforme cresce).
// Solto: pilula com fundo proprio, perto da borda escolhida, entrando com a mesma animacao ("Indicador de volume").
// Nao pega o mouse nem o teclado (so mostra).
import Quickshell
import Quickshell.Wayland
import QtQuick

Scope {
    id: root
    property var geo: ({ osd: null })

    property bool alive: false
    readonly property bool want: Settings.osdOn && Osd.showing
    onWantChanged: if (want) { closeT.stop(); alive = true } else closeT.restart()
    Timer { id: closeT; interval: Motion.durationOf("osd", true) + 80; onTriggered: root.alive = false }

    LazyLoader {
        active: root.alive

        PanelWindow {
            id: win
            anchors { left: true; right: true; top: true; bottom: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "mine-osd"

            readonly property string side: Settings.osdSide
            readonly property bool vert: side === "left" || side === "right"
            readonly property bool docked: Settings.osdDocked
            readonly property real e: Settings.edge
            readonly property real pp: BarState.osdProg
            readonly property real dep: BarState.osdDepth
            readonly property real len: BarState.osdLen(vert)

            // ---- acoplado: area do bloco que ja saiu da moldura ----
            readonly property var pk: root.geo.osd
            readonly property real fullDepth: pk ? pk.t : 0
            readonly property real vis: Math.max(0, e + (fullDepth - e) * pp)
            readonly property real lag: fullDepth - vis
            readonly property rect clipR: !docked || !pk ? Qt.rect(0, 0, width, height)
                : side === "top" ? Qt.rect(pk.rect.x, 0, pk.rect.w, vis)
                : side === "bottom" ? Qt.rect(pk.rect.x, height - vis, pk.rect.w, vis)
                : side === "left" ? Qt.rect(0, pk.rect.y, vis, pk.rect.h)
                : Qt.rect(width - vis, pk.rect.y, vis, pk.rect.h)
            // caixa do conteudo (tela): dentro do bloco, sem a espessura da moldura
            readonly property rect dbox: !pk ? Qt.rect(0, 0, 0, 0)
                : side === "top" ? Qt.rect(pk.rect.x + 14, pk.rect.y + e + 10, pk.rect.w - 28, dep)
                : side === "bottom" ? Qt.rect(pk.rect.x + 14, pk.rect.y + 10, pk.rect.w - 28, dep)
                : side === "left" ? Qt.rect(pk.rect.x + e + 10, pk.rect.y + 14, dep, pk.rect.h - 28)
                : Qt.rect(pk.rect.x + 10, pk.rect.y + 14, dep, pk.rect.h - 28)
            // ---- solto: pilula afastada da borda; desliza dela para dentro ----
            readonly property real gap: 22
            readonly property real fw: vert ? dep + 20 : len
            readonly property real fh: vert ? len : dep + 20
            readonly property real away: (1 - pp) * 40
            readonly property rect fbox: side === "top" ? Qt.rect((width - fw) / 2, e + gap - away, fw, fh)
                : side === "bottom" ? Qt.rect((width - fw) / 2, height - e - gap - fh + away, fw, fh)
                : side === "left" ? Qt.rect(e + gap - away, (height - fh) / 2, fw, fh)
                : Qt.rect(width - e - gap - fw + away, (height - fh) / 2, fw, fh)

            Item {
                id: holder
                x: win.clipR.x; y: win.clipR.y
                width: win.clipR.width; height: win.clipR.height
                clip: win.docked

                Item {
                    id: inner
                    x: -holder.x + (!win.docked ? 0 : win.side === "left" ? -win.lag : (win.side === "right" ? win.lag : 0))
                    y: -holder.y + (!win.docked ? 0 : win.side === "top" ? -win.lag : (win.side === "bottom" ? win.lag : 0))
                    width: win.width; height: win.height

                    // fundo da pilula solta (a acoplada usa a moldura)
                    Rectangle {
                        visible: !win.docked
                        x: win.fbox.x; y: win.fbox.y; width: win.fbox.width; height: win.fbox.height
                        radius: Math.min(width, height) / 2
                        color: Theme.gl(Settings.barColor, 1)
                        border.width: Settings.outline ? 1 : 0
                        border.color: Theme.border
                        opacity: Math.max(0, Math.min(1, win.pp * 2))
                        scale: 0.92 + 0.08 * Math.min(1, win.pp)
                    }

                    OsdContent {
                        readonly property rect b: win.docked ? win.dbox : Qt.rect(win.fbox.x + (win.vert ? 10 : 18), win.fbox.y + (win.vert ? 18 : 10), win.fbox.width - (win.vert ? 20 : 36), win.fbox.height - (win.vert ? 36 : 20))
                        x: b.x; y: b.y; width: b.width; height: b.height
                        vertical: win.vert
                        opacity: Math.max(0, Math.min(1, win.pp * 3 - 0.4))
                    }
                }
            }
        }
    }

    // icone + barra + valor (vertical: valor em cima, barra no meio, icone embaixo)
    component OsdContent: Item {
        id: c
        property bool vertical: true
        readonly property bool isMedia: Osd.kind === "media"
        readonly property bool isMic: Osd.kind === "mic"
        readonly property real level: isMic ? (Osd.micMuted ? 0 : 1) : (Osd.muted ? 0 : Math.min(1.5, Osd.volume))
        readonly property string icon: isMedia ? Osd.mediaIcon : isMic ? (Osd.micMuted ? "micOff" : "mic")
            : (Osd.muted || Osd.volume <= 0.001 ? "volumeOff" : Osd.volume < 0.34 ? "volumeLow" : Osd.volume < 0.67 ? "volumeMed" : "volume")
        readonly property string label: isMedia ? "" : isMic ? (Osd.micMuted ? "mudo" : "ligado") : (Osd.muted ? "mudo" : Math.round(Osd.volume * 100) + "")
        readonly property color fg: Settings.textColor
        readonly property color ac: Settings.accent

        // ---- volume / microfone ----
        Item {
            anchors.fill: parent
            visible: !c.isMedia
            UiIcon {
                id: ic
                name: c.icon; size: 20; color: c.fg
                x: c.vertical ? (parent.width - width) / 2 : 0
                y: c.vertical ? parent.height - height : (parent.height - height) / 2
            }
            Text {
                id: val
                text: c.label; color: c.fg; font.pixelSize: 12; font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                width: c.vertical ? parent.width : 40
                x: c.vertical ? 0 : parent.width - width
                y: c.vertical ? 0 : (parent.height - height) / 2
            }
            // trilho e preenchimento (acima de 100% fica em outra cor)
            Rectangle {
                id: track
                readonly property real th: 6
                x: c.vertical ? (parent.width - th) / 2 : ic.width + 12
                y: c.vertical ? val.height + 10 : (parent.height - th) / 2
                width: c.vertical ? th : parent.width - ic.width - val.width - 24
                height: c.vertical ? parent.height - val.height - ic.height - 20 : th
                radius: th / 2
                color: Qt.rgba(c.fg.r, c.fg.g, c.fg.b, 0.16)
                readonly property real f: Math.min(1, c.level)
                Rectangle {
                    radius: parent.radius
                    color: c.ac
                    width: c.vertical ? parent.width : parent.width * track.f
                    height: c.vertical ? parent.height * track.f : parent.height
                    y: c.vertical ? parent.height - height : 0
                    Behavior on width { enabled: !c.vertical; NumberAnimation { duration: 90 } }
                    Behavior on height { enabled: c.vertical; NumberAnimation { duration: 90 } }
                }
            }
        }

        // ---- midia: icone e titulo ----
        Item {
            anchors.fill: parent
            visible: c.isMedia
            UiIcon {
                id: mic
                name: c.icon; size: 22; color: c.ac
                x: c.vertical ? (parent.width - width) / 2 : 0
                y: c.vertical ? 0 : (parent.height - height) / 2
            }
            Text {
                text: Osd.mediaText; color: c.fg; font.pixelSize: 12; font.weight: Font.Medium
                elide: Text.ElideRight
                width: c.vertical ? parent.height - mic.height - 14 : parent.width - mic.width - 12
                // na vertical o titulo corre ao longo da barra (girado)
                rotation: c.vertical ? -90 : 0
                transformOrigin: Item.Center
                x: c.vertical ? (parent.width - width) / 2 : mic.width + 12
                y: c.vertical ? mic.height + 14 + (parent.height - mic.height - 14) / 2 - height / 2 : (parent.height - height) / 2
                horizontalAlignment: c.vertical ? Text.AlignHCenter : Text.AlignLeft
            }
        }
    }
}
