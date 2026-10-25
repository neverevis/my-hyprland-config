// Pagina "Paineis" (kit Set*): escolhe o painel (Inicio, Launcher, Notificacoes, Tela e cantos) em cartoes e mostra so as
// secoes dele logo abaixo (so a escolhida existe: menos rolagem). A busca indexa cada painel separado (SettingsWindow.indexSources).
import QtQuick

SetPage {
    id: page
    title: "Painéis"
    subtitle: "Os painéis que saem da moldura e as zonas da tela"
    // sub-pagina: home, launcher, notifications ou more (visao geral, barra lateral, luz noturna, clarao, cantos ativos, equalizador)
    readonly property var subs: [["home", "Início", "dashboard"], ["launcher", "Launcher", "apps"], ["notifications", "Notificações", "bell"], ["more", "Tela e cantos", "arrow_top_left"]]
    readonly property string sub: ({ home: "home", launcher: "launcher", notifications: "notifications", more: "more", overview: "more", left: "more" })[Settings.settingsSub] ?? "home"

    SetSection {
        SetChoice {
            style: "tiles"; columns: 4; thumbHeight: 52
            options: page.subs
            value: page.sub
            onPicked: v => Settings.settingsSub = v
        }
    }
    Loader {
        width: parent.width
        sourceComponent: page.sub === "launcher" ? launcherC : page.sub === "notifications" ? notifC : page.sub === "more" ? moreC : homeC
    }
    Component { id: homeC; PageHome {} }
    Component { id: launcherC; PageLauncher {} }
    Component { id: notifC; PageNotifications {} }
    Component { id: moreC; PagePanelsMore {} }
}
