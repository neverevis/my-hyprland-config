// Busca de wallpapers no Wallhaven (wallhaven.cc, API publica; a logica fica em Wallhaven.qml, a mesma do seletor):
// digitar e Enter busca; clique numa miniatura baixa a imagem para a pasta de wallpapers e aplica, clique direito so baixa.
// Filtros (ordem, periodo, proporcao, categorias, pureza, cor) ficam salvos. Sketchy / nsfw pedem a chave da API.
import Quickshell
import QtQuick

Card {
    id: wc
    icon: "web"
    title: "Wallhaven"
    subtitle: "Busque wallpapers online. Clique numa imagem para baixar e aplicar; clique direito só baixa. O seletor (Super + W) também busca aqui."

    Row {
        width: parent.width
        spacing: 8
        UiField { id: q; width: parent.width - 110; text: Wallhaven.query; placeholderText: "O que procurar (ex.: montanhas, cyberpunk, sakura)…"; onTextEdited: Wallhaven.query = text; onAccepted: Wallhaven.newSearch() }
        UiButton { icon: "search"; text: "Buscar"; kind: "accent"; onClicked: Wallhaven.newSearch() }
    }
    UiLabel { text: "Ordenar por" }
    Flow {
        width: parent.width
        spacing: 6
        Repeater {
            model: Wallhaven.sortings
            delegate: UiButton { required property var modelData; text: modelData[1]; kind: Wallhaven.pref("sorting") === modelData[0] ? "accent" : "ghost"; onClicked: { Wallhaven.setPref("sorting", modelData[0]); Wallhaven.newSearch() } }
        }
    }
    UiLabel { visible: Wallhaven.pref("sorting") === "toplist"; text: "Período do Top" }
    Flow {
        visible: Wallhaven.pref("sorting") === "toplist"
        width: parent.width
        spacing: 6
        Repeater {
            model: Wallhaven.ranges
            delegate: UiButton { required property var modelData; text: modelData[1]; kind: Wallhaven.pref("topRange") === modelData[0] ? "accent" : "ghost"; onClicked: { Wallhaven.setPref("topRange", modelData[0]); Wallhaven.newSearch() } }
        }
    }
    UiSeg { options: [["desc", "Maior primeiro", "arrowDown"], ["asc", "Menor primeiro", "arrowUp"]]; value: Wallhaven.pref("order"); onPicked: v => { Wallhaven.setPref("order", v); Wallhaven.newSearch() } }
    UiLabel { text: "Proporção" }
    Flow {
        width: parent.width
        spacing: 6
        Repeater {
            model: Wallhaven.ratioList
            delegate: UiButton { required property var modelData; text: modelData[1]; kind: Wallhaven.pref("ratios") === modelData[0] ? "accent" : "ghost"; onClicked: { Wallhaven.setPref("ratios", modelData[0]); Wallhaven.newSearch() } }
        }
    }
    UiLabel { text: "Categorias e pureza" }
    Flow {
        width: parent.width
        spacing: 6
        Repeater {
            model: [["cats", 0, "Geral"], ["cats", 1, "Anime"], ["cats", 2, "Pessoas"]]
            delegate: UiButton { required property var modelData; icon: Wallhaven.flag(modelData[0], modelData[1]) ? "check" : ""; text: modelData[2]; kind: "ghost"; onClicked: Wallhaven.toggleFlag(modelData[0], modelData[1]) }
        }
        Item { width: 12; height: 1 }
        Repeater {
            model: [["purity", 0, "Seguro"], ["purity", 1, "Sugestivo"], ["purity", 2, "Adulto"]]
            delegate: UiButton { required property var modelData; icon: Wallhaven.flag(modelData[0], modelData[1]) ? "check" : ""; text: modelData[2]; kind: "ghost"; onClicked: Wallhaven.toggleFlag(modelData[0], modelData[1]) }
        }
    }
    Row {
        visible: Wallhaven.pref("purity") !== "100"
        width: parent.width
        spacing: 8
        UiText { anchors.verticalCenter: parent.verticalCenter; text: "Chave da API"; color: Theme.text; font.pixelSize: 13 }
        UiField { width: parent.width - 120; text: Settings.whApiKey; placeholderText: "wallhaven.cc > Conta > API (necessária para sugestivo e adulto)"; onEditingFinished: Settings.whApiKey = text.trim() }
    }
    UiLabel { text: "Cor" }
    Flow {
        width: parent.width
        spacing: 6
        Rectangle {
            width: 26; height: 26; radius: 13; color: "transparent"; border.width: 1; border.color: Theme.border
            UiIcon { anchors.centerIn: parent; name: "close"; size: 14; color: Theme.muted }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Wallhaven.setPref("colors", ""); Wallhaven.newSearch() } }
        }
        Repeater {
            model: Wallhaven.palette
            delegate: Rectangle {
                required property string modelData
                width: 26; height: 26; radius: 13; color: "#" + modelData
                border.width: Wallhaven.pref("colors") === modelData ? 3 : 1; border.color: Wallhaven.pref("colors") === modelData ? Theme.accent : Theme.border
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Wallhaven.setPref("colors", modelData); Wallhaven.newSearch() } }
            }
        }
    }
    UiText { visible: Wallhaven.status !== ""; text: Wallhaven.status; color: Theme.muted; font.pixelSize: 12 }
    Flow {
        width: parent.width
        spacing: 8
        Repeater {
            model: Wallhaven.results
            delegate: Rectangle {
                required property var modelData
                width: (parent.width - 3 * 8) / 4; height: width * 0.62; radius: 10; color: Theme.track; clip: true
                border.width: tm.containsMouse ? 2 : 1; border.color: tm.containsMouse ? Theme.accent : Theme.border
                Image { anchors.fill: parent; anchors.margins: 1; source: modelData.thumb; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize: Qt.size(320, 200) }
                Rectangle {
                    anchors { left: parent.left; bottom: parent.bottom; margins: 6 }
                    width: rl.implicitWidth + 10; height: 18; radius: 9; color: Qt.rgba(0, 0, 0, 0.6)
                    UiText { id: rl; anchors.centerIn: parent; text: Wallhaven.downloading === modelData.id ? "Baixando…" : modelData.res; color: "white"; font.pixelSize: 9; font.weight: Font.DemiBold }
                }
                MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => Wallhaven.take(parent.modelData, mouse.button === Qt.LeftButton) }
            }
        }
    }
    Row {
        visible: Wallhaven.results.length > 0
        spacing: 8
        UiButton { icon: "arrowLeft"; kind: "ghost"; enabled: Wallhaven.page > 1; onClicked: Wallhaven.go(-1) }
        UiText { anchors.verticalCenter: parent.verticalCenter; text: "Página " + Wallhaven.page + " / " + Wallhaven.lastPage; color: Theme.muted; font.pixelSize: 12 }
        UiButton { icon: "arrowRight"; kind: "ghost"; enabled: Wallhaven.page < Wallhaven.lastPage; onClicked: Wallhaven.go(1) }
    }
}
