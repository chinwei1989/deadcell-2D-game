class_name Player
extends CharacterBody2D
## Player character controller (gray-box Ronin; PLAN.md sections 4 and 5).
##
## Runs only on the peer that owns this player (its multiplayer authority). All numbers
## come from the PlayerTuning resource. States: NORMAL (run/jump/wall), DODGE, SLASH,
## HURT, DEAD. Not yet built: parry, deflect, quick-draw, Focus, executions (see AGENTS.md).

signal state_changed(new_state: State)
signal died
signal respawned

enum State { NORMAL, DODGE, SLASH, HURT, DEAD }

@export var tuning: PlayerTuning

var state: State = State.NORMAL
var facing: int = 1
var spawn_position: Vector2

var _coyote_left: float = 0.0
var _jump_buffer_left: float = 0.0
var _air_jumps_left: int = 0
var _drop_through_left: float = 0.0
var _dodge_elapsed: float = 0.0
var _dodge_cooldown_left: float = 0.0
var _dodge_direction: int = 1
var _hurt_left: float = 0.0
var _respawn_left: float = 0.0
var _slash_index: int = 0
var _slash_frame: int = 0
var _slash_buffered: bool = false
var _slash_aim: Vector2 = Vector2.RIGHT

@onready var resolve: ResolveComponent = $Resolve
@onready var _visual: Node2D = $Visual
@onready var _slash_pivot: Node2D = $SlashPivot
@onready var _slash_trail: Line2D = $SlashPivot/SlashTrail
@onready var _hitbox: HitboxComponent = $SlashPivot/Hitbox
@onready var _hurtbox: HurtboxComponent = $Hurtbox


func _ready() -> void:
	assert(tuning != null, "Player needs a PlayerTuning resource")
	spawn_position = global_position
	resolve.max_pips = tuning.max_resolve
	resolve.invulnerability_time = tuning.hurt_invulnerability
	resolve.reset()
	_hitbox.build_damage = _build_slash_damage
	_hitbox.hit_landed.connect(_on_slash_hit)
	_hurtbox.received.connect(_on_hurt)
	_slash_trail.visible = false


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	_tick_timers(delta)
	match state:
		State.NORMAL:
			_state_normal(delta)
		State.DODGE:
			_state_dodge(delta)
		State.SLASH:
			_state_slash(delta)
		State.HURT:
			_state_hurt(delta)
		State.DEAD:
			_state_dead(delta)
	move_and_slide()
	if is_on_floor():
		_coyote_left = tuning.coyote_time
		_air_jumps_left = tuning.air_jumps
	_hurtbox.invulnerable = _in_dodge_iframes() or resolve.is_invulnerable() or state == State.DEAD


# --- States ---------------------------------------------------------------------------

func _state_normal(delta: float) -> void:
	var axis := _move_axis()
	if axis != 0.0:
		_set_facing(1 if axis > 0.0 else -1)
	_apply_run(axis, delta)
	_apply_gravity(delta)
	_apply_wall_slide(axis)
	if _jump_buffer_left > 0.0:
		_try_jump()
	if Input.is_action_just_released(&"jump"):
		_cut_jump()
	if Input.is_action_just_pressed(&"dodge") and _dodge_cooldown_left <= 0.0:
		_start_dodge(axis)
	elif Input.is_action_just_pressed(&"slash"):
		_start_slash(0)


func _state_dodge(delta: float) -> void:
	_dodge_elapsed += delta
	velocity = Vector2(_dodge_direction * tuning.dodge_speed(), 0.0)
	if _dodge_elapsed >= tuning.dodge_duration:
		velocity.x *= 0.5
		_set_state(State.NORMAL)
	elif _dodge_elapsed >= tuning.dodge_duration * 0.7 and Input.is_action_just_pressed(&"slash"):
		_start_slash(0) # Late-dodge cancel into attack.


func _state_slash(delta: float) -> void:
	_slash_frame += 1
	var startup := tuning.slash_startup_frames[_slash_index]
	var active := tuning.slash_active_frames[_slash_index]
	var recovery := tuning.slash_recovery_frames[_slash_index]
	var is_active := _slash_frame > startup and _slash_frame <= startup + active
	_hitbox.active = is_active
	_slash_trail.visible = is_active
	if is_active:
		_hitbox.process_hits()
	_apply_gravity(delta)
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, tuning.ground_deceleration * 0.5 * delta)
	if Input.is_action_just_pressed(&"slash"):
		_slash_buffered = true

	if _slash_frame > startup + active:
		# Recovery frames: can be cancelled into the next combo hit, a dodge or a jump.
		if _slash_buffered and _slash_index < tuning.combo_length() - 1:
			_start_slash(_slash_index + 1)
			return
		if Input.is_action_just_pressed(&"dodge") and _dodge_cooldown_left <= 0.0:
			_start_dodge(_move_axis())
			return
		if _jump_buffer_left > 0.0 and (is_on_floor() or _coyote_left > 0.0):
			_set_state(State.NORMAL)
			_try_jump()
			return
	if _slash_frame >= startup + active + recovery:
		_set_state(State.NORMAL)


func _state_hurt(delta: float) -> void:
	_hurt_left -= delta
	_apply_gravity(delta)
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, tuning.ground_deceleration * delta)
	if _hurt_left <= 0.0:
		_set_state(State.NORMAL)


func _state_dead(delta: float) -> void:
	velocity = Vector2.ZERO
	_respawn_left -= delta
	if _respawn_left <= 0.0:
		_respawn()


# --- Movement helpers -----------------------------------------------------------------

func _move_axis() -> float:
	return Input.get_axis(&"move_left", &"move_right")


func _tick_timers(delta: float) -> void:
	_coyote_left = maxf(_coyote_left - delta, 0.0)
	_jump_buffer_left = maxf(_jump_buffer_left - delta, 0.0)
	_dodge_cooldown_left = maxf(_dodge_cooldown_left - delta, 0.0)
	if Input.is_action_just_pressed(&"jump"):
		_jump_buffer_left = tuning.jump_buffer
	if _drop_through_left > 0.0:
		_drop_through_left -= delta
		if _drop_through_left <= 0.0:
			collision_mask |= Layers.ONE_WAY


func _apply_run(axis: float, delta: float) -> void:
	var target := axis * tuning.run_speed
	var accel := tuning.air_acceleration
	if is_on_floor():
		accel = tuning.ground_acceleration if absf(target) > 0.01 else tuning.ground_deceleration
	velocity.x = move_toward(velocity.x, target, accel * delta)


func _apply_gravity(delta: float) -> void:
	var gravity := tuning.gravity_up if velocity.y < 0.0 else tuning.gravity_down
	velocity.y = minf(velocity.y + gravity * delta, tuning.max_fall_speed)


func _apply_wall_slide(axis: float) -> void:
	if is_on_floor() or not is_on_wall() or velocity.y < 0.0 or axis == 0.0:
		return
	if signf(axis) != -signf(get_wall_normal().x):
		return # Only slide while pushing into the wall.
	velocity.y = minf(velocity.y, tuning.wall_slide_speed)
	_air_jumps_left = tuning.air_jumps


func _try_jump() -> void:
	if Input.is_action_pressed(&"move_down") and is_on_floor() and _standing_on_one_way():
		_drop_through()
	elif is_on_floor() or _coyote_left > 0.0:
		_jump(tuning.jump_velocity())
	elif is_on_wall_only():
		var push := signf(get_wall_normal().x)
		velocity.x = push * tuning.wall_jump_push
		_set_facing(int(push))
		_jump(tuning.wall_jump_velocity())
	elif _air_jumps_left > 0:
		_air_jumps_left -= 1
		_jump(tuning.double_jump_velocity())


func _jump(speed: float) -> void:
	velocity.y = -speed
	_coyote_left = 0.0
	_jump_buffer_left = 0.0


func _cut_jump() -> void:
	velocity.y = maxf(velocity.y, -tuning.min_jump_velocity())


func _standing_on_one_way() -> bool:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var body := collision.get_collider() as CollisionObject2D
		if collision.get_normal().y < -0.7 and body and body.collision_layer & Layers.ONE_WAY:
			return true
	return false


func _drop_through() -> void:
	collision_mask &= ~Layers.ONE_WAY
	_drop_through_left = tuning.drop_through_time
	_jump_buffer_left = 0.0


func _start_dodge(axis: float) -> void:
	_dodge_direction = (1 if axis > 0.0 else -1) if axis != 0.0 else facing
	_set_facing(_dodge_direction)
	_dodge_elapsed = 0.0
	_dodge_cooldown_left = tuning.dodge_duration + tuning.dodge_cooldown
	_set_state(State.DODGE)


func _in_dodge_iframes() -> bool:
	return state == State.DODGE \
		and _dodge_elapsed >= tuning.dodge_iframe_start \
		and _dodge_elapsed <= tuning.dodge_iframe_end


func _set_facing(direction: int) -> void:
	if direction == 0:
		return
	facing = direction
	_visual.scale.x = direction


func _set_state(new_state: State) -> void:
	if state == State.SLASH and new_state != State.SLASH:
		_hitbox.active = false
		_slash_trail.visible = false
	state = new_state
	state_changed.emit(state)


# --- Slash ----------------------------------------------------------------------------

func _start_slash(index: int) -> void:
	_slash_index = index
	_slash_frame = 0
	_slash_buffered = false
	_slash_aim = _snapped_aim()
	if _slash_aim.x != 0.0:
		_set_facing(int(signf(_slash_aim.x)))
	_slash_pivot.rotation = _slash_aim.angle()
	_hitbox.reset_hits()
	if is_on_floor():
		velocity.x = _slash_aim.x * tuning.slash_lunge_speed
	_set_state(State.SLASH)


## Aim from the movement input, snapped to 8 directions. No input = facing direction.
## On the ground, downward aims become horizontal.
func _snapped_aim() -> Vector2:
	var raw := Vector2(_move_axis(), Input.get_axis(&"move_up", &"move_down"))
	if raw.length() < 0.3:
		return Vector2(facing, 0.0)
	var aim := Vector2.RIGHT.rotated(snappedf(raw.angle(), PI / 4.0)).round()
	if is_on_floor() and aim.y > 0.0:
		aim.y = 0.0
		if aim.x == 0.0:
			aim.x = facing
	return aim


func _build_slash_damage() -> DamageInfo:
	var info := DamageInfo.new()
	info.amount = tuning.slash_damage[_slash_index]
	info.posture = tuning.slash_posture[_slash_index]
	info.knockback = _slash_aim.normalized() * tuning.slash_knockback[_slash_index]
	info.hit_freeze_frames = tuning.slash_hit_freeze[_slash_index]
	info.source = self
	info.source_peer_id = get_multiplayer_authority()
	return info


func _on_slash_hit(hurtbox: HurtboxComponent, info: DamageInfo) -> void:
	Feel.hit_freeze([self, hurtbox.entity()], info.hit_freeze_frames)
	Feel.shake(0.3 if _slash_index == tuning.combo_length() - 1 else 0.12)


# --- Taking damage --------------------------------------------------------------------

func _on_hurt(info: DamageInfo) -> void:
	if state == State.DEAD:
		return
	match resolve.take_hit(info.resolve_cost):
		ResolveComponent.HitResult.IGNORED:
			return
		ResolveComponent.HitResult.KILLED:
			_die()
			return
	velocity = info.knockback
	_hurt_left = tuning.hurt_stun_time
	_set_state(State.HURT)
	Feel.shake(0.4)
	Events.player_hit.emit(self, info)


func _die() -> void:
	_respawn_left = tuning.respawn_time
	_visual.modulate.a = 0.25
	_set_state(State.DEAD)
	died.emit()
	Events.player_died.emit(self)


func _respawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	reset_physics_interpolation()
	resolve.reset()
	_visual.modulate.a = 1.0
	_set_state(State.NORMAL)
	respawned.emit()
	Events.player_respawned.emit(self)
