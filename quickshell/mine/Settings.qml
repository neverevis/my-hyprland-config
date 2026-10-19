// Configuracoes do seu shell, num lugar so (singleton: qualquer arquivo usa "Settings.edge" etc.).
// Salvas em settings.json (nesta pasta) e recarregadas sozinhas quando o arquivo muda.
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // ---- globais ----
    property alias edge: adapter.edge                   // espessura fina da moldura
    property alias cornerRadius: adapter.cornerRadius   // cantos internos da tela
    property alias fillet: adapter.fillet               // curva onde a tira comeca a subir
    property alias topRadius: adapter.topRadius         // arredondamento do topo de cada barra
    // cores manuais (guardadas) e cores efetivas: com o tema do wallpaper ligado, as efetivas vem da Palette
    property alias userBarColor: adapter.barColor
    property alias userTextColor: adapter.textColor
    property alias userAccent: adapter.accent           // destaque da janela de configuracoes
    readonly property color barColor: themeOn ? ThemeColors.background : userBarColor
    readonly property color textColor: themeOn ? ThemeColors.text : userTextColor
    readonly property color accent: themeOn ? ThemeColors.primary : userAccent
    // ---- tema a partir do wallpaper ----
    property alias themeOn: adapter.themeOn
    property alias themeMode: adapter.themeMode          // dark | light | auto (claro de dia, escuro a noite)
    property alias themeSource: adapter.themeSource      // wallpaper | preset (esquemas prontos da aba Integradas)
    property alias themePreset: adapter.themePreset      // id do esquema pronto (ver Presets.qml)
    property int clockHour: new Date().getHours()
    Timer { interval: 60000; repeat: true; running: true; onTriggered: Settings.clockHour = new Date().getHours() }
    readonly property string themeModeEff: themeMode === "auto" ? (clockHour >= 7 && clockHour < 18 ? "light" : "dark") : themeMode
    property alias themeVariant: adapter.themeVariant    // tonalspot | vibrant | expressive | fidelity | content | neutral | monochrome | rainbow | fruitsalad
    property alias themeKitty: adapter.themeKitty        // gera o tema do kitty
    property alias themeGtk: adapter.themeGtk            // cores nos apps GTK3/GTK4
    property alias themeBrave: adapter.themeBrave        // cor do tema do Brave (politica gerenciada)
    property alias themeBorders: adapter.themeBorders    // aplica as cores nas bordas das janelas do Hyprland
    property alias outline: adapter.outline             // contorno fino em todas as bordas
    property alias glass: adapter.glass
    property alias glassOpacity: adapter.glassOpacity
    // ---- blur (ver HyprSync.qml): parte global do Hyprland e parte so da moldura do Quickshell ----
    property alias blurManaged: adapter.blurManaged     // o Quickshell controla o blur global do Hyprland
    property alias blurEnabled: adapter.blurEnabled
    property alias blurSize: adapter.blurSize
    property alias blurPasses: adapter.blurPasses
    property alias blurNoise: adapter.blurNoise         // milesimos (76 = 0.076)
    property alias blurContrast: adapter.blurContrast   // centesimos
    property alias blurBrightness: adapter.blurBrightness
    property alias blurVibrancy: adapter.blurVibrancy
    property alias shellBlur: adapter.shellBlur         // desfocar o fundo da moldura
    property alias shellIgnoreAlpha: adapter.shellIgnoreAlpha   // % de opacidade abaixo da qual nao desfoca
    property alias shellGrain: adapter.shellGrain       // grao proprio da moldura (%)
    // ---- animacao de mostrar/esconder as barras (curva de bezier cubica: x1,y1,x2,y2 em centesimos) ----
    property alias animDuration: adapter.animDuration   // ms
    property alias animX1: adapter.animX1
    property alias animY1: adapter.animY1
    property alias animX2: adapter.animX2
    property alias animY2: adapter.animY2
    property alias hideDelay: adapter.hideDelay         // ms antes de esconder apos o mouse sair
    // ---- area de trabalho: widgets e presets (ver Desktop.qml) ----
    property alias desktopOn: adapter.desktopOn             // mostra os widgets da area de trabalho
    property alias desktopWidgets: adapter.desktopWidgets   // [{ id, type, fx, fy, cols, rows, opts }]
    property alias desktopCard: adapter.desktopCard         // opacidade do fundo dos cartoes (0..100)
    property alias presets: adapter.presets                 // [{ name, created, data: { chave: valor } }]
    // ---- sessao: tela de bloqueio e menu de energia ----
    property alias lockBlur: adapter.lockBlur             // 0..100: desfoque do wallpaper na tela de bloqueio
    property alias lockDim: adapter.lockDim               // 0..80: escurecimento
    property alias lockMedia: adapter.lockMedia           // mostra a musica tocando
    property alias lockSeconds: adapter.lockSeconds       // relogio com segundos
    property alias powerConfirm: adapter.powerConfirm
    // inatividade (ver Idle.qml): minutos sem uso ate cada acao (0 = desligado); idleMedia: musica tocando segura tudo
    property alias idleLock: adapter.idleLock
    property alias idleScreenOff: adapter.idleScreenOff
    property alias idleSuspend: adapter.idleSuspend
    property alias idleMedia: adapter.idleMedia     // segundos de contagem antes de sair/reiniciar/desligar (0 = na hora)
    property alias showDelay: adapter.showDelay         // ms com o mouse na borda antes de mostrar (evita abrir sem querer)
    property alias barsPanelMode: adapter.barsPanelMode // push | out | sink: o que as barras fazem quando um painel acoplado abre
    readonly property var animCurve: [animX1 / 100, animY1 / 100, animX2 / 100, animY2 / 100, 1, 1]
    // ---- wallpaper (ver Wallpaper.qml) ----
    property alias wpDir: adapter.wpDir                 // pasta de imagens
    property alias wallpaper: adapter.wallpaper         // arquivo atual
    property alias wpWipeAngle: adapter.wpWipeAngle     // direcao da cortina em graus (0 = esquerda->direita, 90 = cima->baixo)
    property alias wpParallax: adapter.wpParallax       // % da largura que os wallpapers andam junto com a cortina
    property alias wpTransition: adapter.wpTransition   // fade | slide | wipe | circle | zoom | random | none
    property alias wpDuration: adapter.wpDuration       // ms
    property alias wpEasing: adapter.wpEasing           // smooth | decel | snappy | linear
    property alias wpInterval: adapter.wpInterval       // troca automatica, em minutos (0 = desligada)
    property alias wpShuffle: adapter.wpShuffle         // ordem aleatoria na troca automatica
    property alias wpPickerSide: adapter.wpPickerSide         // bottom | top | left | right
    property alias wpPickerDocked: adapter.wpPickerDocked     // acoplado a moldura (sai da borda) ou flutuante
    property alias wpPickerOffset: adapter.wpPickerOffset     // deslocamento ao longo da borda (px)
    // ---- painel Inicio (ver Home.qml) ----
    property alias homeDocked: adapter.homeDocked
    property alias homeSide: adapter.homeSide                   // bottom | top | left | right
    property alias homeOffset: adapter.homeOffset
    property alias homeFillet: adapter.homeFillet
    property alias homeRadius: adapter.homeRadius
    property bool homeOpen: false                               // painel aberto (nao e salvo)
    // ---- notificacoes (ver Notifications.qml) ----
    property alias notifOn: adapter.notifOn                     // o Quickshell e o servidor de notificacoes
    property alias notifSide: adapter.notifSide                 // right | left | top | bottom
    property alias notifDocked: adapter.notifDocked             // cresce da moldura (acoplado) ou cartoes soltos no canto
    property alias notifCorner: adapter.notifCorner             // encostar no canto (com o ponto da borda no inicio ou no fim)
    property alias notifAnchor: adapter.notifAnchor             // start | center | end (ao longo da borda)
    property alias notifWidth: adapter.notifWidth               // largura do cartao (px)
    property alias notifMax: adapter.notifMax                   // cartoes visiveis ao mesmo tempo
    property alias notifTimeout: adapter.notifTimeout           // segundos (quando o app nao pede um tempo)
    property alias notifFillet: adapter.notifFillet
    property alias notifRadius: adapter.notifRadius
    property bool notifDnd: false                               // nao perturbe (nao e salvo)
    // ---- indicador de volume / midia (ver Osd.qml e OsdWindow.qml) ----
    property alias osdOn: adapter.osdOn
    property alias osdDocked: adapter.osdDocked                 // sai da moldura (acoplado) ou pilula flutuante
    property alias osdSide: adapter.osdSide                     // right | left | top | bottom
    property alias osdTimeout: adapter.osdTimeout               // ms na tela depois da ultima mudanca
    // ---- launcher de aplicativos (ver Launcher.qml) ----
    property alias launcherWidth: adapter.launcherWidth
    property alias launcherRows: adapter.launcherRows           // linhas de resultado visiveis
    property alias launcherIcon: adapter.launcherIcon           // tamanho dos icones (px)
    property alias launcherRadius: adapter.launcherRadius
    property alias launcherDocked: adapter.launcherDocked       // acoplado a moldura (sai da borda) ou flutuante
    property alias launcherSide: adapter.launcherSide           // bottom | top | left | right (acoplado)
    property alias launcherOffset: adapter.launcherOffset
    property alias launcherFillet: adapter.launcherFillet       // curva onde o painel acoplado encontra a moldura
    property bool settingsOpen: false                           // janela de configuracoes aberta (nao e salvo)
    property string settingsPage: "bars"                        // pagina aberta nas configuracoes (nao e salvo; paginas podem levar a outras)
    property bool launcherOpen: false                           // launcher aberto (nao e salvo)
    property alias launcherPos: adapter.launcherPos             // center | top
    property alias launcherUsage: adapter.launcherUsage         // { id do app: vezes aberto } (ordena os resultados)
    property alias wpPickerCount: adapter.wpPickerCount       // quantos wallpapers aparecem no seletor (1, 3 ou 5)
    property alias wpPickerRadius: adapter.wpPickerRadius     // arredondamento dos cantos do painel (topo)
    property alias wpPickerFillet: adapter.wpPickerFillet     // curva onde o painel encontra a moldura
    property alias wpCardRadius: adapter.wpCardRadius         // arredondamento das miniaturas
    property alias wpPickerGap: adapter.wpPickerGap           // distancia da borda quando flutuante (px)
    property bool wpPickerOpen: false                   // seletor aberto (nao e salvo)
    // ---- animacoes nomeadas: lista propria + qual usar em cada lugar (o motor fica em Motion.qml) ----
    // tudo num so objeto salvo de uma vez (evita corrida entre gravar e recarregar o arquivo):
    //   animCfg = { anims: [{ name, type: bezier|spring, x1, y1, x2, y2, duration, mass, stiffness, dampening }],
    //               use: { alvo: nome } (abrir / unico), out: { alvo: nome } (fechar; sem entrada = igual a abrir),
    //               speed: 1 (velocidade global), hypr: false (o Hyprland segue estas animacoes), hyprStyle: { windows, workspaces, layers }, migrated }
    property alias animCfg: adapter.animCfg
    readonly property var anims: (animCfg && animCfg.anims) ? animCfg.anims : []
    readonly property var animUse: (animCfg && animCfg.use) ? animCfg.use : animDefaults
    readonly property var animOut: (animCfg && animCfg.out) ? animCfg.out : ({})
    readonly property bool animMigrated: !!(animCfg && animCfg.migrated)
    function setAnimCfg(patch: var): void { animCfg = Object.assign({}, animCfg ?? {}, { anims: anims, use: animUse, migrated: animMigrated }, patch) }

    readonly property var builtinAnims: [
        { name: "Padrão", x1: 5, y1: 70, x2: 10, y2: 100, duration: 260, builtin: true },
        { name: "Desacelera", x1: 5, y1: 70, x2: 10, y2: 100, duration: 360, builtin: true },
        { name: "Suave", x1: 40, y1: 0, x2: 20, y2: 100, duration: 400, builtin: true },
        { name: "Rápida", x1: 20, y1: 80, x2: 40, y2: 100, duration: 160, builtin: true },
        { name: "Linear", x1: 0, y1: 0, x2: 100, y2: 100, duration: 300, builtin: true },
        { name: "Elástica", x1: 30, y1: 150, x2: 60, y2: 100, duration: 600, builtin: true },
        { name: "Wallpaper", x1: 40, y1: 0, x2: 20, y2: 100, duration: 900, builtin: true },
        { name: "Ênfase (entrada)", x1: 5, y1: 70, x2: 10, y2: 100, duration: 500, builtin: true },
        { name: "Ênfase (saída)", x1: 30, y1: 0, x2: 80, y2: 15, duration: 400, builtin: true },
        { name: "Saída rápida", x1: 30, y1: 0, x2: 80, y2: 15, duration: 220, builtin: true },
        { name: "Padrão M3", x1: 20, y1: 0, x2: 0, y2: 100, duration: 500, builtin: true },
        { name: "Mola", type: "spring", mass: 1, stiffness: 238, dampening: 24.2, builtin: true },
        { name: "Mola macia", type: "spring", mass: 1, stiffness: 170, dampening: 26, builtin: true },
        { name: "Mola elástica", type: "spring", mass: 1, stiffness: 320, dampening: 15, builtin: true },
        { name: "Quique", type: "spring", mass: 1, stiffness: 420, dampening: 11, builtin: true }
    ]
    // group: secao na pagina Animacoes; phases: tem abrir e fechar; hypr: folhas do Hyprland [abrir, fechar]; style: chave do estilo (hyprStyle)
    readonly property var animGroups: [
        { id: "panels", label: "Painéis", icon: "dashboard" },
        { id: "shell", label: "Barras e moldura", icon: "bars" },
        { id: "desk", label: "Área de trabalho e sessão", icon: "image" },
        { id: "hypr", label: "Janelas (Hyprland)", icon: "window" }
    ]
    readonly property var animTargets: [
        { id: "launcher", label: "Launcher de aplicativos", group: "panels", phases: true, page: "launcher" },
        { id: "home", label: "Painel Início", group: "panels", phases: true, page: "home" },
        { id: "picker", label: "Seletor de wallpaper", group: "panels", phases: true, page: "wallpaper" },
        { id: "notifications", label: "Notificações", group: "panels", phases: true, page: "notifications" },
        { id: "osd", label: "Indicador de volume", group: "panels", phases: true, page: "frame" },
        { id: "settings", label: "Janela de configurações", group: "panels", phases: true },
        { id: "power", label: "Menu de energia", group: "panels", phases: true, page: "session" },
        { id: "bars", label: "Barras (mostrar / esconder)", group: "shell", phases: true, page: "bars" },
        { id: "workspaces", label: "Workspaces na barra", group: "shell" },
        { id: "wallpaper", label: "Transição de wallpaper", group: "desk", page: "wallpaper" },
        { id: "desktop", label: "Widgets da área de trabalho", group: "desk", page: "desktop" },
        { id: "lock", label: "Tela de bloqueio", group: "desk", page: "session" },
        { id: "hyprWindows", label: "Abrir e fechar janelas", group: "hypr", phases: true, hypr: ["windowsIn", "windowsOut"], style: "windows" },
        { id: "hyprMove", label: "Mover e redimensionar", group: "hypr", hypr: ["windowsMove"] },
        { id: "hyprWorkspaces", label: "Trocar de workspace", group: "hypr", hypr: ["workspaces"], style: "workspaces" },
        { id: "hyprLayers", label: "Camadas flutuantes (launcher solto, menus)", group: "hypr", phases: true, hypr: ["layersIn", "layersOut"], style: "layers" }
    ]
    readonly property var animDefaults: ({ bars: "Padrão", picker: "Desacelera", wallpaper: "Wallpaper", workspaces: "Rápida", launcher: "Desacelera", notifications: "Desacelera", home: "Desacelera", power: "Desacelera", lock: "Desacelera", desktop: "Suave",
        osd: "Desacelera", settings: "Ênfase (entrada)", hyprWindows: "Ênfase (entrada)", hyprMove: "Padrão M3", hyprWorkspaces: "Padrão M3", hyprLayers: "Ênfase (entrada)" })
    // saida: so onde a fechada sempre foi diferente (o resto fecha igual abre, como antes)
    readonly property var animOutDefaults: ({ settings: "Ênfase (saída)", hyprWindows: "Saída rápida", hyprLayers: "Ênfase (saída)" })
    readonly property var hyprStyleDefaults: ({ windows: "popin 85%", workspaces: "slide", layers: "slide" })
    readonly property var hyprStyleOptions: ({
        windows: [["popin 85%", "Surgir"], ["slide", "Deslizar"], ["gnomed", "GNOME"]],
        workspaces: [["slide", "Deslizar"], ["slidevert", "Vertical"], ["slidefade 20%", "Deslizar + fade"], ["fade", "Fade"]],
        layers: [["slide", "Deslizar"], ["popin 90%", "Surgir"], ["fade", "Fade"]]
    })
    function targetInfo(id: string): var { return animTargets.find(t => t.id === id) ?? null }

    function allAnims(): var { return builtinAnims.concat(anims) }
    function findAnim(name: string): var { return allAnims().find(a => a.name === name) ?? null }
    // compatibilidade: animacao de abrir/unica de um lugar (ver Motion.of)
    function animOf(target: string): var { return Motion.of(target, false) }
    function setUse(target: string, name: string): void { const u = Object.assign({}, animUse); u[target] = name; setAnimCfg({ use: u }) }
    // fechar: name vazio = igual a abrir
    function setOut(target: string, name: string): void { const o = Object.assign({}, animOut); o[target] = name; setAnimCfg({ out: o }) }
    function uniqueAnimName(base: string): string {
        let n = base, i = 2
        while (findAnim(n)) n = base + " " + i++
        return n
    }
    function addAnim(from: var): string {
        const a = Object.assign({}, from)
        delete a.builtin
        a.name = uniqueAnimName((from.name ?? "Animação") + " (cópia)")
        setAnimCfg({ anims: anims.concat([a]) })
        return a.name
    }
    function setAnim(name: string, key: string, value: var): void {
        const list = JSON.parse(JSON.stringify(anims))
        const a = list.find(x => x.name === name)
        if (!a) return
        a[key] = value
        setAnimCfg({ anims: list })
    }
    function setAnimMany(name: string, vals: var): void {
        const list = JSON.parse(JSON.stringify(anims))
        const a = list.find(x => x.name === name)
        if (!a) return
        Object.assign(a, vals)
        setAnimCfg({ anims: list })
    }
    function renameAnim(oldName: string, newName: string): string {
        newName = newName.trim()
        if (newName === "" || newName === oldName || findAnim(newName)) return oldName
        const list = JSON.parse(JSON.stringify(anims))
        const a = list.find(x => x.name === oldName)
        if (!a) return oldName
        a.name = newName
        const u = Object.assign({}, animUse), o = Object.assign({}, animOut)
        for (const k in u) if (u[k] === oldName) u[k] = newName
        for (const k in o) if (o[k] === oldName) o[k] = newName
        setAnimCfg({ anims: list, use: u, out: o })
        return newName
    }
    function removeAnim(name: string): void {
        const u = Object.assign({}, animUse), o = Object.assign({}, animOut)
        for (const k in u) if (u[k] === name) u[k] = animDefaults[k] ?? "Padrão"
        for (const k in o) if (o[k] === name) delete o[k]
        setAnimCfg({ anims: anims.filter(a => a.name !== name), use: u, out: o })
    }

    // uma vez: leva a animacao global antiga (curva/duracao unicas) para uma animacao nomeada
    function migrateAnims(): void {
        if (animMigrated) return
        const list = JSON.parse(JSON.stringify(anims))
        const use = Object.assign({}, animDefaults)
        const std = builtinAnims[0]
        if (animX1 !== std.x1 || animY1 !== std.y1 || animX2 !== std.x2 || animY2 !== std.y2 || animDuration !== std.duration) {
            list.push({ name: "Minha curva", x1: animX1, y1: animY1, x2: animX2, y2: animY2, duration: animDuration })
            use.bars = "Minha curva"
        }
        setAnimCfg({ anims: list, use: use, migrated: true })
    }

    // ---- composicao: cada parte acoplada a moldura (cresce dela) ou solta (superficie propria) ----
    readonly property var compParts: [
        { id: "bars", label: "Barras", icon: "bars", page: "bars", hint: "Todas as barras (cada uma também pode ser ajustada na página Barras)." },
        { id: "launcher", label: "Launcher", icon: "apps", page: "launcher" },
        { id: "home", label: "Painel Início", icon: "dashboard", page: "home" },
        { id: "picker", label: "Seletor de wallpaper", icon: "wallpaper", page: "wall" },
        { id: "notifications", label: "Notificações", icon: "bell", page: "notifications" },
        { id: "osd", label: "Indicador de volume", icon: "volume", page: "frame" }
    ]
    function partDocked(id: string): bool {
        if (id === "bars") { const b = (bars || []).filter(x => !x.full); return b.length === 0 || b.some(x => !x.detached) }
        return id === "launcher" ? launcherDocked : id === "home" ? homeDocked : id === "picker" ? wpPickerDocked
            : id === "notifications" ? notifDocked : id === "osd" ? osdDocked : true
    }
    function setPartDocked(id: string, on: bool): void {
        if (id === "bars") mutate(b => { for (const x of b) if (!x.full) x.detached = !on })
        else if (id === "launcher") launcherDocked = on
        else if (id === "home") homeDocked = on
        else if (id === "picker") wpPickerDocked = on
        else if (id === "notifications") notifDocked = on
        else if (id === "osd") osdDocked = on
    }
    // integrated | independent | mixed
    readonly property string composition: {
        const st = compParts.map(p => partDocked(p.id))
        return st.every(x => x) ? "integrated" : st.every(x => !x) ? "independent" : "mixed"
    }
    function applyComposition(mode: string): void { for (const p of compParts) setPartDocked(p.id, mode === "integrated") }

    // ---- barras: lista de {side, width, offset, height, full, modules:[{type, ...}]} ----
    property alias bars: adapter.bars

    readonly property var moduleTypes: [
        { type: "clock", label: "Relógio" },
        { type: "workspaces", label: "Workspaces" },
        { type: "window", label: "Janela ativa" },
        { type: "cpu", label: "CPU" },
        { type: "memory", label: "Memória" },
        { type: "volume", label: "Volume" },
        { type: "tray", label: "Bandeja" },
        { type: "palette", label: "Cores do tema" },
        { type: "power", label: "Energia" },
        { type: "text", label: "Texto" }
    ]

    function reset(): void {
        adapter.edge = 6
        adapter.cornerRadius = 16
        adapter.fillet = 10
        adapter.topRadius = 12
        adapter.barColor = "#1b1b22"
        adapter.textColor = "#e6e1e9"
        adapter.accent = "#bb9af7"
        adapter.outline = true
        adapter.glass = false
        adapter.glassOpacity = 60
        adapter.blurManaged = false
        adapter.blurEnabled = true
        adapter.blurSize = 3
        adapter.blurPasses = 4
        adapter.blurNoise = 76
        adapter.blurContrast = 89
        adapter.blurBrightness = 103
        adapter.blurVibrancy = 18
        adapter.shellBlur = true
        adapter.shellIgnoreAlpha = 5
        adapter.shellGrain = 0
        adapter.animDuration = 260
        adapter.animX1 = 5
        adapter.animY1 = 70
        adapter.animX2 = 10
        adapter.animY2 = 100
        adapter.hideDelay = 450
        adapter.showDelay = 0
        adapter.lockBlur = 100
        adapter.lockDim = 32
        adapter.lockMedia = true
        adapter.lockSeconds = false
        adapter.powerConfirm = 3
        adapter.idleLock = 0
        adapter.idleScreenOff = 0
        adapter.idleSuspend = 0
        adapter.idleMedia = true
        adapter.barsPanelMode = "push"
        adapter.wpDir = "~/Imagens/Wallpapers"
        adapter.wpTransition = "circle"
        adapter.wpParallax = 20
        adapter.wpWipeAngle = 0
        adapter.wpDuration = 900
        adapter.wpEasing = "smooth"
        adapter.wpInterval = 0
        adapter.wpShuffle = true
        adapter.wpPickerSide = "bottom"
        adapter.wpPickerDocked = true
        adapter.wpPickerOffset = 0
        adapter.wpPickerGap = 14
        adapter.wpPickerCount = 5
        adapter.homeDocked = true
        adapter.homeSide = "bottom"
        adapter.homeOffset = 0
        adapter.homeFillet = 13
        adapter.homeRadius = 14
        adapter.notifOn = true
        adapter.notifSide = "right"
        adapter.notifAnchor = "start"
        adapter.notifCorner = false
        adapter.notifDocked = true
        adapter.notifWidth = 360
        adapter.notifMax = 4
        adapter.notifTimeout = 6
        adapter.notifFillet = 12
        adapter.notifRadius = 14
        adapter.osdOn = true
        adapter.osdDocked = true
        adapter.osdSide = "right"
        adapter.osdTimeout = 1400
        adapter.launcherWidth = 640
        adapter.launcherRows = 7
        adapter.launcherIcon = 32
        adapter.launcherRadius = 22
        adapter.launcherPos = "center"
        adapter.launcherDocked = true
        adapter.launcherSide = "bottom"
        adapter.launcherOffset = 0
        adapter.launcherFillet = 12
        adapter.wpPickerRadius = 12
        adapter.wpPickerFillet = 10
        adapter.wpCardRadius = 14
        adapter.themeOn = false
        adapter.themeMode = "dark"
        adapter.themeSource = "wallpaper"
        adapter.themePreset = "mocha"
        adapter.themeKitty = true
        adapter.themeGtk = true
        adapter.themeBrave = true
        adapter.themeVariant = "tonalspot"
        adapter.themeBorders = true
        adapter.animCfg = { anims: [], use: animDefaults, out: {}, speed: 1, hypr: false, migrated: true }
        adapter.bars = [defaultBar("bottom")]
    }

    function defaultSection(name: string): var {
        return { name: name, anchor: "center", align: "center", width: 0, offset: 0, spacing: 14, modules: [] }
    }
    function defaultBar(side: string): var {
        const sec = defaultSection("Centro")
        sec.modules = [{ type: "clock", format: "ddd dd MMM   HH:mm" }]
        return { side: side, size: 30, pos: 50, height: 34, full: false, autoHide: false, sections: [sec] }
    }
    // largura e posicao das barras em % do lado da tela (L = comprimento do lado em px).
    // barras antigas guardavam em px (width/offset/corner): convertidas na hora, ate a primeira edicao
    function barSize(b: var, L: real): real { return b.size ?? Math.max(3, Math.min(100, (b.width ?? 520) / Math.max(1, L) * 100)) }
    function barPos(b: var, L: real): real {
        if (b.pos !== undefined) return b.pos
        if (b.corner === "start") return 0
        if (b.corner === "end") return 100
        const travel = L - (barSize(b, L) / 100 * L)
        return travel > 1 ? Math.max(1.5, Math.min(98.5, 50 + (b.offset ?? 0) / travel * 100)) : 50
    }
    // barras antigas guardavam "modules" direto na barra: viram uma secao central
    function sectionsOf(bar: var): var {
        if (!bar) return []
        return bar.sections ?? [Object.assign(defaultSection("Centro"), { modules: bar.modules ?? [] })]
    }

    // ---- edicao das barras (sempre troca a lista inteira, para o QML notar a mudanca) ----
    function mutate(fn: var): void {
        const copy = JSON.parse(JSON.stringify(adapter.bars))
        for (const b of copy) if (!b.sections) { b.sections = sectionsOf(b); delete b.modules }   // migracao
        fn(copy)
        adapter.bars = copy
    }
    function setBar(i: int, key: string, value: var): void { mutate(b => { if (b[i]) b[i][key] = value }) }
    function addBar(side: string): void { mutate(b => b.push(defaultBar(side))) }
    function removeBar(i: int): void { mutate(b => b.splice(i, 1)) }
    // prioridade = ordem da lista (a primeira ganha a disputa por espaco): d = -1 sobe, +1 desce
    function moveBar(i: int, d: int): void { mutate(b => { const j = i + d; if (j < 0 || j >= b.length) return; const t = b[i]; b[i] = b[j]; b[j] = t }) }
    // depuracao visual na propria barra enquanto a pagina Barras esta aberta (nao e salvo)
    property int barDebugBar: -1
    property int barDebugSec: -1

    function addSection(i: int): void { mutate(b => { const n = b[i].sections.length; b[i].sections.push(Object.assign(defaultSection("Seção " + (n + 1)), { anchor: n % 2 === 0 ? "start" : "end" })) }) }
    function removeSection(i: int, si: int): void { mutate(b => { if (b[i].sections.length > 1) b[i].sections.splice(si, 1) }) }
    function setSection(i: int, si: int, key: string, value: var): void { mutate(b => { if (b[i].sections[si]) b[i].sections[si][key] = value }) }

    function addModule(i: int, si: int, type: string): void {
        mutate(b => {
            const m = { type: type }
            if (type === "clock") m.format = "ddd dd MMM   HH:mm"
            if (type === "text") m.text = "texto"
            b[i].sections[si].modules.push(m)
        })
    }
    function removeModule(i: int, si: int, j: int): void { mutate(b => b[i].sections[si].modules.splice(j, 1)) }
    function moveModule(i: int, si: int, j: int, d: int): void {
        mutate(b => {
            const m = b[i].sections[si].modules, k = j + d
            if (k < 0 || k >= m.length) return
            const t = m[j]; m[j] = m[k]; m[k] = t
        })
    }
    function moveModuleTo(i: int, si: int, j: int, target: int): void {
        mutate(b => {
            if (target < 0 || target >= b[i].sections.length || target === si) return
            const m = b[i].sections[si].modules.splice(j, 1)[0]
            b[i].sections[target].modules.push(m)
        })
    }
    function setModuleOpt(i: int, si: int, j: int, key: string, value: var): void { mutate(b => { b[i].sections[si].modules[j][key] = value }) }

    // gravacao agrupada: varias mudancas seguidas (aplicar composicao, preset...) viram uma escrita so; enquanto ha
    // mudanca local esperando para gravar, uma recarga do arquivo (vinda de uma escrita anterior) nao atropela ela
    Timer { id: saveT; interval: 80; onTriggered: fv.writeAdapter() }
    FileView {
        id: fv
        path: Quickshell.env("HOME") + "/.config/quickshell/mine/settings.json"
        watchChanges: true
        onFileChanged: if (!saveT.running) reload()
        onLoaded: root.migrateAnims()
        onAdapterUpdated: saveT.restart()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter()   // primeira vez: cria o arquivo com os padroes
        }

        JsonAdapter {
            id: adapter
            property int edge: 6
            property int cornerRadius: 16
            property int fillet: 10
            property int topRadius: 12
            property string barColor: "#1b1b22"
            property string textColor: "#e6e1e9"
            property string accent: "#bb9af7"
            property bool outline: true
            property bool glass: false
            property int glassOpacity: 60
            property bool blurManaged: false
            property bool blurEnabled: true
            property int blurSize: 3
            property int blurPasses: 4
            property int blurNoise: 76
            property int blurContrast: 89
            property int blurBrightness: 103
            property int blurVibrancy: 18
            property bool shellBlur: true
            property int shellIgnoreAlpha: 5
            property int shellGrain: 0
            property int animDuration: 260
            property int animX1: 5
            property int animY1: 70
            property int animX2: 10
            property int animY2: 100
            property int hideDelay: 450
            property int showDelay: 0
            property bool desktopOn: true
            property var desktopWidgets: []
            property int desktopCard: 72
            property var presets: []
            property int lockBlur: 100
            property int lockDim: 32
            property bool lockMedia: true
            property bool lockSeconds: false
            property int powerConfirm: 3
            property int idleLock: 0
            property int idleScreenOff: 0
            property int idleSuspend: 0
            property bool idleMedia: true
            property string barsPanelMode: "push"
            property string wpDir: "~/Imagens/Wallpapers"
            property string wallpaper: ""
            property string wpTransition: "circle"
            property int wpParallax: 20
            property int wpWipeAngle: 0
            property int wpDuration: 900
            property string wpEasing: "smooth"
            property int wpInterval: 0
            property bool wpShuffle: true
            property string wpPickerSide: "bottom"
            property bool wpPickerDocked: true
            property int wpPickerOffset: 0
            property int wpPickerGap: 14
            property int wpPickerCount: 5
            property bool homeDocked: true
            property string homeSide: "bottom"
            property int homeOffset: 0
            property int homeFillet: 13
            property int homeRadius: 14
            property bool notifOn: true
            property string notifSide: "right"
            property string notifAnchor: "start"
            property bool notifCorner: false
            property bool notifDocked: true
            property int notifWidth: 360
            property int notifMax: 4
            property int notifTimeout: 6
            property int notifFillet: 12
            property int notifRadius: 14
            property bool osdOn: true
            property bool osdDocked: true
            property string osdSide: "right"
            property int osdTimeout: 1400
            property int launcherWidth: 640
            property int launcherRows: 7
            property int launcherIcon: 32
            property int launcherRadius: 22
            property string launcherPos: "center"
            property bool launcherDocked: true
            property string launcherSide: "bottom"
            property int launcherOffset: 0
            property int launcherFillet: 13
            property var launcherUsage: ({})
            property int wpPickerRadius: 11
            property int wpPickerFillet: 13
            property int wpCardRadius: 14
            property bool themeKitty: true
            property bool themeGtk: true
            property bool themeBrave: true
            property bool themeOn: false
            property string themeMode: "dark"
            property string themeSource: "wallpaper"
            property string themePreset: "mocha"
            property string themeVariant: "tonalspot"
            property bool themeBorders: true
            property var animCfg: ({ anims: [], use: { bars: "Padrão", picker: "Desacelera", wallpaper: "Wallpaper", workspaces: "Rápida" }, migrated: false })
            property var bars: [{ side: "bottom", width: 520, offset: 0, height: 34, full: false, autoHide: false, modules: [{ type: "clock", format: "ddd dd MMM   HH:mm" }] }]
        }
    }
}
