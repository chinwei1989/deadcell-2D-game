extends Node
## Top-level game flow. Scene paths live here so other code never hard-codes them.

signal mode_changed(mode: Mode)

enum Mode { BOOT, TITLE, HUB, LOBBY, IN_RUN, RESULTS }

const SCENES: Dictionary = {
	&"test_arena": "res://game/arena/test_arena.tscn",
}

var mode: Mode = Mode.BOOT


func _exit_tree() -> void:
	SpriteSheet.clear_cache()
	LevelLight.clear_cache()


func goto(scene_id: StringName, new_mode: Mode) -> void:
	assert(SCENES.has(scene_id), "Unknown scene id: %s" % scene_id)
	mode = new_mode
	mode_changed.emit(mode)
	get_tree().change_scene_to_file.call_deferred(SCENES[scene_id])
