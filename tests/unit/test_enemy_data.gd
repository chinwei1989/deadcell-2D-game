extends TestCase
## Checks every enemy data file under res://enemies against the design rules.

## PLAN.md section 5.4: every enemy attack shows a wind-up of at least 18 frames.
const MIN_WINDUP_FRAMES := 18


func test_all_enemies_have_readable_windups() -> void:
	var files := _enemy_data_files("res://enemies")
	assert_true(files.size() >= 2, "found enemy data files")
	for path in files:
		var data := load(path) as EnemyData
		assert_true(data != null, "%s loads as EnemyData" % path)
		if data:
			assert_true(data.windup_frames >= MIN_WINDUP_FRAMES, "%s wind-up is %d frames" % [path, data.windup_frames])
			assert_true(data.max_health > 0.0, "%s has health" % path)


func test_frame_time_conversion() -> void:
	assert_near(FrameTime.seconds(60), 1.0)
	assert_near(FrameTime.seconds(6), 0.1)


func _enemy_data_files(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub in DirAccess.get_directories_at(dir):
		found.append_array(_enemy_data_files(dir.path_join(sub)))
	for file in DirAccess.get_files_at(dir):
		if file.ends_with("_data.tres"):
			found.append(dir.path_join(file))
	return found
