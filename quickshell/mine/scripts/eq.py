#!/usr/bin/env python3
# Equalizador de 10 bandas pelo EasyEffects: grava o preset "mine-eq" (so o plugin equalizer) e carrega com easyeffects -l.
#   eq.py state                      -> JSON {gains, pre, custom, active}
#   eq.py apply g0 ... g9 pre        -> grava o estado e o preset e carrega
#   eq.py save NOME | delete NOME    -> curvas proprias (guardam os ganhos atuais)
#   eq.py restore PRESET             -> volta a um preset do EasyEffects ("" = so descarrega o mine-eq)
import json, os, subprocess, sys

HOME = os.path.expanduser("~")
ST = os.path.join(HOME, ".local/state/quickshell-mine/eq.json")
PRE_DIR = os.path.join(HOME, ".local/share/easyeffects/output")
NAME = "mine-eq"
FREQ = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]

def load():
    try:
        d = json.load(open(ST))
    except Exception:
        d = {}
    d.setdefault("gains", [0.0] * 10)
    d.setdefault("pre", 0.0)
    d.setdefault("custom", {})
    d.setdefault("active", False)
    return d

def save(d):
    os.makedirs(os.path.dirname(ST), exist_ok=True)
    json.dump(d, open(ST, "w"))

def band(i, g):
    return {"frequency": float(FREQ[i]), "gain": float(g), "mode": "RLC (BT)", "mute": False, "q": 1.41, "slope": "x1", "solo": False, "type": "Bell", "width": 4.0}

def write_preset(d):
    ch = {"band%d" % i: band(i, g) for i, g in enumerate(d["gains"])}
    eq = {"balance": 0.0, "bypass": False, "input-gain": float(d["pre"]), "mode": "IIR", "num-bands": 10,
          "output-gain": 0.0, "pitch-left": 0.0, "pitch-right": 0.0, "split-channels": False,
          "left": ch, "right": ch}
    os.makedirs(PRE_DIR, exist_ok=True)
    json.dump({"output": {"blocklist": [], "equalizer#0": eq, "plugins_order": ["equalizer#0"]}}, open(os.path.join(PRE_DIR, NAME + ".json"), "w"), indent=2)

def ee(*a):
    subprocess.run(["easyeffects", *a], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=8)

def main():
    a = sys.argv[1:]
    if not a or a[0] == "state":
        print(json.dumps(load())); return
    d = load()
    if a[0] == "apply":
        v = [max(-12.0, min(12.0, float(x))) for x in a[1:11]]
        d["gains"] = v + [0.0] * (10 - len(v))
        d["pre"] = max(-12.0, min(12.0, float(a[11]))) if len(a) > 11 else 0.0
        d["active"] = True
        save(d); write_preset(d); ee("-l", NAME)
    elif a[0] == "save" and len(a) > 1:
        d["custom"][a[1]] = list(d["gains"]); save(d)
    elif a[0] == "delete" and len(a) > 1:
        d["custom"].pop(a[1], None); save(d)
    elif a[0] == "restore":
        d["active"] = False; save(d)
        if len(a) > 1 and a[1]:
            ee("-l", a[1])
        else:
            try:
                os.remove(os.path.join(PRE_DIR, NAME + ".json"))
            except OSError:
                pass
    print(json.dumps(load()))

main()
