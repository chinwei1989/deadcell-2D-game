class_name Player
extends CharacterBody2D
## Player character controller (gray-box Ronin; PLAN.md sections 4 and 5).
##
## Runs only on the peer that owns this player (its multiplayer authority). All numbers
## come from the PlayerTuning resource. Timings are measured in game time (see FrameTime)
## so Focus slow motion slows them down.
##
## States:
##   NORMAL       run, jump, double jump, wall slide/jump, drop-through
##   LEDGE        hanging on a ledge (up/jump = climb, down = let go, away+jump = jump off)
##   DODGE        dash with invincibility frames
##   SLASH        3-hit, 8-direction combo; slashing projectiles deflects them
##   PARRY        short parry window (tap Parry); held → GUARD
##   GUARD        blocks hits from the front for a small Resolve chip
##   DRAW_CHARGE  quick-draw: holding Slash after the first hit sheathes the blade
##   DRAW_STRIKE  releasing the charge dashes through enemies with one strike
##   SLAM         Down + Slash in the air: dive, then a shockwave on landing
##   CUT_LINK     holding Interact next to a staggered Linked frees them (vulnerable meanwhile)
##   HURT, DEAD

signal state_changed(new_state: State)
## Hits landed in the current combo (0 = combo ended).
signal combo_changed(hits: int)
signal died
signal respawned

enum State { NORMAL, LEDGE, DODGE, SLASH, PARRY, GUARD, DRAW_CHARGE, DRAW_STRIKE, SLAM, CUT_LINK, HURT, DEAD }

const HALF_WIDTH := 7.0
const HALF_HEIGHT := 22.0
const CHARGED_COLOR := Color(1.6, 1.3, 1.0)
const HURT_FLASH_TIME := 0.08
## Below this speed (px/s) on the ground the hero sneaks (low half-walk) instead of sprinting.
const SNEAK_SPEED := 120.0
## Length of the front-flip animation after a double jump (seconds).
const FLIP_TIME := 0.36

@export var tuning: PlayerTuning
## Sprite sheet made by tools/blender/models/ronin.py + make_spritesheet.py; animations are
## named after the states (see _animate()). Empty = gray-box polygons.
@export_file("*.png") var sprite_sheet: String = ""
## The katana burns with amber fire (glow, embers, firelight; PLAN.md: the Heat element).
@export var fire_blade: bool = true

var state: State = State.NORMAL
var facing: int = 1
var spawn_position: Vector2

var _state_time: float = 0.0
var _coyote_left: float = 0.0
var _jump_buffer_left: float = 0.0
var _air_jumps_left: int = 0
var _drop_through_left: float = 0.0
var _dodge_cooldown_left: float = 0.0
var _dodge_direction: int = 1
var _ledge_regrab_left: float = 0.0
var _ledge_point: Vector2 = Vector2.ZERO
var _hurt_left: float = 0.0
var _respawn_left: float = 0.0
var _slash_index: int = 0
var _slash_buffered: bool = false
var _slash_held_time: float = 0.0
var _slash_aim: Vector2 = Vector2.RIGHT
var _draw_charge: float = 0.0
var _draw_crit: bool = false
var _slam_landed: bool = false
var _cut_target: LinkedCitizen
var _wall_sliding: bool = false
var _slash_stepped: bool = false
var _step_left: float = 0.0
var _step_velocity_x: float = 0.0
var _air_pops_left: int = 0
var combo_hits: int = 0
var _combo_left: float = 0.0
var _hurt_flash_left: float = 0.0
var _flip_left: float = 0.0
var _sprite: AnimatedSprite2D
var _trail: SwordTrail
var _fire: FireBlade

@onready var resolve: ResolveComponent = $Resolve
@onready var focus: FocusComponent = $Focus
@onready var _visual: Node2D = $Visual
@onready var _slash_pivot: Node2D = $SlashPivot
@onready var _slash_trail: Line2D = $SlashPivot/SlashTrail
@onready var _hitbox: HitboxComponent = $SlashPivot/Hitbox
@onready var _hurtbox: HurtboxComponent = $Hurtbox


func _ready() -> void:
	assert(tuning != null, "Player needs a PlayerTuning resource")
	add_to_group(&"players")
	spawn_position = global_position
	resolve.max_pips = tuning.max_resolve
	resolve.invulnerability_time = tuning.hurt_invulnerability
	resolve.reset()
	focus.max_seconds = tuning.focus_max_seconds
	focus.reset()
	focus.activated.connect(func() -> void: Feel.set_slow_motion(true, tuning.focus_time_scale))
	focus.deactivated.connect(func() -> void: Feel.set_slow_motion(false))
	_hitbox.build_damage = _build_blade_damage
	_hitbox.hit_landed.connect(_on_blade_hit)
	_hurtbox.received.connect(_on_hurt)
	_shape_slash_trail()
	_slash_trail.visible = false
	if sprite_sheet != "":
		_make_sprite()


func _exit_tree() -> void:
	focus.deactivate() # Never leave the game stuck in slow motion.


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	_state_time += delta
	_tick_timers(delta)
	_update_focus(delta)
	match state:
		State.NORMAL:
			_state_normal(delta)
		State.LEDGE:
			_state_ledge()
		State.DODGE:
			_state_dodge()
		State.SLASH:
			_state_slash(delta)
		State.PARRY:
			_state_parry(delta)
		State.GUARD:
			_state_guard(delta)
		State.DRAW_CHARGE:
			_state_draw_charge(delta)
		State.DRAW_STRIKE:
			_state_draw_strike(delta)
		State.SLAM:
			_state_slam(delta)
		State.CUT_LINK:
			_state_cut_link(delta)
		State.HURT:
			_state_hurt(delta)
		State.DEAD:
			_state_dead(delta)
	var falling_speed := velocity.y
	var was_on_floor := is_on_floor()
	move_and_slide()
	if is_on_floor() and not was_on_floor and falling_speed > 260.0:
		Feel.dust(global_position + Vector2(0.0, HALF_HEIGHT), 10, 2.0)
		Audio.play(&"land", -8.0)
	if is_on_floor():
		_coyote_left = tuning.coyote_time
		_air_jumps_left = tuning.air_jumps
		_air_pops_left = tuning.air_slash_pops
	_hurtbox.invulnerable = _is_invulnerable()
	_update_visual(delta)


# --- Visuals --------------------------------------------------------------------------

## The slash smear: a crescent in front of the hero (rotated with the aim) that is thick in
## the middle, tapered at both ends, and fades from hot red-orange to a white edge.
func _shape_slash_trail() -> void:
	var points := PackedVector2Array()
	for i in 11:
		var angle := deg_to_rad(lerpf(-75.0, 75.0, i / 10.0))
		points.append(Vector2(6.0, 0.0) + Vector2(cos(angle), sin(angle)) * 30.0)
	_slash_trail.points = points
	_slash_trail.width = 7.0
	var taper := Curve.new()
	taper.add_point(Vector2(0.0, 0.1))
	taper.add_point(Vector2(0.55, 1.0))
	taper.add_point(Vector2(1.0, 0.15))
	_slash_trail.width_curve = taper
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 0.353, 0.212, 0.0))
	fade.set_color(1, Color(1.0, 0.95, 0.85, 0.95))
	fade.add_point(0.6, Color(1.0, 0.353, 0.212, 0.85))
	_slash_trail.gradient = fade
	_slash_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_slash_trail.end_cap_mode = Line2D.LINE_CAP_ROUND


func _make_sprite() -> void:
	for child in _visual.get_children():
		child.queue_free() # Gray-box polygons.
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteSheet.frames(sprite_sheet)
	_sprite.centered = false
	_sprite.offset = -SpriteSheet.origin(sprite_sheet)
	_sprite.material = SpriteSheet.material(sprite_sheet)
	_visual.add_child(_sprite)
	_sprite.play(&"idle")
	_trail = SwordTrail.new()
	add_child(_trail)
	_add_key_light()
	if fire_blade:
		_fire = FireBlade.new()
		add_child(_fire)


## A soft light that follows the hero so they stay readable in dark areas (and catches
## the edges of the normal-mapped sprite).
func _add_key_light() -> void:
	var light := PointLight2D.new()
	light.texture = LevelLight.radial_texture()
	light.texture_scale = 1.5
	light.color = Color(0.85, 0.9, 1.0)
	light.energy = 0.7
	light.height = 40.0
	light.position = Vector2(-10.0, -20.0)
	add_child(light)


func _update_visual(delta: float) -> void:
	var color := CHARGED_COLOR if state == State.DRAW_CHARGE and _draw_charge >= 1.0 else Color.WHITE
	if state == State.DEAD:
		color.a = 0.25 if _sprite == null else 1.0
	elif resolve.is_invulnerable():
		color.a = 0.45 if int(_state_time * 20.0) % 2 == 0 else 1.0 # Blink while invulnerable.
	_visual.modulate = color
	_hurt_flash_left = maxf(_hurt_flash_left - delta, 0.0)
	if _sprite:
		(_sprite.material as ShaderMaterial).set_shader_parameter(&"amount", 1.0 if _hurt_flash_left > 0.0 else 0.0)
		_animate()
		_feed_trail()
		_afterimages()


## Picks the sprite animation for the current state. Attacks and other timed states set
## the frame from the state's progress, so the art always matches the frame data (and
## slows down with Focus).
func _animate() -> void:
	var anim := &"idle"
	var progress := -1.0
	var speed_scale := 1.0
	match state:
		State.NORMAL:
			var speed := absf(velocity.x)
			if is_on_floor():
				_flip_left = 0.0
				if speed > SNEAK_SPEED:
					anim = &"run"
					speed_scale = clampf(speed / tuning.run_speed, 0.6, 1.4) # Feet keep pace.
				elif speed > 15.0:
					anim = &"sneak"
				else:
					anim = &"idle"
			elif _flip_left > 0.0:
				anim = &"flip"
				progress = 1.0 - _flip_left / FLIP_TIME
			elif _wall_sliding:
				anim = &"wall_slide"
			else:
				anim = &"jump" if velocity.y < 0.0 else &"fall"
		State.LEDGE:
			anim = &"hang"
		State.DODGE:
			anim = &"dodge"
			progress = _state_time / tuning.dodge_duration
		State.SLASH:
			anim = _slash_animation()
		State.PARRY:
			anim = &"parry"
			progress = _state_time / FrameTime.seconds(tuning.parry_window_frames)
		State.GUARD:
			anim = &"guard"
		State.DRAW_CHARGE:
			anim = &"draw_charge"
		State.DRAW_STRIKE:
			anim = &"draw_strike"
			progress = _state_time / FrameTime.seconds(tuning.draw_dash_frames + tuning.draw_recovery_frames)
		State.SLAM:
			anim = &"slam_land" if _slam_landed else &"slam"
			if _slam_landed:
				progress = _state_time / FrameTime.seconds(tuning.slam_recovery_frames)
		State.CUT_LINK:
			anim = &"cut_link"
		State.HURT:
			anim = &"hurt"
			progress = 1.0 - _hurt_left / tuning.hurt_stun_time
		State.DEAD:
			anim = &"dead"
			progress = (tuning.respawn_time - _respawn_left) / (tuning.respawn_time * 0.6)
	_sprite.speed_scale = speed_scale
	if _sprite.animation != anim:
		_sprite.play(anim)
	if state == State.SLASH:
		_sprite.pause()
		_sprite.frame = _slash_frame(_sprite.sprite_frames.get_frame_count(anim))
	elif progress >= 0.0:
		var count := _sprite.sprite_frames.get_frame_count(anim)
		_sprite.pause()
		_sprite.frame = clampi(int(progress * count), 0, count - 1)
	elif not _sprite.is_playing():
		_sprite.play(anim)


## Slash art is drawn as wind-up poses, strike poses (blade sweeping through), then
## follow-through poses. Map each to its frame-data phase so the strike pose shows exactly
## during the active frames, whatever the attack's timing.
func _slash_frame(count: int) -> int:
	var durations: Array[float] = [
		FrameTime.seconds(tuning.slash_startup_frames[_slash_index]),
		FrameTime.seconds(tuning.slash_active_frames[_slash_index]),
		FrameTime.seconds(tuning.slash_recovery_frames[_slash_index]),
	]
	var counts := SpriteSheet.phases(sprite_sheet, _sprite.animation)
	if counts.size() != 3:
		# Art without phases: 1-2 wind-up frames, 1-2 strike frames, the rest recovery.
		var windup := 1 if count <= 4 else 2
		var strike := 2 if count >= 6 else 1
		counts = PackedInt32Array([windup, strike, count - windup - strike])
	return phase_frame(_state_time, durations, counts)


## Which frame to show `time` seconds into an attack whose parts last `durations` seconds
## and are drawn with `counts` frames each: frames within a part are spread evenly over it.
static func phase_frame(time: float, durations: Array[float], counts: PackedInt32Array) -> int:
	var first := 0
	for i in counts.size():
		var last_part := i == counts.size() - 1
		if time <= durations[i] or last_part:
			var t := clampf(time / durations[i], 0.0, 0.999) if durations[i] > 0.0 else 0.999
			return first + mini(int(t * counts[i]), counts[i] - 1)
		time -= durations[i]
		first += counts[i]
	return maxi(first - 1, 0)


## Sends the blade's current base and tip (world space) to the sword trail while an attack
## is swinging; ends the stroke otherwise.
func _feed_trail() -> void:
	var heat := clampf(float(combo_hits) / tuning.combo_full_heat, 0.0, 1.0)
	_trail.heat = heat
	var swinging := false
	match state:
		State.SLASH:
			swinging = _past(FrameTime.seconds(tuning.slash_startup_frames[_slash_index]) * 0.5) \
				and not _past(FrameTime.seconds(tuning.slash_startup_frames[_slash_index]
					+ tuning.slash_active_frames[_slash_index] + tuning.slash_recovery_frames[_slash_index] / 2))
		State.DRAW_STRIKE:
			swinging = not _past(FrameTime.seconds(tuning.draw_dash_frames + tuning.draw_recovery_frames / 2))
		State.SLAM:
			swinging = true
	var bases := SpriteSheet.track(sprite_sheet, _sprite.animation, &"blade_base")
	var tips := SpriteSheet.track(sprite_sheet, _sprite.animation, &"blade_tip")
	if tips.is_empty() or state == State.DEAD:
		_trail.stop()
		if _fire:
			_fire.hide_blade()
		return
	var origin := SpriteSheet.origin(sprite_sheet)
	var frame := clampi(_sprite.frame, 0, tips.size() - 1)
	var flip := Vector2(facing, 1.0)
	var base := global_position + (bases[frame] - origin) * flip
	var tip := global_position + (tips[frame] - origin) * flip
	if _fire:
		_fire.intensity = maxf(heat, 0.6 if swinging else 0.0)
		_fire.set_blade(base, tip)
	if swinging:
		_trail.add_blade(base, tip)
	else:
		_trail.stop()


## Ghost copies of the hero behind fast moves: dodges, quick-draw dashes, slam dives and
## the forward bursts of combo hits.
func _afterimages() -> void:
	var fast := false
	var color := Feel.HOT
	match state:
		State.DODGE:
			fast = true
			color = Color("4fd1c5") # Cold teal: invincible dodge.
		State.DRAW_STRIKE:
			fast = not _past(FrameTime.seconds(tuning.draw_dash_frames))
			color = Feel.WHITE_HOT
		State.SLAM:
			fast = not _slam_landed
		State.SLASH:
			fast = _step_left > 0.0 and absf(_step_velocity_x) > 200.0
	if not fast or Engine.get_physics_frames() % 2 != 0:
		return
	var texture := _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame)
	Feel.afterimage(texture, global_position, _sprite.offset, facing < 0, color)


func _slash_animation() -> StringName:
	if _slash_aim.y < 0.0:
		return &"slash_up"
	if _slash_aim.y > 0.0:
		return &"slash_down"
	return [&"slash1", &"slash2", &"slash3"][mini(_slash_index, 2)]


# --- States ---------------------------------------------------------------------------

func _state_normal(delta: float) -> void:
	_wall_sliding = false
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
	if not is_on_floor() and velocity.y >= 0.0 and _ledge_regrab_left <= 0.0:
		var ledge: Variant = _find_ledge()
		if ledge != null:
			_grab_ledge(ledge)
			return
	if Input.is_action_pressed(&"interact") and is_on_floor():
		_cut_target = _linked_in_reach()
		if _cut_target:
			Audio.play(&"cut_link", -4.0, 0.0)
			_set_state(State.CUT_LINK)
			return
	if Input.is_action_just_pressed(&"dodge") and _dodge_cooldown_left <= 0.0:
		_start_dodge(axis)
	elif Input.is_action_just_pressed(&"parry"):
		_set_state(State.PARRY)
	elif Input.is_action_just_pressed(&"slash"):
		if not is_on_floor() and Input.is_action_pressed(&"move_down"):
			_start_slam()
		else:
			_start_slash(0)


func _state_ledge() -> void:
	velocity = Vector2.ZERO
	var axis := _move_axis()
	if Input.is_action_pressed(&"move_down"):
		_release_ledge()
	elif _jump_buffer_left > 0.0:
		if axis != 0.0 and signf(axis) != facing:
			_release_ledge()
			velocity.x = -facing * tuning.wall_jump_push
			_set_facing(-facing)
			_jump(tuning.wall_jump_velocity())
		else:
			_climb_ledge()
	elif Input.is_action_pressed(&"move_up") or (signf(axis) == facing and _state_time > 0.15):
		_climb_ledge()


func _state_dodge() -> void:
	velocity = Vector2(_dodge_direction * tuning.dodge_speed(), 0.0)
	if _state_time >= tuning.dodge_duration:
		velocity.x *= 0.5
		_set_state(State.NORMAL)
	elif _state_time >= tuning.dodge_duration * 0.7 and Input.is_action_just_pressed(&"slash"):
		_start_slash(0) # Late-dodge cancel into attack.


func _state_slash(delta: float) -> void:
	var startup := FrameTime.seconds(tuning.slash_startup_frames[_slash_index])
	var active := FrameTime.seconds(tuning.slash_active_frames[_slash_index])
	var recovery := FrameTime.seconds(tuning.slash_recovery_frames[_slash_index])
	var is_active := _past(startup) and not _past(startup + active)
	if is_active and not _slash_stepped:
		_slash_stepped = true
		_start_slash_step()
	_hitbox.active = is_active
	_slash_trail.visible = is_active and _sprite == null
	if is_active:
		_hitbox.process_hits()
		_deflect_projectiles(_state_time - startup)
	_apply_gravity(delta * (1.0 if is_on_floor() else tuning.air_slash_gravity_scale))
	if _step_left > 0.0:
		_step_left -= delta
		velocity.x = _step_velocity_x
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, tuning.ground_deceleration * 0.5 * delta)
	_slash_held_time = _slash_held_time + delta if Input.is_action_pressed(&"slash") else 0.0
	if Input.is_action_just_pressed(&"slash"):
		_slash_buffered = true

	if _past(startup + active):
		# Recovery: can turn into a quick-draw charge, the next combo hit, a dodge or a jump.
		if _slash_index == 0 and _slash_held_time >= FrameTime.seconds(tuning.draw_hold_frames):
			Audio.play(&"draw_charge", -6.0, 0.0)
			_set_state(State.DRAW_CHARGE)
			return
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
	if _past(startup + active + recovery):
		_set_state(State.NORMAL)


func _state_parry(delta: float) -> void:
	_apply_gravity(delta)
	_apply_friction(delta)
	var window := FrameTime.seconds(tuning.parry_window_frames)
	if not _past(window):
		return
	if Input.is_action_pressed(&"parry"):
		_set_state(State.GUARD)
	elif _past(window + FrameTime.seconds(tuning.parry_whiff_recovery_frames)):
		_set_state(State.NORMAL)


func _state_guard(delta: float) -> void:
	_apply_gravity(delta)
	_apply_friction(delta)
	var axis := _move_axis()
	if axis != 0.0:
		_set_facing(1 if axis > 0.0 else -1) # Turn to block, but don't move.
	if not Input.is_action_pressed(&"parry"):
		_set_state(State.NORMAL)
	elif Input.is_action_just_pressed(&"dodge") and _dodge_cooldown_left <= 0.0:
		_start_dodge(axis)


func _state_draw_charge(delta: float) -> void:
	var axis := _move_axis()
	if axis != 0.0:
		_set_facing(1 if axis > 0.0 else -1)
	_apply_run(axis * tuning.draw_charge_move_factor, delta)
	_apply_gravity(delta)
	_draw_charge = clampf(_state_time / FrameTime.seconds(tuning.draw_charge_frames), 0.0, 1.0)
	if not Input.is_action_pressed(&"slash"):
		_start_draw_strike()
	elif Input.is_action_just_pressed(&"dodge") and _dodge_cooldown_left <= 0.0:
		_start_dodge(axis)


func _state_draw_strike(delta: float) -> void:
	var dash := FrameTime.seconds(tuning.draw_dash_frames)
	if not _past(dash):
		velocity = Vector2(facing * tuning.draw_distance / dash, 0.0)
		_hitbox.active = true
		_slash_trail.visible = true
		_hitbox.process_hits()
		_deflect_projectiles(0.0)
		return
	_hitbox.active = false
	_slash_trail.visible = false
	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0.0, tuning.ground_deceleration * 2.0 * delta)
	if _past(dash + FrameTime.seconds(tuning.draw_recovery_frames)):
		_set_state(State.NORMAL)


func _state_slam(delta: float) -> void:
	if not _slam_landed:
		velocity = Vector2(0.0, tuning.slam_speed)
		_hitbox.active = true
		_slash_trail.visible = true
		_hitbox.process_hits()
		if is_on_floor():
			_land_slam()
		return
	_apply_friction(delta)
	_apply_gravity(delta)
	if _past(FrameTime.seconds(tuning.slam_recovery_frames)):
		_set_state(State.NORMAL)


func _state_cut_link(delta: float) -> void:
	_apply_gravity(delta)
	_apply_friction(delta)
	if not is_instance_valid(_cut_target) or not _cut_target.can_cut_link() or not Input.is_action_pressed(&"interact"):
		if is_instance_valid(_cut_target):
			_cut_target.set_cut_progress(0.0)
		_set_state(State.NORMAL)
		return
	_set_facing(1 if _cut_target.global_position.x >= global_position.x else -1)
	var progress := clampf(_state_time / tuning.cut_link_time, 0.0, 1.0)
	_cut_target.set_cut_progress(progress)
	if progress >= 1.0:
		_cut_target.free_link(self)
		Audio.play(&"freed", -2.0, 0.0)
		resolve.restore(tuning.execution_resolve) # Mercy is rewarded like an execution.
		_set_state(State.NORMAL)


## Nearest staggered Linked within cut_link_range, or null.
func _linked_in_reach() -> LinkedCitizen:
	var best: LinkedCitizen = null
	var best_distance := tuning.cut_link_range
	for node in get_tree().get_nodes_in_group(&"linked"):
		var linked := node as LinkedCitizen
		var distance := global_position.distance_to(linked.global_position + Vector2(0.0, -HALF_HEIGHT))
		if linked.can_cut_link() and distance <= best_distance:
			best = linked
			best_distance = distance
	return best


func _state_hurt(delta: float) -> void:
	_hurt_left -= delta
	_apply_gravity(delta)
	if is_on_floor():
		_apply_friction(delta)
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


## True once the current state has lasted longer than `seconds` (game time).
func _past(seconds: float) -> bool:
	return _state_time > seconds + FrameTime.EPSILON


func _tick_timers(delta: float) -> void:
	_coyote_left = maxf(_coyote_left - delta, 0.0)
	_jump_buffer_left = maxf(_jump_buffer_left - delta, 0.0)
	_dodge_cooldown_left = maxf(_dodge_cooldown_left - delta, 0.0)
	_ledge_regrab_left = maxf(_ledge_regrab_left - delta, 0.0)
	_flip_left = maxf(_flip_left - delta, 0.0)
	if combo_hits > 0:
		_combo_left -= delta
		if _combo_left <= 0.0:
			_set_combo(0)
	if Input.is_action_just_pressed(&"jump"):
		_jump_buffer_left = tuning.jump_buffer
	if _drop_through_left > 0.0:
		_drop_through_left -= delta
		if _drop_through_left <= 0.0:
			collision_mask |= Layers.ONE_WAY


func _update_focus(delta: float) -> void:
	# Engine.time_scale slows everyone, so Focus is solo-only for now (AGENTS.md).
	if Input.is_action_just_pressed(&"focus") and not Net.is_online() and state != State.DEAD:
		focus.toggle()
	focus.tick(delta / Engine.time_scale)


func _apply_run(axis: float, delta: float) -> void:
	var target := axis * tuning.run_speed
	var accel := tuning.air_acceleration
	if is_on_floor():
		accel = tuning.ground_acceleration if absf(target) > 0.01 else tuning.ground_deceleration
	velocity.x = move_toward(velocity.x, target, accel * delta)


func _apply_friction(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, tuning.ground_deceleration * delta)


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
	_wall_sliding = true


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
		_flip_left = FLIP_TIME


func _jump(speed: float) -> void:
	Audio.play(&"jump", -10.0, 0.1)
	if is_on_floor() or _coyote_left > 0.0:
		Feel.dust(global_position + Vector2(0.0, HALF_HEIGHT), 6)
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
	_dodge_cooldown_left = tuning.dodge_duration + tuning.dodge_cooldown
	if is_on_floor():
		Feel.dust(global_position + Vector2(-_dodge_direction * 6.0, HALF_HEIGHT), 8, 1.5)
	Audio.play(&"dodge", -6.0)
	_set_state(State.DODGE)


func _is_invulnerable() -> bool:
	match state:
		State.DEAD:
			return true
		State.DODGE:
			if _state_time >= tuning.dodge_iframe_start and _state_time <= tuning.dodge_iframe_end:
				return true
		State.DRAW_STRIKE:
			if not _past(FrameTime.seconds(tuning.draw_dash_frames)):
				return true # The quick-draw dash passes through attacks.
	return resolve.is_invulnerable()


func _set_facing(direction: int) -> void:
	if direction == 0:
		return
	facing = direction
	_visual.scale.x = direction


func _set_state(new_state: State) -> void:
	_hitbox.active = false
	_slash_trail.visible = false
	state = new_state
	_state_time = 0.0
	state_changed.emit(state)


# --- Ledge ----------------------------------------------------------------------------

## Returns the ledge corner (wall x, ledge top y) in front of the player, or null.
func _find_ledge() -> Variant:
	var space := get_world_2d().direct_space_state
	var top := global_position.y - HALF_HEIGHT
	var reach := Vector2(facing * (HALF_WIDTH + tuning.ledge_reach_x), 0.0)
	var hand := Vector2(global_position.x, top + 2.0)
	var wall := _ray(space, hand, hand + reach)
	if wall.is_empty():
		return null
	var above := Vector2(global_position.x, top - tuning.ledge_reach_y)
	if not _ray(space, above, above + reach).is_empty():
		return null # The wall continues above: no ledge.
	var probe_x: float = wall.position.x + facing * 2.0
	var floor_hit := _ray(space, Vector2(probe_x, above.y), Vector2(probe_x, top + 4.0))
	if floor_hit.is_empty() or floor_hit.normal.y > -0.7:
		return null
	return Vector2(wall.position.x, floor_hit.position.y)


func _ray(space: PhysicsDirectSpaceState2D, from: Vector2, to: Vector2) -> Dictionary:
	return space.intersect_ray(PhysicsRayQueryParameters2D.create(from, to, Layers.WORLD, [get_rid()]))


func _grab_ledge(point: Vector2) -> void:
	_ledge_point = point
	global_position = Vector2(point.x - facing * (HALF_WIDTH + 0.5), point.y + HALF_HEIGHT - 6.0)
	velocity = Vector2.ZERO
	_air_jumps_left = tuning.air_jumps
	_set_state(State.LEDGE)


func _release_ledge() -> void:
	_ledge_regrab_left = tuning.ledge_regrab_delay
	_set_state(State.NORMAL)


func _climb_ledge() -> void:
	var target := Vector2(_ledge_point.x + facing * (HALF_WIDTH + 2.0), _ledge_point.y - HALF_HEIGHT - 0.5)
	if test_move(Transform2D(0.0, target), Vector2(0.0, -1.0)):
		_release_ledge() # No room to stand up there.
		return
	global_position = target
	reset_physics_interpolation()
	_jump_buffer_left = 0.0
	_set_state(State.NORMAL)


# --- Blade: slash, quick-draw, deflect ------------------------------------------------

func _start_slash(index: int) -> void:
	_slash_index = index
	_slash_buffered = false
	if index == 0:
		_slash_held_time = 0.0
	_slash_aim = _snapped_aim()
	if _slash_aim.x != 0.0:
		_set_facing(int(signf(_slash_aim.x)))
	_slash_pivot.rotation = _slash_aim.angle()
	_hitbox.reset_hits()
	_slash_stepped = false
	_step_left = 0.0
	if is_on_floor():
		velocity.x = _slash_aim.x * tuning.slash_lunge_speed
	elif _air_pops_left > 0:
		_air_pops_left -= 1
		velocity.y = minf(velocity.y, -tuning.air_slash_pop) # Hang in the air to chain hits.
	if is_on_floor() and _slash_aim.y == 0.0:
		Audio.play([&"slash_1", &"slash_2", &"slash_3"][mini(index, 2)], -2.0)
	else:
		Audio.play(&"slash_air", -2.0)
	_set_state(State.SLASH)


## Choreography: each hit bursts forward when its active frames start (the finisher
## leaps), pulled toward an enemy in front so combos flow from target to target.
func _start_slash_step() -> void:
	var duration := FrameTime.seconds(tuning.slash_step_frames[_slash_index])
	var speed := tuning.slash_step_speed[_slash_index]
	var direction := signf(_slash_aim.x)
	var target := _magnet_target(direction)
	if target:
		var gap := absf(target.global_position.x - global_position.x) - tuning.slash_magnet_stop
		speed = clampf(gap / duration, 0.0, tuning.slash_magnet_max_speed)
	if direction != 0.0:
		_step_velocity_x = direction * speed
		_step_left = duration
	if tuning.slash_hop[_slash_index] > 0.0 and _slash_aim.y == 0.0:
		velocity.y = -tuning.slash_hop[_slash_index]


## Nearest enemy (or practice target) in front within slash_magnet_range, at about
## the same height.
func _magnet_target(direction: float) -> Node2D:
	if direction == 0.0:
		return null
	var best: Node2D = null
	var best_distance := tuning.slash_magnet_range
	for node in get_tree().get_nodes_in_group(&"targets"):
		var target := node as Node2D
		var offset := target.global_position - global_position
		if signf(offset.x) != direction or absf(offset.y) > 48.0:
			continue
		if absf(offset.x) < best_distance:
			best = target
			best_distance = absf(offset.x)
	return best


func _set_combo(hits: int) -> void:
	combo_hits = hits
	_combo_left = tuning.combo_timeout
	combo_changed.emit(combo_hits)


func _start_draw_strike() -> void:
	_draw_crit = _draw_charge >= 1.0
	_slash_aim = Vector2(facing, 0.0)
	_slash_pivot.rotation = _slash_aim.angle()
	_hitbox.reset_hits()
	Audio.play(&"draw_strike", 0.0 if _draw_crit else -3.0)
	_set_state(State.DRAW_STRIKE)


func _start_slam() -> void:
	_slam_landed = false
	_slash_aim = Vector2.DOWN
	_slash_pivot.rotation = _slash_aim.angle()
	_hitbox.reset_hits()
	Audio.play(&"slam_dive", -4.0)
	_set_state(State.SLAM)


## Landing shockwave: hits every enemy hurtbox within slam_landing_radius of the feet.
func _land_slam() -> void:
	_slam_landed = true
	_hitbox.active = false
	_slash_trail.visible = false
	_state_time = 0.0 # Recovery is timed from the landing.
	velocity = Vector2.ZERO
	Feel.shake(0.35)
	Feel.dust(global_position + Vector2(0.0, HALF_HEIGHT), 16, 3.0)
	Audio.play(&"slam_land", 0.0)
	Feel.ring(global_position + Vector2(0.0, HALF_HEIGHT - 2.0), tuning.slam_landing_radius)
	var circle := CircleShape2D.new()
	circle.radius = tuning.slam_landing_radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, global_position + Vector2(0.0, HALF_HEIGHT - 4.0))
	query.collision_mask = Layers.ENEMY_HURTBOX
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 16):
		var hurtbox := hit["collider"] as HurtboxComponent
		if hurtbox == null:
			continue
		var info := _build_blade_damage()
		info.amount = tuning.slam_landing_damage
		info.posture = tuning.slam_landing_posture
		var side := signf(hurtbox.global_position.x - global_position.x)
		info.knockback = Vector2((side if side != 0.0 else facing) * 160.0, -120.0)
		if hurtbox.receive(info):
			_on_blade_hit(hurtbox, info)


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


func _build_blade_damage() -> DamageInfo:
	var info := DamageInfo.new()
	info.can_execute = true
	info.source = self
	info.source_peer_id = get_multiplayer_authority()
	if state == State.SLAM:
		info.amount = tuning.slam_damage
		info.posture = tuning.slam_posture
		info.knockback = Vector2(0.0, 120.0)
		info.hit_freeze_frames = tuning.slam_hit_freeze
	elif state == State.DRAW_STRIKE:
		var multiplier := tuning.draw_crit_multiplier if _draw_crit else 1.0
		info.amount = tuning.draw_damage * multiplier
		info.posture = tuning.draw_posture * multiplier
		info.is_crit = _draw_crit
		info.knockback = Vector2(facing * 120.0, -60.0)
		info.hit_freeze_frames = tuning.draw_hit_freeze
	else:
		info.amount = tuning.slash_damage[_slash_index]
		info.posture = tuning.slash_posture[_slash_index]
		info.knockback = _slash_aim.normalized() * tuning.slash_knockback[_slash_index]
		info.hit_freeze_frames = tuning.slash_hit_freeze[_slash_index]
	return info


func _on_blade_hit(hurtbox: HurtboxComponent, info: DamageInfo) -> void:
	var target := hurtbox.entity()
	_set_combo(combo_hits + 1)
	var heavy := info.is_crit or state in [State.DRAW_STRIKE, State.SLAM] or _slash_index == tuning.combo_length() - 1
	var hit_point := hurtbox.global_position.lerp(global_position, 0.25)
	var direction := info.knockback if info.knockback != Vector2.ZERO else Vector2(facing, 0.0)
	var heat := clampf(float(combo_hits) / tuning.combo_full_heat, 0.0, 1.0)
	var color := (FireBlade.OUTER if fire_blade else Feel.HOT).lerp(Feel.AMBER, heat)
	if info.executed:
		Audio.play(&"execute", 2.0, 0.03)
	else:
		Audio.play(&"hit_heavy" if heavy else &"hit_light", 0.0 if heavy else -2.0)
	if fire_blade:
		Audio.play(&"ember_burst", -14.0, 0.15)
	if info.executed:
		resolve.restore(tuning.execution_resolve)
		Feel.hit_freeze([self, target], tuning.execution_hit_freeze)
		Feel.shake(0.5)
		Feel.impact(hit_point, direction, 1.0, Feel.WHITE_HOT)
		Feel.flash(0.12)
	else:
		Feel.hit_freeze([self, target], info.hit_freeze_frames)
		Feel.shake(0.3 if heavy else 0.12)
		Feel.impact(hit_point, direction, 0.7 if heavy else 0.3, color)
	if fire_blade:
		Feel.embers(hit_point, 10 if heavy or info.executed else 5)
		Feel.fire_burst(hit_point, 0.5 if info.executed else (0.6 if heavy else 0.25))
	Feel.damage_number(hurtbox.global_position + Vector2(0.0, -24.0), info.amount, info.is_crit or info.executed)
	if info.killed:
		focus.refill(tuning.focus_refill_kill)


## Slashing a projectile sends it back. Within the first perfect_deflect_frames of the
## active window it goes straight back at the shooter as a crit.
func _deflect_projectiles(active_time: float) -> void:
	var perfect := active_time <= FrameTime.seconds(tuning.perfect_deflect_frames) + FrameTime.EPSILON
	for area in _hitbox.get_overlapping_areas():
		var projectile := area as Projectile
		if projectile == null or not projectile.can_deflect():
			continue
		var direction := _slash_aim.normalized()
		if perfect and is_instance_valid(projectile.shooter):
			direction = projectile.global_position.direction_to(projectile.shooter.global_position)
		var damage := tuning.perfect_deflect_damage if perfect else tuning.deflect_damage
		projectile.deflect(self, direction, perfect, damage, tuning.deflect_posture, tuning.deflect_speed_multiplier)
		Audio.play(&"deflect", 0.0 if perfect else -4.0, 0.08, 1.15 if perfect else 1.0)
		focus.refill(tuning.focus_refill_perfect_deflect if perfect else tuning.focus_refill_deflect)
		Feel.hit_freeze([self], 5 if perfect else 3)
		Feel.shake(0.2 if perfect else 0.1)
		Events.projectile_deflected.emit(projectile, perfect)


# --- Taking damage, parry, guard ------------------------------------------------------

func _on_hurt(info: DamageInfo) -> void:
	if state == State.DEAD:
		return
	if _is_from_front(info):
		if state == State.PARRY and not _past(FrameTime.seconds(tuning.parry_window_frames)):
			_parry(info)
			return
		if state == State.GUARD:
			_guard(info)
			return
	match resolve.take_hit(info.resolve_cost):
		ResolveComponent.HitResult.IGNORED:
			return
		ResolveComponent.HitResult.KILLED:
			_die()
			return
	velocity = info.knockback
	Audio.play(&"hurt", -2.0)
	_set_combo(0)
	_hurt_left = tuning.hurt_stun_time
	_hurt_flash_left = HURT_FLASH_TIME
	_set_state(State.HURT)
	Feel.shake(0.4)
	Events.player_hit.emit(self, info)


func _is_from_front(info: DamageInfo) -> bool:
	var source := info.source as Node2D
	if source == null:
		return false
	var side := signf(source.global_position.x - global_position.x)
	return side == 0.0 or int(side) == facing


func _parry(info: DamageInfo) -> void:
	var attacker := info.source
	if attacker.has_method(&"on_parried"):
		attacker.call(&"on_parried", self)
	resolve.restore(tuning.perfect_parry_resolve)
	focus.refill(tuning.focus_refill_parry)
	Feel.hit_freeze([self, attacker], tuning.parry_hit_freeze)
	Feel.shake(0.25)
	Audio.play(&"parry", 0.0, 0.04)
	Events.parry_succeeded.emit(self, attacker)
	_set_state(State.NORMAL) # Free to counter-slash immediately.


func _guard(info: DamageInfo) -> void:
	var attacker := info.source
	if attacker.has_method(&"on_blocked"):
		attacker.call(&"on_blocked", self)
	if resolve.pips > 0.0:
		resolve.take_hit(info.resolve_cost * tuning.guard_chip) # Chip damage never kills.
	velocity.x = -facing * tuning.guard_pushback
	Feel.shake(0.1)
	Audio.play(&"guard", -4.0)
	Events.guard_blocked.emit(self)


func _die() -> void:
	_respawn_left = tuning.respawn_time
	focus.deactivate()
	Audio.play(&"death", 0.0, 0.0)
	_set_state(State.DEAD)
	died.emit()
	Events.player_died.emit(self)


func _respawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	reset_physics_interpolation()
	resolve.reset()
	focus.reset()
	_set_state(State.NORMAL)
	respawned.emit()
	Events.player_respawned.emit(self)
