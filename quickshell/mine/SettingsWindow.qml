// Janela de configuracoes (barra lateral + paginas). Todas as mudancas valem ao vivo e ficam salvas.
// Abra/feche com:  qs -c mine ipc call settings toggle      
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: root
    property bool open: false
    property string page: "bars"

    IpcHandler {
        target: "settings"
        function toggle(): void { root.open = !root.open }
    }

    readonly property var pages: [
        { id: "bars", label: "Barras" },
        { id: "frame", label: "Moldura" },
        { id: "look", label: "Aparência" },
        { id: "wall", label: "Wallpaper" },
        { id: "blur", label: "Blur" },
        { id: "launcher", label: "Launcher" },
        { id: "anim", label: "Animação" }
    ]

    LazyLoader {
        active: root.open

        PanelWindow {   // sem ancoras: aparece centralizada
            implicitWidth: 900
            implicitHeight: Math.min(660, (screen ? screen.height : 800) - 80)
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.namespace: "mine-settings"

            Rectangle {
                anchors.fill: parent
                radius: 20
                color: Theme.gl(Theme.bg, 1)
                border.width: 1
                border.color: Theme.border
                clip: true
                focus: true
                Keys.onEscapePressed: root.open = false

                // ---- barra lateral ----
                Rectangle {
                    id: side
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: 210
                    color: "transparent"
                    // um unico retangulo com cantos arredondados so na esquerda (o da direita fica cortado): sem sobreposicao, o vidro nao dobra
                    clip: true
                    Rectangle { x: 0; y: 0; width: parent.width + 40; height: parent.height; radius: 20; color: Theme.gl(Theme.sidebar, 1) }

                    Column {
                        anchors { fill: parent; margins: 16 }
                        spacing: 6

                        Row {
                            spacing: 10
                            bottomPadding: 14
                            Rectangle { width: 12; height: 12; radius: 6; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "Quickshell"; color: Theme.text; font.pixelSize: 17; font.weight: Font.Bold }
                        }

                        Repeater {
                            model: root.pages
                            delegate: Rectangle {
                                id: nav
                                required property var modelData
                                width: parent.width; height: 40; radius: 10
                                color: root.page === modelData.id ? Theme.cardHi : (navMouse.containsMouse ? Theme.card : "transparent")
                                Rectangle {
                                    visible: root.page === nav.modelData.id
                                    width: 3; height: 18; radius: 2; color: Theme.accent
                                    anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                                }
                                Text {
                                    anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                                    text: nav.modelData.label
                                    color: root.page === nav.modelData.id ? Theme.text : Theme.muted
                                    font.pixelSize: 14; font.weight: Font.Medium
                                }
                                MouseArea { id: navMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.page = nav.modelData.id }
                            }
                        }
                    }

                    Column {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 16 }
                        spacing: 8
                        UiButton { width: parent.width; text: "Restaurar padrão"; onClicked: Settings.reset() }
                        UiButton { width: parent.width; text: "Fechar"; kind: "accent"; onClicked: root.open = false }
                    }
                }

                // ---- conteudo ----
                Item {
                    anchors { left: side.right; right: parent.right; top: parent.top; bottom: parent.bottom; margins: 24 }

                    Text {
                        id: title
                        text: (root.pages.find(p => p.id === root.page) ?? { label: "" }).label
                        color: Theme.text; font.pixelSize: 24; font.weight: Font.Bold
                    }

                    Item {
                        anchors { left: parent.left; right: parent.right; top: title.bottom; topMargin: 16; bottom: parent.bottom }

                        Loader {
                            anchors.fill: parent
                            active: root.page === "bars"
                            visible: active
                            sourceComponent: PageBars {}
                        }
                        Flickable {
                            id: pageFlick
                            anchors.fill: parent
                            visible: root.page !== "bars"
                            contentHeight: pageLoader.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            interactive: false   // so a roda do mouse rola (arrastar nao)
                            WheelHandler {
                                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                onWheel: e => { const f = pageFlick; f.contentY = Math.max(0, Math.min(Math.max(0, f.contentHeight - f.height), f.contentY - e.angleDelta.y)) }
                            }
                            Loader {
                                id: pageLoader
                                width: parent.width
                                sourceComponent: root.page === "launcher" ? launcherC : root.page === "frame" ? frameC : (root.page === "blur" ? blurC : (root.page === "anim" ? animC : (root.page === "wall" ? wallC : lookC)))
                            }
                        }
                        Component { id: launcherC; PageLauncher {} }
                        Component { id: frameC; PageFrame {} }
                        Component { id: lookC; PageLook {} }
                        Component { id: blurC; PageBlur {} }
                        Component { id: animC; PageAnim {} }
                        Component { id: wallC; PageWallpaper {} }
                    }
                }
            }
        }
    }
}
