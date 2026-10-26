class_name CorpsePiece
extends RigidBody2D
## The remains of a dead machine: either the two halves of a frame cut by a blade (the cut
## edge glows, then cools) or the whole frame thrown by the killing blow. Pieces tumble and
## bounce off the level, then blink and burst into scrap. Visual only: they collide with the
## level but nothing collides with them.
##
## Pieces stay frozen for `hold` seconds first, so the cut reads during the hit freeze
## before the halves fly apart.

const SHADER := preload("res://game/fx/slice.gdshader")
## How hard the halves spring apart along the cut normal, and the upward pop.
const SPLIT_SPEED := 130.0
const POP_SPEED := 170.0
## Share of the killing blow's knockback the remains carry.
const PUSH_SHARE := 0.7
const SPIN_MIN := 4.0
const SPIN_MAX := 9.0
const COOL_TIME := 1.0
const BLINK_TIME := 0.25
## Impacts faster than this play a clank and kick up dust.
const CLANK_SPEED := 90.0

var _sprite: Sprite2D
var _velocity: Vector2
var _spin: float
var _life: float
var _hold: float
var _age: float = 0.0
var _released: bool = false
var _rng := RandomNumberGenerator.new()


## The cut line in frame pixels for a sprite drawn facing `facing` (frames are drawn
## mirrored when facing left). `center` is where the cut passes, relative to the sprite's
## origin point in the world; `direction` is the cut's direction in the world.
static func frame_cut(origin: Vector2, center: Vector2, direction: Vector2, facing: int) -> Dictionary:
	var mirror := Vector2(-1.0 if facing < 0 else 1.0, 1.0)
	var normal := direction.normalized().orthogonal() * mirror
	return {"point": origin + center * mirror, "normal": normal}


## Cuts `frame` (an AtlasTexture from a sprite sheet) in two along `direction` through
## `center` (world) and throws the halves. `at` is the sprite's origin in the world.
static func slice(parent: Node, frame: Texture2D, origin: Vector2, at: Vector2, facing: int,
		center: Vector2, direction: Vector2, push: Vector2, hold: float, life: float) -> void:
	var cut := frame_cut(origin, center - at, direction, facing)
	var world_normal := direction.normalized().orthogonal()
	for side: float in [1.0, -1.0]:
		var piece := CorpsePiece.new()
		var piece_center := center + world_normal * side * 5.0
		piece._setup(frame, origin, at - piece_center, facing, cut, side)
		piece._velocity = push * PUSH_SHARE + world_normal * side * SPLIT_SPEED + Vector2(0.0, -POP_SPEED)
		piece._spin = side * piece._rng.randf_range(SPIN_MIN, SPIN_MAX)
		piece._hold = hold
		piece._life = life
		parent.add_child(piece)
		piece.global_position = piece_center
		piece.reset_physics_interpolation()
		piece._add_embers(center - piece_center)


## Throws the whole frame (a kill that isn't a blade cut, e.g. a deflected bolt).
static func throw(parent: Node, frame: Texture2D, origin: Vector2, at: Vector2, facing: int,
		center: Vector2, push: Vector2, hold: float, life: float) -> void:
	var piece := CorpsePiece.new()
	piece._setup(frame, origin, at - center, facing, {"point": Vector2.ZERO, "normal": Vector2.UP}, 0.0)
	piece._velocity = push * PUSH_SHARE + Vector2(0.0, -POP_SPEED)
	piece._spin = (1.0 if push.x >= 0.0 else -1.0) * piece._rng.randf_range(SPIN_MIN, SPIN_MAX)
	piece._hold = hold
	piece._life = life
	parent.add_child(piece)
	piece.global_position = center
	piece.reset_physics_interpolation()
	piece._add_smoke()


func _setup(frame: Texture2D, origin: Vector2, sprite_position: Vector2, facing: int,
		cut: Dictionary, side: float) -> void:
	_rng.randomize()
	collision_layer = 0
	collision_mask = Layers.WORLD | Layers.ONE_WAY
	gravity_scale = 1.6
	angular_damp = 1.5
	contact_monitor = true
	max_contacts_reported = 2
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	freeze = true
	var bounce := PhysicsMaterial.new()
	bounce.bounce = 0.3
	bounce.friction = 0.9
	physics_material_override = bounce
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(12.0, 7.0)
	shape.shape = box
	add_child(shape)
	_sprite = Sprite2D.new()
	_sprite.texture = frame
	_sprite.centered = false
	_sprite.offset = -origin
	_sprite.position = sprite_position
	_sprite.scale.x = -1.0 if facing < 0 else 1.0
	var material := ShaderMaterial.new()
	material.shader = SHADER
	var atlas := frame as AtlasTexture
	if atlas and atlas.atlas:
		var sheet := atlas.atlas.get_size()
		material.set_shader_parameter(&"region", Vector4(atlas.region.position.x / sheet.x,
			atlas.region.position.y / sheet.y, atlas.region.size.x / sheet.x, atlas.region.size.y / sheet.y))
		material.set_shader_parameter(&"frame_size", atlas.region.size)
	else:
		material.set_shader_parameter(&"frame_size", frame.get_size())
	material.set_shader_parameter(&"cut_point", cut["point"])
	material.set_shader_parameter(&"cut_normal", cut["normal"])
	material.set_shader_parameter(&"side", side)
	_sprite.material = material
	add_child(_sprite)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_age += delta
	if not _released and _age >= _hold:
		_released = true
		freeze = false
		linear_velocity = _velocity
		angular_velocity = _spin


func _process(_delta: float) -> void:
	var material := _sprite.material as ShaderMaterial
	material.set_shader_parameter(&"heat", clampf(1.0 - (_age - _hold) / COOL_TIME, 0.0, 1.0))
	var blink_start := _hold + _life
	if _age >= blink_start:
		_sprite.visible = fmod(_age - blink_start, 0.08) < 0.05
		if _age >= blink_start + BLINK_TIME:
			Feel.death_burst(global_position, Color("4fd1c5"), 0.35)
			Audio.play(&"scrap_pop", -12.0, 0.1)
			queue_free()


func _on_body_entered(_body: Node) -> void:
	if linear_velocity.length() < CLANK_SPEED:
		return
	Audio.play(&"clank", -14.0, 0.15)
	Feel.dust(global_position + Vector2(0.0, 4.0), 4, 0.5)


## Sparks drip from the hot cut for a moment.
func _add_embers(offset: Vector2) -> void:
	var sparks := CPUParticles2D.new()
	sparks.position = offset
	sparks.local_coords = false
	sparks.amount = 14
	sparks.lifetime = 0.5
	sparks.one_shot = true
	sparks.explosiveness = 0.2
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = 5.0
	sparks.direction = Vector2.UP
	sparks.spread = 70.0
	sparks.gravity = Vector2(0.0, 300.0)
	sparks.initial_velocity_min = 20.0
	sparks.initial_velocity_max = 90.0
	sparks.scale_amount_max = 1.6
	var ramp := Gradient.new()
	ramp.set_color(0, Feel.WHITE_HOT * Feel.GLOW)
	ramp.set_color(1, Color(Feel.HOT, 0.0))
	sparks.color_ramp = ramp
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	sparks.material = additive
	sparks.z_index = 1
	add_child(sparks)
	sparks.emitting = true


## A broken machine trails dark smoke while it falls.
func _add_smoke() -> void:
	var smoke := CPUParticles2D.new()
	smoke.local_coords = false
	smoke.amount = 18
	smoke.lifetime = 0.8
	smoke.direction = Vector2.UP
	smoke.spread = 30.0
	smoke.gravity = Vector2(0.0, -40.0)
	smoke.initial_velocity_min = 5.0
	smoke.initial_velocity_max = 20.0
	smoke.scale_amount_min = 2.0
	smoke.scale_amount_max = 4.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.16, 0.15, 0.16, 0.7))
	ramp.set_color(1, Color(0.08, 0.08, 0.1, 0.0))
	smoke.color_ramp = ramp
	smoke.show_behind_parent = true
	add_child(smoke)
	smoke.emitting = true
