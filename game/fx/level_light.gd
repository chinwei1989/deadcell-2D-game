class_name LevelLight
extends Node2D
## A light source placed in a level: a small fixture, a soft glowing halo, a PointLight2D
## that lights everything around it, and a faint additive "pool" of the light's color.
## (2D lights multiply the color of what they hit, so on dark walls they barely show; the
## pool makes the colored light visible on the environment, like painted lighting.) WARM lamps flicker gently, NEON tubes buzz now and
## then, WARNING lights blink. Origin = where the fixture hangs.

enum Kind { WARM, NEON, WARNING }

const COLORS: Dictionary = {
	Kind.WARM: Color(1.0, 0.68, 0.32),
	Kind.NEON: Color(0.31, 0.82, 0.77),
	Kind.WARNING: Color(1.0, 0.25, 0.2),
}
## Light radius in pixels and brightness per kind.
const RADIUS: Dictionary = {Kind.WARM: 150.0, Kind.NEON: 120.0, Kind.WARNING: 80.0}
## 2D lights multiply the color of what they hit, so dark surfaces need strong lights.
const ENERGY: Dictionary = {Kind.WARM: 2.4, Kind.NEON: 2.0, Kind.WARNING: 2.0}
## Colors above 1.0 glow through the bloom.
const GLOW := 1.6
## Strength of the painted light pool on the environment.
const POOL_ALPHA := 0.16

static var _texture: GradientTexture2D

@export var kind: Kind = Kind.WARM

var _light: PointLight2D
var _halo: Sprite2D
var _pool: Sprite2D
var _time: float = 0.0
var _buzz_left: float = 0.0


func _ready() -> void:
	_time = randf() * 10.0 # Lights don't flicker in sync (visual only).
	var color: Color = COLORS[kind]
	_build_fixture(color)
	_light = PointLight2D.new()
	_light.texture = radial_texture()
	_light.texture_scale = float(RADIUS[kind]) / 64.0
	_light.color = color
	_light.energy = ENERGY[kind]
	_light.blend_mode = Light2D.BLEND_MODE_ADD
	_light.height = 24.0 # Above the play plane: normal-mapped sprites get top/side light.
	_light.position = Vector2(0.0, 6.0)
	add_child(_light)
	_pool = Sprite2D.new()
	_pool.texture = radial_texture()
	_pool.scale = Vector2.ONE * float(RADIUS[kind]) * 2.0 / 128.0
	_pool.modulate = Color(color, POOL_ALPHA)
	_pool.position = _light.position
	var pool_material := CanvasItemMaterial.new()
	pool_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	pool_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_pool.material = pool_material
	add_child(_pool)
	_halo = Sprite2D.new()
	_halo.texture = radial_texture()
	_halo.scale = Vector2.ONE * float(RADIUS[kind]) / 400.0
	_halo.modulate = Color(color * 1.3, 0.55)
	_halo.position = _light.position
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_halo.material = additive
	add_child(_halo)


func _process(delta: float) -> void:
	_time += delta
	var level := 1.0
	match kind:
		Kind.WARM:
			level = 0.93 + 0.05 * sin(_time * 9.0) + 0.02 * sin(_time * 23.0)
		Kind.NEON:
			_buzz_left -= delta
			if _buzz_left <= 0.0 and randf() < 0.004:
				_buzz_left = 0.12
			level = 0.35 if _buzz_left > 0.0 and int(_time * 40.0) % 2 == 0 else 1.0
		Kind.WARNING:
			level = 1.0 if fmod(_time, 1.2) < 0.6 else 0.15
	_light.energy = float(ENERGY[kind]) * level
	_halo.modulate.a = 0.55 * level
	_pool.modulate.a = POOL_ALPHA * level


## Releases the shared light texture (called on quit so nothing is reported as leaked).
static func clear_cache() -> void:
	_texture = null


static func radial_texture() -> GradientTexture2D:
	if _texture == null:
		_texture = GradientTexture2D.new()
		_texture.width = 128
		_texture.height = 128
		_texture.fill = GradientTexture2D.FILL_RADIAL
		_texture.fill_from = Vector2(0.5, 0.5)
		_texture.fill_to = Vector2(1.0, 0.5)
		var fade := Gradient.new()
		# Set both ends before adding points: add_point() re-sorts, shifting indexes.
		fade.set_color(0, Color.WHITE)
		fade.set_color(1, Color(1, 1, 1, 0))
		fade.add_point(0.4, Color(1, 1, 1, 0.45))
		_texture.gradient = fade
	return _texture


func _build_fixture(color: Color) -> void:
	var dark := Color("172c34")
	match kind:
		Kind.WARM:
			_line([Vector2(0, -12), Vector2(0, 0)], dark, 1.0) # Cable.
			_polygon([Vector2(-5, 0), Vector2(5, 0), Vector2(7, 5), Vector2(-7, 5)], Color("2d5560"))
			_polygon([Vector2(-3, 5), Vector2(3, 5), Vector2(2, 7), Vector2(-2, 7)], color * GLOW)
		Kind.NEON:
			_polygon([Vector2(-10, -2), Vector2(10, -2), Vector2(10, 4), Vector2(-10, 4)], dark)
			_line([Vector2(-8, 1), Vector2(8, 1)], color * GLOW, 2.0)
		Kind.WARNING:
			_polygon([Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3)], dark)
			_polygon([Vector2(-2, -2), Vector2(2, -2), Vector2(2, 2), Vector2(-2, 2)], color * GLOW)


func _polygon(points: Array[Vector2], color: Color) -> void:
	var polygon := Polygon2D.new()
	polygon.polygon = PackedVector2Array(points)
	polygon.color = color
	add_child(polygon)


func _line(points: Array[Vector2], color: Color, width: float) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array(points)
	line.default_color = color
	line.width = width
	add_child(line)
