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
    // sem recarregar sozinho ao salvar um .qml: com UseQApplication, desmontar as janelas no recarregamento as vezes
    // aborta no Qt (QWindow::unsetCursor) e pode deixar o shell parado. Para aplicar mudancas: shell-switch restart
    settings.watchFiles: false

    readonly property color baseColor: Settings.barColor
    readonly property color fillColor: Qt.rgba(baseColor.r, baseColor.g, baseColor.b, Settings.glass ? Settings.glassOpacityEff / 100 : 1)

    Component.onCompleted: { HyprSync.ready; AppThemes.ready; Idle.ready }

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
        // diagnostico: estado e progresso (0..1) de cada painel
        function status(): string {
            return JSON.stringify({ launcher: [Settings.launcherOpen, BarState.launcherProg], home: [Settings.homeOpen, BarState.homeProg],
                picker: [Settings.wpPickerOpen, BarState.pickerProg], notif: [BarState.notifCount, BarState.notifProg], osd: [Osd.showing, BarState.osdProg],
                settings: Settings.settingsOpen, composition: Settings.composition,
                geo: { launcher: shell.geo.launcher ? shell.geo.launcher.rect : null, home: shell.geo.home ? shell.geo.home.rect : null, osd: shell.geo.osd ? shell.geo.osd.rect : null } })
        }
        // diagnostico: ler / mudar uma configuracao (valor em JSON) e ver onde cada barra ficou
        function get(key: string): string { return JSON.stringify(Settings[key]) }
        function set(key: string, json: string): string {
            try { Settings[key] = JSON.parse(json); return JSON.stringify(Settings[key]) } catch (e) { return "erro: " + e }
        }
        function barset(i: int, key: string, json: string): string {
            try { const v = JSON.parse(json); Settings.mutate(b => { b[i][key] = v }); return JSON.stringify(Settings.bars[i][key]) } catch (e) { return "erro: " + e }
        }
        // so funcoes sem argumentos (uma chamada sem o indice ja apagou a barra errada)
        // modulos de teste numa secao de uma barra (a pagina Barras faz o mesmo pela interface)
        function addmod(bar: int, sec: int, type: string): string { Settings.addModule(bar, sec, type); return JSON.stringify(Settings.bars[bar].sections[sec].modules.map(m => m.type)) }
        function rmmod(bar: int, sec: int, idx: int): string { Settings.removeModule(bar, sec, idx); return JSON.stringify(Settings.bars[bar].sections[sec].modules.map(m => m.type)) }
        function setmod(bar: int, sec: int, idx: int, key: string, json: string): string {
            try { Settings.setModuleOpt(bar, sec, idx, key, JSON.parse(json)); return JSON.stringify(Settings.bars[bar].sections[sec].modules[idx]) } catch (e) { return "erro: " + e }
        }
        function setsec(bar: int, sec: int, key: string, json: string): string {
            try { Settings.setSection(bar, sec, key, JSON.parse(json)); return JSON.stringify(Settings.bars[bar].sections[sec][key]) } catch (e) { return "erro: " + e }
        }
        function rmbar(i: int): string { if (i < 0 || i >= Settings.bars.length) return "erro: indice"; Settings.removeBar(i); return String(Settings.bars.length) }
        function call(fn: string): string {
            const f = Settings[fn]
            if (typeof f !== "function") return "erro: " + fn + " nao existe"
            if (f.length > 0) return "erro: " + fn + " precisa de argumentos"
            try { const r = f(); return r === undefined ? "ok" : JSON.stringify(r) } catch (e) { return "erro: " + e }
        }
        // diagnostico: mostra uma dica de texto como se o mouse estivesse na barra de cima (tip <texto> | tip off)
        function tip(text: string): string {
            if (text === "off") { BarState.pop = null; return "ok" }
            BarState.tipEnter(text.replace(/_/g, " "), "top", { x: 900, y: 0, w: 30, h: 34 })
            BarState.pop = BarState.popPending
            return "ok"
        }
        // diagnostico: abre um cartao de detalhes da barra de cima (calendar | resources | updates | ...) ou fecha (off)
        function popup(kind: string): string {
            BarState.pop = kind === "off" ? null : { kind: kind, opts: ({}), side: "top", type: kind, rect: { x: 900, y: 0, w: 30, h: 34 } }
            return "ok"
        }
        function color(id: string): string { return "theme " + Theme.role(id) + " · paleta " + ThemeColors.of(id) + " · t " + ThemeColors.t[id] + " · fam " + JSON.stringify(Theme.family(id)) }
        function bars(): string {
            return JSON.stringify((shell.geo.bars || []).map((b, i) => b ? { i: i, side: b.side, hidden: !!b.hidden, det: !!b.detached, full: !!b.full, t: b.t, rect: b.rect } : null))
        }
    }   // carrega o HyprSync (singleton) ja no inicio

    // mostrar / esconder todas as barras: qs -c mine ipc call bar toggle | open | close | status
    IpcHandler {
        target: "bar"
        function toggle(): string { BarState.barsOpen = !BarState.barsOpen; return BarState.barsOpen ? "aberta" : "fechada" }
        function open(): string { BarState.barsOpen = true; return "aberta" }
        function close(): string { BarState.barsOpen = false; return "fechada" }
        function status(): string { return BarState.barsOpen ? "aberta" : "fechada" }
    }

    WallpaperWindow {}
    WallpaperPicker { geo: shell.geo }
    SettingsWindow { id: settingsWin; geo: shell.geo }
    Launcher { geo: shell.geo; settingsRef: settingsWin }
    Notifications { geo: shell.geo }
    OsdWindow { geo: shell.geo }
    BarPopup {}
    RegionSelector {}
    RecFrame {}
    GameOverlay {}
    OnScreenKeyboard {}
    ScreenTranslator {}
    // servicos que precisam existir desde o inicio (singletons so nascem quando alguem os usa)
    readonly property var services: [HotCorners.actions.length, NightLight.active, SystemGuard.updates, DropShelf.files.length]
    Home { geo: shell.geo }
    PowerMenu {}
    PhotoEditor {}
    PickWindow {}
    PolkitWindow {}
    Overview {}
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

    // faixa fina em todo o comprimento de cada lado que tem barra escondida: encostar nela revela a barra (opcao "Revelar encostando em qualquer ponto da borda")
    component EdgeReveal: PanelWindow {
        id: er
        required property string side
        readonly property bool vert: side === "left" || side === "right"
        visible: Settings.barEdgeReveal && BarState.barsOpen && Settings.bars.some(b => b.side === side && b.autoHide)
        anchors {
            top: side !== "bottom"
            bottom: side !== "top"
            left: side !== "right"
            right: side !== "left"
        }
        implicitWidth: vert ? Math.max(1, Math.min(16, Settings.barHoverStrip)) : 1
        implicitHeight: vert ? 1 : Math.max(1, Math.min(16, Settings.barHoverStrip))
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "mine-edge"
        HoverHandler { onHoveredChanged: BarState.setEdge(er.side, hovered) }
    }
    EdgeReveal { side: "top" }
    EdgeReveal { side: "bottom" }
    EdgeReveal { side: "left" }
    EdgeReveal { side: "right" }

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
