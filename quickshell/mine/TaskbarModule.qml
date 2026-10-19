// Modulo "taskbar" (o dock do shell): apps fixados (Settings.dockPinned) + abertos (janelas do Hyprland por classe).
// Clique: abre o app, ou foca a janela dele (cliques seguidos alternam entre as janelas); meio: abre outra instancia;
// direito: fixa / desafixa. Bolinhas embaixo: quantas janelas abertas. Passar o mouse aumenta um pouco o icone.
// Opcoes do modulo: iconSize (px), running (mostrar os abertos nao fixados).
import Quickshell
import Quickshell.Hyprland
import QtQuick

Item {
    id: root
    property var opts: ({})
    property bool vertical: false
    readonly property int isz: opts.iconSize ?? 26
    implicitWidth: vertical ? isz + 8 : list.implicitWidth
    implicitHeight: vertical ? list.implicitHeight : isz + 8

    readonly property var wins: Hyprland.toplevels.values.filter(t => t.lastIpcObject && t.lastIpcObject.class)
    function entryOf(cls) { return DesktopEntries.heuristicLookup(cls) }
    function keyOf(cls) { const e = entryOf(cls); return e ? e.id : cls.toLowerCase() }
    readonly property var apps: {
        const pinned = (Settings.dockPinned || []).slice(), out = pinned.map(id => ({ id: id, pinned: true, wins: [] }))
        for (const t of wins) {
            const k = keyOf(t.lastIpcObject.class)
            let a = out.find(x => x.id === k)
            if (!a) { if (root.opts.running === false) continue; a = { id: k, pinned: false, wins: [], cls: t.lastIpcObject.class }; out.push(a) }
            a.wins.push(t)
            a.cls = t.lastIpcObject.class
        }
        return out
    }
    function hypr(lua) { Quickshell.execDetached(["hyprctl", "eval", "hl.dispatch(" + lua + ")"]) }
    function togglePin(id) { const l = (Settings.dockPinned || []).slice(), i = l.indexOf(id); if (i >= 0) l.splice(i, 1); else l.push(id); Settings.dockPinned = l }
    property var cycle: ({})
    function activate(a) {
        if (!a.wins.length) { const e = DesktopEntries.byId(a.id) ?? entryOf(a.id); if (e) e.execute(); return }
        const i = ((cycle[a.id] ?? -1) + 1) % a.wins.length
        const c = Object.assign({}, cycle); c[a.id] = i; cycle = c
        hypr('hl.dsp.focus({ window = "address:' + a.wins[i].lastIpcObject.address + '" })')
    }

    Grid {
        id: list
        columns: root.vertical ? 1 : Math.max(1, root.apps.length)
        spacing: 6
        Repeater {
            model: root.apps
            delegate: Item {
                id: app
                required property var modelData
                readonly property var e: DesktopEntries.byId(modelData.id) ?? root.entryOf(modelData.cls ?? modelData.id)
                readonly property bool focused: modelData.wins.some(t => t.activated)
                width: root.isz + 8; height: root.isz + 8
                Rectangle {
                    anchors.fill: parent; radius: 9
                    color: app.focused ? Qt.rgba(Settings.accent.r, Settings.accent.g, Settings.accent.b, 0.22) : (am.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                    Behavior on color { ColorAnimation { duration: 140 } }
                }
                Image {
                    anchors.centerIn: parent
                    width: root.isz; height: root.isz
                    sourceSize: Qt.size(root.isz * 2, root.isz * 2)
                    source: Icons.path(app.e && app.e.icon ? app.e.icon : (app.modelData.cls ?? app.modelData.id), "application-x-executable")
                    scale: am.pressed ? 0.88 : (am.containsMouse ? 1.14 : 1)
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
                    opacity: app.modelData.wins.length || am.containsMouse ? 1 : 0.75
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
                        if (m.button === Qt.RightButton) root.togglePin(app.modelData.id)
                        else if (m.button === Qt.MiddleButton) { if (app.e) app.e.execute() }
                        else root.activate(app.modelData)
                    }
                }
            }
        }
    }
}
