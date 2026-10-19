// Area de trabalho: catalogo de widgets, edicao do layout e presets (o visual inteiro salvo com um nome).
// Os widgets ficam em Settings.desktopWidgets (cada um com id, type, fx, fy, cols, rows, opts): fx/fy = posicao de 0 a 1
// dentro da area livre da tela; cols/rows = tamanho em celulas da grade). Ao aplicar um preset, quem ja existe
// desliza/muda de forma ate o novo lugar (DesktopLayer anima x, y, largura e altura).
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool peek: false             // traz a camada para a frente das janelas (para conferir/capturar)
    property bool editing: false          // modo de edicao (arrastar, trocar tamanho, remover)
    property string dragging: ""          // id do widget sendo arrastado (para as guias)
    readonly property real cell: 150      // lado de uma celula da grade
    readonly property real gap: 14        // espaco entre celulas
    function px(n) { return n * cell + (n - 1) * gap }

    // ---------------- catalogo ----------------
    // cada widget: tamanhos (cols x rows, o primeiro e o padrao), grupo, opcoes proprias (esquema que o OptionsForm desenha)
    // tipos de opcao: seg (options [[valor, rotulo]]), switch, slider (from, to, step, suffix), text (multiline), font, color
    // ("" = automatico), image (caminho), list (uma linha por item). "when": { chave: valor | [valores] } mostra so nesse caso.
    readonly property var groups: [
        { id: "time", label: "Tempo" }, { id: "media", label: "Mídia" }, { id: "system", label: "Sistema" },
        { id: "work", label: "Produtividade" }, { id: "deco", label: "Decoração" }
    ]
    readonly property var catalog: [
        { type: "clock", group: "time", name: "Relógio", icon: "clock", desc: "Digital, flor com ponteiros, diário ou pixel; com frase opcional.",
          sizes: [[2, 1], [1, 1], [2, 2], [3, 1], [3, 2]], options: [
            { key: "style", label: "Estilo", type: "seg", def: "auto", options: [["auto", "Automático"], ["digital", "Digital"], ["analog", "Flor"], ["daily", "Diário"], ["pixel", "Pixel"]] },
            { key: "seconds", label: "Segundos", type: "switch", def: true },
            { key: "date", label: "Mostrar a data", type: "switch", def: true },
            { key: "h12", label: "12 horas (AM/PM)", type: "switch", def: false },
            { key: "font", label: "Fonte", type: "font", def: "", when: { style: ["auto", "digital", "daily"] } },
            { key: "weight", label: "Peso", type: "slider", from: 100, to: 900, step: 100, def: 700, when: { style: ["auto", "digital", "daily"] } },
            { key: "scale", label: "Tamanho do texto", type: "slider", from: 50, to: 160, step: 5, suffix: " %", def: 100 },
            { key: "vertical", label: "Hora em pé (horas sobre minutos)", type: "switch", def: false, when: { style: ["auto", "digital"] } },
            { key: "animate", label: "Animar a troca dos números", type: "switch", def: true, when: { style: ["auto", "digital", "pixel"] } },
            { key: "align", label: "Alinhamento", type: "seg", def: "center", options: [["left", "Esquerda"], ["center", "Centro"], ["right", "Direita"]], when: { style: ["auto", "digital", "daily"] } },
            { key: "sides", label: "Pétalas da flor (0 = círculo)", type: "slider", from: 0, to: 24, step: 1, def: 12, when: { style: "analog" } },
            { key: "rotate", label: "Flor girando devagar", type: "switch", def: false, when: { style: "analog" } },
            { key: "dial", label: "Mostrador", type: "seg", def: "dots", options: [["none", "Nada"], ["dots", "Pontos"], ["lines", "Traços"], ["numbers", "Números"], ["full", "Completo"]], when: { style: "analog" } },
            { key: "hourHand", label: "Ponteiro das horas", type: "seg", def: "fill", options: [["classic", "Clássico"], ["fill", "Cheio"], ["hollow", "Vazado"], ["hide", "Sem"]], when: { style: "analog" } },
            { key: "minuteHand", label: "Ponteiro dos minutos", type: "seg", def: "medium", options: [["classic", "Clássico"], ["thin", "Fino"], ["medium", "Médio"], ["bold", "Grosso"], ["hide", "Sem"]], when: { style: "analog" } },
            { key: "secondHand", label: "Ponteiro dos segundos", type: "seg", def: "dot", options: [["dot", "Bolinha"], ["line", "Linha"], ["classic", "Clássico"], ["hide", "Sem"]], when: { style: "analog" } },
            { key: "dateStyle", label: "Data no mostrador", type: "seg", def: "bubble", options: [["bubble", "Bolha"], ["border", "Borda"], ["rect", "Etiqueta"], ["hide", "Sem"]], when: { style: "analog" } },
            { key: "variant", label: "Variante", type: "seg", def: "badge", options: [["badge", "Selo"], ["morning", "Saudação"], ["script", "Manuscrito"], ["bold", "Forte"]], when: { style: "daily" } },
            { key: "pixelSize", label: "Tamanho do pixel", type: "slider", from: 3, to: 14, step: 1, suffix: " px", def: 7, when: { style: "pixel" } },
            { key: "quote", label: "Frase embaixo", type: "text", def: "" },
            { key: "quoteFont", label: "Frase na fonte do relógio", type: "switch", def: true }
          ] },
        { type: "weather", group: "time", name: "Clima", icon: "sun", desc: "Agora e a previsão (Open-Meteo, sem chave).", sizes: [[2, 1], [1, 1], [3, 1], [2, 2], [3, 2]], options: [
            { key: "show", label: "Mostrar", type: "seg", def: "auto", options: [["auto", "Conforme o tamanho"], ["now", "Só agora"], ["hours", "Próximas horas"], ["days", "Próximos dias"]] },
            { key: "details", label: "Detalhes (sensação, vento, umidade)", type: "switch", def: true }
          ] },
        { type: "world", group: "time", name: "Relógio mundial", icon: "web", desc: "Várias cidades ao mesmo tempo.", sizes: [[2, 1], [2, 2], [3, 1], [1, 2]], options: [
            { key: "zones", label: "Fusos (um por linha: Região/Cidade)", type: "list", def: ["America/Sao_Paulo", "Europe/London", "Asia/Tokyo", "America/New_York"] },
            { key: "faces", label: "Mostrar como", type: "seg", def: "digital", options: [["digital", "Digital"], ["analog", "Ponteiros"]] },
            { key: "vertical", label: "Empilhar na vertical", type: "switch", def: false }
          ] },
        { type: "calendar", group: "time", name: "Calendário", icon: "calendar", desc: "O mês, a semana ou o dia de hoje.", sizes: [[2, 2], [1, 1], [2, 1], [3, 2]], options: [
            { key: "weekStart", label: "Semana começa no", type: "seg", def: 0, options: [[0, "Domingo"], [1, "Segunda"]] },
            { key: "weekends", label: "Destacar fins de semana", type: "switch", def: true },
            { key: "weekNumbers", label: "Número da semana", type: "switch", def: false }
          ] },
        { type: "media", group: "media", name: "Mídia", icon: "music", desc: "Capa, música, controles e letra sincronizada.", sizes: [[2, 1], [3, 1], [2, 2], [1, 1], [3, 2]], options: [
            { key: "controls", label: "Controles", type: "switch", def: true },
            { key: "titles", label: "Título e artista", type: "switch", def: true },
            { key: "lyrics", label: "Letra sincronizada (lrclib.net)", type: "switch", def: false },
            { key: "artShape", label: "Forma da capa", type: "seg", def: "rounded", options: [["rounded", "Arredondada"], ["circle", "Círculo"], ["flower", "Flor"], ["square", "Quadrada"]] },
            { key: "spin", label: "Capa girando (disco)", type: "switch", def: false, when: { artShape: ["circle", "flower"] } },
            { key: "blurBg", label: "Fundo com a capa desfocada", type: "switch", def: true }
          ] },
        { type: "visualizer", group: "media", name: "Visualizador", icon: "pulse", desc: "As frequências do som tocando (precisa do cava).", sizes: [[3, 1], [2, 1], [4, 1], [2, 2]], options: [
            { key: "vstyle", label: "Estilo", type: "seg", def: "bars", options: [["bars", "Barras"], ["mirror", "Espelho"], ["wave", "Onda"], ["dots", "Pontos"], ["ring", "Anel"]] },
            { key: "bars", label: "Faixas", type: "slider", from: 8, to: 64, step: 4, def: 32 },
            { key: "colors", label: "Cores", type: "seg", def: "theme", options: [["theme", "Tema"], ["cover", "Capa da música"], ["mono", "Uma cor"]] },
            { key: "sensitivity", label: "Sensibilidade", type: "slider", from: 30, to: 300, step: 10, suffix: " %", def: 100 },
            { key: "idleHide", label: "Esconder quando nada toca", type: "switch", def: true }
          ] },
        { type: "system", group: "system", name: "Sistema", icon: "chip", desc: "CPU, memória, disco, temperatura, GPU e rede.", sizes: [[2, 1], [1, 1], [2, 2], [3, 1], [1, 2]], options: [
            { key: "metrics", label: "O que mostrar", type: "seg", def: "basic", options: [["basic", "CPU, RAM, disco"], ["hot", "CPU, temperatura, GPU"], ["all", "Tudo"]] },
            { key: "look", label: "Visual", type: "seg", def: "rings", options: [["rings", "Anéis"], ["bars", "Barras"], ["graph", "Gráfico"]] }
          ] },
        { type: "user", group: "system", name: "Usuário", icon: "account", desc: "Sua foto, saudação e o computador.", sizes: [[2, 1], [3, 1], [1, 1], [2, 2]], options: [
            { key: "greeting", label: "Saudação", type: "switch", def: true },
            { key: "info", label: "Linha de informação", type: "seg", def: "uptime", options: [["uptime", "Tempo ligado"], ["host", "Usuário@máquina"], ["kernel", "Sistema e kernel"], ["none", "Nada"]] },
            { key: "avatarShape", label: "Forma da foto", type: "seg", def: "circle", options: [["circle", "Círculo"], ["flower", "Flor"], ["rounded", "Arredondada"]] }
          ] },
        { type: "todo", group: "work", name: "Tarefas", icon: "check", desc: "Lista de afazeres que fica salva.", sizes: [[2, 2], [2, 1], [3, 2], [2, 3]], options: [
            { key: "hideDone", label: "Esconder as concluídas", type: "switch", def: false },
            { key: "progress", label: "Barra de progresso", type: "switch", def: true }
          ] },
        { type: "notes", group: "work", name: "Notas", icon: "pencil", desc: "Um bloco de notas que fica salvo.", sizes: [[2, 2], [2, 1], [3, 2], [1, 1]], options: [
            { key: "title", label: "Título", type: "text", def: "Notas" },
            { key: "mono", label: "Fonte de código", type: "switch", def: false },
            { key: "size", label: "Tamanho da letra", type: "slider", from: 10, to: 28, step: 1, suffix: " px", def: 14 }
          ] },
        { type: "timer", group: "work", name: "Timers", icon: "timer", desc: "Cronômetro, contagem regressiva e pomodoro.", sizes: [[2, 1], [2, 2], [1, 1], [3, 1]], options: [
            { key: "mode", label: "Modo", type: "seg", def: "pomodoro", options: [["pomodoro", "Pomodoro"], ["countdown", "Regressivo"], ["stopwatch", "Cronômetro"]] },
            { key: "focus", label: "Foco", type: "slider", from: 5, to: 90, step: 5, suffix: " min", def: 25, when: { mode: "pomodoro" } },
            { key: "pause", label: "Pausa", type: "slider", from: 1, to: 30, step: 1, suffix: " min", def: 5, when: { mode: "pomodoro" } },
            { key: "longPause", label: "Pausa longa", type: "slider", from: 5, to: 60, step: 5, suffix: " min", def: 15, when: { mode: "pomodoro" } },
            { key: "cycles", label: "Ciclos até a pausa longa", type: "slider", from: 2, to: 8, step: 1, def: 4, when: { mode: "pomodoro" } },
            { key: "minutes", label: "Duração", type: "slider", from: 1, to: 180, step: 1, suffix: " min", def: 10, when: { mode: "countdown" } },
            { key: "notify", label: "Avisar ao terminar", type: "switch", def: true }
          ] },
        { type: "text", group: "deco", name: "Texto", icon: "compose", desc: "Uma frase, com a fonte e a cor que quiser.", sizes: [[3, 1], [2, 1], [4, 1], [2, 2], [4, 2]], options: [
            { key: "text", label: "Texto", type: "text", multiline: true, def: "Olá, mundo" },
            { key: "font", label: "Fonte", type: "font", def: "" },
            { key: "size", label: "Tamanho", type: "slider", from: 12, to: 200, step: 2, suffix: " px", def: 64 },
            { key: "weight", label: "Peso", type: "slider", from: 100, to: 900, step: 100, def: 600 },
            { key: "italic", label: "Itálico", type: "switch", def: false },
            { key: "align", label: "Alinhamento", type: "seg", def: "center", options: [["left", "Esquerda"], ["center", "Centro"], ["right", "Direita"]] },
            { key: "shadow", label: "Sombra", type: "switch", def: true }
          ] },
        { type: "image", group: "deco", name: "Imagem", icon: "image", desc: "Foto com forma, cartão com legenda ou adesivo.", sizes: [[2, 2], [1, 1], [2, 1], [3, 2], [2, 3]], options: [
            { key: "path", label: "Imagem", type: "image", def: "" },
            { key: "kind", label: "Tipo", type: "seg", def: "photo", options: [["photo", "Foto"], ["card", "Cartão"], ["sticker", "Adesivo"]] },
            { key: "shape", label: "Forma", type: "seg", def: "rounded", options: [["rounded", "Arredondada"], ["circle", "Círculo"], ["flower", "Flor"], ["square", "Quadrada"]], when: { kind: "photo" } },
            { key: "fit", label: "Enquadrar", type: "seg", def: "crop", options: [["crop", "Preencher"], ["fit", "Inteira"]] },
            { key: "caption", label: "Legenda", type: "text", def: "", when: { kind: "card" } },
            { key: "tilt", label: "Inclinação", type: "slider", from: -30, to: 30, step: 1, suffix: "°", def: -4, when: { kind: "sticker" } },
            { key: "outline", label: "Contorno branco", type: "slider", from: 0, to: 16, step: 1, suffix: " px", def: 8, when: { kind: "sticker" } }
          ] }
    ]
    // opcoes que todo widget tem
    readonly property var commonOptions: [
        { key: "card", label: "Fundo", type: "seg", def: "auto", options: [["auto", "Padrão"], ["card", "Cartão"], ["glass", "Vidro"], ["none", "Sem fundo"]] },
        { key: "fg", label: "Cor do texto", type: "seg", def: "auto", options: [["auto", "Automática"], ["theme", "Do tema"], ["custom", "Escolher"]] },
        { key: "fgColor", label: "Cor", type: "color", def: "#ffffff", when: { fg: "custom" } },
        { key: "place", label: "Posição", type: "seg", def: "free", options: [["free", "Onde eu deixar"], ["calm", "Área calma do wallpaper"], ["busy", "Área movimentada"]] },
        { key: "lock", label: "Mostrar também na tela de bloqueio", type: "switch", def: false }
    ]
    // fundo padrao de cada tipo (relogio e texto ficam bem soltos no wallpaper)
    readonly property var cardDefaults: ({ clock: "none", text: "none", visualizer: "none", image: "none" })
    function info(type) { return catalog.find(c => c.type === type) ?? catalog[0] }
    function optionsOf(type) { return info(type).options.concat(commonOptions) }
    // valor de uma opcao com o padrao do esquema
    function opt(w, key) {
        const o = (w && w.opts) || {}
        if (o[key] !== undefined) return o[key]
        if (key === "card") return cardDefaults[w ? w.type : ""] ?? "auto"
        const d = optionsOf(w ? w.type : "").find(x => x.key === key)
        return d ? d.def : undefined
    }
    function shown(w, def) {
        if (!def.when) return true
        for (const k in def.when) { const v = opt(w, k), want = def.when[k]; if (Array.isArray(want) ? want.indexOf(v) < 0 : v !== want) return false }
        return true
    }

    function find(id) { return (Settings.desktopWidgets || []).find(w => w.id === id) ?? null }
    function mutate(fn) {
        const list = JSON.parse(JSON.stringify(Settings.desktopWidgets || []))
        fn(list)
        Settings.desktopWidgets = list
    }
    function add(type, at) {
        const c = info(type)
        const id = type + "-" + Date.now().toString(36)
        const n = (Settings.desktopWidgets || []).length
        const p = at ?? { fx: 0.04 + (n % 5) * 0.06, fy: 0.06 + (n % 5) * 0.08 }
        mutate(l => l.push({ id: id, type: type, fx: p.fx, fy: p.fy, cols: c.sizes[0][0], rows: c.sizes[0][1], opts: {} }))
        editing = true
        selected = id
        return id
    }
    function duplicate(id) {
        const w = find(id)
        if (!w) return
        const c = JSON.parse(JSON.stringify(w))
        c.id = w.type + "-" + Date.now().toString(36)
        c.fx = Math.min(1, w.fx + 0.05); c.fy = Math.min(1, w.fy + 0.06)
        mutate(l => l.push(c))
        selected = c.id
    }
    function remove(id) { if (selected === id) selected = ""; mutate(l => { const i = l.findIndex(w => w.id === id); if (i >= 0) l.splice(i, 1) }) }
    function setPos(id, fx, fy) { mutate(l => { const w = l.find(x => x.id === id); if (w) { w.fx = fx; w.fy = fy; if (w.opts && w.opts.place && w.opts.place !== "free") w.opts.place = "free" } }) }
    function setOpt(id, k, v) { mutate(l => { const w = l.find(x => x.id === id); if (w) { w.opts = w.opts || {}; w.opts[k] = v } }) }
    function setSize(id, c, r) { mutate(l => { const w = l.find(x => x.id === id); if (w) { w.cols = Math.max(1, Math.min(6, c)); w.rows = Math.max(1, Math.min(5, r)) } }) }
    function cycleSize(id) {
        mutate(l => {
            const w = l.find(x => x.id === id)
            if (!w) return
            const s = info(w.type).sizes
            const i = s.findIndex(z => z[0] === w.cols && z[1] === w.rows)
            const n = s[(i + 1) % s.length]
            w.cols = n[0]; w.rows = n[1]
        })
    }
    function bringToFront(id) { mutate(l => { const i = l.findIndex(w => w.id === id); if (i >= 0 && i < l.length - 1) l.push(l.splice(i, 1)[0]) }) }
    property string selected: ""          // widget com as opcoes abertas (inspetor na area de trabalho)
    property bool locked: false           // trava o arrasto (nao e salvo)

    // ---------------- posicao automatica e cor do texto (scripts/desk_place.py) ----------------
    // auto = { id: { fx, fy, lum } }: lugar escolhido pela analise do wallpaper e o brilho embaixo de cada widget
    property var auto: ({})
    property rect area: Qt.rect(0, 0, 1920, 1080)   // area livre (DesktopLayer informa)
    property size screenSize: Qt.size(1920, 1080)
    readonly property string analysisKey: Wallpaper.current + "|" + JSON.stringify((Settings.desktopWidgets || []).map(w => [w.id, w.cols, w.rows, w.fx, w.fy, opt(w, "place")])) + "|" + area
    onAnalysisKeyChanged: analyzeT.restart()
    Timer { id: analyzeT; interval: 400; onTriggered: root.analyze() }
    function posOf(w) {
        const a = auto[w.id]
        return (opt(w, "place") !== "free" && a && a.fx !== undefined) ? { fx: a.fx, fy: a.fy } : { fx: w.fx, fy: w.fy }
    }
    function analyze() {
        const ws = Settings.desktopWidgets || []
        if (!ws.length || Wallpaper.current === "") return
        const ar = area
        const list = ws.map(w => {
            const pw = px(w.cols), ph = px(w.rows)
            return { id: w.id, w: pw, h: ph, mode: opt(w, "place"), x: ar.x + w.fx * Math.max(0, ar.width - pw), y: ar.y + w.fy * Math.max(0, ar.height - ph) }
        })
        placer.command = ["python3", Qt.resolvedUrl("scripts/desk_place.py").toString().replace("file://", ""), Wallpaper.current, String(Math.round(screenSize.width)), String(Math.round(screenSize.height)),
            JSON.stringify({ area: [ar.x, ar.y, ar.width, ar.height], widgets: list })]
        placer.running = false
        placer.running = true
    }
    Process {
        id: placer
        stdout: StdioCollector { onStreamFinished: { try { root.auto = JSON.parse(text) } catch (e) {} } }
    }

    // ---------------- presets ----------------
    // o que um preset guarda (o "visual" do shell); o resto das configuracoes fica como esta
    readonly property var presetKeys: ["desktopWidgets", "desktopCard", "bars", "edge", "cornerRadius", "fillet", "topRadius", "outline",
        "glass", "glassOpacity", "shellBlur", "shellGrain", "userAccent", "userBarColor", "userTextColor", "desktopCardStyle", "desktopShadow",
        "themeOn", "themeMode", "themeSource", "themePreset", "themeVariant", "wallpaper"]
    // layouts prontos (so mudam os widgets): bons pontos de partida
    readonly property var builtins: [
        { name: "Painel lateral", builtin: true, icon: "view_column", data: { desktopWidgets: [
            { id: "b-clock", type: "clock", fx: 0.03, fy: 0.04, cols: 2, rows: 1, opts: { style: "digital" } },
            { id: "b-weather", type: "weather", fx: 0.03, fy: 0.28, cols: 2, rows: 1, opts: {} },
            { id: "b-media", type: "media", fx: 0.03, fy: 0.52, cols: 2, rows: 1, opts: {} },
            { id: "b-system", type: "system", fx: 0.03, fy: 0.78, cols: 2, rows: 1, opts: { look: "bars" } }] } },
        { name: "Centro", builtin: true, icon: "alignCenter", data: { desktopWidgets: [
            { id: "b-clock", type: "clock", fx: 0.5, fy: 0.22, cols: 3, rows: 1, opts: { style: "daily", variant: "morning" } },
            { id: "b-media", type: "media", fx: 0.5, fy: 0.62, cols: 3, rows: 1, opts: { lyrics: true } }] } },
        { name: "Flor", builtin: true, icon: "flower", data: { desktopWidgets: [
            { id: "b-clock", type: "clock", fx: 0.96, fy: 0.06, cols: 2, rows: 2, opts: { style: "analog", dial: "full", sides: 9 } },
            { id: "b-weather", type: "weather", fx: 0.96, fy: 0.62, cols: 2, rows: 1, opts: { card: "glass" } },
            { id: "b-user", type: "user", fx: 0.96, fy: 0.9, cols: 2, rows: 1, opts: { avatarShape: "flower", card: "glass" } }] } },
        { name: "Foco", builtin: true, icon: "target", data: { desktopWidgets: [
            { id: "b-clock", type: "clock", fx: 0.5, fy: 0.08, cols: 3, rows: 1, opts: { style: "digital", seconds: false } },
            { id: "b-timer", type: "timer", fx: 0.3, fy: 0.55, cols: 2, rows: 2, opts: { mode: "pomodoro" } },
            { id: "b-todo", type: "todo", fx: 0.7, fy: 0.55, cols: 2, rows: 2, opts: {} }] } },
        { name: "Música", builtin: true, icon: "music", data: { desktopWidgets: [
            { id: "b-media", type: "media", fx: 0.5, fy: 0.3, cols: 3, rows: 2, opts: { lyrics: true, artShape: "circle", spin: true } },
            { id: "b-visualizer", type: "visualizer", fx: 0.5, fy: 0.98, cols: 4, rows: 1, opts: { vstyle: "mirror" } }] } },
        { name: "Mesa", builtin: true, icon: "dashboard", data: { desktopWidgets: [
            { id: "b-user", type: "user", fx: 0.05, fy: 0.08, cols: 3, rows: 1, opts: {} },
            { id: "b-clock", type: "clock", fx: 0.95, fy: 0.08, cols: 2, rows: 2, opts: { style: "analog" } },
            { id: "b-notes", type: "notes", fx: 0.05, fy: 0.9, cols: 2, rows: 2, opts: {} },
            { id: "b-media", type: "media", fx: 0.5, fy: 0.92, cols: 2, rows: 2, opts: {} },
            { id: "b-calendar", type: "calendar", fx: 0.95, fy: 0.9, cols: 2, rows: 2, opts: {} }] } },
        { name: "Limpo", builtin: true, icon: "broom", data: { desktopWidgets: [] } }
    ]
    readonly property var all: builtins.concat(Settings.presets || [])
    property string lastApplied: ""

    function snapshot() {
        const d = {}
        for (const k of presetKeys) if (Settings[k] !== undefined) d[k] = JSON.parse(JSON.stringify(Settings[k]))
        return d
    }
    function uniqueName(base) {
        let n = base, i = 2
        while (all.find(p => p.name === n)) n = base + " " + i++
        return n
    }
    function save(name) {
        name = uniqueName((name || "").trim() || "Meu preset")
        const list = JSON.parse(JSON.stringify(Settings.presets || []))
        list.push({ name: name, created: Date.now(), data: snapshot() })
        Settings.presets = list
        lastApplied = name
        return name
    }
    function overwrite(name) {
        const list = JSON.parse(JSON.stringify(Settings.presets || []))
        const p = list.find(x => x.name === name)
        if (!p) return
        p.data = snapshot(); p.created = Date.now()
        Settings.presets = list
    }
    function rename(name, to) {
        to = (to || "").trim()
        if (!to || to === name || all.find(p => p.name === to)) return name
        const list = JSON.parse(JSON.stringify(Settings.presets || []))
        const p = list.find(x => x.name === name)
        if (p) p.name = to
        Settings.presets = list
        if (lastApplied === name) lastApplied = to
        return to
    }
    function removePreset(name) { Settings.presets = (Settings.presets || []).filter(p => p.name !== name) }
    function apply(name) {
        const p = all.find(x => x.name === name)
        if (!p) return
        const d = p.data || {}
        // widgets que existem nos dois lados (mesmo id) deslizam ate o novo lugar; os outros entram/saem com fade
        for (const k of Object.keys(d)) {
            if (k === "wallpaper") { if (d[k] && d[k] !== Settings.wallpaper) Settings.wallpaper = d[k]; continue }
            // presets antigos guardavam as cores calculadas (so leitura); a escolha do usuario fica em user*
            const key = ({ accent: "userAccent", barColor: "userBarColor", textColor: "userTextColor" })[k] ?? k
            if (Settings[key] === undefined) continue
            Settings[key] = JSON.parse(JSON.stringify(d[k]))
        }
        lastApplied = name
    }

    IpcHandler {
        target: "desktop"
        function edit(): void { root.editing = !root.editing }
        function preset(name: string): void { root.apply(name) }
        function toggle(): void { Settings.desktopOn = !Settings.desktopOn }
        function peek(): void { root.peek = !root.peek }
        function add(type: string): void { Settings.desktopOn = true; root.add(type) }
        function lock(): void { root.locked = !root.locked }
        function select(id: string): void { root.editing = true; root.selected = id }   // abre as opcoes de um widget
        function menu(x: int, y: int): void { DeskMenu.show(x, y, "") }                   // menu de clique direito nesse ponto
    }
}
