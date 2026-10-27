class_name TestArena
extends Level
## The sandbox: the Level built from game/arena/maps/sandbox.txt, for tuning movement and
## combat and for the bot demo scenarios (dev/demo_driver.gd). The map legend is in level.gd.
##
## Command-line options (after --):
##   --demo=<scenario>   add the demo driver (scripted input / bot)
##   --overview          show the whole map zoomed out
##   --room=<res path>   load another map instead (e.g. a run room), with its own markers

const MAP_PATH := "res://game/arena/maps/sandbox.txt"
const DemoDriver := preload("res://dev/demo_driver.gd")


func _ready() -> void:
	RunState.start_run()
	map_path = MAP_PATH
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--room="):
			map_path = arg.get_slice("=", 1)
	super()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--demo"):
			add_child(DemoDriver.new(arg.get_slice("=", 1) if "=" in arg else "combo"))
		elif arg == "--overview":
			camera.show_overview(Rect2(Vector2.ZERO, Vector2(map_size * TILE)))
