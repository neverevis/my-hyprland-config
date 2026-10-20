// Wallhaven (wallhaven.cc, API publica): busca com filtros (ordem, periodo, proporcao, categorias, pureza, cor), paginas e download.
// Usado pelo cartao nas configuracoes (WallhavenCard) e pelo seletor de wallpaper (fonte "Wallhaven").
// Os filtros ficam salvos em Settings.whPrefs; sketchy / nsfw pedem a chave da API (Settings.whApiKey).
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property string query: ""
    property var results: []
    property string status: ""
    property int page: 1
    property int lastPage: 1
    property bool loading: false
    property string downloading: ""
    property string seed: ""
    // ipc: qs -c mine ipc call wallhaven search <texto>  |  status
    IpcHandler {
        target: "wallhaven"
        function search(q: string): void { root.query = q; root.newSearch() }
        function status(): string { return root.status + " | " + root.results.length + " resultados | pag " + root.page + "/" + root.lastPage }
    }

    readonly property var defaults: ({ sorting: "relevance", topRange: "1y", order: "desc", ratios: "", cats: "110", purity: "100", colors: "" })
    function pref(k) { const p = Settings.whPrefs ?? {}; return p[k] !== undefined ? p[k] : defaults[k] }
    function setPref(k, v) { const p = Object.assign({}, Settings.whPrefs ?? {}); p[k] = v; Settings.whPrefs = p }
    function flag(k, i) { return String(pref(k)).charAt(i) === "1" }
    function toggleFlag(k, i) {
        const s = String(pref(k)).split(""); s[i] = s[i] === "1" ? "0" : "1"
        if (s.indexOf("1") < 0) s[i] = "1"   // ao menos uma
        setPref(k, s.join(""))
    }
    readonly property var sortings: [["relevance", "Relevância"], ["date_added", "Recentes"], ["views", "Mais vistos"], ["favorites", "Favoritos"], ["toplist", "Top"], ["hot", "Em alta"], ["random", "Aleatório"]]
    readonly property var ranges: [["1d", "1 dia"], ["3d", "3 dias"], ["1w", "1 semana"], ["1M", "1 mês"], ["3M", "3 meses"], ["6M", "6 meses"], ["1y", "1 ano"]]
    readonly property var ratioList: [["", "Qualquer"], ["16x9", "16:9"], ["16x10", "16:10"], ["21x9", "21:9"], ["9x16", "9:16"], ["1x1", "1:1"]]
    readonly property var palette: ["cc0000", "ff6600", "ffcc33", "77cc33", "336600", "66cccc", "0066cc", "663399", "ea4c88", "663300", "999999", "ffffff", "000000"]
    function nextSort() {
        const i = sortings.findIndex(s => s[0] === pref("sorting"))
        setPref("sorting", sortings[(i + 1) % sortings.length][0])
    }

    // monta o endereco da busca (separado para poder conferir sem rede)
    function buildUrl(pg) {
        const scr = Quickshell.screens[0]
        const s = pref("sorting")
        let u = "https://wallhaven.cc/api/v1/search?q=" + encodeURIComponent(query.trim()) + "&categories=" + pref("cats") + "&purity=" + pref("purity")
            + "&sorting=" + s + "&order=" + pref("order") + "&atleast=" + (scr ? scr.width + "x" + scr.height : "1920x1080") + "&page=" + pg
        if (s === "toplist") u += "&topRange=" + pref("topRange")
        if (pref("ratios") !== "") u += "&ratios=" + pref("ratios")
        if (pref("colors") !== "") u += "&colors=" + pref("colors")
        if (s === "random" && seed !== "") u += "&seed=" + seed
        return u
    }
    function search(pg) {
        if (loading) return
        const n = Math.max(1, pg ?? 1)
        loading = true
        status = "Buscando no Wallhaven…"
        const x = new XMLHttpRequest()
        x.onreadystatechange = () => {
            if (x.readyState !== XMLHttpRequest.DONE) return
            root.loading = false
            if (x.status === 429) { root.status = "Muitas buscas seguidas: espere um pouco"; return }
            if (x.status === 401) { root.status = "Chave da API inválida (necessária para sketchy / nsfw)"; return }
            if (x.status !== 200) { root.status = "Não consegui buscar (" + x.status + ")"; return }
            try {
                const j = JSON.parse(x.responseText)
                const d = j.data || []
                root.results = d.map(w => ({ id: w.id, url: w.path, thumb: w.thumbs.small, res: w.resolution, size: w.file_size }))
                root.page = (j.meta && j.meta.current_page) || n
                root.lastPage = (j.meta && j.meta.last_page) || 1
                if (j.meta && j.meta.seed) root.seed = j.meta.seed
                root.status = root.results.length ? "" : "Nada encontrado"
            } catch (e) { root.status = "Resposta inválida" }
        }
        x.open("GET", buildUrl(n))
        if (Settings.whApiKey !== "") x.setRequestHeader("X-API-Key", Settings.whApiKey)
        x.send()
    }
    function newSearch() { seed = ""; search(1) }
    function go(d) { const n = page + d; if (n >= 1 && n <= lastPage) search(n) }

    property bool applyAfter: true
    function take(w, apply) {
        if (downloading) return
        downloading = w.id
        applyAfter = apply
        const ext = w.url.split(".").pop()
        const dest = Wallpaper.dir + "/wallhaven-" + w.id + "." + ext
        dl.dest = dest
        dl.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && { [ -s "$2" ] || curl -fsSL --max-time 60 -o "$2" "$1"; }', "sh", w.url, dest]
        dl.running = true
    }
    Process {
        id: dl
        property string dest: ""
        onExited: code => {
            root.downloading = ""
            const nm = dest.split("/").pop()
            if (code === 0) {
                if (root.applyAfter) Wallpaper.set(dest)
                root.status = (root.applyAfter ? "Aplicado: " : "Baixado: ") + nm
                Quickshell.execDetached(["notify-send", "-a", "Shell", "Wallhaven", (root.applyAfter ? "Wallpaper aplicado: " : "Download concluído: ") + nm])
            } else {
                root.status = "Falhou ao baixar"
                Quickshell.execDetached(["notify-send", "-a", "Shell", "Wallhaven", "Falhou ao baixar " + nm])
            }
        }
    }
}
