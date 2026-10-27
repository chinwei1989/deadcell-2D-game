class_name Run
extends Node
## One run of the demo (PLAN.md section 29): plays the rooms RunPlan picked, one Level at a
## time. Walking through a room's open exit fades to the next room, carrying the player's
## Resolve. The run ends when the player dies (defeat) or the boss room is cleared
## (victory); both go to the end screen with the run's stats (RunState).
##
## Dev: `-- --run --autoclear` kills each room's enemies after a moment and walks through
## the exit, so the whole run (rooms, transitions, boss, end screen) can be smoke-tested.

const LEVEL_SCENE := preload("res://game/level/level.tscn")
const DemoDriver := preload("res://dev/demo_driver.gd")
const FADE_TIME := 0.35
const VICTORY_DELAY := 3.5
const DEFEAT_DELAY := 2.2

var level: Level

var _fade: ColorRect
var _ending: bool = false
var _autoclear: bool = "--autoclear" in OS.get_cmdline_user_args()


func _ready() -> void:
	if not RunState.active:
		RunState.start_run()
	RunState.rooms = RunPlan.make(RunState.rng.stream(&"rooms"))
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color("05090d")
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	var pause := PauseMenu.new()
	pause.abandon_requested.connect(_finish.bind(false, 0.2))
	add_child(pause)
	_load_room(0)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--demo="):
			add_child(DemoDriver.new(arg.get_slice("=", 1)))


func _load_room(index: int) -> void:
	RunState.room_index = index
	var spec: Dictionary = RunState.rooms[index]
	var theme: AreaTheme = spec["theme"]
	level = LEVEL_SCENE.instantiate() as Level
	level.map_path = spec["map"]
	level.theme = theme
	add_child(level)
	level.player.respawns = false
	if RunState.carried_pips >= 0.0:
		level.player.resolve.set_pips(RunState.carried_pips)
	if index > 0:
		level.hud.hide_controls()
	level.exit_reached.connect(_on_exit_reached)
	level.player_died.connect(_on_player_died)
	if index == RunState.rooms.size() - 1:
		level.cleared.connect(_on_boss_cleared)
	elif bool(spec["first_in_area"]):
		level.hud.show_title(theme.display_name, theme.subtitle)
	create_tween().tween_property(_fade, ^"color:a", 0.0, FADE_TIME)
	if _autoclear:
		get_tree().create_timer(1.0).timeout.connect(_clear_room.bind(level))


func _clear_room(room: Level) -> void:
	if room != level or _ending:
		return
	print("[run] room %d: %s" % [RunState.room_index, room.map_path])
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as EnemyBase
		if enemy and not enemy.health.is_dead():
			enemy.health.damage(enemy.health.current)
	if RunState.room_index < RunState.rooms.size() - 1:
		room.cleared.connect(func() -> void:
			get_tree().create_timer(0.4).timeout.connect(_on_exit_reached), CONNECT_ONE_SHOT)


func _on_exit_reached() -> void:
	if _ending:
		return
	RunState.rooms_cleared += 1
	RunState.carried_pips = level.player.resolve.pips
	Feel.set_slow_motion(false)
	var tween := create_tween()
	tween.tween_property(_fade, ^"color:a", 1.0, FADE_TIME)
	tween.tween_callback(_next_room)


func _next_room() -> void:
	remove_child(level) # Out of the tree now, so nothing finds the old player or arena.
	level.queue_free()
	_load_room(RunState.room_index + 1)


func _on_boss_cleared() -> void:
	RunState.rooms_cleared += 1
	_finish(true, VICTORY_DELAY)


func _on_player_died() -> void:
	_finish(false, DEFEAT_DELAY)


func _finish(won: bool, delay: float) -> void:
	if _ending:
		return
	_ending = true
	RunState.end_run(won)
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(_fade, ^"color:a", 1.0, 0.6)
	tween.tween_callback(func() -> void:
		Feel.set_slow_motion(false)
		Game.goto(&"end", Game.Mode.RESULTS))
