class_name ParallaxBackdrop
extends CanvasLayer
## Screen-space background behind the world: repeating city layers that scroll slower than
## the camera (parallax), plus rain. Drawn below the world, so it only shows through open
## space. Layers are AI images made with tools/art/generate_ai_backgrounds.py and
## tools/art/process_backgrounds.py (far → near; each loops seamlessly left to right).

const RAIN := preload("res://art/fx/rain.png")
## Back to front.
const LAYERS: Array[Texture2D] = [
	preload("res://art/backgrounds/ai_far.png"),
	preload("res://art/backgrounds/ai_mid.png"),
	preload("res://art/backgrounds/ai_near.png"),
]
## Horizontal scroll speed of each layer relative to the camera (0 = fixed, 1 = world).
const LAYER_FACTORS: Array[float] = [0.05, 0.12, 0.25]
## How much camera height moves the layers (small, so the skyline stays on screen).
const VERTICAL_FACTOR := 0.04

## Camera height the layers are aligned to (usually the middle of the level).
var reference_y: float = 0.0
## Color multiplied into the city layers (areas set their own mood).
var tint: Color = Color.WHITE
var rain_amount: int = 120
## Extra horizontal scroll in pixels (the title screen drifts without a moving camera).
var drift: float = 0.0

var _rects: Array[TextureRect] = []
var _rain: CPUParticles2D


func _ready() -> void:
	layer = -10
	for texture: Texture2D in LAYERS:
		var rect := TextureRect.new()
		rect.texture = texture
		rect.stretch_mode = TextureRect.STRETCH_TILE
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.modulate = tint
		add_child(rect)
		_rects.append(rect)
	_rain = _make_rain()
	add_child(_rain)


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var view := get_viewport().get_visible_rect().size
	var center := camera.get_screen_center_position()
	for i in _rects.size():
		var rect := _rects[i]
		var texture_size := rect.texture.get_size()
		var scroll_x := fposmod((center.x + drift) * LAYER_FACTORS[i], texture_size.x)
		var shift_y := (center.y - reference_y) * VERTICAL_FACTOR * (i + 1)
		rect.position = Vector2(-scroll_x, view.y - texture_size.y - shift_y).round()
		rect.size = Vector2(view.x + texture_size.x, texture_size.y)
	_rain.position = Vector2(view.x / 2.0, -12.0)
	_rain.emission_rect_extents = Vector2(view.x / 2.0 + 60.0, 1.0)


func _make_rain() -> CPUParticles2D:
	var rain := CPUParticles2D.new()
	rain.texture = RAIN
	rain.amount = maxi(rain_amount, 1)
	rain.lifetime = 0.9
	rain.preprocess = 1.0
	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.direction = Vector2(-0.18, 1.0)
	rain.spread = 2.0
	rain.gravity = Vector2.ZERO
	rain.initial_velocity_min = 380.0
	rain.initial_velocity_max = 460.0
	rain.particle_flag_align_y = true
	rain.modulate = Color(1, 1, 1, 0.55)
	return rain
