// Notificacoes: o Quickshell vira o servidor (org.freedesktop.Notifications) e mostra os avisos como um bloco que cresce da moldura.
// Clique no cartao: executa a acao padrao (se houver) e fecha; clique direito fecha; o mouse em cima pausa o tempo.
// IPC:  qs -c mine ipc call notifications dnd | clear | test
// Configuracoes: pagina "Notificacoes".
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick

Scope {
    id: root
    property var geo: ({ notif: null })   // resultado de Geometry.compute (vem do shell.qml)

    readonly property bool vert: Settings.notifSide === "left" || Settings.notifSide === "right"
    readonly property real cardW: Settings.notifWidth
    readonly property real cardH: 92
    readonly property real gap: 8
    readonly property var all: server.trackedNotifications.values
    readonly property int shownCount: Math.min(all.length, Math.max(1, Settings.notifMax))

    IpcHandler {
        target: "notifications"
        function dnd(): void { Settings.notifDnd = !Settings.notifDnd }
        function clear(): void { for (const n of root.all.slice()) n.dismiss() }
        function test(): void { testProc.running = false; testProc.running = true }
    }
    Process { id: testProc; command: ["notify-send", "-a", "Quickshell", "-i", "dialog-information", "Notificação de teste", "Assim os avisos aparecem, ligados à moldura."] }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        onNotification: n => { n.tracked = true; NotifHistory.add(n) }
    }

    // ---- tamanho do bloco (a moldura acoplada cresce ate ele) ----
    readonly property real stackLen: shownCount > 0 ? (vert ? shownCount * cardH + (shownCount - 1) * gap : shownCount * cardW + (shownCount - 1) * gap) + 20 : 0
    readonly property real stackDepth: vert ? cardW : cardH
    onStackLenChanged: BarState.notifLen = stackLen
    onStackDepthChanged: BarState.notifDepth = stackDepth
    // so conta quando ha o que mostrar (nao perturbe esconde tudo, mas guarda)
    readonly property int visibleCount: Settings.notifOn && !Settings.notifDnd ? shownCount : 0
    Component.onCompleted: { BarState.notifLen = stackLen; BarState.notifDepth = stackDepth; BarState.notifCount = visibleCount }

    // janela existe enquanto houver bloco visivel (ou a animacao de saida)
    property bool alive: false
    onVisibleCountChanged: {
        BarState.notifCount = visibleCount
        if (visibleCount > 0) { closeT.stop(); alive = true } else closeT.restart()
    }
    Timer { id: closeT; interval: 600; onTriggered: root.alive = false }

    LazyLoader {
        active: root.alive && Settings.notifOn

        PanelWindow {
            id: win
            anchors { left: true; right: true; top: true; bottom: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "mine-notifications"
            // so o bloco recebe o mouse; o resto da tela fica livre
            mask: Region { item: hit }

            readonly property string side: Settings.notifSide
            readonly property real e: Settings.edge
            readonly property bool docked: Settings.notifDocked
            readonly property var pk: root.geo.notif
            readonly property real pp: BarState.notifProg
            readonly property real fullDepth: pk ? pk.t : 0
            readonly property real vis: Math.max(0, e + (fullDepth - e) * pp)
            // parte visivel do bloco (cresce da borda): recorta o conteudo
            // solto: o bloco fica afastado da borda (e das barras daquele lado) e entra deslizando dela
            readonly property real fGap: 14
            readonly property real fLen: root.stackLen - 20
            readonly property real fDepth: root.stackDepth
            readonly property var zone: root.geo.zone ?? ({ top: e, right: e, bottom: e, left: e })
            readonly property real fAlong: {
                const vert = root.vert
                const a0 = (vert ? zone.top : zone.left) + fGap, a1 = (vert ? height - zone.bottom : width - zone.right) - fGap
                const an = Settings.notifAnchor
                return an === "start" ? a0 : an === "end" ? a1 - fLen : (a0 + a1 - fLen) / 2
            }
            readonly property real fAway: (1 - Math.min(1, pp)) * 48
            readonly property rect fRect: side === "top" ? Qt.rect(fAlong, zone.top + fGap - fAway, fLen, fDepth)
                : side === "bottom" ? Qt.rect(fAlong, height - zone.bottom - fGap - fDepth + fAway, fLen, fDepth)
                : side === "left" ? Qt.rect(zone.left + fGap - fAway, fAlong, fDepth, fLen)
                : Qt.rect(width - zone.right - fGap - fDepth + fAway, fAlong, fDepth, fLen)
            readonly property rect clipR: !docked ? fRect : !pk ? Qt.rect(0, 0, 0, 0)
                : side === "top" ? Qt.rect(pk.rect.x, 0, pk.rect.w, vis)
                : side === "bottom" ? Qt.rect(pk.rect.x, height - vis, pk.rect.w, vis)
                : side === "left" ? Qt.rect(0, pk.rect.y, vis, pk.rect.h)
                : Qt.rect(width - vis, pk.rect.y, vis, pk.rect.h)
            readonly property real lag: docked ? fullDepth - vis : 0
            // origem do primeiro cartao (tela)
            readonly property real ox: !docked ? fRect.x : !pk ? 0 : (side === "left" ? pk.rect.x + e + 10 : (side === "right" ? pk.rect.x + 10 : pk.rect.x + 10))
            readonly property real oy: !docked ? fRect.y : !pk ? 0 : (side === "top" ? pk.rect.y + e + 10 : (side === "bottom" ? pk.rect.y + 10 : pk.rect.y + 10))

            Item {
                id: hit
                x: win.clipR.x; y: win.clipR.y
                width: win.clipR.width; height: win.clipR.height
            }

            Item {
                id: holder
                x: win.clipR.x; y: win.clipR.y
                width: win.clipR.width; height: win.clipR.height
                clip: win.docked

                Item {
                    id: inner
                    x: -holder.x + (win.side === "left" ? -win.lag : (win.side === "right" ? win.lag : 0))
                    y: -holder.y + (win.side === "top" ? -win.lag : (win.side === "bottom" ? win.lag : 0))
                    width: win.width; height: win.height
                    opacity: Math.max(0, Math.min(1, win.pp * (win.docked ? 4 : 1.6)))

                    Repeater {
                        model: server.trackedNotifications
                        delegate: Item {
                            id: card
                            required property var modelData      // Notification
                            required property int index
                            readonly property var n: modelData
                            readonly property int rank: root.all.length - 1 - index   // 0 = a mais nova
                            readonly property bool critical: n.urgency === NotificationUrgency.Critical
                            readonly property bool shown: rank < root.shownCount
                            width: root.cardW; height: root.cardH
                            // posicao: cartoes enfileirados ao longo da borda (animados)
                            readonly property real along: rank * ((root.vert ? root.cardH : root.cardW) + root.gap)
                            x: win.ox + (root.vert ? 0 : along)
                            y: win.oy + (root.vert ? along : 0)
                            Behavior on x { enabled: !root.vert; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                            Behavior on y { enabled: root.vert; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                            opacity: shown ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                            visible: opacity > 0.01

                            // ---- tempo ate sumir ----
                            readonly property real total: critical ? 0 : (n.expireTimeout > 0 ? n.expireTimeout * 1000 : Settings.notifTimeout * 1000)
                            property real remain: total
                            Timer {
                                interval: 50; repeat: true
                                running: card.total > 0 && card.shown && !hover.hovered
                                onTriggered: { card.remain -= 50; if (card.remain <= 0) card.n.expire() }
                            }

                            // ---- cartao ----
                            Rectangle {
                                id: bg
                                anchors.fill: parent
                                radius: Settings.notifRadius
                                color: win.docked ? Qt.rgba(Theme.cardHi.r, Theme.cardHi.g, Theme.cardHi.b, 0.92) : Theme.gl(Settings.barColor, 1)
                                border.width: 1
                                border.color: card.critical ? Theme.danger : Theme.border
                                scale: hover.hovered ? 1.015 : 1
                                Behavior on scale { NumberAnimation { duration: 120 } }
                                clip: true

                                // barra de tempo restante (fina, na base)
                                Rectangle {
                                    visible: card.total > 0
                                    anchors { left: parent.left; bottom: parent.bottom }
                                    height: 3
                                    width: parent.width * Math.max(0, card.remain / card.total)
                                    color: card.critical ? Theme.danger : Theme.accent
                                    opacity: 0.8
                                }

                                // ---- icone / imagem ----
                                Rectangle {
                                    id: iconBox
                                    anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                                    width: 52; height: 52; radius: 12
                                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
                                    clip: true
                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: card.n.image !== "" ? 0 : 8
                                        source: card.n.image !== "" ? card.n.image : Icons.path(card.n.appIcon, "dialog-information")
                                        fillMode: card.n.image !== "" ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                                        sourceSize: Qt.size(104, 104)
                                        asynchronous: true
                                        smooth: true
                                    }
                                }

                                // ---- texto ----
                                Column {
                                    anchors { left: iconBox.right; leftMargin: 12; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                                    spacing: 2
                                    UiText {
                                        width: parent.width
                                        text: card.n.appName
                                        visible: text !== ""
                                        color: Theme.muted; font.pixelSize: 11; font.weight: Font.Medium
                                        elide: Text.ElideRight
                                    }
                                    UiText {
                                        width: parent.width
                                        text: card.n.summary
                                        color: Theme.text; font.pixelSize: 14; font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }
                                    UiText {
                                        width: parent.width
                                        text: card.n.body
                                        visible: text !== ""
                                        textFormat: Text.StyledText
                                        color: Theme.muted; font.pixelSize: 12
                                        wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                                    }
                                }

                                HoverHandler { id: hover }
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: e => {
                                        if (e.button === Qt.LeftButton) {
                                            const def = card.n.actions.find(a => a.identifier === "default")
                                            if (def) def.invoke()
                                        }
                                        card.n.dismiss()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
