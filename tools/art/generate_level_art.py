"""Generates level dressing in code (PLAN.md section 30): building facade tiles for the back
wall, floor props, and dark foreground silhouettes. Deterministic.

Usage (from the repo root):
    tools/art/.venv/bin/python tools/art/generate_level_art.py

Outputs:
    art/tiles/facade_tiles.png   16 px back-wall tiles; layout must match game/arena/level_dressing.gd
        row 0: col 0-3 plain wall variants, 4 dark window, 5 warm window, 6 cold window,
               7 broken window, 8 vent, 9 vertical pipe, 10 pipe joint, 11 AC unit,
               12 teal sign piece, 13 red sign piece, 14 roof edge, 15 roof edge with antenna
    art/props/<name>.png         crate, barrel, trash, vending, cone, ac_box, pipes, terminal
    art/foreground/<name>.png    pillar, girder, railing, cables (near-black silhouettes)
"""

import random
from pathlib import Path

from PIL import Image

from palette import load_palette

ROOT = Path(__file__).resolve().parents[2]
T = 16
P = load_palette()


def px(img: Image.Image, x: int, y: int, color: str, alpha: int = 255) -> None:
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), (*P[color], alpha))


def rect(img: Image.Image, x: int, y: int, w: int, h: int, color: str, alpha: int = 255) -> None:
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            px(img, xx, yy, color, alpha)


def outline(img: Image.Image, color: str = "void") -> Image.Image:
    """1 px outline around opaque pixels."""
    out = img.copy()
    src = img.load()
    for y in range(img.height):
        for x in range(img.width):
            if src[x, y][3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < img.width and 0 <= ny < img.height and src[nx, ny][3]:
                    out.putpixel((x, y), (*P[color], 255))
                    break
    return out


# --- Facade (back wall) tiles ------------------------------------------------------------

def wall(variant: int, seed: int) -> Image.Image:
    rng = random.Random(seed)
    tile = Image.new("RGBA", (T, T))
    rect(tile, 0, 0, T, T, "shadow")
    for x in range(T):  # panel seams
        px(tile, x, 15, "deep")
    for y in range(T):
        px(tile, 0 if variant % 2 else 8, y, "deep")
    for _ in range(8):
        px(tile, rng.randrange(T), rng.randrange(T), rng.choice(["dark steel", "deep"]))
    if variant == 2:  # stains
        for y in range(4, 14):
            px(tile, 11, y, "shadow")
    if variant == 3:  # bolts
        for x, y in ((3, 3), (12, 3), (3, 12), (12, 12)):
            px(tile, x, y, "dark steel")
    return tile


def window(glass: str, lit: bool, broken: bool = False) -> Image.Image:
    tile = wall(0, 31)
    rect(tile, 3, 2, 10, 11, "void")
    rect(tile, 4, 3, 8, 9, glass)
    if lit:
        rect(tile, 4, 9, 8, 3, "amber light" if glass == "amber" else "teal light")
    rect(tile, 7, 3, 1, 9, "void")  # frame
    rect(tile, 4, 7, 8, 1, "void")
    if broken:
        for x, y in ((5, 4), (6, 5), (9, 6), (10, 4), (8, 9)):
            px(tile, x, y, "void")
    rect(tile, 2, 13, 12, 1, "dark steel")  # sill
    return tile


def make_facade() -> Image.Image:
    sheet = Image.new("RGBA", (16 * T, T), (0, 0, 0, 0))
    tiles = [wall(v, 40 + v) for v in range(4)]
    tiles += [window("shadow", False), window("amber", True), window("teal dim", True),
              window("shadow", False, broken=True)]
    vent = wall(0, 50)
    rect(vent, 3, 4, 10, 8, "void")
    for y in range(5, 11, 2):
        rect(vent, 4, y, 8, 1, "dark steel")
    tiles.append(vent)
    pipe = wall(1, 51)
    rect(pipe, 6, 0, 4, T, "steel")
    rect(pipe, 6, 0, 1, T, "slate")
    rect(pipe, 9, 0, 1, T, "shadow")
    tiles.append(pipe)
    joint = pipe.copy()
    rect(joint, 5, 6, 6, 4, "slate")
    rect(joint, 5, 6, 6, 1, "teal dim")
    tiles.append(joint)
    ac = wall(2, 52)
    rect(ac, 1, 3, 14, 10, "gray dark")
    rect(ac, 2, 4, 7, 8, "steel")
    for i in range(3):  # fan grille
        rect(ac, 3, 5 + i * 2, 5, 1, "shadow")
    rect(ac, 10, 5, 4, 2, "amber")
    tiles.append(ac)
    for color in ("teal", "hot"):
        sign = wall(3, 53)
        rect(sign, 0, 4, T, 8, "void")
        for x in range(1, 15, 3):
            rect(sign, x, 6, 2, 4, color)
        tiles.append(sign)
    roof = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    rect(roof, 0, 10, T, 6, "shadow")
    rect(roof, 0, 10, T, 1, "dark steel")
    rect(roof, 0, 12, T, 1, "void")
    tiles.append(roof)
    antenna = roof.copy()
    rect(antenna, 7, 1, 1, 9, "dark steel")
    rect(antenna, 5, 4, 5, 1, "dark steel")
    px(antenna, 7, 0, "red")
    tiles.append(antenna)
    for i, tile in enumerate(tiles):
        sheet.paste(tile, (i * T, 0))
    return sheet


# --- Props -----------------------------------------------------------------------------

def crate() -> Image.Image:
    img = Image.new("RGBA", (16, 14))
    rect(img, 0, 0, 16, 14, "rust")
    rect(img, 0, 0, 16, 2, "copper")
    rect(img, 1, 3, 14, 1, "rust dark")
    rect(img, 1, 8, 14, 1, "rust dark")
    for x in (2, 13):
        rect(img, x, 2, 1, 12, "rust dark")
    px(img, 7, 5, "amber")  # stencil mark
    px(img, 8, 5, "amber")
    return outline(img)


def barrel() -> Image.Image:
    img = Image.new("RGBA", (12, 16))
    rect(img, 1, 0, 10, 16, "steel")
    rect(img, 1, 0, 3, 16, "slate")
    rect(img, 9, 0, 2, 16, "shadow")
    for y in (3, 12):
        rect(img, 1, y, 10, 1, "dark steel")
    rect(img, 4, 6, 4, 3, "amber")  # hazard label
    return outline(img)


def trash() -> Image.Image:
    img = Image.new("RGBA", (22, 10))
    for cx, cy, r, color in ((5, 6, 5, "shadow"), (12, 5, 6, "dark steel"), (18, 7, 4, "shadow")):
        for y in range(10):
            for x in range(22):
                if (x - cx) ** 2 + (y - cy) ** 2 * 1.6 <= r * r:
                    px(img, x, y, color)
    px(img, 11, 1, "steel")
    px(img, 12, 1, "steel")
    return outline(img)


def vending() -> Image.Image:
    img = Image.new("RGBA", (16, 30))
    rect(img, 0, 0, 16, 30, "gray dark")
    rect(img, 1, 2, 10, 20, "teal dim")
    rect(img, 2, 3, 8, 18, "teal")
    for y in range(4, 20, 4):  # shelves
        rect(img, 2, y, 8, 1, "teal dim")
        for x in range(3, 9, 2):
            px(img, x, y - 1, "amber" if (x + y) % 3 else "hot")
    rect(img, 12, 4, 3, 2, "amber")  # coin slot light
    rect(img, 12, 8, 3, 6, "shadow")
    rect(img, 1, 24, 10, 3, "void")  # tray
    return outline(img)


def cone() -> Image.Image:
    img = Image.new("RGBA", (10, 11))
    for y in range(9):
        half = 1 + y // 2
        rect(img, 5 - half, y, half * 2, 1, "hot" if y % 4 < 2 else "gray light")
    rect(img, 0, 9, 10, 2, "rust dark")
    return outline(img)


def ac_box() -> Image.Image:
    img = Image.new("RGBA", (18, 12))
    rect(img, 0, 0, 18, 12, "gray")
    rect(img, 0, 0, 18, 1, "gray light")
    rect(img, 2, 2, 8, 8, "steel")
    for i in range(4):
        rect(img, 3, 3 + i * 2, 6, 1, "shadow")
    rect(img, 12, 3, 4, 2, "teal dim")
    return outline(img)


def pipes() -> Image.Image:
    img = Image.new("RGBA", (24, 12))
    for y, color in ((1, "steel"), (6, "slate")):
        rect(img, 0, y, 24, 4, color)
        rect(img, 0, y, 24, 1, "gray dark")
    rect(img, 8, 0, 3, 12, "dark steel")
    return outline(img)


def terminal() -> Image.Image:
    img = Image.new("RGBA", (12, 20))
    rect(img, 4, 8, 4, 12, "dark steel")
    rect(img, 0, 0, 12, 9, "gray dark")
    rect(img, 1, 1, 10, 6, "void")
    rect(img, 2, 2, 8, 4, "teal dim")
    rect(img, 2, 2, 8, 1, "teal light")
    return outline(img)


# --- Foreground silhouettes ---------------------------------------------------------------

def silhouette(w: int, h: int, draw) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw(img)
    return img


def pillar(img: Image.Image) -> None:
    rect(img, 6, 0, 22, img.height, "void")
    rect(img, 6, 0, 1, img.height, "shadow")  # faint rim
    for y in range(20, img.height, 46):
        rect(img, 2, y, 30, 6, "void")
    rect(img, 30, 0, 4, img.height, "void")  # pipe


def girder(img: Image.Image) -> None:
    rect(img, 0, 0, 6, img.height, "void")
    rect(img, img.width - 6, 0, 6, img.height, "void")
    for y in range(0, img.height, 24):
        for i in range(24):
            px(img, int(i * (img.width - 1) / 23), y + i, "void")
            px(img, int(i * (img.width - 1) / 23) + 1, y + i, "void")
            px(img, img.width - 1 - int(i * (img.width - 1) / 23), y + i, "void")


def railing(img: Image.Image) -> None:
    rect(img, 0, 0, img.width, 3, "void")
    rect(img, 0, 12, img.width, 2, "void")
    for x in range(0, img.width, 12):
        rect(img, x, 0, 2, img.height, "void")


def cables(img: Image.Image) -> None:
    for sag, thickness in ((26, 2), (40, 1), (52, 2)):
        for x in range(img.width):
            t = x / (img.width - 1)
            y = int(4 + 4 * sag * t * (1 - t))
            for k in range(thickness):
                px(img, x, y + k, "void")


def main() -> None:
    outputs = {"art/tiles/facade_tiles.png": make_facade()}
    for name, fn in (("crate", crate), ("barrel", barrel), ("trash", trash), ("vending", vending), ("cone", cone),
                     ("ac_box", ac_box), ("pipes", pipes), ("terminal", terminal)):
        outputs[f"art/props/{name}.png"] = fn()
    outputs["art/foreground/pillar.png"] = silhouette(36, 260, pillar)
    outputs["art/foreground/girder.png"] = silhouette(60, 220, girder)
    outputs["art/foreground/railing.png"] = silhouette(180, 30, railing)
    outputs["art/foreground/cables.png"] = silhouette(240, 70, cables)
    for relative, image in outputs.items():
        path = ROOT / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        image.save(path)
    print("wrote", len(outputs), "images")


if __name__ == "__main__":
    main()
