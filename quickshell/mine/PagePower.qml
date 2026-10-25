// Pagina "Energia e sessao" (kit Set*): tela de bloqueio, inatividade, senha de administrador (polkit), menu de energia,
// hora e data, atualizacoes e cuidados do sistema, volume e sons, bateria.
import Quickshell
import QtQuick

SetPage {
    id: page
    title: "Energia e sessão"
    subtitle: "Bloqueio, inatividade, menu de energia, hora, atualizações e sons"

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
        SetRow { icon: "lock"; label: "Usar o shell para os pedidos de senha"; checked: Settings.polkitOn; onToggled: on => Settings.polkitOn = on }
        SetRow {
            visible: Settings.polkitOn
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

    // ---- hora e data ----
    SetSection {
        title: "Hora e data"; icon: "clock"
        subtitle: "Relógio da barra, da ilha, do bloqueio e dos detalhes (os widgets têm opção própria)"
        SetBlock {
            Row {
                spacing: 14
                UiText { anchors.verticalCenter: parent.verticalCenter; text: DateTime.time(clk.date); color: Theme.text; font.pixelSize: 30; font.weight: Font.Bold; font.features: { "tnum": 1 } }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    UiText { text: DateTime.date(clk.date); color: Theme.text; font.pixelSize: 14 }
                    UiText { text: DateTime.dateYear(clk.date); color: Theme.muted; font.pixelSize: 12 }
                }
                SystemClock { id: clk; precision: Settings.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes }
            }
        }
        SetChoice {
            icon: "clockOutline"; label: "Formato"
            options: [["24", "24 horas", "clock"], ["ap", "12 h (am/pm)", "clockOutline"], ["AP", "12 h (AM/PM)", "clockOutline"]]
            value: Settings.clock24 ? "24" : Settings.clockAmPm
            onPicked: v => { if (v === "24") Settings.clock24 = true; else { Settings.clock24 = false; Settings.clockAmPm = v } }
        }
        SetRow { icon: "timer"; label: "Mostrar segundos"; description: "Na barra e na ilha (o bloqueio tem a sua opção)"; checked: Settings.clockSeconds; onToggled: on => Settings.clockSeconds = on }
        SetExpander {
            icon: "calendar"; label: "Formatos de data"; description: "Letras do Qt: d dd ddd dddd, M MM MMM MMMM, yy yyyy"
            SetRow { sub: true; label: "Data curta"; UiField { width: 220; placeholderText: "ddd, dd/MM"; text: Settings.dateFormat; onEditingFinished: Settings.dateFormat = text } }
            SetRow { sub: true; label: "Data longa"; description: "Vazio = padrão"; UiField { width: 220; placeholderText: "dddd, d 'de' MMMM"; text: Settings.dateLongFormat; onEditingFinished: Settings.dateLongFormat = text } }
            SetRow { sub: true; label: "Data com ano"; UiField { width: 220; placeholderText: "dd/MM/yyyy"; text: Settings.dateYearFormat; onEditingFinished: Settings.dateYearFormat = text } }
        }
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

    // ---- volume e sons ----
    SetSection {
        title: "Volume e sons"; icon: "volume"
        SetRow { icon: "shield"; label: "Limitar o volume"; description: "Nunca passa do teto e um salto grande de uma vez é contido"; checked: Settings.volGuard; onToggled: on => Settings.volGuard = on }
        SetSlider { visible: Settings.volGuard; sub: true; label: "Teto"; from: 30; to: 150; unit: " %"; value: Settings.volMax; onMoved: v => Settings.volMax = Math.round(v) }
        SetSlider { visible: Settings.volGuard; sub: true; label: "Maior aumento de uma vez"; from: 0; to: 50; unit: " %"; zeroLabel: "Sem limite"; value: Settings.volJump; onMoved: v => Settings.volJump = Math.round(v) }
        SetRow { icon: "speaker"; label: "Sons do shell"; description: "Notificação nova, captura de tela e erro"; checked: Settings.sounds; onToggled: on => Settings.sounds = on }
        SetSlider { visible: Settings.sounds; sub: true; label: "Volume dos sons"; from: 10; to: 100; unit: " %"; value: Settings.soundVolume; onMoved: v => Settings.soundVolume = Math.round(v) }
        SetRow { visible: Settings.sounds; sub: true; label: "Clique ao mudar o volume"; checked: Settings.soundVolChange; onToggled: on => Settings.soundVolChange = on }
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
