// Chat com IA da barra lateral esquerda. Backends: Ollama local (sem chave), OpenAI e compativeis, Gemini.
// Transporte: curl -sN lendo a configuracao pela entrada padrao (a chave nunca aparece na linha de comando).
// Chaves: ~/.local/share/quickshell-mine/ai-keys.json (chmod 600), so as que o usuario digitar. Chats salvos: .../chats/<nome>.json
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property string dir: Quickshell.env("HOME") + "/.local/share/quickshell-mine"
    property bool busy: false
    property string error: ""
    property int tokensIn: 0        // estimativa (4 letras ~ 1 token) ou o que o servidor informar
    property int tokensOut: 0
    readonly property ListModel msgs: ListModel {}
    property int revision: 0        // sobe a cada mudanca nas mensagens (rolar para baixo)

    readonly property var backends: [["ollama", "Ollama (local)"], ["openai", "OpenAI / compatível"], ["gemini", "Gemini"]]
    readonly property string backend: Settings.aiBackend
    readonly property bool needsKey: backend !== "ollama"
    readonly property string model: backend === "ollama" ? Settings.aiOllamaModel : backend === "openai" ? Settings.aiOpenaiModel : Settings.aiGeminiModel
    function setModel(m) {
        if (backend === "ollama") Settings.aiOllamaModel = m
        else if (backend === "openai") Settings.aiOpenaiModel = m
        else Settings.aiGeminiModel = m
    }

    // ---- chaves ----
    property var keys: ({})
    readonly property bool hasKey: !needsKey || !!(keys[backend] || "")
    Process { id: mk; command: ["mkdir", "-p", root.dir + "/chats"] }
    function ensureDir() { mk.running = false; mk.running = true }
    FileView {
        id: keyFile
        path: root.dir + "/ai-keys.json"
        printErrors: false
        onLoaded: { try { root.keys = JSON.parse(text()) } catch (e) { root.keys = ({}) } }
    }
    Process { id: chmodKeys; command: ["chmod", "600", root.dir + "/ai-keys.json"] }
    function setKey(k) {
        const n = Object.assign({}, keys); n[backend] = k.trim()
        keys = n
        ensureDir()
        keyFile.setText(JSON.stringify(n))
        chmodKeys.running = false; chmodKeys.running = true
    }

    // ---- modelos locais (Ollama) ----
    property var localModels: []
    property string localState: "unknown"      // unknown | ok | down | empty
    Process {
        id: tags
        command: ["curl", "-s", "-m", "3", "--fail", Settings.aiOllamaUrl.replace(/\/+$/, "") + "/api/tags"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const l = (JSON.parse(text).models || []).map(m => m.name)
                    root.localModels = l
                    root.localState = l.length ? "ok" : "empty"
                    if (l.length && l.indexOf(Settings.aiOllamaModel) < 0) Settings.aiOllamaModel = l[0]
                } catch (e) { root.localModels = []; root.localState = "down" }
                if (root.pending !== "") { const t = root.pending; root.pending = ""; root.send(t) }
            }
        }
        onExited: code => { if (code !== 0) { root.localModels = []; root.localState = "down"; if (root.pending !== "") { const t = root.pending; root.pending = ""; root.send(t) } } }
    }
    property string pending: ""     // mensagem esperando a lista de modelos do Ollama (so procuramos quando o usuario envia)
    function refreshLocal() { tags.running = false; tags.running = true }
    Connections { target: Settings; function onAiOllamaUrlChanged() { root.refreshLocal() } }

    // ---- montagem do pedido ----
    readonly property string systemText: (Settings.aiSystem.trim() !== "" ? Settings.aiSystem
        : "Você é um assistente dentro de um shell de desktop Linux (Hyprland). Responda em português do Brasil, de forma curta e direta, em Markdown.")
    function cfgStr(s) {   // string entre aspas no formato do arquivo de configuracao do curl
        return JSON.stringify(String(s)).replace(/[\u0000-\u0008\u000b-\u001f]/g, "")
    }
    function history() {
        const out = []
        for (let i = 0; i < msgs.count; i++) {
            const m = msgs.get(i)
            if (m.role === "error" || (m.role === "assistant" && m.content === "")) continue
            out.push({ role: m.role, content: m.content })
        }
        return out
    }
    function build() {
        const h = history(), t = Settings.aiTemp / 100
        const b = backend, key = keys[b] || ""
        let url, headers = ["Content-Type: application/json"], body
        if (b === "ollama") {
            url = Settings.aiOllamaUrl.replace(/\/+$/, "") + "/api/chat"
            body = { model: model, stream: true, options: { temperature: t },
                     messages: [{ role: "system", content: systemText }].concat(h) }
        } else if (b === "openai") {
            url = Settings.aiOpenaiUrl.replace(/\/+$/, "") + "/chat/completions"
            headers.push("Authorization: Bearer " + key)
            body = { model: model, stream: true, temperature: Math.min(2, t),
                     messages: [{ role: "system", content: systemText }].concat(h) }
        } else {
            url = "https://generativelanguage.googleapis.com/v1beta/models/" + encodeURIComponent(model) + ":streamGenerateContent?alt=sse"
            headers.push("x-goog-api-key: " + key)
            body = { systemInstruction: { parts: [{ text: systemText }] }, generationConfig: { temperature: Math.min(2, t) },
                     contents: h.map(m => ({ role: m.role === "assistant" ? "model" : "user", parts: [{ text: m.content }] })) }
        }
        return ["url = " + cfgStr(url)].concat(headers.map(x => "header = " + cfgStr(x)), ["data = " + cfgStr(JSON.stringify(body))]).join("\n")
    }

    // ---- resposta em fluxo ----
    function chunk(line) {
        line = line.trim()
        if (line === "") return
        const last = msgs.count - 1
        if (backend !== "ollama") {
            if (line.indexOf("data:") !== 0) { raw += line; return }
            line = line.slice(5).trim()
            if (line === "[DONE]") return
        }
        let d
        try { d = JSON.parse(line) } catch (e) { raw += line; return }
        let piece = ""
        if (d.error) { error = d.error.message || (typeof d.error === "string" ? d.error : JSON.stringify(d.error)); return }
        if (backend === "ollama") {
            piece = d.message ? (d.message.content || "") : ""
            if (d.done && d.eval_count !== undefined) { tokensIn += d.prompt_eval_count || 0; tokensOut += d.eval_count || 0; gotUsage = true }
        } else if (backend === "openai") {
            const c = d.choices && d.choices[0]
            piece = c && c.delta ? (c.delta.content || "") : ""
            if (d.usage) { tokensIn += d.usage.prompt_tokens || 0; tokensOut += d.usage.completion_tokens || 0; gotUsage = true }
        } else {
            const p = d.candidates && d.candidates[0] && d.candidates[0].content && d.candidates[0].content.parts
            piece = p ? p.map(x => x.text || "").join("") : ""
            if (d.usageMetadata) { tokensIn += 0; gotUsage = false }
        }
        if (piece !== "") { msgs.setProperty(last, "content", msgs.get(last).content + piece); revision++ }
    }
    property string raw: ""          // linhas que nao eram do fluxo (erro em texto puro)
    property bool gotUsage: false

    Process {
        id: req
        environment: ({ "AI_CFG": "" })
        command: ["sh", "-c", "printf '%s\\n' \"$AI_CFG\" | curl -sN --no-buffer -m 300 -K -"]
        stdout: SplitParser { onRead: line => root.chunk(line) }
        onExited: code => {
            root.busy = false
            const last = root.msgs.count - 1
            if (root.error === "" && code !== 0 && last >= 0 && root.msgs.get(last).content === "")
                root.error = code === 7 ? "Não consegui conectar ao servidor. Confira o endereço." : "A conexão falhou (curl " + code + ")."
            if (root.error === "" && root.raw.trim() !== "" && last >= 0 && root.msgs.get(last).content === "")
                root.error = root.raw.trim().slice(0, 300)
            if (last >= 0 && root.msgs.get(last).role === "assistant" && root.msgs.get(last).content === "") root.msgs.remove(last)
            if (root.error !== "") root.msgs.append({ role: "error", content: root.error })
            if (!root.gotUsage) root.tokensOut += Math.ceil((root.msgs.count && root.msgs.get(root.msgs.count - 1).role === "assistant" ? root.msgs.get(root.msgs.count - 1).content.length : 0) / 4)
            root.revision++
        }
    }

    // por que nao da para enviar agora ("" = pode)
    readonly property string blocker: {
        if (model.trim() === "") return backend === "ollama" ? (localState === "down" ? "O Ollama não está rodando. Abra um terminal e rode: ollama serve"
            : "Nenhum modelo do Ollama instalado. No terminal, rode: ollama pull <modelo>") : "Escolha um modelo nas configurações."
        if (needsKey && !hasKey) return "Falta a chave de API. Abra as configurações (engrenagem) e cole a chave."
        return ""
    }

    function send(text) {
        text = text.trim()
        if (text === "" || busy) return
        if (text[0] === "/" && command(text)) return
        if (backend === "ollama" && model.trim() === "" && localState === "unknown" && pending === "") { pending = text; refreshLocal(); return }
        const b = blocker
        error = ""; raw = ""; gotUsage = false
        msgs.append({ role: "user", content: text })
        tokensIn += Math.ceil(text.length / 4)
        if (b !== "") { msgs.append({ role: "error", content: b }); revision++; return }
        msgs.append({ role: "assistant", content: "" })
        revision++
        busy = true
        req.environment = ({ "AI_CFG": build() })
        req.running = false; req.running = true
    }
    function stop() { if (busy) { req.running = false } }
    function clear() { stop(); msgs.clear(); tokensIn = 0; tokensOut = 0; error = ""; revision++ }
    function note(t) { msgs.append({ role: "note", content: t }); revision++ }
    function retry() {
        if (busy) return
        let i = msgs.count - 1
        while (i >= 0 && msgs.get(i).role !== "user") { msgs.remove(i); i-- }
        if (i < 0) return
        const t = msgs.get(i).content
        msgs.remove(i)
        send(t)
    }

    // ---- comandos "/" ----
    readonly property var commands: [
        ["/clear", "Limpar a conversa"], ["/model", "Trocar de modelo: /model <nome>"], ["/temp", "Criatividade de 0 a 2: /temp 0.7"],
        ["/save", "Salvar o chat: /save <nome>"], ["/load", "Abrir um chat salvo: /load <nome>"], ["/chats", "Listar os chats salvos"],
        ["/refresh", "Reler os modelos do Ollama"], ["/retry", "Gerar de novo a última resposta"]
    ]
    function command(t) {
        const p = t.split(/\s+/), c = p[0].toLowerCase(), a = p.slice(1).join(" ")
        if (c === "/clear") { clear(); return true }
        if (c === "/retry") { retry(); return true }
        if (c === "/refresh") { refreshLocal(); note("Procurando modelos do Ollama…"); return true }
        if (c === "/model") {
            if (a === "") note("Modelo atual: " + (model || "(nenhum)")); else { setModel(a); note("Modelo: " + a) }
            return true
        }
        if (c === "/temp") {
            const v = parseFloat(a.replace(",", "."))
            if (isNaN(v) || v < 0 || v > 2) note("Use um número de 0 a 2."); else { Settings.aiTemp = Math.round(v * 100); note("Criatividade: " + v) }
            return true
        }
        if (c === "/save") { saveChat(a || "chat"); return true }
        if (c === "/load") { loadChat(a); return true }
        if (c === "/chats") { listChats(); return true }
        note("Comando desconhecido: " + c)
        return true
    }

    // ---- chats salvos ----
    function safe(n) { return n.replace(/[^\p{L}\p{N}_-]+/gu, "_").replace(/^_+|_+$/g, "").slice(0, 40) || "chat" }
    Process { id: saver; property string name: ""; onExited: code => root.note(code === 0 ? "Chat salvo como “" + name + "”." : "Não consegui salvar o chat.") }
    function saveChat(name) {
        name = safe(name)
        if (!msgs.count) { note("Não há nada para salvar."); return }
        saver.name = name; ensureDir()
        saver.environment = ({ "AI_CHAT": JSON.stringify(history()) })
        saver.command = ["sh", "-c", "printf '%s' \"$AI_CHAT\" > \"$1\"", "sh", dir + "/chats/" + name + ".json"]
        saver.running = false; saver.running = true
    }
    Process {
        id: loader
        property string name: ""
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const l = JSON.parse(text)
                    root.msgs.clear()
                    l.forEach(m => root.msgs.append({ role: m.role, content: m.content }))
                    root.note("Chat “" + loader.name + "” aberto.")
                } catch (e) { root.note("Não achei o chat “" + loader.name + "”.") }
            }
        }
    }
    function loadChat(name) {
        if (name === "") { listChats(); return }
        loader.name = safe(name)
        loader.command = ["cat", dir + "/chats/" + safe(name) + ".json"]
        loader.running = false; loader.running = true
    }
    Process {
        id: lister
        command: ["sh", "-c", "ls -1 \"$1\" 2>/dev/null | sed 's/\\.json$//'", "sh", root.dir + "/chats"]
        stdout: StdioCollector { onStreamFinished: root.note(text.trim() === "" ? "Nenhum chat salvo ainda. Use /save <nome>." : "Chats salvos:\n\n" + text.trim().split("\n").map(x => "- " + x).join("\n")) }
    }
    function listChats() { lister.running = false; lister.running = true }
}
