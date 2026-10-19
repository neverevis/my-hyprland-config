// Modulo "taskbar" (o dock do shell): apps fixados (Settings.dockPinned) + abertos (janelas do Hyprland por classe).
// Clique: abre o app, ou foca a janela dele (cliques seguidos alternam entre as janelas); meio: abre outra instancia;
// direito: fixa / desafixa. Bolinhas embaixo: quantas janelas abertas. Parar o mouse num app aberto mostra as
// miniaturas das janelas dele (clique foca, X fecha).
// Opcoes: iconSize (px), running (abertos nao fixados), magnify (0-100: ampliacao ao passar o mouse, como no Mac),
// appsButton (botao do launcher no inicio), media (musica tocando no fim), mono (icones monocromaticos),
// ignore (classes escondidas, separadas por espaco; aceita * no fim), separator (linha entre fixados e abertos),
// previews (miniaturas das janelas).
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
    readonly property int isz: opts.iconSize ?? 26
    readonly property real mag: Math.max(0, Math.min(100, opts.magnify ?? 35)) / 100
    implicitWidth: vertical ? isz + 8 : list.implicitWidth
    implicitHeight: vertical ? list.implicitHeight : isz + 8

    readonly property var ignore: String(opts.ignore ?? "").trim().split(/\s+/).filter(x => x)
    function ignored(cls) {
        const c = cls.toLowerCase()
        return ignore.some(p => p.endsWith("*") ? c.startsWith(p.slice(0, -1).toLowerCase()) : c === p.toLowerCase())
    }
    readonly property var wins: Hyprland.toplevels.values.filter(t => t.lastIpcObject && t.lastIpcObject.class && !ignored(t.lastIpcObject.class))
    function entryOf(cls) { return DesktopEntries.heuristicLookup(cls) }
    function keyOf(cls) { const e = entryOf(cls); return e ? e.id : cls.toLowerCase() }
    function pinnedList() { return Array.isArray(Settings.dockPinned) ? Settings.dockPinned : [] }
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
        spacing: 6
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
            MouseArea { id: abm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.launcherOpen = !Settings.launcherOpen }
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
                readonly property real nominal: (root.opts.appsButton ? root.isz + 14 : 0) + index * (root.isz + 14) + (root.opts.separator && index >= root.pinnedCount && root.pinnedCount > 0 ? 12 : 0) + (root.isz + 8) / 2
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
                    MouseArea {
                        id: am
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: m => {
                            BarState.pop = null
                            if (m.button === Qt.RightButton) root.togglePin(app.modelData.id)
                            else if (m.button === Qt.MiddleButton) { if (app.e) app.e.execute() }
                            else root.activate(app.modelData)
                        }
                        // miniaturas das janelas (detalhes da barra, tipo "windows")
                        onContainsMouseChanged: {
                            if (!containsMouse) { BarState.popLeave(); return }
                            if (!app.modelData.wins.length || root.opts.previews === false) return
                            const p = cell.mapToItem(null, 0, 0)
                            BarState.popEnter({ kind: "windows", side: root.side, wins: app.modelData.wins, title: app.e ? app.e.name : (app.modelData.cls ?? ""),
                                                rect: { x: p.x + root.origin.x, y: p.y + root.origin.y, w: cell.width, h: cell.height } })
                        }
                    }
                }
            }
        }

        // musica tocando: capa + tocar/pausar
        Item {
            readonly property var p: Mpris.players.values.find(x => x.isPlaying) ?? Mpris.players.values[0] ?? null
            visible: !!root.opts.media && !!p
            width: root.isz + 8; height: root.isz + 8
            RoundImage {
                anchors.centerIn: parent
                width: root.isz; height: root.isz; radius: root.isz * 0.3
                source: parent.p ? (parent.p.trackArtUrl || "") : ""
                sourceSize: Qt.size(96, 96)
            }
            Rectangle {
                anchors.centerIn: parent
                width: root.isz * 0.55; height: width; radius: width / 2
                color: Qt.rgba(0, 0, 0, mm.containsMouse ? 0.6 : 0.35)
                UiIcon { anchors.centerIn: parent; name: parent.parent.p && parent.parent.p.isPlaying ? "pause" : "play"; size: parent.width * 0.6; color: "white" }
            }
            MouseArea { id: mm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (parent.p) parent.p.togglePlaying() }
        }
    }
}
