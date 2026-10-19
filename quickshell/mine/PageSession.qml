// Pagina "Sessao": foto de perfil, tela de bloqueio (Super + L) e menu de energia (Ctrl + Alt + Del).
import Quickshell
import QtQuick

Column {
    spacing: 14

    Card {
        icon: "account"
        title: "Foto de perfil"
        subtitle: "Aparece no Início, no menu de energia e na tela de bloqueio. A imagem é recortada em quadrado."
        Row {
            spacing: 16
            Avatar { size: 72; editable: true }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                UiText { text: Profile.name; color: Theme.text; font.pixelSize: 16; font.weight: Font.Bold }
                UiText { text: "Clique na foto para trocar (fica salva em ~/.face)"; color: Theme.muted; font.pixelSize: 12 }
            }
        }
    }
    Card {
        icon: "lock"
        title: "Tela de bloqueio"
        subtitle: "Super + L. A senha é verificada pelo sistema, como no login."
        Row {
            spacing: 8
            UiButton { icon: "eye"; text: "Prévia"; kind: "accent"; onClicked: { Settings.settingsOpen = false; Quickshell.execDetached(["qs", "-c", "mine", "ipc", "call", "lockpreview", "toggle"]) } }
            UiButton { icon: "lock"; text: "Bloquear agora"; onClicked: { Settings.settingsOpen = false; Power.lock() } }
        }
        UiSlider { label: "Desfoque do wallpaper"; icon: "blur"; from: 0; to: 100; value: Settings.lockBlur; suffix: " %"; onMoved: v => Settings.lockBlur = v }
        UiSlider { label: "Escurecimento"; icon: "night"; from: 0; to: 80; value: Settings.lockDim; suffix: " %"; onMoved: v => Settings.lockDim = v }
        UiSwitch { label: "Relógio com segundos"; icon: "clock"; checked: Settings.lockSeconds; onToggled: on => Settings.lockSeconds = on }
        UiSwitch { label: "Mostrar a música tocando"; icon: "music"; description: "Com controles de anterior, pausar e próxima."; checked: Settings.lockMedia; onToggled: on => Settings.lockMedia = on }
        UiLabel { text: "Relógio" }
        UiSeg { options: [["big", "Grande"], ["analog", "Flor"], ["digital", "Digital"], ["daily", "Diário"], ["pixel", "Pixel"]]; value: Settings.lockClock; onPicked: v => Settings.lockClock = v }
        UiSeg { options: [["top", "No topo", "arrowUp"], ["center", "No centro", "alignCenter"]]; value: Settings.lockClockPos; onPicked: v => Settings.lockClockPos = v }
        UiLabel { text: "Senha" }
        UiSeg { options: [["dots", "Bolinhas"], ["shapes", "Formas (flor, estrela…)"]]; value: Settings.lockChars; onPicked: v => Settings.lockChars = v }
        UiSwitch { label: "Destravar o chaveiro junto"; icon: "lockOpen"; description: "Usa a mesma senha para abrir o gnome-keyring (senhas salvas de apps), se ele estiver trancado."; checked: Settings.lockKeyring; onToggled: on => Settings.lockKeyring = on }
        UiSwitch { label: "Botões de energia na tela de bloqueio"; icon: "power"; description: "Desligado: para desligar ou reiniciar é preciso desbloquear antes."; checked: Settings.lockPower; onToggled: on => Settings.lockPower = on }
        UiLabel { text: "Animação de entrada" }
        AnimPicker { target: "lock" }
    }
    Card {
        icon: "sleep"
        title: "Inatividade"
        subtitle: "O que acontece quando você fica um tempo sem usar o computador (0 = nunca). Vídeos e jogos que pedem para a tela não dormir são respeitados."
        UiSlider { label: "Bloquear depois de"; icon: "lock"; from: 0; to: 60; value: Settings.idleLock; suffix: " min"; onMoved: v => Settings.idleLock = v }
        UiSlider { label: "Apagar a tela depois de"; icon: "monitor"; from: 0; to: 90; value: Settings.idleScreenOff; suffix: " min"; onMoved: v => Settings.idleScreenOff = v }
        UiSlider { label: "Suspender depois de"; icon: "sleep"; from: 0; to: 240; value: Settings.idleSuspend; suffix: " min"; onMoved: v => Settings.idleSuspend = Math.round(v / 5) * 5 }
        UiSwitch { label: "Não contar enquanto toca música"; description: "Com algo tocando (Spotify, navegador…), nada disso acontece."; icon: "music"; checked: Settings.idleMedia; onToggled: on => Settings.idleMedia = on }
        UiText {
            width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 12
            text: Settings.idleLock === 0 && Settings.idleScreenOff === 0 && Settings.idleSuspend === 0 ? "Tudo desligado." :
                  "Pausar por um tempo:  qs -c mine ipc call idle hold   (de novo para voltar)."
        }
    }

    Card {
        icon: "lock"
        title: "Senha de administrador (polkit)"
        subtitle: "Quando um programa pede permissão de administrador (montar disco, instalar, mudar o sistema), o pedido aparece num cartão do shell."
        UiSwitch { label: "Usar o shell para os pedidos de senha"; checked: Settings.polkitOn; onToggled: on => Settings.polkitOn = on }
        UiText {
            visible: Settings.polkitOn
            width: parent.width; wrapMode: Text.WordWrap; font.pixelSize: 12
            color: Settings.polkitRegistered ? Theme.accent : Theme.danger
            text: Settings.polkitRegistered ? "Ativo: os pedidos vão aparecer aqui." : "Não deu para registrar: outro agente (provavelmente o polkit-gnome, iniciado no hyprland/execs.lua) já está rodando. Tire ele do autostart e reinicie a sessão."
        }
    }

    Card {
        icon: "power"
        title: "Menu de energia"
        subtitle: "Ctrl + Alt + Del, o botão no Início ou o módulo \"Energia\" nas barras."
        UiButton { icon: "play"; text: "Abrir o menu"; kind: "accent"; onClicked: { Settings.settingsOpen = false; Power.menuOpen = true } }
        UiSlider { label: "Confirmação antes de sair, reiniciar ou desligar"; icon: "timer"; from: 0; to: 10; value: Settings.powerConfirm; suffix: " s"; onMoved: v => Settings.powerConfirm = v }
        UiText { width: parent.width; wrapMode: Text.WordWrap; text: Settings.powerConfirm > 0 ? "Uma contagem aparece no botão; clique de novo para fazer na hora ou Esc para cancelar." : "Sem contagem: a ação acontece no primeiro clique."; color: Theme.muted; font.pixelSize: 12 }
        UiLabel { text: "Animação" }
        AnimPicker { target: "power" }
    }

    Card {
        icon: "cog"
        title: "Sistema"
        subtitle: "Cuidados com o volume, as atualizações, a hora e os sons do shell."
        UiSwitch { label: "Relógio de 24 horas"; icon: "clock"; description: "Barra, ilha, tela de bloqueio e detalhes (os widgets têm a opção própria)."; checked: Settings.clock24; onToggled: on => Settings.clock24 = on }
        UiSwitch { label: "Avisar antes de desligar durante uma atualização"; icon: "power"; description: "Com o pacman (ou yay/paru) rodando, desligar, reiniciar ou sair pede confirmação."; checked: Settings.sessionGuard; onToggled: on => Settings.sessionGuard = on }
        UiLabel { text: "Proteção do volume" }
        UiSwitch { label: "Limitar o volume"; icon: "volume"; description: "Nunca passa do teto, e um salto grande de uma vez (um app que aumenta sozinho, a roda do mouse) fica limitado."; checked: Settings.volGuard; onToggled: on => Settings.volGuard = on }
        UiSlider { visible: Settings.volGuard; label: "Teto"; from: 30; to: 150; value: Settings.volMax; suffix: " %"; onMoved: v => Settings.volMax = Math.round(v) }
        UiSlider { visible: Settings.volGuard; label: "Maior aumento de uma vez (0 = sem limite)"; from: 0; to: 50; value: Settings.volJump; suffix: " %"; onMoved: v => Settings.volJump = Math.round(v) }
        UiLabel { text: "Atualizações" }
        UiText { text: SystemGuard.updates < 0 ? "Verificando…" : SystemGuard.updates === 0 ? "Sistema em dia." : SystemGuard.updates + " atualização(ões) disponível(is)."; color: Theme.muted; font.pixelSize: 12 }
        UiSlider { label: "Verificar a cada"; from: 1; to: 24; value: Settings.updHours; suffix: " h"; onMoved: v => Settings.updHours = Math.round(v) }
        UiSlider { label: "Avisar a partir de (0 = nunca)"; from: 0; to: 200; value: Settings.updWarn; suffix: " pacotes"; onMoved: v => Settings.updWarn = Math.round(v / 5) * 5 }
        UiButton { icon: "refresh"; text: "Verificar agora"; kind: "ghost"; onClicked: SystemGuard.checkUpdates() }
        UiLabel { text: "Outros daemons de notificação" }
        UiText { width: parent.width; wrapMode: Text.WordWrap; color: SystemGuard.conflicts.length ? Theme.danger : Theme.muted; font.pixelSize: 12
            text: SystemGuard.conflicts.length ? "Rodando junto com o shell: " + SystemGuard.conflicts.join(", ") + " (as notificações podem ir para ele)." : "Nenhum conflito." }
        Row {
            spacing: 8
            UiButton { visible: SystemGuard.conflicts.length > 0; icon: "close"; text: "Encerrar agora"; kind: "danger"; onClicked: { Quickshell.execDetached(["pkill", "-x", SystemGuard.conflicts.join("|")]); SystemGuard.conflicts = [] } }
            UiButton { icon: "refresh"; text: "Procurar"; kind: "ghost"; onClicked: SystemGuard.scan() }
        }
        UiSwitch { label: "Encerrar sozinho ao iniciar"; checked: Settings.killConflicts; onToggled: on => Settings.killConflicts = on }
        UiLabel { text: "Sons do shell" }
        UiSwitch { label: "Sons"; icon: "speaker"; description: "Notificação nova, captura de tela e erro (sons do sistema)."; checked: Settings.sounds; onToggled: on => Settings.sounds = on }
        UiSwitch { visible: Settings.sounds; label: "Clique ao mudar o volume"; checked: Settings.soundVolChange; onToggled: on => Settings.soundVolChange = on }
        UiSlider { visible: Settings.sounds; label: "Volume dos sons"; from: 10; to: 100; value: Settings.soundVolume; suffix: " %"; onMoved: v => Settings.soundVolume = Math.round(v) }
    }
}
