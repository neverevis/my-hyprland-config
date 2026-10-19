#!/usr/bin/env python3
# Aparencia do sistema (pagina Sistema): temas de icones e de cursor instalados, aplicar e baixar fontes.
#   systheme.py icons                     -> [{name, label, samples: [png/svg]}]
#   systheme.py cursors                   -> [{name, label, previews: [png]}]   (previas geradas do arquivo Xcursor)
#   systheme.py current                   -> {icons, cursor, cursorSize, font, mono}
#   systheme.py apply-icons <tema>        -> gsettings + qtengine (backup uma vez em config.json.bak-quickshell)
#   systheme.py apply-cursor <tema> <tam> -> gsettings + hyprctl setcursor (o shell grava o resto no Hyprland)
#   systheme.py apply-font <familia> <tam> / apply-mono <familia> <tam> -> gsettings + qtengine
#   systheme.py gfont <familia>           -> baixa do Google Fonts (repositorio google/fonts) para ~/.local/share/fonts
# Saida: JSON numa linha. Erros viram {"ok": false, "err": "..."}.
import json, os, re, shutil, struct, subprocess, sys, urllib.request

HOME = os.path.expanduser("~")
ICON_DIRS = [os.path.join(HOME, ".icons"), os.path.join(HOME, ".local/share/icons"), "/usr/local/share/icons", "/usr/share/icons"]
CACHE = os.path.join(HOME, ".cache/quickshell-mine/cursors")
QTENGINE = os.path.join(HOME, ".config/qtengine/config.json")
SAMPLES = [["folder", "inode-directory"], ["firefox", "web-browser", "internet-web-browser"], ["utilities-terminal", "terminal", "kitty"],
           ["preferences-system", "systemsettings", "gnome-settings"], ["accessories-text-editor", "text-editor"], ["multimedia-audio-player", "audio-x-generic"]]


def out(o):
    print(json.dumps(o, ensure_ascii=False), flush=True)


def gs(key, val=None):
    if val is None:
        r = subprocess.run(["gsettings", "get", "org.gnome.desktop.interface", key], capture_output=True, text=True, timeout=4)
        return r.stdout.strip().strip("'")
    subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", key, str(val)], capture_output=True, timeout=4)


def theme_dirs(name):
    return [os.path.join(d, name) for d in ICON_DIRS if os.path.isdir(os.path.join(d, name))]


def read_index(d):
    p = os.path.join(d, "index.theme")
    info = {}
    if not os.path.isfile(p):
        return info
    try:
        sec = ""
        for line in open(p, encoding="utf-8", errors="replace"):
            line = line.strip()
            if line.startswith("["):
                sec = line
            elif sec == "[Icon Theme]" and "=" in line:
                k, v = line.split("=", 1)
                info[k.strip()] = v.strip()
    except OSError:
        pass
    return info


def all_names():
    seen = []
    for base in ICON_DIRS:
        if not os.path.isdir(base):
            continue
        for n in sorted(os.listdir(base)):
            if n not in seen and os.path.isdir(os.path.join(base, n)):
                seen.append(n)
    return seen


def find_icon(dirs, names):
    # procura em tamanhos grandes primeiro (48, scalable, 64...) dentro das pastas do tema
    for d in dirs:
        subs = []
        for root, ds, fs in os.walk(d):
            depth = root[len(d):].count(os.sep)
            if depth > 3:
                ds[:] = []
                continue
            subs.append((root, fs))
        def rank(r):
            p = r[0]
            for i, k in enumerate(["/48", "48x48", "scalable", "/64", "64x64", "/32", "32x32"]):
                if k in p:
                    return i
            return 9
        subs.sort(key=rank)
        for names_ in names:
            for root, fs in subs:
                for ext in (".svg", ".png"):
                    if names_ + ext in fs:
                        return os.path.join(root, names_ + ext)
    return ""


def icons():
    res = []
    for n in all_names():
        dirs = theme_dirs(n)
        info = {}
        for d in dirs:
            info = read_index(d) or info
            if info:
                break
        if not info or n in ("default", "hicolor", "locolor") or (info.get("Hidden", "").lower() == "true" and n != "Adwaita"):
            continue
        if not info.get("Directories"):
            continue   # so cursores
        # herda do pai para achar exemplos (ex.: Papirus-Dark herda de Papirus)
        look = list(dirs)
        for parent in info.get("Inherits", "").split(","):
            parent = parent.strip()
            if parent and parent not in ("hicolor",):
                look += theme_dirs(parent)
        samples = [s for s in (find_icon(look, grp) for grp in SAMPLES) if s]
        res.append({"name": n, "label": info.get("Name", n), "samples": samples[:6]})
    return res


# ---- cursores: le o arquivo Xcursor e grava a maior imagem ate 48 px como PNG ----
def xcursor_png(path, dest):
    with open(path, "rb") as f:
        data = f.read()
    if data[:4] != b"Xcur":
        return False
    hsize, _, ntoc = struct.unpack("<III", data[4:16])
    best = None
    for i in range(ntoc):
        typ, sub, pos = struct.unpack("<III", data[16 + i * 12:28 + i * 12])
        if typ == 0xFFFD0002:
            w, h = struct.unpack("<II", data[pos + 16:pos + 24])
            if w <= 64 and (best is None or abs(w - 40) < abs(best[1] - 40)):
                best = (pos, w, h)
    if not best:
        return False
    pos, w, h = best
    px = data[pos + 36:pos + 36 + w * h * 4]
    from PIL import Image
    im = Image.frombuffer("RGBA", (w, h), px, "raw", "BGRA", 0, 1)
    im.save(dest)
    return True


def cursors():
    os.makedirs(CACHE, exist_ok=True)
    res = []
    for n in all_names():
        cdir = next((os.path.join(d, "cursors") for d in theme_dirs(n) if os.path.isdir(os.path.join(d, "cursors"))), "")
        if not cdir or n == "default":
            continue
        info = {}
        for d in theme_dirs(n):
            info = read_index(d) or info
        prev = []
        for shape in (["left_ptr", "default", "arrow"], ["pointer", "hand2", "hand1"], ["text", "xterm", "ibeam"], ["watch", "wait", "progress"]):
            for s in shape:
                src = os.path.realpath(os.path.join(cdir, s))
                if os.path.isfile(src):
                    dest = os.path.join(CACHE, "%s-%s.png" % (n, shape[0]))
                    try:
                        if not os.path.isfile(dest) or os.path.getmtime(dest) < os.path.getmtime(src):
                            xcursor_png(src, dest)
                        if os.path.isfile(dest):
                            prev.append(dest)
                    except Exception:
                        pass
                    break
        if prev:
            res.append({"name": n, "label": info.get("Name", n), "previews": prev})
    return res


def qtengine_set(path_keys, value):
    if not os.path.isfile(QTENGINE):
        return
    bak = QTENGINE + ".bak-quickshell"
    if not os.path.exists(bak):
        shutil.copy2(QTENGINE, bak)
    with open(QTENGINE, encoding="utf-8") as f:
        d = json.load(f)
    o = d
    for k in path_keys[:-1]:
        o = o.setdefault(k, {})
    o[path_keys[-1]] = value
    tmp = QTENGINE + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(d, f, indent=4, ensure_ascii=False)
        f.write("\n")
    os.replace(tmp, QTENGINE)


def current():
    o = {"icons": gs("icon-theme"), "cursor": gs("cursor-theme"), "cursorSize": int(gs("cursor-size") or 24)}
    m = re.match(r"(.*?)\s+(\d+(?:\.\d+)?)$", gs("font-name"))
    o["font"], o["fontSize"] = (m.group(1), float(m.group(2))) if m else (gs("font-name"), 11)
    m = re.match(r"(.*?)\s+(\d+(?:\.\d+)?)$", gs("monospace-font-name"))
    o["mono"], o["monoSize"] = (m.group(1), float(m.group(2))) if m else (gs("monospace-font-name"), 11)
    return o


# ---- Google Fonts: lista a pasta da familia no github.com/google/fonts e baixa os .ttf ----
def gfont(family):
    slug = re.sub(r"[^a-z0-9]", "", family.lower())
    if not slug:
        return {"ok": False, "err": "nome vazio"}
    files = None
    for lic in ("ofl", "apache", "ufl"):
        try:
            req = urllib.request.Request("https://api.github.com/repos/google/fonts/contents/%s/%s" % (lic, slug), headers={"User-Agent": "quickshell-mine"})
            with urllib.request.urlopen(req, timeout=20) as r:
                items = json.load(r)
            files = [i for i in items if i.get("name", "").lower().endswith(".ttf")]
            if files:
                break
        except Exception:
            continue
    if not files:
        return {"ok": False, "err": "Não achei \"%s\" no Google Fonts (confira o nome)." % family}
    dest = os.path.join(HOME, ".local/share/fonts/google", slug)
    os.makedirs(dest, exist_ok=True)
    got = 0
    for i in files[:24]:
        name = os.path.basename(i["name"])
        if "/" in name or name.startswith("."):
            continue
        try:
            with urllib.request.urlopen(urllib.request.Request(i["download_url"], headers={"User-Agent": "quickshell-mine"}), timeout=60) as r:
                blob = r.read()
            if blob[:4] not in (b"\x00\x01\x00\x00", b"true", b"OTTO"):
                continue
            with open(os.path.join(dest, name), "wb") as f:
                f.write(blob)
            got += 1
        except Exception:
            continue
    subprocess.run(["fc-cache", "-f", dest], capture_output=True, timeout=120)
    return {"ok": got > 0, "files": got, "dir": dest, "err": "" if got else "download falhou"}


def main():
    a = sys.argv[1:]
    if not a:
        return out({"ok": False, "err": "uso"})
    c = a[0]
    try:
        if c == "icons":
            out(icons())
        elif c == "cursors":
            out(cursors())
        elif c == "current":
            out(current())
        elif c == "apply-icons":
            gs("icon-theme", a[1]); qtengine_set(["theme", "iconTheme"], a[1]); out({"ok": True})
        elif c == "apply-cursor":
            size = int(a[2]) if len(a) > 2 else 24
            gs("cursor-theme", a[1]); gs("cursor-size", size)
            subprocess.run(["hyprctl", "setcursor", a[1], str(size)], capture_output=True, timeout=5)
            out({"ok": True})
        elif c in ("apply-font", "apply-mono"):
            size = float(a[2]) if len(a) > 2 else 11
            gs("font-name" if c == "apply-font" else "monospace-font-name", "%s %g" % (a[1], size))
            qtengine_set(["theme", "font" if c == "apply-font" else "fontFixed", "family"], a[1])
            out({"ok": True})
        elif c == "gfont":
            out(gfont(" ".join(a[1:])))
        else:
            out({"ok": False, "err": "comando desconhecido"})
    except Exception as e:
        out({"ok": False, "err": str(e)[:200]})


if __name__ == "__main__":
    main()
