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
    // secoes do formulario: "sec" agrupa as opcoes seguidas com o mesmo nome (o icone vem de secIcons); "icon" e "desc" por
    // opcao; nas opcoes seg o terceiro item e o icone; "preview": true desenha cada escolha com o proprio widget em miniatura
    readonly property var secIcons: ({ "Estilo": "palette", "Hora e data": "clock", "Números": "font", "Flor": "flowerOutline", "Ponteiros": "clockOutline",
        "Diário": "calendar", "Pixel": "grid", "Frase": "quoteClose", "Tela de bloqueio": "lockClock", "Mostrar": "eye", "Cidades": "earth",
        "Mês": "calendarWeek", "Capa": "album", "Conteúdo": "listChecks", "Som": "sineWave", "Medidas": "gauge", "Perfil": "accountCircle",
        "Lista": "checkbox", "Bloco": "noteText", "Tempos": "timer", "Texto": "text", "Fonte": "font", "Imagem": "image", "Conversão": "fileSwap",
        "Visual": "paint", "Posição": "cursorMove", "Forma": "shape", "Enquadramento": "crop", "Adesivo": "sticker" })
    readonly property var catalog: [
        { type: "clock", group: "time", name: "Relógio", icon: "clock", desc: "Digital, flor com ponteiros, diário ou pixel; com frase opcional.",
          sizes: [[2, 1], [1, 1], [2, 2], [3, 1], [3, 2]], options: [
            { sec: "Estilo", key: "style", label: "Estilo", type: "seg", preview: true, def: "auto", options: [["auto", "Automático", "auto"], ["digital", "Digital", "clockDigital"], ["analog", "Flor", "flowerOutline"], ["daily", "Diário", "calendar"], ["pixel", "Pixel", "grid"]] },
            { sec: "Hora e data", key: "seconds", label: "Segundos", icon: "timer", type: "switch", def: true },
            { sec: "Hora e data", key: "date", label: "Mostrar a data", icon: "calendar", type: "switch", def: true },
            { sec: "Hora e data", key: "h12", label: "12 horas (AM/PM)", icon: "clockOutline", type: "switch", def: false },
            { sec: "Números", key: "font", label: "Fonte", type: "font", def: "", when: { style: ["auto", "digital", "daily"] } },
            { sec: "Números", key: "weight", label: "Peso", icon: "bold", type: "slider", from: 100, to: 900, step: 100, def: 700, when: { style: ["auto", "digital", "daily"] } },
            { sec: "Números", key: "scale", label: "Tamanho", icon: "textSize", type: "slider", from: 50, to: 160, step: 5, suffix: " %", def: 100 },
            { sec: "Números", key: "fwidth", label: "Largura da fonte", icon: "resize", desc: "Só em fontes variáveis com eixo de largura (ex.: Google Sans Flex, Roboto Flex).", type: "slider", from: 25, to: 151, step: 1, suffix: " %", def: 100, when: { style: ["auto", "digital", "daily"] } },
            { sec: "Números", key: "fround", label: "Arredondamento da fonte", icon: "squareRounded", desc: "Só em fontes variáveis com eixo de arredondamento (ex.: Google Sans Flex).", type: "slider", from: 0, to: 100, step: 5, suffix: " %", def: 0, when: { style: ["auto", "digital", "daily"] } },
            { sec: "Números", key: "vertical", label: "Hora em pé (horas sobre minutos)", icon: "alignVCenter", type: "switch", def: false, when: { style: ["auto", "digital"] } },
            { sec: "Números", key: "animate", label: "Números rolando ao trocar", icon: "animation", type: "switch", def: true, when: { style: ["auto", "digital", "pixel"] } },
            { sec: "Números", key: "align", label: "Alinhamento", type: "seg", def: "center", options: [["auto", "Pelo lugar", "magic"], ["left", "Esquerda", "alignLeft"], ["center", "Centro", "alignCenter"], ["right", "Direita", "alignRight"]], when: { style: ["auto", "digital", "daily"] } },
            { sec: "Flor", key: "sides", label: "Pétalas (0 = círculo)", icon: "flowerOutline", type: "slider", from: 0, to: 24, step: 1, def: 12, when: { style: "analog" } },
            { sec: "Flor", key: "dial", label: "Mostrador", type: "seg", preview: true, def: "dots", options: [["none", "Nada"], ["dots", "Pontos"], ["lines", "Traços"], ["numbers", "Números"], ["full", "Completo"]], when: { style: "analog" } },
            { sec: "Flor", key: "centerTime", label: "Horas no meio", icon: "numeric", desc: "Os números da hora no centro da flor, rolando ao trocar.", type: "switch", def: false, when: { style: "analog" } },
            { sec: "Flor", key: "hourMarks", label: "Disco com marcas das horas", icon: "dotsCircle", desc: "Um disco no meio com as 12 marcas.", type: "switch", def: false, when: { style: "analog" } },
            { sec: "Flor", key: "dateStyle", label: "Data no mostrador", type: "seg", preview: true, def: "bubble", options: [["bubble", "Bolha"], ["border", "Borda"], ["rect", "Etiqueta"], ["hide", "Sem"]], when: { style: "analog" } },
            { sec: "Flor", key: "rotate", label: "Flor girando devagar", icon: "rotate", type: "switch", def: false, when: { style: "analog" } },
            { sec: "Ponteiros", key: "hourHand", label: "Horas", type: "seg", preview: true, def: "fill", options: [["classic", "Clássico"], ["fill", "Cheio"], ["hollow", "Vazado"], ["hide", "Sem"]], when: { style: "analog" } },
            { sec: "Ponteiros", key: "minuteHand", label: "Minutos", type: "seg", preview: true, def: "medium", options: [["classic", "Clássico"], ["thin", "Fino"], ["medium", "Médio"], ["bold", "Grosso"], ["hide", "Sem"]], when: { style: "analog" } },
            { sec: "Ponteiros", key: "secondHand", label: "Segundos", type: "seg", preview: true, def: "dot", options: [["dot", "Bolinha"], ["line", "Linha"], ["classic", "Clássico"], ["hide", "Sem"]], when: { style: "analog" } },
            { sec: "Diário", key: "variant", label: "Variante", type: "seg", preview: true, def: "badge", options: [["badge", "Selo"], ["morning", "Saudação"], ["script", "Manuscrito"], ["bold", "Forte"]], when: { style: "daily" } },
            { sec: "Pixel", key: "orientation", label: "Orientação", icon: "swap_vertical", type: "seg", def: "auto", options: [["auto", "Automática", "auto"], ["vertical", "Vertical", "swap_vertical"], ["horizontal", "Horizontal", "swap_horizontal"]], when: { style: "pixel" } },
            { sec: "Pixel", key: "pixelSize", label: "Tamanho do pixel", icon: "grid", type: "slider", from: 3, to: 14, step: 1, suffix: " px", def: 7, when: { style: "pixel" } },
            { sec: "Frase", key: "quote", label: "Frase embaixo", icon: "quoteClose", type: "text", def: "" },
            { sec: "Frase", key: "quoteFont", label: "Frase na fonte do relógio", icon: "font", type: "switch", def: true },
            { sec: "Tela de bloqueio", key: "lockStyle", label: "Estilo na tela de bloqueio", type: "seg", preview: true, previewAs: "style", def: "same", options: [["same", "O mesmo", "check"], ["digital", "Digital", "clockDigital"], ["analog", "Flor", "flowerOutline"], ["daily", "Diário", "calendar"], ["pixel", "Pixel", "grid"]], when: { lock: true } }
          ] },
        { type: "weather", group: "time", name: "Clima", icon: "sun", desc: "Agora e a previsão (Open-Meteo, sem chave).", sizes: [[2, 1], [1, 1], [3, 1], [2, 2], [3, 2]], options: [
            { sec: "Mostrar", key: "show", label: "Conteúdo", type: "seg", preview: true, def: "auto", options: [["auto", "Conforme o tamanho", "auto"], ["now", "Só agora", "cloudSun"], ["tiles", "Blocos de detalhes", "view_grid"], ["hours", "Próximas horas", "clockOutline"], ["days", "Próximos dias", "calendarWeek"]] },
            { sec: "Mostrar", key: "details", label: "Detalhes (sensação, vento, umidade)", icon: "info", type: "switch", def: true }
          ] },
        { type: "world", group: "time", name: "Relógio mundial", icon: "web", desc: "Várias cidades ao mesmo tempo.", sizes: [[2, 1], [2, 2], [3, 1], [1, 2]], options: [
            { sec: "Cidades", key: "zones", label: "Fusos (um por linha: Região/Cidade; ou use a engrenagem do widget)", type: "list", def: ["America/Sao_Paulo", "Europe/London", "Asia/Tokyo", "America/New_York"] },
            { sec: "Visual", key: "faces", label: "Mostrar como", type: "seg", preview: true, def: "digital", options: [["digital", "Digital", "clockDigital"], ["analog", "Ponteiros", "clockOutline"]] },
            { sec: "Visual", key: "vertical", label: "Empilhar na vertical", icon: "alignVCenter", type: "switch", def: false }
          ] },
        { type: "calendar", group: "time", name: "Calendário", icon: "calendar", desc: "O mês, a semana ou o dia de hoje.", sizes: [[2, 2], [1, 1], [2, 1], [3, 2]], options: [
            { sec: "Mês", key: "weekStart", label: "Semana começa no", type: "seg", def: 0, options: [[0, "Domingo"], [1, "Segunda"]] },
            { sec: "Mês", key: "weekends", label: "Destacar fins de semana", icon: "calendarWeek", type: "switch", def: true },
            { sec: "Mês", key: "weekNumbers", label: "Número da semana", icon: "numeric", type: "switch", def: false }
          ] },
        { type: "media", group: "media", name: "Mídia", icon: "music", desc: "Capa, música, controles e letra sincronizada.", sizes: [[2, 1], [3, 1], [2, 2], [1, 1], [3, 2]], options: [
            { sec: "Conteúdo", key: "controls", label: "Controles", icon: "play", type: "switch", def: true },
            { sec: "Conteúdo", key: "titles", label: "Título e artista", icon: "text", type: "switch", def: true },
            { sec: "Conteúdo", key: "lyrics", label: "Letra sincronizada", icon: "quoteClose", desc: "Busca no lrclib.net pelo nome da música.", type: "switch", def: false },
            { sec: "Capa", key: "artShape", label: "Forma da capa", type: "seg", preview: true, def: "rounded", options: Shapes.list },
            { sec: "Capa", key: "spin", label: "Capa girando (disco)", icon: "album", type: "switch", def: false, when: { artShape: ["circle", "flower", "sunny", "burst", "softburst", "clover4", "clover8", "puffy", "pixel"] } },
            { sec: "Capa", key: "blurBg", label: "Fundo com a capa desfocada", icon: "blur", type: "switch", def: true }
          ] },
        { type: "visualizer", group: "media", name: "Visualizador", icon: "pulse", desc: "As frequências do som tocando (precisa do cava).", sizes: [[3, 1], [2, 1], [4, 1], [2, 2]], options: [
            { sec: "Estilo", key: "vstyle", label: "Estilo", type: "seg", def: "bars", options: [["bars", "Barras", "equalizer"], ["mirror", "Espelho", "swap_vertical"], ["wave", "Onda", "sineWave"], ["dots", "Pontos", "dotsCircle"], ["ring", "Anel", "circleOutline"], ["aurora", "Aurora", "wave2"]] },
            { sec: "Estilo", key: "colors", label: "Cores", type: "seg", def: "theme", options: [["theme", "Tema", "palette"], ["cover", "Capa da música", "album"], ["mono", "Uma cor", "swatch"]] },
            { sec: "Som", key: "bars", label: "Faixas", icon: "equalizer", type: "slider", from: 8, to: 64, step: 4, def: 32 },
            { sec: "Som", key: "sensitivity", label: "Sensibilidade", icon: "gauge", type: "slider", from: 30, to: 300, step: 10, suffix: " %", def: 100 },
            { sec: "Som", key: "idleHide", label: "Esconder quando nada toca", icon: "eyeOff", type: "switch", def: true }
          ] },
        { type: "system", group: "system", name: "Sistema", icon: "chip", desc: "CPU, memória, disco, temperatura, GPU e rede.", sizes: [[2, 1], [1, 1], [2, 2], [3, 1], [1, 2]], options: [
            { sec: "Medidas", key: "metrics", label: "O que mostrar", type: "seg", def: "basic", options: [["basic", "CPU, RAM, disco", "chip"], ["hot", "CPU, temperatura, GPU", "thermo"], ["all", "Tudo", "dashboard"]] },
            { sec: "Visual", key: "look", label: "Visual", type: "seg", preview: true, def: "tiles", options: [["tiles", "Cartões", "dashboard"], ["rings", "Anéis", "chartDonut"], ["bars", "Barras", "bars"], ["graph", "Gráfico", "chart"]] },
            { sec: "Visual", key: "vertical", label: "Empilhar na vertical", icon: "alignVCenter", type: "switch", def: false, when: { look: "tiles" } }
          ] },
        { type: "user", group: "system", name: "Usuário", icon: "account", desc: "Sua foto, saudação e o computador.", sizes: [[2, 1], [3, 1], [1, 1], [2, 2], [1, 2], [2, 3]], options: [
            { sec: "Perfil", key: "greeting", label: "Saudação", icon: "greeting", type: "switch", def: true },
            { sec: "Perfil", key: "info", label: "Linha de informação", type: "seg", def: "uptime", options: [["uptime", "Tempo ligado", "timer"], ["host", "Usuário@máquina", "desktop"], ["kernel", "Sistema e kernel", "linux"], ["none", "Nada", "close"]] },
            { sec: "Perfil", key: "buttons", label: "Botões de atalho (bloquear, ajustes, energia)", icon: "lock", type: "switch", def: true },
            { sec: "Perfil", key: "avatarShape", label: "Forma da foto", type: "seg", preview: true, def: "circle", options: Shapes.list }
          ] },
        { type: "todo", group: "work", name: "Tarefas", icon: "check", desc: "Lista de afazeres que fica salva.", sizes: [[2, 2], [2, 1], [3, 2], [2, 3]], options: [
            { sec: "Lista", key: "hideDone", label: "Esconder as concluídas", icon: "eyeOff", type: "switch", def: false },
            { sec: "Lista", key: "progress", label: "Barra de progresso", icon: "progressCheck", type: "switch", def: true }
          ] },
        { type: "notes", group: "work", name: "Notas", icon: "pencil", desc: "Um bloco de notas que fica salvo.", sizes: [[2, 2], [2, 1], [3, 2], [1, 1]], options: [
            { sec: "Bloco", key: "title", label: "Título", icon: "tag", type: "text", def: "Notas" },
            { sec: "Bloco", key: "mono", label: "Fonte de código", icon: "keyboard", type: "switch", def: false },
            { sec: "Bloco", key: "size", label: "Tamanho da letra", icon: "textSize", type: "slider", from: 10, to: 28, step: 1, suffix: " px", def: 14 }
          ] },
        { type: "timer", group: "work", name: "Timers", icon: "timer", desc: "Cronômetro, contagem regressiva e pomodoro.", sizes: [[2, 1], [2, 2], [1, 1], [3, 1], [4, 1], [1, 3]], options: [
            { sec: "Tempos", key: "mode", label: "Modo", type: "seg", def: "pomodoro", options: [["all", "Os três", "dashboard"], ["pomodoro", "Pomodoro", "target"], ["countdown", "Regressivo", "timer"], ["stopwatch", "Cronômetro", "stopwatch"]] },
            { sec: "Tempos", key: "flip", label: "Tiles na vertical", icon: "dashboard", type: "switch", def: false, when: { mode: "all" } },
            { sec: "Tempos", key: "focus", label: "Foco", icon: "target", type: "slider", from: 5, to: 90, step: 5, suffix: " min", def: 25, when: { mode: ["pomodoro", "all"] } },
            { sec: "Tempos", key: "pause", label: "Pausa", icon: "coffee", type: "slider", from: 1, to: 30, step: 1, suffix: " min", def: 5, when: { mode: ["pomodoro", "all"] } },
            { sec: "Tempos", key: "longPause", label: "Pausa longa", icon: "sleep", type: "slider", from: 5, to: 60, step: 5, suffix: " min", def: 15, when: { mode: ["pomodoro", "all"] } },
            { sec: "Tempos", key: "cycles", label: "Ciclos até a pausa longa", icon: "repeat", type: "slider", from: 2, to: 8, step: 1, def: 4, when: { mode: ["pomodoro", "all"] } },
            { sec: "Tempos", key: "minutes", label: "Duração", icon: "timer", type: "slider", from: 1, to: 180, step: 1, suffix: " min", def: 10, when: { mode: ["countdown", "all"] } },
            { sec: "Tempos", key: "notify", label: "Avisar ao terminar", icon: "bellRing", type: "switch", def: true }
          ] },
        { type: "text", group: "deco", name: "Texto", icon: "compose", desc: "Uma frase, com a fonte e a cor que quiser.", sizes: [[3, 1], [2, 1], [4, 1], [2, 2], [4, 2]], options: [
            { sec: "Texto", key: "text", label: "Texto", type: "text", multiline: true, def: "Olá, mundo" },
            { sec: "Fonte", key: "font", label: "Fonte", type: "font", def: "" },
            { sec: "Fonte", key: "size", label: "Tamanho", icon: "textSize", type: "slider", from: 12, to: 200, step: 2, suffix: " px", def: 64 },
            { sec: "Fonte", key: "weight", label: "Peso", icon: "bold", type: "slider", from: 100, to: 900, step: 100, def: 600 },
            { sec: "Fonte", key: "italic", label: "Itálico", icon: "italic", type: "switch", def: false },
            { sec: "Fonte", key: "align", label: "Alinhamento", type: "seg", def: "center", options: [["left", "Esquerda", "alignLeft"], ["center", "Centro", "alignCenter"], ["right", "Direita", "alignRight"]] },
            { sec: "Fonte", key: "shadow", label: "Sombra", icon: "textShadow", type: "switch", def: true }
          ] },
        { type: "image", group: "deco", name: "Imagem", icon: "image", desc: "Foto numa forma, cartão com legenda ou adesivo. Solte uma imagem nele para trocar.", sizes: [[2, 2], [1, 1], [2, 1], [3, 2], [2, 3]], free: true, options: [
            { sec: "Imagem", key: "path", label: "Imagem", type: "image", def: "" },
            { sec: "Imagem", key: "kind", label: "Tipo", type: "seg", preview: true, def: "photo", options: [["photo", "Foto", "image"], ["card", "Cartão", "imageFrame"], ["sticker", "Adesivo", "sticker"]] },
            { sec: "Forma", key: "shape", label: "Forma", type: "seg", preview: true, def: "rounded", options: Shapes.list, when: { kind: "photo" } },
            { sec: "Forma", key: "sides", label: "Pétalas", icon: "flowerOutline", type: "slider", from: 3, to: 24, step: 1, def: 10, when: { kind: "photo", shape: "flower" } },
            { sec: "Enquadramento", key: "fit", label: "Encaixe", type: "seg", def: "crop", options: [["crop", "Preencher a forma", "crop"], ["fit", "Imagem inteira", "fullscreen"]], when: { kind: ["photo", "card"] } },
            { sec: "Enquadramento", key: "zoom", label: "Zoom", icon: "arrow_expand", desc: "Editando, a roda do mouse em cima da foto também dá zoom.", type: "slider", from: 100, to: 400, step: 5, suffix: " %", def: 100, when: { kind: ["photo", "card"], fit: "crop" } },
            { sec: "Enquadramento", key: "panX", label: "Posição na horizontal", icon: "swap_horizontal", desc: "Qual parte aparece: -100 % mostra a esquerda, 100 % a direita.", type: "slider", from: -100, to: 100, step: 5, suffix: " %", def: 0, when: { kind: ["photo", "card"], fit: "crop" } },
            { sec: "Enquadramento", key: "panY", label: "Posição na vertical", icon: "swap_vertical", type: "slider", from: -100, to: 100, step: 5, suffix: " %", def: 0, when: { kind: ["photo", "card"], fit: "crop" } },
            { sec: "Enquadramento", key: "tilt", label: "Inclinação", icon: "rotate", desc: "Editando, a alça redonda em cima do widget gira arrastando.", type: "slider", from: -180, to: 180, step: 1, suffix: "°", def: 0, when: { kind: ["photo", "sticker"] } },
            { sec: "Imagem", key: "caption", label: "Legenda", icon: "tag", type: "text", def: "", when: { kind: "card" } },
            { sec: "Adesivo", key: "outline", label: "Contorno branco", icon: "circleOutline", type: "slider", from: 0, to: 16, step: 1, suffix: " px", def: 8, when: { kind: "sticker" } }
          ] },
        { type: "convert", group: "deco", name: "Conversor de imagens", icon: "fileSwap", desc: "Solte imagens nele e elas viram PNG, JPG, WEBP, AVIF ou PDF.", sizes: [[2, 2], [2, 1], [1, 1], [3, 2]], options: [
            { sec: "Conversão", key: "format", label: "Converter para", type: "seg", def: "webp", options: [["png", "PNG"], ["jpg", "JPG"], ["webp", "WEBP"], ["avif", "AVIF"], ["pdf", "PDF"]] },
            { sec: "Conversão", key: "quality", label: "Qualidade", icon: "tuneVariant", type: "slider", from: 30, to: 100, step: 5, suffix: " %", def: 85, when: { format: ["jpg", "webp", "avif"] } },
            { sec: "Conversão", key: "where", label: "Salvar em", type: "seg", def: "same", options: [["same", "Mesma pasta", "folder"], ["downloads", "Downloads", "download"]] },
            { sec: "Conversão", key: "keep", label: "Manter o original", icon: "copy", type: "switch", def: true }
          ] }
    ]
    // opcoes que todo widget tem
    readonly property var commonOptions: [
        { sec: "Visual", key: "card", label: "Fundo", type: "seg", def: "auto", options: [["auto", "Padrão", "auto"], ["card", "Cartão", "cards"], ["glass", "Vidro", "glass"], ["none", "Sem fundo", "image"]] },
        { sec: "Visual", key: "tone", label: "Cor", type: "tone", def: "global" },
        { sec: "Visual", key: "fgColor", label: "Minha cor", type: "color", def: "#ffffff", when: { tone: "custom" } },
        { sec: "Posição", key: "place", label: "Posição", type: "seg", def: "free", options: [["free", "Onde eu deixar", "cursorMove"], ["calm", "Área calma", "leaf"], ["busy", "Área movimentada", "sparkle"]] },
        { sec: "Tela de bloqueio", key: "lock", label: "Mostrar também na tela de bloqueio", icon: "lock", type: "switch", def: false },
        { sec: "Tela de bloqueio", key: "lockOnly", label: "Só na tela de bloqueio", icon: "lockClock", desc: "Some da área de trabalho (aparece apagado enquanto você edita).", type: "switch", def: false, when: { lock: true } }
    ]
    // fundo padrao de cada tipo (relogio e texto ficam bem soltos no wallpaper)
    readonly property var cardDefaults: ({ clock: "none", text: "none", visualizer: "none", image: "none" })
    function info(type) { return catalog.find(c => c.type === type) ?? catalog[0] }
    function optionsOf(type) {
        // as opcoes de "Tela de bloqueio" do proprio widget (ex.: estilo do relogio) vao junto com as comuns da mesma secao
        const own = info(type).options, lockOwn = own.filter(o => o.sec === "Tela de bloqueio")
        return own.filter(o => o.sec !== "Tela de bloqueio").concat(commonOptions, lockOwn)
    }
    // valor de uma opcao com o padrao do esquema
    function opt(w, key) {
        const o = (w && w.opts) || {}
        if (o[key] !== undefined) return o[key]
        // tom: widgets antigos guardavam "fg" (auto | theme | custom)
        if (key === "tone" && o.fg !== undefined) return ({ theme: "primary", custom: "custom" })[o.fg] ?? "global"
        if (key === "card") return (w && w.type === "system" && (o.look ?? "tiles") === "tiles") ? "none" : (cardDefaults[w ? w.type : ""] ?? "auto")
        const d = optionsOf(w ? w.type : "").find(x => x.key === key)
        return d ? d.def : undefined
    }
    function shown(w, def) {
        if (!def.when) return true
        // o Repeater entrega as listas do esquema como listas do Qt (Array.isArray da falso): Array.from resolve as duas
        for (const k in def.when) { const v = opt(w, k), want = def.when[k]; if (want !== null && typeof want === "object" ? Array.from(want).indexOf(v) < 0 : v !== want) return false }
        return true
    }

    // sombra dos widgets (pagina Aparencia > Sombras e brilhos): "light" = wallpaper claro embaixo (no automatico vira brilho)
    function shadowGlow(light) { const m = Settings.desktopShadowMode; return m === "light" || m === "accent" || (m === "auto" && light) }
    function shadowColor(light) {
        const k = Settings.desktopShadowStrength / 100, m = Settings.desktopShadowMode
        if (m === "accent") return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, Math.min(1, k * 0.9))
        return shadowGlow(light) ? Qt.rgba(1, 1, 1, k * 0.4) : Qt.rgba(0, 0, 0, k)
    }
    function shadowBlur(light) { return Settings.desktopShadowSize / 100 * (shadowGlow(light) ? 0.6 : 1) }
    function shadowOffset(light) { return shadowGlow(light) ? 0 : Settings.desktopShadowOffset }

    // widgets com campo de texto pedem o teclado (a camada da area de trabalho normalmente nao recebe teclas)
    property var keyWant: ({})
    readonly property bool typing: Object.keys(keyWant).some(k => keyWant[k])
    // com o mouse em cima de um campo em uso: foco exclusivo (o Hyprland nao entrega o teclado a camada de baixo so pelo clique)
    readonly property bool typingHere: Object.keys(keyWant).some(k => keyWant[k] && k.indexOf("-h-") > 0 && keyWant[k.replace("-h-", "-f-")])
    function wantKeys(key, on) { if (!!keyWant[key] === on) return; const m = Object.assign({}, keyWant); m[key] = on; keyWant = m }

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
    function remove(id) { if (selected === id) selected = ""; selection = selection.filter(x => x !== id); mutate(l => { const i = l.findIndex(w => w.id === id); if (i >= 0) l.splice(i, 1) }) }
    function setPos(id, fx, fy) { mutate(l => { const w = l.find(x => x.id === id); if (w) { w.fx = fx; w.fy = fy; if (w.opts && w.opts.place && w.opts.place !== "free") w.opts.place = "free" } }) }
    function setOpt(id, k, v) { mutate(l => { const w = l.find(x => x.id === id); if (w) { w.opts = w.opts || {}; w.opts[k] = v } }) }
    // tamanho e lugar de uma vez (alca do canto); tamanhos quebrados so nos widgets "free" (imagem)
    function setGeom(id, c, r, fx, fy) { mutate(l => { const w = l.find(x => x.id === id); if (w) { const f = !!info(w.type).free; w.cols = Math.max(f ? 0.5 : 1, Math.min(6, c)); w.rows = Math.max(f ? 0.5 : 1, Math.min(5, r)); w.fx = fx; w.fy = fy; if (w.opts && w.opts.place && w.opts.place !== "free") w.opts.place = "free" } }) }
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
    property bool locked: Settings.desktopLocked   // trava o arrasto (salvo em Settings.desktopLocked)
    // selecao multipla (marquee / Ctrl+clique): ids; selected (inspetor) so quando e um
    property var selection: []
    property real gdx: 0                  // deslocamento do grupo durante o arrasto em grupo
    property real gdy: 0
    function inSel(id) { return selection.indexOf(id) >= 0 }
    function toggleSel(id) { selection = inSel(id) ? selection.filter(x => x !== id) : selection.concat([id]); selected = selection.length === 1 ? selection[0] : "" }
    function removeMany(ids) { selected = ""; selection = []; mutate(l => { for (const id of ids) { const i = l.findIndex(w => w.id === id); if (i >= 0) l.splice(i, 1) } }) }
    function setPosMany(ps) { mutate(l => { for (const p of ps) { const w = l.find(x => x.id === p.id); if (w) { w.fx = p.fx; w.fy = p.fy; if (w.opts && w.opts.place && w.opts.place !== "free") w.opts.place = "free" } } }) }
    onEditingChanged: if (!editing) selection = []
    // liga/desliga um tipo (menu Widgets): se ja existe tira todos, senao poe um no tamanho padrao
    function hasType(t) { return (Settings.desktopWidgets || []).some(w => w.type === t) }
    function toggleType(t) { if (hasType(t)) mutate(l => { for (let i = l.length - 1; i >= 0; i--) if (l[i].type === t) l.splice(i, 1) }); else { const e = editing; add(t); editing = e; selected = "" } }

    // ---------------- posicao automatica e cor do texto (scripts/desk_place.py) ----------------
    // auto = { id: { fx, fy, lum } }: lugar escolhido pela analise do wallpaper e o brilho embaixo de cada widget
    property var auto: ({})
    property rect area: Qt.rect(0, 0, 1920, 1080)   // area livre (DesktopLayer informa)
    property size screenSize: Qt.size(1920, 1080)
    readonly property string analysisKey: Wallpaper.still + "|" + JSON.stringify((Settings.desktopWidgets || []).map(w => [w.id, w.cols, w.rows, w.fx, w.fy, opt(w, "place")])) + "|" + area
    onAnalysisKeyChanged: analyzeT.restart()
    Timer { id: analyzeT; interval: 400; onTriggered: root.analyze() }
    function posOf(w) {
        const a = auto[w.id]
        return (opt(w, "place") !== "free" && a && a.fx !== undefined) ? { fx: a.fx, fy: a.fy } : { fx: w.fx, fy: w.fy }
    }
    function analyze() {
        const ws = Settings.desktopWidgets || []
        if (!ws.length || Wallpaper.still === "") return
        const ar = area
        const list = ws.map(w => {
            const pw = px(w.cols), ph = px(w.rows)
            return { id: w.id, w: pw, h: ph, mode: opt(w, "place"), x: ar.x + w.fx * Math.max(0, ar.width - pw), y: ar.y + w.fy * Math.max(0, ar.height - ph) }
        })
        placer.command = ["python3", Qt.resolvedUrl("scripts/desk_place.py").toString().replace("file://", ""), Wallpaper.still, String(Math.round(screenSize.width)), String(Math.round(screenSize.height)),
            JSON.stringify({ area: [ar.x, ar.y, ar.width, ar.height], widgets: list })]
        placer.running = false
        placer.running = true
    }
    Process {
        id: placer
        stdout: StdioCollector { onStreamFinished: { try { root.auto = JSON.parse(text) } catch (e) {} } }
    }

    // ---------------- presets ----------------
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
    readonly property var all: builtins.concat(Looks.list)
    property string lastApplied: ""

    // salvar / aplicar / editar: Looks.qml (os visuais guardam grupos escolhidos; os layouts prontos acima so os widgets)
    function save(name) { return Looks.save(name, Looks.defaultGroups()) }
    function overwrite(name) { Looks.overwrite(name) }
    function rename(name, to) { const r = Looks.rename(name, to); if (lastApplied === name) lastApplied = r; return r }
    function removePreset(name) { Looks.remove(name) }
    function apply(name) { Looks.apply(name); lastApplied = name }

    IpcHandler {
        target: "desktop"
        function edit(): void { root.editing = !root.editing }
        function preset(name: string): void { root.apply(name) }
        function toggle(): void { Settings.desktopOn = !Settings.desktopOn }
        function peek(): void { root.peek = !root.peek }
        function add(type: string): void { Settings.desktopOn = true; root.add(type) }
        function lock(): void { Settings.desktopLocked = !Settings.desktopLocked }
        function select(id: string): void { root.editing = true; root.selected = id }   // abre as opcoes de um widget
        function menu(x: int, y: int): void { DeskMenu.show(x, y, "") }                   // menu de clique direito nesse ponto
        function menuclose(): void { DeskMenu.close() }
        function menucenter(): void { DeskMenu.show(root.screenSize.width / 2 - 145, root.screenSize.height / 2 - 160, "") }   // menu no meio da tela (atalho)
        function state(): string { return JSON.stringify({ editing: root.editing, selected: root.selected, locked: root.locked, peek: root.peek }) }
        function stop(): void { root.editing = false; root.selected = ""; root.peek = false }   // sai da edicao (testes)
    }
}
