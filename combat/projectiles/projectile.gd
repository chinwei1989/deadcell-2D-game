class_name Projectile
extends Area2D
## A bullet or bolt fired by an enemy. It hits players; a player's slash can deflect it,
## after which it flies back and hits enemies instead (PLAN.md section 5.1).
## Call launch() before adding it to the tree.

const ENEMY_COLOR := Color("4fd1c5")
const DEFLECTED_COLOR := Color("ff5a36")

@export var speed: float = 160.0
@export var lifetime: float = 4.0
@export var resolve_cost: float = 1.0

var velocity: Vector2 = Vector2.ZERO
var shooter: Node2D
var deflected: bool = false

var _age: float = 0.0
var _damage: float = 0.0
var _posture: float = 0.0
var _crit: bool = false
var _deflected_by: Node

@onready var _hitbox: HitboxComponent = $Hitbox
@onready var _trail: Line2D = $Trail


func launch(from_shooter: Node2D, direction: Vector2, launch_speed: float = -1.0) -> void:
	shooter = from_shooter
	if launch_speed > 0.0:
		speed = launch_speed
	velocity = direction.normalized() * speed
	rotation = velocity.angle()


func _ready() -> void:
	add_to_group(&"projectiles")
	collision_layer = Layers.PROJECTILES
	collision_mask = Layers.WORLD
	body_entered.connect(func(_body: Node2D) -> void: queue_free())
	_hitbox.collision_layer = Layers.ENEMY_ATTACK
	_hitbox.collision_mask = Layers.PLAYER_HURTBOX
	_hitbox.active = true
	_hitbox.auto_process = true
	_hitbox.build_damage = _build_damage
	_hitbox.hit_landed.connect(func(_hurtbox: HurtboxComponent, _info: DamageInfo) -> void: queue_free())
	_trail.default_color = ENEMY_COLOR


func _physics_process(delta: float) -> void:
	position += velocity * delta
	_age += delta
	if _age >= lifetime:
		queue_free()


func can_deflect() -> bool:
	return not deflected


func deflect(by: Node, direction: Vector2, perfect: bool, damage: float, posture: float, speed_multiplier: float) -> void:
	deflected = true
	_deflected_by = by
	_damage = damage
	_posture = posture
	_crit = perfect
	velocity = direction.normalized() * velocity.length() * speed_multiplier
	rotation = velocity.angle()
	_age = 0.0
	collision_layer = Layers.DEFLECTED
	_hitbox.collision_layer = Layers.PLAYER_ATTACK
	_hitbox.collision_mask = Layers.ENEMY_HURTBOX
	_hitbox.reset_hits()
	_trail.default_color = DEFLECTED_COLOR


## Blocked by a parry: the projectile is destroyed.
func on_parried(_by: Node) -> void:
	queue_free()


func on_blocked(_by: Node) -> void:
	queue_free()


func _build_damage() -> DamageInfo:
	var info := DamageInfo.new()
	info.source = self
	if deflected:
		info.amount = _damage
		info.posture = _posture
		info.is_crit = _crit
		info.knockback = velocity.normalized() * 80.0
		info.hit_freeze_frames = 6 if _crit else 3
		info.source_peer_id = _deflected_by.get_multiplayer_authority() if is_instance_valid(_deflected_by) else 1
	else:
		info.resolve_cost = resolve_cost
		info.knockback = Vector2(signf(velocity.x) * 140.0, -110.0)
	return info
