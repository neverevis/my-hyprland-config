// Pagina "Terminal" (kit Set*): terminal padrao (Terminal.qml), visual do kitty/foot e prompt do starship (TermPrompt.qml).
// So grava o que voce trocou; nada roda com a pagina fechada (leitura das configs ao abrir, um processo por mudanca).
import Quickshell
import QtQuick

SetPage {
    id: page
    title: "Terminal"
    subtitle: "Qual terminal abre, como ele fica e o prompt"
    Component.onCompleted: Terminal.refreshBase()

    readonly property var picks: [["", "Automático", "auto", "usa o " + Terminal.autoName]].concat(Terminal.installed.map(id => { const t = Terminal.info(id); return [id, t.name, t.icon, ""] }))
    readonly property string img: Terminal.look("image") || ""
    readonly property var missing: [["starship", Terminal.starship, "o prompt"], ["fastfetch", Terminal.fastfetch, "as informações de boas-vindas"], ["chafa", Terminal.chafa, "imagem nos terminais que não são o kitty"]].filter(t => !t[1])

    // maquete no topo; clicar no fundo dela leva ao Visual
    preview: TermMock { onVisualRequested: page.goVisual() }
    function goVisual() {
        let f = page.parent
        while (f && f.contentY === undefined) f = f.parent
        if (!f) return
        const y = Math.max(0, Math.min(Math.max(0, f.contentHeight - f.height), visualSec.mapToItem(f.contentItem, 0, 0).y - SetK.lg))
        scrollAnim.target = f; scrollAnim.to = y; scrollAnim.restart()
    }
    NumberAnimation { id: scrollAnim; property: "contentY"; duration: SetK.base; easing.type: Easing.OutCubic }

    // ---- ferramentas que faltam ----
    SetSection {
        visible: Terminal.loaded && page.missing.length > 0
        title: "Ferramentas que faltam"; icon: "info"
        SetBlock {
            Repeater {
                model: page.missing
                delegate: UiText { required property var modelData; width: parent.width; wrapMode: Text.WordWrap; color: Theme.text; font.pixelSize: SetK.fRow; text: modelData[0] + ": " + modelData[2] }
            }
            DetailsLine { cmd: "sudo pacman -S " + page.missing.map(t => t[0]).join(" ") }
        }
    }

    // ---- terminal padrao ----
    SetSection {
        title: "Terminal padrão"; icon: "console"
        subtitle: "Abre pelo launcher, pelos botões do shell e pelos apps que pedem um terminal"
        SetChoice {
            label: ""; style: "tiles"; tileDesc: true; minTile: 120; thumbHeight: 54
            options: page.picks
            value: Settings.defaultTerminal || ""
            onPicked: v => Settings.defaultTerminal = v
            thumb: Component {
                Item {
                    property var opt
                    property bool on
                    property bool hovered
                    UiIcon { visible: (opt?.[0] ?? "") === ""; anchors.centerIn: parent; name: "auto"; size: 24; color: on ? Theme.accent : Theme.muted }
                    Image {
                        visible: (opt?.[0] ?? "") !== ""
                        anchors.centerIn: parent; width: 32; height: 32; sourceSize: Qt.size(64, 64); fillMode: Image.PreserveAspectFit; smooth: true
                        source: opt && opt[0] !== "" ? Icons.path(opt[2], "utilities-terminal") : ""
                    }
                }
            }
        }
        SetRow {
            icon: "console"; label: "Abrir o terminal"; description: "Abre o " + Terminal.termName
            UiButton { text: "Abrir"; kind: "ghost"; onClicked: AppCmds.run("terminal") }
        }
    }

    // ---- visual ----
    SetSection {
        id: visualSec
        title: "Visual"; icon: "palette"
        subtitle: Terminal.lookOk ? "Do " + Terminal.termName + ". Só o que você muda é gravado; o resto continua como está no terminal" : ""
        SetRow {
            visible: !Terminal.lookOk
            icon: "info"; label: "Visual ainda não editável aqui"; description: "Por enquanto só o kitty e o foot têm estas opções"
        }
        SetRow {
            visible: Terminal.id === "foot"
            icon: "info"; label: "Vale para janelas novas do foot"; description: "O foot não recarrega a aparência das janelas abertas"
        }
        SetRow {
            visible: Terminal.lookOk; enabled: Terminal.hasImage
            icon: "image"; label: "Imagem de fundo"
            description: !Terminal.hasImage ? "O " + Terminal.termName + " não tem imagem de fundo" : page.img === "" ? "Nenhuma" : page.img.split("/").pop()
            canReset: Terminal.isSet("image"); onReset: Terminal.setLook("image", undefined)
            UiButton { icon: "folderOpen"; text: "Escolher imagem"; onClicked: Pick.image("Imagem de fundo do terminal", p => Terminal.setLook("image", p)) }
            UiButton { visible: page.img !== ""; icon: "trash"; text: "Remover imagem"; kind: "ghost"; onClicked: Terminal.setLook("image", "") }
        }
        SetChoice {
            visible: Terminal.lookOk; enabled: Terminal.hasImage && page.img !== ""
            icon: "fullscreen"; label: "Como a imagem preenche"
            options: [["fill", "Preencher"], ["fit", "Ajustar"], ["center", "Centralizar"], ["tile", "Repetir"]]
            value: Terminal.look("layout")
            canReset: Terminal.isSet("layout"); onReset: Terminal.setLook("layout", undefined)
            onPicked: v => Terminal.setLook("layout", v)
        }
        SetSlider {
            visible: Terminal.lookOk; enabled: Terminal.hasImage && page.img !== ""
            icon: "night"; label: "Escurecer a imagem"; description: "Ajuda a ler o texto sobre a imagem"
            from: 0; to: 100; unit: " %"; def: Terminal.base.tint ?? 0; value: Terminal.look("tint") ?? 0
            onMoved: v => Terminal.setLook("tint", v)
        }
        SetSlider {
            visible: Terminal.lookOk
            icon: "opacity"; label: "Transparência"; description: "Do fundo do terminal; o texto continua nítido"
            from: 0; to: 80; unit: " %"; def: 100 - (Terminal.base.opacity ?? 100); value: 100 - (Terminal.look("opacity") ?? 100)
            onMoved: v => Terminal.setLook("opacity", 100 - v)
        }
        SetSlider {
            visible: Terminal.lookOk
            icon: "frame"; label: "Margem interna"; from: 0; to: 60; unit: " px"; def: Terminal.base.pad ?? 0; value: Terminal.look("pad") ?? 0
            onMoved: v => Terminal.setLook("pad", v)
        }
        SetBlock {
            visible: Terminal.lookOk
            OptionsForm {
                width: parent.width
                schema: [{ key: "font", label: "Fonte", icon: "font", type: "font" }]
                get: k => Terminal.look("font") || ""
                set: (k, v) => Terminal.setLook("font", v || undefined)
            }
        }
        SetSlider {
            visible: Terminal.lookOk
            icon: "textSize"; label: "Tamanho da fonte"; from: 6; to: 32; unit: " pt"; def: Terminal.base.fontSize ?? 12; value: Terminal.look("fontSize") ?? 12
            onMoved: v => Terminal.setLook("fontSize", v)
        }
        SetChoice {
            visible: Terminal.lookOk
            icon: "cursorMove"; label: "Cursor"
            options: [["beam", "Barra"], ["block", "Bloco"], ["underline", "Sublinhado"]]
            value: Terminal.look("cursor")
            canReset: Terminal.isSet("cursor"); onReset: Terminal.setLook("cursor", undefined)
            onPicked: v => Terminal.setLook("cursor", v)
        }
        SetRow {
            visible: Terminal.lookOk
            icon: "pulse"; label: "Piscar cursor"
            checked: Terminal.look("blink") === true
            canReset: Terminal.isSet("blink"); onReset: Terminal.setLook("blink", undefined)
            onToggled: on => Terminal.setLook("blink", on)
        }
    }

    // ---- prompt ----
    SetSection {
        title: "Prompt"; icon: "console"
        subtitle: Terminal.starship ? "O que aparece antes de cada comando (starship)" : ""
        SetRow {
            visible: !Terminal.starship
            icon: "info"; label: Terminal.loaded ? "O starship não está instalado" : "Procurando o starship…"
            description: Terminal.loaded ? "Veja “Ferramentas que faltam” no alto da página" : ""
        }
        SetRow {
            visible: Terminal.starship
            icon: "console"; label: "Usar o prompt montado aqui"; description: "Desligado, vale o seu ~/.config/starship.toml"
            checked: TermPrompt.on; onToggled: on => TermPrompt.set("on", on)
        }
        SetRow {
            visible: Terminal.starship && TermPrompt.err !== ""
            icon: "info"; label: "O starship não aceitou esta configuração"; description: TermPrompt.err
        }
        UiText {
            visible: Terminal.starship && TermPrompt.on
            x: SetK.pad; width: parent.width - SetK.pad * 2; topPadding: SetK.sm; bottomPadding: SetK.sm; wrapMode: Text.WordWrap
            text: "Vale para terminais novos (o fish lê isto ao abrir)"; color: Theme.muted; font.pixelSize: SetK.fDesc
        }
        SetChoice {
            visible: Terminal.starship && TermPrompt.on
            icon: "folder"; label: "Pasta"; description: "O caminho curto mostra até 3 níveis"
            options: [["name", "Só o nome"], ["short", "Caminho curto"], ["full", "Caminho completo"]]
            value: TermPrompt.get("dirStyle"); onPicked: v => TermPrompt.set("dirStyle", v)
        }
        SetChoice {
            visible: Terminal.starship && TermPrompt.on
            icon: "chevRight"; label: "Símbolo"
            options: [["❯", "❯"], ["$", "$"], ["›", "›"], ["λ", "λ"], ["➜", "➜"]]
            value: TermPrompt.get("sym"); onPicked: v => TermPrompt.set("sym", v)
        }
        SetChoice {
            visible: Terminal.starship && TermPrompt.on
            icon: "palette"; label: "Cor"; description: "Vem do tema e muda junto com ele"
            options: [["accent", "Destaque"], ["secondary", "Secundária"], ["tertiary", "Terciária"]]
            value: TermPrompt.get("color"); onPicked: v => TermPrompt.set("color", v)
        }
        SetRow {
            visible: Terminal.starship && TermPrompt.on
            icon: "alignLeft"; label: "Em duas linhas"; description: "O símbolo vai para a linha de baixo"
            checked: TermPrompt.get("two"); onToggled: on => TermPrompt.set("two", on)
        }
        SetRow {
            visible: Terminal.starship && TermPrompt.on
            icon: "minus"; label: "Linha em branco entre comandos"
            checked: TermPrompt.get("gap"); onToggled: on => TermPrompt.set("gap", on)
        }
    }

    SetSection {
        visible: Terminal.starship && TermPrompt.on
        title: "Peças do prompt"; icon: "layers"; subtitle: "Na ordem em que aparecem; as setas mudam a ordem"
        Repeater {
            model: [["user", "Usuário", "account", "Seu nome de usuário"], ["host", "Computador", "desktop", "O nome desta máquina"], ["dir", "Pasta", "folder", "Onde você está"],
                    ["git", "Git", "branch", "Ramo e mudanças, dentro de repositórios"], ["dur", "Tempo do comando", "timer", "Só quando passa de 2 s"], ["time", "Hora", "clock", "A hora de cada prompt"],
                    ["env", "Ambiente", "package", "Versão de python, node e rust, só dentro de projetos"], ["err", "Erro do último comando", "info", "O símbolo fica vermelho quando falha"]]
            delegate: SetRow {
                required property var modelData
                icon: modelData[2]; label: modelData[1]; description: modelData[3]
                checked: TermPrompt.get(modelData[0]); onToggled: on => TermPrompt.set(modelData[0], on)
                UiButton { visible: TermPrompt.piece(modelData[0]) !== null && TermPrompt.get(modelData[0]); icon: "chevUp"; kind: "ghost"; enabled: TermPrompt.active().indexOf(modelData[0]) > 0; onClicked: TermPrompt.move(modelData[0], -1) }
                UiButton { visible: TermPrompt.piece(modelData[0]) !== null && TermPrompt.get(modelData[0]); icon: "chevDown"; kind: "ghost"; enabled: TermPrompt.active().indexOf(modelData[0]) < TermPrompt.active().length - 1; onClicked: TermPrompt.move(modelData[0], 1) }
            }
        }
    }

    // ---- boas-vindas ----
    SetSection {
        title: "Boas-vindas"; icon: "greeting"
        subtitle: Terminal.fastfetch ? "O que aparece ao abrir o terminal (fastfetch)" : ""
        SetRow {
            visible: !Terminal.fastfetch
            icon: "info"; label: Terminal.loaded ? "O fastfetch não está instalado" : "Procurando o fastfetch…"
            description: Terminal.loaded ? "Veja “Ferramentas que faltam” no alto da página" : ""
        }
        SetRow {
            visible: Terminal.fastfetch
            icon: "greeting"; label: "Usar as boas-vindas montadas aqui"; description: TermFetch.on ? "Desligue para voltar às suas boas-vindas de antes" : "Desligado, vale a sua mensagem atual. Mudar a imagem ou os itens liga sozinho"
            checked: TermFetch.on; onToggled: on => TermFetch.set("on", on)
        }
        SetRow {
            visible: Terminal.fastfetch && TermFetch.err !== ""
            icon: "info"; label: "O fastfetch não aceitou esta configuração"; description: TermFetch.err
        }
        SetRow {
            visible: Terminal.fastfetch && TermFetch.on && !TermFetch.canImage
            icon: "info"; label: "Sem imagem neste terminal"; description: "Fora do kitty a imagem precisa do chafa (veja “Ferramentas que faltam”)"
        }
        SetRow {
            visible: Terminal.fastfetch
            icon: "image"; label: "Imagem"
            description: TermFetch.image === "" ? "Sem imagem" : TermFetch.image.split("/").pop() + (TermFetch.get("image") === "" ? " (a sua atual)" : "")
            canReset: TermFetch.get("image") !== ""; onReset: TermFetch.set("image", undefined)
            UiButton { icon: "folderOpen"; text: "Escolher imagem"; onClicked: Pick.image("Imagem das boas-vindas", p => TermFetch.set("image", p)) }
            UiButton { visible: TermFetch.image !== ""; icon: "trash"; text: "Sem imagem"; kind: "ghost"; onClicked: TermFetch.set("image", "none") }
        }
        UiText {
            visible: Terminal.fastfetch && TermFetch.on
            x: SetK.pad; width: parent.width - SetK.pad * 2; topPadding: SetK.sm; bottomPadding: SetK.sm; wrapMode: Text.WordWrap
            text: "Vale para terminais novos (o fish lê isto ao abrir)"; color: Theme.muted; font.pixelSize: SetK.fDesc
        }
    }

    SetSection {
        visible: Terminal.fastfetch
        title: "Itens das boas-vindas"; icon: "layers"; subtitle: "Na ordem em que aparecem; as setas mudam a ordem"
        Repeater {
            model: TermFetch.catalog.map(c => c.k)
            delegate: SetRow {
                required property string modelData
                readonly property var c: TermFetch.item(modelData)
                icon: c.icon; label: c.label
                checked: TermFetch.get(modelData); onToggled: on => on ? TermFetch.place(modelData, 9999) : TermFetch.remove(modelData)
                UiButton { visible: TermFetch.get(modelData); icon: "chevUp"; kind: "ghost"; enabled: TermFetch.active().indexOf(modelData) > 0; onClicked: TermFetch.move(modelData, -1) }
                UiButton { visible: TermFetch.get(modelData); icon: "chevDown"; kind: "ghost"; enabled: TermFetch.active().indexOf(modelData) < TermFetch.active().length - 1; onClicked: TermFetch.move(modelData, 1) }
            }
        }
    }
}
