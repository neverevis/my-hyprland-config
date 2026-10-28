// SetPage: pagina das configuracoes feita com o kit (substitui o cabecalho da janela).
// Titulo grande + uma linha de descricao opcional, depois a previa ao vivo (preview: um SetPreview ou qualquer Item)
// e as secoes (SetSection) como filhos. A janela centraliza a pagina com largura maxima SetK.maxWidth.
// Exemplo:
//   SetPage {
//       title: "Tema e cores"; subtitle: "Cores, transparência e fontes"
//       preview: SetPreview { ... }
//       SetSection { title: "Modo"; icon: "themeAuto"; SetRow { ... } }
//   }
import QtQuick

Column {
    id: page
    readonly property bool kitPage: true      // a janela esconde o cabecalho antigo para estas paginas
    readonly property int maxWidth: SetK.maxWidth
    property string title
    property string subtitle
    property alias preview: prevBox.data
    default property alias sections: body.data

    width: parent ? parent.width : SetK.maxWidth
    spacing: 0

    Column {
        width: parent.width
        spacing: SetK.xs
        bottomPadding: SetK.lg
        UiText { text: page.title; color: Theme.text; font.family: Theme.fontTitle; font.pixelSize: SetK.fPage; font.weight: Font.Bold }
        UiText { visible: page.subtitle !== ""; width: parent.width; elide: Text.ElideRight; text: page.subtitle; color: Theme.muted; font.pixelSize: 13 }
    }
    Column {
        id: prevBox
        z: 5   // popovers da previa passam por cima das secoes
        visible: children.length > 0
        width: parent.width
        bottomPadding: visible ? SetK.xl : 0
    }
    Column {
        id: body
        width: parent.width
        spacing: SetK.xxl - 4
        bottomPadding: SetK.xl
    }
}
