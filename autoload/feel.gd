extends Node
## Local-only game feel: hit freeze and screen shake (PLAN.md sections 5 and 16).
## Never changes state other peers can see, so it is safe in co-op.

var _frozen: Dictionary = {}


## Pauses physics on the given nodes for a number of physics frames. Freezing the
## attacker also pauses its attack timeline, which is what makes hits feel heavy.
func hit_freeze(nodes: Array, frames: int) -> void:
	if frames <= 0:
		return
	for node: Variant in nodes:
		if node is Node and is_instance_valid(node):
			_frozen[node] = maxi(int(_frozen.get(node, 0)), frames)
			(node as Node).set_physics_process(false)


func shake(trauma: float) -> void:
	Events.screen_shake.emit(trauma)


func _physics_process(_delta: float) -> void:
	for node: Variant in _frozen.keys():
		if not is_instance_valid(node):
			_frozen.erase(node)
			continue
		_frozen[node] = int(_frozen[node]) - 1
		if int(_frozen[node]) <= 0:
			_frozen.erase(node)
			(node as Node).set_physics_process(true)
