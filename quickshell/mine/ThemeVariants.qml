// Estilos de paleta (uma lista so, usada nas configuracoes e no menu da area de trabalho).
// id, rotulo, icone, descricao (linha de descricao), curta (sob o cartao), rec (aparece sem abrir "Mais estilos").
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property var list: [
        { id: "auto", label: "Automático", icon: "auto", rec: true, short: "Decide pela imagem", desc: "Escolhe sozinho pela imagem: se ela for calma, usa tons neutros" },
        { id: "wallpaper", label: "Wallpaper", icon: "wallpaper", rec: true, short: "Cores da imagem", desc: "As cores que mais aparecem na imagem" },
        { id: "tonalspot", label: "Tonal", icon: "palette", rec: true, short: "Tons suaves", desc: "Tons suaves da cor principal" },
        { id: "vibrant", label: "Vibrante", icon: "lightning", rec: true, short: "Vivas e saturadas", desc: "Cores mais vivas e saturadas" },
        { id: "fidelity", label: "Fiel", icon: "eye", rec: true, short: "Cor da imagem", desc: "A cor principal da imagem, sem mudar" },
        { id: "expressive", label: "Expressivo", icon: "magic", rec: false, short: "Mais contraste", desc: "Gira as cores para dar mais contraste" },
        { id: "content", label: "Conteúdo", icon: "image", rec: false, short: "Fiel, com apoio", desc: "Fiel à imagem, com cores vizinhas de apoio" },
        { id: "neutral", label: "Neutro", icon: "balance", rec: false, short: "Quase cinza", desc: "Quase cinza, com um toque da cor" },
        { id: "monochrome", label: "Mono", icon: "moon", rec: false, short: "Só cinzas", desc: "Só tons de cinza" },
        { id: "rainbow", label: "Arco-íris", icon: "firework", rec: false, short: "Várias cores", desc: "Várias cores, pouco ligadas à imagem" },
        { id: "fruitsalad", label: "Frutas", icon: "leaf", rec: false, short: "Ainda mais cores", desc: "Ainda mais cores, bem alegre" }
    ]
    function ids(rec: bool): var { return list.filter(v => v.rec === rec).map(v => v.id) }
    function info(id: string): var { return list.find(v => v.id === id) ?? null }
    function label(id: string): string { return (info(id) ?? { label: id }).label }
    // opcoes no formato do SetChoice: [id, rotulo, icone, curta]
    function options(rec: bool): var { return list.filter(v => v.rec === rec).map(v => [v.id, v.label, v.icon, v.short]) }

    // 4 cores de previa, so do carater do estilo, a partir da cor atual (base) e das cores do wallpaper (wall)
    function dots(id: string, base: color, wall: var): var {
        const h = base.hslHue < 0 ? 0 : base.hslHue, s = base.hslSaturation, l = base.hslLightness
        const w = i => (wall && wall.length > i) ? Qt.color(wall[i]) : base
        const hh = d => ((h + d / 360) % 1 + 1) % 1
        const c = (d, sat, lit) => Qt.hsla(hh(d), Math.max(0, Math.min(1, sat)), lit, 1)
        switch (id) {
        case "auto": return [w(0), w(1), c(0, 0.1, 0.55), base]
        case "wallpaper": return [w(0), w(1), w(2), w(3)]
        case "fidelity": return [base, c(0, s, Math.min(0.85, l + 0.18)), c(0, s, Math.max(0.15, l - 0.18)), w(0)]
        case "tonalspot": return [c(0, 0.32, 0.3), c(0, 0.32, 0.5), c(0, 0.32, 0.72), c(60, 0.28, 0.6)]
        case "vibrant": return [c(0, 0.95, 0.5), c(20, 0.95, 0.55), c(40, 0.9, 0.6), c(-25, 0.9, 0.45)]
        case "expressive": return [c(0, 0.7, 0.55), c(60, 0.7, 0.55), c(120, 0.65, 0.5), c(300, 0.7, 0.6)]
        case "content": return [base, c(25, s * 0.8, l), c(-25, s * 0.8, l), w(1)]
        case "neutral": return [c(0, 0.07, 0.25), c(0, 0.07, 0.45), c(0, 0.07, 0.65), c(0, 0.3, 0.8)]
        case "monochrome": return [c(0, 0, 0.25), c(0, 0, 0.45), c(0, 0, 0.65), c(0, 0, 0.85)]
        case "rainbow": return [c(0, 0.7, 0.55), c(90, 0.7, 0.55), c(180, 0.7, 0.55), c(270, 0.7, 0.55)]
        case "fruitsalad": return [c(0, 0.8, 0.6), c(45, 0.8, 0.6), c(150, 0.75, 0.55), c(235, 0.8, 0.6)]
        }
        return [base, base, base, base]
    }
}
