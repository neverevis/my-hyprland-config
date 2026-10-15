// Seletor de wallpaper: um painel sai da borda da tela (acoplado a moldura, ou flutuante) com as imagens enfileiradas.
// Role o mouse (ou use as setas) para ir ao proximo/anterior; Enter ou clique aplica; Esc fecha.
// Lado (cima/baixo/esquerda/direita), acoplado e deslocamento: Settings.wpPicker*  (pagina Wallpaper).
// IPC:  qs -c mine ipc call wallpaper pick | next | prev | random
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects

Scope {
    id: root
    property var geo: ({ picker: null })   // resultado de Geometry.compute (vem do shell.qml)

    IpcHandler {
        target: "wallpaper"
        function pick(): void { if (!Settings.wpPickerOpen) { Settings.launcherOpen = false; Settings.settingsOpen = false } Settings.wpPickerOpen = !Settings.wpPickerOpen }
        function close(): void { Settings.wpPickerOpen = false }
        function next(): void { Wallpaper.step(1) }
        function prev(): void { Wallpaper.step(-1) }
        function random(): void { Wallpaper.random() }
    }

    // mantem a janela ate a animacao de saida terminar
    property bool alive: false
    property bool warm: false
    Timer { interval: 1500; running: true; onTriggered: { root.warm = true; warmOff.start() } }
    Timer { id: warmOff; interval: 12000; onTriggered: root.warm = false }
    Connections {
        target: Settings
        function onWpPickerOpenChanged() {
            if (Settings.wpPickerOpen) { closeTimer.stop(); root.alive = true }
            else closeTimer.restart()
        }
    }
    Timer { id: closeTimer; interval: 420; onTriggered: root.alive = false }

    // a janela fica sempre carregada (so escondida quando fechada): as miniaturas continuam decodificadas na memoria
    LazyLoader {
        active: true

        PanelWindow {
            id: win
            visible: root.alive || root.warm   // 'warm': aparece invisivel por instantes ao iniciar, so para carregar as miniaturas
            mask: root.alive ? null : emptyMask   // escondido/aquecendo: nao pega o mouse
            Region { id: emptyMask }
            anchors { left: true; right: true; top: true; bottom: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.alive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.namespace: "mine-wallpaper-picker"   // regra do Hyprland: sem animacao propria (a animacao e daqui)

            // mantem TODAS as miniaturas decodificadas na memoria (o carrossel circular so cria os cartoes proximos do centro,
            // e o cache de imagens do Qt so vale enquanto alguem usa a imagem): abrir o seletor nao recarrega nada
            Item {
                visible: false
                Repeater {
                    model: Wallpaper.files
                    delegate: Image {
                        required property var modelData
                        source: "file://" + modelData.path
                        sourceSize: Qt.size(480, 270)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }
            }

            // ---- geometria ----
            readonly property string side: Settings.wpPickerSide
            readonly property bool vert: side === "left" || side === "right"
            readonly property bool docked: Settings.wpPickerDocked
            readonly property real e: Settings.edge                       // espessura da moldura
            readonly property real cellLen: vert ? 142 : 256              // tamanho de um item ao longo da fila
            readonly property real contentDepth: Geometry.pickerDepth(vert)   // profundidade do conteudo
            readonly property real len: Geometry.pickerLen(vert, width, height)
            readonly property real total: vert ? height : width
            readonly property real pp: BarState.pickerProg                // progresso (0..1), mesma animacao das barras

            // acoplado: a moldura (Geometry) ja cresceu ate aqui; usamos o retangulo dessa "barra"
            readonly property var pk: geo.picker
            // flutuante: posicao propria
            readonly property real fcenter: Math.max(len / 2 + 20, Math.min(total - len / 2 - 20, total / 2 + Settings.wpPickerOffset))
            readonly property real v0: e + Settings.wpPickerGap
            readonly property rect fbox: side === "top" ? Qt.rect(fcenter - len / 2, v0, len, contentDepth)
                : side === "bottom" ? Qt.rect(fcenter - len / 2, height - v0 - contentDepth, len, contentDepth)
                : side === "left" ? Qt.rect(v0, fcenter - len / 2, contentDepth, len)
                : Qt.rect(width - v0 - contentDepth, fcenter - len / 2, contentDepth, len)

            // retangulo do conteudo (tela)
            readonly property rect box: docked && pk ? (
                side === "top" ? Qt.rect(pk.rect.x, pk.rect.y + e + 8, pk.rect.w, contentDepth)
                : side === "bottom" ? Qt.rect(pk.rect.x, pk.rect.y + 12, pk.rect.w, contentDepth)
                : side === "left" ? Qt.rect(pk.rect.x + e + 8, pk.rect.y, contentDepth, pk.rect.h)
                : Qt.rect(pk.rect.x + 12, pk.rect.y, contentDepth, pk.rect.h)) : fbox

            // docked: parte visivel do painel (cresce da borda) -> recorta o conteudo; ele tambem sobe junto
            readonly property real fullDepth: docked && pk ? pk.t : 0
            readonly property real vis: docked ? Math.max(0, Math.min(fullDepth, e + (fullDepth - e) * pp)) : 0
            readonly property rect clipR: !docked || !pk ? Qt.rect(0, 0, 0, 0)
                : side === "top" ? Qt.rect(pk.rect.x, 0, pk.rect.w, vis)
                : side === "bottom" ? Qt.rect(pk.rect.x, height - vis, pk.rect.w, vis)
                : side === "left" ? Qt.rect(0, pk.rect.y, vis, pk.rect.h)
                : Qt.rect(width - vis, pk.rect.y, vis, pk.rect.h)
            // quanto o conteudo ainda esta deslocado em direcao a borda
            readonly property real lag: docked ? fullDepth - vis : (1 - Math.min(1, pp)) * (e + Settings.wpPickerGap + contentDepth + 40)

            // clique fora fecha
            MouseArea { anchors.fill: parent; onClicked: Settings.wpPickerOpen = false }

            // ---- flutuante: painel proprio que desliza da borda ----
            Rectangle {
                visible: !win.docked
                x: win.fbox.x - 8 + (win.side === "left" ? -win.lag : (win.side === "right" ? win.lag : 0))
                y: win.fbox.y - 8 + (win.side === "top" ? -win.lag : (win.side === "bottom" ? win.lag : 0))
                width: win.fbox.width + 16; height: win.fbox.height + 16
                radius: 24
                color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.94)
                border.width: 1; border.color: Theme.border
                MouseArea { anchors.fill: parent }
            }

            // ---- conteudo (recortado pela parte visivel do painel quando acoplado) ----
            Item {
                id: holder
                x: win.docked ? win.clipR.x : 0
                y: win.docked ? win.clipR.y : 0
                width: win.docked ? win.clipR.width : win.width
                height: win.docked ? win.clipR.height : win.height
                clip: win.docked

                MouseArea { anchors.fill: parent; visible: win.docked }   // clique no painel nao fecha

                Item {
                    id: inner
                    // coordenadas da tela: o conteudo fica no lugar final e sobe junto com a moldura
                    x: -holder.x + (win.side === "left" ? -win.lag : (win.side === "right" ? win.lag : 0))
                    y: -holder.y + (win.side === "top" ? -win.lag : (win.side === "bottom" ? win.lag : 0))
                    width: win.width; height: win.height
                    opacity: Math.max(0, Math.min(1, win.pp * 1.4 - 0.2))

                // ---- fila de imagens ----
                PathView {
                    id: list
                    // a lista mostra exatamente N cartoes (a folga das margens fica fora dela: sem lasca do proximo wallpaper)
                    x: win.box.x + (win.vert ? 0 : Geometry.pickerPad); y: win.box.y + (win.vert ? Geometry.pickerPad : 0)
                    width: win.box.width - (win.vert ? 0 : 2 * Geometry.pickerPad); height: win.box.height - (win.vert ? 2 * Geometry.pickerPad : 0)
                    model: Wallpaper.files
                    focus: true
                    clip: true
                    // carrossel circular: ao passar do ultimo volta ao primeiro (e vice-versa). Os itens correm por uma reta centrada
                    readonly property real span: (win.vert ? height : width)
                    pathItemCount: Math.min(Wallpaper.files.length, Math.ceil(span / win.cellLen) + 2)
                    readonly property real runLen: pathItemCount * win.cellLen
                    path: Path {
                        startX: win.vert ? list.width / 2 : list.width / 2 - list.runLen / 2
                        startY: win.vert ? list.height / 2 - list.runLen / 2 : list.height / 2
                        PathLine {
                            x: win.vert ? list.width / 2 : list.width / 2 + list.runLen / 2
                            y: win.vert ? list.height / 2 + list.runLen / 2 : list.height / 2
                        }
                    }
                    preferredHighlightBegin: 0.5
                    preferredHighlightEnd: 0.5
                    highlightRangeMode: PathView.StrictlyEnforceRange
                    highlightMoveDuration: 280
                    interactive: false          // so a roda do mouse / setas movem
                    function onOpen() { currentIndex = Wallpaper.indexOfCurrent(); positionViewAtIndex(currentIndex, PathView.Center); forceActiveFocus(); syncFocus() }
                    function syncFocus() { Wallpaper.pickerFocus = currentIndex >= 0 && currentIndex < Wallpaper.files.length ? Wallpaper.files[currentIndex].path : "" }
                    Connections {
                        target: root
                        function onAliveChanged() { if (root.alive) list.onOpen(); else Wallpaper.pickerFocus = "" }
                    }
                    Component.onCompleted: if (root.alive) onOpen()
                    onCurrentIndexChanged: if (root.alive) syncFocus()
                    Component.onDestruction: Wallpaper.pickerFocus = ""

                    Keys.onEscapePressed: Settings.wpPickerOpen = false
                    // segurar a tecla: movimento curto por passo (senao cada repeticao reinicia a animacao longa e o carrossel arrasta)
                    function step(d, fast) {
                        highlightMoveDuration = fast ? 70 : 260
                        if (d > 0) incrementCurrentIndex(); else decrementCurrentIndex()
                    }
                    Keys.onLeftPressed: e => step(-1, e.isAutoRepeat)
                    Keys.onUpPressed: e => step(-1, e.isAutoRepeat)
                    Keys.onRightPressed: e => step(1, e.isAutoRepeat)
                    Keys.onDownPressed: e => step(1, e.isAutoRepeat)
                    Keys.onReturnPressed: apply()
                    Keys.onEnterPressed: apply()
                    function apply() {
                        if (currentIndex >= 0 && currentIndex < Wallpaper.files.length) Wallpaper.set(Wallpaper.files[currentIndex].path)
                    }

                    Timer { id: wheelT; interval: 160 }   // rolagem seguida = passos rapidos
                    WheelHandler {
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: e => { list.step((e.angleDelta.y < 0 || e.angleDelta.x < 0) ? 1 : -1, wheelT.running); wheelT.restart() }
                    }

                    delegate: Item {
                        id: card
                        required property int index
                        required property var modelData
                        readonly property bool cur: PathView.isCurrentItem
                        readonly property bool applied: modelData.path === Wallpaper.current
                        width: win.vert ? list.width : win.cellLen
                        height: win.vert ? win.cellLen : list.height

                        Item {
                            id: tile
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: (parent.height - height) / 2
                            width: 240; height: 135
                            property real sel: card.cur ? 1.12 : 0.92
                            Behavior on sel { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            scale: sel
                            transformOrigin: Item.Center
                            // renderiza o cartao com o dobro de resolucao e suavizado: sem serrilhado ao escalar (o selecionado cresce um pouco)
                            layer.enabled: true
                            layer.smooth: true
                            layer.textureSize: Qt.size(width * 2, height * 2)
                            opacity: card.cur ? 1 : 0.7
                            Behavior on opacity { NumberAnimation { duration: 220 } }

                            Image {
                                id: thumb
                                anchors.fill: parent
                                source: "file://" + card.modelData.path
                                sourceSize: Qt.size(480, 270)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: false
                            }
                            Rectangle { id: round; anchors.fill: parent; radius: Settings.wpCardRadius; x: -width - 20; layer.enabled: true; layer.smooth: true; layer.textureSize: Qt.size(width * 2, height * 2) }
                            MultiEffect {
                                anchors.fill: parent
                                source: thumb
                                maskEnabled: true
                                maskSource: round
                            }
                            Rectangle {   // contorno do selecionado / do aplicado
                                anchors.fill: parent
                                radius: Settings.wpCardRadius
                                color: "transparent"
                                border.width: card.applied && !card.cur ? 2 : 0
                                border.color: Theme.text
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { list.currentIndex = card.index; Wallpaper.set(card.modelData.path) }
                            }
                        }
                    }
                }

                Text {
                    visible: Wallpaper.files.length === 0
                    x: win.box.x; y: win.box.y + win.box.height / 2 - height / 2; width: win.box.width
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.muted; font.pixelSize: 14
                    text: "Nenhuma imagem em " + Wallpaper.dir
                }
                }
            }
        }
    }
}
