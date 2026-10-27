class_name PauseMenu
extends CanvasLayer
## Esc / Start during a run: pauses the game with RESUME, CONTROLS, ABANDON RUN (ends the
## run as a defeat, with its stats) and QUIT TO TITLE.

signal abandon_requested

var _panel: Control
var _controls: PanelContainer
var _first: Button


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.visible = false
	add_child(_panel)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.06, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(dim)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.offset_left = -110.0
	column.offset_right = 110.0
	column.offset_top = -70.0
	column.offset_bottom = 70.0
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 2)
	_panel.add_child(column)
	var title := Hud.make_label(24, Color("f2a541"), HORIZONTAL_ALIGNMENT_CENTER)
	title.text = "PAUSED"
	column.add_child(title)
	_first = Menu.button("RESUME", close)
	column.add_child(_first)
	column.add_child(Menu.button("CONTROLS", func() -> void: _controls.visible = not _controls.visible))
	column.add_child(Menu.button("ABANDON RUN", func() -> void:
		close()
		abandon_requested.emit()))
	column.add_child(Menu.button("QUIT TO TITLE", func() -> void:
		close()
		Feel.set_slow_motion(false)
		RunState.end_run(false)
		Game.goto(&"title", Game.Mode.TITLE)))
	_controls = Hud.make_controls_panel()
	_controls.visible = false
	_panel.add_child(_controls)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if _panel.visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func open() -> void:
	_panel.visible = true
	get_tree().paused = true
	Audio.play(&"focus_on", -12.0)
	_first.grab_focus.call_deferred()


func close() -> void:
	_panel.visible = false
	_controls.visible = false
	get_tree().paused = false
