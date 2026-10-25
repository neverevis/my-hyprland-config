// Painel "Launcher" (secoes do kit dentro da pagina Paineis): posicao, tamanho, busca (buscador, sites fora, o que aparece sem prefixo),
// prefixos, favoritos e escondidos, emoji/comandos e animacao (Super + Tab). A grade de workspaces (Visao geral) esta em "Tela e cantos".
import Quickshell
import QtQuick

Column {
    id: page
    spacing: SetK.xl
    readonly property var engines: [
        ["https://www.google.com/search?q=", "Google", "search"], ["https://duckduckgo.com/?q=", "DuckDuckGo", "search"], ["https://search.brave.com/search?q=", "Brave", "search"],
        ["https://www.startpage.com/do/search?q=", "Startpage", "search"], ["https://kagi.com/search?q=", "Kagi", "search"], ["https://www.bing.com/search?q=", "Bing", "search"],
        ["https://www.perplexity.ai/search?q=", "Perplexity", "search"], ["https://www.youtube.com/results?search_query=", "YouTube", "play"]]
    function setIn(prop, key, val) { const o = Object.assign({}, Settings[prop] || {}); o[key] = val; Settings[prop] = o }

    SetSection {
        title: "Launcher de aplicativos"; icon: "apps"; subtitle: "Abre com Super + Tab. Os mais usados aparecem primeiro"
        SetRow { icon: "play"; label: "Abrir o launcher"; UiButton { icon: "play"; text: "Abrir"; kind: "accent"; onClicked: Settings.launcherOpen = true } }
        SetRow { icon: "frame"; label: "Acoplado à moldura"; description: "Sai da borda como uma barra. Desligado, flutua"; checked: Settings.launcherDocked; onToggled: on => Settings.launcherDocked = on }
        SetRow { visible: Settings.launcherDocked; icon: "dock"; label: "Lado da tela"; below: SidePick { value: Settings.launcherSide; onPicked: v => Settings.launcherSide = v } }
        SetChoice { visible: !Settings.launcherDocked; icon: "alignCenter"; label: "Onde flutua"; options: [["center", "Centro", "alignCenter"], ["top", "Topo", "arrowUp"]]; value: Settings.launcherPos; onPicked: v => Settings.launcherPos = v }
        SetSlider { icon: "swap_horizontal"; label: "Largura"; from: 400; to: 1000; step: 10; unit: " px"; def: 640; value: Settings.launcherWidth; onMoved: v => Settings.launcherWidth = Math.round(v) }
        SetSlider { icon: "view_column"; label: "Resultados visíveis"; from: 3; to: 12; def: 7; value: Settings.launcherRows; onMoved: v => Settings.launcherRows = Math.round(v) }
        SetExpander {
            icon: "tune"; label: "Tamanho e curvas"; description: "Ícones, cantos, deslocamento e curva da moldura"
            SetSlider { sub: true; label: "Tamanho dos ícones"; from: 20; to: 56; unit: " px"; def: 32; value: Settings.launcherIcon; onMoved: v => Settings.launcherIcon = Math.round(v) }
            SetSlider { sub: true; label: "Arredondamento"; from: 0; to: 40; unit: " px"; def: 22; value: Settings.launcherRadius; onMoved: v => Settings.launcherRadius = Math.round(v) }
            SetSlider { visible: Settings.launcherDocked; sub: true; label: "Deslocamento"; from: -1000; to: 1000; step: 10; unit: " px"; def: 0; value: Settings.launcherOffset; onMoved: v => Settings.launcherOffset = Math.round(v) }
            SetSlider { visible: Settings.launcherDocked; sub: true; label: "Curva ao encontrar a moldura"; from: 0; to: 40; unit: " px"; def: 13; value: Settings.launcherFillet; onMoved: v => Settings.launcherFillet = Math.round(v) }
        }
        SetExpander { icon: "animation"; label: "Animação"; lazy: Component { SetBlock { sub: true; AnimPicker { width: parent.width; target: "launcher" } } } }
    }

    SetSection {
        title: "Busca"; icon: "search"; subtitle: "Sem prefixo mostra apps e, se quiser, contas, ações, opções do shell e a web"
        SetChoice {
            icon: "web"; label: "Buscador da web"
            style: "tiles"; minTile: 100; thumbHeight: 34
            options: page.engines
            value: Settings.launcherEngine; onPicked: v => Settings.launcherEngine = v
        }
        SetRow {
            icon: "link"; label: "Endereço do buscador"; description: "O texto vai no fim (ou onde estiver %s)"
            UiField { width: 260; text: Settings.launcherEngine; onEditingFinished: if (text.trim() !== "") Settings.launcherEngine = text.trim() }
        }
        SetRow { icon: "search"; label: "Busca aproximada"; description: "\"ffx\" acha o Firefox. Desligada, só nomes que contêm o texto"; checked: Settings.launcherFuzzy; onToggled: on => Settings.launcherFuzzy = on }
        SetExpander {
            icon: "eye"; label: "Sem prefixo, mostrar também"; description: "Contas, ações, opções do shell e web"
            Repeater {
                model: [["math", "Contas", "Ex.: 12*3,5 mostra o resultado"], ["actions", "Ações do shell", "Bloquear, capturar, trocar o wallpaper…"],
                        ["settings", "Opções do shell", "Ex.: \"opacidade\" abre o ajuste direto"], ["web", "Buscar na web", "Sempre a última opção"]]
                delegate: SetRow {
                    required property var modelData
                    sub: true; label: modelData[1]; description: modelData[2]
                    checked: (Settings.launcherDefaults || {})[modelData[0]] !== false
                    onToggled: on => page.setIn("launcherDefaults", modelData[0], on)
                }
            }
        }
        SetExpander {
            icon: "close"; label: "Sites fora da busca"; description: "Um por linha, ex.: pinterest.com"
            SetBlock {
                sub: true
                OptionsForm {
                    width: parent.width
                    schema: [{ key: "launcherExclude", label: "Sites", type: "list" }]
                    get: k => Settings[k]
                    set: (k, v) => Settings[k] = v
                }
            }
        }
    }

    SetSection {
        title: "Prefixos e modos"; icon: "keyboard"; subtitle: "O primeiro caractere escolhe o modo"
        SetExpander {
            icon: "keyboard"; label: "Prefixos"; description: "Vazio desliga o modo"
            lazy: Component {
                SetBlock {
                    sub: true
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
            }
        }
        SetChoice { icon: "sticker"; label: "Ao escolher emoji ou símbolo"; options: [["copy", "Copiar", "cards"], ["type", "Digitar", "keyboard"]]; value: Settings.launcherPick; onPicked: v => Settings.launcherPick = v }
        SetRow { icon: "eyeOff"; label: "Esconder a área de transferência"; description: "Na busca com ; os textos viram bolinhas e as miniaturas somem"; checked: Settings.launcherClipHide; onToggled: on => Settings.launcherClipHide = on }
        SetRow { icon: "keyboard"; label: "Terminal do modo comando"; UiField { width: 140; text: Settings.launcherTerminal; placeholderText: "kitty"; onEditingFinished: Settings.launcherTerminal = text.trim() || "kitty" } }
    }

    SetSection {
        title: "Apps favoritos e escondidos"; icon: "sparkle"; subtitle: "No launcher, clique direito num app para favoritar"
        SetExpander {
            icon: "sparkle"; label: "Favoritos"; description: (Settings.launcherFavs || []).length ? ((Settings.launcherFavs || []).length === 1 ? "1 app, aparece primeiro" : (Settings.launcherFavs || []).length + " apps, aparecem primeiro") : "Nenhum ainda; marque um app no launcher para fixar aqui"
            lazy: Component {
                SetBlock {
                    sub: true
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
                }
            }
        }
        SetExpander {
            icon: "eyeOff"; label: "Escondidos"; description: (Settings.launcherHidden || []).length ? ((Settings.launcherHidden || []).length === 1 ? "1 app fora do launcher" : (Settings.launcherHidden || []).length + " apps fora do launcher") : "Nenhum app escondido"
            lazy: Component {
                SetBlock {
                    sub: true
                    Row {
                        spacing: 8
                        UiField { id: hideF; width: 260; placeholderText: "Nome do app para esconder…"; onAccepted: hideB.clicked() }
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
            }
        }
        SetRow { icon: "history"; label: "Histórico de uso"; description: "Quantas vezes você abriu cada app, para ordenar os resultados"; UiButton { icon: "broom"; text: "Limpar histórico"; kind: "danger"; onClicked: Settings.launcherUsage = ({}) } }
    }
}
