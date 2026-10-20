// Modulo "taskbar" (o dock do shell): apps fixados (Settings.dockPinned) + abertos (janelas do Hyprland por classe).
// Clique: abre o app, ou foca a janela dele (cliques seguidos alternam entre as janelas); meio: abre outra instancia;
// direito: menu (acoes do app, nova janela, mover para o workspace, fixar / desafixar, fechar); Shift + direito fixa direto.
// Arrastar um app fixado muda a ordem (arrastar para longe do dock desafixa). Bolinhas embaixo: quantas janelas abertas. Parar o mouse num app aberto mostra as
// miniaturas das janelas dele (clique foca, X fecha).
// Opcoes: iconSize (px), running (abertos nao fixados), magnify (0-100: ampliacao ao passar o mouse, como no Mac),
// appsButton (botao do launcher no inicio), media (musica tocando no fim), mono (icones monocromaticos),
// ignore (classes escondidas, separadas por espaco; aceita * no fim e /regex/), separator (linhas entre os grupos),
// previews (miniaturas das janelas), spacing (px entre os icones), appsAction (launcher | overview | home), pinButton (alfinete que
// liga / desliga o esconder automatico do dock), mediaText (titulo e botoes no cartao de musica), revealEmpty (BarWindow: mostra o dock
// sozinho quando nao ha janela no workspace).
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Effects

Item {
    id: root
    property var opts: ({})
    property bool vertical: false
    property string side: "bottom"
    property point origin: Qt.point(0, 0)
    property int barIdx: -1
    readonly property int gap: Math.max(0, Math.min(24, opts.spacing ?? 6))
    readonly property int isz: opts.iconSize ?? 26
    readonly property real mag: Math.max(0, Math.min(100, opts.magnify ?? 35)) / 100
    implicitWidth: vertical ? isz + 8 : list.implicitWidth
    implicitHeight: vertical ? list.implicitHeight : isz + 8

    readonly property var ignore: String(opts.ignore ?? "").trim().split(/\s+/).filter(x => x)
    function ignored(cls) {
        const c = cls.toLowerCase()
        return ignore.some(p => {
            if (p.length > 2 && p.startsWith("/") && p.endsWith("/")) { try { return new RegExp(p.slice(1, -1), "i").test(cls) } catch (e) { return false } }
            return p.endsWith("*") ? c.startsWith(p.slice(0, -1).toLowerCase()) : c === p.toLowerCase()
        })
    }
    readonly property var wins: Hyprland.toplevels.values.filter(t => t.lastIpcObject && t.lastIpcObject.class && !ignored(t.lastIpcObject.class))
    function entryOf(cls) { return DesktopEntries.heuristicLookup(cls) }
    function keyOf(cls) { const e = entryOf(cls); return e ? e.id : cls.toLowerCase() }
    function pinnedList() { return Settings.list(Settings.dockPinned) }
    readonly property var apps: {
        const out = pinnedList().map(id => ({ id: id, pinned: true, wins: [] }))
        for (const t of wins) {
            const k = keyOf(t.lastIpcObject.class)
            let a = out.find(x => x.id === k)
            if (!a) { if (root.opts.running === false) continue; a = { id: k, pinned: false, wins: [], cls: t.lastIpcObject.class }; out.push(a) }
            a.wins.push(t)
            a.cls = t.lastIpcObject.class
        }
        return out
    }
    readonly property int pinnedCount: apps.filter(a => a.pinned).length
    function hypr(lua) { Quickshell.execDetached(["hyprctl", "eval", "hl.dispatch(" + lua + ")"]) }
    function togglePin(id) { const l = pinnedList().slice(), i = l.indexOf(id); if (i >= 0) l.splice(i, 1); else l.push(id); Settings.dockPinned = l }
    // menu de contexto (cartao "appmenu" do BarPopup)
    function menuFor(a, e, rc) {
        const items = [{ header: e ? e.name : (a.cls ?? a.id) }]
        const acts = e && e.actions ? Array.from(e.actions) : []
        for (const ac of acts) items.push({ text: ac.name, icon: "chevRight", fn: () => ac.execute() })
        if (acts.length) items.push({ sep: true })
        items.push({ text: "Abrir nova janela", icon: "plus", fn: () => { if (e) e.execute() } })
        if (a.wins.length) {
            items.push({ sep: true }, { header: "Mover para o workspace" })
            items.push({ wsrow: true, fn: n => hypr('hl.dsp.window.move({ workspace = ' + n + ', window = "address:' + a.wins[0].lastIpcObject.address + '" })') })
        }
        items.push({ sep: true })
        items.push({ text: a.pinned ? "Desafixar do dock" : "Fixar no dock", icon: a.pinned ? "pinOff" : "pin", fn: () => togglePin(a.id) })
        if (a.wins.length) items.push({ text: a.wins.length > 1 ? "Fechar todas as janelas" : "Fechar a janela", icon: "close", danger: true,
            fn: () => { for (const t of a.wins) hypr('hl.dsp.window.close({ window = "address:' + t.lastIpcObject.address + '" })') } })
        const req = { kind: "appmenu", bar: root.barIdx, side: root.side, rect: rc, items: items, opts: ({}) }
        BarState.popPending = req
        BarState.pop = req
    }
    function movePinned(id, delta) {
        const l = pinnedList().slice(), i = l.indexOf(id)
        if (i < 0) return
        const j = Math.max(0, Math.min(l.length - 1, i + delta))
        if (j === i) return
        l.splice(i, 1); l.splice(j, 0, id); Settings.dockPinned = l
    }
    property var cycle: ({})
    function activate(a) {
        if (!a.wins.length) { const e = DesktopEntries.byId(a.id) ?? entryOf(a.id); if (e) e.execute(); return }
        const i = ((cycle[a.id] ?? -1) + 1) % a.wins.length
        const c = Object.assign({}, cycle); c[a.id] = i; cycle = c
        hypr('hl.dsp.focus({ window = "address:' + a.wins[i].lastIpcObject.address + '" })')
    }

    // ampliacao: posicao do mouse ao longo do dock
    property real mouseAlong: -1
    HoverHandler {
        onPointChanged: root.mouseAlong = root.vertical ? point.position.y : point.position.x
        onHoveredChanged: if (!hovered) root.mouseAlong = -1
    }
    function scaleAt(center) {
        if (mouseAlong < 0 || mag <= 0) return 1
        const d = Math.abs(center - mouseAlong) / (isz * 2.2)
        return 1 + mag * Math.max(0, 1 - d * d)
    }

    Grid {
        id: list
        columns: root.vertical ? 1 : 99
        spacing: root.gap
        verticalItemAlignment: Grid.AlignVCenter
        horizontalItemAlignment: Grid.AlignHCenter

        // botao de apps (abre o launcher)
        Item {
            visible: !!root.opts.appsButton
            width: root.isz + 8; height: root.isz + 8
            Rectangle {
                anchors.centerIn: parent
                width: root.isz; height: root.isz; radius: root.isz * 0.3
                color: abm.containsMouse ? Theme.tint(0.3) : Theme.tint(0.16)
                UiIcon { anchors.centerIn: parent; name: "apps"; size: root.isz * 0.55; color: Theme.accent }
            }
            MouseArea { id: abm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const a = root.opts.appsAction ?? "launcher"
                    if (a === "overview") Actions.run("overview")
                    else if (a === "home") Settings.homeOpen = !Settings.homeOpen
                    else Settings.launcherOpen = !Settings.launcherOpen
                } }
            TipHover { text: "Todos os apps"; side: root.side; origin: root.origin }
        }

        Rectangle {   // linha depois do botao de apps
            visible: !!root.opts.separator && !!root.opts.appsButton
            width: root.vertical ? root.isz : 1.5; height: root.vertical ? 1.5 : root.isz - 4
            color: Qt.rgba(Settings.textColor.r, Settings.textColor.g, Settings.textColor.b, 0.25)
        }

        Repeater {
            model: root.apps
            delegate: Item {
                id: app
                required property var modelData
                required property int index
                readonly property var e: DesktopEntries.byId(modelData.id) ?? root.entryOf(modelData.cls ?? modelData.id)
                readonly property bool focused: modelData.wins.some(t => t.activated)
                readonly property bool sepBefore: !!root.opts.separator && index === root.pinnedCount && index > 0
                readonly property real gapBefore: sepBefore ? 12 : 0
                // centro sem ampliacao (estavel: nao depende do tamanho dos vizinhos ja ampliados)
                readonly property real nominal: (root.opts.appsButton ? root.isz + 8 + root.gap : 0) + index * (root.isz + 8 + root.gap) + (root.opts.separator && index >= root.pinnedCount && root.pinnedCount > 0 ? 12 : 0) + (root.isz + 8) / 2
                readonly property real s: root.scaleAt(nominal)
                readonly property real cellLen: (root.isz + 8) * (1 + (s - 1) * 0.6)
                width: root.vertical ? root.isz + 8 : cellLen + gapBefore
                height: root.vertical ? cellLen + gapBefore : root.isz + 8
                Rectangle {
                    visible: app.sepBefore
                    x: root.vertical ? 4 : 4; y: root.vertical ? 4 : 6
                    width: root.vertical ? root.isz : 1.5; height: root.vertical ? 1.5 : root.isz - 4
                    color: Qt.rgba(Settings.textColor.r, Settings.textColor.g, Settings.textColor.b, 0.25)
                }
                Item {
                    id: cell
                    x: root.vertical ? 0 : app.gapBefore + (app.cellLen - width) / 2
                    y: root.vertical ? app.gapBefore + (app.cellLen - height) / 2 : 0
                    width: root.isz + 8; height: root.isz + 8
                    Rectangle {
                        anchors.fill: parent; radius: 9
                        color: app.focused ? Qt.rgba(Settings.accent.r, Settings.accent.g, Settings.accent.b, 0.22) : (am.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }
                    Image {
                        anchors.centerIn: parent
                        width: root.isz; height: root.isz
                        sourceSize: Qt.size(root.isz * 3, root.isz * 3)
                        source: Icons.path(app.e && app.e.icon ? app.e.icon : (app.modelData.cls ?? app.modelData.id), "application-x-executable")
                        scale: (am.pressed ? 0.88 : 1) * (root.mag > 0 ? app.s : (am.containsMouse ? 1.14 : 1))
                        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                        // ampliado: cresce para longe da borda (como no Mac)
                        transformOrigin: root.side === "bottom" ? Item.Bottom : root.side === "top" ? Item.Top : root.side === "left" ? Item.Left : Item.Right
                        opacity: app.modelData.wins.length || am.containsMouse ? 1 : 0.75
                        layer.enabled: !!root.opts.mono
                        layer.effect: MultiEffect { colorization: 1; colorizationColor: Settings.textColor; brightness: 0.35 }
                    }
                    // janelas abertas: bolinhas (a do app focado alonga)
                    Row {
                        anchors { horizontalCenter: root.vertical ? undefined : parent.horizontalCenter; bottom: root.vertical ? undefined : parent.bottom
                                  verticalCenter: root.vertical ? parent.verticalCenter : undefined; left: root.vertical ? parent.left : undefined }
                        spacing: 2
                        Repeater {
                            model: Math.min(3, app.modelData.wins.length)
                            delegate: Rectangle { width: app.focused && !root.vertical ? 10 : 4; height: app.focused && root.vertical ? 10 : 4; radius: 2; color: app.focused ? Settings.accent : Qt.rgba(Settings.textColor.r, Settings.textColor.g, Settings.textColor.b, 0.6)
                                Behavior on width { NumberAnimation { duration: 160 } } }
                        }
                    }
                    // arrastar (so fixados): muda a ordem; para longe do dock desafixa
                    DragHandler {
                        id: dh
                        enabled: app.modelData.pinned
                        target: null
                        acceptedButtons: Qt.LeftButton
                        onActiveChanged: {
                            if (active) { BarState.pop = null; return }
                            const along = root.vertical ? dh.activeTranslation.y : dh.activeTranslation.x
                            const away = root.vertical ? dh.activeTranslation.x : dh.activeTranslation.y
                            const sgn = root.side === "right" || root.side === "bottom" ? -1 : 1
                            if (Math.abs(away) > root.isz * 2.2 && sgn * away > 0) root.togglePin(app.modelData.id)
                            else root.movePinned(app.modelData.id, Math.round(along / (root.isz + 8 + root.gap)))
                        }
                    }
                    transform: Translate { x: dh.active && !root.vertical ? dh.activeTranslation.x : 0; y: dh.active && root.vertical ? dh.activeTranslation.y : 0 }
                    z: dh.active ? 10 : 0
                    MouseArea {
                        id: am
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: m => {
                            BarState.pop = null
                            if (m.button === Qt.RightButton && (m.modifiers & Qt.ShiftModifier)) root.togglePin(app.modelData.id)
                            else if (m.button === Qt.RightButton) {
                                const p = cell.mapToItem(null, 0, 0)
                                root.menuFor(app.modelData, app.e, { x: p.x + root.origin.x, y: p.y + root.origin.y, w: cell.width, h: cell.height })
                            }
                            else if (m.button === Qt.MiddleButton) { if (app.e) app.e.execute() }
                            else root.activate(app.modelData)
                        }
                        // miniaturas das janelas (detalhes da barra, tipo "windows")
                        onContainsMouseChanged: {
                            if (!containsMouse) { BarState.popLeave(); return }
                            const p = cell.mapToItem(null, 0, 0)
                            const rc = { x: p.x + root.origin.x, y: p.y + root.origin.y, w: cell.width, h: cell.height }
                            const nm = app.e ? app.e.name : (app.modelData.cls ?? app.modelData.id)
                            // sem janelas (ou sem miniaturas): so o nome do app
                            if (!app.modelData.wins.length || root.opts.previews === false) { BarState.tipEnter(nm, root.side, rc); return }
                            BarState.popEnter({ kind: "windows", bar: root.barIdx, side: root.side, wins: app.modelData.wins, title: app.e ? app.e.name : (app.modelData.cls ?? ""),
                                                rect: { x: p.x + root.origin.x, y: p.y + root.origin.y, w: cell.width, h: cell.height } })
                        }
                    }
                }
            }
        }

        Rectangle {   // linha antes do cartao de musica
            visible: !!root.opts.separator && mcard.visible
            width: root.vertical ? root.isz : 1.5; height: root.vertical ? 1.5 : root.isz - 4
            color: Qt.rgba(Settings.textColor.r, Settings.textColor.g, Settings.textColor.b, 0.25)
        }
        // musica tocando: capa + tocar/pausar; na horizontal tambem titulo, artista e anterior / proxima (opcao mediaText)
        Item {
            id: mcard
            readonly property var p: Mpris.players.values.find(x => x.isPlaying) ?? Mpris.players.values[0] ?? null
            readonly property bool wide: !root.vertical && root.opts.mediaText !== false
            visible: !!root.opts.media && !!p
            width: root.vertical ? root.isz + 8 : (wide ? root.isz + 8 + txtCol.width + 6 + btns.width : root.isz + 8)
            height: root.vertical ? root.isz + 8 : root.isz + 8
            Item {
                id: art
                width: root.isz + 8; height: root.isz + 8
                RoundImage {
                    anchors.centerIn: parent
                    width: root.isz; height: root.isz; radius: root.isz * 0.3
                    source: mcard.p ? (mcard.p.trackArtUrl || "") : ""
                    sourceSize: Qt.size(96, 96)
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: root.isz * 0.55; height: width; radius: width / 2
                    color: Qt.rgba(0, 0, 0, mm.containsMouse ? 0.6 : 0.35)
                    UiIcon { anchors.centerIn: parent; name: mcard.p && mcard.p.isPlaying ? "pause" : "play"; size: parent.width * 0.6; color: "white" }
                }
                MouseArea { id: mm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (mcard.p) mcard.p.togglePlaying() }
            }
            Column {
                id: txtCol
                visible: mcard.wide
                x: art.width + 2
                anchors.verticalCenter: parent.verticalCenter
                width: visible ? 130 : 0
                spacing: -1
                UiText { width: parent.width; elide: Text.ElideRight; text: mcard.p ? (mcard.p.trackTitle || mcard.p.identity) : ""; color: Settings.textColor; font.pixelSize: 12; font.weight: Font.DemiBold }
                UiText { width: parent.width; elide: Text.ElideRight; text: mcard.p ? (mcard.p.trackArtist || "") : ""; color: Settings.textColor; opacity: 0.65; font.pixelSize: 10 }
            }
            Row {
                id: btns
                visible: mcard.wide
                x: art.width + 2 + txtCol.width + 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Repeater {
                    model: [["prev", () => mcard.p.previous()], ["next", () => mcard.p.next()]]
                    delegate: Rectangle {
                        required property var modelData
                        width: 22; height: 22; radius: 11; color: bmm.containsMouse ? Qt.rgba(Settings.textColor.r, Settings.textColor.g, Settings.textColor.b, 0.16) : "transparent"
                        UiIcon { anchors.centerIn: parent; name: modelData[0]; size: 13; color: Settings.textColor }
                        MouseArea { id: bmm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (mcard.p) modelData[1]() }
                    }
                }
            }
        }
        // alfinete: dock sempre visivel (fixo) ou escondido ate o mouse encostar
        Rectangle {
            visible: !!root.opts.pinButton && root.barIdx >= 0
            width: root.isz + 8; height: root.isz + 8
            color: "transparent"
            readonly property bool fixed: root.barIdx >= 0 && Settings.bars[root.barIdx] ? !Settings.bars[root.barIdx].autoHide : true
            Rectangle {
                anchors.centerIn: parent
                width: root.isz; height: root.isz; radius: root.isz * 0.3
                color: pbm.containsMouse ? Theme.tint(0.3) : (parent.fixed ? Theme.tint(0.16) : "transparent")
                UiIcon { anchors.centerIn: parent; name: parent.parent.fixed ? "pin" : "pinOff"; size: root.isz * 0.55; color: parent.parent.fixed ? Theme.accent : Settings.textColor }
            }
            MouseArea { id: pbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: { BarState.pop = null; const b = Settings.bars[root.barIdx]; Settings.setBar(root.barIdx, "autoHide", !(b && b.autoHide)) } }
            TipHover { text: parent.fixed ? "Dock fixo (clique para esconder sozinho)" : "Dock escondido (clique para fixar)"; side: root.side; origin: root.origin }
        }
    }
}
