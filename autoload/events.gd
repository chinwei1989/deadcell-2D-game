extends Node
## Global signal bus for events many systems care about (HUD, audio, analytics,
## achievements). Node-to-node communication should use the node's own signals instead.

@warning_ignore_start("unused_signal")
signal player_hit(player: Node, info: DamageInfo)
signal player_died(player: Node)
signal player_respawned(player: Node)
signal enemy_damaged(enemy: Node, info: DamageInfo)
signal enemy_killed(enemy: Node)
signal posture_broken(entity: Node)
## Local only (screen shake never syncs over the network).
signal screen_shake(trauma: float)
@warning_ignore_restore("unused_signal")
