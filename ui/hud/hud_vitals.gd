class_name HudVitals
extends Control
## The player's vitals, drawn pixel by pixel (no textures): Resolve pips as diamonds on a
## dark plate and the Focus bar under them. Losing a pip shakes the plate and flashes the
## lost pip; the last pip pulses red.

const PIP_SIZE := 9
const PIP_GAP := 2
const PADDING := 4
const BAR_HEIGHT := 4
const PLATE := Color(0.035, 0.07, 0.1, 0.62)
const ACCENT := Color("f2a541")
const PIP_FULL := Color("f2a541")
const PIP_HOT := Color(1.0, 0.92, 0.7)
const PIP_EMPTY := Color("1f2c36")
const PIP_RIM := Color("5a4630")
const OUTLINE := Color("0b1620")
const DANGER := Color("ff5a36")
const FOCUS := Color("4fd1c5")
const FOCUS_BACK := Color("10262e")
const HIT_TIME := 0.35

var pips: float = 4.0
var max_pips: float = 4.0
var focus_ratio: float = 1.0
var focus_active: bool = false

var _hit_left: float = 0.0
var _gain_left: float = 0.0
var _lost_pip: int = -1
var _time: float = 0.0
var _rng := RandomNumberGenerator.new()


func set_resolve(new_pips: float, new_max: float) -> void:
	if new_pips < pips:
		_hit_left = HIT_TIME
		_lost_pip = int(ceil(new_pips))
	elif new_pips > pips:
		_gain_left = HIT_TIME
	pips = new_pips
	max_pips = new_max
	custom_minimum_size = plate_size()
	size = custom_minimum_size
	queue_redraw()


func set_focus(ratio: float, active: bool) -> void:
	focus_ratio = clampf(ratio, 0.0, 1.0)
	focus_active = active
	queue_redraw()


func plate_size() -> Vector2:
	var count := int(ceil(max_pips))
	return Vector2(PADDING * 2 + count * PIP_SIZE + (count - 1) * PIP_GAP, PADDING * 3 + PIP_SIZE + BAR_HEIGHT)


func _process(delta: float) -> void:
	_time += delta / maxf(Engine.time_scale, 0.01)
	_hit_left = maxf(_hit_left - delta, 0.0)
	_gain_left = maxf(_gain_left - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var shake := Vector2.ZERO
	if _hit_left > HIT_TIME * 0.5:
		shake = Vector2(_rng.randi_range(-1, 1), _rng.randi_range(-1, 1))
	var plate := Rect2(shake, plate_size())
	draw_rect(plate, PLATE)
	draw_rect(Rect2(plate.position, Vector2(1, plate.size.y)), ACCENT)
	var count := int(ceil(max_pips))
	var low := pips <= 1.0 and pips > 0.0
	for i in count:
		var at := plate.position + Vector2(PADDING + i * (PIP_SIZE + PIP_GAP), PADDING)
		_draw_pip(at, clampf(pips - i, 0.0, 1.0), i, low)
	var bar := Rect2(plate.position + Vector2(PADDING, PADDING * 2 + PIP_SIZE), Vector2(plate.size.x - PADDING * 2, BAR_HEIGHT))
	draw_rect(bar.grow(1), OUTLINE)
	draw_rect(bar, FOCUS_BACK)
	var fill := FOCUS
	if focus_active:
		fill = FOCUS.lightened(0.35 + 0.25 * sin(_time * 12.0))
	draw_rect(Rect2(bar.position, Vector2(roundf(bar.size.x * focus_ratio), bar.size.y)), fill)
	if focus_ratio >= 1.0:
		draw_rect(Rect2(bar.position + Vector2(bar.size.x - 1, -1), Vector2(1, BAR_HEIGHT + 2)), Color.WHITE)


func _draw_pip(at: Vector2, fill: float, index: int, low: bool) -> void:
	var c := at + Vector2(4, 4)
	draw_colored_polygon(_diamond(c, 5.0), OUTLINE)
	draw_colored_polygon(_diamond(c, 4.0), PIP_RIM if fill <= 0.0 else PIP_EMPTY)
	draw_colored_polygon(_diamond(c, 3.0), PIP_EMPTY)
	var color := PIP_FULL
	if low:
		color = PIP_FULL.lerp(DANGER, 0.5 + 0.5 * sin(_time * 9.0))
	if _gain_left > 0.0:
		color = color.lerp(PIP_HOT, _gain_left / HIT_TIME)
	if fill >= 1.0:
		draw_colored_polygon(_diamond(c, 4.0), color)
		draw_rect(Rect2(c + Vector2(-1, -2), Vector2(1, 1)), PIP_HOT) # Glint.
	elif fill >= 0.5:
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -4), c + Vector2(0, 4), c + Vector2(-4, 0)]), color)
	if index == _lost_pip and _hit_left > 0.0:
		var flash := Color(1, 1, 1, _hit_left / HIT_TIME)
		draw_colored_polygon(_diamond(c, 4.0 + 2.0 * (1.0 - _hit_left / HIT_TIME)), flash)


func _diamond(c: Vector2, r: float) -> PackedVector2Array:
	return PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
