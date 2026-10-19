#!/usr/bin/env python3
# Valores atuais de opcoes do Hyprland (para a pagina Hyprland mostrar o que esta valendo):
#   hyprget.py general:gaps_in decoration:rounding ...  -> {"general:gaps_in": 2, ...}
# gaps ("css": "2 2 2 2") viram um numero quando os quatro lados sao iguais. Tambem devolve "_monitors" (hyprctl monitors).
import json, subprocess, sys

def get(opt):
    try:
        d = json.loads(subprocess.run(["hyprctl", "getoption", opt, "-j"], capture_output=True, text=True, timeout=3).stdout)
    except Exception:
        return None
    for k in ("int", "float", "str", "custom", "bool"):
        if k in d:
            v = d[k]
            if k == "str" and v == "[[EMPTY]]":
                return ""
            return round(v, 3) if k == "float" else v
    if "css" in d:
        p = d["css"].split()
        return int(p[0]) if len(set(p)) == 1 else d["css"]
    return None

out = {o: get(o) for o in sys.argv[1:]}
try:
    out["_monitors"] = [{"name": m["name"], "mode": f'{m["width"]}x{m["height"]}@{m["refreshRate"]:.2f}Hz', "scale": m["scale"],
                         "modes": m.get("availableModes", []), "x": m["x"], "y": m["y"], "transform": m.get("transform", 0)}
                        for m in json.loads(subprocess.run(["hyprctl", "monitors", "-j"], capture_output=True, text=True, timeout=3).stdout)]
except Exception:
    out["_monitors"] = []
print(json.dumps(out))
