class_name Spikes
extends Node2D
## Floor spikes: cost the player 1 Resolve and bounce them up. Origin is the top-left
## corner; size is in pixels.

@export var size: Vector2 = Vector2(64, 16)
@export var color: Color = Color("d64545")
@export var bounce: float = 330.0
## Off when the level draws spikes with tiles instead.
@export var draw_visual: bool = true


func _ready() -> void:
	if draw_visual:
		_build_visual()
	_build_hitbox()


func _build_visual() -> void:
	var points := PackedVector2Array()
	var teeth := maxi(int(size.x / 8.0), 1)
	var tooth_width := size.x / teeth
	for i in teeth:
		points.append(Vector2(i * tooth_width, size.y))
		points.append(Vector2((i + 0.5) * tooth_width, 0.0))
	points.append(Vector2(size.x, size.y))
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.color = color
	add_child(polygon)


func _build_hitbox() -> void:
	var hitbox := HitboxComponent.new()
	hitbox.collision_layer = Layers.ENEMY_ATTACK
	hitbox.collision_mask = Layers.PLAYER_HURTBOX
	hitbox.monitorable = false
	hitbox.active = true
	hitbox.auto_process = true
	hitbox.rehit_interval = 0.5
	hitbox.build_damage = _build_damage
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size - Vector2(4.0, 6.0)
	shape.shape = rect
	shape.position = size / 2.0 + Vector2(0.0, 3.0)
	hitbox.add_child(shape)
	add_child(hitbox)


func _build_damage() -> DamageInfo:
	var info := DamageInfo.new()
	info.resolve_cost = 1.0
	info.knockback = Vector2(0.0, -bounce)
	info.source = self
	return info
