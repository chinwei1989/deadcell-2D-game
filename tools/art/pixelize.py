"""Turns any image (e.g. AI output) into LAST EDGE pixel art (PLAN.md section 30).

Downscales to the target pixel size, snaps every color to the game palette, makes
transparency hard-edged, and can add a 1 px outline so sprites read against busy
backgrounds.

Usage (from the repo root):
    tools/art/.venv/bin/python tools/art/pixelize.py IN.png OUT.png --height 48
    tools/art/.venv/bin/python tools/art/pixelize.py IN.png OUT.png --width 32 --outline
    tools/art/.venv/bin/python tools/art/pixelize.py IN.png OUT.png --height 360 --colors "void,deep,shadow,teal"

Options:
    --width / --height   target size in pixels (give one to keep the aspect ratio)
    --colors             comma-separated palette color names to restrict to (default: all)
    --alpha-threshold    0-255, pixels below become fully transparent (default 128)
    --outline            add a 1 px outline in the palette's "void" color
"""

import argparse
from pathlib import Path

from PIL import Image

from palette import PaletteMatcher, load_palette


def pixelize(
    image: Image.Image,
    width: int | None,
    height: int | None,
    colors: list[tuple[int, int, int]],
    alpha_threshold: int = 128,
    outline: tuple[int, int, int] | None = None,
) -> Image.Image:
    image = image.convert("RGBA")
    if width is None and height is None:
        raise ValueError("give --width or --height")
    if width is None:
        width = max(1, round(image.width * height / image.height))
    if height is None:
        height = max(1, round(image.height * width / image.width))
    # Box filter averages each block of source pixels: clean, no ringing.
    small = image.resize((width, height), Image.Resampling.BOX)

    matcher = PaletteMatcher(colors)
    out = Image.new("RGBA", small.size, (0, 0, 0, 0))
    src = small.load()
    dst = out.load()
    for y in range(small.height):
        for x in range(small.width):
            r, g, b, a = src[x, y]
            if a >= alpha_threshold:
                dst[x, y] = (*matcher.nearest((r, g, b)), 255)

    if outline is not None:
        dst_copy = out.copy().load()
        for y in range(out.height):
            for x in range(out.width):
                if dst_copy[x, y][3] != 0:
                    continue
                neighbors = [(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
                if any(0 <= nx < out.width and 0 <= ny < out.height and dst_copy[nx, ny][3] != 0 for nx, ny in neighbors):
                    dst[x, y] = (*outline, 255)
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--width", type=int)
    parser.add_argument("--height", type=int)
    parser.add_argument("--colors", help="comma-separated palette color names")
    parser.add_argument("--alpha-threshold", type=int, default=128)
    parser.add_argument("--outline", action="store_true")
    args = parser.parse_args()

    palette = load_palette()
    names = [n.strip() for n in args.colors.split(",")] if args.colors else list(palette)
    unknown = [n for n in names if n not in palette]
    if unknown:
        parser.error(f"unknown palette colors: {', '.join(unknown)}")
    result = pixelize(
        Image.open(args.input),
        args.width,
        args.height,
        [palette[n] for n in names],
        args.alpha_threshold,
        palette["void"] if args.outline else None,
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    result.save(args.output)
    print(f"wrote {args.output} ({result.width}x{result.height})")


if __name__ == "__main__":
    main()
