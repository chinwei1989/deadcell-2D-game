class_name Shockwave
extends HitboxComponent
## A crackling wave of energy running along the floor (the Warden's slam). It can't be
## parried or guarded: jump over it. Dies at walls, ledges or after `life` seconds.
## Origin = on the floor.

const HEIGHT := 14.0
const COLOR := Color(0.31 * 1.8, 0.82 * 1.8, 0.77 * 1.8)

var direction: float = 1.0
var speed: float = 230.0
var life: float = 1.4

var _age: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	collision_layer = Layers.ENEMY_ATTACK
	collision_mask = Layers.PLAYER_HURTBOX
	monitorable = false
	active = true
	auto_process = true
	add_to_group(&"shockwaves")
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(12.0, HEIGHT)
	shape.shape = box
	shape.position = Vector2(0.0, -HEIGHT / 2.0)
	add_child(shape)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = additive
	z_index = 5


func _physics_process(delta: float) -> void:
	super(delta)
	_age += delta
	var step := direction * speed * delta
	var space := get_world_2d().direct_space_state
	var ahead := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -6), global_position + Vector2(step + direction * 6.0, -6), Layers.WORLD)
	var below := PhysicsRayQueryParameters2D.create(global_position + Vector2(step, -2), global_position + Vector2(step, 6), Layers.WORLD | Layers.ONE_WAY)
	if _age >= life or not space.intersect_ray(ahead).is_empty() or space.intersect_ray(below).is_empty():
		Feel.dust(global_position, 4, 0.5)
		queue_free()
		return
	position.x += step
	queue_redraw()


func _draw() -> void:
	var fade := 1.0 - _age / life
	for i in 4: # Jagged arcs of energy.
		var points := PackedVector2Array()
		for j in 5:
			var y := -HEIGHT * j / 4.0
			points.append(Vector2(_rng.randf_range(-4.0, 4.0) - direction * j * 1.5, y))
		draw_polyline(points, Color(COLOR, 0.8 * fade), 1.0)
	draw_rect(Rect2(Vector2(-7.0, -2.0), Vector2(14.0, 2.0)), Color(COLOR, fade))
