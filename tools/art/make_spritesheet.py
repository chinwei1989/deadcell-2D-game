"""Packs Blender-rendered frames (tools/blender/out/<name>/) into a game sprite sheet
(PLAN.md section 30.3): every pixel snapped to the game palette, hard alpha, and a 1 px
dark outline so characters read against busy backgrounds.

Usage (from the repo root):
    tools/art/.venv/bin/python tools/art/make_spritesheet.py hound

Outputs:
    art/sprites/<name>.png    one row per animation, frames left to right
    art/sprites/<name>_n.png  matching normal map (if the model rendered normals), so 2D
                              lights hit characters from the side like 3D lighting
    art/sprites/<name>.json   frame size, origin (feet/center pixel) and per-animation rows,
                              frame counts, fps and looping; read by game/fx/sprite_sheet.gd
"""

import json
import sys
from pathlib import Path

from PIL import Image

from palette import load_palette
from pixelize import pixelize

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "tools" / "blender" / "out"
DST = ROOT / "art" / "sprites"


def main(name: str) -> None:
    meta = json.loads((SRC / name / "meta.json").read_text())
    w, h = meta["frame_size"]
    palette = load_palette()
    colors = list(palette.values())
    anims = meta["animations"]
    columns = max(a["frames"] for a in anims.values())
    sheet = Image.new("RGBA", (columns * w, len(anims) * h), (0, 0, 0, 0))
    has_normals = bool(meta.get("normals")) and (SRC / name / f"{next(iter(anims))}_00_n.png").exists()
    normal_sheet = Image.new("RGBA", sheet.size, (128, 128, 255, 0)) if has_normals else None
    out_meta = {"frame_size": [w, h], "origin": meta["origin"], "animations": {}}
    for row, (anim, spec) in enumerate(anims.items()):
        for i in range(spec["frames"]):
            frame = Image.open(SRC / name / f"{anim}_{i:02d}.png")
            pixel = pixelize(frame, w, h, colors, alpha_threshold=100, outline=palette["void"])
            sheet.paste(pixel, (i * w, row * h))
            if normal_sheet is not None:
                normal_sheet.paste(_normal_frame(SRC / name / f"{anim}_{i:02d}_n.png", pixel), (i * w, row * h))
        out_meta["animations"][anim] = {"row": row, **spec}
    DST.mkdir(parents=True, exist_ok=True)
    sheet.save(DST / f"{name}.png")
    if normal_sheet is not None:
        normal_sheet.save(DST / f"{name}_n.png")
    (DST / f"{name}.json").write_text(json.dumps(out_meta, indent=2))
    print(f"wrote art/sprites/{name}.png ({sheet.width}x{sheet.height}) and {name}.json")


def _normal_frame(path: Path, color_frame: Image.Image) -> Image.Image:
    """Normal map pixels where the color frame is opaque; outline pixels (added after
    rendering) face the viewer (flat normal)."""
    normal = Image.open(path).convert("RGBA").resize(color_frame.size, Image.Resampling.BOX)
    out = Image.new("RGBA", color_frame.size, (128, 128, 255, 0))
    src, color, dst = normal.load(), color_frame.load(), out.load()
    for y in range(color_frame.height):
        for x in range(color_frame.width):
            if color[x, y][3] == 0:
                continue
            r, g, b, a = src[x, y]
            dst[x, y] = (r, g, b, 255) if a > 100 else (128, 128, 255, 255)
    return out


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: make_spritesheet.py <name>")
    main(sys.argv[1])
