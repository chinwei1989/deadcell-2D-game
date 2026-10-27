extends TestCase
## Run rooms and the run plan: every room map must be playable, and the same seed must
## always give the same run.

const FEET := ["P", "D", "H", "L", "?", "W", ">"]


func test_every_room_map_is_valid() -> void:
	for theme in RunPlan.AREAS:
		assert_true(theme.rooms.size() >= theme.rooms_per_run, "%s has enough rooms" % theme.display_name)
		for room_name in theme.rooms:
			var path := AreaTheme.room_path(room_name)
			assert_true(FileAccess.file_exists(path), "%s exists" % path)
			var rows := Level.load_map(path)
			assert_true(rows.size() > 0, "%s loads" % path)
			var width := rows[0].length()
			for y in rows.size():
				assert_eq(rows[y].length(), width, "%s row %d width" % [path, y])
				assert_eq(rows[y][0], "#", "%s left border row %d" % [path, y])
				assert_eq(rows[y][width - 1], "#", "%s right border row %d" % [path, y])
			assert_eq(rows[0].count("#"), width, "%s top border" % path)
			assert_eq(rows[rows.size() - 1].count("#"), width, "%s bottom border" % path)
			assert_eq(_count(rows, "P"), 1, "%s has one spawn" % path)
			assert_eq(_count(rows, ">"), 1, "%s has one exit" % path)
			for y in rows.size() - 1:
				for x in width:
					if rows[y][x] in FEET:
						assert_true(rows[y + 1][x] in ["#", "="], "%s: '%s' at (%d, %d) stands on ground" % [path, rows[y][x], x, y])


func test_boss_room_has_the_warden() -> void:
	var boss: AreaTheme = RunPlan.AREAS[RunPlan.AREAS.size() - 1]
	assert_eq(_count(Level.load_map(AreaTheme.room_path(boss.rooms[0])), "W"), 1)


func test_plan_is_deterministic_and_complete() -> void:
	var a := RunPlan.make(RngStreams.new(1234).stream(&"rooms"))
	var b := RunPlan.make(RngStreams.new(1234).stream(&"rooms"))
	var expected := 0
	for theme in RunPlan.AREAS:
		expected += mini(theme.rooms_per_run, theme.rooms.size())
	assert_eq(a.size(), expected)
	for i in a.size():
		assert_eq(String(a[i]["map"]), String(b[i]["map"]), "room %d same for the same seed" % i)
	assert_true(String(a[a.size() - 1]["map"]).contains("boss"), "the boss room is last")
	assert_true(bool(a[0]["first_in_area"]), "the first room starts an area")


func test_plan_never_repeats_a_room() -> void:
	for seed_value in [1, 2, 3, 99, 4242]:
		var seen := {}
		for room in RunPlan.make(RngStreams.new(seed_value).stream(&"rooms")):
			assert_false(seen.has(room["map"]), "seed %d repeats %s" % [seed_value, room["map"]])
			seen[room["map"]] = true


func test_different_seeds_vary_the_run() -> void:
	var first := RunPlan.make(RngStreams.new(1).stream(&"rooms"))
	var differs := false
	for seed_value in range(2, 12):
		var other := RunPlan.make(RngStreams.new(seed_value).stream(&"rooms"))
		for i in other.size():
			if other[i]["map"] != first[i]["map"]:
				differs = true
	assert_true(differs, "seeds pick different rooms")


func _count(rows: PackedStringArray, character: String) -> int:
	var total := 0
	for row in rows:
		total += row.count(character)
	return total
