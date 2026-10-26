extends TestCase
## Hit reactions and deaths: who flinches, and where a blade cut falls on a sprite frame.


func test_flinch_unless_armored() -> void:
	var data := EnemyData.new()
	assert_true(EnemyBase.should_flinch(data, &"approach", false, false))
	assert_false(EnemyBase.should_flinch(data, &"windup", true, false), "wind-ups are armored")
	data.flinch_during_attacks = true
	assert_true(EnemyBase.should_flinch(data, &"windup", true, false))


func test_no_flinch_when_helpless_dead_or_heavy() -> void:
	var data := EnemyData.new()
	for state: StringName in [&"staggered", &"stunned", &"dead", &"freed"]:
		assert_false(EnemyBase.should_flinch(data, state, false, false), "no flinch while %s" % state)
	assert_false(EnemyBase.should_flinch(data, &"idle", false, true), "a kill doesn't flinch")
	data.flinch_frames = 0
	assert_false(EnemyBase.should_flinch(data, &"idle", false, false), "0 frames = never flinches")


func test_cut_passes_through_the_body_center() -> void:
	var origin := Vector2(40, 50)
	var cut := CorpsePiece.frame_cut(origin, Vector2(2, -10), Vector2(1, 0), 1)
	assert_eq(cut["point"], Vector2(42, 40))
	assert_eq(absf((cut["normal"] as Vector2).y), 1.0, "a horizontal swing cuts horizontally")


func test_cut_mirrors_for_left_facing_frames() -> void:
	var origin := Vector2(40, 50)
	var right := CorpsePiece.frame_cut(origin, Vector2(6, -10), Vector2(1, 1), 1)
	var left := CorpsePiece.frame_cut(origin, Vector2(-6, -10), Vector2(-1, 1), -1)
	assert_eq(left["point"], right["point"], "mirrored hit lands on the same frame pixel")
	assert_true((left["normal"] as Vector2).is_equal_approx(-(right["normal"] as Vector2)) \
		or (left["normal"] as Vector2).is_equal_approx(right["normal"] as Vector2), "same cut line")


func test_people_are_not_machines() -> void:
	var linked := load("res://enemies/linked_citizen/linked_citizen_data.tres") as EnemyData
	var hound := load("res://enemies/hound/hound_data.tres") as EnemyData
	assert_false(linked.is_machine, "the Linked are people: they collapse, never get cut up")
	assert_true(hound.is_machine)
