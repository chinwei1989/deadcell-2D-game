class_name MachineState
extends Node
## One state in a StateMachine. Override the methods you need.

var machine: StateMachine


func enter(_data: Dictionary) -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
