class_name TestArena
extends Node2D
## Gray-box sandbox level built from an ASCII map file, for tuning movement and combat
## across several levels (PLAN.md section 29.1). Real rooms will be TileMapLayer scenes
## combined by the level generator; the same legend can seed those later.
##
## Map legend (one character = one 16 px tile):
##   #  solid            =  one-way platform (jump up through, Down+Jump drops)
##   ^  spikes           P  player spawn (feet)        D  training dummy (feet)
##   H  Hound (feet)     R  Patrol Drone (center)   L  Linked Citizen (feet)
##   *  warm lamp        +  teal neon light            !  red warning light
##   a-z  named markers (e.g. demo scenario starts, feet); not spawned
## Anything else is empty space.
##
## Start with --overview (after --) to see the whole map zoomed out.

const TILE := 16
const MAP_PATH := "res://game/arena/maps/sandbox.txt"
const PLAYER_SCENE := preload("res://characters/player/player.tscn")
const DUMMY_SCENE := preload("res://enemies/training_dummy/training_dummy.tscn")
const HOUND_SCENE := preload("res://enemies/hound/hound.tscn")
const DRONE_SCENE := preload("res://enemies/patrol_drone/patrol_drone.tscn")
const LINKED_SCENE := preload("res://enemies/linked_citizen/linked_citizen.tscn")
const DemoDriver := preload("res://dev/demo_driver.gd")
const TILES_TEXTURE := preload("res://art/tiles/sandbox_tiles.png")
## Ambient light for the world canvas: dim and cool, so level lights make pools of color.
const AMBIENT := Color(0.5, 0.56, 0.68)
const LIGHT_KINDS: Dictionary = {"*": LevelLight.Kind.WARM, "+": LevelLight.Kind.NEON, "!": LevelLight.Kind.WARNING}

## Size of the map in tiles.
var map_size: Vector2i = Vector2i.ZERO
## Marker character → list of positions (pixels). Feet position for ground markers.
var markers: Dictionary = {}

@onready var _camera: CameraRig = $CameraRig
@onready var _hud: Hud = $Hud


func _ready() -> void:
	add_to_group(&"arena")
	RunState.start_run()
	var rows := _load_map(MAP_PATH)
	_build_backdrop()
	_build_glow()
	add_child(Atmosphere.new())
	var ambient := CanvasModulate.new()
	ambient.color = AMBIENT # The level is dark between its lights.
	add_child(ambient)
	Audio.play_music("res://audio/music/neon_rain.wav")
	Audio.play_ambience("res://audio/sfx/rain_loop.wav")
	add_child(LevelDressing.build_back_wall(rows, map_size))
	_build_tiles(rows)
	_build_terrain(rows)
	LevelDressing.place_props(rows, self)
	add_child(LevelDressing.build_foreground(map_size))
	_spawn_entities()

	var player := PLAYER_SCENE.instantiate() as Player
	player.position = marker(&"P") + Vector2(0.0, -Player.HALF_HEIGHT)
	add_child(player)

	_camera.target = player
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = map_size.x * TILE
	_camera.limit_bottom = map_size.y * TILE
	_camera.snap_to_target()
	_hud.bind_player(player)

	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--demo"):
			add_child(DemoDriver.new(arg.get_slice("=", 1) if "=" in arg else "combo"))
		elif arg == "--overview":
			_camera.show_overview(Rect2(Vector2.ZERO, Vector2(map_size * TILE)))


## First position of a marker character, in pixels (feet for ground markers).
func marker(character: StringName) -> Vector2:
	var positions: Array = markers.get(character, [])
	assert(not positions.is_empty(), "Map has no '%s' marker" % character)
	return positions[0]


func _load_map(path: String) -> PackedStringArray:
	var rows := FileAccess.get_file_as_string(path).split("\n", false)
	var width := 0
	for row in rows:
		width = maxi(width, row.length())
	map_size = Vector2i(width, rows.size())
	return rows


func _build_terrain(rows: PackedStringArray) -> void:
	for y in rows.size():
		var row := rows[y]
		var x := 0
		while x < row.length():
			var tile := row[x]
			var run := 1
			while x + run < row.length() and row[x + run] == tile:
				run += 1
			match tile:
				"#":
					_add_block(Rect2i(x, y, run, 1), false)
				"=":
					_add_block(Rect2i(x, y, run, 1), true)
				"*", "+", "!":
					for i in run:
						_add_light(tile, Vector2i(x + i, y))
				"^":
					var spikes := Spikes.new()
					spikes.position = Vector2(x * TILE, y * TILE)
					spikes.size = Vector2(run * TILE, TILE)
					spikes.draw_visual = false
					add_child(spikes)
				_:
					if tile != " ":
						for i in run:
							_add_marker(tile, Vector2i(x + i, y))
			x += run


func _add_light(character: String, cell: Vector2i) -> void:
	var light := LevelLight.new()
	light.kind = LIGHT_KINDS[character]
	light.position = Vector2(cell * TILE) + Vector2(TILE / 2.0, 2.0)
	add_child(light)


func _add_marker(character: String, cell: Vector2i) -> void:
	# Ground markers sit on the bottom edge of their cell; drones float in its center.
	var offset := Vector2(TILE / 2.0, TILE / 2.0 if character == "R" else float(TILE))
	var list: Array = markers.get(StringName(character), [])
	list.append(Vector2(cell * TILE) + offset)
	markers[StringName(character)] = list


func _spawn_entities() -> void:
	var scenes := {&"D": DUMMY_SCENE, &"H": HOUND_SCENE, &"R": DRONE_SCENE, &"L": LINKED_SCENE}
	for character: StringName in scenes:
		for at: Vector2 in markers.get(character, []):
			var node := (scenes[character] as PackedScene).instantiate() as Node2D
			node.position = at
			add_child(node, true)


## Collision for one horizontal run of solid or one-way tiles (visuals come from tiles).
func _add_block(tiles: Rect2i, one_way: bool) -> void:
	var rect := Rect2(Vector2(tiles.position * TILE), Vector2(tiles.size * TILE))
	var body := StaticBody2D.new()
	body.collision_layer = Layers.ONE_WAY if one_way else Layers.WORLD
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(rect.size.x, 4.0) if one_way else rect.size
	shape.shape = box
	shape.position = Vector2(rect.get_center().x, rect.position.y + box.size.y / 2.0)
	shape.one_way_collision = one_way
	body.add_child(shape)
	add_child(body)


## Bloom: bright effects (slashes, sparks, neon) glow like in a lit pixel-art game.
func _build_glow() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CANVAS
	environment.glow_enabled = true
	environment.glow_intensity = 0.35
	environment.glow_strength = 0.8
	environment.glow_bloom = 0.0
	environment.glow_hdr_threshold = 1.25
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	environment.adjustment_enabled = true # Light color grading: a touch more contrast and color.
	environment.adjustment_contrast = 1.08
	environment.adjustment_saturation = 1.12
	for level in 7:
		environment.set_glow_level(level, level in [1, 2, 3])
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)


func _build_backdrop() -> void:
	var backdrop := ParallaxBackdrop.new()
	backdrop.reference_y = map_size.y * TILE / 2.0
	add_child(backdrop)


## Draws the map with the generated tileset; AutoTile picks edges, corners and variants.
func _build_tiles(rows: PackedStringArray) -> void:
	var source := TileSetAtlasSource.new()
	source.texture = TILES_TEXTURE
	source.texture_region_size = Vector2i(TILE, TILE)
	var atlas_size := Vector2i(TILES_TEXTURE.get_width() / TILE, TILES_TEXTURE.get_height() / TILE)
	for ay in atlas_size.y:
		for ax in atlas_size.x:
			source.create_tile(Vector2i(ax, ay))
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE, TILE)
	tileset.add_source(source, 0)

	var layer := TileMapLayer.new()
	layer.name = "Terrain"
	layer.tile_set = tileset
	for y in rows.size():
		for x in rows[y].length():
			match rows[y][x]:
				"#":
					layer.set_cell(Vector2i(x, y), 0, AutoTile.solid_tile(rows, x, y))
				"=":
					layer.set_cell(Vector2i(x, y), 0, AutoTile.one_way_tile(rows, x, y))
				"^":
					layer.set_cell(Vector2i(x, y), 0, AutoTile.SPIKES)
	add_child(layer)
