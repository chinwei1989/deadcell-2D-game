class_name CameraRig
extends Camera2D
## Follows a target with look-ahead and adds local-only trauma screen shake
## (PLAN.md section 16). Looks down while the target falls fast, so drops between
## levels show where you'll land. Shake strength is scaled by the player's setting.
##
## Zoom: shows about target_visible_height world pixels vertically (close, like Dead
## Cells), rounded so every world pixel covers a whole number of screen pixels.
## Recomputed when the window size changes.

@export var target: Node2D
## Roughly how many world pixels tall the view should be (240 = 15 tiles).
@export var target_visible_height: float = 240.0
@export var look_ahead: float = 48.0
@export var vertical_offset: float = -24.0
## Extra downward look while falling faster than fall_look_speed.
@export var fall_look_ahead: float = 64.0
@export var fall_look_speed: float = 260.0
@export var follow_speed: float = 8.0
@export var vertical_follow_speed: float = 6.0
@export var max_shake_offset: float = 6.0
@export var trauma_decay: float = 1.8

var _trauma: float = 0.0
var _fall_look: float = 0.0
var _overview: bool = false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	Events.screen_shake.connect(add_trauma)
	get_viewport().size_changed.connect(_apply_zoom)
	_apply_zoom()


## Zoom giving a whole number of screen pixels per world pixel, with the view as close as
## possible to target_height world pixels tall. viewport_height is the stretched
## viewport's height (e.g. 360), window_height the real window's height in pixels.
static func pixel_perfect_zoom(window_height: float, viewport_height: float, target_height: float) -> float:
	var pixels_per_world_pixel := maxf(roundf(window_height / target_height), 1.0)
	return pixels_per_world_pixel * viewport_height / window_height


func _apply_zoom() -> void:
	if _overview:
		return
	var window_height := float(get_window().size.y)
	var viewport_height := get_viewport().get_visible_rect().size.y
	if window_height <= 0.0 or viewport_height <= 0.0:
		return
	var z := pixel_perfect_zoom(window_height, viewport_height, target_visible_height)
	zoom = Vector2(z, z)


func add_trauma(amount: float) -> void:
	var strength := float(Settings.get_value("feel", "screen_shake"))
	_trauma = minf(_trauma + amount * strength, 1.0)


## Jump straight to the target (after spawning or teleporting).
func snap_to_target() -> void:
	if is_instance_valid(target):
		global_position = _goal()
		reset_physics_interpolation()


## Stop following and zoom out to show the whole area (map overview / debugging).
func show_overview(area: Rect2) -> void:
	_overview = true
	target = null
	var viewport := get_viewport_rect().size
	var fit := minf(viewport.x / area.size.x, viewport.y / area.size.y)
	zoom = Vector2(fit, fit)
	limit_left = int(area.position.x)
	limit_top = int(area.position.y)
	limit_right = int(area.end.x)
	limit_bottom = int(area.end.y)
	global_position = area.get_center()
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if is_instance_valid(target):
		var falling := target is CharacterBody2D and (target as CharacterBody2D).velocity.y > fall_look_speed
		_fall_look = move_toward(_fall_look, fall_look_ahead if falling else 0.0, 240.0 * delta)
		var goal := _goal()
		global_position.x = lerpf(global_position.x, goal.x, 1.0 - exp(-follow_speed * delta))
		global_position.y = lerpf(global_position.y, goal.y, 1.0 - exp(-vertical_follow_speed * delta))
	_trauma = maxf(_trauma - trauma_decay * delta, 0.0)
	var shake := _trauma * _trauma
	offset = Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * max_shake_offset * shake


func _goal() -> Vector2:
	var ahead := 0.0
	if target is Player:
		ahead = (target as Player).facing * look_ahead
	return target.global_position + Vector2(ahead, vertical_offset + _fall_look)
