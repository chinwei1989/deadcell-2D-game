extends TestCase
## Level dressing must never draw over solid tiles and must look the same every run.

const ROWS: PackedStringArray = [
	"##########################################",
	"#                                        #",
	"#                                        #",
	"#        ####                            #",
	"#                                        #",
	"##########################################",
]


func test_back_wall_skips_solid_tiles() -> void:
	var layer := LevelDressing.build_back_wall(ROWS, Vector2i(ROWS[0].length(), ROWS.size()))
	for cell in layer.get_used_cells():
		assert_true(ROWS[cell.y][cell.x] != "#", "facade over solid at %s" % cell)
	layer.free()


func test_back_wall_is_deterministic() -> void:
	var size := Vector2i(ROWS[0].length(), ROWS.size())
	var a := LevelDressing.build_back_wall(ROWS, size)
	var b := LevelDressing.build_back_wall(ROWS, size)
	assert_eq(a.get_used_cells(), b.get_used_cells())
	a.free()
	b.free()


func test_props_stand_on_floors() -> void:
	var parent := Node2D.new()
	LevelDressing.place_props(ROWS, parent)
	for child in parent.get_children():
		var sprite := child as Sprite2D
		var feet := sprite.position + Vector2(sprite.texture.get_width() / 2.0, sprite.texture.get_height())
		var below := Vector2i(int(feet.x / LevelDressing.TILE), int(feet.y / LevelDressing.TILE))
		assert_true(ROWS[below.y][below.x] == "#", "prop at %s stands on solid ground" % sprite.position)
	parent.free()
