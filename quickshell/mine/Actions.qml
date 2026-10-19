// Acoes do shell num lugar so: o launcher (prefixo "/") e os botoes rapidos do Inicio usam a mesma lista.
// Cada acao: id, nome, descricao, icone (Ico), palavras-chave, run(). Algumas sao liga/desliga (on()).
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root
    function sh(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }
    readonly property string bin: Quickshell.env("HOME") + "/.local/bin/"

    readonly property var list: [
        { id: "lock", name: "Bloquear a tela", icon: "lock", keys: "lock bloquear", run: () => Power.lock() },
        { id: "suspend", name: "Suspender", icon: "sleep", keys: "sleep dormir suspender", run: () => Power.run("suspend") },
        { id: "logout", name: "Sair da sessão", icon: "logout", keys: "logout sair", run: () => Power.run("logout") },
        { id: "reboot", name: "Reiniciar", icon: "restart", keys: "reboot reiniciar", run: () => Power.run("reboot") },
        { id: "poweroff", name: "Desligar", icon: "power", keys: "shutdown desligar", run: () => Power.run("poweroff") },
        { id: "power", name: "Menu de energia", icon: "power", keys: "energia sessao", run: () => Power.menuOpen = true },
        { id: "shot", name: "Capturar uma área", desc: "Seletor do shell: arraste ou clique numa janela; copia e salva", icon: "frame", keys: "print screenshot captura recorte", run: () => Capture.start("copy") },
        { id: "ocr", name: "Copiar texto da tela (OCR)", desc: "Escolha uma área: o texto vai para a área de transferência", icon: "textBox", keys: "ocr texto ler copiar tesseract", run: () => Capture.start("ocr") },
        { id: "translateScreen", name: "Traduzir um pedaço da tela", desc: "Lê o texto da área e copia a tradução", icon: "earth", keys: "traduzir tradutor translate tela", run: () => Capture.start("translate") },
        { id: "annotate", name: "Capturar e anotar", desc: "Abre a captura no satty", icon: "pencil", keys: "anotar desenhar satty captura", run: () => Capture.start("annotate") },
        { id: "overlay", name: "Painel de jogo", desc: "Mira, notas, imagem, gravação, volume por app e sistema por cima de tudo", icon: "gamepad", keys: "jogo game overlay mira crosshair", run: () => Quickshell.execDetached(["qs", "-c", "mine", "ipc", "call", "overlay", "toggle"]) },
        { id: "shelf", name: "Prateleira de arquivos", desc: "Solte arquivos e arraste de volta para outro lugar", icon: "layers", keys: "prateleira dropover arquivos shelf", run: () => Quickshell.execDetached(["qs", "-c", "mine", "ipc", "call", "shelf", "toggle"]) },
        { id: "lens", name: "Buscar imagem da tela (Google Lens)", desc: "Envia a área para o litterbox.catbox.moe (apaga em 1 h)", icon: "search", keys: "lens google buscar imagem", run: () => Capture.start("lens") },
        { id: "shotFull", name: "Capturar a tela inteira", icon: "fullscreen", keys: "print screenshot captura tela", run: () => sh("sleep 0.4; " + root.bin + "screenshot-area --full") },
        { id: "picker", name: "Pegar uma cor da tela", desc: "Copia o código da cor", icon: "palette", keys: "color picker cor conta-gotas hyprpicker", run: () => sh("sleep 0.3; hyprpicker -a") },
        { id: "record", name: "Gravar a tela", desc: "De novo para parar", icon: "monitor", keys: "record gravar video", toggle: true, on: () => Recorder.active, run: () => Recorder.toggle(false) },
        { id: "recordArea", name: "Gravar uma área", icon: "frame", keys: "record gravar area", run: () => Recorder.active ? Recorder.stop() : Capture.start("record") },
        { id: "dnd", name: "Não perturbe", icon: "bellOff", keys: "dnd notificacoes silencio", toggle: true, on: () => Settings.notifDnd, run: () => Settings.notifDnd = !Settings.notifDnd },
        { id: "caffeine", name: "Manter acordado", desc: "Pausa o bloqueio e o descanso automáticos", icon: "coffee", keys: "caffeine idle acordado", toggle: true, on: () => Idle.paused, run: () => Idle.paused = !Idle.paused },
        { id: "theme", name: "Alternar tema claro / escuro", icon: "themeAuto", keys: "tema dark light claro escuro", run: () => Settings.themeMode = Settings.themeModeEff === "dark" ? "light" : "dark" },
        { id: "wallNext", name: "Próximo wallpaper", icon: "next", keys: "wallpaper fundo proximo", run: () => Wallpaper.step(1) },
        { id: "wallRandom", name: "Wallpaper aleatório", icon: "dice", keys: "wallpaper fundo aleatorio", run: () => Wallpaper.random() },
        { id: "wallPick", name: "Escolher o wallpaper", icon: "wallpaper", keys: "wallpaper fundo seletor", run: () => Settings.wpPickerOpen = true },
        { id: "widgets", name: "Editar os widgets", icon: "dashboard", keys: "widgets area de trabalho editar", run: () => { Settings.desktopOn = true; DeskState.editing = true } },
        { id: "widgetsToggle", name: "Mostrar os widgets", icon: "eye", keys: "widgets mostrar esconder", toggle: true, on: () => Settings.desktopOn, run: () => Settings.desktopOn = !Settings.desktopOn },
        { id: "notifClear", name: "Limpar as notificações", icon: "broom", keys: "notificacoes limpar", run: () => Quickshell.execDetached(["qs", "-c", "mine", "ipc", "call", "notifications", "clear"]) },
        { id: "settings", name: "Configurações do shell", icon: "cog", keys: "settings configuracoes opcoes", run: () => Settings.settingsOpen = true },
        { id: "anims", name: "Animações", icon: "animation", keys: "animacoes curvas molas", run: () => { Settings.settingsPage = "anim"; Settings.settingsOpen = true } },
        { id: "integrated", name: "Composição: tudo na moldura", icon: "frame", keys: "moldura integrado composicao", run: () => Settings.applyComposition("integrated") },
        { id: "independent", name: "Composição: tudo solto", icon: "cards", keys: "solto independente composicao", run: () => Settings.applyComposition("independent") },
        { id: "overview", name: "Visão geral dos workspaces", icon: "view_grid", keys: "overview workspaces janelas exposicao", run: () => Quickshell.execDetached(["qs", "-c", "mine", "ipc", "call", "overview", "toggle"]) },
        { id: "home", name: "Painel Início", icon: "home", keys: "inicio painel", run: () => Settings.homeOpen = true },
        { id: "restart", name: "Reiniciar o shell", icon: "refresh", keys: "reload restart quickshell", run: () => sh("shell-switch restart") }
    ]
    function find(id) { return list.find(a => a.id === id) ?? null }
    function run(id) { const a = find(id); if (a) a.run() }
}
