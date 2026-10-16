//@ pragma UseQApplication
// Seu Quickshell: uma moldura fina na tela com barras que "sobem" (engrossam) onde voce quiser.
//   - UMA janela de tela cheia desenha tudo num so Shape (sem sobreposicao: o vidro/blur fica uniforme)
//   - ela e "click-through"; o espaco e reservado por janelinhas transparentes
//   - cada barra tem uma janela propria (BarWindow) com os modulos
//   - tudo vem de Settings (settings.json); a geometria, de Geometry.qml
// Recarregue com: shell-switch restart
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects

ShellRoot {
    id: shell

    readonly property color baseColor: Settings.barColor
    readonly property color fillColor: Qt.rgba(baseColor.r, baseColor.g, baseColor.b, Settings.glass ? Settings.glassOpacity / 100 : 1)

    Component.onCompleted: { HyprSync.ready; AppThemes.ready }

    // Super+Q (qs-close-or-kill): fecha o que estiver aberto do shell; responde false se nao havia nada (ai fecha a janela do app)
    IpcHandler {
        target: "panels"
        function closeall(): bool {
            const any = Settings.settingsOpen || Settings.launcherOpen || Settings.wpPickerOpen || Settings.homeOpen
                || Power.menuOpen || Profile.picking || Profile.editing !== ""
            Settings.settingsOpen = false; Settings.launcherOpen = false; Settings.wpPickerOpen = false; Settings.homeOpen = false
            Power.menuOpen = false
            if (Profile.picking || Profile.editing !== "") Profile.cancel()
            return any
        }
    }   // carrega o HyprSync (singleton) ja no inicio

    WallpaperWindow {}
    WallpaperPicker { geo: shell.geo }
    SettingsWindow { geo: shell.geo }
    Launcher { geo: shell.geo }
    Notifications { geo: shell.geo }
    Home { geo: shell.geo }
    PowerMenu {}
    PhotoEditor {}
    LockScreen {}
    DesktopLayer { geo: shell.geo }

    PanelWindow {
        id: frame
        anchors { left: true; right: true; top: true; bottom: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region {}
        WlrLayershell.namespace: "mine-frame"   // a regra de blur do Hyprland casa com este nome

        readonly property var geo: Geometry.compute(width, height, BarState.p)

        PaletteExtractor {}   // gera a paleta do tema a partir do wallpaper (so age com o tema ligado)

        Shape {
            anchors.fill: parent
            // GeometryRenderer + camada em 2x: o CurveRenderer (mais leve) gera artefatos onde as formas se sobrepoem
            preferredRendererType: Shape.GeometryRenderer
            layer.enabled: true      // suaviza as bordas (o GeometryRenderer nao tem antialias proprio)
            layer.smooth: true
            layer.textureSize: Qt.size(width * 2, height * 2)   // desenha no dobro da resolucao e reduz: bordas lisas
            ShapePath {
                fillColor: shell.fillColor
                strokeColor: "transparent"
                fillRule: ShapePath.WindingFill
                PathSvg { path: frame.geo.path }
            }
        }

        // grao proprio da moldura: textura de ruido recortada pelo formato da moldura (so aparece se shellGrain > 0)
        Item {   // mascara: o mesmo desenho, em branco
            id: grainMask
            anchors.fill: parent
            visible: false
            layer.enabled: Settings.shellGrain > 0   // sem grao: nao desenha a mascara (antes renderizava sempre)
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.GeometryRenderer
                layer.enabled: Settings.shellGrain > 0
                layer.samples: 8
                ShapePath {
                    fillColor: "white"
                    strokeColor: "transparent"
                    fillRule: ShapePath.WindingFill
                    PathSvg { path: frame.geo.path }
                }
            }
        }
        Image {
            id: grainTex
            anchors.fill: parent
            visible: false
            source: Qt.resolvedUrl("noise.png")
            fillMode: Image.Tile
        }
        MultiEffect {
            anchors.fill: parent
            visible: Settings.shellGrain > 0
            source: grainTex
            maskEnabled: true
            maskSource: grainMask
            opacity: Settings.shellGrain / 100
        }
    }

    readonly property var geo: frame.geo

    Variants {
        model: Settings.bars.map((b, i) => i)
        delegate: BarWindow {
            geo: shell.geo
        }
    }

    // ---- reservas de espaco: janelinhas transparentes que so empurram as janelas dos apps ----
    component Reserve: PanelWindow {
        required property string side
        readonly property int zone: Math.round(shell.geo.zone[side] ?? 0)
        visible: zone > 0
        anchors {
            top: side !== "bottom"
            bottom: side !== "top"
            left: side !== "right"
            right: side !== "left"
        }
        implicitWidth: 1
        implicitHeight: 1
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: zone
        color: "transparent"
        mask: Region {}
    }

    Reserve { side: "top" }
    Reserve { side: "bottom" }
    Reserve { side: "left" }
    Reserve { side: "right" }
}
