extends Node
## File locations for saves. All reads and writes go through JsonStore.

const PROFILE_PATH := "user://profile.json"
const RUN_PATH := "user://run.json"


func load_profile() -> Dictionary:
	return JsonStore.read(PROFILE_PATH)


func save_profile(data: Dictionary) -> Error:
	return JsonStore.write(PROFILE_PATH, data)


func load_run() -> Dictionary:
	return JsonStore.read(RUN_PATH)


func save_run(data: Dictionary) -> Error:
	return JsonStore.write(RUN_PATH, data)


func clear_run() -> void:
	for path: String in [RUN_PATH, RUN_PATH + ".bak"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
