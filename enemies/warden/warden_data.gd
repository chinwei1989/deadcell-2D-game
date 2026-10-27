class_name WardenData
extends EnemyData
## Extra numbers for the Warden boss (enemies/warden/warden.gd). The base EnemyData attack
## fields are its baton sweep. Frame values are at 60 fps; every wind-up stays >= 18 frames
## even after the phase 2 speed-up.

@export_group("Fight")
## The fight starts when a player comes this close.
@export var intro_range: float = 230.0
@export var intro_time: float = 1.8
## Seconds of walking between attacks.
@export var attack_cooldown: float = 0.45
## Below this share of health: phase 2 (faster wind-ups, bolt volleys).
@export var phase2_health: float = 0.5
@export var phase2_windup_scale: float = 0.8
@export var rage_time: float = 1.2

@export_group("Charge")
@export var charge_windup_frames: int = 40
@export var charge_speed: float = 380.0
@export var charge_max_time: float = 1.1
## Helpless after slamming into a wall (open to punishment).
@export var crash_frames: int = 70
@export var charge_resolve_cost: float = 1.5
@export var charge_knockback: Vector2 = Vector2(320, -200)

@export_group("Slam")
@export var slam_windup_frames: int = 34
@export var slam_air_time: float = 0.7
@export var slam_land_frames: int = 46
@export var shockwave_speed: float = 230.0
@export var shockwave_life: float = 1.4
@export var shockwave_resolve_cost: float = 1.0

@export_group("Volley")
@export var shoot_windup_frames: int = 30
@export var shoot_bolts: int = 3
@export var shoot_spread_degrees: float = 12.0
@export var shoot_interval: float = 0.16
@export var shoot_recovery: float = 0.6
