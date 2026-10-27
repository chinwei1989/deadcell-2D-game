class_name Menu
## Shared pieces for the title and end screens: pixel-font buttons (keyboard, mouse and
## gamepad: arrows/D-pad move, Enter/Space/A press) and the drifting city backdrop.

const TEXT := Color("b8c7cf")
const HOT := Color("f2a541")
const PLATE := Color(0.035, 0.07, 0.1, 0.0)
const PLATE_FOCUS := Color(0.12, 0.07, 0.04, 0.85)


## A menu button: dim text that turns amber with a ">" marker and a dark plate when focused
## or hovered. Hovering also focuses, so the mouse and keyboard never disagree.
static func button(text: String, on_pressed: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = false
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", TEXT)
	for state in ["font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(state, HOT)
	var normal := StyleBoxFlat.new()
	normal.bg_color = PLATE
	normal.set_content_margin_all(3)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	var focus := normal.duplicate() as StyleBoxFlat
	focus.bg_color = PLATE_FOCUS
	focus.border_color = HOT
	focus.border_width_left = 2
	for style_name in ["normal", "disabled"]:
		b.add_theme_stylebox_override(style_name, normal)
	for style_name in ["hover", "pressed", "focus", "hover_pressed"]:
		b.add_theme_stylebox_override(style_name, focus)
	b.pressed.connect(func() -> void:
		Audio.play(&"slash_1", -8.0, 0.05)
		on_pressed.call())
	b.focus_entered.connect(func() -> void: Audio.play(&"dodge", -18.0, 0.05, 1.6))
	b.mouse_entered.connect(b.grab_focus)
	return b


## The city behind menus: glow, dim ambient light, the parallax layers drifting slowly and
## rain. Needs a Camera2D in the scene (the backdrop follows the active camera).
static func backdrop(parent: Node, tint: Color = Color.WHITE, ambient: Color = Color(0.55, 0.6, 0.72)) -> ParallaxBackdrop:
	parent.add_child(Level.make_glow())
	var light := CanvasModulate.new()
	light.color = ambient
	parent.add_child(light)
	var city := ParallaxBackdrop.new()
	city.tint = tint
	city.rain_amount = 160
	parent.add_child(city)
	var atmosphere := Atmosphere.new()
	parent.add_child(atmosphere)
	return city


## "mm:ss" for the stats screen.
static func clock(seconds: float) -> String:
	var total := int(seconds)
	return "%d:%02d" % [total / 60, total % 60]
