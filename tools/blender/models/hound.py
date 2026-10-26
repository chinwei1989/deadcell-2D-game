"""Hound: a lean robot dog (PLAN.md section 9.1), modeled and animated by script.

    /Applications/Blender.app/Contents/MacOS/Blender -b -P tools/blender/models/hound.py

Animations match the states in enemies/hound/hound.gd: idle, run, windup, lunge, recover,
stagger. Frame size 64×44 px at 22 px per unit; origin = feet center at pixel (32, 42).
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import sprite_render as sr  # noqa: E402

sr.reset_scene()

# Body ----------------------------------------------------------------------------------
root = sr.pivot("Root", (0.0, 0.0, 0.0))
body = sr.pivot("Body", (0.0, 0.0, 0.62), root)
sr.box("Torso", (1.05, 0.42, 0.34), (0.0, 0.0, 0.0), "gray dark", body)
sr.box("Spine", (0.9, 0.3, 0.1), (-0.05, 0.0, 0.2), "steel", body)
sr.box("SpineLight", (0.6, 0.32, 0.04), (-0.05, 0.0, 0.26), "teal dim", body)
sr.box("Belly", (0.7, 0.3, 0.12), (0.0, 0.0, -0.2), "dark steel", body)
sr.box("Haunch", (0.36, 0.44, 0.36), (-0.42, 0.0, -0.02), "gray", body)
sr.box("Shoulder", (0.32, 0.44, 0.34), (0.38, 0.0, 0.0), "gray", body)

neck = sr.pivot("Neck", (0.48, 0.0, 0.12), body)
sr.box("NeckBox", (0.22, 0.24, 0.2), (0.1, 0.0, 0.08), "steel", neck)
head = sr.pivot("Head", (0.22, 0.0, 0.16), neck)
sr.box("Skull", (0.34, 0.3, 0.24), (0.1, 0.0, 0.02), "gray", head)
sr.box("Snout", (0.3, 0.22, 0.14), (0.36, 0.0, -0.05), "gray dark", head)
sr.box("Jaw", (0.26, 0.2, 0.06), (0.3, 0.0, -0.15), "shadow", head)
sr.box("Eye", (0.12, 0.32, 0.08), (0.2, 0.0, 0.06), "teal light", head)
sr.box("Ear", (0.08, 0.1, 0.16), (-0.02, 0.0, 0.2), "steel", head, rotation_y=-0.3)

tail = sr.pivot("Tail", (-0.55, 0.0, 0.1), body)
sr.box("Antenna", (0.36, 0.05, 0.05), (-0.18, 0.0, 0.08), "steel", tail, rotation_y=0.5)
sr.box("TailLight", (0.06, 0.07, 0.06), (-0.34, 0.0, 0.18), "red", tail)

# Legs: hip pivot → thigh → knee pivot → shin → foot. Near legs are brighter than far legs.
LEG = {}
for name, x, y, near in (("FrontNear", 0.36, -0.2, True), ("FrontFar", 0.32, 0.2, False),
                          ("BackNear", -0.4, -0.2, True), ("BackFar", -0.44, 0.2, False)):
    color = "gray light" if near else "gray dark"
    hip = sr.pivot(f"{name}Hip", (x, y, -0.1), body)
    sr.box(f"{name}Thigh", (0.17, 0.12, 0.3), (0.0, 0.0, -0.15), color, hip)
    knee = sr.pivot(f"{name}Knee", (0.0, 0.0, -0.3), hip)
    sr.box(f"{name}Shin", (0.13, 0.1, 0.26), (0.0, 0.0, -0.13), "gray" if near else "steel", knee)
    sr.box(f"{name}Foot", (0.2, 0.12, 0.07), (0.05, 0.0, -0.26), "shadow", knee)
    LEG[name] = (hip, knee)


def legs(phase_front: float, phase_back: float, swing: float, bend: float, t: float) -> None:
    """Gallop-ish cycle: each leg swings with a phase; knees bend on the forward swing."""
    for name, (hip, knee) in LEG.items():
        phase = phase_front if name.startswith("Front") else phase_back
        if name.endswith("Far"):
            phase += 0.15
        s = sr.wave(t, phase)
        hip.rotation_euler = (0.0, s * swing, 0.0)
        knee.rotation_euler = (0.0, -max(0.0, -sr.wave(t, phase + 0.2)) * bend - 0.1, 0.0)


def pose_default() -> None:
    root.location = (0.0, 0.0, 0.0)
    body.location = (0.0, 0.0, 0.62)
    body.rotation_euler = (0.0, 0.0, 0.0)
    neck.rotation_euler = (0.0, -0.2, 0.0)
    head.rotation_euler = (0.0, 0.2, 0.0)
    tail.rotation_euler = (0.0, 0.0, 0.0)


def idle(t: float) -> None:
    pose_default()
    body.location = (0.0, 0.0, 0.62 + 0.015 * sr.wave(t))
    tail.rotation_euler = (0.0, 0.15 * sr.wave(t), 0.0)
    legs(0.0, 0.5, 0.0, 0.0, t)


def run(t: float) -> None:
    pose_default()
    body.location = (0.0, 0.0, 0.6 + 0.05 * abs(sr.wave(t)))
    body.rotation_euler = (0.0, 0.08 * sr.wave(t, 0.25), 0.0)
    neck.rotation_euler = (0.0, 0.05, 0.0)
    tail.rotation_euler = (0.0, -0.3, 0.0)
    legs(0.0, 0.45, 0.65, 1.1, t)


def windup(t: float) -> None:
    pose_default()
    crouch = min(1.0, t * 2.0)
    shake = 0.015 * math.sin(t * 40.0)
    body.location = (-0.08 * crouch + shake, 0.0, 0.62 - 0.16 * crouch)
    body.rotation_euler = (0.0, 0.18 * crouch, 0.0)  # nose down, haunches up
    neck.rotation_euler = (0.0, 0.25 * crouch, 0.0)
    head.rotation_euler = (0.0, -0.2 * crouch, 0.0)
    tail.rotation_euler = (0.0, -0.6 * crouch, 0.0)
    for name, (hip, knee) in LEG.items():
        hip.rotation_euler = (0.0, (0.35 if name.startswith("Back") else -0.25) * crouch, 0.0)
        knee.rotation_euler = (0.0, -0.9 * crouch, 0.0)


def lunge(t: float) -> None:
    pose_default()
    body.location = (0.1, 0.0, 0.66)
    body.rotation_euler = (0.0, -0.2, 0.0)  # stretched forward, nose up
    neck.rotation_euler = (0.0, -0.3, 0.0)
    head.rotation_euler = (0.0, -0.25 + 0.2 * t, 0.0)
    tail.rotation_euler = (0.0, -0.8, 0.0)
    for name, (hip, knee) in LEG.items():
        front = name.startswith("Front")
        hip.rotation_euler = (0.0, -1.1 if front else 1.0, 0.0)
        knee.rotation_euler = (0.0, -0.2, 0.0)


def recover(t: float) -> None:
    run(t * 0.5)
    body.location = (0.0, 0.0, 0.58)
    neck.rotation_euler = (0.0, 0.3 - 0.3 * t, 0.0)


def stagger(t: float) -> None:
    pose_default()
    body.location = (0.0, 0.0, 0.48 + 0.02 * sr.wave(t))
    body.rotation_euler = (0.0, -0.1, 0.0)
    neck.rotation_euler = (0.0, 0.5, 0.0)
    head.rotation_euler = (0.0, 0.35 + 0.1 * sr.wave(t), 0.0)
    tail.rotation_euler = (0.0, 0.5, 0.0)
    for name, (hip, knee) in LEG.items():
        hip.rotation_euler = (0.0, 0.2 if name.startswith("Front") else -0.2, 0.0)
        knee.rotation_euler = (0.0, -0.7, 0.0)


sr.render_animations(
    "hound",
    frame_size=(64, 44),
    origin_px=(32, 42),
    pixels_per_unit=22,
    animations={
        "idle": {"frames": 4, "fps": 6, "loop": True, "pose": idle},
        "run": {"frames": 8, "fps": 14, "loop": True, "pose": run},
        "windup": {"frames": 4, "fps": 10, "loop": False, "pose": windup},
        "lunge": {"frames": 3, "fps": 12, "loop": False, "pose": lunge},
        "recover": {"frames": 4, "fps": 8, "loop": False, "pose": recover},
        "stagger": {"frames": 4, "fps": 6, "loop": True, "pose": stagger},
    },
)
