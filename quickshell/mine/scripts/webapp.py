#!/usr/bin/env python3
# Webapps: atalhos .desktop que abrem um site como app (navegador Chromium com --app=). Os arquivos ficam em
# ~/.local/share/applications/shell-webapp-<nome>.desktop (so os criados aqui; o launcher ja indexa os .desktop).
#   webapp.py list                       -> JSON [{id, name, url}]
#   webapp.py add <url> [navegador]      -> cria; imprime ok ou erro
#   webapp.py remove <id>                -> apaga o .desktop e o icone
import json, os, re, subprocess, sys, urllib.parse

HOME = os.path.expanduser("~")
APPS = HOME + "/.local/share/applications"
ICONS = HOME + "/.local/share/quickshell-mine/webapp-icons"
PFX = "shell-webapp-"

def slug(host):
    return re.sub(r"[^a-z0-9]+", "-", host.lower()).strip("-")

def read(path):
    d = {}
    for l in open(path, errors="ignore"):
        if "=" in l and not l.startswith("["):
            k, v = l.rstrip("\n").split("=", 1)
            d.setdefault(k, v)
    return d

def lst():
    out = []
    if os.path.isdir(APPS):
        for f in sorted(os.listdir(APPS)):
            if f.startswith(PFX) and f.endswith(".desktop"):
                d = read(os.path.join(APPS, f))
                m = re.search(r"--app=(\S+)", d.get("Exec", ""))
                out.append({"id": f[len(PFX):-8], "name": d.get("Name", f), "url": m.group(1) if m else ""})
    return out

def icon_for(url, sid):
    os.makedirs(ICONS, exist_ok=True)
    p = urllib.parse.urlparse(url)
    ico, png = f"{ICONS}/{sid}.ico", f"{ICONS}/{sid}.png"
    try:
        subprocess.run(["curl", "-fsL", "--max-time", "6", "-o", ico, f"{p.scheme}://{p.netloc}/favicon.ico"], check=True, capture_output=True)
        if open(ico, "rb").read(4) == b"\x89PNG":
            os.replace(ico, png); return png
        for tool in (["magick", ico + "[0]", png], ["convert", ico + "[0]", png]):
            try:
                subprocess.run(tool, check=True, capture_output=True, timeout=8)
                if os.path.exists(png): return png
            except Exception:
                pass
    except Exception:
        pass
    return "applications-internet"

def add(url, browser):
    if not re.match(r"^https?://", url): url = "https://" + url
    p = urllib.parse.urlparse(url)
    if not p.netloc or " " in url: print("erro: endereço inválido"); return
    sid = slug(p.netloc)
    name = p.netloc.removeprefix("www.").split(".")[0].capitalize()
    os.makedirs(APPS, exist_ok=True)
    icon = icon_for(url, sid)
    open(f"{APPS}/{PFX}{sid}.desktop", "w").write(
        f"[Desktop Entry]\nType=Application\nName={name}\nComment=Webapp (criado pelo shell)\nExec={browser} --app={url}\nIcon={icon}\n"
        f"Terminal=false\nCategories=Network;\nStartupWMClass={p.netloc}\n")
    print("ok")

def remove(sid):
    sid = re.sub(r"[^a-z0-9-]", "", sid)
    for f in (f"{APPS}/{PFX}{sid}.desktop", f"{ICONS}/{sid}.png", f"{ICONS}/{sid}.ico"):
        if os.path.exists(f): os.remove(f)
    print("ok")

a = sys.argv[1:]
if a and a[0] == "list": print(json.dumps(lst()))
elif len(a) >= 2 and a[0] == "add": add(a[1], a[2] if len(a) > 2 else "brave")
elif len(a) >= 2 and a[0] == "remove": remove(a[1])
