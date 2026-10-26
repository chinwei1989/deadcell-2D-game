extends Node
## Permanent progress (unlocks, mastery, Mercy record...). Shape is defined in
## ProfileSchema. Change data, then call save_profile().

var data: Dictionary = {}


func _ready() -> void:
	load_profile()
	Events.linked_freed.connect(func(_linked: Node, _by: Node) -> void: _add_mercy("freed_total"))
	Events.enemy_executed.connect(_on_enemy_executed)


func load_profile() -> void:
	var loaded := SaveService.load_profile()
	data = ProfileSchema.migrate(loaded) if not loaded.is_empty() else ProfileSchema.defaults()


func save_profile() -> Error:
	return SaveService.save_profile(data)


## The Mercy record: Linked freed vs executed (drives the hub and the true ending).
func _add_mercy(key: String) -> void:
	data["mercy"][key] = int(data["mercy"][key]) + 1
	save_profile()


func _on_enemy_executed(enemy: Node, _by: Node) -> void:
	if enemy is LinkedCitizen:
		_add_mercy("executed_total")
