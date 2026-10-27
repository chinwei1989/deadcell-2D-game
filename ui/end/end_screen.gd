class_name EndScreen
extends Node2D
## After a run: victory or defeat, the run's stats (RunState) and what next: run again,
## give feedback (if Game.FEEDBACK_URL is set), back to the title, quit.

const WIN_COLOR := Color(1.0, 0.62, 0.22)
const LOSE_COLOR := Color("d64545")


func _ready() -> void:
	var camera := Camera2D.new()
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS # Physics interpolation is on.
	add_child(camera)
	camera.make_current()
	var won := RunState.victory
	print("[end] victory=%s rooms=%d kills=%d time=%s" % [won, RunState.rooms_cleared, RunState.kills, Menu.clock(RunState.elapsed())])
	var city := Menu.backdrop(self, Color(0.7, 0.75, 0.9) if won else Color(0.75, 0.55, 0.6),
		Color(0.5, 0.55, 0.68) if won else Color(0.5, 0.42, 0.48))
	city.drift = 900.0
	Audio.play_music("res://audio/music/neon_rain.wav")

	var ui := CanvasLayer.new()
	ui.layer = 5
	add_child(ui)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.offset_left = -170.0
	column.offset_right = 170.0
	column.offset_top = -130.0
	column.offset_bottom = 130.0
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 4)
	ui.add_child(column)

	var headline := Hud.make_label(24, (WIN_COLOR * 1.25) if won else LOSE_COLOR, HORIZONTAL_ALIGNMENT_CENTER)
	headline.text = "THE WARDEN FALLS" if won else "YOUR EDGE DULLS"
	column.add_child(headline)
	var sub := Hud.make_label(8, Color("b8c7cf"), HORIZONTAL_ALIGNMENT_CENTER)
	sub.text = "DEMO COMPLETE. THANK YOU FOR PLAYING." if won else "THE CITY STILL WAITS. TRY AGAIN."
	column.add_child(sub)
	column.add_child(_spacer(8))

	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 24)
	stats.add_theme_constant_override("v_separation", 3)
	stats.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(stats)
	for row in _stat_rows():
		var name_label := Hud.make_label(8, Color("8aa1ad"), HORIZONTAL_ALIGNMENT_LEFT)
		name_label.text = row[0]
		stats.add_child(name_label)
		var value := Hud.make_label(8, Color("e8d8c8"), HORIZONTAL_ALIGNMENT_RIGHT)
		value.text = row[1]
		stats.add_child(value)
	column.add_child(_spacer(10))

	var buttons := VBoxContainer.new()
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	buttons.add_theme_constant_override("separation", 2)
	column.add_child(buttons)
	var again := Menu.button("RUN AGAIN", func() -> void:
		RunState.start_run()
		Game.goto(&"run", Game.Mode.IN_RUN))
	buttons.add_child(again)
	if Game.FEEDBACK_URL != "":
		buttons.add_child(Menu.button("GIVE FEEDBACK", func() -> void: OS.shell_open(Game.FEEDBACK_URL)))
	buttons.add_child(Menu.button("TITLE", func() -> void: Game.goto(&"title", Game.Mode.TITLE)))
	if not OS.has_feature("web"):
		buttons.add_child(Menu.button("QUIT", func() -> void: get_tree().quit()))
	again.grab_focus.call_deferred()


func _stat_rows() -> Array[Array]:
	var rows: Array[Array] = [
		["TIME", Menu.clock(RunState.elapsed())],
		["ROOMS CLEARED", "%d / %d" % [RunState.rooms_cleared, RunState.rooms.size()]],
		["KILLS", str(RunState.kills)],
		["EXECUTIONS", str(RunState.executions)],
		["LINKED FREED", str(RunState.freed)],
		["BEST COMBO", str(RunState.best_combo)],
	]
	return rows


func _spacer(height: float) -> Control:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, height)
	return gap
