extends TestCase

const DIR := "user://test_saves"
const PATH := DIR + "/profile.json"


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	_clean()


func after_each() -> void:
	_clean()


func test_write_then_read_roundtrip() -> void:
	assert_eq(JsonStore.write(PATH, {"memory_shards": 12}), OK)
	assert_eq(int(JsonStore.read(PATH).get("memory_shards", -1)), 12)


## Godot prints a "Parse JSON failed" error during this test. That's expected.
func test_falls_back_to_backup_when_main_file_is_corrupt() -> void:
	JsonStore.write(PATH, {"memory_shards": 1})
	JsonStore.write(PATH, {"memory_shards": 2}) # First version becomes the backup.
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("{ not json")
	file.close()
	assert_eq(int(JsonStore.read(PATH).get("memory_shards", -1)), 1)


func test_missing_file_reads_empty() -> void:
	assert_true(JsonStore.read(DIR + "/missing.json").is_empty())


func test_migrate_fills_missing_keys_and_keeps_values() -> void:
	var old := {"save_version": 0, "memory_shards": 55, "mercy": {"freed_total": 9}}
	var migrated := ProfileSchema.migrate(old)
	assert_eq(int(migrated["save_version"]), ProfileSchema.VERSION)
	assert_eq(int(migrated["memory_shards"]), 55)
	assert_eq(int(migrated["mercy"]["freed_total"]), 9)
	assert_eq(int(migrated["mercy"]["executed_total"]), 0, "new nested key gets its default")
	assert_true(migrated.has("story_flags"))


func _clean() -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
