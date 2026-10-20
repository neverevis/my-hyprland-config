// Opcoes dos modulos de barra que usam o formulario generico (OptionsForm) na pagina Barras.
// Os modulos antigos (workspaces, medidores, volume, bandeja, cores) tem paineis proprios e podem ter mais opcoes aqui.
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property var popup: { "key": "popup", "label": "Detalhes ao passar o mouse", "type": "switch", "def": true }
    readonly property var schemas: ({
        island: [
            { key: "idle", label: "Em repouso mostra", type: "seg", def: "clock", desc: "A roda do mouse na ilha alterna só o repouso (volta ao relógio mesmo com música); com Ctrl, ou sobre os botões, ela troca de faixa. Quando outra coisa também está acontecendo, ela vira uma bolinha ao lado da ilha: clique nela para trazê-la.", options: [["clock", "Relógio"], ["window", "Janela ativa"], ["weather", "Clima"], ["dot", "Só um ponto"]] },
            { key: "format", label: "Formato do relógio (ex.: HH:mm, ddd HH:mm)", type: "text", def: "HH:mm", when: { idle: "clock" } },
            { key: "avatar", label: "Foto de perfil no repouso", icon: "account", type: "switch", def: false },
            { key: "status", label: "Ícones de estado no repouso (microfone, som, rede, notificações)", icon: "pulse", type: "switch", def: false },
            { key: "media", label: "Música tocando", type: "switch", def: true },
            { key: "visualizer", label: "Visualizador da música", icon: "wave", type: "seg", def: "bars", when: { media: true }, options: [["bars", "Barras"], ["wave", "Onda"], ["none", "Nenhum"]] },
            { key: "controls", label: "Botões da música", icon: "play", type: "seg", def: "hover", when: { media: true }, options: [["hover", "Ao passar o mouse"], ["always", "Sempre"], ["never", "Nunca"]] },
            { key: "expand", label: "Abrir o título inteiro por 3 s ao trocar de faixa (ou ao passar o mouse)", icon: "swap_horizontal", type: "switch", def: true, when: { media: true } },
            { key: "notifs", label: "Notificações novas", type: "switch", def: true, desc: "Mostra o título e o começo do texto. Com ela ligada, os cartões de notificação não aparecem (a ilha mostra no lugar), desde que a barra não se esconda sozinha." },
            { key: "osd", label: "Volume, microfone, brilho e luz noturna ao mudar", type: "switch", def: true, desc: "No lugar do indicador de volume que sai da moldura (vale com a barra sempre visível)." },
            { key: "timer", label: "Timer correndo", type: "switch", def: true, desc: "Clique pausa ou continua; botão direito zera." },
            { key: "rec", label: "Gravação da tela", type: "switch", def: true },
            { key: "pill", label: "Fundo em pílula", type: "switch", def: true },
            { key: "max", label: "Largura máxima do texto", type: "slider", from: 80, to: 420, def: 260, suffix: " px" }
        ],
        clock: [{ key: "shortDate", label: "Data curta (dia/mês) embaixo da hora, nas barras laterais", icon: "calendar", type: "switch", def: true }, popup],
        window: [{ key: "showClass", label: "Mostrar o nome do app em cima do título", icon: "window", type: "switch", def: true }],
        notifs: [{ key: "badge", label: "Aviso de notificações novas", icon: "bellRing", type: "seg", def: "count", options: [["count", "Número", "numeric"], ["dot", "Só um ponto", "circleOutline"]] }],
        divisor: [{ key: "style", label: "Estilo", icon: "shape", type: "seg", def: "rect", options: [["rect", "Linha", "alignVCenter"], ["dot", "Ponto", "circleOutline"], ["space", "Só espaço", "swap_horizontal"]] },
                  { key: "spacing", label: "Espaço em volta", icon: "swap_horizontal", type: "slider", from: 0, to: 40, def: 8, suffix: " px" }],
        utils: [{ key: "screenSnip", label: "Capturar uma área da tela", icon: "frame", type: "switch", def: true },
                { key: "colorPicker", label: "Pegar uma cor da tela", icon: "palette", type: "switch", def: true },
                { key: "record", label: "Gravar a tela (com o tempo ao lado)", icon: "recordRec", type: "switch", def: false },
                { key: "wallpaper", label: "Escolher o wallpaper", icon: "wallpaper", type: "switch", def: false },
                { key: "darkMode", label: "Alternar tema claro / escuro", icon: "sun", type: "switch", def: false },
                { key: "perfProfile", label: "Perfil de energia (economia, equilibrado, desempenho)", icon: "balance", type: "switch", def: false },
                { key: "mic", label: "Microfone (mudo / ligado)", icon: "mic", type: "switch", def: true }],
        media: [{ key: "artist", label: "Mostrar o artista antes do título", icon: "account", type: "switch", def: false },
                { key: "clean", label: "Limpar o título (tira \"(Official Video)\", \"- YouTube\"…)", icon: "broom", type: "switch", def: true },
                { key: "ring", label: "Anel de progresso em volta do ícone", icon: "circleOutline", type: "switch", def: true },
                { key: "lyrics", label: "Mostrar a linha atual da letra", icon: "music", type: "switch", def: false },
                { key: "leftClick", label: "Clique esquerdo", icon: "play", type: "seg", def: "toggle", options: [["toggle", "Tocar / pausar"], ["panel", "Abrir a aba Mídia"]], desc: "Botão do meio e voltar do mouse: faixa anterior. Direito e avançar: próxima." },
                { key: "preferredPlayer", label: "Player preferido (parte do nome, ex.: spotify)", icon: "speaker", type: "text", def: "" },
                { key: "alwaysVisible", label: "Mostrar mesmo sem nada tocando", icon: "eye", type: "switch", def: false },
                { key: "minW", label: "Largura mínima do texto", type: "slider", from: 0, to: 300, def: 0, suffix: " px" },
                { key: "maxW", label: "Largura máxima do texto", type: "slider", from: 60, to: 520, def: 280, suffix: " px" }, popup],
        aiusage: [{ key: "alwaysVisible", label: "Mostrar mesmo sem dados do Claude Code neste PC", icon: "eye", type: "switch", def: false }, popup],
        avatar: [popup], livewall: [],
        battery: [{ key: "style", label: "Estilo", icon: "battery", type: "seg", def: "bar", options: [["bar", "Barra"], ["ios", "iOS"], ["macos", "macOS"], ["windows", "Windows"], ["ring", "Anel"], ["icon", "Ícone"], ["number", "Número"]] },
                  { key: "showPercentage", label: "Mostrar a porcentagem", type: "switch", def: true },
                  { key: "showCharging", label: "Raio ao carregar", type: "switch", def: true }, popup],
        bluetooth: [popup], sysicons: [],
        weather: [popup], netspeed: [popup], gpu: [popup], temp: [popup], updates: [popup], privacy: [popup],
        cpu: [popup], memory: [popup], volume: [popup],
        tray: [{ key: "hidePassive", label: "Esconder os ícones parados", type: "switch", def: true },
               { key: "mono", label: "Ícones monocromáticos (cor do texto da barra)", type: "switch", def: true },
               { key: "overflow", label: "Botão de mais ícones", icon: "dotsH", type: "switch", def: true, desc: "Os ícones escondidos (Shift + botão do meio no ícone) ficam num cartão que abre neste botão, em vez de sumirem." },
               { key: "customMenu", label: "Menu do botão direito desenhado pelo shell", icon: "menu", type: "switch", def: true, desc: "Desligado, usa o menu nativo de cada app." },
               { key: "showItemId", label: "Mostrar o id do app na dica", icon: "tag", type: "switch", def: false }],
        launcher: [{ key: "icon", label: "Ícone (nome, ex.: apps, arch, rocket)", type: "text", def: "apps" }],
        visualizer: [{ key: "bars", label: "Barrinhas", type: "slider", from: 4, to: 32, def: 10 },
                     { key: "dimIdle", label: "Esmaecer quando nada está tocando", type: "switch", def: true }],
        taskbar: [{ key: "iconSize", label: "Tamanho dos ícones", type: "slider", from: 18, to: 48, def: 26, suffix: " px" },
                  { key: "spacing", label: "Espaço entre os ícones", type: "slider", from: 0, to: 24, def: 6, suffix: " px" },
                  { key: "magnify", label: "Ampliar ao passar o mouse (como no Mac)", type: "slider", from: 0, to: 100, def: 35, suffix: " %" },
                  { key: "running", label: "Mostrar também os apps abertos que não estão fixados", type: "switch", def: true },
                  { key: "separator", label: "Linhas entre fixados, abertos, música e apps", type: "switch", def: false },
                  { key: "previews", label: "Miniaturas das janelas ao passar o mouse", type: "switch", def: true },
                  { key: "appsButton", label: "Botão de apps", type: "switch", def: false },
                  { key: "appsAction", label: "O botão de apps abre", icon: "apps", type: "seg", def: "launcher", when: { appsButton: true }, options: [["launcher", "Launcher"], ["overview", "Visão geral"], ["home", "Início"]] },
                  { key: "pinButton", label: "Alfinete (fixa o dock ou deixa esconder sozinho)", icon: "pin", type: "switch", def: false },
                  { key: "revealEmpty", label: "Aparecer sozinho num workspace vazio (com o esconder automático ligado)", icon: "eye", type: "switch", def: false },
                  { key: "media", label: "Música tocando no fim", type: "switch", def: false },
                  { key: "mediaText", label: "Título, artista e faixa anterior / próxima ao lado da capa", type: "switch", def: true, when: { media: true } },
                  { key: "mono", label: "Ícones monocromáticos", type: "switch", def: false },
                  { key: "ignore", label: "Esconder apps (classes separadas por espaço; * no fim vale prefixo; /regex/)", type: "text", def: "" }]
    })
    function schema(type) { return schemas[type] ?? [] }
    function value(mod, key) { const d = schema(mod.type).find(x => x.key === key); return mod[key] !== undefined ? mod[key] : (d ? d.def : undefined) }
    function shown(mod, d) {
        if (!d.when) return true
        for (const k in d.when) if (value(mod, k) !== d.when[k]) return false
        return true
    }
}
