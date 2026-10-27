class_name RunPlan
## Picks the rooms of a run, in order: rooms_per_run random rooms from each area, then the
## boss. Deterministic for a given RNG stream (same seed → same run, for co-op and dailies).

const AREAS: Array[AreaTheme] = [
	preload("res://game/run/areas/neon_slums.tres"),
	preload("res://game/run/areas/rain_rooftops.tres"),
	preload("res://game/run/areas/warden_arena.tres"),
]


## [{"theme": AreaTheme, "map": path, "first_in_area": bool}] for each room of the run.
static func make(rng: RandomNumberGenerator, areas: Array[AreaTheme] = AREAS) -> Array[Dictionary]:
	var rooms: Array[Dictionary] = []
	for theme in areas:
		var pool := Array(theme.rooms)
		for i in range(pool.size() - 1, 0, -1): # Shuffle with the run's own stream.
			var j := rng.randi_range(0, i)
			var swap: Variant = pool[i]
			pool[i] = pool[j]
			pool[j] = swap
		for k in mini(theme.rooms_per_run, pool.size()):
			rooms.append({"theme": theme, "map": AreaTheme.room_path(pool[k]), "first_in_area": k == 0})
	return rooms
