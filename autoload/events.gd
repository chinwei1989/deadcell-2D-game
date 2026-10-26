extends Node
## Global signal bus for events many systems care about (HUD, audio, analytics,
## achievements). Node-to-node communication should use the node's own signals instead.

@warning_ignore_start("unused_signal")
signal player_hit(player: Node, info: DamageInfo)
signal player_died(player: Node)
signal player_respawned(player: Node)
signal parry_succeeded(player: Node, attacker: Node)
signal guard_blocked(player: Node)
signal projectile_deflected(projectile: Node, perfect: bool)
signal enemy_damaged(enemy: Node, info: DamageInfo)
signal enemy_killed(enemy: Node)
signal enemy_executed(enemy: Node, by: Node)
## A Linked human was freed instead of executed (PLAN.md section 9.2).
signal linked_freed(linked: Node, by: Node)
signal posture_broken(entity: Node)
## Local only (screen shake never syncs over the network).
signal screen_shake(trauma: float)
## Local only: Focus slow motion started or stopped.
signal focus_changed(active: bool)
## Local only: brief full-screen flash (executions, big finishers). strength 0..1.
signal screen_flash(strength: float)
@warning_ignore_restore("unused_signal")
