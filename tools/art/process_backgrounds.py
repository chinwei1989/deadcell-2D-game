"""Turns raw AI backdrop images (from generate_ai_backgrounds.py) into game-ready parallax
layers (PLAN.md section 30):

1. cut the plain background out of the mid/near layers (flood fill from the sky side, so
   lit windows inside buildings are kept),
2. make each layer loop seamlessly left-to-right (cross-fade the ends),
3. darken it by depth so gameplay stays readable in front,
4. pixelize to the game palette at screen height (360 px).

Usage (from the repo root):
    tools/art/.venv/bin/python tools/art/process_backgrounds.py
    tools/art/.venv/bin/python tools/art/process_backgrounds.py --pick far=1102 mid=2202 near=3304

Outputs art/backgrounds/ai_far.png, ai_mid.png, ai_near.png and a preview composite in
tools/art/raw/preview.png.
"""

import argparse
from collections import deque
from pathlib import Path

from PIL import Image, ImageEnhance

from palette import load_palette
from pixelize import pixelize

ROOT = Path(__file__).resolve().parents[2]
RAW_DIR = Path(__file__).with_name("raw")
OUT_DIR = ROOT / "art" / "backgrounds"
SCREEN_HEIGHT = 360
SEAM = 200  # pixels cross-faded to make the loop seamless (at raw resolution)

DEFAULT_PICKS = {"far": 1101, "mid": 2202, "near": 3303}
# Brightness multiplier by depth: far layers recede, gameplay stays the brightest thing.
BRIGHTNESS = {"far": 0.45, "mid": 0.4, "near": 0.4}
# How each layer's plain background is removed (see cut_out_background).
CUT_OUT = {"mid": "wand", "near": "light"}
# Palette colors each layer may use (cold and dark, plus the warm/neon accents).
COLORS = {
    "far": ["void", "deep", "shadow", "dark steel", "steel", "slate", "teal dim", "gray dark", "amber", "rust"],
    "mid": ["void", "deep", "shadow", "dark steel", "steel", "slate", "teal dim",
            "gray dark", "amber", "rust", "rust dark"],
    "near": ["void", "deep", "shadow", "dark steel", "steel", "slate", "teal dim", "red", "hot", "amber"],
}


def _distance(a: tuple, b: tuple) -> float:
    return ((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2) ** 0.5


def cut_out_background(image: Image.Image, mode: str, step: float = 14.0, max_drift: float = 140.0) -> Image.Image:
    """Makes the plain background transparent.

    mode "wand": like a contiguous magic wand started from the top edge. The fill spreads to
        neighbours whose color is within `step` of the current pixel (so smooth sky gradients
        are followed) but stops at shape edges, and never drifts more than `max_drift` from
        the sky color where it started. Keeps lit windows inside buildings.
    mode "light": for dark silhouettes on a light background: every light, unsaturated
        pixel is background, including sky enclosed by cables and antennas.
    Then removes tiny floating specks and the light halo around shapes."""
    rgba = image.convert("RGBA")
    w, h = rgba.size
    px = rgba.load()
    top_row = sorted(px[x, 0][:3] for x in range(w))
    bg = top_row[len(top_row) // 2]  # median top-edge color

    seen = bytearray(w * h)
    if mode == "light":
        for y in range(h):
            for x in range(w):
                r, g, b, _ = px[x, y]
                if (r + g + b) / 3 > 110 and max(r, g, b) - min(r, g, b) < 45:
                    seen[y * w + x] = 1
    queue: deque[tuple[int, int]] = deque()
    starts = [] if mode == "light" else [(x, 0) for x in range(w)] + [(0, y) for y in range(h * 3 // 4)] + [(w - 1, y) for y in range(h * 3 // 4)]
    for x, y in starts:
        if _distance(px[x, y], bg) < max_drift / 2 and not seen[y * w + x]:
            seen[y * w + x] = 1
            queue.append((x, y))
    while queue:
        x, y = queue.popleft()
        here = px[x, y]
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx]:
                there = px[nx, ny]
                if _distance(there, here) < step and _distance(there, bg) < max_drift:
                    seen[ny * w + nx] = 1
                    queue.append((nx, ny))

    for y in range(h):
        for x in range(w):
            if seen[y * w + x]:
                px[x, y] = (0, 0, 0, 0)
    # Remove specks floating in the sky (birds, noise): small detached opaque islands.
    min_island = 60
    island_seen = bytearray(w * h)
    for sy in range(h):
        for sx in range(w):
            if seen[sy * w + sx] or island_seen[sy * w + sx]:
                continue
            island = [(sx, sy)]
            island_seen[sy * w + sx] = 1
            i = 0
            while i < len(island):
                x, y = island[i]
                i += 1
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx] and not island_seen[ny * w + nx]:
                        island_seen[ny * w + nx] = 1
                        island.append((nx, ny))
            if len(island) <= min_island:
                for x, y in island:
                    seen[y * w + x] = 1
                    px[x, y] = (0, 0, 0, 0)
    # Remove the light halo left around shapes: bright pixels touching the cut-out.
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a and (r + g + b) / 3 > 170:
                if any(0 <= nx < w and 0 <= ny < h and seen[ny * w + nx]
                       for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))):
                    px[x, y] = (0, 0, 0, 0)
    return rgba


def make_seamless(image: Image.Image, seam: int = SEAM) -> Image.Image:
    """Cross-fades the right end into the left end. The result is `seam` px narrower
    and loops without a visible edge."""
    w, h = image.size
    out = image.crop((0, 0, w - seam, h))
    left = image.crop((0, 0, seam, h))
    right = image.crop((w - seam, 0, w, h))
    # linear_gradient is black at the top; rotating clockwise puts white on the left.
    mask = Image.linear_gradient("L").rotate(-90, expand=True).resize((seam, h))  # 255 → 0, left to right
    blended = Image.composite(right, left, mask)
    out.paste(blended, (0, 0))
    return out


def process(name: str, seed: int, palette: dict) -> Image.Image:
    raw = Image.open(RAW_DIR / f"{name}_{seed}.png").convert("RGBA")
    if name in CUT_OUT:
        raw = cut_out_background(raw, CUT_OUT[name])
    raw = make_seamless(raw)
    rgb = ImageEnhance.Brightness(raw.convert("RGB")).enhance(BRIGHTNESS[name])
    rgb.putalpha(raw.getchannel("A"))
    return pixelize(rgb, None, SCREEN_HEIGHT, [palette[c] for c in COLORS[name]])


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pick", nargs="*", default=[], help="layer=seed, e.g. far=1102")
    args = parser.parse_args()
    picks = dict(DEFAULT_PICKS)
    for item in args.pick:
        layer, seed = item.split("=")
        picks[layer] = int(seed)

    palette = load_palette()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    layers = {}
    for name, seed in picks.items():
        layers[name] = process(name, seed, palette)
        out = OUT_DIR / f"ai_{name}.png"
        layers[name].save(out)
        print(f"wrote {out.relative_to(ROOT)} ({layers[name].width}x{layers[name].height}) from {name}_{seed}.png")

    preview = layers["far"].copy()
    for name in ("mid", "near"):
        preview.alpha_composite(layers[name].crop((0, 0, preview.width, preview.height)))
    preview.resize((preview.width * 2, preview.height * 2), Image.Resampling.NEAREST).save(RAW_DIR / "preview.png")


if __name__ == "__main__":
    main()
