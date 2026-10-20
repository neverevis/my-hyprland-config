// Tela de bloqueio (protocolo de bloqueio de sessao do Wayland: o Hyprland so libera depois da senha certa).
// Wallpaper desfocado, relogio grande, foto de perfil e o campo de senha (verificada pelo PAM, servico "login").
// Ao desbloquear, tudo some num fade direto para a area de trabalho (precisa de misc:session_lock_xray no Hyprland).
// Se o shell travar com a tela bloqueada: Ctrl+Alt+F3, entre no terminal e rode
//   shell-switch restart && qs -c mine ipc call session lock      (depois volte com Ctrl+Alt+F1 e digite a senha)
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Effects

Scope {
    id: root

    property string pw: ""
    property bool checking: false
    property string error: ""
    property int fails: 0
    property bool leaving: false        // senha certa: animacao de saida antes de soltar a tela
    property bool caps: false
    readonly property int leaveMs: 520

    // o bloqueio de verdade: so termina quando "locked" volta a falso
    WlSessionLock {
        id: lock
        locked: Power.locked
        onLockedChanged: if (locked) { root.pw = ""; root.error = ""; root.leaving = false; root.checking = false }

        WlSessionLockSurface {
            id: surf
            // transparente: o fundo preto e desenhado pela propria tela (assim a saida pode revelar a area de trabalho)
            color: "transparent"
            LockView { anchors.fill: parent }
        }
    }

    PamContext {
        id: pam
        config: "login"
        onPamMessage: { if (responseRequired) respond(root.pw) }
        onCompleted: result => {
            root.checking = false
            if (result === PamResult.Success) {
                root.fails = 0
                if (Settings.lockKeyring && !root.preview) { keyring.secret = root.pw; keyring.running = true }
                root.leaving = true
                unlockTimer.restart()
            } else {
                root.fails++
                root.pw = ""
                root.error = result === PamResult.MaxTries ? "Muitas tentativas. Aguarde um pouco e tente de novo."
                    : (root.fails >= 3 ? "Senha incorreta. Depois de várias tentativas o sistema pode esperar alguns minutos." : "Senha incorreta")
            }
        }
        onError: err => { root.checking = false; root.pw = ""; root.error = "Não foi possível verificar a senha (" + PamError.toString(err) + ")" }
    }
    // destrava o chaveiro do GNOME com a mesma senha (pela entrada padrao: a senha nunca vai nos argumentos)
    Process {
        id: keyring
        property string secret: ""
        command: ["gnome-keyring-daemon", "--unlock"]
        stdinEnabled: true
        onStarted: { write(secret); secret = ""; stdinEnabled = false }
    }
    // solta a tela so depois do fade terminar (nesse ponto ela ja esta invisivel: sem piscar preto)
    Timer { id: unlockTimer; interval: root.leaveMs + 30; onTriggered: { Power.locked = false; root.preview = false } }

    // previa (sem bloquear de verdade): qs -c mine ipc call lockpreview toggle  (Esc fecha)
    property bool preview: false
    IpcHandler {
        target: "lockpreview"
        function toggle(): void { root.preview = !root.preview; root.pw = ""; root.error = ""; root.leaving = false }
        // so na previa: simula a senha certa (para ver a saida); nunca solta um bloqueio de verdade
        function leave(): void { if (root.preview && !Power.locked) { root.leaving = true; unlockTimer.restart() } }
        // so na previa: preenche n caracteres falsos (ver as bolinhas/formas sem digitar)
        function fill(n: int): void { if (root.preview && !Power.locked) root.pw = "x".repeat(Math.max(0, Math.min(30, n))) }
    }
    LazyLoader {
        active: root.preview && !Power.locked
        PanelWindow {
            anchors { left: true; right: true; top: true; bottom: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "mine-lock-preview"
            LockView { anchors.fill: parent; isPreview: true }
        }
    }
    function submit() {
        if (checking || leaving || pw === "") return
        error = ""
        checking = true
        pam.start()
    }

    // caps lock (le o LED do teclado enquanto bloqueado)
    Process {
        id: capsProc
        command: ["sh", "-c", "cat /sys/class/leds/*::capslock/brightness 2>/dev/null | sort -r | head -1"]
        stdout: StdioCollector { onStreamFinished: root.caps = text.trim() !== "" && text.trim() !== "0" }
    }
    Timer { interval: 500; repeat: true; running: Power.locked || root.preview; triggeredOnStart: true; onTriggered: capsProc.running = true }

    // ---------- o que aparece em cada tela ----------
    component LockView: Item {
        id: v
        property bool isPreview: false
        readonly property var anim: Settings.animOf("lock")

        // p: entrada (0 -> 1, curva escolhida em Animacoes); q: saida (0 -> 1 ao acertar a senha)
        property real p: 0
        Component.onCompleted: p = 1
        Behavior on p { MotionAnim { use: "lock" } }
        property real q: root.leaving ? 1 : 0
        Behavior on q { NumberAnimation { duration: root.leaveMs; easing.type: Easing.InOutCubic } }
        // entrada em etapas: fundo, depois o relogio, depois a foto e o campo
        readonly property real pBg: Math.max(0, Math.min(1, p * 1.6))
        readonly property real pClock: Math.max(0, Math.min(1.2, (p - 0.08) / 0.92))
        readonly property real pBox: Math.max(0, Math.min(1.2, (p - 0.18) / 0.82))

        opacity: 1 - q   // saida: tudo some junto, revelando a area de trabalho

        // fundo preto por baixo do wallpaper (cobre tudo mesmo se a imagem ainda nao carregou)
        Rectangle { anchors.fill: parent; color: "black"; opacity: Math.min(1, v.p * 3) }

        // wallpaper desfocado e escurecido
        Image {
            id: wp
            anchors.fill: parent
            source: Settings.lockWallpaper !== "" ? Wallpaper.stillUrl(Settings.lockWallpaper) : (Wallpaper.current !== "" ? Wallpaper.stillUrl(Wallpaper.current) : "")
            sourceSize: Qt.size(Math.round(width / 4), Math.round(height / 4))   // menor = desfoque mais forte e mais barato
            fillMode: Image.PreserveAspectCrop
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: wp
            autoPaddingEnabled: false
            blurEnabled: Settings.lockBlur > 0
            blurMax: 64
            // entra focando para desfocado; ao sair, volta a ficar nitido enquanto some
            blur: Settings.lockBlur / 100 * (0.25 + 0.75 * Math.min(1, v.pBg)) * (1 - 0.6 * v.q)
            scale: 1.06 - 0.06 * v.pBg + 0.04 * v.q
            opacity: v.pBg
        }
        Rectangle { anchors.fill: parent; color: "black"; opacity: Settings.lockDim / 100 * Math.min(1, v.pBg) }
        Rectangle {   // vinheta (o texto fica legivel em qualquer wallpaper)
            anchors.fill: parent
            opacity: Math.min(1, v.pBg)
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.22) }
                GradientStop { position: 0.35; color: "transparent" }
                GradientStop { position: 0.6; color: "transparent" }
                GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.5) }
            }
        }

        // ---- widgets marcados "mostrar tambem na tela de bloqueio" (mesma posicao da area de trabalho) ----
        DeskView {
            anchors.fill: parent
            area: Qt.rect(40, 40, width - 80, height - 80)
            lockMode: true
            darkBg: true
            opacity: Math.max(0, Math.min(1, v.pBox * 1.2))
        }

        // ---- relogio ----
        SystemClock { id: clk; precision: Settings.lockSeconds ? SystemClock.Seconds : SystemClock.Minutes }
        Item {
            id: clockBox
            readonly property bool centered: Settings.lockClockPos === "center"
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: (centered ? parent.height * 0.5 - height - 150 : parent.height * 0.12) - (1 - v.pClock) * 50 - v.q * 40 }
            width: Settings.lockClock === "big" ? clockCol.width : wclock.width
            height: Settings.lockClock === "big" ? clockCol.height : wclock.height
            opacity: Math.max(0, Math.min(1, v.pClock * 1.4))
            // outros estilos: o mesmo relogio dos widgets (flor, digital, diario, pixel), no tom claro sobre o fundo escuro
            DwClock {
                id: wclock
                visible: Settings.lockClock !== "big"
                width: Settings.lockClock === "analog" ? 360 : 640
                height: Settings.lockClock === "analog" ? 360 : 240
                cols: Settings.lockClock === "analog" ? 2 : 3; rows: Settings.lockClock === "analog" ? 2 : 1
                bare: true
                fg: "white"; dim: Qt.rgba(1, 1, 1, 0.75); ac: Qt.lighter(Theme.accent, 1.15)
                ac2: Theme.tertiary; cont: Theme.primaryContainer; contInk: Theme.primaryContainerInk
                opts: ({ style: Settings.lockClock, seconds: Settings.lockSeconds, dial: "dots", variant: "morning" })
            }
            Column {
                id: clockCol
                visible: Settings.lockClock === "big"
                spacing: 0
                UiText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: DateTime.time(clk.date, Settings.lockSeconds)
                    font.features: { "tnum": 1 }   // digitos de largura fixa: o relogio nao "pula" quando os numeros mudam
                    font.pixelSize: 140; font.weight: Font.DemiBold; font.letterSpacing: -3
                    color: "white"
                }
                UiText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: { const s = clk.date.toLocaleDateString(Qt.locale("pt_BR"), "dddd, d 'de' MMMM"); return s.charAt(0).toUpperCase() + s.slice(1) }
                    color: Qt.rgba(1, 1, 1, 0.88); font.pixelSize: 21; font.weight: Font.Medium; font.letterSpacing: 0.4
                }
            }
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 0.9; shadowOpacity: 0.35; shadowVerticalOffset: 3; shadowHorizontalOffset: 0 }
        }

        // ---- usuario + senha ----
        Column {
            id: box
            anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter; verticalCenterOffset: parent.height * 0.13 + (1 - v.pBox) * 60 + v.q * 30 }
            opacity: Math.max(0, Math.min(1, v.pBox * 1.4))
            spacing: 14

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: av.width; height: av.height
                // halo suave atras da foto (na cor de destaque; vermelho no erro)
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 26; height: width; radius: width / 2
                    color: root.error !== "" ? Theme.danger : Theme.accent
                    opacity: root.leaving ? 0.35 : 0.16
                    Behavior on opacity { NumberAnimation { duration: 250 } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                    layer.enabled: true
                    layer.effect: MultiEffect { blurEnabled: true; blur: 1; blurMax: 32 }
                }
                Avatar {
                    id: av
                    size: 108; ring: 3
                    ringColor: root.error !== "" ? Theme.danger : Theme.accent
                    Behavior on ringColor { ColorAnimation { duration: 200 } }
                    scale: (0.85 + 0.15 * Math.min(1, v.pBox)) * (root.leaving ? 1.06 : 1)
                    Behavior on scale { enabled: root.leaving; NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                }
            }
            UiText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Profile.name
                color: "white"; font.pixelSize: 22; font.weight: Font.Bold
                topPadding: 2
            }

            // campo de senha
            Item {
                id: fieldWrap
                anchors.horizontalCenter: parent.horizontalCenter
                width: 360; height: 54
                // tremida quando a senha esta errada
                property real shake: 0
                SequentialAnimation {
                    id: shakeAnim
                    NumberAnimation { target: fieldWrap; property: "shake"; to: -12; duration: 50 }
                    NumberAnimation { target: fieldWrap; property: "shake"; to: 10; duration: 70 }
                    NumberAnimation { target: fieldWrap; property: "shake"; to: -6; duration: 60 }
                    NumberAnimation { target: fieldWrap; property: "shake"; to: 3; duration: 50 }
                    NumberAnimation { target: fieldWrap; property: "shake"; to: 0; duration: 40 }
                }
                Connections { target: root; function onErrorChanged() { if (root.error !== "") shakeAnim.restart() } }

                Rectangle {
                    id: field
                    x: fieldWrap.shake
                    width: parent.width; height: parent.height; radius: height / 2
                    color: Qt.rgba(1, 1, 1, input.activeFocus ? 0.14 : 0.09)
                    border.width: 1.5
                    border.color: root.error !== "" ? Theme.danger : (root.leaving ? Theme.accent : (input.activeFocus ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.85) : Qt.rgba(1, 1, 1, 0.16)))
                    Behavior on border.color { ColorAnimation { duration: 180 } }
                    Behavior on color { ColorAnimation { duration: 180 } }
                    // brilho leve na borda de cima (vidro)
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1.5 }
                        height: parent.height / 2; radius: height
                        gradient: Gradient {
                            GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.07) }
                            GradientStop { position: 1; color: "transparent" }
                        }
                    }

                    UiIcon {
                        id: lockIco
                        anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
                        name: root.leaving ? "unlock" : "lock"; size: 19
                        color: root.leaving ? Theme.accent : Qt.rgba(1, 1, 1, 0.7)
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }

                    // a senha nunca aparece: so bolinhas
                    TextInput {
                        font.family: Theme.font
                        id: input
                        anchors { left: lockIco.right; leftMargin: 14; right: go.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        height: parent.height
                        opacity: 0          // invisivel: so captura o teclado
                        echoMode: TextInput.Password
                        text: root.pw
                        onTextEdited: { root.pw = text; if (root.error !== "") root.error = "" }
                        onAccepted: root.submit()
                        focus: true
                        enabled: !root.checking && !root.leaving
                        Component.onCompleted: forceActiveFocus()
                        Keys.onEscapePressed: { if (v.isPreview && root.pw === "") root.preview = false; root.pw = ""; text = "" }
                    }
                    Connections { target: root; function onPwChanged() { if (input.text !== root.pw) input.text = root.pw } }
                    UiText {
                        anchors { left: input.left; verticalCenter: parent.verticalCenter }
                        opacity: root.pw === "" ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                        text: root.leaving ? "Bem-vindo de volta" : "Digite sua senha"
                        color: Qt.rgba(1, 1, 1, 0.5); font.pixelSize: 15
                    }

                    // bolinhas fixas (nao recriadas a cada tecla): so a nova entra, so a ultima sai;
                    // verificando: uma onda passa por elas
                    property real wave: 0
                    NumberAnimation on wave { running: root.checking; from: 0; to: 1; duration: 900; loops: Animation.Infinite }
                    Row {
                        anchors { left: input.left; verticalCenter: parent.verticalCenter }
                        width: input.width
                        clip: true
                        spacing: 7
                        layoutDirection: root.pw.length * 17 > input.width ? Qt.RightToLeft : Qt.LeftToRight
                        Repeater {
                            model: 64
                            delegate: Item {
                                required property int index
                                readonly property bool on: index < root.pw.length
                                readonly property color color: root.leaving ? Theme.accent : "white"
                                visible: on || scale > 0.02
                                width: Settings.lockChars === "shapes" ? 15 : 10; height: width
                                // cada letra uma forma (flor, estrela, circulo, quadrado arredondado...), girada um pouco
                                Flower {
                                    anchors.fill: parent
                                    visible: Settings.lockChars === "shapes"
                                    readonly property var pick: [["flower", 6, 0.16], ["flower", 5, 0.5], ["circle", 0, 0], ["flower", 9, 0.12], ["rounded", 0, 0], ["flower", 4, 0.42], ["flower", 12, 0.1]][parent.index % 7]
                                    shape: pick[0]; sides: pick[1]; depth: pick[2]
                                    radius: width * 0.28
                                    color: parent.color
                                    rotation: (parent.index * 37) % 90
                                }
                                Rectangle { anchors.fill: parent; radius: width / 2; visible: Settings.lockChars !== "shapes"; color: parent.color
                                    Behavior on color { ColorAnimation { duration: 180 } } }
                                y: root.checking ? -4 * Math.max(0, Math.sin((field.wave * 1.6 - index / Math.max(1, root.pw.length)) * Math.PI * 2)) : 0
                                scale: on ? 1 : 0
                                Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutBack; easing.overshoot: 2.2 } }
                            }
                        }
                    }

                    // botao de enviar
                    Rectangle {
                        id: go
                        anchors { right: parent.right; rightMargin: 7; verticalCenter: parent.verticalCenter }
                        width: 40; height: 40; radius: 20
                        readonly property bool hot: root.pw !== "" || root.checking || root.leaving
                        color: hot ? Theme.accent : Qt.rgba(1, 1, 1, gm.containsMouse ? 0.14 : 0.08)
                        scale: gm.pressed ? 0.92 : 1
                        Behavior on color { ColorAnimation { duration: 160 } }
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        UiIcon {
                            anchors.centerIn: parent
                            name: root.leaving ? "check" : "arrowRight"; size: 20
                            color: go.hot ? Theme.accentText : Qt.rgba(1, 1, 1, 0.55)
                        }
                        MouseArea { id: gm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.submit() }
                    }
                }
            }

            // mensagens: erro ou caps lock
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 440; height: 22
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    opacity: msg.text !== "" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    UiIcon { visible: root.error === "" && root.caps; name: "caps"; size: 15; color: Qt.rgba(1, 1, 1, 0.8); anchors.verticalCenter: parent.verticalCenter }
                    UiText {
                        id: msg
                        width: Math.min(implicitWidth, 420)
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        text: root.error !== "" ? root.error : (root.caps ? "Caps Lock está ativado" : "")
                        color: root.error !== "" ? Qt.lighter(Theme.danger, 1.2) : Qt.rgba(1, 1, 1, 0.8)
                        font.pixelSize: 13; font.weight: Font.Medium
                    }
                }
            }
        }

        // ---- midia tocando (se houver) ----
        readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? null
        Rectangle {
            visible: !!v.player && Settings.lockMedia
            anchors { left: parent.left; bottom: parent.bottom; margins: 28 }
            anchors.bottomMargin: 28 - (1 - Math.min(1, v.pBox)) * 30
            width: 320; height: 76; radius: 22
            color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.12)
            opacity: Math.max(0, Math.min(1, v.pBox * 1.4))
            RoundImage {
                id: art
                x: 12; anchors.verticalCenter: parent.verticalCenter
                width: 52; height: 52; radius: 14
                source: v.player ? (v.player.trackArtUrl ?? "") : ""
                sourceSize: Qt.size(104, 104)
            }
            Column {
                anchors { left: art.right; leftMargin: 12; right: ctl.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                spacing: 2
                UiText { width: parent.width; elide: Text.ElideRight; text: v.player ? (v.player.trackTitle || "Tocando") : ""; color: "white"; font.pixelSize: 14; font.weight: Font.DemiBold }
                UiText { width: parent.width; elide: Text.ElideRight; text: v.player ? (v.player.trackArtist || v.player.identity) : ""; color: Qt.rgba(1, 1, 1, 0.65); font.pixelSize: 12 }
            }
            Row {
                id: ctl
                anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                spacing: 2
                Repeater {
                    model: [["prev", () => v.player.previous()], ["pause", () => v.player.togglePlaying()], ["next", () => v.player.next()]]
                    delegate: Rectangle {
                        required property var modelData
                        width: 32; height: 32; radius: 16
                        color: bm.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
                        UiIcon { anchors.centerIn: parent; name: modelData[0]; size: 18; color: "white" }
                        MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (v.player) modelData[1]() }
                    }
                }
            }
        }

        // ---- energia (canto) ----
        Row {
            visible: Settings.lockPower
            anchors { right: parent.right; bottom: parent.bottom; margins: 28 }
            anchors.bottomMargin: 28 - (1 - Math.min(1, v.pBox)) * 30
            spacing: 10
            opacity: Math.max(0, Math.min(1, v.pBox * 1.4))
            Repeater {
                model: [["sleep", "suspend", "Suspender"], ["restart", "reboot", "Reiniciar"], ["power", "poweroff", "Desligar"]]
                delegate: Rectangle {
                    id: pb
                    required property var modelData
                    property bool armed: false   // reiniciar/desligar: segundo clique confirma
                    width: armed ? 136 : 48; height: 48; radius: 24
                    clip: true
                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    color: armed ? Theme.danger : (pm.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.08))
                    border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.12)
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        UiIcon { name: pb.modelData[0]; size: 20; color: "white"; anchors.verticalCenter: parent.verticalCenter }
                        UiText { visible: pb.armed; text: pb.modelData[2] + "?"; color: "white"; font.pixelSize: 13; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                    }
                    Timer { id: disarm; interval: 3500; onTriggered: pb.armed = false }
                    MouseArea {
                        id: pm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const id = pb.modelData[1]
                            if (id === "suspend") { Quickshell.execDetached(["systemctl", "suspend"]); return }
                            if (!pb.armed) { pb.armed = true; disarm.restart(); return }
                            Quickshell.execDetached(["systemctl", id])
                        }
                    }
                }
            }
        }
    }
}
