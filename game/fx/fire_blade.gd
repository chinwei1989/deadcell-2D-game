class_name FireBlade
extends Node2D
## The burning katana. The owner calls set_blade() every frame with the blade's base and tip
## in world space (from the sprite sheet's tracks), or hide_blade().
##
## Layers, back to front:
##   smoke       a few dark wisps rising off the flames
##   flames      soft fire licking upward along the whole blade (always on)
##   swing fire  bigger, longer-lived flames shed while swinging: each swing leaves a
##               burning arc in the air (particles stay where they were emitted)
##   embers      bright sparks drifting up
##   glow        heat haze + molten core drawn along the blade (core glows through bloom)
##   firelight   a flickering light that lights the hero and the surroundings
## `intensity` (0..1) is raised while attacking and by combo heat.

const OUTER := Color(1.0, 0.42, 0.08)
const MIDDLE := Color(1.0, 0.62, 0.18)
const CORE := Color(1.0, 0.86, 0.55)
const CORE_GLOW := 1.8
## Flames are emitted from points spread along the blade (from base toward tip).
const FLAME_POINTS := 14
## Kept for tests and older callers: ember emission points match the flame points.
const EMBER_POINTS := FLAME_POINTS

## 0..1: how hard the blade is burning right now.
var intensity: float = 0.0

var _base: Vector2
var _tip: Vector2
var _visible_blade: bool = false
var _time: float = 0.0
var _flames: CPUParticles2D
var _swing_fire: CPUParticles2D
var _smoke: CPUParticles2D
var _embers: CPUParticles2D
var _light: PointLight2D


func _ready() -> void:
	top_level = true
	z_index = 4
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = additive
	_smoke = _make_smoke()
	add_child(_smoke)
	_flames = _make_flames(additive, 90, 0.32, 0.055, 0.085, 30.0)
	add_child(_flames)
	_swing_fire = _make_flames(additive, 140, 0.45, 0.07, 0.12, 20.0)
	add_child(_swing_fire)
	_embers = _make_embers(additive)
	add_child(_embers)
	_light = _make_light()
	add_child(_light)


func set_blade(base: Vector2, tip: Vector2) -> void:
	_base = base
	_tip = tip
	_visible_blade = true
	var points := PackedVector2Array()
	for i in FLAME_POINTS:
		points.append((tip - base) * lerpf(0.12, 1.0, float(i) / (FLAME_POINTS - 1)))
	for emitter in _emitters():
		if emitter:
			emitter.global_position = base
			emitter.emission_points = points
			emitter.emitting = true
	if _swing_fire:
		_swing_fire.emitting = intensity > 0.5
	_light.global_position = base.lerp(tip, 0.55)
	_light.visible = true


func hide_blade() -> void:
	_visible_blade = false
	for emitter in _emitters():
		if emitter:
			emitter.emitting = false
	_light.visible = false


func _emitters() -> Array[CPUParticles2D]:
	return [_flames, _swing_fire, _smoke, _embers]


func _process(delta: float) -> void:
	_time += delta / maxf(Engine.time_scale, 0.01)
	_embers.initial_velocity_max = 40.0 + 60.0 * intensity # Swinging flings embers further.
	_flames.scale_amount_max = 0.085 + 0.03 * intensity
	_light.energy = (1.1 + 0.7 * intensity) * (0.8 + 0.2 * _flicker(1.3))
	_light.texture_scale = 1.1 + 0.4 * intensity
	queue_redraw()


func _draw() -> void:
	if not _visible_blade:
		return
	var flicker := _flicker(0.0)
	var boost := 1.0 + 0.6 * intensity
	var along := _tip - _base
	var lick := Vector2(0.0, -2.0 * flicker) # Heat rises.
	draw_line(_base + along * 0.1 + lick, _tip + lick, Color(OUTER, 0.22 * boost), 10.0 + 3.0 * flicker)
	draw_line(_base + along * 0.08, _tip, Color(MIDDLE, 0.5 * boost), 4.5 + flicker)
	draw_line(_base + along * 0.12, _tip - along.normalized(), CORE * (CORE_GLOW * (0.9 + 0.2 * flicker)), 1.5)


## Smooth pseudo-random flicker in about -1..1.
func _flicker(seed_offset: float) -> float:
	var t := _time + seed_offset
	return 0.6 * sin(t * 23.0) + 0.4 * sin(t * 37.0 + 1.7)


## Soft fire: blobs that start white-hot and small, swell, turn orange then red, and fade
## as they rise. Particles stay in the world (local_coords off), so a moving blade leaves fire.
func _make_flames(additive: CanvasItemMaterial, amount: int, lifetime: float, scale_min: float,
		scale_max: float, rise_speed: float) -> CPUParticles2D:
	var flames := CPUParticles2D.new()
	flames.local_coords = false
	flames.amount = amount
	flames.lifetime = lifetime
	flames.texture = LevelLight.radial_texture()
	flames.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINTS
	flames.direction = Vector2.UP
	flames.spread = 25.0
	flames.gravity = Vector2(0.0, -170.0)
	flames.initial_velocity_min = 8.0
	flames.initial_velocity_max = rise_speed
	flames.damping_min = 20.0
	flames.damping_max = 40.0
	flames.scale_amount_min = scale_min
	flames.scale_amount_max = scale_max
	var size := Curve.new()
	size.add_point(Vector2(0.0, 0.35))
	size.add_point(Vector2(0.25, 1.0))
	size.add_point(Vector2(1.0, 0.15))
	flames.scale_amount_curve = size
	var ramp := Gradient.new()
	ramp.set_color(0, CORE * 1.7)
	ramp.set_color(1, Color(0.35, 0.04, 0.0, 0.0))
	ramp.add_point(0.25, MIDDLE * 1.35) # After the ends: add_point() re-sorts indexes.
	ramp.add_point(0.6, Color(0.95, 0.28, 0.05, 0.75))
	flames.color_ramp = ramp
	flames.material = additive
	return flames


func _make_smoke() -> CPUParticles2D:
	var smoke := CPUParticles2D.new()
	smoke.local_coords = false
	smoke.amount = 16
	smoke.lifetime = 0.9
	smoke.texture = LevelLight.radial_texture()
	smoke.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINTS
	smoke.direction = Vector2.UP
	smoke.spread = 20.0
	smoke.gravity = Vector2(0.0, -60.0)
	smoke.initial_velocity_min = 10.0
	smoke.initial_velocity_max = 30.0
	smoke.scale_amount_min = 0.08
	smoke.scale_amount_max = 0.14
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.1, 0.08, 0.08, 0.0))
	ramp.set_color(1, Color(0.06, 0.07, 0.09, 0.0))
	ramp.add_point(0.3, Color(0.12, 0.1, 0.1, 0.35))
	smoke.color_ramp = ramp
	return smoke


func _make_embers(additive: CanvasItemMaterial) -> CPUParticles2D:
	var embers := CPUParticles2D.new()
	embers.local_coords = false
	embers.amount = 40
	embers.lifetime = 0.7
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINTS
	embers.direction = Vector2.UP
	embers.spread = 45.0
	embers.gravity = Vector2(0.0, -110.0)
	embers.initial_velocity_min = 10.0
	embers.initial_velocity_max = 40.0
	embers.scale_amount_min = 1.0
	embers.scale_amount_max = 1.8
	var ramp := Gradient.new()
	ramp.set_color(0, CORE * 1.8)
	ramp.set_color(1, Color(OUTER, 0.0))
	ramp.add_point(0.35, MIDDLE * 1.3)
	embers.color_ramp = ramp
	embers.material = additive
	return embers


func _make_light() -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = LevelLight.radial_texture()
	light.texture_scale = 1.1
	light.color = MIDDLE
	light.blend_mode = Light2D.BLEND_MODE_ADD
	light.height = 8.0 # Low: the blade's fire rims the hero from the side.
	light.visible = false
	return light
