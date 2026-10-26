class_name Hud
extends CanvasLayer
## Gray-box HUD: Resolve pips, Focus meter, player state and a controls hint, plus a cold
## tint while Focus slow motion is on. Replace with the real HUD (PLAN.md section 19)
## once UI art exists.

const FULL_PIP := "◆"
const HALF_PIP := "◈"
const EMPTY_PIP := "◇"
const HINT := "Move A/D  Jump Space  Slash J/LMB (hold = quick-draw, aim W/S)  Parry K/RMB (hold = guard)  Dodge Shift  Focus F  Interact R"
const FOCUS_BAR_SIZE := Vector2(60, 3)
const FOCUS_COLOR := Color("4fd1c5")
const SLOW_MOTION_TINT := Color(0.31, 0.82, 0.773, 0.12)

const COMBO_RANKS: Array[Array] = [
	[5, "SHARP"], [12, "RUTHLESS"], [20, "RELENTLESS"], [35, "UNSTOPPABLE"], [60, "LAST EDGE"],
]

var _resolve_label: Label
var _state_label: Label
var _combo_count: Label
var _combo_rank: Label
var _flash: ColorRect
var _focus_fill: ColorRect
var _slow_motion_tint: ColorRect


func _ready() -> void:
	layer = 5 # Above the atmosphere layer (fog, vignette).
	_slow_motion_tint = ColorRect.new()
	_slow_motion_tint.color = SLOW_MOTION_TINT
	_slow_motion_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_slow_motion_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slow_motion_tint.visible = false
	add_child(_slow_motion_tint)

	_resolve_label = _make_label(Vector2(8, 6), 12, Color("f2a541"))
	var focus_back := ColorRect.new()
	focus_back.position = Vector2(8, 24)
	focus_back.size = FOCUS_BAR_SIZE
	focus_back.color = Color("1f3a44")
	add_child(focus_back)
	_focus_fill = ColorRect.new()
	_focus_fill.size = FOCUS_BAR_SIZE
	_focus_fill.color = FOCUS_COLOR
	focus_back.add_child(_focus_fill)
	_state_label = _make_label(Vector2(8, 30), 8, Color("8aa1ad"))
	_make_label(Vector2(8, 344), 8, FOCUS_COLOR).text = HINT
	Events.focus_changed.connect(func(active: bool) -> void: _slow_motion_tint.visible = active)

	_combo_count = _make_combo_label(40, 24, Color("ff5a36"))
	_combo_rank = _make_combo_label(70, 9, Color("f2a541"))

	_flash = ColorRect.new()
	_flash.color = Color(1, 0.97, 0.88, 0.0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	Events.screen_flash.connect(_on_screen_flash)


func bind_player(player: Player) -> void:
	player.resolve.changed.connect(_on_resolve_changed)
	player.focus.changed.connect(_on_focus_changed)
	player.state_changed.connect(_on_state_changed)
	player.combo_changed.connect(_on_combo_changed)
	_on_resolve_changed(player.resolve.pips, player.resolve.max_pips)
	_on_focus_changed(player.focus.seconds, player.focus.max_seconds)
	_on_state_changed(player.state)


func _on_resolve_changed(pips: float, max_pips: float) -> void:
	var text := ""
	for i in int(ceil(max_pips)):
		var fill := pips - i
		text += FULL_PIP if fill >= 1.0 else (HALF_PIP if fill >= 0.5 else EMPTY_PIP)
	_resolve_label.text = text


func _on_combo_changed(hits: int) -> void:
	if hits < 2:
		var fade := create_tween().set_parallel()
		fade.tween_property(_combo_count, ^"modulate:a", 0.0, 0.3)
		fade.tween_property(_combo_rank, ^"modulate:a", 0.0, 0.3)
		return
	_combo_count.text = "%d HITS" % hits
	var rank := ""
	for entry in COMBO_RANKS:
		if hits >= int(entry[0]):
			rank = str(entry[1])
	if rank != "" and rank != _combo_rank.text:
		Audio.play(&"rank_up", -6.0, 0.0)
	_combo_rank.text = rank
	_combo_count.modulate.a = 1.0
	_combo_rank.modulate.a = 1.0
	_combo_count.scale = Vector2(1.35, 1.35) # Pop on every hit.
	create_tween().tween_property(_combo_count, ^"scale", Vector2.ONE, 0.12)


func _on_screen_flash(strength: float) -> void:
	_flash.color.a = strength
	create_tween().tween_property(_flash, ^"color:a", 0.0, 0.18)


func _make_combo_label(top: float, font_size: int, color: Color) -> Label:
	var label := _make_label(Vector2.ZERO, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.anchor_left = 1.0
	label.anchor_right = 1.0
	label.offset_left = -170.0
	label.offset_right = -10.0
	label.offset_top = top
	label.pivot_offset = Vector2(160.0, 12.0)
	label.add_theme_color_override("font_outline_color", Color("0b1620"))
	label.add_theme_constant_override("outline_size", 4)
	label.modulate.a = 0.0
	return label


func _on_focus_changed(seconds: float, max_seconds: float) -> void:
	_focus_fill.size.x = FOCUS_BAR_SIZE.x * seconds / max_seconds


func _on_state_changed(state: Player.State) -> void:
	_state_label.text = Player.State.keys()[state]


func _make_label(at: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label
