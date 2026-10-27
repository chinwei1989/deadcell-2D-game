class_name LevelDressing
## Decorates a level built from an ASCII map (PLAN.md section 29.1): building facades behind
## the play space (with a rooftop skyline, so the city backdrop shows above), props standing
## on floors, and a foreground layer of dark silhouettes that pass in front of the camera.
## Purely visual: nothing here collides or affects gameplay. Art comes from
## tools/art/generate_level_art.py; the facade atlas layout is documented there.

const TILE := 16
const FACADE_TEXTURE := preload("res://art/tiles/facade_tiles.png")
const WALLS: Array[int] = [0, 1, 2, 3]
const WINDOW_DARK := 4
const WINDOW_WARM := 5
const WINDOW_COLD := 6
const WINDOW_BROKEN := 7
const VENT := 8
const PIPE := 9
const PIPE_JOINT := 10
const AC_UNIT := 11
const SIGN_TEAL := 12
const SIGN_RED := 13
const ROOF := 14
const ROOF_ANTENNA := 15
## Building rooftops are this many tiles from the top of the map (min, max); the default for
## the sandbox. Run rooms pass their AreaTheme's range.
const ROOF_RANGE := Vector2i(12, 30)
## Chance of an alley (a gap with no facade, showing the city behind) after a building.
const ALLEY_CHANCE := 0.4
const PROPS: Dictionary = {
	"crate": 4, "barrel": 3, "trash": 3, "cone": 2, "pipes": 2, "ac_box": 2, "terminal": 1, "vending": 1,
}
## Fraction of floor cells that get a prop.
const PROP_CHANCE := 0.11
const FOREGROUND: Array[String] = ["pillar", "cables", "girder", "railing"]


## A back-wall TileMapLayer: one building after another across the map width.
static func build_back_wall(rows: PackedStringArray, map_size: Vector2i, roof_range: Vector2i = ROOF_RANGE) -> TileMapLayer:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026 # Fixed: the same city every run (and for both co-op players).
	var layer := TileMapLayer.new()
	layer.name = "BackWall"
	layer.tile_set = _tileset()
	layer.z_index = -2
	var x := 0
	while x < map_size.x:
		var width := rng.randi_range(4, 9)
		var roof := rng.randi_range(roof_range.x, roof_range.y)
		var pipe_column := x + rng.randi_range(0, width - 1) if rng.randf() < 0.5 else -1
		var sign_row := rng.randi_range(roof + 3, map_size.y - 6) if rng.randf() < 0.35 else -1
		for bx in range(x, mini(x + width, map_size.x)):
			for y in range(roof, map_size.y):
				if _is_solid(rows, bx, y):
					continue
				var tile := _facade_tile(rng, bx - x, y - roof, bx == pipe_column, y == sign_row)
				if y == roof:
					tile = ROOF_ANTENNA if rng.randf() < 0.2 else ROOF
				layer.set_cell(Vector2i(bx, y), 0, Vector2i(tile, 0))
		x += width
		if rng.randf() < ALLEY_CHANCE:
			x += rng.randi_range(2, 5)
	return layer


## Props standing on floors and platforms, chosen deterministically per cell.
static func place_props(rows: PackedStringArray, parent: Node) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var textures := {}
	for prop: String in PROPS:
		textures[prop] = load("res://art/props/%s.png" % prop)
	for y in range(1, rows.size() - 1):
		for x in range(1, rows[y].length() - 1):
			if rows[y][x] != " " or not (rows[y + 1][x] in ["#", "="]):
				continue
			if rng.randf() > PROP_CHANCE:
				continue
			var prop := _weighted_prop(rng)
			if prop == "vending" and (rows[y - 1][x] != " " or rows[y + 1][x] != "#"):
				prop = "crate"
			var sprite := Sprite2D.new()
			sprite.texture = textures[prop]
			sprite.centered = false
			sprite.flip_h = rng.randf() < 0.5
			var size: Vector2 = sprite.texture.get_size()
			sprite.position = Vector2(x * TILE + (TILE - size.x) / 2.0 + rng.randf_range(-3.0, 3.0), (y + 1) * TILE - size.y)
			sprite.z_index = -1
			parent.add_child(sprite)


## Dark silhouettes in front of the play space that scroll faster than the world.
static func build_foreground(map_size: Vector2i) -> Parallax2D:
	var layer := Parallax2D.new()
	layer.name = "Foreground"
	layer.scroll_scale = Vector2(1.3, 1.1)
	layer.z_index = 30
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED # Always a black silhouette.
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var x := 220.0
	var bottom := map_size.y * TILE + 60.0
	while x < map_size.x * TILE * 1.3:
		var kind: String = FOREGROUND[rng.randi_range(0, FOREGROUND.size() - 1)]
		var sprite := Sprite2D.new()
		sprite.texture = load("res://art/foreground/%s.png" % kind)
		sprite.centered = false
		sprite.material = unshaded
		sprite.modulate = Color(1, 1, 1, 0.92)
		var size: Vector2 = sprite.texture.get_size()
		match kind:
			"cables":
				sprite.position = Vector2(x, rng.randf_range(40.0, map_size.y * TILE * 0.5))
			"railing":
				sprite.position = Vector2(x, bottom - size.y - rng.randf_range(0.0, 120.0))
			_:
				sprite.position = Vector2(x, bottom - size.y)
		layer.add_child(sprite)
		x += rng.randf_range(380.0, 620.0)
	return layer


static func _facade_tile(rng: RandomNumberGenerator, column: int, depth: int, pipe: bool, sign_row: bool) -> int:
	if pipe:
		return PIPE_JOINT if depth % 6 == 3 else PIPE
	if sign_row and column < 4:
		return SIGN_TEAL if rng.randf() < 0.6 else SIGN_RED
	if column % 3 == 1 and depth % 3 == 1 and depth > 1:
		var roll := rng.randf()
		if roll < 0.5:
			return WINDOW_DARK
		if roll < 0.7:
			return WINDOW_WARM
		if roll < 0.9:
			return WINDOW_COLD
		return WINDOW_BROKEN
	var detail := rng.randf()
	if detail < 0.04:
		return AC_UNIT
	if detail < 0.08:
		return VENT
	return WALLS[rng.randi_range(0, WALLS.size() - 1)]


static func _weighted_prop(rng: RandomNumberGenerator) -> String:
	var total := 0
	for weight: int in PROPS.values():
		total += weight
	var roll := rng.randi_range(1, total)
	for prop: String in PROPS:
		roll -= int(PROPS[prop])
		if roll <= 0:
			return prop
	return "crate"


static func _is_solid(rows: PackedStringArray, x: int, y: int) -> bool:
	return y < rows.size() and x < rows[y].length() and rows[y][x] == "#"


static func _tileset() -> TileSet:
	var source := TileSetAtlasSource.new()
	source.texture = FACADE_TEXTURE
	source.texture_region_size = Vector2i(TILE, TILE)
	for ax in FACADE_TEXTURE.get_width() / TILE:
		source.create_tile(Vector2i(ax, 0))
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE, TILE)
	tileset.add_source(source, 0)
	return tileset
