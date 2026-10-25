class_name Hud
extends CanvasLayer
## Gray-box HUD: Resolve pips, player state and a controls hint. Replace with the real
## HUD (PLAN.md section 19) once UI art exists.

const FULL_PIP := "◆"
const HALF_PIP := "◈"
const EMPTY_PIP := "◇"
const HINT := "Move A/D  Jump Space  Slash J/LMB (aim W/S)  Dodge Shift  ·  Down+Jump drops through"

var _resolve_label: Label
var _state_label: Label


func _ready() -> void:
	_resolve_label = _make_label(Vector2(8, 6), 12, Color("f2a541"))
	_state_label = _make_label(Vector2(8, 22), 8, Color("8aa1ad"))
	_make_label(Vector2(8, 344), 8, Color("4fd1c5")).text = HINT


func bind_player(player: Player) -> void:
	player.resolve.changed.connect(_on_resolve_changed)
	player.state_changed.connect(_on_state_changed)
	_on_resolve_changed(player.resolve.pips, player.resolve.max_pips)
	_on_state_changed(player.state)


func _on_resolve_changed(pips: float, max_pips: float) -> void:
	var text := ""
	for i in int(ceil(max_pips)):
		var fill := pips - i
		text += FULL_PIP if fill >= 1.0 else (HALF_PIP if fill >= 0.5 else EMPTY_PIP)
	_resolve_label.text = text


func _on_state_changed(state: Player.State) -> void:
	_state_label.text = Player.State.keys()[state]


func _make_label(at: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label
