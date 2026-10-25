class_name ProfileSchema
## Shape and versioning of the permanent profile save (PLAN.md section 31).
## When the shape changes: bump VERSION, add a step in migrate(), add a unit test.

const VERSION := 1


static func defaults() -> Dictionary:
	return {
		"save_version": VERSION,
		"memory_shards": 0,
		"characters": ["ronin"],
		"unlocked": {"blades": ["katana"], "gadgets": [], "techniques": []},
		"mastery": {},
		"evolutions_found": [],
		"mercy": {"freed_total": 0, "executed_total": 0},
		"threat_level_unlocked": 0,
		"hub_stage": 0,
		"story_flags": [],
		"endings": [],
		"stats": {"runs": 0, "wins": 0, "best_daily": 0},
	}


## Brings any older save up to the current VERSION. Unknown keys from newer versions
## are kept; missing keys get default values.
static func migrate(data: Dictionary) -> Dictionary:
	var result := defaults()
	_merge(result, data)
	# Version steps go here, oldest first, e.g.:
	# if int(data.get("save_version", 0)) < 2:
	#     result["new_key"] = ...
	result["save_version"] = VERSION
	return result


static func _merge(into: Dictionary, from: Dictionary) -> void:
	for key: Variant in from:
		if into.has(key) and into[key] is Dictionary and from[key] is Dictionary:
			_merge(into[key], from[key])
		else:
			into[key] = from[key]
