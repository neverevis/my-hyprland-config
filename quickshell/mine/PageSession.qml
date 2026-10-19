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
                Text { text: Profile.name; color: Theme.text; font.pixelSize: 16; font.weight: Font.Bold }
                Text { text: "Clique na foto para trocar (fica salva em ~/.face)"; color: Theme.muted; font.pixelSize: 12 }
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
        Text {
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
        Text {
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
        Text { width: parent.width; wrapMode: Text.WordWrap; text: Settings.powerConfirm > 0 ? "Uma contagem aparece no botão; clique de novo para fazer na hora ou Esc para cancelar." : "Sem contagem: a ação acontece no primeiro clique."; color: Theme.muted; font.pixelSize: 12 }
        UiLabel { text: "Animação" }
        AnimPicker { target: "power" }
    }
}
