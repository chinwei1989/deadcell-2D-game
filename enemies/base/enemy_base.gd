class_name EnemyBase
extends CharacterBody2D
## Base for all enemies (PLAN.md section 9). Simulates only on the host (its multiplayer
## authority). Numbers come from an EnemyData resource.
##
## Subclasses override _ai(delta) with a `match state:` over StringName states and switch
## with set_state(). The base handles these states itself:
##   &"staggered"  posture broken: helpless, can be executed by a player blade
##   &"stunned"    briefly helpless after being parried
##   &"dead"
## Required child nodes: Visual, Health, Posture, Hurtbox, and either sprite_sheet set
## (an animated pixel sprite, see SpriteSheet) or a gray-box Visual/Body Polygon2D.
## Optional: AttackHitbox (HitboxComponent, enabled by the subclass during attacks),
## PostureBar/Fill (ColorRect).
##
## Sprite animations: the animation named like the current state plays if it exists;
## ANIMATION_ALIASES maps other states (e.g. approach → run); otherwise "idle".

signal died

const FLASH_TIME := 0.05
const STAGGER_COLOR := Color("4fd1c5")
## Extra damage taken while staggered.
const STAGGER_DAMAGE_MULTIPLIER := 1.5
const ANIMATION_ALIASES: Dictionary = {
	&"approach": &"run",
	&"staggered": &"stagger",
	&"stunned": &"stagger",
	&"cooldown": &"idle",
}

@export var data: EnemyData
## Sprite sheet PNG made by tools/art/make_spritesheet.py; empty = gray-box polygons.
@export_file("*.png") var sprite_sheet: String = ""

var state: StringName = &"idle"
var state_time: float = 0.0
var facing: int = 1
var target: Player

var _flash_left: float = 0.0
var _telegraphing: bool = false
var _base_color: Color
var _posture_bar_width: float = 0.0

@onready var health: HealthComponent = $Health
@onready var posture: PostureComponent = $Posture
@onready var hurtbox: HurtboxComponent = $Hurtbox
@onready var visual: Node2D = $Visual
@onready var attack_hitbox: HitboxComponent = get_node_or_null(^"AttackHitbox")
@onready var _body: Polygon2D = get_node_or_null(^"Visual/Body")
var _sprite: AnimatedSprite2D
@onready var _posture_fill: ColorRect = get_node_or_null(^"PostureBar/Fill")


func _ready() -> void:
	assert(data != null, "%s needs an EnemyData resource" % name)
	add_to_group(&"enemies")
	add_to_group(&"targets")
	collision_layer = Layers.ENEMY_BODY
	collision_mask = Layers.WORLD | Layers.ONE_WAY
	health.max_health = data.max_health
	health.reset()
	posture.max_posture = maxf(data.max_posture, 1.0)
	posture.recovery_delay = data.posture_recovery_delay
	posture.recovery_rate = data.posture_recovery_rate
	posture.stagger_time = data.stagger_time
	hurtbox.received.connect(take_hit)
	posture.broken.connect(_on_posture_broken)
	posture.recovered.connect(_on_posture_recovered)
	health.died.connect(_die)
	if attack_hitbox:
		attack_hitbox.build_damage = build_attack_damage
	if _posture_fill:
		var bar := _posture_fill.get_parent() as ColorRect
		_posture_bar_width = bar.size.x
		bar.visible = data.max_posture > 0.0
	if sprite_sheet != "":
		_make_sprite()
	elif _body:
		_base_color = _body.color


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	state_time += delta
	match state:
		&"dead":
			return
		&"staggered":
			_helpless(delta)
		&"stunned":
			_helpless(delta)
			if state_time >= data.parried_stun:
				set_state(&"idle")
		_:
			target = _find_target()
			_ai(delta)
	move_and_slide()


func _process(delta: float) -> void:
	_flash_left = maxf(_flash_left - delta, 0.0)
	var tint := Color.WHITE
	var amount := 0.0
	if _flash_left > 0.0:
		amount = 1.0
	elif state == &"staggered":
		tint = STAGGER_COLOR
		amount = 0.45
	elif _telegraphing:
		# Blink toward white during an attack wind-up.
		amount = 0.3 + 0.3 * sin(Time.get_ticks_msec() * 0.03)
	if _sprite:
		var mat := _sprite.material as ShaderMaterial
		mat.set_shader_parameter(&"tint", tint)
		mat.set_shader_parameter(&"amount", amount)
		_play_animation_for_state()
	elif _body:
		_body.color = _base_color.lerp(tint, amount)
	if _posture_fill:
		_posture_fill.size.x = _posture_bar_width * posture.value / posture.max_posture


func _make_sprite() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "Sprite"
	_sprite.sprite_frames = SpriteSheet.frames(sprite_sheet)
	_sprite.centered = false
	_sprite.offset = -SpriteSheet.origin(sprite_sheet)
	_sprite.material = SpriteSheet.material(sprite_sheet)
	visual.add_child(_sprite)
	_sprite.play(&"idle")


func _play_animation_for_state() -> void:
	if state == &"dead":
		return
	var anim: StringName = state
	if not _sprite.sprite_frames.has_animation(anim):
		anim = ANIMATION_ALIASES.get(state, &"idle")
	if not _sprite.sprite_frames.has_animation(anim):
		anim = &"idle"
	if _sprite.animation != anim:
		_sprite.play(anim)


## Override in subclasses: movement and attack decisions.
func _ai(_delta: float) -> void:
	pass


func set_state(new_state: StringName) -> void:
	state = new_state
	state_time = 0.0
	_telegraphing = false
	if attack_hitbox:
		attack_hitbox.active = false


func telegraph() -> void:
	_telegraphing = true


func face(direction: int) -> void:
	if direction == 0:
		return
	facing = direction
	visual.scale.x = direction
	if attack_hitbox:
		attack_hitbox.scale.x = direction


func distance_to_target() -> float:
	return global_position.distance_to(target.global_position) if target else INF


func direction_to_target() -> int:
	if target == null:
		return facing
	return 1 if target.global_position.x >= global_position.x else -1


## True once the current state has lasted `frames` frames of game time.
func state_past_frames(frames: int) -> bool:
	return state_time > FrameTime.seconds(frames) + FrameTime.EPSILON


func apply_gravity(delta: float) -> void:
	if data.uses_gravity:
		velocity.y = minf(velocity.y + data.gravity * delta, data.max_fall_speed)


func run_toward(direction: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, direction * data.move_speed, data.acceleration * delta)


func build_attack_damage() -> DamageInfo:
	var info := DamageInfo.new()
	info.resolve_cost = data.attack_resolve_cost
	info.knockback = Vector2(data.attack_knockback.x * facing, data.attack_knockback.y)
	info.hit_freeze_frames = data.attack_hit_freeze
	info.source = self
	return info


func take_hit(info: DamageInfo) -> void:
	if state == &"dead":
		return
	if info.can_execute and is_executable():
		_execute(info)
		return
	var multiplier := STAGGER_DAMAGE_MULTIPLIER if posture.is_staggered() else 1.0
	if data.max_posture > 0.0:
		posture.add(info.posture)
	info.killed = health.damage(info.amount * multiplier)
	_flash_left = FLASH_TIME
	if not info.killed and state != &"staggered":
		velocity += info.knockback * (1.0 - data.knockback_resistance)
	Events.enemy_damaged.emit(self, info)


func is_executable() -> bool:
	return state == &"staggered"


## Called by a player who parried this enemy's attack.
func on_parried(_by: Node) -> void:
	if state == &"dead":
		return
	set_state(&"stunned")
	if data.max_posture > 0.0:
		posture.add(data.parried_posture_damage) # May break posture → staggered.


func _helpless(delta: float) -> void:
	apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)


func _find_target() -> Player:
	var best: Player = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group(&"players"):
		var player := node as Player
		if player == null or player.state == Player.State.DEAD:
			continue
		var distance := global_position.distance_to(player.global_position)
		if distance < best_distance:
			best = player
			best_distance = distance
	return best


func _execute(info: DamageInfo) -> void:
	info.executed = true
	info.killed = true
	Events.enemy_executed.emit(self, info.source)
	health.damage(health.current)


func _on_posture_broken() -> void:
	if state == &"dead":
		return
	set_state(&"staggered")
	Events.posture_broken.emit(self)


func _on_posture_recovered() -> void:
	if state == &"staggered":
		set_state(&"idle")


func _die() -> void:
	set_state(&"dead")
	velocity = Vector2.ZERO
	collision_layer = 0
	hurtbox.set_deferred(&"monitorable", false)
	remove_from_group(&"targets")
	died.emit()
	Events.enemy_killed.emit(self)
	Feel.death_burst(global_position + Vector2(0.0, -10.0 if data.uses_gravity else 0.0), Color("4fd1c5"), 1.0)
	Audio.play(&"machine_death", -4.0)
	var tween := create_tween()
	tween.tween_property(visual, ^"modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
