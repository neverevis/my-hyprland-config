// Pagina "Wallpaper": pasta, estilo (normal, centralizado numa forma, mosaico), efeitos (desfoque, escurecer,
// paralaxe por workspace), videos, wallpaper da tela de bloqueio, transicao, troca automatica, seletor e Wallhaven.
import Quickshell
import QtQuick

Column {
    spacing: 14

    Card {
        icon: "wallpaper"
        title: "Wallpaper atual"
        subtitle: Wallpaper.files.length + " imagens em " + Wallpaper.dir
        Rectangle {
            width: parent.width; height: Math.min(200, width * 9 / 16)
            radius: 12; color: Theme.track; clip: true
            border.width: 1; border.color: Theme.border
            Image {
                anchors.fill: parent; anchors.margins: 1
                source: Wallpaper.current !== "" ? Wallpaper.stillUrl(Wallpaper.current) : ""
                sourceSize: Qt.size(720, 400)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }
        Flow {
            width: parent.width
            spacing: 6
            UiButton { icon: "images"; text: "Abrir seletor"; kind: "accent"; onClicked: Settings.wpPickerOpen = true }
            UiButton { icon: "prev"; text: "Anterior"; onClicked: Wallpaper.step(-1) }
            UiButton { icon: "next"; text: "Próximo"; onClicked: Wallpaper.step(1) }
            UiButton { icon: "dice"; text: "Aleatório"; onClicked: Wallpaper.random() }
        }
        UiLabel { text: "Pasta" }
        UiField {
            width: parent.width
            text: Settings.wpDir
            placeholderText: "~/Imagens/Wallpapers"
            onEditingFinished: Settings.wpDir = text
        }
    }

    Card {
        icon: "transition"
        title: "Transição"
        subtitle: "A animação ao trocar de wallpaper. Dissolver, Pixelar, Ondas, Persianas e Redemoinho são shaders (a borda acesa usa a cor de destaque)."
        Flow {
            width: parent.width
            spacing: 6
            Repeater {
                model: [["fade", "Fade"], ["slide", "Deslizar"], ["wipe", "Cortina"], ["circle", "Círculo"], ["zoom", "Zoom"],
                        ["dissolve", "Dissolver"], ["pixelate", "Pixelar"], ["ripple", "Ondas"], ["blinds", "Persianas"], ["swirl", "Redemoinho"],
                        ["random", "Aleatória"], ["none", "Nenhuma"]]
                delegate: UiButton {
                    required property var modelData
                    text: modelData[1]
                    checked: Settings.wpTransition === modelData[0]
                    onClicked: Settings.wpTransition = modelData[0]
                }
            }
        }
        Column {
            visible: Settings.wpTransition === "wipe" || Settings.wpTransition === "random"
            width: parent.width
            spacing: 10
            UiLabel { text: "Direção da cortina" }
            UiSeg {
                options: [[0, "", "arrow_right"], [45, "", "arrow_bottom_right"], [90, "", "arrowDown"], [135, "", "arrow_bottom_left"], [180, "", "arrow_left"], [225, "", "arrow_top_left"], [270, "", "arrowUp"], [315, "", "arrow_top_right"]]
                value: Settings.wpWipeAngle
                onPicked: v => Settings.wpWipeAngle = v
            }
            UiSlider { label: "Ângulo exato"; from: 0; to: 359; value: Settings.wpWipeAngle; suffix: "°"; onMoved: v => Settings.wpWipeAngle = Math.round(v) }
        }
        UiSlider { label: "Movimento dos wallpapers (cortina: posição, círculo: escala)"; from: 0; to: 50; value: Settings.wpParallax; suffix: " %"; onMoved: v => Settings.wpParallax = Math.round(v) }
        UiLabel { text: "Animação" }
        AnimPicker { target: "wallpaper" }
    }

    Card {
        icon: "image"
        title: "Estilo"
        subtitle: "Normal: a imagem cobre a tela. Centralizado: a imagem numa forma no meio, sobre uma cor do tema. Mosaico: várias imagens lado a lado."
        UiSeg { options: [["fill", "Normal", "fullscreen"], ["centered", "Centralizado", "flower"], ["collage", "Mosaico", "view_grid"]]; value: Settings.wpMode; onPicked: v => Settings.wpMode = v }
        RoleRow { visible: Settings.wpMode !== "fill"; label: "Cor do fundo"; value: Settings.wpBgRole; roles: ["primaryContainer", "secondaryContainer", "tertiaryContainer", "primary", "secondary", "tertiary", "surfaceHigh", "surfaceLow", "bg"]; onPicked: v => Settings.wpBgRole = v }
        Column {
            visible: Settings.wpMode === "centered"
            width: parent.width; spacing: 12
            UiLabel { text: "Forma" }
            ShapePicker { width: parent.width; value: Settings.wpCenterShape; sides: Settings.wpCenterSides; onPicked: v => Settings.wpCenterShape = v }
            UiSlider { visible: Settings.wpCenterShape === "flower"; label: "Pétalas"; from: 4; to: 20; value: Settings.wpCenterSides; onMoved: v => Settings.wpCenterSides = Math.round(v) }
            UiSlider { label: "Tamanho"; from: 20; to: 95; value: Settings.wpCenterSize; suffix: " %"; onMoved: v => Settings.wpCenterSize = Math.round(v) }
            UiSwitch { label: "Girar devagar"; checked: Settings.wpCenterSpin; onToggled: on => Settings.wpCenterSpin = on }
        }
        Column {
            visible: Settings.wpMode === "collage"
            width: parent.width; spacing: 12
            UiLabel { text: "Arranjo" }
            UiSeg { options: [["2v", "Lado a lado"], ["2h", "Em cima e embaixo"], ["3", "Três"], ["1+2", "Um grande + dois"], ["2x2", "Quatro"]]; value: Settings.wpCollageLayout; onPicked: v => Settings.wpCollageLayout = v }
            UiSlider { label: "Espaço entre as imagens"; from: 0; to: 80; value: Settings.wpCollageGap; suffix: " px"; onMoved: v => Settings.wpCollageGap = Math.round(v) }
            UiSlider { label: "Margem da tela"; from: 0; to: 200; value: Settings.wpCollageMargin; suffix: " px"; onMoved: v => Settings.wpCollageMargin = Math.round(v) }
            UiSlider { label: "Arredondamento"; from: 0; to: 60; value: Settings.wpCollageRadius; suffix: " px"; onMoved: v => Settings.wpCollageRadius = Math.round(v) }
            UiText { width: parent.width; wrapMode: Text.WordWrap; color: Theme.muted; font.pixelSize: 12; text: "A primeira é o wallpaper atual. As outras: as escolhidas abaixo, ou as próximas da pasta." }
            Flow {
                width: parent.width; spacing: 8
                Repeater {
                    model: 3
                    delegate: Rectangle {
                        required property int index
                        readonly property string pic: (Settings.list(Settings.wpCollage))[index] ?? ""
                        width: 120; height: 72; radius: 10; color: Theme.track; clip: true; border.width: 1; border.color: Theme.border
                        Image { anchors.fill: parent; anchors.margins: 1; visible: parent.pic !== ""; source: parent.pic ? Wallpaper.stillUrl(parent.pic) : ""; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(240, 144); asynchronous: true }
                        UiIcon { visible: parent.pic === ""; anchors.centerIn: parent; name: "plus"; size: 18; color: Theme.muted }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: m => {
                                const i = parent.index
                                const put = p => { const l = (Settings.list(Settings.wpCollage)).slice(); while (l.length <= i) l.push(""); l[i] = p; Settings.wpCollage = l }
                                if (m.button === Qt.RightButton) put(""); else Pick.image("Imagem do mosaico", put)
                            } }
                    }
                }
            }
        }
    }

    Card {
        icon: "blur"
        title: "Efeitos"
        subtitle: "Desfocar e escurecer ajudam a ler as janelas transparentes. \"Com janelas\" só aplica quando o workspace tem alguma."
        UiSlider { label: "Desfoque"; from: 0; to: 100; value: Settings.wpBlur; suffix: " %"; onMoved: v => Settings.wpBlur = Math.round(v) }
        UiSeg { visible: Settings.wpBlur > 0; options: [["windows", "Com janelas"], ["always", "Sempre"], ["never", "Nunca"]]; value: Settings.wpBlurWhen; onPicked: v => Settings.wpBlurWhen = v }
        UiSlider { label: "Escurecer"; from: 0; to: 80; value: Settings.wpDim; suffix: " %"; onMoved: v => Settings.wpDim = Math.round(v) }
        UiSeg { visible: Settings.wpDim > 0; options: [["windows", "Com janelas"], ["always", "Sempre"], ["never", "Nunca"]]; value: Settings.wpDimWhen; onPicked: v => Settings.wpDimWhen = v }
        UiSlider { label: "Paralaxe ao trocar de workspace (0 = desligada)"; from: 0; to: 20; value: Settings.wpWsParallax; suffix: " %"; onMoved: v => Settings.wpWsParallax = Math.round(v) }
        UiSwitch { visible: Settings.wpWsParallax > 0; label: "Deslizar na vertical"; checked: Settings.wpWsVertical; onToggled: on => Settings.wpWsVertical = on }
        UiLabel { text: "Vídeos" }
        UiSwitch { label: "Vídeos da pasta entram na lista"; description: "MP4, WebM, MKV e MOV: rodam em loop, sem som. A paleta de cores sai do primeiro quadro."; checked: Settings.wpVideos; onToggled: on => Settings.wpVideos = on }
        UiSwitch { label: "Pausar o vídeo com janela em tela cheia"; checked: Settings.wpVideoPause; onToggled: on => Settings.wpVideoPause = on }
    }

    Card {
        icon: "lock"
        title: "Tela de bloqueio"
        subtitle: Settings.lockWallpaper ? "Wallpaper próprio: " + Settings.lockWallpaper.split("/").pop() : "Usa o mesmo wallpaper da área de trabalho."
        Row {
            spacing: 8
            UiButton { icon: "folderOpen"; text: "Escolher imagem…"; onClicked: Pick.image("Wallpaper da tela de bloqueio", p => Settings.lockWallpaper = p) }
            UiButton { visible: Settings.lockWallpaper !== ""; icon: "restore"; text: "Usar o da área de trabalho"; kind: "ghost"; onClicked: Settings.lockWallpaper = "" }
            UiButton { icon: "eye"; text: "Ver"; kind: "ghost"; onClicked: Quickshell.execDetached(["qs", "-c", "mine", "ipc", "call", "lockpreview", "toggle"]) }
        }
    }

    Card {
        icon: "timer"
        title: "Troca automática"
        UiSlider { label: "Trocar a cada (0 = desligado)"; from: 0; to: 120; value: Settings.wpInterval; suffix: " min"; onMoved: v => Settings.wpInterval = v }
        UiSwitch { label: "Ordem aleatória"; checked: Settings.wpShuffle; onToggled: on => Settings.wpShuffle = on }
    }

    Card {
        icon: "carousel"
        title: "Seletor"
        subtitle: "Como o carrossel de wallpapers aparece."
        UiSwitch { label: "Acoplado à moldura"; description: "Sai da borda da tela como uma barra. Desligado, flutua perto da borda."; checked: Settings.wpPickerDocked; onToggled: on => Settings.wpPickerDocked = on }
        SidePick { value: Settings.wpPickerSide; onPicked: v => Settings.wpPickerSide = v }
        UiSlider { label: "Deslocamento"; from: -1000; to: 1000; value: Settings.wpPickerOffset; suffix: " px"; onMoved: v => Settings.wpPickerOffset = v }
        UiSlider { visible: !Settings.wpPickerDocked; label: "Distância da borda"; from: 0; to: 80; value: Settings.wpPickerGap; suffix: " px"; onMoved: v => Settings.wpPickerGap = v }
        UiSwitch { label: "Fechar ao escolher"; description: "Enter ou clique aplica o wallpaper e fecha o seletor."; checked: Settings.wpCloseAfter; onToggled: on => Settings.wpCloseAfter = on }
        UiSwitch { label: "Usar o navegador de arquivos"; description: "Em vez do carrossel, o atalho do seletor abre o navegador de imagens do shell."; checked: Settings.wpSystemDialog; onToggled: on => Settings.wpSystemDialog = on }
        UiLabel { text: "Ordem das imagens" }
        UiSeg { options: [["name", "Nome", "sortName"], ["time", "Data", "sortTime"], ["size", "Tamanho", "disk"]]; value: Settings.wpSort; onPicked: v => Settings.wpSort = v }
        UiSwitch { label: "Ordem invertida"; checked: Settings.wpSortRev; onToggled: on => Settings.wpSortRev = on }
        UiLabel { text: "Wallpapers visíveis" }
        UiSeg {
            options: [[1, "1"], [3, "3"], [5, "5"]]
            value: Settings.wpPickerCount
            onPicked: v => Settings.wpPickerCount = v
        }
        UiSlider { label: "Arredondamento do painel"; from: 0; to: 40; value: Settings.wpPickerRadius; suffix: " px"; onMoved: v => Settings.wpPickerRadius = v }
        UiSlider { visible: Settings.wpPickerDocked; label: "Curva ao encontrar a moldura"; from: 0; to: 40; value: Settings.wpPickerFillet; suffix: " px"; onMoved: v => Settings.wpPickerFillet = v }
        UiSlider { label: "Arredondamento das miniaturas"; from: 0; to: 40; value: Settings.wpCardRadius; suffix: " px"; onMoved: v => Settings.wpCardRadius = v }
        UiLabel { text: "Animação" }
        AnimPicker { target: "picker" }
    }

    WallhavenCard { width: parent.width }
}
