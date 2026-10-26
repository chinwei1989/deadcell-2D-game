"""Generates the game's pixel font (original, drawn here): 5x7 capitals, digits and
punctuation, packed as a BMFont (text .fnt + PNG) that Godot imports as a FontFile.
Lowercase letters map to the capitals (an all-caps display face). Deterministic.

Usage (from the repo root):
    tools/art/.venv/bin/python tools/art/generate_font.py

Outputs:
    art/fonts/last_edge.png   white glyphs on transparent (tint with font_color)
    art/fonts/last_edge.fnt   BMFont text descriptor; size 8 = 1x, use 16/24 for 2x/3x
"""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "art" / "fonts"
SIZE = 8  # Nominal font size: the size that draws glyphs 1:1.
HEIGHT = 7  # Cap height.
LINE_HEIGHT = 10
SPACE_ADVANCE = 4
COLUMNS = 16

# Each glyph: 7 rows of equal width; '#' = ink. Width varies per glyph.
GLYPHS: dict[str, str] = {
    "A": ".###. #...# #...# ##### #...# #...# #...#",
    "B": "####. #...# #...# ####. #...# #...# ####.",
    "C": ".###. #...# #.... #.... #.... #...# .###.",
    "D": "####. #...# #...# #...# #...# #...# ####.",
    "E": "##### #.... #.... ####. #.... #.... #####",
    "F": "##### #.... #.... ####. #.... #.... #....",
    "G": ".###. #...# #.... #.### #...# #...# .####",
    "H": "#...# #...# #...# ##### #...# #...# #...#",
    "I": "### .#. .#. .#. .#. .#. ###",
    "J": "..### ...#. ...#. ...#. #..#. #..#. .##..",
    "K": "#...# #..#. #.#.. ##... #.#.. #..#. #...#",
    "L": "#.... #.... #.... #.... #.... #.... #####",
    "M": "#...# ##.## #.#.# #.#.# #...# #...# #...#",
    "N": "#...# ##..# #.#.# #..## #...# #...# #...#",
    "O": ".###. #...# #...# #...# #...# #...# .###.",
    "P": "####. #...# #...# ####. #.... #.... #....",
    "Q": ".###. #...# #...# #...# #.#.# #..#. .##.#",
    "R": "####. #...# #...# ####. #.#.. #..#. #...#",
    "S": ".#### #.... #.... .###. ....# ....# ####.",
    "T": "##### ..#.. ..#.. ..#.. ..#.. ..#.. ..#..",
    "U": "#...# #...# #...# #...# #...# #...# .###.",
    "V": "#...# #...# #...# #...# .#.#. .#.#. ..#..",
    "W": "#...# #...# #...# #.#.# #.#.# ##.## #...#",
    "X": "#...# #...# .#.#. ..#.. .#.#. #...# #...#",
    "Y": "#...# #...# .#.#. ..#.. ..#.. ..#.. ..#..",
    "Z": "##### ....# ...#. ..#.. .#... #.... #####",
    "0": ".###. #...# #..## #.#.# ##..# #...# .###.",
    "1": ".#. ##. .#. .#. .#. .#. ###",
    "2": ".###. #...# ....# ...#. ..#.. .#... #####",
    "3": "####. ....# ....# .###. ....# ....# ####.",
    "4": "...#. ..##. .#.#. #..#. ##### ...#. ...#.",
    "5": "##### #.... ####. ....# ....# #...# .###.",
    "6": ".###. #.... #.... ####. #...# #...# .###.",
    "7": "##### ....# ...#. ..#.. ..#.. ..#.. ..#..",
    "8": ".###. #...# #...# .###. #...# #...# .###.",
    "9": ".###. #...# #...# .#### ....# ....# .###.",
    ".": ". . . . . . #",
    ",": ".. .. .. .. .. .# #.",
    ":": ". . # . . # .",
    "!": "# # # # # . #",
    "?": ".###. #...# ....# ...#. ..#.. ..... ..#..",
    "-": "... ... ... ### ... ... ...",
    "+": "..... ..#.. ..#.. ##### ..#.. ..#.. .....",
    "/": "....# ...#. ...#. ..#.. .#... .#... #....",
    "%": "##..# ##.#. ...#. ..#.. .#... .#.## #..##",
    "'": "# # . . . . .",
    "\"": "#.# #.# ... ... ... ... ...",
    "(": ".# #. #. #. #. #. .#",
    ")": "#. .# .# .# .# .# #.",
    "[": "## #. #. #. #. #. ##",
    "]": "## .# .# .# .# .# ##",
    "<": "... ..# .#. #.. .#. ..# ...",
    ">": "... #.. .#. ..# .#. #.. ...",
    "=": ".... .... #### .... #### .... ....",
    "_": "..... ..... ..... ..... ..... ..... #####",
    "#": ".#.#. ##### .#.#. .#.#. .#.#. ##### .#.#.",
    "&": ".##.. #..#. .##.. .#... #.#.# #..#. .##.#",
    "*": "..... #.#.# .###. ##### .###. #.#.# .....",
}


def parse(rows: str) -> list[str]:
    lines = rows.split()
    assert len(lines) == HEIGHT, rows
    assert len({len(line) for line in lines}) == 1, rows
    return lines


def main() -> None:
    glyphs = {char: parse(rows) for char, rows in GLYPHS.items()}
    cell_w = max(len(g[0]) for g in glyphs.values()) + 1
    cell_h = HEIGHT + 1
    rows = (len(glyphs) + COLUMNS - 1) // COLUMNS
    sheet = Image.new("RGBA", (COLUMNS * cell_w, rows * cell_h), (0, 0, 0, 0))
    entries: list[str] = []
    for index, (char, lines) in enumerate(glyphs.items()):
        x0, y0 = (index % COLUMNS) * cell_w, (index // COLUMNS) * cell_h
        width = len(lines[0])
        for y, line in enumerate(lines):
            for x, ink in enumerate(line):
                if ink == "#":
                    sheet.putpixel((x0 + x, y0 + y), (255, 255, 255, 255))
        codes = [ord(char)] + ([ord(char.lower())] if char.isalpha() else [])
        for code in codes:
            entries.append(f"char id={code} x={x0} y={y0} width={width} height={HEIGHT} "
                           f"xoffset=0 yoffset=1 xadvance={width + 1} page=0 chnl=15")
    entries.append(f"char id=32 x=0 y=0 width=0 height=0 xoffset=0 yoffset=0 xadvance={SPACE_ADVANCE} page=0 chnl=15")
    OUT.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT / "last_edge.png")
    lines = [
        f'info face="Last Edge" size={SIZE} bold=0 italic=0 charset="" unicode=1 stretchH=100 '
        f"smooth=0 aa=1 padding=0,0,0,0 spacing=1,1 outline=0",
        f"common lineHeight={LINE_HEIGHT} base={HEIGHT + 1} scaleW={sheet.width} scaleH={sheet.height} "
        f"pages=1 packed=0",
        'page id=0 file="last_edge.png"',
        f"chars count={len(entries)}",
        *entries,
    ]
    (OUT / "last_edge.fnt").write_text("\n".join(lines) + "\n")
    print("wrote", len(entries), "characters")


if __name__ == "__main__":
    main()
