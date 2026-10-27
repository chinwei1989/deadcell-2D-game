extends Node
## State of the current run (seed, Threat Level, RNG streams, rooms, stats). Reset at the
## start of every run; permanent progress belongs in Profile instead.

var active: bool = false
var seed_value: int = 0
var threat_level: int = 0
var rng: RngStreams = RngStreams.new(0)
## Rooms of this run, in order: [{"theme": AreaTheme, "map": path}] (see RunPlan).
var rooms: Array[Dictionary] = []
var room_index: int = 0
## Resolve pips carried from room to room (-1 = full).
var carried_pips: float = -1.0

# Stats for the end screen.
var kills: int = 0
var executions: int = 0
var freed: int = 0
var best_combo: int = 0
var rooms_cleared: int = 0
var victory: bool = false
var _start_msec: int = 0
var _end_msec: int = 0


func _ready() -> void:
	Events.enemy_killed.connect(func(_e: Node) -> void: kills += 1)
	Events.enemy_executed.connect(func(_e: Node, _by: Node) -> void: executions += 1)
	Events.linked_freed.connect(func(_e: Node, _by: Node) -> void: freed += 1)


## Pass a seed for daily runs and co-op (the host's seed); -1 picks a random one.
func start_run(run_seed: int = -1, threat: int = 0) -> void:
	seed_value = run_seed if run_seed >= 0 else randi()
	threat_level = threat
	rng = RngStreams.new(seed_value)
	active = true
	rooms = []
	room_index = 0
	carried_pips = -1.0
	kills = 0
	executions = 0
	freed = 0
	best_combo = 0
	rooms_cleared = 0
	victory = false
	_start_msec = Time.get_ticks_msec()
	_end_msec = 0


func end_run(won: bool) -> void:
	active = false
	victory = won
	_end_msec = Time.get_ticks_msec()


func note_combo(hits: int) -> void:
	best_combo = maxi(best_combo, hits)


## Seconds since the run started (frozen once it ends).
func elapsed() -> float:
	var end := _end_msec if _end_msec > 0 else Time.get_ticks_msec()
	return (end - _start_msec) / 1000.0
