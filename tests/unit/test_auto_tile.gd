extends TestCase

const ROWS: PackedStringArray = [
	"#####",
	"#   #",
	"# ==#",
	"#####",
]


func test_corner_mask_counts_outside_as_solid() -> void:
	# Top-left corner: map edge to the N and W, solid E and S.
	assert_eq(AutoTile.solid_mask(ROWS, 0, 0), AutoTile.N | AutoTile.E | AutoTile.S | AutoTile.W)


func test_floor_tile_has_open_top() -> void:
	# Bottom row cell under empty space: everything solid except north.
	assert_eq(AutoTile.solid_mask(ROWS, 1, 3), AutoTile.E | AutoTile.S | AutoTile.W)
	assert_eq(AutoTile.solid_tile(ROWS, 1, 3), Vector2i(AutoTile.E | AutoTile.S | AutoTile.W, 0))


func test_surrounded_tile_uses_a_stable_variant() -> void:
	var first := AutoTile.solid_tile(ROWS, 0, 0)
	assert_eq(first.y, 1, "interior variants are on row 1")
	assert_true(first.x >= 0 and first.x <= 3)
	assert_eq(AutoTile.solid_tile(ROWS, 0, 0), first, "same cell, same variant")


func test_one_way_caps() -> void:
	assert_eq(AutoTile.one_way_tile(ROWS, 2, 2), AutoTile.ONE_WAY_LEFT)
	assert_eq(AutoTile.one_way_tile(ROWS, 3, 2), AutoTile.ONE_WAY_RIGHT)
	assert_eq(AutoTile.one_way_tile(PackedStringArray([" = "]), 1, 0), AutoTile.ONE_WAY_SINGLE)
	assert_eq(AutoTile.one_way_tile(PackedStringArray(["==="]), 1, 0), AutoTile.ONE_WAY_MIDDLE)
