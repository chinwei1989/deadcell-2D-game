class_name CameraRig
extends Camera2D
## Follows a target with look-ahead and adds local-only trauma screen shake
## (PLAN.md section 16). Shake strength is scaled by the player's setting.

@export var target: Node2D
@export var look_ahead: float = 56.0
@export var vertical_offset: float = -24.0
@export var follow_speed: float = 8.0
@export var max_shake_offset: float = 6.0
@export var trauma_decay: float = 1.8

var _trauma: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	Events.screen_shake.connect(add_trauma)


func add_trauma(amount: float) -> void:
	var strength := float(Settings.get_value("feel", "screen_shake"))
	_trauma = minf(_trauma + amount * strength, 1.0)


## Jump straight to the target (after spawning or teleporting).
func snap_to_target() -> void:
	if is_instance_valid(target):
		global_position = _goal()
		reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if is_instance_valid(target):
		global_position = global_position.lerp(_goal(), 1.0 - exp(-follow_speed * delta))
	_trauma = maxf(_trauma - trauma_decay * delta, 0.0)
	var shake := _trauma * _trauma
	offset = Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * max_shake_offset * shake


func _goal() -> Vector2:
	var ahead := 0.0
	if target is Player:
		ahead = (target as Player).facing * look_ahead
	return target.global_position + Vector2(ahead, vertical_offset)
