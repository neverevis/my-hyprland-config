// Medidas do kit das configuracoes (SetPage, SetSection, SetRow, SetExpander, SetSlider, SetChoice, SetColor, SetPreview).
// Escala de espaco em passos de 4 px; poucos tamanhos de texto e bem separados (titulo, secao, linha, descricao).
// Use sempre estes valores nas paginas novas, nunca numeros soltos.
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    // espacos
    readonly property int xs: 4
    readonly property int sm: 8
    readonly property int md: 12
    readonly property int lg: 16
    readonly property int xl: 24
    readonly property int xxl: 32
    // largura maxima do conteudo (centralizado na janela)
    readonly property int maxWidth: 760
    // linhas
    readonly property int rowH: 56          // linha sem descricao
    readonly property int rowHDesc: 64      // linha com descricao
    readonly property int subH: 52          // sub-linha (dentro de um expansor)
    readonly property int tile: 20          // icone das linhas (sem caixa)
    readonly property int pad: 16           // margem interna das linhas
    readonly property int textX: pad + tile + 12   // onde comeca o texto das linhas (sub-linhas alinham aqui)
    readonly property int boxRadius: 18     // caixa das secoes
    readonly property int innerRadius: 12   // destaque de hover dentro da caixa
    // texto
    readonly property int fPage: 26
    readonly property int fSection: 13
    readonly property int fRow: 14
    readonly property int fDesc: 12
    readonly property int fChip: 12
    // movimento (ease-out forte, curto: e uma tela de uso, nao de vitrine)
    readonly property int fast: 140
    readonly property int base: 200
    readonly property var ease: [0.23, 1, 0.32, 1, 1, 1]
}
