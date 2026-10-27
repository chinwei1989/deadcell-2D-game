class_name Warden
extends EnemyBase
## The Warden: HALCYON's riot enforcer, the demo's boss (PLAN.md section 10). Numbers live
## in WardenData. It waits until a player comes close, roars (the HUD shows its health bar),
## then cycles attacks chosen by distance:
##   sweep   baton sweep in front: parry it (posture damage, stun) or dodge back
##   charge  shield charge across the arena (red wind-up = unblockable): dodge through or
##           jump; slamming into a wall leaves it helpless for a moment
##   slam    leaps at the player and lands with shockwaves running both ways: jump them
##   volley  (phase 2) a fan of bolts: deflect them back
## Below phase2_health it rages once, then winds up faster and adds the volley.
## Executions don't kill it: they take execution_damage and end the stagger.

signal engaged
signal phase_two

const PROJECTILE_SCENE := preload("res://combat/projectiles/projectile.tscn")
## Attack → [anim when close (<= attack_range), weight close, weight mid, weight far].
const ATTACKS: Dictionary = {
	&"sweep": [3.0, 0.0, 0.0],
	&"charge": [0.0, 2.0, 3.0],
	&"slam": [1.0, 2.0, 2.0],
	&"volley": [0.0, 2.0, 3.0],
}
const MID_RANGE := 200.0

var phase: int = 1

var _wdata: WardenData
var _last_attack: StringName = &""
var _bolts_left: int = 0
var _bolt_clock: float = 0.0
var _slam_target_x: float = 0.0
var _rng: RandomNumberGenerator

@onready var _charge_hitbox: HitboxComponent = $ChargeHitbox


func _ready() -> void:
	super()
	_wdata = data as WardenData
	assert(_wdata != null, "The Warden needs a WardenData resource")
	add_to_group(&"bosses")
	# Its own red key light, so the boss reads against the dark arena.
	var glow := PointLight2D.new()
	glow.texture = LevelLight.radial_texture()
	glow.texture_scale = 1.6
	glow.color = Color("ff5a5a")
	glow.energy = 1.3
	glow.height = 24.0
	glow.position = Vector2(30.0, -60.0)
	visual.add_child(glow)
	state = &"dormant"
	_rng = RunState.rng.stream(&"warden")
	_charge_hitbox.build_damage = _build_charge_damage
	attack_hitbox.hit_landed.connect(func(_h: HurtboxComponent, _i: DamageInfo) -> void: Audio.play(&"hit_heavy", -2.0))


func _ai(delta: float) -> void:
	apply_gravity(delta)
	match state:
		&"dormant":
			run_toward(0.0, delta)
			if distance_to_target() <= _wdata.intro_range:
				set_state(&"intro")
				face(direction_to_target())
				Audio.play(&"warden_roar", 0.0)
				Feel.shake(0.6)
				engaged.emit()
		&"intro":
			run_toward(0.0, delta)
			if state_time >= _wdata.intro_time:
				set_state(&"approach")
		&"idle", &"approach":
			_approach(delta)
		&"rage":
			run_toward(0.0, delta)
			if state_time >= _wdata.rage_time:
				set_state(&"approach")
		&"sweep_windup":
			run_toward(0.0, delta)
			face(direction_to_target())
			telegraph()
			if state_past_frames(_windup(data.windup_frames)):
				set_state(&"sweep")
				attack_hitbox.reset_hits()
				velocity.x = facing * 140.0 # Step into the swing.
				Audio.play(&"slash_3", -2.0, 0.0, 0.6)
		&"sweep":
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			attack_hitbox.active = not state_past_frames(data.active_frames)
			if attack_hitbox.active:
				attack_hitbox.process_hits()
			else:
				set_state(&"sweep_recover")
		&"sweep_recover":
			run_toward(0.0, delta)
			if state_past_frames(data.recovery_frames):
				set_state(&"approach")
		&"charge_windup":
			run_toward(0.0, delta)
			face(direction_to_target())
			telegraph(true)
			if state_past_frames(_windup(_wdata.charge_windup_frames)):
				set_state(&"charge")
				_charge_hitbox.reset_hits()
				_charge_hitbox.active = true
				Audio.play(&"slam_dive", -2.0, 0.0, 0.7)
		&"charge":
			velocity.x = facing * _wdata.charge_speed
			_charge_hitbox.process_hits()
			if Engine.get_physics_frames() % 6 == 0:
				Feel.dust(global_position, 3, 0.6)
			if is_on_wall():
				_crash()
			elif state_time >= _wdata.charge_max_time:
				_charge_hitbox.active = false
				set_state(&"sweep_recover")
		&"crash":
			_helpless(delta)
			if state_past_frames(_wdata.crash_frames):
				set_state(&"approach")
		&"slam_windup":
			run_toward(0.0, delta)
			face(direction_to_target())
			telegraph(true)
			if state_past_frames(_windup(_wdata.slam_windup_frames)):
				_leap()
		&"slam_air":
			if state_time > 0.1 and is_on_floor():
				_land()
		&"slam_land":
			run_toward(0.0, delta)
			if state_past_frames(_wdata.slam_land_frames):
				set_state(&"approach")
		&"shoot_windup":
			run_toward(0.0, delta)
			face(direction_to_target())
			telegraph()
			if state_past_frames(_windup(_wdata.shoot_windup_frames)):
				set_state(&"shoot")
				_bolts_left = _wdata.shoot_bolts
				_bolt_clock = 0.0
		&"shoot":
			run_toward(0.0, delta)
			_bolt_clock -= delta
			if _bolts_left > 0 and _bolt_clock <= 0.0:
				_fire_bolt(_wdata.shoot_bolts - _bolts_left)
				_bolts_left -= 1
				_bolt_clock = _wdata.shoot_interval
			elif _bolts_left == 0 and state_time >= _wdata.shoot_recovery:
				set_state(&"approach")


## Attacks are armored, and so is the boss while it isn't helpless: it never flinches.
func is_armored() -> bool:
	return true


func take_hit(info: DamageInfo) -> void:
	super(info)
	if phase == 1 and state != &"dead" and health.current <= health.max_health * _wdata.phase2_health:
		phase = 2
		if state != &"staggered":
			set_state(&"rage")
		Audio.play(&"warden_roar", 2.0, 0.0, 0.8)
		Feel.shake(0.8)
		Feel.flash(0.25)
		phase_two.emit()


func face(direction: int) -> void:
	super(direction)
	if direction != 0 and _charge_hitbox:
		_charge_hitbox.scale.x = direction


func animation_for_state() -> StringName:
	match state:
		&"dormant":
			return &"idle"
		&"idle", &"approach":
			return &"walk" if absf(velocity.x) > 10.0 else &"idle"
		&"rage":
			return &"intro"
		&"stunned", &"staggered":
			return &"stagger"
	return super()


func _approach(delta: float) -> void:
	if target == null:
		run_toward(0.0, delta)
		return
	face(direction_to_target())
	var distance := absf(target.global_position.x - global_position.x)
	if state_time >= _wdata.attack_cooldown:
		var attack := _choose_attack(distance)
		if attack != &"":
			_start(attack)
			return
	run_toward(facing if distance > data.attack_range * 0.8 else 0.0, delta)


## Weighted pick by range band; the last attack is less likely to repeat.
func _choose_attack(distance: float) -> StringName:
	var band := 0 if distance <= data.attack_range else (1 if distance <= MID_RANGE else 2)
	var total := 0.0
	var weights := {}
	for attack: StringName in ATTACKS:
		var weight: float = ATTACKS[attack][band]
		if attack == &"volley" and phase < 2:
			weight = 0.0
		if attack == _last_attack:
			weight *= 0.35
		weights[attack] = weight
		total += weight
	if total <= 0.0:
		return &""
	var roll := _rng.randf() * total
	for attack: StringName in weights:
		roll -= float(weights[attack])
		if roll <= 0.0:
			return attack
	return &""


func _start(attack: StringName) -> void:
	_last_attack = attack
	match attack:
		&"sweep":
			set_state(&"sweep_windup")
			Audio.play(&"hound_windup", -4.0, 0.0, 0.6)
		&"charge":
			set_state(&"charge_windup")
			Audio.play(&"draw_charge", -2.0, 0.0, 0.7)
		&"slam":
			set_state(&"slam_windup")
			Audio.play(&"hound_windup", -4.0, 0.0, 0.5)
		&"volley":
			set_state(&"shoot_windup")
			Audio.play(&"drone_charge", -6.0, 0.0, 0.7)


## The current wind-up's length in frames (scaled in phase 2), or -1 if not winding up.
func current_windup_frames() -> int:
	match state:
		&"sweep_windup":
			return _windup(data.windup_frames)
		&"charge_windup":
			return _windup(_wdata.charge_windup_frames)
		&"slam_windup":
			return _windup(_wdata.slam_windup_frames)
		&"shoot_windup":
			return _windup(_wdata.shoot_windup_frames)
	return -1


func _windup(frames: int) -> int:
	return maxi(roundi(frames * (_wdata.phase2_windup_scale if phase == 2 else 1.0)), 18)


func _crash() -> void:
	_charge_hitbox.active = false
	set_state(&"crash")
	velocity = Vector2(-facing * 120.0, -120.0)
	Feel.shake(0.7)
	Feel.impact(global_position + Vector2(facing * 30.0, -40.0), Vector2(-facing, -0.3), 1.0, Feel.WHITE_HOT)
	Audio.play(&"slam_land", 0.0, 0.0, 1.2)
	Audio.play(&"clank", -2.0, 0.0, 0.7)


func _leap() -> void:
	set_state(&"slam_air")
	_slam_target_x = target.global_position.x if target else global_position.x
	var time := _wdata.slam_air_time
	velocity = Vector2((_slam_target_x - global_position.x) / time, -data.gravity * time / 2.0)
	Audio.play(&"jump", 0.0, 0.0, 0.6)


func _land() -> void:
	set_state(&"slam_land")
	velocity = Vector2.ZERO
	for side: float in [-1.0, 1.0]:
		var wave := Shockwave.new()
		wave.direction = side
		wave.speed = _wdata.shockwave_speed
		wave.life = _wdata.shockwave_life
		wave.build_damage = _build_shockwave_damage.bind(side)
		wave.position = global_position + Vector2(side * 10.0, 0.0)
		get_parent().add_child(wave)
	Feel.shake(0.8)
	Feel.ring(global_position, 70.0, Color("4fd1c5"))
	Feel.dust(global_position, 16, 2.0)
	Audio.play(&"slam_land", 2.0)


func _fire_bolt(index: int) -> void:
	if target == null:
		return
	var muzzle := global_position + Vector2(facing * 52.0, -50.0)
	var aim := (target.global_position + Vector2(0.0, -10.0)) - muzzle
	var offset := (index - (_wdata.shoot_bolts - 1) / 2.0) * deg_to_rad(_wdata.shoot_spread_degrees)
	var bolt := PROJECTILE_SCENE.instantiate() as Projectile
	bolt.launch(self, aim.rotated(offset), data.projectile_speed)
	bolt.position = muzzle
	get_parent().add_child(bolt)
	Audio.play(&"laser", -8.0, 0.05)


func _build_charge_damage() -> DamageInfo:
	var info := DamageInfo.new()
	info.resolve_cost = _wdata.charge_resolve_cost
	info.knockback = Vector2(_wdata.charge_knockback.x * facing, _wdata.charge_knockback.y)
	info.hit_freeze_frames = data.attack_hit_freeze
	info.source = self
	info.tags = PackedStringArray(["unblockable"])
	return info


func _build_shockwave_damage(side: float) -> DamageInfo:
	var info := DamageInfo.new()
	info.resolve_cost = _wdata.shockwave_resolve_cost
	info.knockback = Vector2(side * 180.0, -240.0)
	info.hit_freeze_frames = 3
	info.source = self
	info.tags = PackedStringArray(["unblockable"])
	return info


func _die() -> void:
	_charge_hitbox.active = false
	Feel.flash(0.6)
	Feel.shake(1.0)
	for i in 4: # A chain of small blasts before it falls apart.
		var at := global_position + Vector2(_rng.randf_range(-30.0, 30.0), _rng.randf_range(-80.0, -20.0))
		get_tree().create_timer(0.08 * i, true, false, true).timeout.connect(
			Feel.death_burst.bind(at, Color("ff5a36"), 0.8))
	super()
