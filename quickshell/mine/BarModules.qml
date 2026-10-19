// Opcoes dos modulos de barra que usam o formulario generico (OptionsForm) na pagina Barras.
// Os modulos antigos (workspaces, medidores, volume, bandeja, cores) tem paineis proprios e podem ter mais opcoes aqui.
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property var popup: { "key": "popup", "label": "Detalhes ao passar o mouse", "type": "switch", "def": true }
    readonly property var schemas: ({
        island: [
            { key: "idle", label: "Em repouso mostra", type: "seg", def: "clock", options: [["clock", "Relógio"], ["window", "Janela ativa"], ["dot", "Só um ponto"]] },
            { key: "format", label: "Formato do relógio (ex.: HH:mm, ddd HH:mm)", type: "text", def: "HH:mm", when: { idle: "clock" } },
            { key: "media", label: "Música tocando", type: "switch", def: true },
            { key: "notifs", label: "Notificações novas", type: "switch", def: true },
            { key: "osd", label: "Volume, microfone e mídia ao mudar", type: "switch", def: true },
            { key: "timer", label: "Timer correndo", type: "switch", def: true },
            { key: "rec", label: "Gravação da tela", type: "switch", def: true },
            { key: "pill", label: "Fundo em pílula", type: "switch", def: true },
            { key: "max", label: "Largura máxima do texto", type: "slider", from: 80, to: 420, def: 260, suffix: " px" }
        ],
        clock: [popup],
        media: [{ key: "max", label: "Tamanho máximo do título", type: "slider", from: 10, to: 60, def: 28, suffix: " letras" }, popup],
        weather: [popup], netspeed: [popup], gpu: [popup], temp: [popup], updates: [popup], privacy: [popup],
        cpu: [popup], memory: [popup], volume: [popup],
        tray: [{ key: "hidePassive", label: "Esconder os ícones parados", type: "switch", def: false },
               { key: "mono", label: "Ícones monocromáticos (cor do texto da barra)", type: "switch", def: false }],
        launcher: [{ key: "icon", label: "Ícone (nome, ex.: apps, arch, rocket)", type: "text", def: "apps" }],
        visualizer: [{ key: "bars", label: "Barrinhas", type: "slider", from: 4, to: 32, def: 10 }],
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
