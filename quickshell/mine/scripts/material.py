#!/usr/bin/env python3
"""Gera o tema (Material You) a partir de uma imagem, como o Caelestia faz:
quantiza o wallpaper (Celebi), escolhe a cor-fonte pela pontuacao do Material e monta um esquema dinamico.

uso: material.py <imagem> [dark|light] [variante]
variantes: tonalspot (padrao) vibrant expressive fidelity content neutral monochrome rainbow fruitsalad
saida: JSON { papel: "#rrggbb", ... } (papeis do Material + term0..term15). Resultado guardado em ~/.cache/quickshell-mine.
"""
import hashlib
import json
import sys
from pathlib import Path

from materialyoucolor.dynamiccolor.material_dynamic_colors import MaterialDynamicColors
from materialyoucolor.hct import Hct
from materialyoucolor.quantize import ImageQuantizeCelebi
from materialyoucolor.score.score import Score
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


def main() -> None:
    image = sys.argv[1]
    mode = sys.argv[2] if len(sys.argv) > 2 else "dark"
    variant = sys.argv[3] if len(sys.argv) > 3 else "tonalspot"
    if variant not in SCHEMES:
        variant = "tonalspot"

    p = Path(image)
    key = hashlib.sha1(f"{p.resolve()}:{p.stat().st_mtime_ns}".encode()).hexdigest()[:16]
    cache_dir = Path.home() / ".cache" / "quickshell-mine"
    cache = cache_dir / f"{key}-{variant}-{mode}.json"
    if cache.exists():
        print(cache.read_text())
        return

    # cor-fonte: quantiza (128 cores) e pontua; a melhor vira a cor primaria do esquema
    seed_cache = cache_dir / f"{key}.seed"
    if seed_cache.exists():
        source = int(seed_cache.read_text())
    else:
        colors = ImageQuantizeCelebi(str(p), 1, 128)
        source = Score.score(colors)[0]
        cache_dir.mkdir(parents=True, exist_ok=True)
        seed_cache.write_text(str(source))

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
    out["_variant"] = variant
    out["_mode"] = mode

    cache_dir.mkdir(parents=True, exist_ok=True)
    text = json.dumps(out)
    cache.write_text(text)
    print(text)


if __name__ == "__main__":
    main()
