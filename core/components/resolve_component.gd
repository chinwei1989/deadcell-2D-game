class_name ResolveComponent
extends Node
## Player health as Resolve pips (PLAN.md section 5.2). Each hit costs pips; a hit taken
## at 0 pips kills (in co-op: downed). Pips can be fractional (half pips from parries).

signal changed(pips: float, max_pips: float)
## Reached 0 pips: the next hit kills.
signal emptied
signal killed

enum HitResult { IGNORED, HURT, KILLED }

@export var max_pips: float = 4.0
@export var invulnerability_time: float = 0.8

var pips: float = 0.0
var _invulnerable_left: float = 0.0


func _ready() -> void:
	reset()


func _physics_process(delta: float) -> void:
	tick(delta)


func reset() -> void:
	pips = max_pips
	_invulnerable_left = 0.0
	changed.emit(pips, max_pips)


func tick(delta: float) -> void:
	_invulnerable_left = maxf(_invulnerable_left - delta, 0.0)


func is_invulnerable() -> bool:
	return _invulnerable_left > 0.0


func take_hit(cost: float = 1.0) -> HitResult:
	if is_invulnerable():
		return HitResult.IGNORED
	if pips <= 0.0:
		killed.emit()
		return HitResult.KILLED
	pips = maxf(pips - cost, 0.0)
	_invulnerable_left = invulnerability_time
	changed.emit(pips, max_pips)
	if pips <= 0.0:
		emptied.emit()
	return HitResult.HURT


func restore(amount: float) -> void:
	pips = minf(pips + amount, max_pips)
	changed.emit(pips, max_pips)
