#!/usr/bin/env python3
# Lista de atalhos do Hyprland para o launcher (prefixo "<"): le ~/.config/hypr/variables.lua (kbXxx = "TECLAS") e
# hyprland/keybinds.lua (create_bind / hl.bind). Com a config em Lua o "hyprctl binds" so mostra "__lua", entao o nome
# de cada atalho sai do nome da variavel (kbTerminal -> "Abrir o terminal") ou do comentario da linha.
# Saida: [{"keys": "SUPER + T", "label": "...", "section": "..."}]
import json, os, re, sys, subprocess

HYPR = os.path.expanduser("~/.config/hypr")
NAMES = {
    "kbTerminal": "Abrir o terminal", "kbBrowser": "Abrir o navegador", "kbEditor": "Abrir o editor",
    "kbFileExplorer": "Abrir os arquivos", "kbAudioSettings": "Configurações de áudio",
    "kbCloseWindow": "Fechar a janela (ou o painel do shell aberto)", "kbPinWindow": "Fixar a janela em todos os workspaces",
    "kbWindowFullscreen": "Tela cheia", "kbWindowBorderedFullscreen": "Maximizar", "kbToggleWindowFloating": "Janela flutuante",
    "kbCenterWindow": "Centralizar a janela", "kbNormalizeWindow": "Tamanho normal e centralizada", "kbWindowPip": "Imagem no canto (PiP)",
    "kbMoveWindow": "Mover a janela (arrastar)", "kbResizeWindow": "Redimensionar a janela (arrastar)",
    "kbWindowDecreaseWidth": "Diminuir a largura", "kbWindowIncreaseWidth": "Aumentar a largura",
    "kbWindowDecreaseHeight": "Diminuir a altura", "kbWindowIncreaseHeight": "Aumentar a altura",
    "kbWindowCycleNext": "Próxima janela", "kbWindowCyclePrev": "Janela anterior",
    "kbWindowGroupCycleNext": "Próxima janela do grupo", "kbWindowGroupCyclePrev": "Janela anterior do grupo",
    "kbToggleGroup": "Agrupar janelas", "kbUngroup": "Tirar do grupo", "kbGroupLockActive": "Travar o grupo",
    "kbNextWs": "Próximo workspace", "kbPrevWs": "Workspace anterior", "kbNextWsGroup": "Próximo grupo de workspaces", "kbPrevWsGroup": "Grupo de workspaces anterior",
    "kbMoveWinToWsNext": "Levar a janela para o próximo workspace", "kbMoveWinToWsPrev": "Levar a janela para o workspace anterior",
    "kbMoveWinToWsSpecial": "Guardar a janela no workspace especial", "kbMoveWinFromWsSpecial": "Tirar a janela do workspace especial",
    "kbSpecialWs": "Workspace especial", "kbSystemMonitorWs": "Monitor do sistema", "kbMusicWs": "Workspace de música",
    "kbCommunicationWs": "Workspace de conversas", "kbTodoWs": "Workspace de tarefas",
    "kbScreenshot": "Capturar a tela inteira", "kbScreenshotFreeze": "Capturar uma área (congelada)", "kbScreenshotRegion": "Capturar uma área",
    "kbColorPicker": "Pegar uma cor da tela", "kbWallpaper": "Wallpaper aleatório", "kbWallpaperPicker": "Seletor de wallpaper",
    "kbShellSettings": "Configurações do shell", "kbDesktopWidgetsEdit": "Editar os widgets",
    "kbLock": "Bloquear a tela", "kbSession": "Menu de energia", "kbSleep": "Suspender",
    "kbMediaToggle": "Tocar / pausar", "kbMediaNext": "Próxima faixa", "kbMediaPrev": "Faixa anterior", "kbMediaStop": "Parar a mídia",
    "kbVolumeMute": "Silenciar", "kbClipboardPasteLatest": "Colar o último copiado", "kbLauncher": "Painel Início",
}

def strip_comment(line):
    out, q = [], None
    i = 0
    while i < len(line):
        c = line[i]
        if q:
            out.append(c)
            if c == "\\" and i + 1 < len(line):
                out.append(line[i + 1]); i += 2; continue
            if c == q:
                q = None
        elif c in "\"'":
            q = c; out.append(c)
        elif line.startswith("--", i):
            return "".join(out), line[i + 2:].strip()
        else:
            out.append(c)
        i += 1
    return "".join(out), ""

def load_vars():
    v = {}
    try:
        text = open(os.path.join(HYPR, "variables.lua"), encoding="utf-8").read()
    except OSError:
        return v
    for m in re.finditer(r"\b(kb\w+)\s*=\s*(\"[^\"]*\"|\{[^}]*\})", text):
        val = m.group(2)
        v[m.group(1)] = re.findall(r"\"([^\"]*)\"", val) if val.startswith("{") else [val.strip('"')]
    return v

def pretty(k):
    parts = [p.strip() for p in k.split("+")]
    nice = {"SUPER": "Super", "SHIFT": "Shift", "CTRL": "Ctrl", "ALT": "Alt", "mouse_down": "Roda ↓", "mouse_up": "Roda ↑",
            "mouse:272": "Botão esquerdo", "mouse:273": "Botão direito", "Page_Down": "PgDn", "Page_Up": "PgUp", "Backslash": "\\",
            "Comma": ",", "Minus": "-", "Equal": "=", "Escape": "Esc", "SUPER_L": "Super", "TAB": "Tab", "Space": "Espaço",
            "XF86AudioPlay": "Tecla Play", "XF86AudioPause": "Tecla Pausa", "XF86AudioNext": "Tecla Próxima", "XF86AudioPrev": "Tecla Anterior",
            "XF86AudioStop": "Tecla Parar", "XF86AudioMute": "Tecla Mudo", "XF86AudioMicMute": "Tecla Mudo do microfone",
            "XF86AudioRaiseVolume": "Tecla Volume +", "XF86AudioLowerVolume": "Tecla Volume −", "Print": "Print Screen"}
    r = [nice.get(p, p[:1].upper() + p[1:] if p.islower() and len(p) > 1 else p) for p in parts]
    if r == ["Super", "Super"]:
        return "Super (sozinho)"
    return " + ".join(r)

SECTIONS = [("media", "Mídia"), ("bloqueio", "Sessão"), ("workspace", "Workspaces"), ("window group", "Janelas"), ("window", "Janelas"), ("janela", "Janelas"),
            ("launcher", "Shell"), ("quickshell", "Shell"), ("noctalia", "Shell"), ("app", "Apps"), ("utilit", "Utilidades"),
            ("captura", "Utilidades"), ("media", "Mídia"), ("volume", "Volume"), ("brightness", "Brilho"), ("sleep", "Sessão"),
            ("bloqueio", "Sessão"), ("clipboard", "Área de transferência"), ("test", "Teste"), ("misc", "Workspaces")]
def section_of(comment, cur):
    c = comment.lower()
    for k, v in SECTIONS:
        if k in c:
            return v
    return cur if len(comment) > 30 else comment

def humanize(var, action, comment):
    if var and var in NAMES:
        return NAMES[var]
    if comment:
        return comment[:1].upper() + comment[1:]
    m = re.search(r"exec_cmd\(\s*\"([^\"]+)\"", action)
    if m:
        cmd = m.group(1)
        for pat, lab in (("AUDIO_SOURCE@ toggle", "Silenciar o microfone"), ("%+", "Aumentar o volume"), ("%-", "Diminuir o volume"),
                         ("notify-send", "Notificação de teste"), ("cliphist", "Colar o último copiado")):
            if pat in cmd or pat in action:
                return lab
        ipc = re.search(r"ipc call (\w+) (\w+)", cmd)
        if ipc:
            return "Shell: " + ipc.group(1) + " " + ipc.group(2)
        return "Executar: " + cmd.split("/")[-1][:60]
    m = re.search(r"hl\.dsp\.([\w.]+)", action)
    if m:
        return m.group(1).replace(".", " ").replace("_", " ")
    if var:
        return re.sub(r"(?<!^)([A-Z])", r" \1", var[2:]).lower().capitalize()
    return "Atalho"

def main():
    vars_ = load_vars()
    out, seen = [], set()
    section = ""
    try:
        lines = open(os.path.join(HYPR, "hyprland", "keybinds.lua"), encoding="utf-8").read().split("\n")
    except OSError:
        lines = []
    i = 0
    while i < len(lines):
        raw = lines[i]
        code, comment = strip_comment(raw)
        if not code.strip() and comment and not comment.startswith("-"):
            section = section_of(comment, section)
            i += 1
            continue
        m = re.search(r"\b(create_bind|hl\.bind)\(\s*(.*)$", code)
        if not m:
            i += 1
            continue
        # junta linhas ate fechar o primeiro argumento (create_bind(\n vars.kb..., ...)
        body = m.group(2)
        j = i
        while not body.strip() and j + 1 < len(lines):
            j += 1
            body += strip_comment(lines[j])[0]
        arg = body.strip()
        keys, var = [], ""
        if arg.startswith("{"):
            inner = arg[1:arg.find("}")] if "}" in arg else arg[1:]
            for part in inner.split(","):
                part = part.strip()
                if part.startswith("vars."):
                    var = part[5:]; keys += vars_.get(var, [])
                elif part.startswith('"'):
                    keys.append(part.strip('"'))
        elif arg.startswith("vars."):
            var = re.match(r"vars\.(\w+)", arg).group(1)
            keys = vars_.get(var, [])
        elif ".. dir" in arg.split(",")[0]:
            mod = re.match(r"\"([^\"]*)\"", arg).group(1)
            what = "Mover a janela" if "SHIFT" in mod else "Focar a janela"
            key = (mod + "setas").replace("+ setas", "+ Setas")
            if key not in seen:
                seen.add(key)
                out.append({"keys": pretty(mod.rstrip(" +")) + " + Setas", "label": what + " na direção", "section": section})
            i = j + 1
            continue
        elif arg.startswith('"'):
            keys = [re.match(r"\"([^\"]*)\"", arg).group(1)]
        elif arg.startswith("extend_keybind"):
            em = re.search(r"vars\.(\w+)", arg)
            if em:
                var = em.group(1)
                base = vars_.get(var, [""])[0]
                lab = {"kbGoToWs": "Ir para o workspace 1–10", "kbMoveWinToWs": "Levar a janela para o workspace 1–10",
                       "kbGoToWsGroup": "Ir para o grupo de workspaces 1–10", "kbMoveWinToWsGroup": "Levar a janela para o grupo 1–10"}.get(var)
                if base and lab and var not in seen:
                    seen.add(var)
                    out.append({"keys": pretty(base + " + 1…0"), "label": lab, "section": section})
            i = j + 1
            continue
        rest = body + " " + " ".join(strip_comment(l)[0] for l in lines[j + 1:j + 4])
        label = humanize(var, rest, comment)
        for k in keys:
            if not k or (k, label) in seen:
                continue
            seen.add((k, label))
            out.append({"keys": pretty(k), "label": label, "section": section})
        i = j + 1
    if not out:   # reserva: o que o Hyprland sabe (so com descricao)
        try:
            for b in json.loads(subprocess.run(["hyprctl", "binds", "-j"], capture_output=True, text=True, timeout=3).stdout):
                if b.get("description"):
                    out.append({"keys": str(b.get("key")), "label": b["description"], "section": ""})
        except Exception:
            pass
    print(json.dumps(out, ensure_ascii=False))

main()
