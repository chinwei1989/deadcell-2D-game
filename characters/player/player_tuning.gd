class_name PlayerTuning
extends Resource
## Movement and combat numbers for one playable character (PLAN.md sections 4 and 5.4).
## Units: pixels, seconds, and physics frames (60 per second). Each character has its
## own .tres file; tune there, never in player.gd.

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

@export_group("Wall")
@export var wall_slide_speed: float = 90.0
@export var wall_jump_height: float = 64.0
@export var wall_jump_push: float = 220.0

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
