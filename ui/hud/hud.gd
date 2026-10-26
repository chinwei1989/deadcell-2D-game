class_name Hud
extends CanvasLayer
## The in-run HUD (PLAN.md section 19): vitals plate top-left (Resolve pips + Focus bar,
## HudVitals), combo counter top-right, a controls panel at the bottom that fades out after
## a few seconds (toggle with the "help" action), a cold tint during Focus slow motion and
## the screen flash. All text uses the pixel font from the project theme
## (ui/theme/game_theme.tres): keep font sizes at multiples of 8 so glyphs stay crisp.

const SLOW_MOTION_TINT := Color(0.31, 0.82, 0.773, 0.12)
const COMBO_COLOR := Color("ff5a36")
const RANK_COLOR := Color("f2a541")
const HOT_WHITE := Color(1.0, 0.95, 0.85)
const KEY_COLOR := Color("f2a541")
const ACTION_COLOR := Color("b8c7cf")
const DIM := Color("5c6f7a")
## Seconds the controls panel stays up at the start of a run.
const HELP_TIME := 9.0
## [key, action] pairs for the controls panel.
const CONTROLS: Array[Array] = [
	["A D", "MOVE"], ["SPACE", "JUMP"], ["J", "SLASH"], ["HOLD J", "QUICK-DRAW"], ["K", "PARRY"],
	["SHIFT", "DODGE"], ["S + J", "SLAM (AIR)"], ["F", "FOCUS"], ["R", "FREE LINKED"],
]
const COMBO_RANKS: Array[Array] = [
	[5, "SHARP"], [12, "RUTHLESS"], [20, "RELENTLESS"], [35, "UNSTOPPABLE"], [60, "LAST EDGE"],
]

var _vitals: HudVitals
var _combo_box: VBoxContainer
var _combo_count: Label
var _combo_rank: Label
var _help: PanelContainer
var _help_hint: Label
var _help_left: float = HELP_TIME
var _flash: ColorRect
var _slow_motion_tint: ColorRect
var _focus_active: bool = false
var _focus_ratio: float = 1.0


func _ready() -> void:
	layer = 5 # Above the atmosphere layer (fog, vignette).
	_slow_motion_tint = _full_rect(SLOW_MOTION_TINT)
	_slow_motion_tint.visible = false
	Events.focus_changed.connect(_on_focus_toggled)

	_vitals = HudVitals.new()
	_vitals.position = Vector2(8, 8)
	_vitals.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vitals)

	_combo_box = VBoxContainer.new()
	_combo_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	_combo_box.anchor_left = 1.0
	_combo_box.anchor_right = 1.0
	_combo_box.offset_left = -200.0
	_combo_box.offset_right = -10.0
	_combo_box.offset_top = 8.0
	_combo_box.add_theme_constant_override("separation", 1)
	_combo_box.modulate.a = 0.0
	_combo_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_combo_box)
	var count_row := HBoxContainer.new()
	count_row.alignment = BoxContainer.ALIGNMENT_END
	count_row.add_theme_constant_override("separation", 3)
	_combo_box.add_child(count_row)
	_combo_count = _label(24, COMBO_COLOR, HORIZONTAL_ALIGNMENT_RIGHT)
	count_row.add_child(_combo_count)
	var hits := _label(8, COMBO_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
	hits.text = "HITS"
	hits.size_flags_vertical = Control.SIZE_SHRINK_END
	count_row.add_child(hits)
	_combo_rank = _label(16, RANK_COLOR, HORIZONTAL_ALIGNMENT_RIGHT)
	_combo_box.add_child(_combo_rank)

	_help = _make_help()
	add_child(_help)
	_help_hint = _label(8, DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	_help_hint.text = "H  CONTROLS"
	_help_hint.anchor_left = 1.0
	_help_hint.anchor_right = 1.0
	_help_hint.anchor_top = 1.0
	_help_hint.anchor_bottom = 1.0
	_help_hint.offset_left = -120.0
	_help_hint.offset_right = -8.0
	_help_hint.offset_top = -16.0
	_help_hint.offset_bottom = -6.0
	_help_hint.modulate.a = 0.0
	add_child(_help_hint)

	_flash = _full_rect(Color(1, 0.97, 0.88, 0.0))
	Events.screen_flash.connect(_on_screen_flash)


func bind_player(player: Player) -> void:
	player.resolve.changed.connect(_vitals.set_resolve)
	player.focus.changed.connect(_on_focus_changed)
	player.combo_changed.connect(_on_combo_changed)
	_vitals.pips = player.resolve.pips
	_vitals.set_resolve(player.resolve.pips, player.resolve.max_pips)
	_on_focus_changed(player.focus.seconds, player.focus.max_seconds)


func _process(delta: float) -> void:
	var real_delta := delta / maxf(Engine.time_scale, 0.01)
	if Input.is_action_just_pressed(&"help"):
		_help_left = 0.0 if _help_left > 0.0 else INF
	_help_left = maxf(_help_left - real_delta, 0.0)
	var target := clampf(_help_left / 0.6, 0.0, 1.0) # Fade over the last 0.6 s.
	_help.modulate.a = move_toward(_help.modulate.a, target, real_delta * 4.0)
	_help_hint.modulate.a = move_toward(_help_hint.modulate.a, 0.7 if target == 0.0 else 0.0, real_delta * 3.0)


func _on_combo_changed(hits: int) -> void:
	if hits < 2:
		create_tween().tween_property(_combo_box, ^"modulate:a", 0.0, 0.3)
		return
	_combo_count.text = str(hits)
	var rank := ""
	for entry in COMBO_RANKS:
		if hits >= int(entry[0]):
			rank = str(entry[1])
	if rank != "" and rank != _combo_rank.text:
		Audio.play(&"rank_up", -6.0, 0.0)
		_combo_rank.add_theme_color_override("font_color", HOT_WHITE)
		create_tween().tween_method(_set_rank_color, HOT_WHITE, RANK_COLOR, 0.4)
	_combo_rank.text = rank
	_combo_box.modulate.a = 1.0
	# Pop on every hit: flash white-hot and bump up 2 px (no scaling: keeps the pixels crisp).
	_combo_count.add_theme_color_override("font_color", HOT_WHITE)
	create_tween().tween_method(_set_count_color, HOT_WHITE, COMBO_COLOR, 0.15)
	_combo_box.offset_top = 6.0
	create_tween().tween_property(_combo_box, ^"offset_top", 8.0, 0.1)


func _set_count_color(color: Color) -> void:
	_combo_count.add_theme_color_override("font_color", color)


func _set_rank_color(color: Color) -> void:
	_combo_rank.add_theme_color_override("font_color", color)


func _on_focus_changed(seconds: float, max_seconds: float) -> void:
	_focus_ratio = seconds / max_seconds if max_seconds > 0.0 else 0.0
	_vitals.set_focus(_focus_ratio, _focus_active)


func _on_focus_toggled(active: bool) -> void:
	_focus_active = active
	_slow_motion_tint.visible = active
	_vitals.set_focus(_focus_ratio, active)


func _on_screen_flash(strength: float) -> void:
	_flash.color.a = strength
	create_tween().tween_property(_flash, ^"color:a", 0.0, 0.18)


## Bottom-center panel of key chips: [KEY] ACTION.
func _make_help() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.07, 0.1, 0.72)
	style.border_color = Color("1f3a44")
	style.set_border_width_all(1)
	style.set_content_margin_all(5)
	panel.add_theme_stylebox_override("panel", style)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -250.0
	panel.offset_right = 250.0
	panel.offset_top = -40.0
	panel.offset_bottom = -8.0
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var flow := HFlowContainer.new()
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 3)
	panel.add_child(flow)
	var key_style := StyleBoxFlat.new()
	key_style.bg_color = Color("1a1410")
	key_style.border_color = Color("5a4630")
	key_style.set_border_width_all(1)
	key_style.content_margin_left = 2
	key_style.content_margin_right = 2
	key_style.content_margin_top = 1
	key_style.content_margin_bottom = 0
	for entry in CONTROLS:
		var chip := HBoxContainer.new()
		chip.add_theme_constant_override("separation", 3)
		var key := _label(8, KEY_COLOR, HORIZONTAL_ALIGNMENT_CENTER)
		key.text = str(entry[0])
		key.add_theme_stylebox_override("normal", key_style)
		chip.add_child(key)
		var action := _label(8, ACTION_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
		action.text = str(entry[1])
		chip.add_child(action)
		flow.add_child(chip)
	return panel


func _label(font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _full_rect(color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	return rect
