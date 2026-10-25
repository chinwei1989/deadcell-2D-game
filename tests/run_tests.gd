extends SceneTree
## Headless unit test runner. Runs every "test_" method in res://tests/unit/test_*.gd.
## Exits with code 1 if any test fails.
##
## Run: godot --headless --path . -s res://tests/run_tests.gd

const TEST_DIR := "res://tests/unit"


func _initialize() -> void:
	var total := 0
	var failed := 0
	for path in _test_files():
		var script := load(path) as GDScript
		if script == null:
			print("  FAIL ", path, " (could not load script)")
			failed += 1
			continue
		for method: Dictionary in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			total += 1
			var suite: TestCase = script.new()
			suite.before_each()
			suite.call(method_name)
			suite.after_each()
			if suite.failures.is_empty():
				print("  PASS ", path.get_file(), " :: ", method_name)
			else:
				failed += 1
				print("  FAIL ", path.get_file(), " :: ", method_name)
				for failure in suite.failures:
					print("        ", failure)
	print("\n%d tests, %d failed" % [total, failed])
	quit(1 if failed > 0 else 0)


func _test_files() -> PackedStringArray:
	var files := PackedStringArray()
	for file in DirAccess.get_files_at(TEST_DIR):
		if file.begins_with("test_") and file.ends_with(".gd"):
			files.append(TEST_DIR.path_join(file))
	files.sort()
	return files
