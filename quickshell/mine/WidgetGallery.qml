// Galeria "Adicionar widget": abas por grupo e uma grade de cartoes com miniatura ao vivo, nome e descricao.
// Fica dentro de um Loader (DesktopLayer): nada existe com ela fechada; as miniaturas so existem na aba aberta e
// nascem em segundo plano. Clicar adiciona no ponto pedido (DeskState.galleryX/Y) e seleciona o novo widget.
import QtQuick

Item {
    id: g
    anchors.fill: parent
    property string tab: ""
    readonly property var hidden: Settings.list(Settings.desktopMenuHidden)
    function entries(gid) { return DeskState.catalog.filter(c => c.group === gid && hidden.indexOf(c.type) < 0) }
    readonly property var groupsShown: DeskState.groups.filter(x => entries(x.id).length > 0)
    readonly property string curTab: groupsShown.some(x => x.id === tab) ? tab : (groupsShown.length ? groupsShown[0].id : "")
    readonly property var types: entries(curTab).map(c => c.type)
    property real k: 0
    Component.onCompleted: { k = 1; g.forceActiveFocus() }
    // altura estavel entre abas: a do grupo com mais widgets (3 por linha)
    readonly property int maxRows: groupsShown.reduce((m, x) => Math.max(m, Math.ceil(entries(x.id).length / 3)), 1)
    Behavior on k { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    function close() { DeskState.galleryOpen = false }

    focus: true
    Keys.onEscapePressed: close()

    Rectangle { anchors.fill: parent; color: "#000000"; opacity: 0.30 * g.k }
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: g.close() }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Math.min(700, g.width - 60)
        height: Math.min(g.height - 80, 124 + g.maxRows * 198 + 14)
        radius: 22
        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.98)
        border.width: 1; border.color: Theme.border
        opacity: g.k
        scale: 0.97 + 0.03 * g.k
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

        Item {
            id: head
            x: 20; y: 16; width: parent.width - 40; height: 40
            Rectangle { id: hi; width: 40; height: 40; radius: 12; color: Theme.tint(0.18)
                UiIcon { anchors.centerIn: parent; name: "plus"; size: 20; color: Theme.accent } }
            Column {
                anchors { left: hi.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
                UiText { text: "Adicionar widget"; color: Theme.text; font.pixelSize: 17; font.weight: Font.Bold }
                UiText { text: "Escolha um para pôr na área de trabalho."; color: Theme.muted; font.pixelSize: 12 }
            }
            UiButton { anchors.right: parent.right; icon: "close"; kind: "ghost"; onClicked: g.close() }
        }
        UiSeg {
            id: tabs
            x: 20; y: head.y + head.height + 14
            width: parent.width - 40
            fill: true
            options: g.groupsShown.map(x => [x.id, x.label])
            value: g.curTab
            onPicked: v => { g.tab = v; gs.toTop() }
        }
        DeskScroll {
            id: gs
            x: 14; y: tabs.y + tabs.height + 12
            width: parent.width - 28; height: parent.height - y - 14
            contentHeight: flow.implicitHeight + 6
            Flow {
                id: flow
                x: 6
                width: parent.width - 12
                spacing: 12
                readonly property real tw: Math.floor((width - 2 * spacing) / 3)
                Repeater {
                    model: g.types
                    delegate: Rectangle {
                        id: tile
                        required property string modelData
                        readonly property var c: DeskState.info(modelData)
                        width: flow.tw; height: 112 + 74; radius: 16
                        color: tm.containsMouse ? Theme.cardHi : Theme.track
                        border.width: tm.containsMouse ? 2 : 1; border.color: tm.containsMouse ? Theme.accent : Theme.border
                        Behavior on color { ColorAnimation { duration: 120 } }
                        WidgetPreview {
                            x: 6; y: 6; width: parent.width - 12; height: 112
                            plain: true; async: true; showLabel: false
                            w: ({ type: tile.modelData, cols: tile.c.sizes[0][0], rows: tile.c.sizes[0][1], opts: ({}) })
                        }
                        Column {
                            x: 12; y: 112 + 14; width: parent.width - 24
                            spacing: 3
                            Row {
                                spacing: 7
                                UiIcon { name: tile.c.icon; size: 14; color: tm.containsMouse ? Theme.accent : Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                                UiText { text: tile.c.name; color: Theme.text; font.pixelSize: 13; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                            }
                            UiText { width: parent.width; text: tile.c.desc; color: Theme.muted; font.pixelSize: 11; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight }
                        }
                        // dica de clique
                        Rectangle {
                            opacity: tm.containsMouse ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                            anchors { right: parent.right; top: parent.top; margins: 12 }
                            width: 28; height: 28; radius: 14; color: Theme.accent
                            UiIcon { anchors.centerIn: parent; name: "plus"; size: 16; color: Theme.accentText }
                        }
                        MouseArea {
                            id: tm
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { const t = tile.modelData; g.close(); DeskState.addAt(t, DeskState.galleryX, DeskState.galleryY) }
                        }
                    }
                }
            }
        }
    }
}
