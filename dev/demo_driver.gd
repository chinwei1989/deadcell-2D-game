extends Node
## Scripted and bot-driven input for recording playtests without a person (PLAN.md
## section 34). The test arena adds this when the game is started with --demo=<scenario>.
## Events (parries, deflects, executions, state changes) are printed to stdout, so a run
## can be checked from the log as well as from recorded frames.
##
##   godot --path . --write-movie /tmp/frames/f.png --fixed-fps 60 --quit-after 420 -- --demo=hound
##   godot --headless --path . --fixed-fps 60 --quit-after 420 -- --demo=hound   (log only)
## Always pass --fixed-fps 60 headless, or game time runs at real-time speed.
##
## Scenarios:
##   combo  run to a dummy, 3-hit combo (stagger), execution, quick-draw, Focus
##   hound  walk at the Hound; the bot parries its lunge and executes it
##   drone  stand under the Patrol Drone; the bot deflects its bolts back at it
##   ledge  hop next to a wall; the player grabs the ledge and climbs up
##   slam   step off a platform and slam down onto the dummy below
##   ninja  sprint, double-jump front flip, dodge roll, short sneak steps
##   linked walk at a Linked Citizen; the bot parries its grab and cuts the link
##   warden fight the Warden (run with --room=res://game/run/rooms/boss/warden_arena.txt):
##          parry sweeps, roll through charges, jump shockwaves, deflect bolts, punish
##   walk   pace right and left, never fight (with --run: tests losing a run)
##   brawl  walk at the Hound, slash it whenever it isn't attacking (flinches, recoil) and
##          roll away from its lunges, until it staggers; then execute it (cut in two)
## Set the DEMO_TRACE environment variable to also print the player's position and state.

## [time in seconds, action, pressed]
const TIMELINES: Dictionary = {
	"combo": [
		[0.1, &"move_right", true], [0.95, &"move_right", false],
		[1.0, &"slash", true], [1.05, &"slash", false],
		[1.25, &"slash", true], [1.3, &"slash", false],
		[1.5, &"slash", true], [1.55, &"slash", false],
		[2.0, &"slash", true], [2.05, &"slash", false],
		[3.4, &"slash", true], [4.1, &"slash", false],
		[4.8, &"focus", true], [4.85, &"focus", false],
		[5.0, &"move_left", true], [5.6, &"move_left", false],
		[5.7, &"slash", true], [5.75, &"slash", false],
	],
	"hound": [],
	"brawl": [],
	"warden": [],
	"walk": [
		[0.1, &"move_right", true], [6.0, &"move_right", false], [6.0, &"move_left", true], [12.0, &"move_left", false],
		[12.0, &"move_right", true], [18.0, &"move_right", false], [18.0, &"move_left", true], [24.0, &"move_left", false],
		[24.0, &"move_right", true],
	],
	"linked": [],
	"drone": [],
	"ledge": [
		[0.1, &"move_right", true],
		[0.25, &"jump", true], [0.27, &"jump", false],
		[0.8, &"move_right", false],
		[1.0, &"move_up", true], [1.1, &"move_up", false],
	],
	"ninja": [
		[0.1, &"move_right", true], [1.3, &"move_right", false],
		[0.5, &"jump", true], [0.6, &"jump", false],
		[0.75, &"jump", true], [0.8, &"jump", false],
		[1.6, &"dodge", true], [1.65, &"dodge", false],
		[2.2, &"move_left", true], [2.3, &"move_left", false],
		[2.6, &"move_left", true], [3.6, &"move_left", false],
	],
	"slam": [
		[0.1, &"move_right", true], [0.42, &"move_right", false],
		[0.5, &"move_down", true],
		[0.5, &"slash", true], [0.55, &"slash", false],
		[0.8, &"move_down", false],
	],
}
## Map marker (see the legend in test_arena.gd) where the player starts, if not at P.
const STARTS: Dictionary = {
	"hound": &"b",
	"brawl": &"b",
	"drone": &"c",
	"ledge": &"d",
	"slam": &"e",
	"linked": &"f",
}
const BOT_SCENARIOS: Array[String] = ["hound", "drone", "linked", "brawl", "warden"]
## Warden states where it can't hurt you: hit it.
const WARDEN_OPENINGS: Array[StringName] = [&"crash", &"slam_land", &"sweep_recover", &"stunned", &"staggered", &"approach", &"shoot"]
## Seconds before the bot can press the same action again.
const BOT_COOLDOWN := 0.3

var _scenario: String
var _time: float = 0.0
var _next: int = 0
var _release_at: Dictionary = {}
var _cooldowns: Dictionary = {}


func _init(scenario: String = "combo") -> void:
	_scenario = scenario if TIMELINES.has(scenario) else "combo"


func _ready() -> void:
	# Run before gameplay nodes so pressed actions count as "just pressed" this frame.
	process_physics_priority = -100
	print("[demo] scenario: ", _scenario)
	Events.parry_succeeded.connect(func(_p: Node, a: Node) -> void: _log("parry succeeded vs %s" % a.name))
	Events.guard_blocked.connect(func(_p: Node) -> void: _log("guard blocked"))
	Events.projectile_deflected.connect(func(_p: Node, perfect: bool) -> void: _log("deflect (perfect=%s)" % perfect))
	Events.enemy_executed.connect(func(e: Node, _by: Node) -> void: _log("executed %s" % e.name))
	Events.enemy_killed.connect(func(e: Node) -> void: _log("killed %s" % e.name))
	Events.enemy_damaged.connect(func(e: Node, _i: DamageInfo) -> void: _log("hit %s (%s)" % [e.name, e.get(&"state")]))
	Events.posture_broken.connect(func(e: Node) -> void: _log("posture broken: %s" % e.name))
	Events.linked_freed.connect(func(e: Node, _by: Node) -> void: _log("freed %s" % e.name))
	Events.player_hit.connect(func(_p: Node, _i: DamageInfo) -> void: _log("player hit"))
	Events.focus_changed.connect(func(active: bool) -> void: _log("focus %s" % ("on" if active else "off")))
	var player := _player()
	if player:
		player.state_changed.connect(func(s: Player.State) -> void: _log("state %s" % Player.State.keys()[s]))
		var arena := get_tree().get_first_node_in_group(&"arena") as Level
		if arena and STARTS.has(_scenario):
			player.global_position = arena.marker(STARTS[_scenario]) + Vector2(0.0, -Player.HALF_HEIGHT)
			player.spawn_position = player.global_position
			player.reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	_time += delta
	for action: StringName in _release_at.keys():
		if _time >= float(_release_at[action]):
			Input.action_release(action)
			_release_at.erase(action)
	var timeline: Array = TIMELINES[_scenario]
	while _next < timeline.size() and _time >= float(timeline[_next][0]):
		var step: Array = timeline[_next]
		if step[2]:
			Input.action_press(step[1])
		else:
			Input.action_release(step[1])
		_next += 1
	if _scenario in BOT_SCENARIOS:
		_bot()
	if OS.has_environment("DEMO_TRACE") and Engine.get_physics_frames() % 15 == 0:
		var p := _player()
		if p:
			_log("trace pos=%s vel=%s state=%s" % [p.global_position.round(), p.velocity.round(), Player.State.keys()[p.state]])


## Reacts like a (very good) player: turns toward threats, parries lunges, executes
## staggered enemies, aims slashes at incoming bolts, and walks toward enemies in the
## hound scenario. Steering and aim are pressed in the same frame as the attack, so the
## player's facing and slash aim use them.
func _bot() -> void:
	var player := _player()
	if player == null:
		return
	var steer := 0.0
	var aim_up := false
	var hold_interact := false
	var nearest := INF
	for node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as EnemyBase
		var distance := player.global_position.distance_to(enemy.global_position)
		nearest = minf(nearest, distance)
		var side := signf(enemy.global_position.x - player.global_position.x)
		if enemy is Warden:
			var bot_steer := _fight_warden(enemy as Warden, player, distance, side)
			if bot_steer != 0.0:
				steer = bot_steer
			continue
		# Parry as the wind-up ends, like a player reading the telegraph. (Presses made by a
		# script only count as "just pressed" on the next physics frame, so reacting to the
		# lunge itself is one frame too late against fast grabs.)
		var winding_up := enemy.state == &"windup" and enemy.state_past_frames(enemy.data.windup_frames - 3)
		if _scenario == "brawl" and winding_up and distance < 80.0:
			steer = -side # No parries here: roll away from the lunge.
			_tap(&"dodge")
		elif _scenario == "brawl" and enemy.state != &"staggered" and distance < 66.0 and not enemy.is_armored():
			steer = side
			_tap(&"slash")
		elif (winding_up or enemy.state == &"lunge") and distance < 56.0:
			steer = side
			_tap(&"parry")
		elif enemy.state == &"staggered" and distance < 56.0:
			steer = side
			if enemy is LinkedCitizen:
				hold_interact = true
			else:
				_tap(&"slash")
	for node in get_tree().get_nodes_in_group(&"shockwaves"):
		var wave := node as Shockwave
		var dx := player.global_position.x - wave.global_position.x
		if signf(dx) == wave.direction and absf(dx) < 34.0 and absf(player.global_position.y + Player.HALF_HEIGHT - wave.global_position.y) < 12.0:
			_tap(&"jump")
	for node in get_tree().get_nodes_in_group(&"projectiles"):
		var bolt := node as Projectile
		var to_player := player.global_position + Vector2(0.0, -6.0) - bolt.global_position
		if not bolt.deflected and to_player.length() < 46.0 and bolt.velocity.dot(to_player) > 0.0:
			steer = signf(-to_player.x)
			aim_up = to_player.y > 12.0
			_tap(&"slash")
	if hold_interact:
		steer = 0.0 # Stand still while cutting the link.
	elif steer == 0.0 and _scenario in ["hound", "linked", "brawl", "warden"] and nearest > 50.0 and nearest < 1000.0:
		steer = 1.0
	_set_pressed(&"interact", hold_interact)
	_set_pressed(&"move_right", steer > 0.0)
	_set_pressed(&"move_left", steer < 0.0)
	_set_pressed(&"move_up", aim_up)


## Returns how to steer (0 = let the default walk-in steering decide).
func _fight_warden(w: Warden, player: Player, distance: float, side: float) -> float:
	var windup := w.current_windup_frames()
	var late := windup > 0 and w.state_past_frames(windup - 4)
	match w.state:
		&"sweep_windup":
			if late and distance < 120.0:
				_tap(&"parry")
				return side
		&"charge":
			if distance < 70.0 and signf(w.velocity.x) == -side:
				_tap(&"dodge") # Roll through it (i-frames).
				return side
			return side
		&"slam_windup", &"slam_air":
			return -side if distance < 60.0 else 0.0
	if w.state in WARDEN_OPENINGS and distance < 76.0:
		_tap(&"slash")
		return side
	return 0.0


func _set_pressed(action: StringName, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _tap(action: StringName) -> void:
	if _time < float(_cooldowns.get(action, 0.0)):
		return
	Input.action_press(action)
	_release_at[action] = _time + 0.04
	_cooldowns[action] = _time + BOT_COOLDOWN


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"players") as Player


func _log(message: String) -> void:
	print("[demo t=%.2f] %s" % [_time, message])
