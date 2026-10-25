class_name HurtboxComponent
extends Area2D
## The area where an entity can be hit. Emits received(info); the owning entity decides
## what the hit does (Resolve, health, posture...).
## Set monitoring = false and monitorable = true in the scene.

signal received(info: DamageInfo)

## While true, hits are refused (e.g. dodge invincibility frames).
@export var invulnerable: bool = false


## Returns true if the hit was accepted.
func receive(info: DamageInfo) -> bool:
	if invulnerable:
		return false
	received.emit(info)
	return true


func entity() -> Node:
	return get_parent()
