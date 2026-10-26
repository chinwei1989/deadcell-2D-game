"""The Ronin (the hero): hooded swordfighter with a mask, warm visor, long coat, trailing
scarf and a katana. Modeled from boxes on a joint hierarchy and posed by script.

    /Applications/Blender.app/Contents/MacOS/Blender -b -P tools/blender/models/ronin.py

Frame size 160×120 px at 22 px per unit (the figure is ~44 px tall; the long katana needs
room to swing). Origin = body center at pixel (80, 72), matching the Player node's origin (feet are 22 px below it).

Angles are in degrees, rotation in the side view:
  - limbs hang down at 0; positive swings them backward (-X), negative forward (+X)
  - torso/head stand up at 0; positive leans forward
  - the blade's direction is shoulder + elbow + wrist: -90 = forward, 90 = backward,
    180 = straight up, 0 = straight down, -135 = forward-up, -45 = forward-down
Animation names match the hero states used by characters/player/player.gd.
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import sprite_render as sr  # noqa: E402

sr.reset_scene()

COAT = "copper"
COAT_LIGHT = "amber"
HOOD = "rust"
sr.COLORS.setdefault("rust dark", (58, 30, 26))
sr.COLORS.setdefault("amber light", (255, 211, 138))
sr.COLORS.setdefault("ember dark", (30, 16, 18))

# Skeleton ------------------------------------------------------------------------------
root = sr.pivot("Root", (0.0, 0.0, 0.0))
pelvis = sr.pivot("Pelvis", (0.0, 0.0, -0.05), root)
sr.box("Hips", (0.3, 0.3, 0.16), (0.0, 0.0, -0.02), "shadow", pelvis)

coat_back = sr.pivot("CoatBack", (-0.06, 0.02, 0.0), pelvis)
sr.box("CoatBackPanel", (0.3, 0.32, 0.62), (-0.02, 0.0, -0.3), COAT, coat_back)
coat_front = sr.pivot("CoatFront", (0.08, -0.17, 0.0), pelvis)
sr.box("CoatFrontPanel", (0.18, 0.04, 0.5), (0.0, 0.0, -0.25), COAT_LIGHT, coat_front)

torso = sr.pivot("Torso", (0.0, 0.0, 0.0), pelvis)
sr.box("Chest", (0.34, 0.32, 0.6), (0.0, 0.0, 0.3), COAT, torso)
sr.box("Lapel", (0.06, 0.34, 0.42), (0.15, 0.0, 0.34), COAT_LIGHT, torso)
sr.box("Belt", (0.36, 0.34, 0.07), (0.0, 0.0, 0.05), "amber", torso)
sr.box("Sheath", (0.08, 0.06, 0.7), (-0.16, 0.2, -0.05), "ember dark", torso, rotation_y=-1.0)

neck = sr.pivot("Neck", (0.02, 0.0, 0.62), torso)
head = sr.pivot("Head", (0.0, 0.0, 0.0), neck)
sr.box("Hood", (0.34, 0.34, 0.34), (-0.02, 0.0, 0.17), HOOD, head)
sr.box("HoodPeak", (0.12, 0.3, 0.1), (0.14, 0.0, 0.33), HOOD, head)
sr.box("Mask", (0.08, 0.3, 0.22), (0.15, 0.0, 0.12), "gray light", head)
sr.box("Visor", (0.04, 0.32, 0.05), (0.2, 0.0, 0.16), "amber light", head)

scarf = []
parent = sr.pivot("Scarf0", (-0.12, 0.0, -0.02), neck)
sr.box("ScarfKnot", (0.2, 0.36, 0.12), (0.06, 0.0, 0.0), "hot", parent)
for i in range(3):
    seg = sr.pivot(f"ScarfJoint{i}", (0.0, 0.0, 0.0) if i == 0 else (0.0, 0.0, -0.22), parent)
    sr.box(f"Scarf{i}", (0.09, 0.08, 0.24), (0.0, 0.0, -0.11), "hot" if i < 2 else "red", seg)
    scarf.append(seg)
    parent = seg


def limb(prefix: str, attach: tuple, parent_obj, upper: float, lower: float, width: float, color: str,
         color_lower: str):
    top = sr.pivot(f"{prefix}Top", attach, parent_obj)
    sr.box(f"{prefix}Upper", (width, width, upper), (0.0, 0.0, -upper / 2), color, top)
    mid = sr.pivot(f"{prefix}Mid", (0.0, 0.0, -upper), top)
    sr.box(f"{prefix}Lower", (width * 0.9, width * 0.9, lower), (0.0, 0.0, -lower / 2), color_lower, mid)
    return top, mid


far_hip, far_knee = limb("FarLeg", (0.0, 0.12, -0.04), pelvis, 0.48, 0.44, 0.15, "shadow", "void")
sr.box("FarBoot", (0.22, 0.12, 0.08), (0.05, 0.0, -0.46), "void", far_knee)
near_hip, near_knee = limb("NearLeg", (0.0, -0.12, -0.04), pelvis, 0.48, 0.44, 0.16, "dark steel", "shadow")
sr.box("NearBoot", (0.23, 0.13, 0.09), (0.05, 0.0, -0.46), "void", near_knee)

far_sh, far_el = limb("FarArm", (0.02, 0.2, 0.55), torso, 0.3, 0.28, 0.12, "rust", "rust")
sr.box("FarHand", (0.1, 0.1, 0.1), (0.0, 0.0, -0.3), "gray dark", far_el)
near_sh, near_el = limb("NearArm", (0.02, -0.2, 0.55), torso, 0.3, 0.28, 0.13, COAT_LIGHT, COAT)
sr.box("NearHand", (0.11, 0.11, 0.11), (0.0, 0.0, -0.3), "gray", near_el)
wrist = sr.pivot("Wrist", (0.0, 0.0, -0.3), near_el)
sr.box("Hilt", (0.07, 0.07, 0.24), (0.0, 0.0, 0.08), "amber", wrist)
sr.box("Guard", (0.16, 0.12, 0.04), (0.0, 0.0, -0.04), "copper", wrist)
# A long katana whose steel glows with heat: amber body, white-hot cutting edge.
BLADE_LENGTH = 1.45
sr.box("Blade", (0.08, 0.04, BLADE_LENGTH), (0.0, 0.0, -0.06 - BLADE_LENGTH / 2), "amber", wrist)
sr.box("Edge", (0.03, 0.05, BLADE_LENGTH - 0.05), (0.045, 0.0, -0.06 - BLADE_LENGTH / 2), "amber light", wrist)
sr.box("Spine", (0.02, 0.05, BLADE_LENGTH - 0.1), (-0.04, 0.0, -0.06 - BLADE_LENGTH / 2), "hot", wrist)
# Tracked points for the game's sword trails (see render_animations(tracks=...)).
blade_base = sr.pivot("BladeBase", (0.0, 0.0, -0.12), wrist)
blade_tip = sr.pivot("BladeTip", (0.0, 0.0, -0.06 - BLADE_LENGTH), wrist)

JOINTS = {
    "lean": torso, "head": head, "near_hip": near_hip, "near_knee": near_knee, "far_hip": far_hip,
    "far_knee": far_knee, "near_sh": near_sh, "near_el": near_el, "wrist": wrist, "far_sh": far_sh,
    "far_el": far_el, "coat": coat_back, "coat_front": coat_front,
}
DEFAULT = {
    "lean": 6, "head": -4, "near_hip": -8, "near_knee": 12, "far_hip": 10, "far_knee": 8,
    "near_sh": -30, "near_el": -40, "wrist": -65, "far_sh": -15, "far_el": -80,
    "coat": 5, "coat_front": 0, "scarf": 25, "scarf_wave": 0.0, "scarf_amp": 12, "z": 0.0, "x": 0.0, "body_rot": 0,
}


def blade(total: float, sh: float, el: float) -> dict:
    """Arm angles plus the wrist angle that points the blade at `total`."""
    return {"near_sh": sh, "near_el": el, "wrist": total - sh - el}


def apply(**pose) -> None:
    p = {**DEFAULT, **pose}
    for name, obj in JOINTS.items():
        obj.rotation_euler = (0.0, math.radians(p[name]), 0.0)
    # Knees bend backward (positive), elbows forward (negative): already in the angle signs.
    pelvis.location = (p["x"], 0.0, -0.05 + p["z"])
    root.rotation_euler = (0.0, math.radians(p["body_rot"]), 0.0)
    # Follow-through: each scarf segment repeats the wave of the one before it a little later
    # and a little wider, so the cloth ripples from the knot to the tip.
    for i, seg in enumerate(scarf):
        base = p["scarf"] if i == 0 else p["scarf"] * 0.15
        ripple = math.sin((p["scarf_wave"] - 0.12 * i) * 2 * math.pi) * p["scarf_amp"] * (1 + 0.6 * i)
        seg.rotation_euler = (0.0, math.radians(base + ripple), 0.0)


def frames_of(*poses: dict):
    """An animation where frame i uses poses[i]."""
    return lambda t: apply(**poses[min(int(t * len(poses) + 1e-6), len(poses) - 1)])


def sword(total: float, sh: float, el: float) -> dict:
    """Sword-arm angles for keyed(). Unlike blade(), these are interpolated as written, so
    use unwrapped angles to pick the way round: e.g. back (90) → up (180) → forward (270)
    swings over the top, while 90 → 0 → -90 would sweep under. The wrist is solved per frame."""
    return {"total": total, "near_sh": sh, "near_el": el}


def ease(u: float, kind: str) -> float:
    if kind == "in":  # Accelerate: a blade gathering speed.
        return u * u
    if kind == "out":  # Decelerate: settling, or coiling up.
        return 1 - (1 - u) ** 2
    if kind == "smooth":
        return u * u * (3 - 2 * u)
    return u


def keyed(*keys: tuple):
    """An animation interpolated between key poses: keys are (frame, pose, ease) with pose made
    with sword() plus any DEFAULT joints; ease ("in", "out", "smooth", "linear") shapes the
    motion from the previous key to this one. Frames between keys are in-betweens, so the
    blade sweeps through its whole arc instead of jumping. The last key sets the frame count."""
    frame_count = keys[-1][0] + 1

    def pose(t: float) -> None:
        i = min(round(t * frame_count), frame_count - 1)
        b = next(k for k in keys if k[0] >= i)
        a = keys[keys.index(b) - 1] if keys.index(b) > 0 else b
        u = 0.0 if b[0] == a[0] else ease((i - a[0]) / (b[0] - a[0]), b[2])
        start, end = {**DEFAULT, **a[1]}, {**DEFAULT, **b[1]}
        p = {k: start[k] + (end[k] - start[k]) * u for k in end}
        p["wrist"] = p.pop("total") - p["near_sh"] - p["near_el"]
        apply(**p)

    pose.frames = frame_count
    return pose


# Animations ----------------------------------------------------------------------------

def idle(t: float) -> None:
    apply(z=-0.02 * (1 + sr.wave(t)) / 2, scarf=25, scarf_wave=t, coat=5 + 2 * sr.wave(t))


def run(t: float) -> None:
    """Ninja sprint: low and leaning hard forward, long gliding strides with bent knees,
    little bounce, katana trailing behind, free arm forward for balance."""
    phase = 2 * math.pi * t
    swing = math.sin(phase)
    forward = math.cos(phase)  # > 0 while the near leg swings forward (knee lifts)
    apply(lean=34 + 3 * math.sin(2 * phase), head=-26, z=-0.15 + 0.035 * abs(forward),
          near_hip=-15 - 46 * swing, near_knee=32 + 72 * max(0.0, forward),
          far_hip=-15 + 46 * swing, far_knee=32 + 72 * max(0.0, -forward),
          **blade(98 + 4 * swing, 58 + 4 * swing, -18), far_sh=-35 - 22 * swing, far_el=-55,
          coat=58 + 9 * math.sin(2 * phase), coat_front=42 + 6 * math.sin(2 * phase + 1.0),
          scarf=100, scarf_wave=2 * t, scarf_amp=16)


def sneak(t: float) -> None:
    """Half run, half walk: a deep crouch with short quick steps, blade held low and ready."""
    phase = 2 * math.pi * t
    swing = math.sin(phase)
    forward = math.cos(phase)
    apply(lean=24, head=-16, z=-0.24 + 0.02 * abs(forward),
          near_hip=-25 - 26 * swing, near_knee=55 + 45 * max(0.0, forward),
          far_hip=-25 + 26 * swing, far_knee=55 + 45 * max(0.0, -forward),
          **blade(-118 + 6 * swing, -30, -55), far_sh=-25 + 10 * swing, far_el=-75,
          coat=24 + 5 * math.sin(2 * phase), coat_front=16, scarf=55, scarf_wave=t, scarf_amp=10)


def dodge(t: float) -> None:
    """A tucked forward roll: crouch, full spin, come up ready."""
    spin = min(1.0, max(0.0, (t - 0.1) / 0.75))
    eased = spin * spin * (3 - 2 * spin)
    tuck = math.sin(math.pi * min(1.0, t / 0.9))
    apply(body_rot=360 * eased, z=-0.35 * tuck - 0.05, lean=20 + 50 * tuck, head=10 * tuck,
          near_hip=-30 - 80 * tuck, near_knee=40 + 90 * tuck, far_hip=-20 - 80 * tuck, far_knee=40 + 90 * tuck,
          **blade(100 - 20 * tuck, 40, -10), far_sh=-40 - 50 * tuck, far_el=-90,
          coat=30 + 40 * tuck, coat_front=20 + 30 * tuck, scarf=90 + 40 * tuck, scarf_wave=t, scarf_amp=20)


def flip(t: float) -> None:
    """Double jump: a ninja front flip with the blade held out."""
    eased = t * t * (3 - 2 * t)
    tuck = math.sin(math.pi * t)
    apply(body_rot=360 * eased, lean=15 + 30 * tuck, head=10 * tuck,
          near_hip=-30 - 70 * tuck, near_knee=40 + 80 * tuck, far_hip=-15 - 70 * tuck, far_knee=35 + 80 * tuck,
          **blade(-100, -70, -20), far_sh=-60 - 40 * tuck, far_el=-60,
          coat=-20 + 60 * tuck, coat_front=-10 + 40 * tuck, scarf=150, scarf_wave=t, scarf_amp=22)


jump = frames_of(
    dict(lean=10, near_hip=-55, near_knee=85, far_hip=-20, far_knee=60, **blade(-130, -60, -30), far_sh=-40,
         far_el=-60, coat=-10, coat_front=-15, scarf=110, z=0.05),
    dict(lean=8, near_hip=-45, near_knee=70, far_hip=-15, far_knee=55, **blade(-135, -55, -35), far_sh=-35,
         far_el=-60, coat=-5, coat_front=-10, scarf=115, z=0.05),
)
fall = frames_of(
    dict(lean=4, near_hip=-18, near_knee=35, far_hip=14, far_knee=25, **blade(-120, -70, -10), far_sh=-80,
         far_el=-20, coat=55, coat_front=45, scarf=160),
    dict(lean=4, near_hip=-14, near_knee=30, far_hip=18, far_knee=28, **blade(-115, -75, -10), far_sh=-85,
         far_el=-20, coat=62, coat_front=50, scarf=165, scarf_wave=0.5),
)
wall_slide = frames_of(
    dict(lean=-4, near_hip=-30, near_knee=60, far_hip=-5, far_knee=40, **blade(60, 25, -10), far_sh=-110,
         far_el=0, coat=30, scarf=150, z=0.03),
    dict(lean=-4, near_hip=-28, near_knee=58, far_hip=-6, far_knee=42, **blade(60, 25, -10), far_sh=-112,
         far_el=0, coat=34, scarf=155, z=0.03, scarf_wave=0.5),
)
hang = frames_of(
    dict(lean=-6, head=8, near_hip=4, near_knee=10, far_hip=-6, far_knee=14, **blade(30, -170, 0),
         far_sh=-172, far_el=0, coat=0, scarf=10),
    dict(lean=-6, head=8, near_hip=6, near_knee=14, far_hip=-4, far_knee=12, **blade(32, -168, 0),
         far_sh=-170, far_el=0, coat=3, scarf=14, scarf_wave=0.5),
)
STANCE = dict(near_hip=-30, near_knee=22, far_hip=28, far_knee=10)
DEEP = dict(near_hip=-46, near_knee=48, far_hip=41, far_knee=21)
TUCK = dict(near_hip=-40, near_knee=70, far_hip=-10, far_knee=50)
# Attacks: 3 parts, rendered with in-betweens (see keyed()); the "phases" in the render list
# give the frame count of each part: wind-up (coil, slow in), strike (the blade sweeps the
# whole arc at an even speed), recovery (overshoot, then settle back toward guard).

# Diagonal cut from over the shoulder: arms swing back → up → forward over the top.
slash1 = keyed(
    (0, dict(lean=2, **STANCE, **sword(120, 45, -10), far_sh=-20, far_el=-70, coat=8, scarf=40), "linear"),
    (2, dict(lean=-5, **STANCE, **sword(152, 62, -5), far_sh=-8, far_el=-60, coat=10, scarf=45), "out"),
    (3, dict(lean=6, **STANCE, **sword(205, 150, -10), far_sh=0, far_el=-50, coat=14, scarf=52), "linear"),
    (5, dict(lean=24, **STANCE, **sword(320, 300, -10), far_sh=35, far_el=-30, coat=30, coat_front=20,
             scarf=75), "linear"),
    (6, dict(lean=26, **STANCE, **sword(334, 306, -8), far_sh=36, far_el=-30, coat=32, coat_front=22,
             scarf=82, scarf_wave=0.2), "out"),
    (9, dict(lean=12, **STANCE, **sword(240, 315, -40), far_sh=-10, far_el=-70, coat=15, scarf=50,
             scarf_wave=0.6), "smooth"),
)
# Rising cut: the blade comes up from low forward, through forward, to straight up and past.
slash2 = keyed(
    (0, dict(lean=12, **STANCE, **sword(-60, -55, -30), far_sh=-10, far_el=-60, coat=12, scarf=50), "linear"),
    (2, dict(lean=18, **STANCE, **sword(-25, -45, -5), far_sh=25, far_el=-40, coat=20, scarf=58), "out"),
    (3, dict(lean=14, **STANCE, **sword(-72, -82, -10), far_sh=0, far_el=-36, coat=17, scarf=62), "linear"),
    (5, dict(lean=2, **STANCE, **sword(-195, -170, -10), far_sh=-50, far_el=-20, coat=8, scarf=72), "linear"),
    (6, dict(lean=0, **STANCE, **sword(-206, -176, -8), far_sh=-52, far_el=-20, coat=6, scarf=76,
             scarf_wave=0.2), "out"),
    (9, dict(lean=8, **STANCE, **sword(-130, -60, -30), far_sh=-15, far_el=-70, coat=10, scarf=50,
             scarf_wave=0.6), "smooth"),
)
# Finisher: a leaping overhead chop, landing in a deep stance.
slash3 = keyed(
    (0, dict(lean=-2, **STANCE, **sword(150, -120, -20), far_sh=-120, far_el=-30, coat=6, scarf=40), "linear"),
    (3, dict(lean=-14, z=0.05, **STANCE, **sword(182, -168, -5), far_sh=-168, far_el=-8, coat=0, scarf=34),
     "out"),
    (4, dict(lean=4, z=0.02, **STANCE, **sword(220, -140, -5), far_sh=-130, far_el=-10, coat=10, scarf=50),
     "linear"),
    (6, dict(lean=34, z=-0.16, **DEEP, **sword(340, -40, -5), far_sh=-40, far_el=-30, coat=45, coat_front=35,
             scarf=100), "linear"),
    (7, dict(lean=30, z=-0.14, **DEEP, **sword(336, -40, -5), far_sh=-38, far_el=-30, coat=40,
             coat_front=30, scarf=96, scarf_wave=0.2), "out"),
    (11, dict(lean=12, z=-0.04, **STANCE, **sword(250, -45, -40), far_sh=-15, far_el=-70, coat=15, scarf=50,
              scarf_wave=0.7), "smooth"),
)
slash_up = keyed(
    (0, dict(lean=8, **STANCE, **sword(-50, -35, -20), far_sh=-10, far_el=-60, coat=10, scarf=45), "linear"),
    (1, dict(lean=12, z=-0.03, **STANCE, **sword(-30, -25, -10), far_sh=0, far_el=-55, coat=12, scarf=48),
     "out"),
    (2, dict(lean=4, **STANCE, **sword(-95, -105, -10), far_sh=-30, far_el=-45, coat=12, scarf=60), "linear"),
    (4, dict(lean=-8, z=0.03, **STANCE, **sword(-200, -178, -5), far_sh=-65, far_el=-25, coat=16, scarf=82),
     "linear"),
    (5, dict(lean=-9, z=0.03, **STANCE, **sword(-214, -176, -10), far_sh=-70, far_el=-20, coat=18, scarf=86,
             scarf_wave=0.2), "out"),
    (8, dict(lean=6, **STANCE, **sword(-130, -60, -30), far_sh=-20, far_el=-70, coat=10, scarf=50,
             scarf_wave=0.6), "smooth"),
)
slash_down = keyed(
    (0, dict(lean=0, **TUCK, **sword(-120, -90, -20), far_sh=-40, far_el=-40, coat=20, scarf=118), "linear"),
    (1, dict(lean=-6, **TUCK, **sword(-160, -130, -10), far_sh=-60, far_el=-30, coat=18, scarf=122), "out"),
    (2, dict(lean=4, **TUCK, **sword(-105, -88, -5), far_sh=-35, far_el=-35, coat=24, scarf=126), "linear"),
    (4, dict(lean=16, **TUCK, **sword(22, -4, 5), far_sh=8, far_el=-40, coat=32, scarf=134), "linear"),
    (5, dict(lean=16, **TUCK, **sword(32, 2, 5), far_sh=10, far_el=-40, coat=32, scarf=135,
             scarf_wave=0.2), "out"),
    (8, dict(lean=6, near_hip=-30, near_knee=60, far_hip=-10, far_knee=45, **sword(-90, -60, -20), far_sh=-30,
             far_el=-50, coat=25, scarf=120, scarf_wave=0.6), "smooth"),
)
PARRY_POSE = dict(lean=6, z=-0.04, near_hip=-25, near_knee=30, far_hip=25, far_knee=20,
                  **blade(-178, -70, -60), far_sh=-75, far_el=-55, coat=8, scarf=40)
parry = frames_of(
    dict(PARRY_POSE, **blade(-165, -55, -70), lean=10),
    PARRY_POSE,
)
guard = frames_of(
    dict(PARRY_POSE, z=-0.08, near_knee=40, scarf=30),
    dict(PARRY_POSE, z=-0.08, near_knee=40, scarf=32, scarf_wave=0.5),
)
DRAW_POSE = dict(lean=24, z=-0.16, near_hip=-45, near_knee=60, far_hip=40, far_knee=30,
                 **blade(70, 30, -20), far_sh=20, far_el=-90, coat=20, coat_front=15, scarf=60)
draw_charge = frames_of(
    DRAW_POSE,
    dict(DRAW_POSE, z=-0.17, scarf=64, scarf_wave=0.5),
)
LUNGE = dict(near_hip=-70, near_knee=30, far_hip=60, far_knee=20)
# Quick-draw: the blade leaves the sheath low and forward, cuts through, and keeps rising
# over the top to end behind the dashing hero.
draw_strike = keyed(
    (0, dict(lean=45, z=-0.22, **LUNGE, **sword(-55, -60, 0), far_sh=60, far_el=-10, coat=66, coat_front=50,
             scarf=105), "linear"),
    (1, dict(lean=45, z=-0.22, **LUNGE, **sword(-95, -92, 0), far_sh=60, far_el=-10, coat=70, coat_front=55,
             scarf=110), "linear"),
    (3, dict(lean=40, z=-0.2, near_hip=-65, near_knee=35, far_hip=58, far_knee=25, **sword(-250, -300, 10),
             far_sh=55, far_el=-20, coat=72, coat_front=55, scarf=115), "out"),
    (6, dict(lean=15, z=-0.06, **STANCE, **sword(-260, -315, 5), far_sh=10, far_el=-60, coat=30, scarf=70,
             scarf_wave=0.6), "smooth"),
)
slam = frames_of(
    dict(lean=20, near_hip=-70, near_knee=100, far_hip=-50, far_knee=90, **blade(5, -10, 0), far_sh=-20,
         far_el=-20, coat=-30, coat_front=-30, scarf=170),
    dict(lean=22, near_hip=-72, near_knee=105, far_hip=-52, far_knee=95, **blade(2, -10, 0), far_sh=-22,
         far_el=-18, coat=-35, coat_front=-35, scarf=172, scarf_wave=0.5),
)
slam_land = frames_of(
    dict(lean=40, z=-0.3, near_hip=-80, near_knee=100, far_hip=50, far_knee=60, **blade(-25, -40, -5),
         far_sh=-30, far_el=-30, coat=50, coat_front=40, scarf=60),
    dict(lean=30, z=-0.22, near_hip=-70, near_knee=90, far_hip=45, far_knee=55, **blade(-30, -40, -5),
         far_sh=-30, far_el=-30, coat=40, coat_front=30, scarf=50),
)
CUT_POSE = dict(lean=30, z=-0.3, near_hip=-80, near_knee=110, far_hip=40, far_knee=100,
                **blade(70, 35, -10), far_sh=-85, far_el=-15, coat=25, scarf=40)
cut_link = frames_of(
    CUT_POSE,
    dict(CUT_POSE, far_sh=-80, far_el=-25, scarf_wave=0.5),
)
hurt = frames_of(
    dict(lean=-22, head=18, near_hip=10, near_knee=25, far_hip=-15, far_knee=20, **blade(60, 35, -10),
         far_sh=40, far_el=-30, coat=-10, scarf=10),
    dict(lean=-14, head=10, near_hip=5, near_knee=20, far_hip=-10, far_knee=15, **blade(70, 30, -10),
         far_sh=30, far_el=-40, coat=0, scarf=20),
)
dead = frames_of(
    dict(lean=-22, head=18, near_hip=10, near_knee=25, far_hip=-15, far_knee=20, **blade(60, 35, -10),
         far_sh=40, far_el=-30, coat=-10, scarf=10),
    dict(lean=20, z=-0.4, near_hip=-80, near_knee=120, far_hip=-60, far_knee=110, **blade(40, 30, 0),
         far_sh=10, far_el=-30, coat=30, scarf=20),
    dict(lean=55, z=-0.55, near_hip=-85, near_knee=125, far_hip=-70, far_knee=115, **blade(20, 20, 0),
         far_sh=20, far_el=-10, coat=50, scarf=30),
    dict(body_rot=-90, z=-0.95, x=0.0, lean=0, near_hip=-10, near_knee=20, far_hip=-5, far_knee=15,
         **blade(-80, -80, 0), far_sh=-60, far_el=-10, coat=0, scarf=0),
)

sr.render_animations(
    "ronin",
    frame_size=(160, 120),
    origin_px=(80, 72),
    pixels_per_unit=22,
    tracks={"blade_base": blade_base, "blade_tip": blade_tip},
    animations={
        "idle": {"frames": 4, "fps": 6, "loop": True, "pose": idle},
        "run": {"frames": 12, "fps": 18, "loop": True, "pose": run},
        "sneak": {"frames": 8, "fps": 10, "loop": True, "pose": sneak},
        "jump": {"frames": 2, "fps": 8, "loop": True, "pose": jump},
        "fall": {"frames": 2, "fps": 8, "loop": True, "pose": fall},
        "wall_slide": {"frames": 2, "fps": 6, "loop": True, "pose": wall_slide},
        "hang": {"frames": 2, "fps": 4, "loop": True, "pose": hang},
        "dodge": {"frames": 8, "fps": 24, "loop": False, "pose": dodge},
        "flip": {"frames": 8, "fps": 22, "loop": False, "pose": flip},
        "slash1": {"frames": slash1.frames, "fps": 18, "loop": False, "pose": slash1, "phases": (4, 2, 4)},
        "slash2": {"frames": slash2.frames, "fps": 18, "loop": False, "pose": slash2, "phases": (3, 3, 4)},
        "slash3": {"frames": slash3.frames, "fps": 16, "loop": False, "pose": slash3, "phases": (5, 2, 5)},
        "slash_up": {"frames": slash_up.frames, "fps": 16, "loop": False, "pose": slash_up, "phases": (2, 3, 4)},
        "slash_down": {"frames": slash_down.frames, "fps": 16, "loop": False, "pose": slash_down, "phases": (2, 3, 4)},
        "parry": {"frames": 2, "fps": 16, "loop": False, "pose": parry},
        "guard": {"frames": 2, "fps": 4, "loop": True, "pose": guard},
        "draw_charge": {"frames": 2, "fps": 8, "loop": True, "pose": draw_charge},
        "draw_strike": {"frames": draw_strike.frames, "fps": 14, "loop": False, "pose": draw_strike},
        "slam": {"frames": 2, "fps": 12, "loop": True, "pose": slam},
        "slam_land": {"frames": 2, "fps": 10, "loop": False, "pose": slam_land},
        "cut_link": {"frames": 2, "fps": 4, "loop": True, "pose": cut_link},
        "hurt": {"frames": 2, "fps": 10, "loop": False, "pose": hurt},
        "dead": {"frames": 4, "fps": 6, "loop": False, "pose": dead},
    },
)
