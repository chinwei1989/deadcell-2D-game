class_name EnemyData
extends Resource
## Numbers for one enemy type (PLAN.md section 9). Each enemy has its own .tres file.
## Frame values are at 60 fps (FrameTime.seconds()). Every attack needs a wind-up of at
## least 18 frames so players can read it (PLAN.md section 5.4); a unit test checks this.

@export_group("Body")
@export var max_health: float = 20.0
## 0 = no posture bar (dies before posture matters, e.g. drones).
@export var max_posture: float = 0.0
@export var posture_recovery_delay: float = 1.0
@export var posture_recovery_rate: float = 10.0
@export var stagger_time: float = 2.0
## 0 = full knockback, 1 = immune.
@export_range(0.0, 1.0) var knockback_resistance: float = 0.0
@export var uses_gravity: bool = true
@export var gravity: float = 1500.0
@export var max_fall_speed: float = 540.0

@export_group("Movement")
@export var move_speed: float = 80.0
@export var acceleration: float = 800.0

@export_group("Senses")
@export var aggro_range: float = 140.0
@export var attack_range: float = 40.0

@export_group("Attack")
@export var windup_frames: int = 24
@export var active_frames: int = 6
@export var recovery_frames: int = 30
@export var lunge_speed: float = 0.0
@export var lunge_hop: float = 0.0
@export var attack_resolve_cost: float = 1.0
## x is multiplied by the enemy's facing.
@export var attack_knockback: Vector2 = Vector2(200.0, -150.0)
@export var attack_hit_freeze: int = 4

@export_group("When parried")
@export var parried_posture_damage: float = 20.0
## Seconds the enemy is stunned after being parried (if its posture doesn't break).
@export var parried_stun: float = 0.8

@export_group("Reactions")
## Hit stun after a hit that doesn't break posture or kill: the enemy recoils, helpless.
## 0 = never flinches (heavy enemies).
@export var flinch_frames: int = 14
## False = attacks are armored: hits during a wind-up or an attack don't interrupt it
## (players must still read and answer the telegraph).
@export var flinch_during_attacks: bool = false
## Machines are cut in two by blade kills and burst into scrap; people collapse.
@export var is_machine: bool = true
## Seconds the remains stay before they're cleared.
@export var corpse_time: float = 1.2

@export_group("Ranged")
@export var projectile_speed: float = 160.0
@export var fire_cooldown: float = 1.6
