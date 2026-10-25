// Pagina "Energia e sessao" (kit Set*): tela de bloqueio, inatividade, senha de administrador (polkit), menu de energia,
// atualizacoes e cuidados do sistema, bateria (hora e data e volume e sons agora ficam nas paginas Data, hora e idioma e Som).
import Quickshell
import QtQuick

SetPage {
    id: page
    title: "Energia e sessão"
    subtitle: "Bloqueio, inatividade, menu de energia, atualizações e bateria"

    // ---- tela de bloqueio ----
    SetSection {
        title: "Tela de bloqueio"; icon: "lock"
        subtitle: "Super + L; a senha é verificada pelo sistema, como no login"
        SetRow {
            icon: "eye"; label: "Prévia"; description: "Veja a tela sem bloquear de verdade"
            UiButton { icon: "eye"; text: "Prévia"; kind: "accent"; onClicked: { Settings.settingsOpen = false; Quickshell.execDetached(["qs", "-c", "mine", "ipc", "call", "lockpreview", "toggle"]) } }
            UiButton { icon: "lock"; text: "Bloquear agora"; onClicked: { Settings.settingsOpen = false; Power.lock() } }
        }
        SetSlider { icon: "blur"; label: "Desfoque do wallpaper"; from: 0; to: 100; unit: " %"; value: Settings.lockBlur; onMoved: v => Settings.lockBlur = Math.round(v) }
        SetSlider { icon: "night"; label: "Escurecimento"; from: 0; to: 80; unit: " %"; value: Settings.lockDim; onMoved: v => Settings.lockDim = Math.round(v) }
        SetChoice {
            icon: "clock"; label: "Relógio"
            options: [["big", "Grande"], ["analog", "Flor"], ["digital", "Digital"], ["daily", "Diário"], ["pixel", "Pixel"]]
            value: Settings.lockClock; onPicked: v => Settings.lockClock = v
        }
        SetExpander {
            icon: "clockDigital"; label: "Relógio e música"; description: "Posição, segundos e controles de música"
            SetChoice { sub: true; label: "Posição"; options: [["top", "No topo", "arrowUp"], ["center", "No centro", "alignCenter"]]; value: Settings.lockClockPos; onPicked: v => Settings.lockClockPos = v }
            SetRow { sub: true; label: "Relógio com segundos"; checked: Settings.lockSeconds; onToggled: on => Settings.lockSeconds = on }
            SetRow { sub: true; label: "Mostrar a música tocando"; description: "Com anterior, pausar e próxima"; checked: Settings.lockMedia; onToggled: on => Settings.lockMedia = on }
        }
        SetExpander {
            icon: "shield"; label: "Senha e segurança"; description: "Caracteres, chaveiro e botões de energia"
            SetChoice { sub: true; label: "Ao digitar a senha"; options: [["dots", "Bolinhas"], ["shapes", "Formas"]]; value: Settings.lockChars; onPicked: v => Settings.lockChars = v }
            SetRow { sub: true; label: "Destravar o chaveiro junto"; description: "Usa a mesma senha para abrir o gnome-keyring, se estiver trancado"; checked: Settings.lockKeyring; onToggled: on => Settings.lockKeyring = on }
            SetRow { sub: true; label: "Botões de energia no bloqueio"; description: "Desligado: é preciso desbloquear antes de desligar"; checked: Settings.lockPower; onToggled: on => Settings.lockPower = on }
            SetRow { sub: true; label: "Pedir a senha para desligar"; description: "Desligar e reiniciar só depois da senha certa"; checked: Settings.lockRequirePw; onToggled: on => Settings.lockRequirePw = on }
        }
        SetExpander {
            icon: "animation"; label: "Animação de entrada"
            lazy: Component { SetBlock { sub: true; AnimPicker { target: "lock"; width: parent.width } } }
        }
    }

    // ---- inatividade ----
    SetSection {
        title: "Inatividade"; icon: "sleep"
        subtitle: Settings.idleLock === 0 && Settings.idleScreenOff === 0 && Settings.idleSuspend === 0 ? "Tudo desligado" : "Vídeos e jogos que pedem tela acesa são respeitados"
        SetSlider { icon: "lock"; label: "Bloquear depois de"; from: 0; to: 60; unit: " min"; zeroLabel: "Nunca"; def: 0; value: Settings.idleLock; onMoved: v => Settings.idleLock = Math.round(v) }
        SetSlider { icon: "monitor"; label: "Apagar a tela depois de"; from: 0; to: 90; unit: " min"; zeroLabel: "Nunca"; def: 0; value: Settings.idleScreenOff; onMoved: v => Settings.idleScreenOff = Math.round(v) }
        SetSlider { icon: "sleep"; label: "Suspender depois de"; from: 0; to: 240; step: 5; unit: " min"; zeroLabel: "Nunca"; def: 0; value: Settings.idleSuspend; onMoved: v => Settings.idleSuspend = Math.round(v / 5) * 5 }
        SetRow { icon: "music"; label: "Não contar enquanto toca música"; description: "Pausar por um tempo: qs -c mine ipc call idle hold"; checked: Settings.idleMedia; onToggled: on => Settings.idleMedia = on }
    }

    // ---- polkit ----
    SetSection {
        title: "Senha de administrador (polkit)"; icon: "shieldLock"
        subtitle: "Pedidos de permissão (montar disco, instalar) aparecem num cartão do shell"
        SetRow { icon: "lock"; label: "Usar sempre o shell para os pedidos de senha"; description: SysAct.shellAgent && !Settings.polkitOn ? "Já está em uso: nenhum outro agente está rodando" : "Desligado, o shell só assume quando nenhum outro agente está rodando"; checked: Settings.polkitOn; onToggled: on => Settings.polkitOn = on }
        SetRow {
            visible: SysAct.shellAgent
            sub: true; label: Settings.polkitRegistered ? "Ativo: os pedidos vão aparecer aqui" : "Não deu para registrar"
            description: Settings.polkitRegistered ? "" : "Outro agente (talvez o polkit-gnome do execs.lua) já roda; tire-o do autostart"
        }
    }

    // ---- menu de energia ----
    SetSection {
        title: "Menu de energia"; icon: "power"
        subtitle: "Ctrl + Alt + Del, o botão no Início ou o módulo Energia nas barras"
        SetRow { icon: "play"; label: "Abrir o menu"; UiButton { text: "Abrir"; kind: "accent"; onClicked: { Settings.settingsOpen = false; Power.menuOpen = true } } }
        SetSlider {
            icon: "timer"; label: "Confirmação antes de agir"
            description: Settings.powerConfirm > 0 ? "Uma contagem aparece no botão; clique de novo para agir na hora" : "A ação acontece no primeiro clique"
            from: 0; to: 10; unit: " s"; zeroLabel: "Sem contagem"; def: 0; value: Settings.powerConfirm; onMoved: v => Settings.powerConfirm = Math.round(v)
        }
        SetExpander {
            icon: "animation"; label: "Animação do menu"
            lazy: Component { SetBlock { sub: true; AnimPicker { target: "power"; width: parent.width } } }
        }
    }

    // ---- hora e data (mudou para a pagina Data, hora e idioma; mesmas chaves) ----
    SetSection {
        title: "Hora e data"; icon: "clock"
        subtitle: "Formato do relógio e da data, fuso horário e sincronização"
        SetRow { icon: "clockOutline"; label: "Formato da hora e da data"; description: "Mudou para Data, hora e idioma"; link: true; onClicked: Settings.settingsPage = "time" }
    }

    // ---- atualizacoes e cuidados do sistema ----
    SetSection {
        title: "Atualizações"; icon: "download"
        subtitle: SystemGuard.updates < 0 ? "Verificando…" : SystemGuard.updates === 0 ? "Sistema em dia" : SystemGuard.updates + " atualização(ões) disponível(is)"
        SetRow {
            icon: "refresh"; label: SystemGuard.checking ? "Verificando…" : "Verificar agora"
            description: Settings.updAur && SystemGuard.updAurN > 0 ? SystemGuard.updRepo + " do pacman e " + SystemGuard.updAurN + " do AUR" : ""
            UiButton { icon: "refresh"; text: "Verificar"; kind: "ghost"; enabled: !SystemGuard.checking; onClicked: SystemGuard.checkUpdates() }
            UiButton { icon: "download"; text: "Atualizar agora"; kind: "ghost"; onClicked: SystemGuard.runUpdate() }
        }
        SetRow { icon: "package"; label: "Contar também o AUR"; description: "Usa o yay (ou o paru) junto com o pacman"; checked: Settings.updAur; onToggled: on => { Settings.updAur = on; SystemGuard.checkUpdates() } }
        SetExpander {
            icon: "tune"; label: "Quando verificar e avisar"; description: "Intervalo e limites dos avisos"
            SetSlider { sub: true; label: "Verificar a cada"; from: 1; to: 24; unit: " h"; value: Settings.updHours; onMoved: v => Settings.updHours = Math.round(v) }
            SetSlider { sub: true; label: "Avisar a partir de"; from: 0; to: 200; step: 5; unit: " pacotes"; zeroLabel: "Nunca"; value: Settings.updWarn; onMoved: v => Settings.updWarn = Math.round(v / 5) * 5 }
            SetSlider { sub: true; label: "Ficar vermelho a partir de"; from: 0; to: 300; step: 5; unit: " pacotes"; zeroLabel: "Nunca"; value: Settings.updStrong; onMoved: v => Settings.updStrong = Math.round(v / 5) * 5 }
        }
    }
    SetSection {
        title: "Sistema"; icon: "cog"
        subtitle: "Cuidados com atualizações e com outros daemons de notificação"
        SetRow { icon: "power"; label: "Avisar antes de desligar numa atualização"; description: "Com o pacman, yay ou paru rodando, pede confirmação"; checked: Settings.sessionGuard; onToggled: on => Settings.sessionGuard = on }
        SetRow {
            icon: "bell"; label: "Outros daemons de notificação"
            description: SystemGuard.conflicts.length ? "Rodando junto: " + SystemGuard.conflicts.join(", ") : "Nenhum conflito"
            UiButton { visible: SystemGuard.conflicts.length > 0; icon: "close"; text: "Encerrar"; kind: "danger"; onClicked: { Quickshell.execDetached(["pkill", "-x", SystemGuard.conflicts.join("|")]); SystemGuard.conflicts = [] } }
            UiButton { icon: "refresh"; text: "Procurar"; kind: "ghost"; onClicked: SystemGuard.scan() }
        }
        SetRow { sub: true; label: "Encerrar sozinho ao iniciar"; checked: Settings.killConflicts; onToggled: on => Settings.killConflicts = on }
    }

    // ---- volume e sons (mudou para a pagina Som; mesmas chaves) ----
    SetSection {
        title: "Volume e sons"; icon: "volume"
        subtitle: "Limite de volume e sons do shell"
        SetRow { icon: "speaker"; label: "Limite de volume e sons do shell"; description: "Mudou para a página Som"; link: true; onClicked: Settings.settingsPage = "sound" }
    }

    // ---- bateria (so em computadores com bateria) ----
    SetSection {
        visible: Battery.present
        title: "Bateria"; icon: "battery"
        subtitle: "Avisos e ações quando a carga fica baixa"
        SetRow { icon: "bell"; label: "Avisar com notificação"; checked: Settings.batNotify; onToggled: on => Settings.batNotify = on }
        SetSlider { icon: "batteryAlert"; label: "Bateria baixa"; from: 5; to: 50; unit: " %"; value: Settings.batLow; onMoved: v => Settings.batLow = Math.round(v) }
        SetSlider { icon: "batteryAlert"; label: "Bateria crítica"; from: 1; to: 20; unit: " %"; value: Settings.batCritical; onMoved: v => Settings.batCritical = Math.round(v) }
        SetExpander {
            icon: "tune"; label: "Mais avisos"
            SetRow { sub: true; label: "Avisar quando carregar por completo"; checked: Settings.batFullNotify; onToggled: on => Settings.batFullNotify = on }
            SetRow { sub: true; label: "Suspender sozinho na carga crítica"; description: "Espera 30 segundos depois do aviso"; checked: Settings.batAutoSuspend; onToggled: on => Settings.batAutoSuspend = on }
            SetSlider { sub: true; label: "Aviso de mouse, teclado e fones"; from: 5; to: 50; unit: " %"; value: Settings.batPeripheralLow; onMoved: v => Settings.batPeripheralLow = Math.round(v) }
        }
    }
}
