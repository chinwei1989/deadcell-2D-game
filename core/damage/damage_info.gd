class_name DamageInfo
extends RefCounted
## One hit, from attacker to target (PLAN.md section 27.2). Built fresh for every hit by
## the attacker, then read by the target, which fills in the result fields at the end.

enum Element { NONE, HEAT, SHOCK, CRYO, BLEED }

## Damage to enemies' health.
var amount: float = 0.0
## Posture damage (fills the target's posture bar).
var posture: float = 0.0
## Resolve pips this hit costs a player.
var resolve_cost: float = 1.0
var element: Element = Element.NONE
var knockback: Vector2 = Vector2.ZERO
var hit_freeze_frames: int = 0
var is_crit: bool = false
## False for non-lethal damage, e.g. hits on the Linked (PLAN.md section 9.2).
var is_lethal: bool = true
## True for player blade attacks: hitting a staggered enemy executes it.
var can_execute: bool = false
## The node the hit came from (used for direction checks such as parry and guard).
var source: Node = null
var source_peer_id: int = 1
var tags: PackedStringArray = []

# Results, set by the target.
var executed: bool = false
var killed: bool = false
