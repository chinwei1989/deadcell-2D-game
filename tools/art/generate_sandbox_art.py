"""Generates the sandbox's pixel art in code (PLAN.md section 30): the terrain tileset,
two repeating city backdrop layers and a rain streak. Deterministic: the same script
always produces the same images.

Usage (from the repo root):
    tools/art/.venv/bin/python tools/art/generate_sandbox_art.py

Outputs:
    art/tiles/sandbox_tiles.png     16 px tiles, layout must match game/arena/auto_tile.gd
    art/backgrounds/city_far.png    640x360, repeats horizontally
    art/backgrounds/city_near.png   640x360, transparent sky, repeats horizontally
    art/fx/rain.png                 1x8 rain streak

Tileset layout (column, row):
    row 0, col 0-15   solid tiles by neighbour mask: N=1, E=2, S=4, W=8 (bit set = solid neighbour)
    row 1, col 0-3    interior variants (mask 15): plain, rivets, crack, vent with a warm light
    row 1, col 4-7    one-way platform: left cap, middle, right cap, single
    row 1, col 8      spikes
"""

import random
from pathlib import Path

from PIL import Image

from palette import load_palette

ROOT = Path(__file__).resolve().parents[2]
T = 16
P = load_palette()


def px(img: Image.Image, x: int, y: int, color: str) -> None:
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), (*P[color], 255))


def rect(img: Image.Image, x: int, y: int, w: int, h: int, color: str) -> None:
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            px(img, xx, yy, color)


# --- Terrain tiles ------------------------------------------------------------------

def solid_tile(mask: int, variant: int, seed: int) -> Image.Image:
    rng = random.Random(seed)
    tile = Image.new("RGBA", (T, T))
    rect(tile, 0, 0, T, T, "steel")
    # Concrete blocks: seams line up across neighbouring tiles.
    for x in range(T):
        px(tile, x, 7, "dark steel")
        px(tile, x, 15, "dark steel")
    for y in range(0, 7):
        px(tile, 5, y, "dark steel")
    for y in range(8, 15):
        px(tile, 12, y, "dark steel")
    # Grime and wear.
    for _ in range(9):
        px(tile, rng.randrange(T), rng.randrange(T), rng.choice(["steel light", "dark steel"]))

    if mask == 15:
        if variant == 1:  # rivets
            for x, y in ((2, 2), (9, 2), (2, 10), (14, 10)):
                px(tile, x, y, "teal dim")
        elif variant == 2:  # crack
            x = 4
            for y in range(1, 13):
                px(tile, x, y, "shadow")
                if rng.random() < 0.45:
                    x += rng.choice((-1, 1))
        elif variant == 3:  # vent with a warm light behind it
            rect(tile, 4, 4, 8, 5, "shadow")
            for x in range(5, 11, 2):
                rect(tile, x, 5, 1, 3, "rust dark")
            px(tile, 7, 6, "amber")
            px(tile, 8, 6, "amber light")

    north, east, south, west = (mask & 1) == 0, (mask & 2) == 0, (mask & 4) == 0, (mask & 8) == 0
    if west:
        rect(tile, 0, 0, 1, T, "shadow")
        rect(tile, 1, 0, 1, T, "dark steel")
    if east:
        rect(tile, T - 1, 0, 1, T, "shadow")
        rect(tile, T - 2, 0, 1, T, "dark steel")
    if south:
        rect(tile, 0, T - 1, T, 1, "shadow")
        rect(tile, 0, T - 2, T, 1, "dark steel")
        for x in range(1, T - 1):  # drips under ledges
            if rng.random() < 0.15:
                px(tile, x, T - 3, "dark steel")
    if north:
        rect(tile, 0, 0, T, 1, "teal")
        rect(tile, 0, 1, T, 1, "teal dim")
        rect(tile, 0, 2, T, 1, "slate")
        for x in range(T):
            if rng.random() < 0.2:
                px(tile, x, 3, "slate")
        # Rounded top corners where a side is open too.
        if west:
            px(tile, 0, 0, "slate")
            px(tile, 0, 1, "steel")
        if east:
            px(tile, T - 1, 0, "slate")
            px(tile, T - 1, 1, "steel")
    return tile


def one_way_tile(left_cap: bool, right_cap: bool) -> Image.Image:
    tile = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    rect(tile, 0, 0, T, 1, "teal")
    rect(tile, 0, 1, T, 1, "teal dim")
    for x in range(T):  # grating
        for y in range(2, 5):
            px(tile, x, y, "shadow" if x % 3 == 0 else "slate")
    rect(tile, 0, 5, T, 1, "dark steel")
    for cap, x0, step in ((left_cap, 0, 1), (right_cap, T - 1, -1)):
        if not cap:
            continue
        rect(tile, min(x0, x0 + step), 0, 2, 6, "teal dim")
        px(tile, x0 + step, 3, "teal light")  # bolt
        for i in range(5):  # support bracket
            px(tile, x0 + step * (1 + i), 6 + i, "slate")
            px(tile, x0, 6 + i, "dark steel")
    return tile


def spikes_tile() -> Image.Image:
    tile = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    rect(tile, 0, 13, T, 3, "rust dark")
    rect(tile, 0, 13, T, 1, "rust")
    for base in range(0, T, 4):
        for row in range(10):  # each spike narrows from 4 px at the bottom to a 1 px tip
            y = 12 - row
            half = 2.0 * (10 - row) / 10
            x0 = round(base + 2 - half)
            x1 = max(round(base + 2 + half), x0 + 1)
            for x in range(x0, x1):
                px(tile, x, y, "rust")
            px(tile, x0, y, "red")  # lit left edge
        px(tile, base + 1, 3, "hot")
        px(tile, base + 1, 2, "amber light")
    return tile


def make_tileset() -> Image.Image:
    sheet = Image.new("RGBA", (16 * T, 2 * T), (0, 0, 0, 0))
    for mask in range(16):
        sheet.paste(solid_tile(mask, 0, 100 + mask), (mask * T, 0))
    for variant in range(4):
        sheet.paste(solid_tile(15, variant, 200 + variant), (variant * T, T))
    for i, (left, right) in enumerate(((True, False), (False, False), (False, True), (True, True))):
        sheet.paste(one_way_tile(left, right), ((4 + i) * T, T))
    sheet.paste(spikes_tile(), (8 * T, T))
    return sheet


# --- City backdrop ------------------------------------------------------------------

def city_layer(seed: int, near: bool) -> Image.Image:
    """A 640x360 skyline that repeats seamlessly left to right."""
    w, h = 640, 360
    rng = random.Random(seed)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    if not near:
        bands = ["void", "void", "deep", "deep", "shadow"]
        for y in range(h):  # stepped gradient sky
            band = bands[min(len(bands) - 1, y * len(bands) // h)]
            rect(img, 0, y, w, 1, band)
        for _ in range(70):  # distant lights in the haze
            px(img, rng.randrange(w), rng.randrange(h // 2), "dark steel")

    body = "dark steel" if near else "shadow"
    roof = "steel" if near else "dark steel"
    window_cold = "slate" if near else "dark steel"
    x = 0
    while x < w:
        bw = rng.randint(40, 90) if near else rng.randint(18, 54)
        bh = rng.randint(110, 230) if near else rng.randint(90, 250)
        top = h - bh
        for xx in range(x, x + bw):
            for yy in range(top, h):
                px(img, xx % w, yy, body)
            px(img, xx % w, top, roof)
        # Windows: mostly cold, a few warm (people still live here).
        for wy in range(top + 6, h - 4, 7 if near else 5):
            for wx in range(x + 3, x + bw - 3, 5 if near else 3):
                roll = rng.random()
                if roll < 0.06:
                    color = "amber" if rng.random() < 0.7 else "amber light"
                elif roll < 0.30:
                    color = window_cold
                else:
                    continue
                rect(img, wx % w, wy, 2 if near else 1, 2 if near else 1, color)
        # Neon signs and antennas.
        if rng.random() < (0.45 if near else 0.25):
            sx, sy = x + rng.randint(2, max(2, bw - 14)), top + rng.randint(8, 40)
            color = rng.choice(["teal", "teal", "hot"])
            for i in range(10 if near else 6):
                px(img, (sx + i) % w, sy, color)
                px(img, (sx + i) % w, sy + (3 if near else 2), color)
        if rng.random() < 0.4:
            ax = x + rng.randint(2, bw - 2)
            for yy in range(top - rng.randint(6, 20), top):
                px(img, ax % w, yy, roof)
            px(img, ax % w, top - 21, "red")
        x += bw + (rng.randint(4, 30) if near else rng.randint(0, 8))
    return img


def rain_streak() -> Image.Image:
    img = Image.new("RGBA", (1, 8), (0, 0, 0, 0))
    r, g, b = P["teal light"]
    for y in range(8):
        img.putpixel((0, y), (r, g, b, 40 + y * 20))
    return img


def main() -> None:
    outputs = {
        "art/tiles/sandbox_tiles.png": make_tileset(),
        "art/backgrounds/city_far.png": city_layer(7, near=False),
        "art/backgrounds/city_near.png": city_layer(11, near=True),
        "art/fx/rain.png": rain_streak(),
    }
    for relative, image in outputs.items():
        path = ROOT / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        image.save(path)
        print(f"wrote {relative} ({image.width}x{image.height})")


if __name__ == "__main__":
    main()
