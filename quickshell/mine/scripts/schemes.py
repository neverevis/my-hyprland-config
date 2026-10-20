#!/usr/bin/env python3
# Esquemas de cores do usuario (pasta schemes/ do shell). Uso:
#   schemes.py <pasta>                 -> lista JSON dos esquemas validos, ja completos (para o Presets.qml)
#   schemes.py <pasta> --import <arq>  -> valida o arquivo e copia para a pasta (imprime ok ou o erro)
# Formato minimo: {"name": "...", "dark": true, "bg": "#rrggbb", "text": "#rrggbb", "primary": "#...", "secondary": "#...", "tertiary": "#...", "error": "#..."}
# Opcionais (senao sao derivados): lowest low s1 s2 muted outline term (16 cores).
import json, os, re, shutil, sys

HEX = re.compile(r"^#[0-9a-fA-F]{6}$")
REQ = ["bg", "text", "primary", "secondary", "tertiary", "error"]

def rgb(h): return [int(h[i:i + 2], 16) for i in (1, 3, 5)]
def mix(a, b, t):
    pa, pb = rgb(a), rgb(b)
    return "#" + "".join("%02x" % round(pa[i] + (pb[i] - pa[i]) * t) for i in range(3))

def complete(d):
    if not isinstance(d, dict): raise ValueError("o arquivo precisa ser um objeto JSON")
    for k in REQ:
        if not isinstance(d.get(k), str) or not HEX.match(d[k]): raise ValueError("campo '%s' ausente ou nao e #rrggbb" % k)
    dark = d.get("dark", True) is not False
    bg, tx = d["bg"], d["text"]
    out = {"name": str(d.get("name") or "Esquema"), "dark": dark}
    out.update({k: d[k] for k in REQ})
    far = "#000000" if dark else "#ffffff"
    near = "#ffffff" if dark else "#000000"
    der = {"lowest": mix(bg, far, 0.35), "low": mix(bg, far, 0.15), "s1": mix(bg, near, 0.08), "s2": mix(bg, near, 0.16),
           "muted": mix(tx, bg, 0.3), "outline": mix(tx, bg, 0.6)}
    for k, v in der.items():
        out[k] = d[k] if isinstance(d.get(k), str) and HEX.match(d[k]) else v
    t = d.get("term")
    if not (isinstance(t, list) and len(t) == 16 and all(isinstance(x, str) and HEX.match(x) for x in t)):
        t = [out["s1"], d["error"], mix(d["primary"], "#00ff00", 0.5), mix(d["tertiary"], "#ffff00", 0.5), d["secondary"], d["tertiary"], d["primary"], tx,
             out["s2"], d["error"], mix(d["primary"], "#00ff00", 0.5), mix(d["tertiary"], "#ffff00", 0.5), d["secondary"], d["tertiary"], d["primary"], tx]
    out["term"] = t
    return out

def main():
    folder = sys.argv[1]
    if len(sys.argv) > 3 and sys.argv[2] == "--import":
        try:
            d = json.load(open(os.path.expanduser(sys.argv[3])))
            complete(d)
        except Exception as e:
            print("erro: %s" % e); return
        os.makedirs(folder, exist_ok=True)
        shutil.copyfile(os.path.expanduser(sys.argv[3]), os.path.join(folder, os.path.basename(sys.argv[3])))
        print("ok"); return
    res = []
    if os.path.isdir(folder):
        for f in sorted(os.listdir(folder)):
            if not f.endswith(".json"): continue
            try:
                s = complete(json.load(open(os.path.join(folder, f))))
                s["id"] = "u-" + f[:-5]
                res.append(s)
            except Exception:
                pass
    print(json.dumps(res))
main()
