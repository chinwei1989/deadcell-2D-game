class_name ExitDoor
extends Area2D
## The way out of a room: sealed (red) while enemies remain, open (teal, glowing) once the
## room is cleared. Walking into it while open emits `entered` once. Origin = feet.

signal entered

const SIZE := Vector2(26, 44)
const FRAME := Color("0b1620")
const STEEL := Color("1f3a44")
const SEALED := Color("d64545")
const OPEN := Color(0.31 * 1.6, 0.82 * 1.6, 0.77 * 1.6) # Above 1: glows through bloom.

var is_open: bool = false

var _used: bool = false
var _time: float = 0.0
var _label: Label
var _light: PointLight2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYER_BODY
	monitorable = false
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(SIZE.x - 10.0, SIZE.y)
	shape.shape = box
	shape.position = Vector2(0.0, -SIZE.y / 2.0)
	add_child(shape)
	z_index = -1
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(60.0, 10.0)
	_label.position = Vector2(-30.0, -SIZE.y - 14.0)
	_label.z_index = 20
	add_child(_label)
	_light = PointLight2D.new()
	_light.texture = LevelLight.radial_texture()
	_light.texture_scale = 0.9
	_light.height = 10.0
	_light.position = Vector2(0.0, -SIZE.y / 2.0)
	add_child(_light)
	body_entered.connect(_on_body_entered)
	_refresh()


func open() -> void:
	if is_open:
		return
	is_open = true
	Audio.play(&"door_open", -4.0)
	Feel.light_flash(global_position + Vector2(0.0, -SIZE.y / 2.0), Color("4fd1c5"), 90.0, 1.2, 0.5)
	_refresh()
	for body in get_overlapping_bodies():
		_on_body_entered(body)


func _process(delta: float) -> void:
	_time += delta
	if not is_open:
		var player := get_tree().get_first_node_in_group(&"players") as Node2D
		_label.visible = player != null and player.global_position.distance_to(global_position) < 110.0
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2(-SIZE.x / 2.0, -SIZE.y), SIZE)
	draw_rect(rect.grow(2.0), FRAME)
	draw_rect(rect, STEEL)
	var inner := rect.grow(-4.0)
	if is_open:
		var pulse := 0.85 + 0.15 * sin(_time * 4.0)
		draw_rect(inner, Color(OPEN * pulse, 0.55))
		for i in 3: # Chevrons pointing through the door.
			var x := inner.position.x + 5.0 + i * 6.0
			var y := inner.get_center().y
			var c := Color(OPEN, 0.4 + 0.6 * fposmod(_time * 2.0 - i * 0.3, 1.0))
			draw_line(Vector2(x, y - 4.0), Vector2(x + 3.0, y), c, 1.0)
			draw_line(Vector2(x + 3.0, y), Vector2(x, y + 4.0), c, 1.0)
	else:
		draw_rect(inner, Color("10161c"))
		for y in range(int(inner.position.y) + 3, int(inner.end.y), 5): # Shutter slats.
			draw_line(Vector2(inner.position.x, y), Vector2(inner.end.x, y), STEEL, 1.0)
		var blink := 0.6 + 0.4 * sin(_time * 5.0)
		draw_rect(Rect2(Vector2(-3.0, -SIZE.y + 6.0), Vector2(6.0, 2.0)), Color(SEALED, blink))


func _refresh() -> void:
	_label.visible = is_open
	_label.text = "EXIT" if is_open else "SEALED"
	_label.add_theme_color_override("font_color", Color("4fd1c5") if is_open else SEALED)
	_light.color = Color("4fd1c5") if is_open else SEALED
	_light.energy = 1.4 if is_open else 0.6


func _on_body_entered(body: Node) -> void:
	if is_open and not _used and body is Player:
		_used = true
		entered.emit()
