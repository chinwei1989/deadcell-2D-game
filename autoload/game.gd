extends Node
## Top-level game flow. Scene paths live here so other code never hard-codes them.

signal mode_changed(mode: Mode)

enum Mode { BOOT, TITLE, HUB, LOBBY, IN_RUN, RESULTS }

const SCENES: Dictionary = {
	&"title": "res://ui/title/title.tscn",
	&"run": "res://game/run/run.tscn",
	&"end": "res://ui/end/end_screen.tscn",
	&"test_arena": "res://game/arena/test_arena.tscn",
}
## Where the end screen's "GIVE FEEDBACK" button goes (a form for playtesters). Empty = no
## button. Set this before sharing a build.
const FEEDBACK_URL := ""

var mode: Mode = Mode.BOOT


func _exit_tree() -> void:
	SpriteSheet.clear_cache()
	LevelLight.clear_cache()


func goto(scene_id: StringName, new_mode: Mode) -> void:
	assert(SCENES.has(scene_id), "Unknown scene id: %s" % scene_id)
	mode = new_mode
	mode_changed.emit(mode)
	get_tree().change_scene_to_file.call_deferred(SCENES[scene_id])
