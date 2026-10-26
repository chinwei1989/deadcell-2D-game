extends TestCase
## Checks the sandbox map file so hand edits can't break the arena or the demo scenarios.

const MAP_PATH := "res://game/arena/maps/sandbox.txt"
const DemoDriver := preload("res://dev/demo_driver.gd")

var rows: PackedStringArray


func before_each() -> void:
	rows = FileAccess.get_file_as_string(MAP_PATH).split("\n", false)


func test_rows_are_rectangular() -> void:
	assert_true(rows.size() > 0, "map has rows")
	for i in rows.size():
		assert_eq(rows[i].length(), rows[0].length(), "row %d width" % i)


func test_border_is_closed() -> void:
	var last := rows.size() - 1
	for x in rows[0].length():
		assert_eq(rows[0][x], "#", "top border at x %d" % x)
		assert_eq(rows[last][x], "#", "bottom border at x %d" % x)
	for y in rows.size():
		assert_eq(rows[y][0], "#", "left border at y %d" % y)
		assert_eq(rows[y][rows[y].length() - 1], "#", "right border at y %d" % y)


func test_has_exactly_one_player_spawn() -> void:
	assert_eq(_count("P"), 1)


func test_demo_markers_exist() -> void:
	for scenario: String in DemoDriver.STARTS:
		var character := String(DemoDriver.STARTS[scenario])
		assert_eq(_count(character), 1, "marker '%s' for the %s scenario" % [character, scenario])


func test_ground_markers_stand_on_something() -> void:
	# Feet markers need a solid or one-way tile directly below them.
	for y in rows.size() - 1:
		for x in rows[y].length():
			var c := rows[y][x]
			if c == "P" or c == "D" or c == "H" or (c >= "a" and c <= "z"):
				assert_true(rows[y + 1][x] in ["#", "="], "'%s' at (%d, %d) has ground below" % [c, x, y])


func _count(character: String) -> int:
	var total := 0
	for row in rows:
		total += row.count(character)
	return total
