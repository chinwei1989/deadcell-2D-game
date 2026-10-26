class_name SpriteSheet
## Builds SpriteFrames from a sheet made by tools/art/make_spritesheet.py: a PNG with one
## row per animation plus a JSON file next to it (frame size, origin, fps, looping).
## Results are cached, so every enemy of a type shares one SpriteFrames.

static var _cache: Dictionary = {}
static var _meta_cache: Dictionary = {}


## png_path: e.g. "res://art/sprites/hound.png" (the JSON must sit next to it).
static func frames(png_path: String) -> SpriteFrames:
	if not _cache.has(png_path):
		_cache[png_path] = _build(png_path)
	return _cache[png_path]


## Drops cached frames and metadata (called on quit so nothing is reported as leaked).
static func clear_cache() -> void:
	_cache.clear()
	_meta_cache.clear()


## The matching normal map sheet (<name>_n.png), or null. Apply it with the sprite shader
## (game/fx/flash.gdshader, `normal_sheet`): wrapping atlas frames in CanvasTextures doesn't
## work, because CanvasTexture ignores the atlas region and always shows the first frame.
static func normal_map(png_path: String) -> Texture2D:
	var normal_path := png_path.get_basename() + "_n.png"
	return load(normal_path) as Texture2D if ResourceLoader.exists(normal_path) else null


## Shader material for a sprite from this sheet: hit-flash tinting plus its normal map.
static func material(png_path: String) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://game/fx/flash.gdshader")
	var normals := normal_map(png_path)
	if normals:
		mat.set_shader_parameter(&"normal_sheet", normals)
		mat.set_shader_parameter(&"use_normals", true)
	return mat


## The pixel in each frame that sits on the node's origin (feet, or center for flyers).
static func origin(png_path: String) -> Vector2:
	var meta := _meta(png_path)
	return Vector2(meta["origin"][0], meta["origin"][1])


## A tracked point (e.g. &"blade_tip") for every frame of an animation, in frame pixels,
## or an empty array if the sheet has no such track.
static func track(png_path: String, animation: StringName, track_name: StringName) -> PackedVector2Array:
	var spec: Dictionary = _meta(png_path)["animations"].get(String(animation), {})
	var points := PackedVector2Array()
	for p: Array in spec.get("tracks", {}).get(String(track_name), []):
		points.append(Vector2(p[0], p[1]))
	return points


## Frame counts of an attack's parts [wind-up, strike, recovery], or empty if the
## animation has none (see "phases" in tools/blender/sprite_render.py).
static func phases(png_path: String, animation: StringName) -> PackedInt32Array:
	var spec: Dictionary = _meta(png_path)["animations"].get(String(animation), {})
	var counts := PackedInt32Array()
	for count: float in spec.get("phases", []):
		counts.append(int(count))
	return counts


static func _meta(png_path: String) -> Dictionary:
	if not _meta_cache.has(png_path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(png_path.get_basename() + ".json"))
		assert(parsed is Dictionary, "Missing or invalid sprite sheet JSON for %s" % png_path)
		_meta_cache[png_path] = parsed
	return _meta_cache[png_path]


static func _build(png_path: String) -> SpriteFrames:
	var meta := _meta(png_path)
	var texture := load(png_path) as Texture2D
	var size := Vector2(meta["frame_size"][0], meta["frame_size"][1])
	var result := SpriteFrames.new()
	result.remove_animation(&"default")
	var animations: Dictionary = meta["animations"]
	for anim: String in animations:
		var spec: Dictionary = animations[anim]
		result.add_animation(anim)
		result.set_animation_speed(anim, float(spec["fps"]))
		result.set_animation_loop(anim, bool(spec["loop"]))
		for i in int(spec["frames"]):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(Vector2(i, int(spec["row"])) * size, size)
			result.add_frame(anim, atlas)
	return result
