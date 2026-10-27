class_name SwordTrail
extends Node2D
## A glowing sweep that follows the real blade. Each frame the owner calls add_blade() with
## the blade's base and tip in world space (from the sprite sheet's tracked points). Big
## jumps between sprite poses are filled with an arc around the base, so a 5-frame swing
## still leaves a smooth crescent. Drawn additively in world space; samples fade quickly.
## heat (0..1) shifts the color from fiery amber-orange through yellow to white-hot.

## How long a sample stays visible (seconds, real time).
const LIFETIME := 0.16
## Samples inserted between two poses whose tips are far apart.
const ARC_STEPS := 7
## The sweep covers the blade from this fraction of its length to the tip.
const INNER := 0.35
const COLD := Color(1.0, 0.48, 0.12)
const WARM := Color(1.0, 0.76, 0.32)
const WHITE_HOT := Color(1.0, 0.97, 0.88)
## Above 1.0 so the edge glows through the bloom.
const EDGE_GLOW := 1.6

var heat: float = 0.0

var _samples: Array[Dictionary] = []
var _has_last: bool = false
var _last_base: Vector2
var _last_tip: Vector2


func _ready() -> void:
	top_level = true
	z_index = 5
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive


func add_blade(base: Vector2, tip: Vector2) -> void:
	if _has_last and _last_tip.distance_to(tip) < 0.5:
		return
	if _has_last and _last_tip.distance_to(tip) > 6.0:
		var from_angle := (_last_tip - _last_base).angle()
		var turn := wrapf((tip - base).angle() - from_angle, -PI, PI)
		var from_length := _last_base.distance_to(_last_tip)
		var to_length := base.distance_to(tip)
		for k in range(1, ARC_STEPS):
			var f := float(k) / ARC_STEPS
			var b := _last_base.lerp(base, f)
			_push(b, b + Vector2.from_angle(from_angle + turn * f) * lerpf(from_length, to_length, f))
	_push(base, tip)
	_last_base = base
	_last_tip = tip
	_has_last = true


## Ends the current stroke (the next add_blade() starts a new one).
func stop() -> void:
	_has_last = false


func _push(base: Vector2, tip: Vector2) -> void:
	_samples.append({"inner": base.lerp(tip, INNER), "tip": tip, "age": 0.0, "stroke_start": not _has_last})


func _process(delta: float) -> void:
	var real_delta := delta / maxf(Engine.time_scale, 0.01)
	for sample in _samples:
		sample["age"] = float(sample["age"]) + real_delta
	while not _samples.is_empty() and float(_samples[0]["age"]) > LIFETIME:
		_samples.pop_front()
	queue_redraw()


func _draw() -> void:
	var color := COLD.lerp(WARM, clampf(heat * 2.0, 0.0, 1.0)).lerp(WHITE_HOT, clampf(heat * 2.0 - 1.0, 0.0, 1.0))
	for i in range(1, _samples.size()):
		var a := _samples[i - 1]
		var b := _samples[i]
		if bool(b["stroke_start"]):
			continue
		var fade_a := 1.0 - float(a["age"]) / LIFETIME
		var fade_b := 1.0 - float(b["age"]) / LIFETIME
		var quad := PackedVector2Array([a["inner"], a["tip"], b["tip"], b["inner"]])
		if Geometry2D.triangulate_polygon(quad).is_empty():
			continue # Twisted or flat (the blade crossed itself between samples): skip it.
		var inner_alpha := 0.05
		draw_polygon(quad, PackedColorArray([
			Color(color, fade_a * inner_alpha), Color(color, fade_a * 0.5),
			Color(color, fade_b * 0.5), Color(color, fade_b * inner_alpha),
		]))
		# Bright cutting edge along the tip.
		draw_line(a["tip"], b["tip"], Color(WHITE_HOT * EDGE_GLOW, fade_b), 1.5)
