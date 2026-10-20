// Bandeja do sistema (StatusNotifier): icones dos apps; clique esquerdo ativa, direito abre o menu, meio = acao secundaria,
// roda do mouse rola; passar o mouse mostra o nome (dica). Opcoes: size (px), spacing (px), hidePassive (esconde os icones
// parados; padrao ligado), mono (icones na cor do texto; padrao ligado), showItemId (mostra o id do app na dica),
// hidden (ids escondidos: clique do meio + Shift esconde; a pagina Barras mostra de volta).
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import QtQuick

Grid {
    id: root
    property var opts: ({})
    property bool vertical: false
    property string side: "bottom"
    property point origin: Qt.point(0, 0)

    readonly property real size: opts.size ?? 18
    spacing: opts.spacing ?? 8
    columns: vertical ? 1 : 99

    readonly property var hiddenIds: Settings.list(opts.hidden)
    Repeater {
        model: SystemTray.items
        delegate: Item {
            id: cell
            required property var modelData   // SystemTrayItem
            readonly property bool gone: ((root.opts.hidePassive ?? true) && modelData.status === Status.Passive) || root.hiddenIds.indexOf(modelData.id) >= 0
            visible: !gone
            width: gone ? 0 : root.size
            height: gone ? 0 : root.size

            Image {
                anchors.fill: parent
                source: cell.modelData.icon
                sourceSize: Qt.size(64, 64)
                smooth: true
                fillMode: Image.PreserveAspectFit
                opacity: cell.modelData.status === Status.Passive ? 0.5 : 1
                scale: mouse.containsMouse ? 1.12 : 1
                Behavior on scale { NumberAnimation { duration: 100 } }
                // monocromatico: o icone vira silhueta na cor do texto da barra
                layer.enabled: root.opts.mono ?? true
                layer.effect: MultiEffect { colorization: 1; colorizationColor: Settings.textColor; brightness: 0.4 }
            }

            readonly property string tipText: {
                const m = modelData
                const t = m.tooltipTitle || m.title || m.id || "", d = m.tooltipDescription || ""
                return t + (d !== "" && d !== t ? " • " + d : "") + (root.opts.showItemId ? " [" + m.id + "]" : "")
            }
            TipHover { text: cell.gone ? "" : cell.tipText; side: root.side; origin: root.origin }

            QsMenuAnchor {
                id: menuAnchor
                menu: cell.modelData.menu
                anchor.item: cell
                anchor.edges: root.side === "bottom" ? Edges.Top : root.side === "top" ? Edges.Bottom : root.side === "left" ? Edges.Right : Edges.Left
                anchor.gravity: anchor.edges
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                anchors.margins: -3
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: m => {
                    BarState.popLeave()
                    if (m.button === Qt.MiddleButton) cell.modelData.secondaryActivate()
                    else if (m.button === Qt.RightButton || cell.modelData.onlyMenu) { if (cell.modelData.hasMenu) menuAnchor.open() }
                    else cell.modelData.activate()
                }
                onWheel: w => cell.modelData.scroll(w.angleDelta.y, false)
            }
        }
    }
}
