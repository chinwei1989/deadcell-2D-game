class_name EnemyBase
extends CharacterBody2D
## Base for all enemies (PLAN.md section 9). Simulates only on the host (its multiplayer
## authority). Numbers come from an EnemyData resource.
##
## Subclasses override _ai(delta) with a `match state:` over StringName states and switch
## with set_state(). The base handles these states itself:
##   &"hurt"       flinch: recoils from a hit, helpless for data.flinch_frames, then idle
##   &"staggered"  posture broken: helpless, can be executed by a player blade
##   &"stunned"    briefly helpless after being parried
##   &"dead"       machines become CorpsePieces (cut in two by blade kills); people collapse
## Attacks are armored (no flinch) while telegraphing or while the attack hitbox is active,
## unless data.flinch_during_attacks. Every hit also kicks the visual back and squashes it.
## Required child nodes: Visual, Health, Posture, Hurtbox, and either sprite_sheet set
## (an animated pixel sprite, see SpriteSheet) or a gray-box Visual/Body Polygon2D.
## Optional: AttackHitbox (HitboxComponent, enabled by the subclass during attacks),
## PostureBar/Fill (ColorRect).
##
## Sprite animations: the animation named like the current state plays if it exists;
## ANIMATION_ALIASES maps other states (e.g. approach → run); otherwise "idle".

signal died

const FLASH_TIME := 0.06
## After the white flash, the hit spot glows like heated metal and cools.
const BURN_COLOR := Color(1.0, 0.5, 0.18)
const BURN_TIME := 0.22
const BURN_AMOUNT := 0.55
## Visual recoil on every hit: kick back (pixels), squash, tilt; eases out over REACT_TIME.
const REACT_TIME := 0.2
const REACT_KICK := 5.0
const REACT_SQUASH := 0.22
const REACT_TILT := 0.18
const SCRAP_COLOR := Color("4fd1c5")
const STAGGER_COLOR := Color("4fd1c5")
## Extra damage taken while staggered.
const STAGGER_DAMAGE_MULTIPLIER := 1.5
const ANIMATION_ALIASES: Dictionary = {
	&"approach": &"run",
	&"staggered": &"stagger",
	&"stunned": &"stagger",
	&"hurt": &"stagger",
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
var _burn_left: float = 0.0
var _react_left: float = 0.0
var _react_direction: Vector2 = Vector2.ZERO
## The hit being applied (read when it kills: direction, blade or not).
var _last_hit: DamageInfo
var _visual_rng := RandomNumberGenerator.new()
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
		&"hurt":
			_helpless(delta)
			if state_past_frames(data.flinch_frames):
				set_state(&"idle")
		&"stunned":
			_helpless(delta)
			if state_time >= data.parried_stun:
				set_state(&"idle")
		_:
			target = _find_target()
			_ai(delta)
	move_and_slide()


func _process(delta: float) -> void:
	if state == &"dead":
		return
	_flash_left = maxf(_flash_left - delta, 0.0)
	_burn_left = maxf(_burn_left - delta, 0.0)
	_react_left = maxf(_react_left - delta, 0.0)
	_animate_reaction()
	var tint := Color.WHITE
	var amount := 0.0
	if _flash_left > 0.0:
		amount = 1.0
	elif _burn_left > 0.0:
		tint = BURN_COLOR
		amount = BURN_AMOUNT * _burn_left / BURN_TIME
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


## Kick back along the hit, squash, tilt, and jitter for the first half of the reaction.
func _animate_reaction() -> void:
	var r := _react_left / REACT_TIME
	var jitter := Vector2.ZERO
	if r > 0.5:
		jitter = Vector2(_visual_rng.randi_range(-1, 1), _visual_rng.randi_range(-1, 1))
	visual.position = (_react_direction * REACT_KICK * r * r).round() + jitter
	visual.scale = Vector2(facing * (1.0 + REACT_SQUASH * r), 1.0 - REACT_SQUASH * 0.8 * r)
	visual.rotation = REACT_TILT * r * signf(_react_direction.x)


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
	var armored := is_armored()
	if data.max_posture > 0.0:
		posture.add(info.posture)
	_last_hit = info
	info.killed = health.damage(info.amount * multiplier)
	_flash_left = FLASH_TIME
	_burn_left = BURN_TIME
	_react_left = REACT_TIME
	_react_direction = info.knockback.normalized() if info.knockback != Vector2.ZERO else Vector2(-facing, 0.0)
	if not info.killed and state != &"staggered":
		velocity += info.knockback * (1.0 - data.knockback_resistance)
	if should_flinch(data, state, armored, info.killed):
		set_state(&"hurt")
	Events.enemy_damaged.emit(self, info)


## Whether a hit interrupts the enemy with a flinch (pure: unit tested).
static func should_flinch(enemy_data: EnemyData, current_state: StringName, armored: bool, killed: bool) -> bool:
	if killed or enemy_data.flinch_frames <= 0:
		return false
	if current_state in [&"staggered", &"stunned", &"dead", &"freed"]:
		return false
	return enemy_data.flinch_during_attacks or not armored


## True while attacking: telegraphing a wind-up or with the attack hitbox live.
func is_armored() -> bool:
	return _telegraphing or (attack_hitbox != null and attack_hitbox.active)


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
	_last_hit = info
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
	var push := _last_hit.knockback if _last_hit else Vector2.ZERO
	var center := _body_center()
	if not data.is_machine:
		Audio.play(&"death", -8.0)
		_collapse(push)
		return
	Feel.death_burst(center, SCRAP_COLOR, 0.6)
	Audio.play(&"machine_death", -4.0)
	if _sprite == null:
		var tween := create_tween()
		tween.tween_property(visual, ^"modulate:a", 0.0, 0.25)
		tween.tween_callback(queue_free)
		return
	var frame := _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame)
	var origin := SpriteSheet.origin(sprite_sheet)
	var hold := FrameTime.seconds(_last_hit.hit_freeze_frames) if _last_hit else 0.0
	if _last_hit and _last_hit.can_execute:
		# A blade kill cuts the machine in two along the swing.
		var direction := push if push != Vector2.ZERO else Vector2(-facing, 0.0)
		direction = direction.rotated(_visual_rng.randf_range(-0.3, 0.3))
		CorpsePiece.slice(get_parent(), frame, origin, global_position, facing, center, direction,
			push, hold, data.corpse_time)
		Audio.play(&"slice", -2.0, 0.08)
	else:
		CorpsePiece.throw(get_parent(), frame, origin, global_position, facing, center, push, hold,
			data.corpse_time)
	queue_free()


## The middle of the body (the hurtbox shape), in the world.
func _body_center() -> Vector2:
	for child in hurtbox.get_children():
		if child is CollisionShape2D:
			return (child as CollisionShape2D).global_position
	return global_position


## People fall away from the blow and lie still, then fade.
func _collapse(push: Vector2) -> void:
	var away := signf(push.x) if push.x != 0.0 else float(-facing)
	visual.position = Vector2.ZERO
	visual.scale = Vector2(facing, 1.0)
	var tween := create_tween()
	tween.tween_property(visual, ^"rotation", away * PI * 0.5, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(visual, ^"position", Vector2(away * 6.0, 0.0), 0.45)
	tween.tween_callback(Feel.dust.bind(global_position + Vector2(away * 14.0, 0.0), 6, 1.0))
	tween.tween_interval(data.corpse_time)
	tween.tween_property(visual, ^"modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
