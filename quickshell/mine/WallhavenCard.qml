// Busca de wallpapers no Wallhaven (wallhaven.cc, API publica, so conteudo seguro): digitar e Enter busca; clique
// numa miniatura baixa a imagem para a sua pasta de wallpapers e aplica. Ordenar por relevancia, mais vistos, recentes
// ou aleatorio; categorias geral / anime / pessoas; resolucao minima da sua tela.
import Quickshell
import Quickshell.Io
import QtQuick

Card {
    id: wc
    icon: "web"
    title: "Wallhaven"
    subtitle: "Busque wallpapers online (só conteúdo seguro). Clique numa imagem para baixar para a sua pasta e aplicar."
    property var results: []
    property string status: ""
    property int page: 1
    property string sorting: "relevance"
    property var cats: ({ general: true, anime: true, people: false })
    property string downloading: ""

    function search(more) {
        page = more ? page + 1 : 1
        status = "Buscando…"
        const c = (cats.general ? "1" : "0") + (cats.anime ? "1" : "0") + (cats.people ? "1" : "0")
        const scr = Quickshell.screens[0]
        const url = "https://wallhaven.cc/api/v1/search?q=" + encodeURIComponent(q.text.trim()) + "&categories=" + c + "&purity=100&sorting=" + sorting
            + "&order=desc&atleast=" + (scr ? scr.width + "x" + scr.height : "1920x1080") + "&page=" + page + (sorting === "toplist" ? "&topRange=1M" : "")
        const x = new XMLHttpRequest()
        x.onreadystatechange = () => {
            if (x.readyState !== XMLHttpRequest.DONE) return
            if (x.status !== 200) { status = "Não consegui buscar (" + x.status + ")"; return }
            try {
                const d = JSON.parse(x.responseText).data || []
                results = (more ? results : []).concat(d.map(w => ({ id: w.id, url: w.path, thumb: w.thumbs.small, res: w.resolution, size: w.file_size })))
                status = results.length ? "" : "Nada encontrado"
            } catch (e) { status = "Resposta inválida" }
        }
        x.open("GET", url)
        x.send()
    }
    function take(w) {
        if (downloading) return
        downloading = w.id
        const ext = w.url.split(".").pop()
        const dest = Wallpaper.dir + "/wallhaven-" + w.id + "." + ext
        dl.dest = dest
        dl.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && [ -s "$2" ] || curl -fsSL --max-time 60 -o "$2" "$1"', "sh", w.url, dest]
        dl.running = true
    }
    Process {
        id: dl
        property string dest: ""
        onExited: code => {
            wc.downloading = ""
            if (code === 0) { Wallpaper.set(dest); wc.status = "Aplicado: " + dest.split("/").pop() }
            else wc.status = "Falhou ao baixar"
        }
    }

    Row {
        width: parent.width
        spacing: 8
        UiField { id: q; width: parent.width - 110; placeholderText: "O que procurar (ex.: montanhas, cyberpunk, sakura)…"; onAccepted: wc.search(false) }
        UiButton { icon: "search"; text: "Buscar"; kind: "accent"; onClicked: wc.search(false) }
    }
    Flow {
        width: parent.width
        spacing: 6
        Repeater {
            model: [["relevance", "Relevância"], ["toplist", "Mais vistos do mês"], ["date_added", "Recentes"], ["random", "Aleatório"]]
            delegate: UiButton { required property var modelData; text: modelData[1]; kind: wc.sorting === modelData[0] ? "accent" : "ghost"; onClicked: { wc.sorting = modelData[0]; wc.search(false) } }
        }
        Item { width: 12; height: 1 }
        Repeater {
            model: [["general", "Geral"], ["anime", "Anime"], ["people", "Pessoas"]]
            delegate: UiButton {
                required property var modelData
                icon: wc.cats[modelData[0]] ? "check" : ""
                text: modelData[1]; kind: "ghost"
                onClicked: { const c = Object.assign({}, wc.cats); c[modelData[0]] = !c[modelData[0]]; wc.cats = c }
            }
        }
    }
    UiText { visible: wc.status !== ""; text: wc.status; color: Theme.muted; font.pixelSize: 12 }
    Flow {
        width: parent.width
        spacing: 8
        Repeater {
            model: wc.results
            delegate: Rectangle {
                required property var modelData
                width: (parent.width - 3 * 8) / 4; height: width * 0.62; radius: 10; color: Theme.track; clip: true
                border.width: tm.containsMouse ? 2 : 1; border.color: tm.containsMouse ? Theme.accent : Theme.border
                Image { anchors.fill: parent; anchors.margins: 1; source: modelData.thumb; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize: Qt.size(320, 200) }
                Rectangle {
                    anchors { left: parent.left; bottom: parent.bottom; margins: 6 }
                    width: rl.implicitWidth + 10; height: 18; radius: 9; color: Qt.rgba(0, 0, 0, 0.6)
                    UiText { id: rl; anchors.centerIn: parent; text: wc.downloading === modelData.id ? "Baixando…" : modelData.res; color: "white"; font.pixelSize: 9; font.weight: Font.DemiBold }
                }
                MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: wc.take(parent.modelData) }
            }
        }
    }
    UiButton { visible: wc.results.length > 0; icon: "plus"; text: "Mais"; kind: "ghost"; onClicked: wc.search(true) }
}
