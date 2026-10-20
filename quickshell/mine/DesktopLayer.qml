// Area de trabalho: uma camada acima do wallpaper e abaixo das janelas (so na tela principal), com os widgets (DeskView),
// o menu de clique direito (DeskMenu: adicionar widget no ponto clicado, editar, wallpaper, presets...) e, editando,
// a grade, as guias e o inspetor (opcoes do widget escolhido, as mesmas da pagina Widgets).
import Quickshell
import Quickshell.Wayland
import QtQuick

Scope {
    id: root
    property var geo: ({})

    PanelWindow {
        id: win
        // tela dos widgets: a primeira da lista Settings.desktopScreens que existir, senao a principal.
        // (varias telas ao mesmo tempo pediriam uma DeskState.area por tela: fica para depois)
        screen: {
            const want = Settings.list(Settings.desktopScreens)
            for (const n of want) { const sc = Quickshell.screens.find(x => x.name === n); if (sc) return sc }
            return Quickshell.screens[0]
        }
        visible: Settings.desktopOn || Settings.desktopMenu
        anchors { left: true; right: true; top: true; bottom: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: DeskState.peek ? WlrLayer.Top : WlrLayer.Bottom
        WlrLayershell.namespace: "mine-desktop"   // regra do Hyprland: blur atras dos cartoes, sem animacao propria
        // teclado so quando precisa: editando, menu aberto ou um widget com campo de texto (notas, tarefas) sob o mouse ou em uso
        WlrLayershell.keyboardFocus: DeskState.typingHere ? WlrKeyboardFocus.Exclusive : DeskState.editing || DeskMenu.open || DeskState.typing ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        // com o menu ligado, a camada pega a area de trabalho inteira (ela fica abaixo das janelas: so recebe o que
        // cai no fundo); sem menu, so os widgets
        mask: DeskState.editing || Settings.desktopMenu ? null : wmask
        Region { id: wmask }
        Component { id: regC; Region {} }
        property var regs: []
        function rebuildMask() {
            for (const r of regs) r.destroy()
            const out = []
            for (let i = 0; i < view.count; i++) { const it = view.itemAt(i); if (it) out.push(regC.createObject(wmask, { item: it })) }
            regs = out
            wmask.regions = out
        }

        // area livre: a tela menos o espaco reservado pelas barras/moldura, com margem
        readonly property real m: 22
        readonly property var z: root.geo && root.geo.zone ? root.geo.zone : ({})
        readonly property rect area: Qt.rect((z.left ?? 0) + m, (z.top ?? 0) + m,
            width - (z.left ?? 0) - (z.right ?? 0) - 2 * m, height - (z.top ?? 0) - (z.bottom ?? 0) - 2 * m)
        onAreaChanged: DeskState.area = area
        onWidthChanged: DeskState.screenSize = Qt.size(width, height)
        onHeightChanged: DeskState.screenSize = Qt.size(width, height)
        Component.onCompleted: { DeskState.area = area; DeskState.screenSize = Qt.size(width, height) }

        // Delete / Backspace: apaga os widgets selecionados (so editando e sem campo de texto em uso)
        Item {
            anchors.fill: parent
            focus: true
            Keys.onPressed: e => {
                if ((e.key === Qt.Key_Delete || e.key === Qt.Key_Backspace) && DeskState.editing && !DeskState.typing && DeskState.selection.length) {
                    DeskState.removeMany(DeskState.selection.slice()); e.accepted = true
                }
            }
        }

        // fundo: clique direito abre o menu; clique esquerdo fecha menu/inspetor/edicao; editando, arrastar faz a selecao em retangulo
        property rect band: Qt.rect(0, 0, 0, 0)
        property bool banding: false
        function bandSelect(r) {
            const ids = []
            for (let i = 0; i < view.count; i++) {
                const it = view.itemAt(i)
                if (it && !it.dying && it.x < r.x + r.width && it.x + it.width > r.x && it.y < r.y + r.height && it.y + it.height > r.y) ids.push(it.wid)
            }
            DeskState.selected = ""
            DeskState.selection = ids
        }
        MouseArea {
            id: bgArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            property real px: 0
            property real py: 0
            property bool swallow: false
            onPressed: m => { px = m.x; py = m.y; swallow = false }
            onPositionChanged: m => {
                if (!pressed || !DeskState.editing || (m.buttons & Qt.RightButton)) return
                if (!win.banding && Math.abs(m.x - px) + Math.abs(m.y - py) < 8) return
                win.banding = true; swallow = true
                win.band = Qt.rect(Math.min(px, m.x), Math.min(py, m.y), Math.abs(m.x - px), Math.abs(m.y - py))
                win.bandSelect(win.band)
            }
            onReleased: win.banding = false
            onClicked: m => {
                if (swallow) { swallow = false; return }
                if (m.button === Qt.RightButton) { DeskMenu.show(m.x, m.y, ""); return }
                if (DeskMenu.open) { DeskMenu.close(); return }
                if (DeskState.selected !== "" || DeskState.selection.length) { DeskState.selected = ""; DeskState.selection = []; return }
                DeskState.editing = false
            }
        }
        Rectangle {
            visible: win.banding
            x: win.band.x; y: win.band.y; width: win.band.width; height: win.band.height
            radius: 6; color: Theme.tint(0.14); border.width: 1.5; border.color: Theme.accent
        }

        // soltar arquivos no fundo: uma imagem vira wallpaper, o resto vai para a prateleira
        DropArea {
            id: dropA
            anchors.fill: parent
            keys: ["text/uri-list"]
            property var pend: []
            readonly property bool oneImage: pend.length === 1 && /\.(png|jpe?g|webp|bmp|gif)$/i.test(pend[0])
            function pathOf(u) { return decodeURIComponent(String(u).replace(/^file:\/\//, "")) }
            onEntered: drag => { pend = Array.from(drag.urls ?? []).map(u => pathOf(u)) }
            onExited: pend = []
            onDropped: drop => {
                const l = Array.from(drop.urls ?? []).map(u => pathOf(u))
                pend = []
                if (!l.length) return
                if (l.length === 1 && /\.(png|jpe?g|webp|bmp|gif)$/i.test(l[0])) Wallpaper.set(l[0])
                else { DropShelf.add(l); DropShelf.open = true }
                drop.accept()
            }
        }
        Rectangle {
            id: dropTip
            anchors.horizontalCenter: parent.horizontalCenter
            y: win.area.y + win.area.height * 0.42
            opacity: dropA.containsDrag ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 160 } }
            width: dropRow.implicitWidth + 44; height: 52; radius: 26
            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.96)
            border.width: 2; border.color: Theme.accent
            Row {
                id: dropRow
                anchors.centerIn: parent
                spacing: 10
                UiIcon { name: dropA.oneImage ? "wallpaper" : "folder"; size: 20; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                UiText { text: dropA.oneImage ? "Solte para usar como wallpaper" : "Solte para pôr na prateleira"; color: Theme.text; font.pixelSize: 14; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        // grade de pontos (so enquanto um widget e arrastado)
        Canvas {
            id: grid
            anchors.fill: parent
            opacity: Settings.desktopGrid && DeskState.dragging !== "" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 220 } }
            readonly property var deps: [win.area, Theme.text]
            onDepsChanged: requestPaint()
            onPaint: {
                const c = getContext("2d"); c.reset()
                c.fillStyle = Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.16)
                const a = win.area, st = 24
                for (let x = a.x; x <= a.x + a.width; x += st)
                    for (let y = a.y; y <= a.y + a.height; y += st) c.fillRect(x - 1, y - 1, 2, 2)
            }
        }
        property bool guideX: false
        property bool guideY: false
        Rectangle { visible: win.guideX && DeskState.dragging !== ""; x: win.area.x + win.area.width / 2 - 1; y: win.area.y; width: 2; height: win.area.height; color: Theme.accent; opacity: 0.8 }
        Rectangle { visible: win.guideY && DeskState.dragging !== ""; x: win.area.x; y: win.area.y + win.area.height / 2 - 1; width: win.area.width; height: 2; color: Theme.accent; opacity: 0.8 }

        // linhas de alinhamento: ao soltar, as bordas do widget piscam e somem em 2 s
        property rect fr: Qt.rect(0, 0, 0, 0)
        property real fk: 0
        NumberAnimation { id: flashAnim; target: win; property: "fk"; from: 1; to: 0; duration: 2000; easing.type: Easing.OutCubic }
        Repeater {
            model: 4
            delegate: Rectangle {
                required property int index
                readonly property bool vert: index < 2
                visible: win.fk > 0
                opacity: 0.85 * win.fk
                color: Theme.accent
                x: vert ? win.fr.x + (index === 1 ? win.fr.width : 0) - 0.75 : win.area.x
                y: vert ? win.area.y : win.fr.y + (index === 3 ? win.fr.height : 0) - 0.75
                width: vert ? 1.5 : win.area.width
                height: vert ? win.area.height : 1.5
            }
        }
        Rectangle { visible: win.fk > 0 && Math.abs(win.fr.x + win.fr.width / 2 - (win.area.x + win.area.width / 2)) < 12; opacity: 0.85 * win.fk; color: Theme.accent
            x: win.area.x + win.area.width / 2 - 0.75; y: win.area.y; width: 1.5; height: win.area.height }
        Rectangle { visible: win.fk > 0 && Math.abs(win.fr.y + win.fr.height / 2 - (win.area.y + win.area.height / 2)) < 12; opacity: 0.85 * win.fk; color: Theme.accent
            x: win.area.x; y: win.area.y + win.area.height / 2 - 0.75; width: win.area.width; height: 1.5 }

        DeskView {
            id: view
            anchors.fill: parent
            visible: Settings.desktopOn
            area: win.area
            editable: true
            onCountChanged: Qt.callLater(win.rebuildMask)
            onGuides: (gx, gy) => { win.guideX = gx; win.guideY = gy }
            onDropped: r => { if (Settings.desktopSnapLines) { win.fr = r; flashAnim.restart() } }
        }

        // ---- inspetor: opcoes do widget escolhido ----
        Rectangle {
            id: insp
            readonly property var w: { Settings.desktopWidgets; return DeskState.find(DeskState.selected) }
            readonly property var info: w ? DeskState.info(w.type) : null
            readonly property Item target: { for (let i = 0; i < view.count; i++) { const it = view.itemAt(i); if (it && it.wid === DeskState.selected) return it } return null }
            readonly property bool rightHalf: !target || target.x + target.width / 2 < win.width / 2
            visible: opacity > 0
            opacity: DeskState.editing && !!w ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }
            width: 400
            height: Math.min(win.area.height, inspCol.implicitHeight + 32)
            x: rightHalf ? win.area.x + win.area.width - width : win.area.x
            y: win.area.y + (win.area.height - height) / 2
            Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            radius: 20
            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.97)
            border.width: 1; border.color: Theme.border
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onWheel: e => { const f = inspFlick; f.contentY = Math.max(0, Math.min(Math.max(0, f.contentHeight - f.height), f.contentY - e.angleDelta.y)) } }
            Flickable {
                id: inspFlick
                anchors { fill: parent; margins: 16 }
                contentHeight: inspCol.implicitHeight
                clip: true
                interactive: false
                Column {
                    id: inspCol
                    width: inspFlick.width
                    spacing: 14
                    Row {
                        width: parent.width
                        spacing: 10
                        Rectangle { width: 36; height: 36; radius: 11; color: Theme.tint(0.18)
                            UiIcon { anchors.centerIn: parent; name: insp.info ? insp.info.icon : "dashboard"; size: 18; color: Theme.accent } }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 36 - 10 - 34 - 14
                            UiText { text: insp.info ? insp.info.name : ""; color: Theme.text; font.pixelSize: 16; font.weight: Font.Bold }
                            UiText { width: parent.width; elide: Text.ElideRight; text: insp.info ? insp.info.desc : ""; color: Theme.muted; font.pixelSize: 11 }
                        }
                        UiButton { icon: "close"; kind: "ghost"; onClicked: DeskState.selected = "" }
                    }
                    SizePicker {
                        width: parent.width
                        sizes: insp.info ? insp.info.sizes : []
                        cols: insp.w ? insp.w.cols : 1
                        rows: insp.w ? insp.w.rows : 1
                        onPicked: (c, r) => DeskState.setSize(insp.w.id, c, r)
                    }
                    OptionsForm {
                        width: parent.width
                        compact: true
                        sectionIcons: DeskState.secIcons
                        previewType: insp.w ? insp.w.type : ""
                        previewOpts: insp.w ? (insp.w.opts || {}) : ({})
                        previewCols: insp.w ? insp.w.cols : 2
                        previewRows: insp.w ? insp.w.rows : 2
                        schema: insp.w ? DeskState.optionsOf(insp.w.type) : []
                        get: k => insp.w ? DeskState.opt(insp.w, k) : undefined
                        set: (k, v) => DeskState.setOpt(insp.w.id, k, v)
                        isShown: d => insp.w ? DeskState.shown(insp.w, d) : false
                    }
                    Flow {
                        width: parent.width
                        spacing: 6
                        UiButton { icon: "cards"; text: "Duplicar"; kind: "ghost"; onClicked: DeskState.duplicate(insp.w.id) }
                        UiButton { icon: "layers"; text: "Para a frente"; kind: "ghost"; onClicked: DeskState.bringToFront(insp.w.id) }
                        UiButton { icon: "trash"; text: "Remover"; kind: "danger"; onClicked: DeskState.remove(insp.w.id) }
                    }
                }
            }
        }

        // ---- menu de clique direito ----
        Item {
            id: menu
            anchors.fill: parent
            visible: DeskMenu.open
            readonly property var w: DeskMenu.wid !== "" ? DeskState.find(DeskMenu.wid) : null
            // carrossel do topo: o wallpaper atual + 5 da mesma pasta, sorteados cada vez que o menu abre
            property var carList: []
            property var carPool: []      // todas as outras, sorteadas; a roda do mouse desliza a janela de 5 sobre elas
            property int carOff: 0
            function scrollCar(d) {
                const n = carPool.length
                if (n < 1) return
                carOff = ((carOff + d) % n + n) % n
                const cur = Wallpaper.current, out = cur ? [cur] : []
                for (let i = 0; i < Math.min(5, n); i++) out.push(carPool[(carOff + i) % n])
                carList = out
            }
            function buildCar() {
                const cur = Wallpaper.current
                const others = Wallpaper.files.filter(f => f.path !== cur).map(f => f.path)
                for (let i = others.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); const t = others[i]; others[i] = others[j]; others[j] = t }
                carPool = others; carOff = 0
                carList = (cur ? [cur] : []).concat(others.slice(0, 5))
            }
            Connections { target: DeskMenu; function onOpenChanged() { if (DeskMenu.open) menu.buildCar() } }
            readonly property var items: {
                const out = []
                if (!w && menu.carList.length > 1) { out.push({ carousel: true }); out.push({ sep: true }) }
                if (w) {
                    const nm = DeskState.info(w.type).name
                    out.push({ icon: "tune", label: "Opções de " + nm.toLowerCase(), act: () => { DeskState.editing = true; DeskState.selected = w.id } })
                    out.push({ icon: "cards", label: "Duplicar", act: () => DeskState.duplicate(w.id) })
                    out.push({ icon: "trash", label: "Remover", danger: true, act: () => DeskState.remove(w.id) })
                    out.push({ sep: true })
                }
                out.push({ icon: "plus", label: "Adicionar widget", sub: "add" })
                out.push({ icon: "dashboard", label: "Widgets", sub: "widgets" })
                out.push({ icon: DeskState.editing ? "check" : "pencil", label: DeskState.editing ? "Terminar a edição" : "Editar widgets", act: () => { DeskState.editing = !DeskState.editing; DeskState.selected = "" } })
                out.push({ icon: DeskState.locked ? "lockOpen" : "lock", label: DeskState.locked ? "Destravar posições" : "Travar posições", act: () => Settings.desktopLocked = !Settings.desktopLocked })
                out.push({ icon: Settings.desktopOn ? "eyeOff" : "eye", label: Settings.desktopOn ? "Esconder os widgets" : "Mostrar os widgets", act: () => Settings.desktopOn = !Settings.desktopOn })
                out.push({ sep: true })
                out.push({ icon: "palette", label: "Wallpaper e estilo", sub: "wpstyle" })
                out.push({ icon: "wallpaper", label: "Trocar o wallpaper…", act: () => Settings.wpPickerOpen = true })
                out.push({ icon: "next", label: "Próximo wallpaper", act: () => Wallpaper.step(1) })
                out.push({ icon: "folder", label: "Prateleira de arquivos" + (DropShelf.files.length ? " (" + DropShelf.files.length + ")" : ""), act: () => DropShelf.open = true })
                out.push({ icon: "layers", label: "Visuais e layouts", sub: "presets" })
                out.push({ sep: true })
                out.push({ icon: "cog", label: "Configurações dos widgets", act: () => { Settings.settingsPage = "desktop"; Settings.settingsOpen = true } })
                return out
            }
            readonly property var subItems: DeskMenu.sub === "add"
                ? DeskState.groups.reduce((acc, g) => { const cs = DeskState.catalog.filter(c => c.group === g.id && Settings.list(Settings.desktopMenuHidden).indexOf(c.type) < 0)
                    return cs.length ? acc.concat([{ head: g.label }], cs.map(c => ({ icon: c.icon, label: c.name, act: () => {
                    Settings.desktopOn = true
                    const a = win.area, pw = DeskState.px(c.sizes[0][0]), ph = DeskState.px(c.sizes[0][1])
                    DeskState.add(c.type, { fx: Math.max(0, Math.min(1, (DeskMenu.x - pw / 2 - a.x) / Math.max(1, a.width - pw))), fy: Math.max(0, Math.min(1, (DeskMenu.y - ph / 2 - a.y) / Math.max(1, a.height - ph))) })
                } }))) : acc }, [])
                : DeskMenu.sub === "widgets" ? [
                    { icon: Settings.desktopLocked ? "lock" : "lockOpen", label: "Travar posições", checked: Settings.desktopLocked, keep: true, act: () => Settings.desktopLocked = !Settings.desktopLocked },
                    { icon: "cursorMove", label: "Arrastar sem editar", checked: Settings.desktopAlwaysDrag, keep: true, act: () => Settings.desktopAlwaysDrag = !Settings.desktopAlwaysDrag },
                    { icon: "layers", label: "Sombra", checked: Settings.desktopShadow, keep: true, act: () => Settings.desktopShadow = !Settings.desktopShadow },
                    { icon: "blur", label: "Desfoque atrás", checked: Settings.desktopBlur, keep: true, act: () => Settings.desktopBlur = !Settings.desktopBlur },
                    { sep: true }, { head: "Ligar ou desligar" }].concat(
                    DeskState.catalog.filter(c => Settings.list(Settings.desktopMenuHidden).indexOf(c.type) < 0).map(c => ({ icon: c.icon, label: c.name, checked: DeskState.hasType(c.type), keep: true, act: () => { Settings.desktopOn = true; DeskState.toggleType(c.type) } })))
                : DeskMenu.sub === "presets" ? (Looks.undoData ? [{ icon: "restore", label: "Desfazer (" + Looks.undoName + ")", act: () => Looks.undo() }] : []).concat(
                    DeskState.all.map(p => ({ icon: p.builtin ? (p.icon || "dashboard") : "layers", label: p.name, checked: DeskState.lastApplied === p.name, act: () => DeskState.apply(p.name) }))) : []
            component MenuList: Rectangle {
                id: ml
                property var entries: []
                property bool isSub: false
                property real w0: 250
                width: w0
                height: mcol.implicitHeight + 12
                radius: 14
                color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.98)
                border.width: 1; border.color: Theme.border
                scale: 0.94 + 0.06 * k; opacity: k
                property real k: 0
                Component.onCompleted: k = 1
                Behavior on k { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
                Column {
                    id: mcol
                    x: 6; y: 6; width: parent.width - 12
                    Repeater {
                        model: ml.entries
                        delegate: Item {
                            required property var modelData
                            width: mcol.width
                            height: modelData.sep ? 9 : modelData.head ? 26 : modelData.carousel ? 88 : 32
                            Item {
                                id: car
                                visible: !!modelData.carousel
                                anchors.fill: parent
                                property int hov: -1
                                readonly property int n: menu.carList.length
                                Repeater {
                                    model: car.visible ? menu.carList : []
                                    delegate: Item {
                                        id: ci
                                        required property string modelData
                                        required property int index
                                        readonly property real wt: car.n < 2 ? 1 : (car.hov >= 0 ? (ci.index === car.hov ? 0.52 : 0.48 / (car.n - 1)) : (ci.index === 0 ? 0.4 : 0.6 / (car.n - 1)))
                                        readonly property real before: { let a = 0; for (let k = 0; k < ci.index; k++) a += (car.n < 2 ? 1 : (car.hov >= 0 ? (k === car.hov ? 0.52 : 0.48 / (car.n - 1)) : (k === 0 ? 0.4 : 0.6 / (car.n - 1)))); return a }
                                        readonly property real tot: car.width - 4 - (car.n - 1) * 4
                                        x: 2 + before * tot + ci.index * 4
                                        y: 4; width: wt * tot; height: car.height - 8
                                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                        RoundImage {
                                            anchors.fill: parent
                                            radius: 10
                                            sourceSize: Qt.size(240, 160)
                                            source: Wallpaper.isVideo(ci.modelData) ? Wallpaper.stillUrl(ci.modelData) : "file://" + ci.modelData
                                        }
                                        Rectangle { anchors.fill: parent; radius: 10; color: "transparent"; border.width: ci.index === 0 ? 2 : 0; border.color: Theme.accent }
                                        MouseArea {
                                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onEntered: car.hov = ci.index
                                            onExited: if (car.hov === ci.index) car.hov = -1
                                            onClicked: { Wallpaper.set(ci.modelData); DeskMenu.close() }
                                        }
                                    }
                                }
                            }
                            Rectangle { visible: !!modelData.sep; anchors.centerIn: parent; width: parent.width - 16; height: 1; color: Theme.border }
                            UiText { visible: !!modelData.head; x: 10; anchors.verticalCenter: parent.verticalCenter; text: modelData.head ?? ""; color: Theme.muted; font.pixelSize: 11; font.weight: Font.DemiBold }
                            Rectangle {
                                visible: !modelData.sep && !modelData.head && !modelData.carousel
                                anchors.fill: parent; radius: 9
                                color: im.containsMouse || (modelData.sub && DeskMenu.sub === modelData.sub) ? (modelData.danger ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.18) : Theme.cardHi) : "transparent"
                                UiIcon { id: mi; x: 10; anchors.verticalCenter: parent.verticalCenter; name: modelData.icon ?? ""; size: 16; color: modelData.danger ? Theme.danger : (modelData.checked ? Theme.accent : Theme.muted) }
                                UiText { anchors { left: mi.right; leftMargin: 10; verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: 24 } elide: Text.ElideRight
                                    text: modelData.label ?? ""; color: modelData.danger ? Theme.danger : Theme.text; font.pixelSize: 13; font.weight: modelData.checked ? Font.DemiBold : Font.Normal }
                                UiIcon { visible: !!modelData.sub || !!modelData.checked; anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter } name: modelData.sub ? "chevRight" : "check"; size: 14; color: Theme.muted }
                                MouseArea {
                                    id: im; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onEntered: if (!ml.isSub && modelData.sub) DeskMenu.sub = modelData.sub; else if (!ml.isSub) DeskMenu.sub = ""
                                    onClicked: { if (modelData.sub) { DeskMenu.sub = modelData.sub; return } if (!modelData.keep) DeskMenu.close(); modelData.act() }
                                }
                            }
                        }
                    }
                }
            }
            MenuList {
                id: main
                w0: 290
                entries: menu.items
                x: Math.min(DeskMenu.x, win.width - width - 8)
                y: Math.min(DeskMenu.y, win.height - height - 8)
            }
            readonly property bool wide: DeskMenu.sub === "wpstyle"
            readonly property real subW: wide ? 304 : 250
            readonly property bool toLeft: main.x + main.width + subW + 4 > win.width
            Loader {
                active: DeskMenu.sub !== "" && !menu.wide
                x: menu.toLeft ? main.x - menu.subW - 4 : main.x + main.width + 4
                sourceComponent: MenuList {
                    isSub: true
                    entries: menu.subItems
                    y: Math.max(8, Math.min(main.y, win.height - height - 8))
                }
            }
            Loader {
                active: menu.wide
                x: menu.toLeft ? main.x - menu.subW - 4 : main.x + main.width + 4
                sourceComponent: Rectangle {
                    id: sp
                    width: 304
                    height: scol.implicitHeight + 24
                    y: Math.max(8, Math.min(main.y, win.height - height - 8))
                    radius: 14
                    color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.98)
                    border.width: 1; border.color: Theme.border
                    scale: 0.94 + 0.06 * k; opacity: k
                    property real k: 0
                    Component.onCompleted: k = 1
                    Behavior on k { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
                    Column {
                        id: scol
                        x: 12; y: 12; width: parent.width - 24
                        spacing: 8
                        UiText { text: "Esquema de cores"; color: Theme.muted; font.pixelSize: 11; font.weight: Font.DemiBold }
                        Flow {
                            width: parent.width
                            spacing: 6
                            Repeater {
                                model: [["wallpaper", "Automático"], ["tonalspot", "Tonal"], ["vibrant", "Vibrante"], ["expressive", "Expressivo"], ["fidelity", "Fiel"], ["content", "Conteúdo"], ["neutral", "Neutro"], ["monochrome", "Mono"], ["rainbow", "Arco-íris"], ["fruitsalad", "Frutas"]]
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool on: Settings.themeVariant === modelData[0]
                                    width: (scol.width - 12) / 3; height: 32
                                    radius: on ? 16 : 9
                                    color: on ? Theme.accent : (vm.containsMouse ? Theme.cardHi : Theme.track)
                                    Behavior on radius { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                    UiText { anchors.centerIn: parent; text: modelData[1]; font.pixelSize: 12; font.weight: parent.on ? Font.Bold : Font.Normal; color: parent.on ? Theme.accentText : Theme.text }
                                    MouseArea { id: vm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.themeVariant = modelData[0] }
                                }
                            }
                        }
                        UiText { text: "Wallpaper"; color: Theme.muted; font.pixelSize: 11; font.weight: Font.DemiBold }
                        UiSeg { fill: true; value: Settings.wpMode; options: [["fill", "Preencher"], ["centered", "Centralizado"], ["collage", "Mosaico"]]; onPicked: v => Settings.wpMode = v }
                        Flickable {
                            visible: Settings.wpMode === "centered"
                            width: parent.width; height: visible ? 80 : 0
                            contentWidth: shapeRow.width; contentHeight: 80
                            clip: true
                            flickableDirection: Flickable.HorizontalFlick
                            boundsBehavior: Flickable.StopAtBounds
                            WheelHandler { onWheel: e => { const f = parent; f.contentX = Math.max(0, Math.min(f.contentWidth - f.width, f.contentX - e.angleDelta.y)) } }
                            ShapePicker { id: shapeRow; width: Shapes.list.length * 80; value: Settings.wpCenterShape; sides: Settings.wpCenterSides; onPicked: v => Settings.wpCenterShape = v }
                        }
                        UiSlider { visible: Settings.wpMode === "centered"; height: visible ? 50 : 0; label: "Tamanho"; from: 20; to: 95; value: Settings.wpCenterSize; suffix: " %"; onMoved: v => Settings.wpCenterSize = Math.round(v) }
                        UiText { text: "Transição"; color: Theme.muted; font.pixelSize: 11; font.weight: Font.DemiBold }
                        Flow {
                            width: parent.width
                            spacing: 5
                            Repeater {
                                model: [["none", "Nenhuma"], ["fade", "Fade"], ["slide", "Deslizar"], ["wipe", "Cortina"], ["circle", "Círculo"], ["zoom", "Zoom"], ["dissolve", "Dissolver"], ["pixelate", "Pixelar"], ["ripple", "Ondas"], ["blinds", "Persianas"], ["swirl", "Redemoinho"], ["random", "Aleatória"]]
                                delegate: UiButton {
                                    required property var modelData
                                    text: modelData[1]
                                    checked: Settings.wpTransition === modelData[0]
                                    onClicked: Settings.wpTransition = modelData[0]
                                }
                            }
                        }
                    }
                }
            }
            Keys.onEscapePressed: DeskMenu.close()
        }

        // aviso do modo de edicao
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: win.area.y + (DeskState.editing ? 0 : -60)
            Behavior on y { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
            opacity: DeskState.editing ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            width: tip.implicitWidth + 300; height: 44; radius: 22
            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.94)
            border.width: 1; border.color: Theme.border
            Row {
                anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                spacing: 10
                UiIcon { name: "dashboard"; size: 18; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                UiText { id: tip; text: DeskState.locked ? "Posições travadas: clique num widget para as opções." : "Arraste para mover, clique para as opções."; color: Theme.text; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
            }
            Row {
                anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                spacing: 6
                UiButton { icon: "plus"; text: "Adicionar"; kind: "ghost"; onClicked: DeskMenu.show(parent.mapToItem(win.contentItem, 0, 40).x, parent.mapToItem(win.contentItem, 0, 40).y, "") }
                UiButton { icon: DeskState.locked ? "lockOpen" : "lock"; kind: "ghost"; onClicked: Settings.desktopLocked = !Settings.desktopLocked }
                UiButton { icon: "check"; text: "Pronto"; kind: "accent"; onClicked: { DeskState.editing = false; DeskState.selected = "" } }
            }
        }
    }
}
