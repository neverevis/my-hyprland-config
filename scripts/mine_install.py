#!/usr/bin/env python3
# Ajudante do install.sh (e do gen-keys-doc.py): le a tabela de atalhos de hypr/quickshell.lua, detecta conflitos com
# os atalhos que o Hyprland ja tem, grava ~/.config/hypr/quickshell-keys.lua, acha/desliga programas que brigam com o
# shell e desfaz tudo no --uninstall. So usa a biblioteca padrao. Subcomandos: veja main().
import argparse, json, os, re, subprocess, sys

MARK = "[mine-disabled]"          # prefixo dos autostarts comentados (o --uninstall tira)
ORIG = ".mine-orig"               # copia do arquivo original (feita uma vez, antes da primeira edicao)

# ---------------------------------------------------------------- tabela de atalhos
STR = r'"(?:[^"\\]|\\.)*"'
def parse_keys(lua_path):
    """Le as linhas { id = "...", key = ..., ... } da tabela `keys` de hypr/quickshell.lua."""
    out = []
    for ln in open(lua_path, encoding="utf-8"):
        s = ln.strip()
        if not s.startswith("{ id ="): continue
        e = {}
        for m in re.finditer(r'(\w+)\s*=\s*(' + STR + r'|true|false|\{[^}]*\})', s):
            k, v = m.group(1), m.group(2)
            if v in ("true", "false"): e[k] = v == "true"
            elif v.startswith("{"): e[k] = [json.loads(x) for x in re.findall(STR, v)]
            else: e[k] = json.loads(v)
        if "id" in e and "key" in e and "cmd" in e: out.append(e)
    return out

def combos(e):
    k = e["key"]
    return k if isinstance(k, list) else [k]

# ---------------------------------------------------------------- combinacoes
MODS = {"SUPER": 64, "WIN": 64, "MOD4": 64, "LOGO": 64, "META": 64, "SHIFT": 1, "CTRL": 4, "CONTROL": 4, "ALT": 8, "MOD1": 8}
def norm(combo):
    toks = [t for t in re.split(r'\s*\+\s*|\s+', combo.strip()) if t]
    if not toks: return (0, "")
    mask = 0
    for t in toks[:-1]: mask |= MODS.get(t.upper(), 0)
    return (mask, toks[-1].lower())

def mods_name(mask):
    return " + ".join(n for n, b in (("CTRL", 4), ("SHIFT", 1), ("ALT", 8), ("SUPER", 64)) if mask & b)

# ---------------------------------------------------------------- arquivos da config do Hyprland
SKIP_FILES = {"quickshell.lua", "quickshell-keys.lua", "quickshell-blur.lua"}
def conf_files(hypr):
    for root, _, files in os.walk(hypr, followlinks=True):
        for f in sorted(files):
            if f.endswith((".lua", ".conf")) and f not in SKIP_FILES:
                yield os.path.join(root, f)

def find_sources(hypr):
    """combinacao normalizada -> ["arquivo:linha", ...] dos hl.bind / bind = achados nos arquivos."""
    src = {}
    for p in conf_files(hypr):
        try: lines = open(p, encoding="utf-8", errors="replace").read().splitlines()
        except OSError: continue
        vs = {}   # variaveis de texto (local mainMod = "SUPER"), usadas como  mainMod .. " + Q"
        for i, ln in enumerate(lines, 1):
            s = ln.strip()
            if s.startswith(("--", "#")): continue
            mv = re.match(r'local\s+(\w+)\s*=\s*"([^"]*)"', s)
            if mv: vs[mv.group(1)] = mv.group(2)
            m = re.search(r'\bhl\.bind\(\s*(?:(\w+)\s*\.\.\s*)?"([^"]+)"', s)
            if m and (not m.group(1) or m.group(1) in vs): src.setdefault(norm(vs.get(m.group(1), "") + m.group(2)), []).append(f"{os.path.relpath(p, hypr)}:{i}")
            m = re.match(r'bind[a-z]*\s*=\s*([^,]*),\s*([^,]+),', s)
            if m:
                mask = 0
                for t in re.split(r'[\s_+]+', m.group(1)): mask |= MODS.get(t.upper(), 0)
                src.setdefault((mask, m.group(2).strip().lower()), []).append(f"{os.path.relpath(p, hypr)}:{i}")
    return src

# ---------------------------------------------------------------- arquivo de escolhas
def read_keys_file(path):
    conflicts, override_block = {}, None
    if os.path.isfile(path):
        t = open(path, encoding="utf-8").read()
        m = re.search(r'conflicts\s*=\s*\{(.*?)\}', t, re.S)
        if m: conflicts = dict(re.findall(r'(\w+)\s*=\s*"(replace|keep)"', m.group(1)))
        m = re.search(r'^  override\s*=\s*\{.*?^  \},?[ \t]*$', t, re.S | re.M)
        if m: override_block = m.group(0)
    return conflicts, override_block

def write_keys_file(path, conflicts, override_block, dry=False):
    ov = override_block or ('  override = {\n    -- settings = "SUPER + ALT + C",   -- outra combinacao (string ou lista), ou false para desligar\n  },')
    if not ov.rstrip().endswith(","): ov = ov.rstrip() + ","
    body = "".join(f'    {k} = "{v}",\n' for k, v in sorted(conflicts.items()))
    text = ('-- Escolhas dos atalhos do Quickshell "mine" (lido por quickshell.lua). Pode editar a mao; o install.sh e o editor das\n'
            '-- configuracoes tambem escrevem aqui. Formato e significado: veja o comentario no inicio de quickshell.lua.\n'
            'return {\n'
            '  -- conflitos com atalhos que voce ja tinha: "replace" = o do shell vence, "keep" = o seu vence\n'
            f'  conflicts = {{\n{body}  }},\n'
            f'{ov}\n'
            '}\n')
    if dry: print(f"[dry-run] gravaria {path}"); return
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, "w", encoding="utf-8").write(text)

# ---------------------------------------------------------------- subcomandos: atalhos
def cmd_keys_json(a):
    print(json.dumps(parse_keys(a.lua), ensure_ascii=False))

def cmd_keys_conflicts(a):
    """Atalhos do shell que caem numa combinacao ja usada por outro atalho do Hyprland (hyprctl binds -j)."""
    entries = parse_keys(a.lua)
    decided, _ = read_keys_file(a.keys)
    binds = json.load(open(a.binds, encoding="utf-8")) if a.binds and os.path.isfile(a.binds) and os.path.getsize(a.binds) else []
    src = find_sources(a.hypr) if a.hypr and os.path.isdir(a.hypr) else {}
    have, static = {}, {}
    if a.static or not binds:    # sem o Hyprland rodando (ou a pedido): procura os atalhos escritos nos arquivos da config
        for n, where in src.items(): static[n] = [f"definido em {w}" for w in where]
    for b in binds:
        if b.get("submap") or b.get("mouse") or str(b.get("description", "")).startswith("[mine]"): continue
        k = (int(b.get("modmask", 0)) & 77, str(b.get("key", "")).lower(), bool(b.get("release")))
        have.setdefault(k, []).append(b)
    res = []
    for e in entries:
        if e.get("off") or (e["id"] in decided and not a.ignore_decided): continue
        for c in combos(e):
            n = norm(c)
            hit = have.get((n[0], n[1], bool(e.get("release"))))
            if not hit and n not in static: continue
            what = list(static.get(n, [])) if not hit else []
            for b in hit or []:
                d = b.get("description") or ""
                if b.get("dispatcher") == "__lua": d = d or "atalho definido em Lua"
                else: d = d or f'{b.get("dispatcher")} {b.get("arg", "")}'.strip()
                what.append(d)
            res.append({"id": e["id"], "combo": c, "desc": e["desc"], "existing": what, "where": src.get(n, []) if hit else []})
    if a.tsv:
        for r in res: print("\t".join([r["id"], r["combo"], r["desc"], " | ".join(r["existing"]), ", ".join(r["where"])]))
    else: print(json.dumps(res, ensure_ascii=False))

def cmd_keys_write(a):
    conflicts, ov = read_keys_file(a.keys)
    for s in a.set or []:
        k, v = s.split("=", 1); conflicts[k] = v
    write_keys_file(a.keys, conflicts, ov, a.dry)

# ---------------------------------------------------------------- programas que brigam com o shell
PROGS = {   # nome -> o que o shell oferece no lugar
    "waybar": "barras", "eww": "barras", "ags": "barras", "hyprpanel": "barras", "nwg-dock-hyprland": "dock", "nwg-panel": "barras",
    "mako": "notificacoes", "dunst": "notificacoes", "swaync": "notificacoes", "fnott": "notificacoes",
    "hyprpaper": "wallpaper", "swww-daemon": "wallpaper", "swww": "wallpaper", "swaybg": "wallpaper", "wpaperd": "wallpaper",
    "hyprlock": "tela de bloqueio", "hypridle": "inatividade",
}
def idle_in_use(settings):
    try: j = json.load(open(settings, encoding="utf-8"))
    except (OSError, ValueError): return False
    return any(float(j.get(k, 0) or 0) > 0 for k in ("idleLock", "idleScreenOff", "idleSuspend"))

def prog_re(n): return re.compile(r'(?<![\w-])' + re.escape(n) + r'(?![\w-])')
def exec_line(path, s):
    if path.endswith(".lua"): return not s.startswith("--") and re.search(r'\bexec(_cmd|_once)?\b|hl\.exec', s) is not None
    return re.match(r'exec(-once)?\s*=', s) is not None

def running(n):
    try: return subprocess.run(["pgrep", "-x", n], capture_output=True).returncode == 0
    except OSError: return False

def cmd_progs_scan(a):
    names = [n for n in PROGS if n != "hypridle" or idle_in_use(a.settings)]
    found = {n: {"name": n, "kind": PROGS[n], "running": running(n), "lines": []} for n in names}
    for p in conf_files(a.hypr) if a.hypr and os.path.isdir(a.hypr) else []:
        try: lines = open(p, encoding="utf-8", errors="replace").read().splitlines()
        except OSError: continue
        for i, ln in enumerate(lines, 1):
            s = ln.strip()
            if not s or MARK in s or not exec_line(p, s): continue
            for n in names:
                if prog_re(n).search(s):
                    # swww-daemon e swww: so conta o mais especifico
                    if n == "swww" and prog_re("swww-daemon").search(s): continue
                    found[n]["lines"].append({"file": p, "line": i, "text": s})
    out = [v for v in found.values() if v["running"] or v["lines"]]
    print(json.dumps(out, ensure_ascii=False))

def backup_once(path):
    if not os.path.exists(path + ORIG):
        open(path + ORIG, "wb").write(open(path, "rb").read())

def lua_ok(path):
    for exe in ("luac", "luac5.4", "luac5.1", "luajit"):
        try:
            args = [exe, "-bl", path, "/dev/null"] if exe == "luajit" else [exe, "-p", path]
            return subprocess.run(args, capture_output=True).returncode == 0
        except OSError: continue
    return True   # sem luac: nao da para checar

def cmd_progs_disable(a):
    names = set(a.names.split(","))
    for p in conf_files(a.hypr):
        try: txt = open(p, encoding="utf-8").read()
        except OSError: continue
        lines = txt.split("\n"); changed = []
        for i, ln in enumerate(lines):
            s = ln.strip()
            if not s or MARK in s or not exec_line(p, s): continue
            if not any(prog_re(n).search(s) for n in names): continue
            lua = p.endswith(".lua")
            # em Lua so comenta linhas que sao uma chamada inteira (senao quebraria o bloco: "function() ... end")
            if lua and not re.match(r'^(hl\.exec(_cmd|_once)?)\((.*)\)\s*(--.*)?$', s):
                print(f"MANUAL {p}:{i+1}: {s}"); continue
            ind = ln[:len(ln) - len(ln.lstrip())]
            lines[i] = f'{ind}{"--" if lua else "#"} {MARK} {s}'
            changed.append(i + 1)
        if not changed: continue
        if a.dry:
            for n in changed: print(f"[dry-run] comentaria {p}:{n}")
            continue
        backup_once(p)
        open(p, "w", encoding="utf-8").write("\n".join(lines))
        if p.endswith(".lua") and not lua_ok(p):
            os.replace(p + ORIG, p); print(f"REVERTIDO {p} (a edicao quebrava o Lua)"); continue
        for n in changed: print(f"OK {p}:{n}")

# ---------------------------------------------------------------- desfazer
def cmd_restore_marks(a):
    pat = re.compile(r'^(\s*)(--|#) ' + re.escape(MARK) + ' ')
    for p in conf_files(a.hypr):
        try: txt = open(p, encoding="utf-8").read()
        except OSError: continue
        if MARK not in txt: continue
        new = "\n".join(pat.sub(r'\1', ln) for ln in txt.split("\n"))
        if a.dry: print(f"[dry-run] restauraria {p}"); continue
        open(p, "w", encoding="utf-8").write(new)
        if os.path.exists(p + ORIG): os.remove(p + ORIG)
        print(f"OK {p}")

def cmd_remove_block(a):
    """Tira a linha que casa com --payload, o comentario logo acima (--comment) e a linha em branco antes dele."""
    if not os.path.isfile(a.file): return
    lines = open(a.file, encoding="utf-8").read().split("\n")
    pay, com = re.compile(a.payload), re.compile(a.comment)
    out, n = [], 0
    for ln in lines:
        if pay.search(ln):
            n += 1
            if out and com.search(out[-1]):
                out.pop()
                if out and out[-1].strip() == "": out.pop()   # a linha em branco que o install.sh pos antes do comentario
            continue
        out.append(ln)
    if n:
        if a.dry: print(f"[dry-run] tiraria {n} linha(s) de {a.file}")
        else:
            open(a.file, "w", encoding="utf-8").write("\n".join(out)); print(f"OK {a.file}")

# ---------------------------------------------------------------- config nova (sistema zerado)
STARTER = """-- hyprland.lua inicial criado pelo instalador do Quickshell "mine" (nao achei o exemplo do Hyprland em /usr/share/hypr).
local terminal = "kitty"
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
hl.config({ input = { kb_layout = "us", kb_variant = "", follow_mouse = 1 } })
local mainMod = "SUPER"
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
"""

def lua_str(v): return '"' + v.replace("\\", "\\\\").replace('"', '\\"') + '"'

def cmd_fresh_lua(a):
    """Cria o hyprland.lua a partir do exemplo oficial do Hyprland (ou do inicial embutido): teclado do sistema e terminal do shell."""
    txt = open(a.example, encoding="utf-8").read() if a.example and os.path.isfile(a.example) else STARTER
    out = []
    if a.layout:
        txt, n1 = re.subn(r'(kb_layout\s*=\s*)"[^"]*"', lambda m: m.group(1) + lua_str(a.layout), txt, count=1)
        txt, n2 = re.subn(r'(kb_variant\s*=\s*)"[^"]*"', lambda m: m.group(1) + lua_str(a.variant or ""), txt, count=1)
        out.append(f"teclado: layout={a.layout}" + (f" variante={a.variant}" if a.variant else "") + ("" if n1 else " (nao achei kb_layout no exemplo)"))
    if a.terminal:
        txt, n = re.subn(r'^(\s*local\s+terminal\s*=\s*)"[^"]*"', lambda m: m.group(1) + lua_str(a.terminal), txt, count=1, flags=re.M)
        out.append("terminal: " + a.terminal if n else "terminal: o exemplo nao declara `local terminal` (so o atalho Super+Return do shell abre o terminal padrao)")
    if a.dry: print("\n".join(out)); return
    os.makedirs(os.path.dirname(a.dst), exist_ok=True)
    open(a.dst, "w", encoding="utf-8").write(txt)
    print("\n".join(out))

def main():
    ap = argparse.ArgumentParser(); sp = ap.add_subparsers(dest="c", required=True)
    def add(name, fn, *args):
        p = sp.add_parser(name); p.set_defaults(fn=fn); p.add_argument("--dry", action="store_true")
        for x in args: p.add_argument(x[0], **x[1])
        return p
    add("keys-json", cmd_keys_json, ("--lua", {"required": True}))
    add("keys-conflicts", cmd_keys_conflicts, ("--lua", {"required": True}), ("--binds", {"required": True}), ("--keys", {"required": True}), ("--hypr", {"default": ""}), ("--static", {"action": "store_true"}), ("--tsv", {"action": "store_true"}), ("--ignore-decided", {"action": "store_true"}))
    add("keys-write", cmd_keys_write, ("--keys", {"required": True}), ("--set", {"action": "append"}))
    add("progs-scan", cmd_progs_scan, ("--hypr", {"default": ""}), ("--settings", {"default": ""}))
    add("progs-disable", cmd_progs_disable, ("--hypr", {"required": True}), ("--names", {"required": True}))
    add("restore-marks", cmd_restore_marks, ("--hypr", {"required": True}))
    add("remove-block", cmd_remove_block, ("--file", {"required": True}), ("--payload", {"required": True}), ("--comment", {"required": True}))
    add("fresh-lua", cmd_fresh_lua, ("--dst", {"required": True}), ("--example", {"default": ""}), ("--layout", {"default": ""}), ("--variant", {"default": ""}), ("--terminal", {"default": ""}))
    a = ap.parse_args(); a.fn(a)

if __name__ == "__main__": main()
