#!/usr/bin/env python3
# Visuais do shell em .zip (ver Looks.qml).
#   looks.py export <look.json>                 -> grava ~/Downloads/<nome>.visual.zip (ou na pasta pessoal); imprime {"path"}
#   looks.py scan <pasta de wallpapers>         -> procura .zip de visuais em Downloads, pasta pessoal e wallpapers; {"files": [...]}
#   looks.py import <zip> <pasta de wallpapers> <chaves permitidas (JSON)>  -> {"name", "data", "missing"}
# Dentro do zip: look.json ({app, version, name, created, data}) e files/<arquivo> (wallpaper e imagens dos widgets).
# Na importacao so entram as chaves conhecidas e so arquivos de imagem dentro de files/ (nada de caminhos com ..);
# o wallpaper vai para a pasta de wallpapers (aparece no seletor) e o resto para ~/.local/share/quickshell-mine/looks/<nome>/.
import json, os, re, shutil, sys, zipfile, hashlib

HOME = os.path.expanduser("~")
IMG = (".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".svg", ".avif", ".jxl")
MAX_FILE = 80 * 1024 * 1024
APP = "quickshell-mine"

def slug(s):
    s = re.sub(r"[^\w\- ]+", "", s, flags=re.UNICODE).strip().replace(" ", "-")
    return s[:60] or "visual"

def walk(v, fn):
    if isinstance(v, dict):
        return {k: walk(x, fn) for k, x in v.items()}
    if isinstance(v, list):
        return [walk(x, fn) for x in v]
    if isinstance(v, str):
        return fn(v)
    return v

def out_dir():
    for d in (os.path.join(HOME, "Downloads"), os.path.join(HOME, "Transferências"), HOME):
        if os.path.isdir(d):
            return d
    return HOME

def export(path):
    look = json.load(open(path, encoding="utf-8"))
    files = {}
    def collect(s):
        if s.startswith("/") and s.lower().endswith(IMG) and os.path.isfile(s) and os.path.getsize(s) <= MAX_FILE:
            base = os.path.basename(s)
            # nomes iguais de pastas diferentes: acrescenta um pedaco do hash
            if base in files and files[base] != s:
                h = hashlib.sha1(s.encode()).hexdigest()[:6]
                b, e = os.path.splitext(base)
                base = f"{b}-{h}{e}"
            files[base] = s
            return "files/" + base
        return s
    look["data"] = walk(look.get("data", {}), collect)
    look["app"] = APP
    dest = os.path.join(out_dir(), slug(look.get("name", "visual")) + ".visual.zip")
    with zipfile.ZipFile(dest, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("look.json", json.dumps(look, ensure_ascii=False, indent=2))
        for base, src in files.items():
            z.write(src, "files/" + base, compress_type=zipfile.ZIP_STORED)
    print(json.dumps({"path": dest}))

def read_look(z):
    try:
        info = z.getinfo("look.json")
    except KeyError:
        return None
    if info.file_size > 4 * 1024 * 1024:
        return None
    try:
        look = json.loads(z.read(info).decode("utf-8"))
    except Exception:
        return None
    return look if isinstance(look, dict) and look.get("app") == APP and isinstance(look.get("data"), dict) else None

def scan(wpdir):
    wpdir = os.path.expanduser(wpdir) if wpdir else ""
    seen, res = set(), []
    for d in (os.path.join(HOME, "Downloads"), os.path.join(HOME, "Transferências"), HOME, wpdir):
        if not d or not os.path.isdir(d):
            continue
        for f in sorted(os.listdir(d)):
            p = os.path.join(d, f)
            if not f.lower().endswith(".zip") or p in seen or not os.path.isfile(p):
                continue
            seen.add(p)
            try:
                with zipfile.ZipFile(p) as z:
                    look = read_look(z)
            except Exception:
                continue
            if look:
                res.append({"path": p, "name": look.get("name", f), "created": look.get("created", 0), "keys": sorted(look["data"].keys())})
    print(json.dumps({"files": res}))

def unique_copy(data, dest_dir, base):
    os.makedirs(dest_dir, exist_ok=True)
    dest = os.path.join(dest_dir, base)
    if os.path.exists(dest):
        if open(dest, "rb").read() == data:
            return dest
        b, e = os.path.splitext(base)
        i = 2
        while os.path.exists(os.path.join(dest_dir, f"{b}-{i}{e}")):
            i += 1
        dest = os.path.join(dest_dir, f"{b}-{i}{e}")
    with open(dest, "wb") as f:
        f.write(data)
    return dest

def do_import(zpath, wpdir, allowed_json):
    wpdir = os.path.expanduser(wpdir) if wpdir else ""
    allowed = set(json.loads(allowed_json))
    with zipfile.ZipFile(zpath) as z:
        look = read_look(z)
        if not look:
            sys.exit("este .zip nao e um visual do shell")
        name = str(look.get("name") or "Importado")[:80]
        data = {k: v for k, v in look["data"].items() if k in allowed}
        members = {}
        for info in z.infolist():
            n = info.filename
            if not n.startswith("files/") or n.endswith("/"):
                continue
            base = n[len("files/"):]
            if "/" in base or "\\" in base or base.startswith(".") or ".." in base or not base.lower().endswith(IMG):
                continue
            if info.file_size > MAX_FILE:
                continue
            members[base] = info
        assets = os.path.join(HOME, ".local/share/quickshell-mine/looks", slug(name))
        wall = data.get("wallpaper") if isinstance(data.get("wallpaper"), str) else ""
        missing, placed = [], {}
        def place(s):
            if not s.startswith("files/"):
                return s
            base = s[len("files/"):]
            if base in placed:
                return placed[base]
            info = members.get(base)
            if not info:
                missing.append(base)
                return ""
            dest = unique_copy(z.read(info), wpdir if (s == wall and wpdir and os.path.isdir(wpdir)) else assets, base)
            placed[base] = dest
            return dest
        data = walk(data, place)
    print(json.dumps({"name": name, "data": data, "missing": missing}, ensure_ascii=False))

def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "export":
        export(sys.argv[2])
    elif cmd == "scan":
        scan(sys.argv[2] if len(sys.argv) > 2 else "")
    elif cmd == "import":
        do_import(sys.argv[2], sys.argv[3], sys.argv[4])
    else:
        sys.exit("uso: looks.py export|scan|import ...")

main()
