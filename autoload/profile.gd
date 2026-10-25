extends Node
## Permanent progress (unlocks, mastery, Mercy record...). Shape is defined in
## ProfileSchema. Change data, then call save_profile().

var data: Dictionary = {}


func _ready() -> void:
	load_profile()


func load_profile() -> void:
	var loaded := SaveService.load_profile()
	data = ProfileSchema.migrate(loaded) if not loaded.is_empty() else ProfileSchema.defaults()


func save_profile() -> Error:
	return SaveService.save_profile(data)
