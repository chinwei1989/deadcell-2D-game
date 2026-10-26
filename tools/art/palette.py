"""Loads the LAST EDGE palette (palette.gpl) and maps colors onto it."""

from pathlib import Path

PALETTE_PATH = Path(__file__).with_name("palette.gpl")


def load_palette(path: Path = PALETTE_PATH) -> dict[str, tuple[int, int, int]]:
    """Returns {name: (r, g, b)} in file order."""
    colors: dict[str, tuple[int, int, int]] = {}
    for line in path.read_text().splitlines():
        parts = line.split()
        if len(parts) >= 4 and all(p.isdigit() for p in parts[:3]):
            colors[" ".join(parts[3:])] = (int(parts[0]), int(parts[1]), int(parts[2]))
    return colors


def _to_lab(rgb: tuple[int, int, int]) -> tuple[float, float, float]:
    """sRGB → CIE Lab (D65), so nearest-color matching follows perceived difference."""
    def linear(c: float) -> float:
        c /= 255.0
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    r, g, b = (linear(c) for c in rgb)
    x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
    y = 0.2126 * r + 0.7152 * g + 0.0722 * b
    z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883

    def f(t: float) -> float:
        return t ** (1 / 3) if t > 0.008856 else 7.787 * t + 16 / 116

    fx, fy, fz = f(x), f(y), f(z)
    return 116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)


class PaletteMatcher:
    """Nearest palette color for any RGB value (cached)."""

    def __init__(self, colors: list[tuple[int, int, int]]):
        self.colors = colors
        self._labs = [_to_lab(c) for c in colors]
        self._cache: dict[tuple[int, int, int], tuple[int, int, int]] = {}

    def nearest(self, rgb: tuple[int, int, int]) -> tuple[int, int, int]:
        if rgb not in self._cache:
            lab = _to_lab(rgb)
            best = min(range(len(self.colors)), key=lambda i: sum((a - b) ** 2 for a, b in zip(lab, self._labs[i])))
            self._cache[rgb] = self.colors[best]
        return self._cache[rgb]
