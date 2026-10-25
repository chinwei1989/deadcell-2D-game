class_name HealthComponent
extends Node
## Hit points for enemies. Players use ResolveComponent instead.

signal changed(current: float, max_health: float)
signal died

@export var max_health: float = 30.0

var current: float = 0.0


func _ready() -> void:
	reset()


func reset() -> void:
	current = max_health
	changed.emit(current, max_health)


func is_dead() -> bool:
	return current <= 0.0


## Returns true if this damage killed the entity.
func damage(amount: float) -> bool:
	if is_dead() or amount <= 0.0:
		return false
	current = maxf(current - amount, 0.0)
	changed.emit(current, max_health)
	if is_dead():
		died.emit()
		return true
	return false


func heal(amount: float) -> void:
	if is_dead():
		return
	current = minf(current + amount, max_health)
	changed.emit(current, max_health)
