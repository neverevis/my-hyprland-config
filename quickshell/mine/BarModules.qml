// Opcoes dos modulos de barra que usam o formulario generico (OptionsForm) na pagina Barras.
// Os modulos antigos (workspaces, medidores, volume, bandeja, cores) tem paineis proprios e podem ter mais opcoes aqui.
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property var popup: { "key": "popup", "label": "Detalhes ao passar o mouse", "type": "switch", "def": true }
    readonly property var schemas: ({
        island: [
            { key: "idle", label: "Em repouso mostra", type: "seg", def: "clock", desc: "A roda do mouse na ilha alterna só o repouso (volta ao relógio mesmo com música); com Ctrl, ou sobre os botões, ela troca de faixa.", options: [["clock", "Relógio"], ["window", "Janela ativa"], ["dot", "Só um ponto"]] },
            { key: "format", label: "Formato do relógio (ex.: HH:mm, ddd HH:mm)", type: "text", def: "HH:mm", when: { idle: "clock" } },
            { key: "media", label: "Música tocando", type: "switch", def: true },
            { key: "notifs", label: "Notificações novas", type: "switch", def: true, desc: "Mostra o título e o começo do texto. Com ela ligada, os cartões de notificação não aparecem (a ilha mostra no lugar), desde que a barra não se esconda sozinha." },
            { key: "osd", label: "Volume, microfone e mídia ao mudar", type: "switch", def: true, desc: "No lugar do indicador de volume que sai da moldura (vale com a barra sempre visível)." },
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
        media: [{ key: "max", label: "Tamanho máximo do título", type: "slider", from: 10, to: 60, def: 28, suffix: " letras" }, popup],
        battery: [{ key: "style", label: "Estilo", icon: "battery", type: "seg", def: "bar", options: [["bar", "Barra"], ["ios", "iOS"], ["macos", "macOS"], ["windows", "Windows"], ["ring", "Anel"], ["icon", "Ícone"], ["number", "Número"]] },
                  { key: "showPercentage", label: "Mostrar a porcentagem", type: "switch", def: true },
                  { key: "showCharging", label: "Raio ao carregar", type: "switch", def: true }, popup],
        bluetooth: [popup], sysicons: [],
        weather: [popup], netspeed: [popup], gpu: [popup], temp: [popup], updates: [popup], privacy: [popup],
        cpu: [popup], memory: [popup], volume: [popup],
        tray: [{ key: "hidePassive", label: "Esconder os ícones parados", type: "switch", def: true },
               { key: "mono", label: "Ícones monocromáticos (cor do texto da barra)", type: "switch", def: true },
               { key: "showItemId", label: "Mostrar o id do app na dica", icon: "tag", type: "switch", def: false }],
        launcher: [{ key: "icon", label: "Ícone (nome, ex.: apps, arch, rocket)", type: "text", def: "apps" }],
        visualizer: [{ key: "bars", label: "Barrinhas", type: "slider", from: 4, to: 32, def: 10 },
                     { key: "dimIdle", label: "Esmaecer quando nada está tocando", type: "switch", def: true }],
        taskbar: [{ key: "iconSize", label: "Tamanho dos ícones", type: "slider", from: 18, to: 48, def: 26, suffix: " px" },
                  { key: "magnify", label: "Ampliar ao passar o mouse (como no Mac)", type: "slider", from: 0, to: 100, def: 35, suffix: " %" },
                  { key: "running", label: "Mostrar também os apps abertos que não estão fixados", type: "switch", def: true },
                  { key: "separator", label: "Linha entre fixados e abertos", type: "switch", def: false },
                  { key: "previews", label: "Miniaturas das janelas ao passar o mouse", type: "switch", def: true },
                  { key: "appsButton", label: "Botão de apps (abre o launcher)", type: "switch", def: false },
                  { key: "media", label: "Música tocando no fim", type: "switch", def: false },
                  { key: "mono", label: "Ícones monocromáticos", type: "switch", def: false },
                  { key: "ignore", label: "Esconder apps (classes separadas por espaço; * no fim vale prefixo)", type: "text", def: "" }]
    })
    function schema(type) { return schemas[type] ?? [] }
    function value(mod, key) { const d = schema(mod.type).find(x => x.key === key); return mod[key] !== undefined ? mod[key] : (d ? d.def : undefined) }
    function shown(mod, d) {
        if (!d.when) return true
        for (const k in d.when) if (value(mod, k) !== d.when[k]) return false
        return true
    }
}
