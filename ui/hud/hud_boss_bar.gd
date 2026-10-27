class_name HudBossBar
extends Control
## A boss's name, health and posture across the top of the screen, drawn in _draw(). Lost
## health first shows as a pale "ghost" that drains after a moment, so big hits read.

const WIDTH := 220.0
const HEALTH_HEIGHT := 5.0
const POSTURE_HEIGHT := 2.0
const PLATE := Color(0.035, 0.07, 0.1, 0.7)
const OUTLINE := Color("0b1620")
const HEALTH := Color("d64545")
const HEALTH_LOW := Color("ff5a36")
const GHOST := Color(1.0, 0.92, 0.8)
const POSTURE := Color("f2a541")
const GHOST_DELAY := 0.5
const GHOST_SPEED := 0.35

var boss: EnemyBase

var _ghost: float = 1.0
var _ghost_wait: float = 0.0
var _last: float = 1.0
var _name: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(WIDTH + 8.0, 24.0)
	size = custom_minimum_size
	_name = Label.new()
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.size = Vector2(WIDTH + 8.0, 10.0)
	_name.position = Vector2(0.0, 1.0)
	_name.add_theme_color_override("font_color", Color("e8d8c8"))
	add_child(_name)


func set_title(text: String) -> void:
	_name.text = text


func _process(delta: float) -> void:
	if not is_instance_valid(boss):
		boss = null
		return
	var ratio := boss.health.current / boss.health.max_health
	if ratio < _last:
		_ghost_wait = GHOST_DELAY
	_last = ratio
	_ghost_wait -= delta
	if _ghost_wait <= 0.0:
		_ghost = move_toward(_ghost, ratio, GHOST_SPEED * delta)
	_ghost = maxf(_ghost, ratio)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PLATE)
	var bar := Rect2(Vector2(4.0, 13.0), Vector2(WIDTH, HEALTH_HEIGHT))
	draw_rect(bar.grow(1.0), OUTLINE)
	draw_rect(bar, Color("2a1418"))
	draw_rect(Rect2(bar.position, Vector2(roundf(WIDTH * _ghost), HEALTH_HEIGHT)), GHOST)
	var color := HEALTH_LOW if _last < 0.25 else HEALTH
	draw_rect(Rect2(bar.position, Vector2(roundf(WIDTH * _last), HEALTH_HEIGHT)), color)
	if boss:
		var posture := boss.posture.value / boss.posture.max_posture
		var stagger := boss.posture.is_staggered()
		var p := Rect2(bar.position + Vector2(0.0, HEALTH_HEIGHT + 2.0), Vector2(WIDTH, POSTURE_HEIGHT))
		draw_rect(p, Color("1a1410"))
		draw_rect(Rect2(p.position, Vector2(roundf(WIDTH * (1.0 if stagger else posture)), POSTURE_HEIGHT)),
			Color("4fd1c5") if stagger else POSTURE)
