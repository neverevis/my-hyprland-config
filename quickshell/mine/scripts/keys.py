#!/usr/bin/env python3
# Ajudante da pagina "Atalhos de teclado" (configuracoes). So biblioteca padrao.
#   keys.py state [--keys ARQ]            JSON: atalhos do shell (tabela de quickshell.lua), escolhas do usuario, binds do Hyprland
#   keys.py write JSON [--keys ARQ]       grava as escolhas (JSON {"conflicts":{},"override":{}}) de forma atomica, com .bak unico e luac -p
# Mesmas regras de combinacao do mine_install.py do repositorio (SUPER=64, SHIFT=1, CTRL=4, ALT=8).
import json, os, re, subprocess, sys, tempfile

HYPR = os.path.expanduser("~/.config/hypr")
LUA = os.path.join(HYPR, "quickshell.lua")
REAL_KEYS = os.path.join(HYPR, "quickshell-keys.lua")
HERE = os.path.dirname(os.path.abspath(__file__))
STR = r'"(?:[^"\\]|\\.)*"'
MODS = {"SUPER": 64, "WIN": 64, "MOD4": 64, "LOGO": 64, "META": 64, "SHIFT": 1, "CTRL": 4, "CONTROL": 4, "ALT": 8, "MOD1": 8}

def parse_keys(path):
    out = []
    try: lines = open(path, encoding="utf-8").read().splitlines()
    except OSError: return out
    for ln in lines:
        s = ln.strip()
        if not s.startswith("{ id ="): continue
        e = {}
        for m in re.finditer(r'(\w+)\s*=\s*(' + STR + r'|true|false|\{[^}]*\})', s):
            k, v = m.group(1), m.group(2)
            if v in ("true", "false"): e[k] = v == "true"
            elif v.startswith("{"): e[k] = [json.loads(x) for x in re.findall(STR, v)]
            else: e[k] = json.loads(v)
        if "id" in e and "key" in e and "cmd" in e:
            if not isinstance(e["key"], list): e["key"] = [e["key"]]
            out.append(e)
    return out

def norm(combo):
    toks = [t for t in re.split(r'\s*\+\s*|\s+', combo.strip()) if t]
    if not toks: return (0, "")
    mask = 0
    for t in toks[:-1]: mask |= MODS.get(t.upper(), 0)
    return (mask, toks[-1].lower())

def read_user(path):
    conflicts, override = {}, {}
    try: t = open(path, encoding="utf-8").read()
    except OSError: return conflicts, override
    t = re.sub(r'--[^\n]*', '', t)
    m = re.search(r'conflicts\s*=\s*\{(.*?)\}', t, re.S)
    if m: conflicts = dict(re.findall(r'(\w+)\s*=\s*"(replace|keep)"', m.group(1)))
    m = re.search(r'override\s*=\s*\{', t)
    if m:
        i, d = m.end(), 1
        while i < len(t) and d:
            d += {"{": 1, "}": -1}.get(t[i], 0); i += 1
        body = t[m.end():i - 1]
        for mm in re.finditer(r'(\w+)\s*=\s*(false|' + STR + r'|\{[^}]*\})', body):
            k, v = mm.group(1), mm.group(2)
            override[k] = False if v == "false" else (json.loads(v) if v.startswith('"') else [json.loads(x) for x in re.findall(STR, v)])
    return conflicts, override

def lq(s): return json.dumps(s, ensure_ascii=False)

def render(path, conflicts, override):
    head = []
    try:
        for ln in open(path, encoding="utf-8").read().splitlines():
            if ln.startswith("--"): head.append(ln)
            else: break
    except OSError: pass
    if not head:
        head = ['-- Escolhas dos atalhos do Quickshell "mine" (lido por quickshell.lua). Pode editar a mao; o install.sh e o editor das',
                '-- configuracoes tambem escrevem aqui. Formato e significado: veja o comentario no inicio de quickshell.lua.']
    c = "".join(f'        {k} = "{v}",\n' for k, v in sorted(conflicts.items()))
    def val(v): return "false" if v is False else (lq(v) if isinstance(v, str) else "{ " + ", ".join(lq(x) for x in v) + " }")
    o = "".join(f'        {k} = {val(v)},\n' for k, v in sorted(override.items()))
    return "\n".join(head) + "\nreturn {\n    conflicts = {\n" + c.replace("        ", "        ") + "    },\n    override = {\n" + o + "    },\n}\n"

def lua_ok(path):
    for exe in ("luac", "luac5.4", "luajit"):
        try:
            args = [exe, "-bl", path, "/dev/null"] if exe == "luajit" else [exe, "-p", path]
            r = subprocess.run(args, capture_output=True, text=True)
            return r.returncode == 0, r.stderr.strip()
        except OSError: continue
    return True, ""

def cmd_write(a):
    d = json.loads(a.json)
    conflicts = {k: v for k, v in (d.get("conflicts") or {}).items() if v in ("replace", "keep") and re.fullmatch(r'\w+', k)}
    override = {}
    for k, v in (d.get("override") or {}).items():
        if not re.fullmatch(r'\w+', k): continue
        if v is False or isinstance(v, str): override[k] = v
        elif isinstance(v, list): override[k] = [str(x) for x in v]
    text = render(a.keys, conflicts, override)
    os.makedirs(os.path.dirname(a.keys), exist_ok=True)
    tmp = tempfile.NamedTemporaryFile("w", dir=os.path.dirname(a.keys), suffix=".tmp", delete=False, encoding="utf-8")
    tmp.write(text); tmp.close()
    ok, err = lua_ok(tmp.name)
    if not ok:
        os.unlink(tmp.name); print(json.dumps({"ok": False, "err": err or "luac recusou o arquivo"})); return
    if os.path.exists(a.keys) and not os.path.exists(a.keys + ".bak"):
        open(a.keys + ".bak", "wb").write(open(a.keys, "rb").read())
    os.replace(tmp.name, a.keys)
    print(json.dumps({"ok": True}))

def editor():
    try: t = open(os.path.join(HYPR, "variables.lua"), encoding="utf-8").read()
    except OSError: return ""
    m = re.search(r'^\s*editor\s*=\s*"([^"]*)"', t, re.M)
    return m.group(1) if m else ""

def labels():
    """combinacao normalizada -> nome, a partir do scripts/keybinds.py (expande 'Super + 1…0')."""
    out = {}
    try:
        items = json.loads(subprocess.run(["python3", os.path.join(HERE, "keybinds.py")], capture_output=True, text=True, timeout=8).stdout)
    except Exception: return out
    for it in items:
        ks = it.get("keys", "")
        if "…" in ks:
            m = re.match(r'(.*?)(\d)…(\d)$', ks)
            if not m: continue
            seq = "1234567890"
            for ch in seq[seq.index(m.group(2)):seq.index(m.group(3)) + 1]: out.setdefault(norm(m.group(1) + ch), it["label"])
        elif "(" not in ks: out.setdefault(norm(ks), it["label"])
    return out

def cmd_state(a):
    entries = parse_keys(LUA)
    conflicts, override = read_user(a.keys)
    try: raw = json.loads(subprocess.run(["hyprctl", "binds", "-j"], capture_output=True, text=True, timeout=5).stdout)
    except Exception: raw = []
    lab = labels()
    binds = []
    for b in raw:
        d = str(b.get("description", ""))
        binds.append({"mask": int(b.get("modmask", 0)) & 77, "key": str(b.get("key", "")), "release": bool(b.get("release")),
                      "mouse": bool(b.get("mouse")), "submap": b.get("submap", ""), "mine": d.startswith("[mine]"), "desc": d,
                      "disp": b.get("dispatcher", ""), "arg": str(b.get("arg", ""))[:60],
                      "label": lab.get(( int(b.get("modmask", 0)) & 77, str(b.get("key", "")).lower()), "")})
    print(json.dumps({"entries": entries, "conflicts": conflicts, "override": override, "binds": binds,
                      "hasSubmap": any(b["submap"] == "mine-rec" for b in binds), "editor": editor(), "keysPath": a.keys,
                      "userBinds": os.path.join(HYPR, "hyprland", "keybinds.lua")}, ensure_ascii=False))

def main():
    import argparse
    p = argparse.ArgumentParser(); sp = p.add_subparsers(dest="c", required=True)
    s = sp.add_parser("state"); s.add_argument("--keys", default=REAL_KEYS); s.set_defaults(f=cmd_state)
    w = sp.add_parser("write"); w.add_argument("json"); w.add_argument("--keys", default=REAL_KEYS); w.set_defaults(f=cmd_write)
    a = p.parse_args(); a.f(a)

if __name__ == "__main__": main()
