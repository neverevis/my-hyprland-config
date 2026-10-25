#!/usr/bin/env python3
# Gera docs/ATALHOS.md e a tabela de atalhos do README.md a partir da tabela `keys` de hypr/quickshell.lua.
# Uso (na raiz do repositorio):  python3 scripts/gen-keys-doc.py
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mine_install import parse_keys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NAMES = {"SUPER": "Super", "CTRL": "Ctrl", "SHIFT": "Shift", "ALT": "Alt", "grave": "`", "period": ".", "tab": "Tab", "space": "Espaço",
         "equal": "=", "minus": "-", "delete": "Delete", "backspace": "Backspace", "super_l": "Super"}

def fmt_combo(c):
    toks = [t for t in c.replace("+", " ").split() if t]
    out = []
    for t in toks:
        out.append(NAMES.get(t, NAMES.get(t.lower(), t if t.startswith(("XF86", "Print")) else t.upper() if len(t) == 1 else t)))
    s = " + ".join(out)
    return "Super (tocar e soltar)" if c == "SUPER + SUPER_L" else "Segurar Super" if c == "SUPER_L" else s

def fmt_key(e):
    k = e["key"] if isinstance(e["key"], list) else [e["key"]]
    return " ou ".join(("`` " + fmt_combo(c) + " ``") if "`" in fmt_combo(c) else f"`{fmt_combo(c)}`" for c in k)

def rows(entries):
    out = []
    for e in entries:
        extra = []
        if e.get("off"): extra.append("desligado por padrão")
        if e.get("locked"): extra.append("funciona com a tela bloqueada")
        out.append(f'| {fmt_key(e)} | {e["desc"]}{" (" + ", ".join(extra) + ")" if extra else ""} | `{e["id"]}` |')
    return out

def main():
    entries = parse_keys(os.path.join(ROOT, "hypr", "quickshell.lua"))
    head = "| Atalho | Ação | id |\n| --- | --- | --- |"
    groups = []
    for e in entries:
        g = e.get("grp", "Outros")
        if g not in [x[0] for x in groups]: groups.append((g, []))
        dict(groups)[g].append(e)
    md = ["# Atalhos de teclado", "",
          "> Gerado por `scripts/gen-keys-doc.py` a partir da tabela em `hypr/quickshell.lua`. Não edite à mão.", "",
          "O `install.sh` cria estes atalhos no seu Hyprland. Se uma combinação já era sua, ele pergunta se o shell substitui ou se o seu fica",
          "(`./install.sh --keys` refaz a escolha). Para trocar uma tecla ou desligar um atalho, edite `~/.config/hypr/quickshell-keys.lua`:", "",
          "```lua", "return {",
          '  conflicts = { settings = "replace", looks = "keep" },   -- replace: o do shell vence; keep: o seu vence',
          '  override  = { settings = "SUPER + ALT + C",              -- outra combinação (texto ou lista)',
          '                overview = false },                         -- false desliga',
          "}", "```", "",
          "A coluna **id** é o nome usado nesse arquivo. Os atalhos com Super usam a tecla Windows.", ""]
    for g, es in groups:
        md += [f"## {g}", "", head] + rows(es) + [""]
    open(os.path.join(ROOT, "docs", "ATALHOS.md"), "w", encoding="utf-8").write("\n".join(md))
    rp = os.path.join(ROOT, "README.md")
    t = open(rp, encoding="utf-8").read()
    a, b = "<!-- ATALHOS:INICIO -->", "<!-- ATALHOS:FIM -->"
    if a in t and b in t:
        table = "\n".join(["| Atalho | Ação |", "| --- | --- |"] + [r.rsplit(" | `", 1)[0] + " |" for r in rows(entries)])
        t = t[:t.index(a) + len(a)] + "\n" + table + "\n" + t[t.index(b):]
        open(rp, "w", encoding="utf-8").write(t)
    print("docs/ATALHOS.md atualizado" + (" e tabela do README" if a in t else " (README sem marcadores)"))

if __name__ == "__main__": main()
