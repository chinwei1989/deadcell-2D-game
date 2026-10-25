class_name HitboxComponent
extends Area2D
## Deals damage to HurtboxComponents it overlaps while active.
##
## Attacks call process_hits() every physics frame during their active frames, so hit
## timing follows frame data exactly. Always-on hazards set auto_process instead.
## Each target is hit once until reset_hits(), unless rehit_interval > 0.

signal hit_landed(hurtbox: HurtboxComponent, info: DamageInfo)

@export var active: bool = false
## Process hits automatically every physics frame (for hazards).
@export var auto_process: bool = false
## Seconds before the same target can be hit again. 0 = once per reset_hits().
@export var rehit_interval: float = 0.0

## Returns a new DamageInfo for each hit.
var build_damage: Callable

var _hit_times: Dictionary = {}
var _clock: float = 0.0


func _physics_process(delta: float) -> void:
	_clock += delta
	if auto_process:
		process_hits()


func reset_hits() -> void:
	_hit_times.clear()


func process_hits() -> void:
	if not active or not build_damage.is_valid():
		return
	for area in get_overlapping_areas():
		var hurtbox := area as HurtboxComponent
		if hurtbox == null or not _can_hit(hurtbox):
			continue
		var info: DamageInfo = build_damage.call()
		if hurtbox.receive(info):
			_hit_times[hurtbox] = _clock
			hit_landed.emit(hurtbox, info)


func _can_hit(hurtbox: HurtboxComponent) -> bool:
	if not _hit_times.has(hurtbox):
		return true
	return rehit_interval > 0.0 and _clock - float(_hit_times[hurtbox]) >= rehit_interval
