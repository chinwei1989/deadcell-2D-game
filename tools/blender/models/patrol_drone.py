"""Patrol Drone: a hovering surveillance drone (PLAN.md section 9.1), modeled by script.

    /Applications/Blender.app/Contents/MacOS/Blender -b -P tools/blender/models/patrol_drone.py

Animations match enemies/patrol_drone/patrol_drone.gd: idle (hover), windup (lens charges
from teal to hot red). Frame size 44×36 px at 20 px per unit; origin = center (22, 18).
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import sprite_render as sr  # noqa: E402

sr.reset_scene()

root = sr.pivot("Root", (0.0, 0.0, 0.0))
hull = sr.pivot("Hull", (0.0, 0.0, 0.0), root)
sr.box("Core", (0.62, 0.5, 0.42), (0.0, 0.0, 0.0), "gray", hull)
sr.box("Top", (0.5, 0.46, 0.08), (0.0, 0.0, 0.25), "gray light", hull)
sr.box("Belly", (0.44, 0.44, 0.1), (0.0, 0.0, -0.25), "steel", hull)
sr.box("Visor", (0.12, 0.52, 0.26), (0.32, 0.0, 0.02), "shadow", hull)
lens = sr.box("Lens", (0.08, 0.54, 0.14), (0.37, 0.0, 0.03), "teal light", hull)
sr.box("Antenna", (0.03, 0.03, 0.22), (-0.18, 0.0, 0.38), "steel", hull)
sr.box("Beacon", (0.06, 0.06, 0.06), (-0.18, 0.0, 0.5), "red", hull)
sr.box("Gun", (0.22, 0.12, 0.08), (0.2, 0.0, -0.3), "dark steel", hull)

rotors = []
for name, x in (("Rear", -0.46), ("Front", 0.4)):
    arm = sr.pivot(f"{name}Arm", (x, 0.0, 0.12), hull)
    sr.box(f"{name}Strut", (0.24, 0.08, 0.06), (0.0, 0.0, 0.0), "steel", arm)
    rotor = sr.pivot(f"{name}Rotor", (0.0, 0.0, 0.1), arm)
    sr.box(f"{name}Blade", (0.5, 0.06, 0.03), (0.0, 0.0, 0.0), "gray dark", rotor)
    rotors.append(rotor)

LENS_CHARGE = ["teal light", "amber", "hot", "hot"]


def set_lens(color: str) -> None:
    lens.data.materials[0] = sr.material(color)


def spin_rotors(t: float) -> None:
    # Seen from the side, a spinning blade looks like it grows and shrinks.
    for i, rotor in enumerate(rotors):
        rotor.scale = (0.35 + 0.65 * abs(math.cos((t * 2 + i * 0.25) * math.pi)), 1.0, 1.0)


def idle(t: float) -> None:
    set_lens("teal light")
    hull.location = (0.0, 0.0, 0.04 * sr.wave(t))
    hull.rotation_euler = (0.0, 0.05 * sr.wave(t, 0.25), 0.0)
    spin_rotors(t)


def windup(t: float) -> None:
    set_lens(LENS_CHARGE[min(int(t * len(LENS_CHARGE)), len(LENS_CHARGE) - 1)])
    hull.location = (-0.04 * t, 0.0, 0.0)
    hull.rotation_euler = (0.0, 0.12 * t, 0.0)  # tilts its gun toward the target
    spin_rotors(t * 2)


sr.render_animations(
    "patrol_drone",
    frame_size=(44, 36),
    origin_px=(22, 18),
    pixels_per_unit=20,
    animations={
        "idle": {"frames": 4, "fps": 10, "loop": True, "pose": idle},
        "windup": {"frames": 4, "fps": 6, "loop": False, "pose": windup},
    },
)
