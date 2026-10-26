class_name AutoTile
## Picks terrain tiles from the sandbox tileset (art/tiles/sandbox_tiles.png) based on
## neighbouring map cells. The atlas layout is documented in
## tools/art/generate_sandbox_art.py and must stay in sync with it.

const N := 1
const E := 2
const S := 4
const W := 8
const ONE_WAY_LEFT := Vector2i(4, 1)
const ONE_WAY_MIDDLE := Vector2i(5, 1)
const ONE_WAY_RIGHT := Vector2i(6, 1)
const ONE_WAY_SINGLE := Vector2i(7, 1)
const SPIKES := Vector2i(8, 1)


## Bit mask of solid neighbours (N=1, E=2, S=4, W=8). Outside the map counts as solid.
static func solid_mask(rows: PackedStringArray, x: int, y: int) -> int:
	var mask := 0
	if _solid(rows, x, y - 1):
		mask |= N
	if _solid(rows, x + 1, y):
		mask |= E
	if _solid(rows, x, y + 1):
		mask |= S
	if _solid(rows, x - 1, y):
		mask |= W
	return mask


## Atlas coordinates for a solid cell. Fully surrounded cells get a detail variant
## chosen deterministically from the cell position (same look every run).
static func solid_tile(rows: PackedStringArray, x: int, y: int) -> Vector2i:
	var mask := solid_mask(rows, x, y)
	if mask != N | E | S | W:
		return Vector2i(mask, 0)
	var roll := RngStreams.derive_seed(x * 7919 + y, "tile") % 100
	var variant := 0 if roll < 70 else (1 if roll < 85 else (2 if roll < 95 else 3))
	return Vector2i(variant, 1)


static func one_way_tile(rows: PackedStringArray, x: int, y: int) -> Vector2i:
	var left := _cell(rows, x - 1, y) != "="
	var right := _cell(rows, x + 1, y) != "="
	if left and right:
		return ONE_WAY_SINGLE
	if left:
		return ONE_WAY_LEFT
	if right:
		return ONE_WAY_RIGHT
	return ONE_WAY_MIDDLE


static func _solid(rows: PackedStringArray, x: int, y: int) -> bool:
	if y < 0 or y >= rows.size() or x < 0 or x >= rows[y].length():
		return true
	return rows[y][x] == "#"


static func _cell(rows: PackedStringArray, x: int, y: int) -> String:
	if y < 0 or y >= rows.size() or x < 0 or x >= rows[y].length():
		return "#"
	return rows[y][x]
