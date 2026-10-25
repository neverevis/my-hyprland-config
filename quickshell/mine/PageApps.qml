// Pagina "Aplicativos" (kit Set*): resumo (abre a janela Aplicativos, AppsWindow.qml: apps, pacotes, instalar, atualizacoes),
// programas ao iniciar, aplicativos padrao e webapps. Estado e comandos em Apps.qml; so roda com a pagina aberta.
import Quickshell
import QtQuick

SetPage {
    id: page
    title: "Aplicativos"
    subtitle: "Gerenciador de apps, o que abre ao iniciar e aplicativos padrão"
    Component.onCompleted: { Apps.use(); Apps.loadStartup(); Webapps.refresh() }
    Component.onDestruction: Apps.release()

    // ---- resumo ----
    SetSection {
        title: "Resumo"; icon: "apps"
        SetRow {
            icon: "package"
            label: Apps.loaded ? (Apps.apps.length === 1 ? "1 app instalado" : Apps.apps.length.toLocaleString(Qt.locale("pt_BR"), "f", 0) + " apps instalados") : Apps.listErr ? "Não consegui ler os apps" : "Lendo os apps…"
            description: (Apps.pkgs > 0 ? (Apps.pkgs === 1 ? "1 pacote" : Apps.pkgs.toLocaleString(Qt.locale("pt_BR"), "f", 0) + " pacotes") + " · " : "") + (Apps.listErr && !Apps.loaded ? "abra a janela Aplicativos para tentar de novo" : "instalar, remover e atualizar na janela Aplicativos")
            UiButton { icon: "apps"; text: "Abrir Aplicativos"; kind: "accent"; onClicked: Apps.openWindow("apps") }
        }
        SetRow {
            icon: "refresh"
            label: {
                const u = SystemGuard.updates
                return SystemGuard.checking ? "Verificando atualizações…" : u < 0 ? "Atualizações indisponíveis: falta o checkupdates (pacman-contrib)" : u === 0 ? "Tudo em dia" : u + (u === 1 ? " atualização pendente" : " atualizações pendentes")
            }
            description: "Veja a lista e atualize tudo na aba Atualizações"
            UiButton { text: "Verificar agora"; kind: "ghost"; enabled: !SystemGuard.checking; onClicked: SystemGuard.checkUpdates() }
            UiButton { icon: "download"; text: "Ver atualizações"; onClicked: Apps.openWindow("updates") }
        }
        SetRow { visible: Apps.dry; icon: "info"; label: "Modo de teste"; description: "Nenhum comando é executado de verdade; só aparece o que rodaria" }
    }

    // ---- ao iniciar ----
    SetSection {
        title: "Ao iniciar"; icon: "rocket"
        subtitle: "Comandos do Hyprland e programas da pasta autostart que abrem ao entrar na sessão"
        Repeater {
            model: Settings.list(Settings.hyprAutostart)
            delegate: SetRow {
                required property string modelData
                required property int index
                icon: "play"; label: modelData
                UiButton { icon: "trash"; kind: "danger"; onClicked: { const l = Settings.list(Settings.hyprAutostart); l.splice(index, 1); Settings.hyprAutostart = l } }
            }
        }
        SetRow {
            visible: Settings.list(Settings.hyprAutostart).length === 0 && Apps.startup.filter(s => !s.system).length === 0
            icon: "info"; label: Apps.startupLoaded ? "Nenhum programa ao iniciar" : "Lendo os programas…"
            description: Apps.startupLoaded ? "Use Novo comando abaixo para escolher o primeiro" : ""
        }
        SetRow {
            visible: Apps.startupErr; icon: "info"; label: "Não deu para mudar esse programa"
            description: "A pasta autostart não aceitou a alteração; confira as permissões e tente de novo"
            UiButton { text: "Tentar de novo"; kind: "ghost"; onClicked: Apps.loadStartup() }
        }
        SetRow {
            icon: "plus"; label: "Novo comando"
            CmdField { id: asF; fieldWidth: 220; placeholderText: "ex.: discord --start-minimized"; onAccepted: asB.clicked() }
            UiButton { id: asB; icon: "plus"; text: "Adicionar"; kind: "accent"; onClicked: { const c = asF.text.trim(); if (!c) return; Settings.hyprAutostart = (Settings.list(Settings.hyprAutostart)).concat([c]); asF.text = "" } }
            below: CmdBelow { f: asF }
        }
        Repeater {
            model: Apps.startup.filter(s => !s.system)
            delegate: SetRow {
                required property var modelData
                icon: "rocket"; label: modelData.name; description: modelData.comment || modelData.exec
                checked: modelData.enabled
                onToggled: on => Apps.setStartup(modelData.file, on)
            }
        }
        SetExpander {
            icon: "cog"; label: "Do sistema"; description: "Só leitura: vêm de /etc/xdg/autostart, são de pacotes (" + Apps.startup.filter(s => s.system).length.toLocaleString(Qt.locale("pt_BR"), "f", 0) + ")"
            lazy: Component {
                SetBlock {
                    sub: true
                    Repeater {
                        model: Apps.startup.filter(s => s.system)
                        delegate: Column {
                            required property var modelData
                            width: parent.width
                            spacing: 1
                            UiText { width: parent.width; elide: Text.ElideRight; text: modelData.name; color: Theme.text; font.pixelSize: 13 }
                            UiText { width: parent.width; elide: Text.ElideRight; text: modelData.exec; color: Theme.muted; font.pixelSize: 11 }
                        }
                    }
                }
            }
        }
    }

    // ---- apps padrao ----
    SetSection {
        title: "Aplicativos padrão"; icon: "apps"
        subtitle: "O que abre ao configurar rede, Bluetooth, volume etc.; vazio usa o padrão mostrado"
        Repeater {
            model: AppCmds.items
            delegate: SetRow {
                id: ar
                required property var modelData
                icon: modelData.icon; label: modelData.label
                CmdField {
                    id: cf
                    text: (Settings.appCmds || ({}))[ar.modelData.id] || ""
                    placeholderText: ar.modelData.def
                    onCommitted: AppCmds.set(ar.modelData.id, text)
                }
                below: CmdBelow { f: cf }
            }
        }
    }

    // ---- webapps ----
    SetSection {
        title: "Webapps"; icon: "web"
        subtitle: "Cada site vira um aplicativo sem abas, também no launcher"
        Repeater {
            model: Webapps.apps
            delegate: SetRow {
                id: wr
                required property var modelData
                icon: "web"; label: modelData.name; description: modelData.url
                UiButton { icon: "play"; kind: "ghost"; onClicked: Quickshell.execDetached(["gtk-launch", "shell-webapp-" + wr.modelData.id]) }
                UiButton { icon: "trash"; kind: "danger"; onClicked: Webapps.remove(wr.modelData.id) }
            }
        }
        SetRow {
            icon: "plus"; label: "Novo webapp"; description: Webapps.msg !== "" ? Webapps.msg : (Webapps.apps.length === 0 ? "Nenhum webapp ainda. Digite um endereço; separe vários por espaço" : "Separe vários endereços por espaço")
            UiField { id: waF; width: 220; placeholderText: "web.whatsapp.com"; onAccepted: waB.clicked() }
            UiButton { id: waB; icon: "plus"; text: Webapps.busy ? "Criando…" : "Criar"; kind: "accent"; enabled: !Webapps.busy; onClicked: { Webapps.add(waF.text); waF.text = "" } }
        }
    }
}
