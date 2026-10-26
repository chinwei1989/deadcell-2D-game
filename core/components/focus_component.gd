class_name FocusComponent
extends Node
## Focus meter for slow motion (PLAN.md section 5.1), measured in real seconds of slow-mo.
## This only tracks the meter; the owner applies the slow motion when activated/deactivated
## fire. Tick it with real time (delta / Engine.time_scale), not game time.

signal changed(seconds: float, max_seconds: float)
signal activated
signal deactivated

@export var max_seconds: float = 3.0
## Minimum meter needed to start Focus.
@export var min_to_activate: float = 0.25

var seconds: float = 0.0
var active: bool = false


func _ready() -> void:
	reset()


func reset() -> void:
	deactivate()
	seconds = max_seconds
	changed.emit(seconds, max_seconds)


func toggle() -> void:
	if active:
		deactivate()
	elif seconds >= min_to_activate:
		active = true
		activated.emit()


func deactivate() -> void:
	if active:
		active = false
		deactivated.emit()


func refill(amount: float) -> void:
	seconds = minf(seconds + amount, max_seconds)
	changed.emit(seconds, max_seconds)


func tick(real_delta: float) -> void:
	if not active:
		return
	seconds = maxf(seconds - real_delta, 0.0)
	changed.emit(seconds, max_seconds)
	if seconds <= 0.0:
		deactivate()
