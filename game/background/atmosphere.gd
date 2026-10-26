class_name Atmosphere
extends CanvasLayer
## Screen-space atmosphere drawn over the world but under the HUD: drifting ground fog
## (moves with a little parallax as the camera pans) and a vignette that darkens the
## screen edges so the eye stays on the action.

const FOG_COLOR := Color(0.55, 0.75, 0.8)
const FOG_ALPHA := 0.11
const FOG_DRIFT := 6.0
## Fog moves slightly faster than the world (it's between the camera and the action).
const FOG_PARALLAX := 1.15

var _fog: ColorRect
var _fog_material: ShaderMaterial
var _time: float = 0.0


func _ready() -> void:
	layer = 1
	_fog = ColorRect.new()
	_fog.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fog_material = ShaderMaterial.new()
	_fog_material.shader = preload("res://game/fx/fog.gdshader")
	_fog_material.set_shader_parameter(&"noise_texture", _fog_texture())
	_fog_material.set_shader_parameter(&"fog_color", FOG_COLOR)
	_fog_material.set_shader_parameter(&"strength", FOG_ALPHA)
	_fog.material = _fog_material
	add_child(_fog)

	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://game/fx/vignette.gdshader")
	vignette.material = mat
	add_child(vignette)


func _process(delta: float) -> void:
	_time += delta
	var camera := get_viewport().get_camera_2d()
	var cam_x := camera.get_screen_center_position().x if camera else 0.0
	var view_width := get_viewport().get_visible_rect().size.x
	# Drift slowly, and slide a little faster than the world as the camera pans.
	_fog_material.set_shader_parameter(&"offset", Vector2((cam_x * FOG_PARALLAX + _time * FOG_DRIFT) / view_width * 0.6, _time * 0.01))


func _fog_texture() -> Texture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.012
	noise.fractal_octaves = 3
	noise.seed = 4
	var texture := NoiseTexture2D.new()
	texture.width = 320
	texture.height = 160
	texture.seamless = true
	texture.noise = noise
	return texture
