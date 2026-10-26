class_name PatrolDrone
extends EnemyBase
## Hovering drone (PLAN.md section 9.1). Patrols around its spawn point; when a player
## comes close it stops, telegraphs and fires a slow bolt at them. Teaches deflecting:
## a perfectly deflected bolt flies straight back and destroys it.
## States: idle (patrol) → windup → cooldown → idle...

const PROJECTILE_SCENE := preload("res://combat/projectiles/projectile.tscn")

@export var patrol_distance: float = 64.0
@export var hover_amplitude: float = 3.0

var _home: Vector2
var _patrol_direction: int = 1


func _ready() -> void:
	super()
	_home = global_position


func _ai(delta: float) -> void:
	_hover()
	match state:
		&"idle":
			run_toward(_patrol_direction, delta)
			var offset := global_position.x - _home.x
			if absf(offset) >= patrol_distance and signf(offset) == _patrol_direction:
				_patrol_direction = -_patrol_direction
			face(_patrol_direction)
			if distance_to_target() <= data.aggro_range:
				set_state(&"windup")
				Audio.play(&"drone_charge", -12.0)
		&"windup":
			run_toward(0.0, delta)
			face(direction_to_target())
			telegraph()
			if state_past_frames(data.windup_frames):
				_fire()
				set_state(&"cooldown")
		&"cooldown":
			run_toward(0.0, delta)
			if state_time >= data.fire_cooldown:
				set_state(&"idle")


## Steers back toward its home height with a gentle bob.
func _hover() -> void:
	var bob := sin(state_time * 3.0) * hover_amplitude
	velocity.y = clampf((_home.y + bob - global_position.y) * 4.0, -data.move_speed, data.move_speed)


func _fire() -> void:
	if target == null:
		return
	var bolt := PROJECTILE_SCENE.instantiate() as Projectile
	var muzzle := global_position + Vector2(facing * 10.0, 0.0)
	bolt.launch(self, (target.global_position + Vector2(0.0, -6.0)) - muzzle, data.projectile_speed)
	bolt.position = muzzle
	get_parent().add_child(bolt)
	Audio.play(&"laser", -12.0)
