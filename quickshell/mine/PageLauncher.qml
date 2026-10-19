// Pagina "Launcher": posicao, aparencia, busca (buscador, sites excluidos, o que aparece sem prefixo), prefixos,
// apps favoritos e escondidos, emoji/simbolos e animacao do launcher (Super + Tab).
import Quickshell
import QtQuick

Column {
    id: page
    spacing: 14
    readonly property var engines: [
        ["Google", "https://www.google.com/search?q="], ["DuckDuckGo", "https://duckduckgo.com/?q="], ["Brave", "https://search.brave.com/search?q="],
        ["Startpage", "https://www.startpage.com/do/search?q="], ["Kagi", "https://kagi.com/search?q="], ["Bing", "https://www.bing.com/search?q="],
        ["Perplexity", "https://www.perplexity.ai/search?q="], ["YouTube", "https://www.youtube.com/results?search_query="]]
    function setIn(prop, key, val) { const o = Object.assign({}, Settings[prop] || {}); o[key] = val; Settings[prop] = o }

    Card {
        icon: "apps"
        title: "Launcher de aplicativos"
        subtitle: "Abra com Super + Tab. Os apps mais usados aparecem primeiro."
        UiButton { icon: "play"; text: "Abrir o launcher"; kind: "accent"; onClicked: Settings.launcherOpen = true }
    }

    Card {
        icon: "dock"
        title: "Posição"
        UiSwitch { label: "Acoplado à moldura"; description: "Sai da borda da tela como uma barra. Desligado, flutua."; checked: Settings.launcherDocked; onToggled: on => Settings.launcherDocked = on }
        SidePick { visible: Settings.launcherDocked; value: Settings.launcherSide; onPicked: v => Settings.launcherSide = v }
        UiSeg {
            visible: !Settings.launcherDocked
            options: [["center", "Centro", "alignCenter"], ["top", "Topo", "arrowUp"]]
            value: Settings.launcherPos
            onPicked: v => Settings.launcherPos = v
        }
        UiSlider { visible: Settings.launcherDocked; label: "Deslocamento"; from: -1000; to: 1000; value: Settings.launcherOffset; suffix: " px"; onMoved: v => Settings.launcherOffset = Math.round(v) }
        UiSlider { visible: Settings.launcherDocked; label: "Curva ao encontrar a moldura"; from: 0; to: 40; value: Settings.launcherFillet; suffix: " px"; onMoved: v => Settings.launcherFillet = Math.round(v) }
    }

    Card {
        icon: "tune"
        title: "Aparência"
        UiSlider { label: "Largura"; from: 400; to: 1000; value: Settings.launcherWidth; suffix: " px"; onMoved: v => Settings.launcherWidth = v }
        UiSlider { label: "Resultados visíveis"; from: 3; to: 12; value: Settings.launcherRows; onMoved: v => Settings.launcherRows = Math.round(v) }
        UiSlider { label: "Tamanho dos ícones"; from: 20; to: 56; value: Settings.launcherIcon; suffix: " px"; onMoved: v => Settings.launcherIcon = Math.round(v) }
        UiSlider { label: "Arredondamento"; from: 0; to: 40; value: Settings.launcherRadius; suffix: " px"; onMoved: v => Settings.launcherRadius = Math.round(v) }
    }

    Card {
        icon: "search"
        title: "Busca"
        subtitle: "Sem prefixo o launcher mostra apps e, se quiser, contas, ações, opções do shell e a busca na web."
        UiLabel { text: "Buscador da web" }
        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: page.engines
                delegate: UiButton {
                    required property var modelData
                    text: modelData[0]; kind: Settings.launcherEngine === modelData[1] ? "accent" : "ghost"
                    onClicked: Settings.launcherEngine = modelData[1]
                }
            }
        }
        UiField {
            width: parent.width
            text: Settings.launcherEngine
            placeholderText: "Endereço (o texto vai no fim, ou onde estiver %s)"
            onEditingFinished: if (text.trim() !== "") Settings.launcherEngine = text.trim()
        }
        OptionsForm {
            width: parent.width
            schema: [{ key: "launcherExclude", label: "Sites fora da busca (um por linha, ex.: pinterest.com)", type: "list" }]
            get: k => Settings[k]
            set: (k, v) => Settings[k] = v
        }
        UiLabel { text: "Sem prefixo, mostrar também" }
        Repeater {
            model: [["math", "Contas", "Ex.: 12*3,5 mostra o resultado"], ["actions", "Ações do shell", "Bloquear, capturar, trocar o wallpaper…"],
                    ["settings", "Opções do shell", "Ex.: \"opacidade\" abre direto o ajuste nas configurações"], ["web", "Buscar na web", "Sempre a última opção"]]
            delegate: UiSwitch {
                required property var modelData
                label: modelData[1]; description: modelData[2]
                checked: (Settings.launcherDefaults || {})[modelData[0]] !== false
                onToggled: on => page.setIn("launcherDefaults", modelData[0], on)
            }
        }
        UiSwitch { label: "Busca aproximada"; description: "Letras na ordem já acham o app (\"ffx\" acha o Firefox). Desligada, só nomes que contêm o texto."; checked: Settings.launcherFuzzy; onToggled: on => Settings.launcherFuzzy = on }
    }

    Card {
        icon: "keyboard"
        title: "Prefixos"
        subtitle: "O primeiro caractere escolhe o modo. Deixe vazio para desligar um modo."
        Grid {
            width: parent.width
            columns: 2
            columnSpacing: 18; rowSpacing: 8
            Repeater {
                model: [["actions", "Ações do shell"], ["clipboard", "Área de transferência"], ["emoji", "Emoji"], ["symbols", "Símbolos"],
                        ["math", "Conta"], ["cmd", "Comando"], ["web", "Busca na web"], ["keys", "Atalhos do Hyprland"], ["translate", "Traduzir"], ["apps", "Só apps"]]
                delegate: Row {
                    required property var modelData
                    readonly property var defs: ({ actions: "/", clipboard: ";", emoji: ":", symbols: ".", math: "=", cmd: "$", web: "?", keys: "<", apps: ">", translate: "!" })
                    spacing: 10
                    width: (parent.width - 18) / 2
                    UiField {
                        width: 52
                        horizontalAlignment: Text.AlignHCenter
                        text: { const o = Settings.launcherPrefixes || {}; return o[modelData[0]] !== undefined ? o[modelData[0]] : parent.defs[modelData[0]] }
                        onEditingFinished: page.setIn("launcherPrefixes", modelData[0], text.trim().slice(0, 2))
                    }
                    UiText { anchors.verticalCenter: parent.verticalCenter; text: modelData[1]; color: Theme.text; font.pixelSize: 13 }
                }
            }
        }
        UiButton { icon: "restore"; text: "Voltar aos prefixos padrão"; kind: "ghost"; onClicked: Settings.launcherPrefixes = ({}) }
    }

    Card {
        icon: "sparkle"
        title: "Apps favoritos e escondidos"
        subtitle: "No launcher, clique direito num app favorita (ou tira dos favoritos). Os favoritos aparecem primeiro."
        UiLabel { text: "Favoritos" }
        UiText { visible: !(Settings.launcherFavs || []).length; text: "Nenhum ainda."; color: Theme.muted; font.pixelSize: 12 }
        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: Settings.launcherFavs || []
                delegate: Rectangle {
                    required property string modelData
                    readonly property var e: DesktopEntries.byId(modelData)
                    height: 34; width: fr.implicitWidth + 20; radius: 17; color: Theme.track; border.width: 1; border.color: Theme.border
                    Row {
                        id: fr
                        anchors.centerIn: parent
                        spacing: 8
                        Image { width: 18; height: 18; sourceSize: Qt.size(36, 36); source: Icons.path(parent.parent.e ? parent.parent.e.icon : parent.parent.modelData, "application-x-executable"); anchors.verticalCenter: parent.verticalCenter }
                        UiText { text: parent.parent.e ? parent.parent.e.name : parent.parent.modelData; color: Theme.text; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                        UiIcon { name: "close"; size: 13; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter
                            MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: Settings.launcherFavs = (Settings.launcherFavs || []).filter(x => x !== fr.parent.modelData) } }
                    }
                }
            }
        }
        UiLabel { text: "Escondidos" }
        Row {
            spacing: 8
            UiField { id: hideF; width: 300; placeholderText: "Nome do app para esconder…"; onAccepted: hideB.clicked() }
            UiButton {
                id: hideB; icon: "eyeOff"; text: "Esconder"
                onClicked: {
                    const q = hideF.text.trim().toLowerCase()
                    if (!q) return
                    const e = DesktopEntries.applications.values.find(x => (x.name ?? "").toLowerCase() === q) ?? DesktopEntries.applications.values.find(x => (x.name ?? "").toLowerCase().includes(q))
                    if (e && (Settings.launcherHidden || []).indexOf(e.id) < 0) Settings.launcherHidden = (Settings.launcherHidden || []).concat([e.id])
                    hideF.text = ""
                }
            }
        }
        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: Settings.launcherHidden || []
                delegate: Rectangle {
                    required property string modelData
                    readonly property var e: DesktopEntries.byId(modelData)
                    height: 34; width: hr.implicitWidth + 20; radius: 17; color: Theme.track; border.width: 1; border.color: Theme.border
                    Row {
                        id: hr
                        anchors.centerIn: parent
                        spacing: 8
                        UiText { text: parent.parent.e ? parent.parent.e.name : parent.parent.modelData; color: Theme.muted; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                        UiIcon { name: "eye"; size: 14; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter
                            MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: Settings.launcherHidden = (Settings.launcherHidden || []).filter(x => x !== hr.parent.modelData) } }
                    }
                }
            }
        }
    }

    Card {
        icon: "send"
        title: "Comandos, emoji e símbolos"
        UiLabel { text: "Ao escolher um emoji ou símbolo" }
        UiSeg { options: [["copy", "Copiar", "cards"], ["type", "Digitar no app", "keyboard"]]; value: Settings.launcherPick; onPicked: v => Settings.launcherPick = v }
        Row {
            spacing: 10
            UiText { anchors.verticalCenter: parent.verticalCenter; text: "Terminal do modo comando"; color: Theme.text; font.pixelSize: 13 }
            UiField { width: 200; text: Settings.launcherTerminal; placeholderText: "kitty"; onEditingFinished: Settings.launcherTerminal = text.trim() || "kitty" }
        }
        UiText { width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 12
            text: "Na área de transferência: Enter copia de novo, clique direito fixa um texto no topo e Delete apaga do histórico." }
    }

    Card {
        icon: "animation"
        title: "Animação"
        subtitle: "As animações são criadas e editadas na página Animações."
        AnimPicker { target: "launcher" }
    }

    Card {
        icon: "history"
        title: "Histórico de uso"
        subtitle: "O launcher conta quantas vezes você abriu cada app para ordenar os resultados."
        UiButton { icon: "broom"; text: "Limpar histórico"; kind: "danger"; onClicked: Settings.launcherUsage = ({}) }
    }
}
