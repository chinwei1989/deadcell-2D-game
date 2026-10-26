class_name LinkedCitizen
extends EnemyBase
## A human controlled by HALCYON through an implant (PLAN.md section 9.2). Clumsy grabs;
## hits never kill it. Break its posture (a parry does it in one go), then either:
##   - slash it: an execution (counts against the Mercy record), or
##   - hold Interact next to it for cut_link_time: the link is cut and the person is freed
##     (counts toward the Mercy record and, later, the hub and the true ending).
## States: idle → approach → windup → lunge (grab) → recover; freed (walks away, fades).

const FREED_COLOR := Color("f2a541")
const IMPLANT_OFF_COLOR := Color("5c6f7a")
const FREED_WALK_TIME := 1.6

var _cut_progress: float = 0.0
var _being_cut: bool = false

@onready var _implant: Polygon2D = $Visual/Implant
@onready var _prompt: Label = $Prompt


func _ready() -> void:
	super()
	add_to_group(&"linked")
	_prompt.visible = false


func _ai(delta: float) -> void:
	apply_gravity(delta)
	match state:
		&"idle":
			run_toward(0.0, delta)
			if distance_to_target() <= data.aggro_range:
				set_state(&"approach")
		&"approach":
			if distance_to_target() > data.aggro_range * 1.5:
				set_state(&"idle")
				return
			face(direction_to_target())
			if absf(target.global_position.x - global_position.x) <= data.attack_range:
				set_state(&"windup")
				Audio.play(&"linked_grab", -8.0)
			else:
				run_toward(facing, delta)
		&"windup":
			run_toward(0.0, delta)
			telegraph()
			if state_past_frames(data.windup_frames):
				set_state(&"lunge")
				velocity = Vector2(facing * data.lunge_speed, -data.lunge_hop)
				attack_hitbox.reset_hits()
		&"lunge":
			attack_hitbox.active = not state_past_frames(data.active_frames)
			if attack_hitbox.active:
				attack_hitbox.process_hits()
			elif is_on_floor():
				set_state(&"recover")
		&"recover":
			run_toward(0.0, delta)
			if state_past_frames(data.recovery_frames):
				set_state(&"approach")
		&"freed":
			run_toward(facing, delta)
			if state_time >= FREED_WALK_TIME:
				queue_free()


func _process(delta: float) -> void:
	super(delta)
	if state == &"freed":
		_body.color = FREED_COLOR
		visual.modulate.a = clampf(1.0 - (state_time - FREED_WALK_TIME * 0.5) / (FREED_WALK_TIME * 0.5), 0.0, 1.0)
		return
	_prompt.visible = state == &"staggered"
	if _being_cut:
		_prompt.text = "Cutting... %d%%" % roundi(_cut_progress * 100.0)
	else:
		_prompt.text = "Hold R: cut the link"
	_being_cut = false


## Hits hurt but never kill: only an execution can (PLAN.md section 9.2).
func take_hit(info: DamageInfo) -> void:
	if state == &"freed":
		return
	info.is_lethal = false
	if not (info.can_execute and is_executable()):
		info.amount = minf(info.amount, maxf(health.current - 1.0, 0.0))
	super(info)


## True while the link can be cut (posture broken and still linked).
func can_cut_link() -> bool:
	return state == &"staggered"


## Called every frame by the player holding Interact; progress is 0..1.
func set_cut_progress(progress: float) -> void:
	_cut_progress = progress
	_being_cut = progress > 0.0
	if _being_cut:
		posture.extend_stagger(0.25) # Stay helpless while someone is cutting the link.


func free_link(by: Node) -> void:
	set_state(&"freed")
	collision_layer = 0
	hurtbox.set_deferred(&"monitorable", false)
	remove_from_group(&"enemies")
	remove_from_group(&"targets")
	_implant.color = IMPLANT_OFF_COLOR
	_prompt.visible = false
	face(-direction_to_target() if target else facing)
	Events.linked_freed.emit(self, by)
