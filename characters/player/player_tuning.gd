class_name PlayerTuning
extends Resource
## Movement and combat numbers for one playable character (PLAN.md sections 4 and 5).
## Units: pixels, seconds, and frames at 60 fps (converted with FrameTime.seconds()).
## Each character has its own .tres file; tune there, never in player.gd.

@export_group("Run")
@export var run_speed: float = 200.0
@export var ground_acceleration: float = 2600.0
@export var ground_deceleration: float = 3200.0
@export var air_acceleration: float = 1800.0

@export_group("Jump")
@export var jump_height: float = 80.0
## Height of a tapped jump (jump released early).
@export var min_jump_height: float = 32.0
@export var double_jump_height: float = 60.0
@export var air_jumps: int = 1
@export var gravity_up: float = 1500.0
@export var gravity_down: float = 2300.0
@export var max_fall_speed: float = 540.0
@export var coyote_time: float = 0.10
@export var jump_buffer: float = 0.12
@export var drop_through_time: float = 0.2

@export_group("Wall and ledge")
@export var wall_slide_speed: float = 90.0
@export var wall_jump_height: float = 64.0
@export var wall_jump_push: float = 220.0
## How far past the body a ledge can be grabbed.
@export var ledge_reach_x: float = 8.0
## How far above the head a ledge top can be grabbed.
@export var ledge_reach_y: float = 12.0
## Seconds before a released ledge can be grabbed again.
@export var ledge_regrab_delay: float = 0.25

@export_group("Dodge")
@export var dodge_distance: float = 104.0
@export var dodge_duration: float = 0.30
@export var dodge_iframe_start: float = 0.03
@export var dodge_iframe_end: float = 0.26
@export var dodge_cooldown: float = 0.10

@export_group("Slash combo")
## One entry per combo hit. All arrays must have the same length.
@export var slash_damage: Array[float] = [10.0, 12.0, 20.0]
@export var slash_posture: Array[float] = [8.0, 10.0, 18.0]
@export var slash_startup_frames: Array[int] = [4, 4, 7]
@export var slash_active_frames: Array[int] = [4, 4, 5]
@export var slash_recovery_frames: Array[int] = [9, 9, 16]
@export var slash_hit_freeze: Array[int] = [3, 3, 6]
@export var slash_knockback: Array[float] = [60.0, 60.0, 180.0]
@export var slash_lunge_speed: float = 120.0

@export_group("Slash choreography")
## Forward burst when each hit's active frames start (px/s), held for slash_step_frames.
@export var slash_step_speed: Array[float] = [150.0, 180.0, 300.0]
@export var slash_step_frames: Array[int] = [6, 6, 10]
## Upward pop per hit: the finisher leaps.
@export var slash_hop: Array[float] = [0.0, 0.0, 230.0]
## Attack magnetism: an enemy in front within this range pulls the step toward it,
## stopping slash_magnet_stop px short (fast enough to arrive, up to slash_magnet_max_speed).
@export var slash_magnet_range: float = 90.0
@export var slash_magnet_stop: float = 26.0
@export var slash_magnet_max_speed: float = 420.0
## Gravity multiplier while slashing in the air (hang time for air combos).
@export var air_slash_gravity_scale: float = 0.3
## Upward pop on each of the first air_slash_pops air slashes before landing.
@export var air_slash_pop: float = 110.0
@export var air_slash_pops: int = 3

@export_group("Combo")
## Seconds without landing a hit before the combo counter resets.
@export var combo_timeout: float = 1.8
## Combo hits for the blade trail to reach full heat (white-hot).
@export var combo_full_heat: int = 30

@export_group("Parry and guard")
## Tap Parry: hits from the front during this window are parried.
@export var parry_window_frames: int = 8
## Lock-out after a parry that caught nothing (unless Parry is held into a guard).
@export var parry_whiff_recovery_frames: int = 12
@export var perfect_parry_resolve: float = 0.5
@export var parry_hit_freeze: int = 6
## Fraction of a hit's Resolve cost taken while guarding.
@export var guard_chip: float = 0.25
@export var guard_pushback: float = 80.0

@export_group("Deflect")
## A projectile slashed within this many active frames is perfectly deflected (sent back
## at the shooter as a crit).
@export var perfect_deflect_frames: int = 4
@export var deflect_speed_multiplier: float = 1.6
@export var deflect_damage: float = 12.0
@export var deflect_posture: float = 10.0
@export var perfect_deflect_damage: float = 30.0

@export_group("Quick-draw")
## Holding Slash this long during the first combo hit sheathes into a quick-draw charge.
@export var draw_hold_frames: int = 14
@export var draw_charge_frames: int = 21
@export var draw_distance: float = 120.0
@export var draw_dash_frames: int = 6
@export var draw_recovery_frames: int = 14
@export var draw_damage: float = 35.0
@export var draw_posture: float = 30.0
## Multiplier for a fully charged quick-draw (always a crit).
@export var draw_crit_multiplier: float = 1.5
@export var draw_hit_freeze: int = 10
## Movement speed while charging, as a fraction of run_speed.
@export var draw_charge_move_factor: float = 0.3

@export_group("Slam")
## Down + Slash in the air: dive straight down, hitting what's below, then a shockwave on landing.
@export var slam_speed: float = 700.0
@export var slam_damage: float = 14.0
@export var slam_posture: float = 12.0
@export var slam_landing_damage: float = 10.0
@export var slam_landing_posture: float = 22.0
@export var slam_landing_radius: float = 40.0
@export var slam_recovery_frames: int = 12
@export var slam_hit_freeze: int = 4

@export_group("Cut the link")
## Hold Interact this long next to a staggered Linked to free them.
@export var cut_link_time: float = 0.6
@export var cut_link_range: float = 40.0

@export_group("Execution")
@export var execution_resolve: float = 1.0
@export var execution_hit_freeze: int = 12

@export_group("Focus")
@export var focus_max_seconds: float = 3.0
@export var focus_time_scale: float = 0.35
@export var focus_refill_kill: float = 0.6
@export var focus_refill_parry: float = 0.8
@export var focus_refill_deflect: float = 0.5
@export var focus_refill_perfect_deflect: float = 1.0

@export_group("Damage taken")
@export var max_resolve: float = 4.0
@export var hurt_invulnerability: float = 0.8
@export var hurt_stun_time: float = 0.25
@export var respawn_time: float = 1.0


func jump_velocity() -> float:
	return sqrt(2.0 * gravity_up * jump_height)


func min_jump_velocity() -> float:
	return sqrt(2.0 * gravity_up * min_jump_height)


func double_jump_velocity() -> float:
	return sqrt(2.0 * gravity_up * double_jump_height)


func wall_jump_velocity() -> float:
	return sqrt(2.0 * gravity_up * wall_jump_height)


func dodge_speed() -> float:
	return dodge_distance / dodge_duration


func combo_length() -> int:
	return slash_damage.size()
