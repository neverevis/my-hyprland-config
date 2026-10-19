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
        screen: Quickshell.screens[0]
        visible: Settings.desktopOn || Settings.desktopMenu
        anchors { left: true; right: true; top: true; bottom: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: DeskState.peek ? WlrLayer.Top : WlrLayer.Bottom
        WlrLayershell.namespace: "mine-desktop"   // regra do Hyprland: blur atras dos cartoes, sem animacao propria
        WlrLayershell.keyboardFocus: DeskState.editing || DeskMenu.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
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

        // fundo: clique direito abre o menu; clique esquerdo fecha menu/inspetor/edicao
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: m => {
                if (m.button === Qt.RightButton) { DeskMenu.show(m.x, m.y, ""); return }
                if (DeskMenu.open) { DeskMenu.close(); return }
                if (DeskState.selected !== "") { DeskState.selected = ""; return }
                DeskState.editing = false
            }
        }

        // grade de pontos (so editando)
        Canvas {
            id: grid
            anchors.fill: parent
            opacity: DeskState.editing && Settings.desktopSnap ? 1 : 0
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

        DeskView {
            id: view
            anchors.fill: parent
            visible: Settings.desktopOn
            area: win.area
            editable: true
            onCountChanged: Qt.callLater(win.rebuildMask)
            onGuides: (gx, gy) => { win.guideX = gx; win.guideY = gy }
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
            width: 380
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
                            width: parent.width - 36 - 10 - 34
                            UiText { text: insp.info ? insp.info.name : ""; color: Theme.text; font.pixelSize: 16; font.weight: Font.Bold }
                            UiText { width: parent.width; elide: Text.ElideRight; text: insp.info ? insp.info.desc : ""; color: Theme.muted; font.pixelSize: 11 }
                        }
                        UiButton { icon: "close"; kind: "ghost"; onClicked: DeskState.selected = "" }
                    }
                    // tamanho
                    Column {
                        width: parent.width
                        spacing: 6
                        UiText { text: "Tamanho"; color: Theme.text; font.pixelSize: 13 }
                        Flow {
                            width: parent.width
                            spacing: 4
                            Repeater {
                                model: insp.info ? insp.info.sizes : []
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool on: insp.w && insp.w.cols === modelData[0] && insp.w.rows === modelData[1]
                                    height: 28; width: 46; radius: 8
                                    color: on ? Theme.accent : (sm.containsMouse ? Theme.cardHi : Theme.track)
                                    border.width: 1; border.color: on ? Theme.accent : Theme.border
                                    UiText { anchors.centerIn: parent; text: modelData[0] + "×" + modelData[1]; color: parent.on ? Theme.accentText : Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold }
                                    MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: DeskState.setSize(insp.w.id, modelData[0], modelData[1]) }
                                }
                            }
                            // tamanho livre: colunas e linhas
                            Repeater {
                                model: [["cols", "Larg."], ["rows", "Alt."]]
                                delegate: Row {
                                    required property var modelData
                                    spacing: 2
                                    UiText { text: modelData[1]; color: Theme.muted; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter; rightPadding: 2; leftPadding: 6 }
                                    Repeater {
                                        model: [-1, 1]
                                        delegate: Rectangle {
                                            required property var modelData
                                            readonly property string k: parent.modelData[0]
                                            width: 24; height: 28; radius: 7
                                            color: pm.containsMouse ? Theme.cardHi : Theme.track; border.width: 1; border.color: Theme.border
                                            UiIcon { anchors.centerIn: parent; name: parent.modelData < 0 ? "minus" : "plus"; size: 12; color: Theme.text }
                                            MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: { const w = insp.w; if (parent.k === "cols") DeskState.setSize(w.id, w.cols + parent.modelData, w.rows); else DeskState.setSize(w.id, w.cols, w.rows + parent.modelData) } }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    OptionsForm {
                        width: parent.width
                        compact: true
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
            readonly property var items: {
                const out = []
                if (w) {
                    const nm = DeskState.info(w.type).name
                    out.push({ icon: "tune", label: "Opções de " + nm.toLowerCase(), act: () => { DeskState.editing = true; DeskState.selected = w.id } })
                    out.push({ icon: "cards", label: "Duplicar", act: () => DeskState.duplicate(w.id) })
                    out.push({ icon: "trash", label: "Remover", danger: true, act: () => DeskState.remove(w.id) })
                    out.push({ sep: true })
                }
                out.push({ icon: "plus", label: "Adicionar widget", sub: "add" })
                out.push({ icon: DeskState.editing ? "check" : "pencil", label: DeskState.editing ? "Terminar a edição" : "Editar widgets", act: () => { DeskState.editing = !DeskState.editing; DeskState.selected = "" } })
                out.push({ icon: DeskState.locked ? "lockOpen" : "lock", label: DeskState.locked ? "Destravar posições" : "Travar posições", act: () => DeskState.locked = !DeskState.locked })
                out.push({ icon: Settings.desktopOn ? "eyeOff" : "eye", label: Settings.desktopOn ? "Esconder os widgets" : "Mostrar os widgets", act: () => Settings.desktopOn = !Settings.desktopOn })
                out.push({ sep: true })
                out.push({ icon: "wallpaper", label: "Trocar o wallpaper…", act: () => Settings.wpPickerOpen = true })
                out.push({ icon: "next", label: "Próximo wallpaper", act: () => Wallpaper.step(1) })
                out.push({ icon: "layers", label: "Visuais e layouts", sub: "presets" })
                out.push({ sep: true })
                out.push({ icon: "cog", label: "Configurações dos widgets", act: () => { Settings.settingsPage = "desktop"; Settings.settingsOpen = true } })
                return out
            }
            readonly property var subItems: DeskMenu.sub === "add"
                ? DeskState.groups.reduce((acc, g) => acc.concat([{ head: g.label }], DeskState.catalog.filter(c => c.group === g.id).map(c => ({ icon: c.icon, label: c.name, act: () => {
                    Settings.desktopOn = true
                    const a = win.area, pw = DeskState.px(c.sizes[0][0]), ph = DeskState.px(c.sizes[0][1])
                    DeskState.add(c.type, { fx: Math.max(0, Math.min(1, (DeskMenu.x - pw / 2 - a.x) / Math.max(1, a.width - pw))), fy: Math.max(0, Math.min(1, (DeskMenu.y - ph / 2 - a.y) / Math.max(1, a.height - ph))) })
                } }))), [])
                : DeskMenu.sub === "presets" ? (Looks.undoData ? [{ icon: "restore", label: "Desfazer (" + Looks.undoName + ")", act: () => Looks.undo() }] : []).concat(
                    DeskState.all.map(p => ({ icon: p.builtin ? (p.icon || "dashboard") : "layers", label: p.name, checked: DeskState.lastApplied === p.name, act: () => DeskState.apply(p.name) }))) : []
            component MenuList: Rectangle {
                id: ml
                property var entries: []
                property bool isSub: false
                width: 250
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
                            height: modelData.sep ? 9 : modelData.head ? 26 : 32
                            Rectangle { visible: !!modelData.sep; anchors.centerIn: parent; width: parent.width - 16; height: 1; color: Theme.border }
                            UiText { visible: !!modelData.head; x: 10; anchors.verticalCenter: parent.verticalCenter; text: modelData.head ?? ""; color: Theme.muted; font.pixelSize: 11; font.weight: Font.DemiBold }
                            Rectangle {
                                visible: !modelData.sep && !modelData.head
                                anchors.fill: parent; radius: 9
                                color: im.containsMouse || (modelData.sub && DeskMenu.sub === modelData.sub) ? (modelData.danger ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.18) : Theme.cardHi) : "transparent"
                                UiIcon { id: mi; x: 10; anchors.verticalCenter: parent.verticalCenter; name: modelData.icon ?? ""; size: 16; color: modelData.danger ? Theme.danger : (modelData.checked ? Theme.accent : Theme.muted) }
                                UiText { anchors { left: mi.right; leftMargin: 10; verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: 24 } elide: Text.ElideRight
                                    text: modelData.label ?? ""; color: modelData.danger ? Theme.danger : Theme.text; font.pixelSize: 13; font.weight: modelData.checked ? Font.DemiBold : Font.Normal }
                                UiIcon { visible: !!modelData.sub || !!modelData.checked; anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter } name: modelData.sub ? "chevRight" : "check"; size: 14; color: Theme.muted }
                                MouseArea {
                                    id: im; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onEntered: if (!ml.isSub && modelData.sub) DeskMenu.sub = modelData.sub; else if (!ml.isSub) DeskMenu.sub = ""
                                    onClicked: { if (modelData.sub) { DeskMenu.sub = modelData.sub; return } DeskMenu.close(); modelData.act() }
                                }
                            }
                        }
                    }
                }
            }
            MenuList {
                id: main
                entries: menu.items
                x: Math.min(DeskMenu.x, win.width - width - 8)
                y: Math.min(DeskMenu.y, win.height - height - 8)
            }
            Loader {
                active: DeskMenu.sub !== ""
                readonly property bool toLeft: main.x + main.width + 254 > win.width
                x: toLeft ? main.x - 254 : main.x + main.width + 4
                sourceComponent: MenuList {
                    isSub: true
                    entries: menu.subItems
                    y: Math.max(8, Math.min(main.y, win.height - height - 8))
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
                UiButton { icon: DeskState.locked ? "lockOpen" : "lock"; kind: "ghost"; onClicked: DeskState.locked = !DeskState.locked }
                UiButton { icon: "check"; text: "Pronto"; kind: "accent"; onClicked: { DeskState.editing = false; DeskState.selected = "" } }
            }
        }
    }
}
