extends Node
## First scene. Autoloads (settings, profile) are ready by now; go to the first screen:
## the title, or straight to the sandbox / a run for development and bot tests.
##   -- --demo=<scenario> / --room=<map> / --overview   the sandbox (TestArena)
##   -- --run [--seed=N] [--demo=<scenario>] [--autoclear]   a run, skipping the title
##   -- --end=win / --end=lose                           the end screen with sample stats


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if "--run" in args:
		var run_seed := -1
		for arg in args:
			if arg.begins_with("--seed="):
				run_seed = int(arg.get_slice("=", 1))
		RunState.start_run(run_seed)
		Game.goto(&"run", Game.Mode.IN_RUN)
		return
	for arg in args:
		if arg.begins_with("--demo") or arg.begins_with("--room") or arg == "--overview":
			Game.goto(&"test_arena", Game.Mode.IN_RUN)
			return
		if arg.begins_with("--end="):
			RunState.start_run()
			RunState.rooms = RunPlan.make(RunState.rng.stream(&"rooms"))
			RunState.rooms_cleared = 7 if arg.ends_with("win") else 4
			RunState.kills = 23
			RunState.executions = 6
			RunState.freed = 2
			RunState.best_combo = 14
			RunState.end_run(arg.ends_with("win"))
			Game.goto(&"end", Game.Mode.RESULTS)
			return
	Game.goto(&"title", Game.Mode.TITLE)
