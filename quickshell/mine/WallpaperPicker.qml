// Seletor de wallpaper: um painel sai da borda da tela (acoplado a moldura, ou flutuante) com as imagens enfileiradas.
// Role o mouse (ou use as setas, Home/End, R = aleatorio) para navegar; Enter, Espaco ou clique aplica; Esc fecha.
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
    property string src: "local"           // fonte do seletor: local (pasta) | wh (Wallhaven)

    IpcHandler {
        target: "wallpaper"
        function pick(): void { if (!Settings.wpPickerOpen && Settings.wpSystemDialog) { Pick.image("Escolha o wallpaper", p => Wallpaper.set(p)); return }
            if (!Settings.wpPickerOpen) { Settings.launcherOpen = false; Settings.homeOpen = false; Settings.leftOpen = false } Settings.wpPickerOpen = !Settings.wpPickerOpen }
        function close(): void { Settings.wpPickerOpen = false }
        function next(): void { Wallpaper.step(1) }
        function prev(): void { Wallpaper.step(-1) }
        function random(): void { Wallpaper.random() }
        function peek(): void { Wallpaper.peek = !Wallpaper.peek }   // traz o wallpaper para a frente (conferir transicoes)
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
    Timer { id: closeTimer; interval: Motion.durationOf("picker", true) + 80; onTriggered: root.alive = false }

    // a janela fica sempre carregada (so escondida quando fechada): as miniaturas continuam decodificadas na memoria
    LazyLoader {
        active: true

        PanelWindow {
            id: win
            // sempre mapeada (esconder com visible recriava a janela a cada abertura e travava 1-2 quadros); fechada: nada desenhado
            Component.onCompleted: contentItem.visible = Qt.binding(() => root.alive || root.warm)   // 'warm': carrega as miniaturas ao iniciar
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
            readonly property bool gridMode: Settings.wpLayout === "grid"
            readonly property var items: root.src === "wh" ? Wallhaven.results : Wallpaper.entries
            function focusView() { if (gridMode) gv.forceActiveFocus(); else list.forceActiveFocus() }
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
            readonly property real vis: docked ? Math.max(0, e + (fullDepth - e) * pp) : 0
            readonly property rect clipR: !docked || !pk ? Qt.rect(0, 0, 0, 0)
                : side === "top" ? Qt.rect(pk.rect.x, 0, pk.rect.w, vis)
                : side === "bottom" ? Qt.rect(pk.rect.x, height - vis, pk.rect.w, vis)
                : side === "left" ? Qt.rect(0, pk.rect.y, vis, pk.rect.h)
                : Qt.rect(width - vis, pk.rect.y, vis, pk.rect.h)
            // quanto o conteudo ainda esta deslocado em direcao a borda
            readonly property real lag: docked ? fullDepth - vis : (1 - pp) * (e + Settings.wpPickerGap + contentDepth + 40)

            // clique fora fecha
            MouseArea { anchors.fill: parent; onClicked: Settings.wpPickerOpen = false }
            // soltar uma imagem (ou video) vinda do gerenciador de arquivos: vira o wallpaper
            DropArea {
                anchors.fill: parent
                keys: ["text/uri-list"]
                onDropped: d => {
                    if (!d.hasUrls) return
                    const p = decodeURIComponent(d.urls[0].toString().replace(/^file:\/\//, ""))
                    if (/\.(png|jpe?g|webp|bmp|mp4|webm|mkv|mov|m4v)$/i.test(p)) { Wallpaper.set(p); d.acceptProposedAction() }
                }
            }

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
                    opacity: Math.max(0, Math.min(1, win.pp * 4))

                // ---- barra de ferramentas: fonte, pastas, ordem, tema, busca ----
                Row {
                    id: tools
                    x: win.box.x + Geometry.pickerPad; y: win.box.y + 4
                    width: win.box.width - 2 * Geometry.pickerPad
                    height: 34
                    spacing: 4
                    readonly property bool wh: root.src === "wh"
                    readonly property int nBtn: wh ? 5 : 6
                    UiButton { icon: "web"; kind: "ghost"; checked: tools.wh; onClicked: root.src = tools.wh ? "local" : "wh" }
                    UiButton { icon: win.gridMode ? "view_column" : "view_grid"; kind: "ghost"; onClicked: Settings.wpLayout = win.gridMode ? "carousel" : "grid" }
                    UiButton { visible: !tools.wh; icon: "arrowUp"; kind: "ghost"; onClicked: Wallpaper.up() }
                    UiButton { visible: !tools.wh; icon: "folderHome"; kind: "ghost"; onClicked: Wallpaper.reset() }
                    UiButton {
                        visible: !tools.wh; icon: Settings.wpSort === "name" ? "sortName" : (Settings.wpSort === "time" ? "sortTime" : (Settings.wpSort === "manual" ? "swap_horizontal" : "disk")); kind: "ghost"; checked: Settings.wpSortRev
                        onClicked: {
                            const o = ["name", "time", "size", "manual"]
                            if (!Settings.wpSortRev) Settings.wpSortRev = true
                            else { Settings.wpSortRev = false; Settings.wpSort = o[(o.indexOf(Settings.wpSort) + 1) % 4] }
                        }
                    }
                    UiButton { visible: tools.wh; icon: "sortName"; kind: "ghost"; onClicked: { Wallhaven.nextSort(); Wallhaven.newSearch() } }
                    UiButton { visible: tools.wh; icon: "arrowLeft"; kind: "ghost"; enabled: Wallhaven.page > 1; onClicked: Wallhaven.go(-1) }
                    UiButton { visible: tools.wh; icon: "arrowRight"; kind: "ghost"; enabled: Wallhaven.page < Wallhaven.lastPage; onClicked: Wallhaven.go(1) }
                    UiButton { visible: !tools.wh; icon: Settings.themeModeEff === "dark" ? "night" : "sun"; kind: "ghost"; onClicked: Settings.themeMode = Settings.themeModeEff === "dark" ? "light" : "dark" }
                    UiField {
                        id: sfield
                        width: Math.max(70, tools.width - tools.nBtn * 38 - 4)
                        placeholderText: tools.wh ? "Buscar no Wallhaven…" : "Filtrar ( / )"
                        text: tools.wh ? Wallhaven.query : Wallpaper.filter
                        onTextEdited: if (!tools.wh) Wallpaper.filter = text
                        onAccepted: { if (tools.wh) { Wallhaven.query = text; Wallhaven.newSearch() } win.focusView() }
                        Keys.onEscapePressed: { if (!tools.wh) { Wallpaper.filter = ""; text = "" } win.focusView() }
                    }
                }

                // ---- fila de imagens ----
                PathView {
                    id: list
                    // a lista mostra exatamente N cartoes (a folga das margens fica fora dela: sem lasca do proximo wallpaper)
                    x: win.box.x + (win.vert ? 0 : Geometry.pickerPad); y: win.box.y + 40 + (win.vert ? Geometry.pickerPad : 0)
                    width: win.box.width - (win.vert ? 0 : 2 * Geometry.pickerPad); height: win.box.height - 40 - (win.vert ? 2 * Geometry.pickerPad : 0)
                    model: win.gridMode ? [] : win.items
                    visible: !win.gridMode
                    focus: !win.gridMode
                    clip: true
                    // carrossel circular: ao passar do ultimo volta ao primeiro (e vice-versa). Os itens correm por uma reta centrada
                    readonly property real span: (win.vert ? height : width)
                    pathItemCount: Math.min(list.count, Math.ceil(span / win.cellLen) + 2)
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
                    function onOpen() { const i = Math.max(0, Wallpaper.entries.findIndex(f => f.path === Wallpaper.current)); currentIndex = i; gv.currentIndex = i; positionViewAtIndex(i, PathView.Center); gv.positionViewAtIndex(i, GridView.Center); win.focusView(); Qt.callLater(win.focusView); syncFocus() }
                    function syncFocus() { const ci = win.gridMode ? gv.currentIndex : currentIndex; const it = root.src === "local" && ci >= 0 && ci < win.items.length ? Wallpaper.entries[ci] : null; Wallpaper.pickerFocus = it && !it.dir ? it.path : "" }
                    Connections { target: Settings; function onWpLayoutChanged() { const i = win.gridMode ? list.currentIndex : gv.currentIndex; if (win.gridMode) gv.currentIndex = i; else list.currentIndex = i; Qt.callLater(win.focusView); Qt.callLater(list.syncFocus) } }
                    Connections {
                        target: root
                        function onAliveChanged() { if (root.alive) list.onOpen(); else Wallpaper.pickerFocus = "" }
                    }
                    Component.onCompleted: if (root.alive) onOpen()
                    onCurrentIndexChanged: if (root.alive) syncFocus()
                    Component.onDestruction: Wallpaper.pickerFocus = ""

                    Keys.onEscapePressed: Settings.wpPickerOpen = false
                    Connections { target: Wallpaper; function onEntriesChanged() {
                        if (!root.alive || root.src !== "local") return
                        let i = 0
                        if (Wallpaper.reorderTo >= 0) { i = Wallpaper.reorderTo + Wallpaper.dirs.length; Wallpaper.reorderTo = -1 }
                        list.currentIndex = i; gv.currentIndex = i; list.syncFocus()
                    } }
                    Connections { target: root; function onSrcChanged() { list.currentIndex = 0; gv.currentIndex = 0; list.syncFocus() } }
                    // segurar a tecla: movimento curto por passo (senao cada repeticao reinicia a animacao longa e o carrossel arrasta)
                    function step(d, fast) {
                        highlightMoveDuration = fast ? 70 : 260
                        if (d > 0) incrementCurrentIndex(); else decrementCurrentIndex()
                    }
                    // Alt+setas: move o wallpaper em foco (ordem manual)
                    function shift(d, e) { if (!(e.modifiers & Qt.AltModifier)) return false; const it = Wallpaper.entries[currentIndex]; if (it && !it.dir && Settings.wpSort === "manual") Wallpaper.moveFile(it.path, d); return true }
                    Keys.onLeftPressed: e => { if (!shift(-1, e)) step(-1, e.isAutoRepeat) }
                    Keys.onUpPressed: e => step(-1, e.isAutoRepeat)
                    Keys.onRightPressed: e => { if (!shift(1, e)) step(1, e.isAutoRepeat) }
                    Keys.onDownPressed: e => step(1, e.isAutoRepeat)
                    Keys.onReturnPressed: apply()
                    Keys.onEnterPressed: apply()
                    Keys.onSpacePressed: apply()
                    Keys.onPressed: e => {
                        if (e.key === Qt.Key_Home) { highlightMoveDuration = 260; currentIndex = 0 }
                        else if (e.key === Qt.Key_End) { highlightMoveDuration = 260; currentIndex = count - 1 }
                        else if (e.key === Qt.Key_Slash || e.key === Qt.Key_F) { sfield.forceActiveFocus(); sfield.selectAll() }
                        else if (e.key === Qt.Key_Backspace && root.src === "local") Wallpaper.up()
                        else if (e.key === Qt.Key_Delete && root.src === "local") { const it = Wallpaper.entries[currentIndex]; if (it && !it.dir) Wallpaper.delPath = it.path }
                        else if (e.key === Qt.Key_R && count > 1) {   // R: vai para um aleatorio (Enter aplica)
                            let n = currentIndex
                            while (n === currentIndex) n = Math.floor(Math.random() * count)
                            highlightMoveDuration = 380; currentIndex = n
                        } else return
                        e.accepted = true
                    }
                    function apply() { if (currentIndex >= 0 && currentIndex < count) choose(root.src === "wh" ? Wallhaven.results[currentIndex] : Wallpaper.entries[currentIndex]) }
                    // dir: entra na pasta; Wallhaven: baixa e aplica; senao aplica (e fecha, se "fechar ao escolher")
                    function choose(it) {
                        if (!it) return
                        if (root.src === "wh") Wallhaven.take(it, true)
                        else if (it.dir) Wallpaper.enter(it.path)
                        else { Wallpaper.set(it.path); if (Settings.wpCloseAfter) Settings.wpPickerOpen = false }
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
                        readonly property bool isDir: !!modelData.dir
                        readonly property bool isWh: root.src === "wh"
                        readonly property bool applied: !isWh && !isDir && modelData.path === Wallpaper.current
                        width: win.vert ? list.width : win.cellLen
                        height: win.vert ? win.cellLen : list.height

                        Item {
                            id: tile
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: (parent.height - height) / 2
                            width: 240; height: 135
                            property real sel: card.cur ? 1.12 : (cm.containsMouse ? 0.97 : 0.92)
                            Behavior on sel { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            scale: sel
                            transformOrigin: Item.Center
                            // renderiza o cartao com o dobro de resolucao e suavizado: sem serrilhado ao escalar (o selecionado cresce um pouco)
                            layer.enabled: true
                            layer.smooth: true
                            layer.textureSize: Qt.size(width * 2, height * 2)
                            opacity: card.cur ? 1 : (cm.containsMouse ? 0.92 : 0.7)
                            Behavior on opacity { NumberAnimation { duration: 220 } }

                            Image {
                                id: thumb
                                anchors.fill: parent
                                source: card.isDir ? "" : (card.isWh ? card.modelData.thumb : "file://" + card.modelData.path)
                                sourceSize: Qt.size(480, 270)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: false
                            }
                            Rectangle {   // pasta: cartao com icone
                                visible: card.isDir
                                anchors.fill: parent; radius: Settings.wpCardRadius; color: Theme.card
                                border.width: 1; border.color: Theme.border
                                UiIcon { anchors.centerIn: parent; anchors.verticalCenterOffset: -8; name: "folder"; size: 48; color: Theme.accent }
                            }
                            Rectangle { id: round; anchors.fill: parent; radius: Settings.wpCardRadius; x: -width - 20; layer.enabled: true; layer.smooth: true; layer.textureSize: Qt.size(width * 2, height * 2) }
                            MultiEffect {
                                anchors.fill: parent
                                source: thumb
                                maskEnabled: true
                                maskSource: round
                            }
                            // nome e posicao do wallpaper em foco, sobre um degrade na parte de baixo do cartao
                            Item {
                                anchors.fill: parent
                                opacity: card.cur ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                                Rectangle {
                                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                    height: 44
                                    bottomLeftRadius: Settings.wpCardRadius; bottomRightRadius: Settings.wpCardRadius
                                    gradient: Gradient {
                                        GradientStop { position: 0; color: "transparent" }
                                        GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.62) }
                                    }
                                }
                                UiText {
                                    anchors { left: parent.left; leftMargin: 10; right: count.left; rightMargin: 6; bottom: parent.bottom; bottomMargin: 7 }
                                    text: card.isWh ? card.modelData.res + (Wallhaven.downloading === card.modelData.id ? "  ·  baixando…" : "") : (card.isDir ? card.modelData.name : card.modelData.path.split("/").pop().replace(/\.[^.]+$/, "").replace(/[-_]+/g, " "))
                                    color: "white"; font.pixelSize: 11; font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                UiText {
                                    id: count
                                    anchors { right: parent.right; rightMargin: 10; bottom: parent.bottom; bottomMargin: 7 }
                                    text: (card.index + 1) + " / " + win.items.length
                                    color: Qt.rgba(1, 1, 1, 0.75); font.pixelSize: 10
                                }
                            }
                            // marca do wallpaper aplicado
                            Rectangle {
                                visible: card.applied
                                anchors { right: parent.right; top: parent.top; margins: 7 }
                                width: 20; height: 20; radius: 10
                                color: Theme.accent
                                UiIcon { anchors.centerIn: parent; name: "check"; size: 13; color: Theme.accentText }
                            }
                            MouseArea {
                                id: cm
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { list.currentIndex = card.index; list.choose(card.modelData) }
                            }
                            WpActions { anchors.fill: parent; visible: !card.isWh && !card.isDir; path: card.modelData.path || ""; shown: card.cur || cm.containsMouse; radius: Settings.wpCardRadius }
                        }
                    }
                }


                // ---- grade (Settings.wpLayout = grid): linhas fixas, rolagem pelo lado longo ----
                GridView {
                    id: gv
                    visible: win.gridMode
                    x: list.x; y: list.y; width: list.width; height: list.height
                    model: win.gridMode ? win.items : []
                    clip: true
                    flow: win.vert ? GridView.FlowLeftToRight : GridView.FlowTopToBottom
                    cellWidth: win.vert ? width / 2 : height / 2 * 16 / 9
                    cellHeight: win.vert ? width / 2 * 9 / 16 : height / 2
                    boundsBehavior: Flickable.StopAtBounds
                    keyNavigationEnabled: true
                    highlightMoveDuration: 120
                    onCurrentIndexChanged: if (root.alive && win.gridMode) list.syncFocus()
                    Keys.onEscapePressed: Settings.wpPickerOpen = false
                    Keys.onReturnPressed: list.choose(win.items[currentIndex])
                    Keys.onEnterPressed: list.choose(win.items[currentIndex])
                    Keys.onSpacePressed: list.choose(win.items[currentIndex])
                    Keys.onPressed: e => {
                        const it = win.items[currentIndex]
                        if ((e.modifiers & Qt.AltModifier) && (e.key === Qt.Key_Left || e.key === Qt.Key_Right || e.key === Qt.Key_Up || e.key === Qt.Key_Down)) {
                            if (it && !it.dir && root.src === "local" && Settings.wpSort === "manual") Wallpaper.moveFile(it.path, (e.key === Qt.Key_Left || e.key === Qt.Key_Up) ? -1 : 1)
                        }
                        else if (e.key === Qt.Key_Slash || e.key === Qt.Key_F) { sfield.forceActiveFocus(); sfield.selectAll() }
                        else if (e.key === Qt.Key_Backspace && root.src === "local") Wallpaper.up()
                        else if (e.key === Qt.Key_Delete && root.src === "local") { if (it && !it.dir) Wallpaper.delPath = it.path }
                        else if (e.key === Qt.Key_R && count > 1) currentIndex = Math.floor(Math.random() * count)
                        else return
                        e.accepted = true
                    }
                    WheelHandler {
                        enabled: !win.vert
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: e => { gv.contentX = Math.max(0, Math.min(Math.max(0, gv.contentWidth - gv.width), gv.contentX - (e.angleDelta.y + e.angleDelta.x) * 0.8)) }
                    }
                    delegate: Item {
                        id: gcell
                        required property int index
                        required property var modelData
                        readonly property bool cur: GridView.isCurrentItem
                        readonly property bool isDir: !!modelData.dir
                        readonly property bool isWh: root.src === "wh"
                        width: gv.cellWidth; height: gv.cellHeight
                        Item {
                            anchors.fill: parent; anchors.margins: 5
                            Rectangle {
                                visible: gcell.isDir
                                anchors.fill: parent; radius: Settings.wpCardRadius; color: Theme.card; border.width: 1; border.color: Theme.border
                                UiIcon { anchors.centerIn: parent; anchors.verticalCenterOffset: -6; name: "folder"; size: 36; color: Theme.accent }
                                UiText { anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 6 } horizontalAlignment: Text.AlignHCenter; text: gcell.modelData.name || ""; color: Theme.muted; font.pixelSize: 10; elide: Text.ElideRight }
                            }
                            RoundImage {
                                visible: !gcell.isDir
                                anchors.fill: parent; radius: Settings.wpCardRadius
                                source: gcell.isDir ? "" : (gcell.isWh ? gcell.modelData.thumb : "file://" + gcell.modelData.path)
                                sourceSize: Qt.size(320, 180)
                                opacity: gcell.cur ? 1 : (gm.containsMouse ? 0.95 : 0.72)
                            }
                            Rectangle { anchors.fill: parent; radius: Settings.wpCardRadius; color: "transparent"; border.width: gcell.cur ? 2 : 0; border.color: Theme.accent }
                            Rectangle {
                                visible: !gcell.isWh && !gcell.isDir && gcell.modelData.path === Wallpaper.current
                                anchors { right: parent.right; top: parent.top; margins: 6 }
                                width: 18; height: 18; radius: 9; color: Theme.accent
                                UiIcon { anchors.centerIn: parent; name: "check"; size: 12; color: Theme.accentText }
                            }
                            MouseArea {
                                id: gm
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { gv.currentIndex = gcell.index; list.choose(gcell.modelData) }
                            }
                            WpActions { anchors.fill: parent; visible: !gcell.isWh && !gcell.isDir; path: gcell.modelData.path || ""; shown: gcell.cur || gm.containsMouse; radius: Settings.wpCardRadius }
                        }
                    }
                }

                UiText {
                    visible: win.items.length === 0
                    x: win.box.x; y: win.box.y + 40 + (win.box.height - 40) / 2 - height / 2; width: win.box.width
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.muted; font.pixelSize: 14
                    text: root.src === "wh" ? (Wallhaven.loading ? "Buscando…" : (Wallhaven.status || "Digite algo e Enter para buscar no Wallhaven")) : (Wallpaper.filter !== "" ? "Nada com esse nome" : "Nenhuma imagem em " + Wallpaper.viewDir)
                }
                }
            }
        }
    }
}
