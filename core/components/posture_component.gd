class_name PostureComponent
extends Node
## Posture bar for elites, armored machines, the Linked and bosses (PLAN.md section 5.2).
## Parries, deflects and heavy hits fill it; when full the entity is staggered and open to
## an execution (or "cut the link"). Recovers slowly when not under pressure.

signal changed(value: float, max_value: float)
signal broken
signal recovered

@export var max_posture: float = 30.0
## Seconds without posture damage before recovery starts.
@export var recovery_delay: float = 1.0
## Posture recovered per second.
@export var recovery_rate: float = 10.0
@export var stagger_time: float = 2.0

var value: float = 0.0
var _since_hit: float = 0.0
var _stagger_left: float = 0.0


func _physics_process(delta: float) -> void:
	tick(delta)


func is_staggered() -> bool:
	return _stagger_left > 0.0


## Keeps the entity staggered for at least `seconds` more (e.g. while its link is cut).
func extend_stagger(seconds: float) -> void:
	if is_staggered():
		_stagger_left = maxf(_stagger_left, seconds)


func add(amount: float) -> void:
	if is_staggered() or amount <= 0.0:
		return
	value = minf(value + amount, max_posture)
	_since_hit = 0.0
	changed.emit(value, max_posture)
	if value >= max_posture:
		_stagger_left = stagger_time
		broken.emit()


func tick(delta: float) -> void:
	if is_staggered():
		_stagger_left = maxf(_stagger_left - delta, 0.0)
		if _stagger_left <= 0.0:
			value = 0.0
			changed.emit(value, max_posture)
			recovered.emit()
		return
	_since_hit += delta
	# Only the time past the delay counts, so results don't depend on frame size.
	var recover_time := minf(delta, _since_hit - recovery_delay)
	if recover_time > 0.0 and value > 0.0:
		value = maxf(value - recovery_rate * recover_time, 0.0)
		changed.emit(value, max_posture)
