#!/usr/bin/env python3
# Aplicativos (Configuracoes > Aplicativos): lista os apps instalados e busca o que instalar. So le, nunca instala nada.
#   apps.py list                  -> JSON {tools, dry, pkgs, apps: [{id, name, icon, path, pkg, src, size, version, desc, flatpak}], pkgs: N}
#                                    src: pacman | aur | flatpak | local. Um passo so pelo banco do pacman (sem pacman -Qo por app).
#   apps.py search-repo <texto>   -> JSON [{pkg, repo, version, desc, installed}]  (pacman -Ss, ate 30)
#   apps.py search-aur <texto>    -> JSON [{pkg, version, desc, installed, votes}]  (AUR RPC v5, ate 30)
#   apps.py search-flatpak <texto>-> JSON [{pkg(id), name, version, desc, installed}]  (se o flatpak existir)
#   apps.py autostart [dir]       -> JSON [{file, name, comment, exec, enabled, system, path}]  (~/.config/autostart + /etc/xdg/autostart)
#   apps.py autostart-set <arquivo> <on|off> [dir] -> guarda copia em .bak e liga/desliga com Hidden=true
import json, os, re, shutil, subprocess, sys, urllib.parse, urllib.request, glob

HOME = os.path.expanduser("~")
DB = "/var/lib/pacman/local"
APPDIRS = ["/usr/share/applications", HOME + "/.local/share/applications"]
FLATDIRS = ["/var/lib/flatpak/exports/share/applications", HOME + "/.local/share/flatpak/exports/share/applications"]


def out(o):
    print(json.dumps(o, ensure_ascii=False), flush=True)


def run(cmd, t=20):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=t).stdout
    except Exception:
        return ""


def desktop(path):
    d = {}
    sec = ""
    try:
        for l in open(path, errors="ignore"):
            l = l.rstrip("\n")
            if l.startswith("["):
                sec = l
                continue
            if sec != "[Desktop Entry]" or "=" not in l or l.startswith("#"):
                continue
            k, v = l.split("=", 1)
            if k not in d:   # a versao sem idioma vem primeiro; Name[pt_BR] so se existir
                d[k] = v
            if k in ("Name[pt_BR]", "Name[pt]") and "Name" in d:
                d["Name"] = v if "Name_pt" not in d else d["Name"]
                d["Name_pt"] = v
    except Exception:
        pass
    return d


def pkgdb():
    # arquivo .desktop (caminho) -> pacote; pacote -> {version, size, desc}
    owner, info = {}, {}
    try:
        names = os.listdir(DB)
    except Exception:
        return owner, info, 0
    for n in names:
        base = DB + "/" + n
        try:
            desc = open(base + "/desc", errors="ignore").read()
            files = open(base + "/files", errors="ignore").read()
        except Exception:
            continue
        m = re.search(r"%NAME%\n(.+)", desc)
        if not m:
            continue
        pkg = m.group(1).strip()
        v = re.search(r"%VERSION%\n(.+)", desc)
        s = re.search(r"%SIZE%\n(\d+)", desc)
        ds = re.search(r"%DESC%\n(.+)", desc)
        info[pkg] = {"version": v.group(1).strip() if v else "", "size": int(s.group(1)) if s else 0, "desc": ds.group(1).strip() if ds else ""}
        if ".desktop" in files:
            for f in files.split("\n"):
                if f.endswith(".desktop") and f.startswith("usr/share/applications/"):
                    owner["/" + f] = pkg
    return owner, info, len(info)


def installed_set():
    return set(run(["pacman", "-Qq"]).split())


def flatpak_list():
    if not shutil.which("flatpak"):
        return {}
    res = {}
    for l in run(["flatpak", "list", "--app", "--columns=application,name,version,size,origin"]).split("\n"):
        p = l.split("\t")
        if len(p) >= 4 and p[0]:
            res[p[0]] = {"name": p[1], "version": p[2], "size": p[3], "origin": p[4] if len(p) > 4 else ""}
    return res


def cmd_list():
    owner, info, npk = pkgdb()
    foreign = set(run(["pacman", "-Qmq"]).split())
    fl = flatpak_list()
    apps = {}
    for dirs, kind in ((APPDIRS, "sys"), (FLATDIRS, "flat")):
        for dd in dirs:
            for p in glob.glob(dd + "/*.desktop"):
                id = os.path.basename(p)
                d = desktop(p)
                if d.get("Type", "Application") != "Application" or d.get("NoDisplay", "").lower() == "true" or d.get("Hidden", "").lower() == "true":
                    continue
                name = d.get("Name_pt") or d.get("Name") or id[:-8]
                a = {"id": id, "name": name, "icon": d.get("Icon", ""), "path": p, "pkg": "", "src": "local", "size": 0, "version": "", "desc": d.get("Comment", ""), "flatpak": ""}
                fid = id[:-8]
                if kind == "flat" or fid in fl:
                    f = fl.get(fid, {})
                    a.update(src="flatpak", pkg=fid, flatpak=fid, version=f.get("version", ""), sizeText=f.get("size", ""))
                elif p in owner:
                    pk = owner[p]
                    i = info.get(pk, {})
                    a.update(pkg=pk, src="aur" if pk in foreign else "pacman", size=i.get("size", 0), version=i.get("version", ""))
                    if not a["desc"]:
                        a["desc"] = i.get("desc", "")
                elif os.path.realpath(p) != p and os.path.realpath(p) in owner:
                    pk = owner[os.path.realpath(p)]
                    i = info.get(pk, {})
                    a.update(pkg=pk, src="aur" if pk in foreign else "pacman", size=i.get("size", 0), version=i.get("version", ""))
                apps[id] = a   # a do usuario (lida depois) vale mais que a do sistema
    lst = sorted(apps.values(), key=lambda a: a["name"].lower())
    helper = shutil.which("paru") and "paru" or shutil.which("yay") and "yay" or ""
    dry = os.environ.get("QS_APPS_DRYRUN") == "1" or os.path.exists(HOME + "/.cache/quickshell-mine/apps-dryrun")
    out({"apps": lst, "pkgs": npk, "tools": {"flatpak": bool(shutil.which("flatpak")), "helper": helper, "expac": bool(shutil.which("expac"))}, "dry": dry})


def clean(q):
    return re.sub(r"[^\w\s.+@-]", " ", q).strip()


def cmd_repo(q):
    q = clean(q)
    if not q:
        return out([])
    res = []
    cur = None
    for l in run(["pacman", "-Ss", "--"] + q.split()).split("\n"):
        if l.startswith("    "):
            if cur:
                cur["desc"] = l.strip()
            continue
        m = re.match(r"(\S+)/(\S+) (\S+)(.*)", l)
        if m:
            cur = {"repo": m.group(1), "pkg": m.group(2), "version": m.group(3), "desc": "", "installed": "[installed" in m.group(4)}
            res.append(cur)
    qq = q.lower()
    res.sort(key=lambda r: (0 if r["pkg"].lower() == qq else 1 if r["pkg"].lower().startswith(qq) else 2 if qq in r["pkg"].lower() else 3, len(r["pkg"])))
    out(res[:30])


def cmd_aur(q):
    q = clean(q)
    if len(q) < 2:
        return out([])
    try:
        req = urllib.request.Request("https://aur.archlinux.org/rpc/v5/search/" + urllib.parse.quote(q) + "?by=name-desc", headers={"User-Agent": "quickshell-mine"})
        d = json.load(urllib.request.urlopen(req, timeout=10))
    except Exception as e:
        return out({"err": "Sem resposta do AUR (" + type(e).__name__ + ")"})
    inst = installed_set()
    rs = sorted(d.get("results", []), key=lambda r: -(r.get("NumVotes") or 0))[:30]
    out([{"pkg": r["Name"], "version": r.get("Version", ""), "desc": r.get("Description") or "", "installed": r["Name"] in inst, "votes": r.get("NumVotes", 0)} for r in rs])


def cmd_flatpak(q):
    q = clean(q)
    if not shutil.which("flatpak") or not q:
        return out([])
    have = flatpak_list()
    res = []
    for l in run(["flatpak", "search", "--columns=application,name,description,version", "--", q], 25).split("\n"):
        p = l.split("\t")
        if len(p) >= 3 and "." in p[0]:
            res.append({"pkg": p[0], "name": p[1], "desc": p[2], "version": p[3] if len(p) > 3 else "", "installed": p[0] in have})
    out(res[:30])


def cmd_autostart(base=None):
    res = []
    mine = base or os.environ.get("QS_APPS_AUTOSTART_DIR") or HOME + "/.config/autostart"
    for dd, system in ((mine, False), ("/etc/xdg/autostart", True)):
        for p in sorted(glob.glob(dd + "/*.desktop")):
            f = os.path.basename(p)
            if system and os.path.exists(mine + "/" + f):
                continue   # o do usuario tem a mesma vez e ja aparece
            d = desktop(p)
            hidden = d.get("Hidden", "").lower() == "true" or d.get("X-GNOME-Autostart-enabled", "").lower() == "false"
            res.append({"file": f, "name": d.get("Name_pt") or d.get("Name") or f[:-8], "comment": d.get("Comment", ""), "exec": d.get("Exec", ""), "icon": d.get("Icon", ""), "enabled": not hidden, "system": system, "path": p})
    out(res)


def cmd_autostart_set(f, state, base=None):
    base = base or os.environ.get("QS_APPS_AUTOSTART_DIR") or HOME + "/.config/autostart"
    if "/" in f or not f.endswith(".desktop"):
        return out({"ok": False, "err": "arquivo invalido"})
    p = base + "/" + f
    if not os.path.exists(p):
        return out({"ok": False, "err": "arquivo nao e do usuario"})
    bak = p + ".bak"
    if not os.path.exists(bak):
        shutil.copy2(p, bak)
    lines = open(p, errors="ignore").read().split("\n")
    # remove Hidden e X-GNOME-Autostart-enabled antigos so na secao principal
    keep, sec = [], ""
    for l in lines:
        if l.startswith("["):
            sec = l
        if sec == "[Desktop Entry]" and re.match(r"(Hidden|X-GNOME-Autostart-enabled)=", l):
            continue
        keep.append(l)
    if state == "off":
        i = next((n for n, l in enumerate(keep) if l.strip() == "[Desktop Entry]"), 0)
        keep.insert(i + 1, "Hidden=true")
    open(p, "w").write("\n".join(keep))
    out({"ok": True})


if __name__ == "__main__":
    a = sys.argv[1:]
    c = a[0] if a else ""
    try:
        if c == "list": cmd_list()
        elif c == "search-repo": cmd_repo(" ".join(a[1:]))
        elif c == "search-aur": cmd_aur(" ".join(a[1:]))
        elif c == "search-flatpak": cmd_flatpak(" ".join(a[1:]))
        elif c == "autostart": cmd_autostart(a[1] if len(a) > 1 else None)
        elif c == "autostart-set": cmd_autostart_set(a[1], a[2], a[3] if len(a) > 3 else None)
        else: out({"err": "uso: apps.py list|search-repo|search-aur|search-flatpak|autostart"})
    except Exception as e:
        out({"err": str(e)})
