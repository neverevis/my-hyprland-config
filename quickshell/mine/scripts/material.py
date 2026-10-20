#!/usr/bin/env python3
"""Gera o tema (Material You) a partir de uma imagem, como o Caelestia faz:
quantiza o wallpaper (Celebi), escolhe a cor-fonte pela pontuacao do Material e monta um esquema dinamico.

uso: material.py <imagem> [dark|light] [variante] [#semente]
variantes: tonalspot (padrao) vibrant expressive fidelity content neutral monochrome rainbow fruitsalad wallpaper
  auto = decide pelo colorido da imagem (Hasler-Suesstrunk): abaixo de 40 usa neutral, senao tonalspot
  #semente = cor-fonte escolhida (conta-gotas): ignora a imagem e monta o esquema so dessa cor
  wallpaper = primaria da cor principal e secundaria/terciaria de outras cores que existem na imagem (sem girar o matiz)
saida extra: _wall = ate 8 cores marcantes da imagem (para os widgets escolherem)
saida: JSON { papel: "#rrggbb", ... } (papeis do Material + term0..term15). Resultado guardado em ~/.cache/quickshell-mine.
"""
import hashlib
import json
import sys
from pathlib import Path

from materialyoucolor.dynamiccolor.material_dynamic_colors import MaterialDynamicColors
from materialyoucolor.hct import Hct
from materialyoucolor.quantize import ImageQuantizeCelebi
from materialyoucolor.score.score import Score, ScoreOptions
from materialyoucolor.palettes.tonal_palette import TonalPalette
from materialyoucolor.scheme.scheme_content import SchemeContent
from materialyoucolor.scheme.scheme_expressive import SchemeExpressive
from materialyoucolor.scheme.scheme_fidelity import SchemeFidelity
from materialyoucolor.scheme.scheme_fruit_salad import SchemeFruitSalad
from materialyoucolor.scheme.scheme_monochrome import SchemeMonochrome
from materialyoucolor.scheme.scheme_neutral import SchemeNeutral
from materialyoucolor.scheme.scheme_rainbow import SchemeRainbow
from materialyoucolor.scheme.scheme_tonal_spot import SchemeTonalSpot
from materialyoucolor.scheme.scheme_vibrant import SchemeVibrant
from materialyoucolor.blend import Blend

SCHEMES = {
    "tonalspot": SchemeTonalSpot, "vibrant": SchemeVibrant, "expressive": SchemeExpressive,
    "fidelity": SchemeFidelity, "content": SchemeContent, "neutral": SchemeNeutral,
    "monochrome": SchemeMonochrome, "rainbow": SchemeRainbow, "fruitsalad": SchemeFruitSalad,
}

# paleta ANSI de base (escura/clara); cada cor e puxada para o matiz do wallpaper (harmonizacao do Material)
TERM_DARK = ["282828", "CC241D", "98971A", "D79921", "458588", "B16286", "689D6A", "A89984",
             "928374", "FB4934", "B8BB26", "FABD2F", "83A598", "D3869B", "8EC07C", "EBDBB2"]
TERM_LIGHT = ["FDF9F3", "FF6188", "A9DC76", "FC9867", "FFD866", "F47FD4", "78DCE8", "333034",
              "121212", "FF6188", "A9DC76", "FC9867", "FFD866", "F47FD4", "78DCE8", "333034"]


def to_hex(argb: int) -> str:
    return "#%06x" % (argb & 0xFFFFFF)


def hue_dist(a: float, b: float) -> float:
    d = abs(a - b) % 360
    return min(d, 360 - d)


def wallpaper_scheme(seed: int, ranked: list, dark: bool):
    # base "Conteudo" (fiel a cor principal) com a secundaria e a terciaria trocadas por cores da propria imagem;
    # se a imagem so tem uma cor, usa vizinhas proximas dela (+-25 graus), nunca a do lado oposto do circulo
    base = SchemeContent(Hct.from_int(seed), dark, 0.0)
    sh = Hct.from_int(seed)
    others = [Hct.from_int(c) for c in ranked[1:] if Hct.from_int(c).chroma >= 10]
    picks = []
    for h in others:
        if all(hue_dist(h.hue, x.hue) > 12 or abs(h.chroma - x.chroma) > 20 for x in [sh] + picks):
            picks.append(h)
    while len(picks) < 2:
        n = len(picks)
        picks.append(Hct.from_hct(sh.hue + (25 if n == 0 else -25), max(16, sh.chroma * 0.6), sh.tone))
    base.secondary_palette = TonalPalette.from_hue_and_chroma(picks[0].hue, max(16, min(picks[0].chroma, 48)))
    base.tertiary_palette = TonalPalette.from_hue_and_chroma(picks[1].hue, max(20, min(picks[1].chroma, 64)))
    return base


def wall_colors(data: dict) -> list:
    # cores marcantes de verdade (as pontuadas e as mais presentes), sem repetir quase iguais
    out = []
    for c in data.get("ranked", []) + data.get("loose", []):
        h = Hct.from_int(c)
        if h.chroma < 6 and h.tone > 20 and h.tone < 90:
            continue
        if any(hue_dist(h.hue, o.hue) < 10 and abs(h.tone - o.tone) < 12 and abs(h.chroma - o.chroma) < 15 for o in out):
            continue
        out.append(h)
        if len(out) >= 8:
            break
    return [to_hex(h.to_int()) for h in out]


def colorfulness(path: str) -> float:
    # metrica de Hasler-Suesstrunk numa miniatura (so PIL, sem numpy)
    from PIL import Image
    im = Image.open(path).convert("RGB")
    im.thumbnail((96, 96))
    px = list(im.get_flattened_data() if hasattr(im, "get_flattened_data") else im.getdata())
    n = max(1, len(px))
    rg = [r - g for r, g, b in px]
    yb = [0.5 * (r + g) - b for r, g, b in px]
    def stat(v):
        m = sum(v) / n
        return m, (sum((x - m) ** 2 for x in v) / n) ** 0.5
    m1, s1 = stat(rg)
    m2, s2 = stat(yb)
    return (s1 ** 2 + s2 ** 2) ** 0.5 + 0.3 * (m1 ** 2 + m2 ** 2) ** 0.5


def main() -> None:
    image = sys.argv[1]
    mode = sys.argv[2] if len(sys.argv) > 2 else "dark"
    variant = sys.argv[3] if len(sys.argv) > 3 else "tonalspot"
    seed_hex = sys.argv[4].lstrip("#") if len(sys.argv) > 4 and len(sys.argv[4].lstrip("#")) == 6 else ""
    if variant not in SCHEMES and variant not in ("wallpaper", "auto"):
        variant = "tonalspot"

    cache_dir = Path.home() / ".cache" / "quickshell-mine"
    p = Path(image)
    if seed_hex:
        key = "seed" + seed_hex
    else:
        key = hashlib.sha1(f"{p.resolve()}:{p.stat().st_mtime_ns}".encode()).hexdigest()[:16]
    shown = variant
    if variant == "auto":
        try:
            variant = "neutral" if (seed_hex or colorfulness(image) < 40) and not seed_hex else "tonalspot"
        except Exception:
            variant = "tonalspot"
    cache = cache_dir / f"{key}-{shown}-{mode}-v2.json"   # v2: com _wall
    if cache.exists():
        print(cache.read_text())
        return

    # cor-fonte: quantiza (128 cores) e pontua; a melhor vira a cor primaria do esquema. O arquivo .seed guarda tambem
    # as outras cores marcantes (JSON); o formato antigo (so um numero) e recalculado
    seed_cache = cache_dir / f"{key}.seed"
    data = None
    if seed_hex:
        c = int("ff" + seed_hex, 16)
        data = {"seed": c, "ranked": [c], "loose": [c]}
    elif seed_cache.exists():
        try:
            data = json.loads(seed_cache.read_text())
            if not isinstance(data, dict):
                data = None
        except ValueError:
            data = None
    if data is None:
        colors = ImageQuantizeCelebi(str(p), 1, 128)
        ranked = Score.score(colors, ScoreOptions(desired=8, filter=True))
        loose = Score.score(colors, ScoreOptions(desired=8, filter=False))
        data = {"seed": ranked[0], "ranked": ranked, "loose": loose}
        cache_dir.mkdir(parents=True, exist_ok=True)
        seed_cache.write_text(json.dumps(data))
    source = data["seed"]

    if variant == "wallpaper":
        scheme = wallpaper_scheme(source, data.get("ranked", []), mode == "dark")
    else:
        scheme = SCHEMES[variant](Hct.from_int(source), mode == "dark", 0.0)
    out = {}
    dyn = MaterialDynamicColors()
    for color in dyn.all_colors:
        out[color.name] = to_hex(color.get_hct(scheme).to_int())

    # cores do terminal, harmonizadas com a cor primaria
    key_color = scheme.primary_palette.key_color.to_int() if hasattr(scheme.primary_palette, "key_color") else source
    for i, h in enumerate(TERM_DARK if mode == "dark" else TERM_LIGHT):
        out[f"term{i}"] = to_hex(Blend.harmonize(int("ff" + h, 16), key_color))
    out["_source"] = to_hex(source)
    out["_wall"] = wall_colors(data)
    out["_variant"] = shown
    out["_mode"] = mode

    cache_dir.mkdir(parents=True, exist_ok=True)
    text = json.dumps(out)
    cache.write_text(text)
    print(text)


if __name__ == "__main__":
    main()
