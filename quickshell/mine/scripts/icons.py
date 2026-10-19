#!/usr/bin/env python3
# Indice de icones do tema: nome -> arquivo (o maior tamanho ate 128 px, ou o svg escalavel), seguindo os temas herdados
# (Inherits do index.theme) ate o hicolor e /usr/share/pixmaps. O shell carrega o arquivo direto, sem o carregador de
# icones do Qt/KDE (o KIconLoader nao aguenta ser chamado de duas threads e derrubava o shell).
# Uso: icons.py <tema|auto> <saida.json>   (grava so se mudou; imprime o numero de icones)
# auto = o tema do qtengine (~/.config/qtengine/config.json), do KDE (kdeglobals) ou do GTK (gsettings).
# Saida compacta: {"theme", "dirs": [pastas], "icons": {nome: [indice da pasta, extensao]}}
import json, os, re, sys

BASES = [os.path.expanduser("~/.local/share/icons"), os.path.expanduser("~/.icons"), "/usr/local/share/icons", "/usr/share/icons"]
EXTS = (".svg", ".png", ".xpm")

def theme_dirs(name):
    # o mesmo tema pode estar em varias pastas (ex.: hicolor em ~/.local/share/icons e em /usr/share/icons): todas valem,
    # a do usuario primeiro
    return [os.path.join(b, name) for b in BASES if os.path.isdir(os.path.join(b, name))]

def inherits(ds):
    for d in ds:
        try:
            with open(os.path.join(d, "index.theme"), encoding="utf-8", errors="ignore") as f:
                for line in f:
                    if line.startswith("Inherits="):
                        return [x.strip() for x in line[9:].split(",") if x.strip()]
        except OSError:
            pass
    return []

def score(rel):
    # tamanho do diretorio (64x64, 64x64@2x, scalable...); preferir ~64-128 px, svg escalavel e a categoria apps
    m = re.match(r"(\d+)x\d+(@(\d)x)?", rel)
    if rel.startswith("scalable"):
        s = 120
    elif m:
        px = int(m.group(1)) * (int(m.group(3)) if m.group(3) else 1)
        s = px if px <= 128 else 128 - (px - 128) / 10
    else:
        s = 10
    if "/apps" in rel or rel.endswith("apps"):
        s += 5
    return s

def index_theme(d, out, seen):
    best = {}
    for root, _dirs, files in os.walk(d, followlinks=True):
        rel = os.path.relpath(root, d)
        sc = score(rel)
        for f in files:
            if not f.endswith(EXTS):
                continue
            n = f[: f.rfind(".")]
            if n in seen:
                continue
            if n not in best or sc > best[n][0] or (sc == best[n][0] and f.endswith(".svg")):
                best[n] = (sc, os.path.join(root, f))
    for n, (_s, p) in best.items():
        out[n] = p
        seen.add(n)

def auto_theme():
    try:
        with open(os.path.expanduser("~/.config/qtengine/config.json"), encoding="utf-8") as f:
            t = re.search(r'"iconTheme"\s*:\s*"([^"]+)"', f.read())
            if t:
                return t.group(1)
    except OSError:
        pass
    try:
        with open(os.path.expanduser("~/.config/kdeglobals"), encoding="utf-8", errors="ignore") as f:
            sec = ""
            for line in f:
                line = line.strip()
                if line.startswith("["):
                    sec = line
                elif sec == "[Icons]" and line.startswith("Theme="):
                    return line[6:]
    except OSError:
        pass
    try:
        import subprocess
        t = subprocess.run(["gsettings", "get", "org.gnome.desktop.interface", "icon-theme"], capture_output=True, text=True, timeout=3).stdout.strip().strip("'")
        if t:
            return t
    except Exception:
        pass
    return "hicolor"

def main():
    theme, dest = sys.argv[1], sys.argv[2]
    if theme == "auto":
        theme = auto_theme()
    out, seen, done, queue = {}, set(), set(), [theme]
    while queue:
        t = queue.pop(0)
        if t in done:
            continue
        done.add(t)
        ds = theme_dirs(t)
        for d in ds:
            index_theme(d, out, seen)
        queue += inherits(ds)
    if "hicolor" not in done:
        for d in theme_dirs("hicolor"):
            index_theme(d, out, seen)
    for pd in ("/usr/share/pixmaps", os.path.expanduser("~/.local/share/pixmaps")):
        if os.path.isdir(pd):
            for f in os.listdir(pd):
                if f.endswith(EXTS):
                    n = f[: f.rfind(".")]
                    if n not in seen:
                        out[n] = os.path.join(pd, f)
                        seen.add(n)
    dirs, di, comp = [], {}, {}
    for n, p in out.items():
        d, f = os.path.split(p)
        if d not in di:
            di[d] = len(dirs); dirs.append(d)
        comp[n] = [di[d], f[len(n):]]
    data = json.dumps({"theme": theme, "dirs": dirs, "icons": comp}, separators=(",", ":"))
    try:
        with open(dest, encoding="utf-8") as f:
            if f.read() == data:
                print(len(out)); return
    except OSError:
        pass
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    tmp = dest + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(data)
    os.replace(tmp, dest)
    print(len(out))

main()
