class_name StateMachine
extends Node
## Generic finite state machine for enemies and bosses. Each child is a MachineState;
## the first child is the starting state. (The player uses a simpler enum state machine
## in player.gd because its states share a lot of movement code.)

signal transitioned(from_state: StringName, to_state: StringName)

var current: MachineState
var _states: Dictionary = {}


func _ready() -> void:
	for child in get_children():
		if child is MachineState:
			var state := child as MachineState
			state.machine = self
			_states[state.name] = state
	if not _states.is_empty():
		current = get_child(0) as MachineState
		current.enter({})


func _physics_process(delta: float) -> void:
	if current:
		current.physics_update(delta)


func transition_to(state_name: StringName, data: Dictionary = {}) -> void:
	if not _states.has(state_name):
		push_error("StateMachine: unknown state '%s'" % state_name)
		return
	var previous := current.name if current else &""
	if current:
		current.exit()
	current = _states[state_name]
	current.enter(data)
	transitioned.emit(previous, state_name)
