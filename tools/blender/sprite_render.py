"""Shared helpers for rendering scripted 3D models into pixel-art frames with Blender
(PLAN.md section 30.3). Runs inside Blender's Python, e.g.:

    /Applications/Blender.app/Contents/MacOS/Blender -b -P tools/blender/models/hound.py

Each model script builds its meshes with these helpers, defines poses per animation, and
calls render_animations(). Frames go to tools/blender/out/<name>/<anim>_<i>.png; then
tools/art/make_spritesheet.py packs and palette-maps them into art/sprites/.

Conventions:
- Side view: the character faces +X (right); Z is up. 1 Blender unit = PIXELS_PER_UNIT px.
- The origin (0, 0, 0) is the point the game places on the ground (feet) or the center
  for flying enemies; the camera is framed so it lands on a known pixel (see frame_spec).
"""

import json
import math
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "tools" / "blender" / "out"
PIXELS_PER_UNIT = 16

# Subset of tools/art/palette.gpl used for model materials (final colors are re-mapped to
# the palette after rendering, so shading tones snap to palette steps).
COLORS = {
    "void": (11, 22, 32), "shadow": (18, 34, 46), "dark steel": (23, 44, 52), "steel": (31, 58, 68),
    "slate": (45, 85, 96), "teal dim": (63, 122, 128), "teal": (79, 209, 197), "teal light": (141, 232, 223),
    "gray dark": (92, 111, 122), "gray": (138, 161, 173), "gray light": (195, 208, 214),
    "rust": (107, 47, 34), "copper": (180, 81, 46), "red": (214, 69, 69), "hot": (255, 90, 54),
    "amber": (242, 165, 65),
}


def reset_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "MATERIAL"
    scene.display.shading.show_cavity = False
    scene.display.shading.show_shadows = False
    scene.display.shading.show_specular_highlight = False
    scene.display.render_aa = "OFF"
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"


def material(name: str) -> bpy.types.Material:
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name)
        r, g, b = (c / 255.0 for c in COLORS[name])
        # Workbench MATERIAL color uses the viewport display color (linear values).
        mat.diffuse_color = (_srgb_to_linear(r), _srgb_to_linear(g), _srgb_to_linear(b), 1.0)
    return mat


def _srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def pivot(name: str, location: tuple, parent: bpy.types.Object | None = None) -> bpy.types.Object:
    """An empty used as a joint: rotate it around Y to swing its children in the side view."""
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    obj.location = location
    return obj


def box(name: str, size: tuple, location: tuple, color: str, parent: bpy.types.Object | None = None,
        rotation_y: float = 0.0) -> bpy.types.Object:
    """A box of `size` (x, y, z) centered at `location` (relative to parent)."""
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = size
    bpy.ops.object.transform_apply(scale=True)
    # Rounded edges: smoother shading, and angled normals so 2D lights can rim the edges.
    bevel = obj.modifiers.new("Bevel", "BEVEL")
    bevel.width = min(size) * 0.3
    bevel.segments = 3
    bpy.ops.object.shade_smooth()
    obj.parent = parent
    obj.location = location
    obj.rotation_euler = (0.0, rotation_y, 0.0)
    obj.data.materials.append(material(color))
    return obj


def cylinder(name: str, radius: float, depth: float, location: tuple, color: str,
             parent: bpy.types.Object | None = None, axis: str = "Y", vertices: int = 10) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, vertices=vertices)
    obj = bpy.context.active_object
    obj.name = name
    if axis == "Y":
        obj.rotation_euler = (math.pi / 2, 0.0, 0.0)
    elif axis == "X":
        obj.rotation_euler = (0.0, math.pi / 2, 0.0)
    bpy.ops.object.transform_apply(rotation=True)
    obj.parent = parent
    obj.location = location
    obj.data.materials.append(material(color))
    return obj


def setup_camera(width_px: int, height_px: int, origin_px: tuple, pixels_per_unit: float = PIXELS_PER_UNIT) -> None:
    """Orthographic side camera. origin_px = pixel (from the top-left) where the world
    origin appears in every frame."""
    scene = bpy.context.scene
    scene.render.resolution_x = width_px
    scene.render.resolution_y = height_px
    scene.render.resolution_percentage = 100
    cam_data = bpy.data.cameras.new("Camera")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = max(width_px, height_px) / pixels_per_unit
    cam = bpy.data.objects.new("Camera", cam_data)
    bpy.context.collection.objects.link(cam)
    # Camera looks along +Y at the XZ plane. Shift it so the origin lands on origin_px.
    center_x = (width_px / 2 - origin_px[0]) / pixels_per_unit
    center_z = (origin_px[1] - height_px / 2) / pixels_per_unit
    cam.location = (center_x, -20.0, center_z)
    cam.rotation_euler = (math.pi / 2, 0.0, 0.0)
    scene.camera = cam


def _render_normals(path: Path) -> None:
    """Renders the current pose as a normal map: Blender's 'check_normal+y' matcap encodes
    the surface direction as color (+Y up, OpenGL style), written without any color
    transform so the values stay linear."""
    scene = bpy.context.scene
    shading = scene.display.shading
    saved = (shading.light, shading.color_type, scene.view_settings.view_transform)
    shading.light = "MATCAP"
    shading.studio_light = "check_normal+y.exr"
    shading.color_type = "SINGLE"
    shading.single_color = (1.0, 1.0, 1.0)
    scene.view_settings.view_transform = "Raw"
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    shading.light, shading.color_type, scene.view_settings.view_transform = saved


def render_animations(name: str, frame_size: tuple, origin_px: tuple, animations: dict,
                      pixels_per_unit: float = PIXELS_PER_UNIT, tracks: dict | None = None,
                      normals: bool = True) -> None:
    """animations: {anim_name: {"frames": n, "fps": f, "loop": bool, "pose": fn(t)}} where
    pose(t) sets the model for t in [0, 1). Writes frames + a meta.json for make_spritesheet.py.
    An optional "phases": [wind-up, strike, recovery] frame counts is passed through, so the
    game can show each part of an attack during the matching frame-data phase.

    tracks: {track_name: object}. The pixel position of each object is recorded for every
    frame (e.g. the blade's hilt and tip, so the game can draw trails along the real blade)."""
    out = OUT_DIR / name
    out.mkdir(parents=True, exist_ok=True)
    for old in out.glob("*.png"):
        old.unlink()
    setup_camera(frame_size[0], frame_size[1], origin_px, pixels_per_unit)
    meta = {"name": name, "frame_size": list(frame_size), "origin": list(origin_px), "animations": {},
            "normals": normals}
    for anim, spec in animations.items():
        recorded = {track: [] for track in (tracks or {})}
        for i in range(spec["frames"]):
            spec["pose"](i / spec["frames"])
            bpy.context.view_layer.update()
            bpy.context.scene.render.filepath = str(out / f"{anim}_{i:02d}.png")
            bpy.ops.render.render(write_still=True)
            if normals:
                _render_normals(out / f"{anim}_{i:02d}_n.png")
            for track, obj in (tracks or {}).items():
                world = obj.matrix_world.translation
                recorded[track].append([round(origin_px[0] + world.x * pixels_per_unit, 2),
                                        round(origin_px[1] - world.z * pixels_per_unit, 2)])
        meta["animations"][anim] = {"frames": spec["frames"], "fps": spec["fps"], "loop": spec["loop"]}
        if "phases" in spec:
            assert sum(spec["phases"]) == spec["frames"], f"{anim}: phases must add up to frames"
            meta["animations"][anim]["phases"] = list(spec["phases"])
        if recorded:
            meta["animations"][anim]["tracks"] = recorded
    (out / "meta.json").write_text(json.dumps(meta, indent=2))
    print(f"rendered {name}: " + ", ".join(f"{a}×{s['frames']}" for a, s in animations.items()))


def wave(t: float, phase: float = 0.0) -> float:
    """sin over one loop, for cyclic animations."""
    return math.sin((t + phase) * 2 * math.pi)
