extends Node
## State of the current run (seed, Threat Level, RNG streams). Reset at the start of
## every run; permanent progress belongs in Profile instead.

var active: bool = false
var seed_value: int = 0
var threat_level: int = 0
var rng: RngStreams = RngStreams.new(0)


## Pass a seed for daily runs and co-op (the host's seed); -1 picks a random one.
func start_run(run_seed: int = -1, threat: int = 0) -> void:
	seed_value = run_seed if run_seed >= 0 else randi()
	threat_level = threat
	rng = RngStreams.new(seed_value)
	active = true


func end_run() -> void:
	active = false
