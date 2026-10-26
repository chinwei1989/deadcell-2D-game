extends SceneTree
## Writes LAST EDGE's project settings: display, rendering, physics, layer names,
## autoloads and the input map. Safe to re-run; it overwrites only the settings below.
##
## Run: godot --headless --path . -s res://dev/configure_project.gd

const AUTOLOADS: Array[Array] = [
	["Events", "res://autoload/events.gd"],
	["Settings", "res://autoload/settings.gd"],
	["SaveService", "res://autoload/save_service.gd"],
	["Profile", "res://autoload/profile.gd"],
	["RunState", "res://autoload/run_state.gd"],
	["Net", "res://autoload/net.gd"],
	["Feel", "res://autoload/feel.gd"],
	["Audio", "res://autoload/audio.gd"],
	["Game", "res://autoload/game.gd"],
]

## Bind input events to every keyboard/controller (as the editor does), not just device 0.
const ALL_DEVICES := -1

## Order matters: index 0 is physics layer 1. Must match core/util/layers.gd.
const PHYSICS_LAYERS: Array[String] = [
	"world", "one_way", "player_body", "enemy_body", "player_attack", "enemy_attack",
	"player_hurtbox", "enemy_hurtbox", "pickups", "interactables", "hazards",
	"projectiles", "deflected",
]


func _initialize() -> void:
	_display()
	_rendering()
	_physics()
	_autoloads()
	_input_map()
	var err := ProjectSettings.save()
	print("Project settings saved: ", error_string(err))
	quit(0 if err == OK else 1)


func _display() -> void:
	_put("display/window/size/viewport_width", 640)
	_put("display/window/size/viewport_height", 360)
	_put("display/window/size/window_width_override", 1280)
	_put("display/window/size/window_height_override", 720)
	_put("display/window/stretch/mode", "canvas_items")
	_put("display/window/stretch/aspect", "expand")
	_put("display/window/stretch/scale_mode", "integer")
	_put("display/window/handheld/orientation", 4) # Sensor landscape.


func _rendering() -> void:
	_put("rendering/renderer/rendering_method", "mobile")
	_put("rendering/renderer/rendering_method.mobile", "mobile")
	_put("rendering/textures/canvas_textures/default_texture_filter", 0) # Nearest.
	_put("rendering/2d/snap/snap_2d_transforms_to_pixel", true)
	_put("rendering/2d/snap/snap_2d_vertices_to_pixel", true)
	_put("rendering/environment/defaults/default_clear_color", Color("0b1620"))
	_put("rendering/viewport/hdr_2d", true) # Colors above 1.0 glow (WorldEnvironment bloom).
	_put("debug/gdscript/warnings/untyped_declaration", 1) # Warn: keep GDScript typed.


func _physics() -> void:
	_put("physics/common/physics_ticks_per_second", 60)
	_put("physics/common/physics_interpolation", true)
	for i in PHYSICS_LAYERS.size():
		_put("layer_names/2d_physics/layer_%d" % (i + 1), PHYSICS_LAYERS[i])


func _autoloads() -> void:
	for entry in AUTOLOADS:
		_put("autoload/" + str(entry[0]), "*" + str(entry[1]))


func _input_map() -> void:
	_action("move_left", [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0), _pad(JOY_BUTTON_DPAD_LEFT)])
	_action("move_right", [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0), _pad(JOY_BUTTON_DPAD_RIGHT)])
	_action("move_up", [_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_action("move_down", [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_action("jump", [_key(KEY_SPACE), _pad(JOY_BUTTON_A)])
	_action("slash", [_key(KEY_J), _mouse(MOUSE_BUTTON_LEFT), _pad(JOY_BUTTON_X)])
	_action("parry", [_key(KEY_K), _mouse(MOUSE_BUTTON_RIGHT), _axis(JOY_AXIS_TRIGGER_LEFT, 1.0)])
	_action("dodge", [_key(KEY_L), _key(KEY_SHIFT), _pad(JOY_BUTTON_B), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)])
	_action("focus", [_key(KEY_F), _pad(JOY_BUTTON_Y)])
	_action("gadget_1", [_key(KEY_Q), _pad(JOY_BUTTON_LEFT_SHOULDER)])
	_action("gadget_2", [_key(KEY_E), _pad(JOY_BUTTON_RIGHT_SHOULDER)])
	_action("interact", [_key(KEY_R), _pad(JOY_BUTTON_DPAD_DOWN)])
	_action("patch_kit", [_key(KEY_C), _pad(JOY_BUTTON_DPAD_UP)])
	_action("ping", [_key(KEY_V), _mouse(MOUSE_BUTTON_MIDDLE)])
	_action("emote", [_key(KEY_T)])
	_action("map", [_key(KEY_TAB), _pad(JOY_BUTTON_BACK)])
	_action("pause", [_key(KEY_ESCAPE), _pad(JOY_BUTTON_START)])


func _put(setting: String, value: Variant) -> void:
	ProjectSettings.set_setting(setting, value)


func _action(action_name: String, events: Array[InputEvent], deadzone: float = 0.2) -> void:
	_put("input/" + action_name, {"deadzone": deadzone, "events": events})


func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.device = ALL_DEVICES
	event.physical_keycode = code
	return event


func _pad(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = ALL_DEVICES
	event.button_index = button
	return event


func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.device = ALL_DEVICES
	event.axis = axis
	event.axis_value = value
	return event


func _mouse(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.device = ALL_DEVICES
	event.button_index = button
	return event
