"""The Warden: HALCYON's riot enforcer and the demo's boss. A hulking armored android with a
riot shield on the far arm and an electric stun baton in the near hand; red visor and core.
Modeled from boxes on a joint hierarchy and posed by script.

    /Applications/Blender.app/Contents/MacOS/Blender -b -P tools/blender/models/warden.py

Frame size 176×152 px at 26 px per unit (the body is ~84 px tall, about twice the hero);
origin = feet center at pixel (88, 146). Animations match the states in enemies/warden/warden.gd.

Angles are degrees in the side view (as in ronin.py): limbs hang down at 0, positive swings
them backward, negative forward; torso/head positive leans forward.
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import sprite_render as sr  # noqa: E402

sr.reset_scene()

ARMOR = "gray"
ARMOR_DARK = "gray dark"
TRIM = "red"

# Skeleton ------------------------------------------------------------------------------
root = sr.pivot("Root", (0.0, 0.0, 0.0))
pelvis = sr.pivot("Pelvis", (0.0, 0.0, 1.42), root)
sr.box("Hips", (0.7, 0.62, 0.3), (0.0, 0.0, 0.0), "dark steel", pelvis)
sr.box("Tasset", (0.5, 0.66, 0.34), (0.12, 0.0, -0.2), ARMOR_DARK, pelvis)

torso = sr.pivot("Torso", (0.0, 0.0, 0.1), pelvis)
sr.box("Chest", (1.0, 0.8, 1.0), (0.0, 0.0, 0.55), ARMOR, torso)
sr.box("ChestPlate", (0.2, 0.84, 0.7), (0.42, 0.0, 0.6), ARMOR_DARK, torso)
sr.box("Core", (0.12, 0.3, 0.22), (0.53, 0.0, 0.62), "hot", torso)
sr.box("CoreRing", (0.08, 0.42, 0.34), (0.5, 0.0, 0.62), "void", torso)
sr.box("Abdomen", (0.7, 0.66, 0.3), (0.05, 0.0, 0.0), "shadow", torso)
sr.box("Backpack", (0.36, 0.7, 0.8), (-0.62, 0.0, 0.62), "dark steel", torso)
sr.box("ExhaustA", (0.12, 0.12, 0.42), (-0.7, -0.18, 1.12), "shadow", torso)
sr.box("ExhaustB", (0.12, 0.12, 0.36), (-0.7, 0.18, 1.08), "shadow", torso)
sr.box("ExhaustTip", (0.14, 0.14, 0.06), (-0.7, -0.18, 1.34), TRIM, torso)

neck = sr.pivot("Neck", (0.12, 0.0, 1.06), torso)
head = sr.pivot("Head", (0.0, 0.0, 0.0), neck)
sr.box("Helmet", (0.46, 0.44, 0.4), (0.0, 0.0, 0.2), ARMOR, head)
sr.box("Crest", (0.4, 0.1, 0.14), (-0.04, 0.0, 0.44), TRIM, head)
sr.box("Faceplate", (0.1, 0.46, 0.3), (0.22, 0.0, 0.16), "dark steel", head)
sr.box("Visor", (0.06, 0.48, 0.07), (0.27, 0.0, 0.22), "red", head)
sr.box("Jaw", (0.3, 0.4, 0.12), (0.1, 0.0, -0.02), "shadow", head)


def limb(prefix: str, attach: tuple, parent_obj, upper: float, lower: float, width: float, color: str,
         color_lower: str):
    top = sr.pivot(f"{prefix}Top", attach, parent_obj)
    sr.box(f"{prefix}Upper", (width, width, upper), (0.0, 0.0, -upper / 2), color, top)
    mid = sr.pivot(f"{prefix}Mid", (0.0, 0.0, -upper), top)
    sr.box(f"{prefix}Lower", (width * 1.05, width * 1.05, lower), (0.0, 0.0, -lower / 2), color_lower, mid)
    return top, mid


far_hip, far_knee = limb("FarLeg", (0.0, 0.22, -0.1), pelvis, 0.68, 0.66, 0.3, "shadow", "dark steel")
sr.box("FarFoot", (0.5, 0.3, 0.14), (0.1, 0.0, -0.68), "void", far_knee)
near_hip, near_knee = limb("NearLeg", (0.0, -0.22, -0.1), pelvis, 0.68, 0.66, 0.32, ARMOR_DARK, ARMOR)
sr.box("NearKneePad", (0.2, 0.36, 0.22), (0.12, 0.0, 0.0), TRIM, near_knee)
sr.box("NearFoot", (0.52, 0.32, 0.15), (0.1, 0.0, -0.68), "shadow", near_knee)

# Far arm: the riot shield.
far_sh, far_el = limb("FarArm", (0.0, 0.48, 0.92), torso, 0.5, 0.48, 0.24, "shadow", "dark steel")
shield = sr.pivot("Shield", (0.18, 0.08, -0.4), far_el)
sr.box("ShieldSlab", (0.12, 0.2, 1.3), (0.0, 0.0, 0.0), "slate", shield)
sr.box("ShieldRim", (0.14, 0.22, 0.1), (0.0, 0.0, 0.62), TRIM, shield)
sr.box("ShieldWindow", (0.14, 0.16, 0.3), (0.02, -0.02, 0.3), "teal dim", shield)
sr.box("ShieldBand", (0.14, 0.22, 0.08), (0.0, 0.0, -0.3), "dark steel", shield)
# Near arm: the stun baton.
near_sh, near_el = limb("NearArm", (0.0, -0.5, 0.92), torso, 0.52, 0.5, 0.26, ARMOR, ARMOR_DARK)
sr.box("Pauldron", (0.62, 0.36, 0.34), (0.0, -0.04, 0.08), ARMOR_DARK, near_sh)
sr.box("PauldronTrim", (0.64, 0.38, 0.08), (0.0, -0.04, 0.24), TRIM, near_sh)
sr.box("Fist", (0.3, 0.3, 0.26), (0.0, 0.0, -0.56), "shadow", near_el)
grip = sr.pivot("Grip", (0.0, 0.0, -0.58), near_el)
BATON = 1.5
sr.box("BatonShaft", (0.1, 0.1, BATON), (0.0, 0.0, -BATON / 2 + 0.2), "shadow", grip)
sr.box("BatonHead", (0.17, 0.17, 0.42), (0.0, 0.0, -BATON + 0.12), "teal", grip)
sr.box("BatonCore", (0.08, 0.19, 0.36), (0.0, 0.0, -BATON + 0.12), "teal light", grip)
sr.box("BatonPommel", (0.16, 0.16, 0.1), (0.0, 0.0, 0.22), TRIM, grip)

JOINTS = {
    "lean": torso, "head": head, "near_hip": near_hip, "near_knee": near_knee, "far_hip": far_hip,
    "far_knee": far_knee, "near_sh": near_sh, "near_el": near_el, "grip": grip, "far_sh": far_sh,
    "far_el": far_el, "shield": shield,
}
DEFAULT = {
    "lean": 4, "head": -4, "near_hip": -10, "near_knee": 14, "far_hip": 12, "far_knee": 10,
    "near_sh": -20, "near_el": -40, "grip": -60, "far_sh": -30, "far_el": -50, "shield": 80,
    "z": 0.0, "x": 0.0,
}


def apply(**pose) -> None:
    p = {**DEFAULT, **pose}
    for name, obj in JOINTS.items():
        obj.rotation_euler = (0.0, math.radians(p[name]), 0.0)
    pelvis.location = (p["x"], 0.0, 1.42 + p["z"])


def blend(*keys: dict):
    """Frames move smoothly through the key poses (evenly spaced, eased)."""
    def pose(t: float) -> None:
        span = t * (len(keys) - 1)
        i = min(int(span), len(keys) - 2)
        u = span - i
        u = u * u * (3 - 2 * u)
        a, b = {**DEFAULT, **keys[i]}, {**DEFAULT, **keys[i + 1]}
        apply(**{k: a[k] + (b[k] - a[k]) * u for k in b})
    return pose


def frames_of(*poses: dict):
    return lambda t: apply(**poses[min(int(t * len(poses) + 1e-6), len(poses) - 1)])


# Animations ----------------------------------------------------------------------------
def idle(t: float) -> None:
    breathe = sr.wave(t)
    apply(z=-0.02 * abs(breathe), lean=4 + 2 * breathe, head=-4 - 2 * breathe, near_el=-40 - 4 * breathe)


def walk(t: float) -> None:
    s = sr.wave(t)
    c = sr.wave(t, 0.25)
    apply(z=-0.06 * abs(c), lean=8, near_hip=-28 * s, far_hip=28 * s,
          near_knee=10 + 30 * max(0.0, s), far_knee=10 + 30 * max(0.0, -s),
          near_sh=-20 + 14 * s, far_sh=-30 - 10 * s, head=-6)


STOMP = dict(near_hip=-30, near_knee=26, far_hip=26, far_knee=14)
sweep_windup = blend(
    dict(STOMP, lean=0, near_sh=-20, near_el=-40, grip=-60),
    dict(STOMP, lean=-10, z=-0.04, near_sh=120, near_el=-30, grip=60, far_sh=-60, far_el=-40, head=4),
    dict(STOMP, lean=-14, z=-0.06, near_sh=150, near_el=-20, grip=50, far_sh=-70, far_el=-30, head=6),
)
sweep = frames_of(
    dict(STOMP, lean=6, z=-0.08, near_sh=220, near_el=-10, grip=0, far_sh=-20, far_el=-60),
    dict(STOMP, lean=20, z=-0.12, near_sh=268, near_el=-4, grip=0, far_sh=10, far_el=-70),
    dict(STOMP, lean=24, z=-0.12, near_sh=300, near_el=-10, grip=-10, far_sh=20, far_el=-70),
    dict(STOMP, lean=20, z=-0.1, near_sh=318, near_el=-20, grip=-20, far_sh=10, far_el=-70),
)
sweep_recover = blend(
    dict(STOMP, lean=20, z=-0.1, near_sh=318, near_el=-20, grip=-20, far_sh=10, far_el=-70),
    dict(lean=6, near_sh=-30, near_el=-40, grip=-50),
)
CROUCH = dict(near_hip=-50, near_knee=60, far_hip=30, far_knee=40, z=-0.2)
charge_windup = blend(
    dict(lean=10, far_sh=-60, far_el=-40, shield=80),
    dict(CROUCH, lean=34, far_sh=-85, far_el=-10, shield=90, near_sh=40, near_el=-20, grip=-40, head=-20),
)
charge = blend(
    dict(CROUCH, lean=38, far_sh=-88, far_el=-6, shield=92, near_sh=40, near_el=-20, grip=-40, head=-24,
         near_hip=-60, far_hip=40),
    dict(lean=36, z=-0.14, near_hip=30, near_knee=50, far_hip=-50, far_knee=30, far_sh=-88, far_el=-6,
         shield=92, near_sh=50, near_el=-20, grip=-40, head=-24),
    dict(CROUCH, lean=38, far_sh=-88, far_el=-6, shield=92, near_sh=40, near_el=-20, grip=-40, head=-24,
         near_hip=-60, far_hip=40),
)
crash = blend(
    dict(lean=-24, z=-0.04, head=24, near_sh=60, near_el=-20, far_sh=40, far_el=-30, shield=60,
         near_hip=10, far_hip=-10),
    dict(lean=-16, z=-0.08, head=14, near_sh=40, near_el=-30, far_sh=30, far_el=-40, shield=70,
         near_hip=-10, near_knee=30, far_hip=10, far_knee=24),
)
slam_windup = blend(
    dict(lean=6, near_sh=-30),
    dict(CROUCH, lean=20, near_sh=-170, near_el=-10, grip=-10, far_sh=-150, far_el=-20, head=-10),
)
slam_air = frames_of(
    dict(lean=-8, near_hip=-40, near_knee=70, far_hip=-20, far_knee=60, near_sh=-185, near_el=-5,
         grip=-10, far_sh=-160, far_el=-10, head=10),
    dict(lean=-10, near_hip=-44, near_knee=74, far_hip=-24, far_knee=64, near_sh=-190, near_el=-5,
         grip=-12, far_sh=-165, far_el=-10, head=12),
)
slam_land = blend(
    dict(near_hip=-70, near_knee=90, far_hip=40, far_knee=60, z=-0.36, lean=40, near_sh=-60, near_el=-10,
         grip=-20, far_sh=-40, far_el=-30, head=-20),
    dict(near_hip=-60, near_knee=80, far_hip=36, far_knee=56, z=-0.3, lean=34, near_sh=-50, near_el=-10,
         grip=-30, far_sh=-40, far_el=-30, head=-14),
    dict(STOMP, lean=10, near_sh=-30, near_el=-40, grip=-50),
)
shoot_windup = blend(
    dict(lean=4, near_sh=-30, near_el=-40, grip=-60),
    dict(STOMP, lean=-4, near_sh=-96, near_el=-4, grip=0, far_sh=-40, far_el=-40, head=-2),
)
shoot = frames_of(
    dict(STOMP, lean=-8, near_sh=-100, near_el=-4, grip=2, far_sh=-40, far_el=-40),
    dict(STOMP, lean=-2, near_sh=-92, near_el=-6, grip=-2, far_sh=-40, far_el=-40),
    dict(STOMP, lean=-8, near_sh=-100, near_el=-4, grip=2, far_sh=-40, far_el=-40),
    dict(STOMP, lean=-2, near_sh=-92, near_el=-6, grip=-2, far_sh=-40, far_el=-40),
)


def stagger(t: float) -> None:
    s = sr.wave(t)
    apply(lean=30 + 3 * s, z=-0.3, near_hip=-60, near_knee=80, far_hip=30, far_knee=70, head=34 + 4 * s,
          near_sh=10, near_el=-10, grip=-20, far_sh=20, far_el=-20, shield=60)


intro = blend(
    dict(lean=4, head=10, near_sh=-20, near_el=-40),
    dict(STOMP, lean=-6, head=-24, near_sh=-150, near_el=-20, grip=-20, far_sh=-50, far_el=-60),
    dict(STOMP, lean=-10, head=-30, near_sh=-160, near_el=-10, grip=-10, far_sh=-60, far_el=-50),
    dict(STOMP, lean=8, head=-4, near_sh=-30, near_el=-40, grip=-60),
)

sr.render_animations(
    "warden",
    frame_size=(176, 152),
    origin_px=(88, 146),
    pixels_per_unit=26,
    animations={
        "idle": {"frames": 4, "fps": 5, "loop": True, "pose": idle},
        "walk": {"frames": 8, "fps": 9, "loop": True, "pose": walk},
        "sweep_windup": {"frames": 4, "fps": 8, "loop": False, "pose": sweep_windup},
        "sweep": {"frames": 4, "fps": 20, "loop": False, "pose": sweep},
        "sweep_recover": {"frames": 3, "fps": 6, "loop": False, "pose": sweep_recover},
        "charge_windup": {"frames": 4, "fps": 7, "loop": False, "pose": charge_windup},
        "charge": {"frames": 6, "fps": 14, "loop": True, "pose": charge},
        "crash": {"frames": 4, "fps": 4, "loop": False, "pose": crash},
        "slam_windup": {"frames": 4, "fps": 8, "loop": False, "pose": slam_windup},
        "slam_air": {"frames": 2, "fps": 8, "loop": True, "pose": slam_air},
        "slam_land": {"frames": 4, "fps": 6, "loop": False, "pose": slam_land},
        "shoot_windup": {"frames": 4, "fps": 8, "loop": False, "pose": shoot_windup},
        "shoot": {"frames": 4, "fps": 12, "loop": True, "pose": shoot},
        "stagger": {"frames": 4, "fps": 5, "loop": True, "pose": stagger},
        "intro": {"frames": 8, "fps": 6, "loop": False, "pose": intro},
    },
)
