class_name Level
extends Node2D
## A playable room built from an ASCII map (PLAN.md section 29.1) and an AreaTheme: terrain
## with auto-tiles, lights, facades, props, foreground, backdrop, enemies and the player.
## Used for run rooms (Run sets `rows` and `theme` before adding it) and, through TestArena,
## for the sandbox.
##
## Map legend (one character = one 16 px tile):
##   #  solid            =  one-way platform (jump up through, Down+Jump drops)
##   ^  spikes           P  player spawn (feet)        D  training dummy (feet)
##   H  Hound (feet)     R  Patrol Drone (center)   L  Linked Citizen (feet)
##   ?  random enemy from the area's pool (feet)     W  the Warden (feet)
##   >  exit door (feet): opens once every enemy is dead or freed
##   *  warm lamp        +  teal neon light            !  red warning light
##   a-z  named markers (e.g. demo scenario starts, feet); not spawned
## Anything else is empty space.

## The player walked through the open exit door.
signal exit_reached
## Every enemy in the room is dead or freed (the exit opens).
signal cleared
signal player_died

const TILE := 16
const PLAYER_SCENE := preload("res://characters/player/player.tscn")
const DUMMY_SCENE := preload("res://enemies/training_dummy/training_dummy.tscn")
const HOUND_SCENE := preload("res://enemies/hound/hound.tscn")
const DRONE_SCENE := preload("res://enemies/patrol_drone/patrol_drone.tscn")
const LINKED_SCENE := preload("res://enemies/linked_citizen/linked_citizen.tscn")
const WARDEN_SCENE := preload("res://enemies/warden/warden.tscn")
const TILES_TEXTURE := preload("res://art/tiles/sandbox_tiles.png")
const DEFAULT_THEME := preload("res://game/run/areas/neon_slums.tres")
const LIGHT_KINDS: Dictionary = {"*": LevelLight.Kind.WARM, "+": LevelLight.Kind.NEON, "!": LevelLight.Kind.WARNING}

## The map, one string per row. Set before the level enters the tree (or set map_path).
var rows: PackedStringArray = []
var map_path: String = ""
var theme: AreaTheme = DEFAULT_THEME
## Size of the map in tiles.
var map_size: Vector2i = Vector2i.ZERO
## Marker character → list of positions (pixels). Feet position for ground markers.
var markers: Dictionary = {}
var player: Player
var exit_door: ExitDoor

var _cleared: bool = false

@onready var camera: CameraRig = $CameraRig
@onready var hud: Hud = $Hud


func _ready() -> void:
	add_to_group(&"arena")
	if rows.is_empty():
		rows = load_map(map_path)
	map_size = measure(rows)
	_build_backdrop()
	_build_glow()
	add_child(Atmosphere.new())
	var ambient := CanvasModulate.new()
	ambient.color = theme.ambient # The level is dark between its lights.
	add_child(ambient)
	Audio.play_music(theme.music)
	Audio.play_ambience("res://audio/sfx/rain_loop.wav")
	add_child(LevelDressing.build_back_wall(rows, map_size, theme.roof_range))
	_build_tiles(rows)
	_build_terrain(rows)
	LevelDressing.place_props(rows, self)
	add_child(LevelDressing.build_foreground(map_size))
	_spawn_entities()

	player = PLAYER_SCENE.instantiate() as Player
	player.position = marker(&"P") + Vector2(0.0, -Player.HALF_HEIGHT)
	add_child(player)
	player.died.connect(player_died.emit)
	player.combo_changed.connect(RunState.note_combo)

	camera.target = player
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = map_size.x * TILE
	camera.limit_bottom = map_size.y * TILE
	camera.snap_to_target()
	hud.bind_player(player)
	var warden := get_tree().get_first_node_in_group(&"bosses") as EnemyBase
	if warden:
		hud.bind_boss(warden)


func _physics_process(_delta: float) -> void:
	if _cleared or not is_inside_tree():
		return
	if get_tree().get_nodes_in_group(&"enemies").is_empty():
		_cleared = true
		if exit_door:
			exit_door.open()
		cleared.emit()


## First position of a marker character, in pixels (feet for ground markers).
func marker(character: StringName) -> Vector2:
	var positions: Array = markers.get(character, [])
	assert(not positions.is_empty(), "Map has no '%s' marker" % character)
	return positions[0]


static func load_map(path: String) -> PackedStringArray:
	return FileAccess.get_file_as_string(path).split("\n", false)


static func measure(map_rows: PackedStringArray) -> Vector2i:
	var width := 0
	for row in map_rows:
		width = maxi(width, row.length())
	return Vector2i(width, map_rows.size())


func _build_terrain(map_rows: PackedStringArray) -> void:
	for y in map_rows.size():
		var row := map_rows[y]
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
	var scenes := {&"D": DUMMY_SCENE, &"H": HOUND_SCENE, &"R": DRONE_SCENE, &"L": LINKED_SCENE, &"W": WARDEN_SCENE}
	for character: StringName in scenes:
		for at: Vector2 in markers.get(character, []):
			_spawn(scenes[character], at)
	var pool := theme.random_enemies
	if not pool.is_empty():
		var rng := RunState.rng.stream(&"room_enemies")
		for at: Vector2 in markers.get(&"?", []):
			var letter := StringName(pool[rng.randi_range(0, pool.size() - 1)])
			_spawn(scenes.get(letter, HOUND_SCENE), at)
	for at: Vector2 in markers.get(&">", []):
		exit_door = ExitDoor.new()
		exit_door.position = at
		exit_door.entered.connect(exit_reached.emit)
		add_child(exit_door)


func _spawn(scene: PackedScene, at: Vector2) -> void:
	var node := scene.instantiate() as Node2D
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


func _build_glow() -> void:
	add_child(make_glow())


## Bloom: bright effects (slashes, sparks, neon) glow like in a lit pixel-art game.
static func make_glow() -> WorldEnvironment:
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
	return world


func _build_backdrop() -> void:
	var backdrop := ParallaxBackdrop.new()
	backdrop.reference_y = map_size.y * TILE / 2.0
	backdrop.tint = theme.backdrop_tint
	backdrop.rain_amount = theme.rain_amount
	add_child(backdrop)


## Draws the map with the generated tileset; AutoTile picks edges, corners and variants.
func _build_tiles(map_rows: PackedStringArray) -> void:
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
	layer.modulate = theme.terrain_tint
	for y in map_rows.size():
		for x in map_rows[y].length():
			match map_rows[y][x]:
				"#":
					layer.set_cell(Vector2i(x, y), 0, AutoTile.solid_tile(map_rows, x, y))
				"=":
					layer.set_cell(Vector2i(x, y), 0, AutoTile.one_way_tile(map_rows, x, y))
				"^":
					layer.set_cell(Vector2i(x, y), 0, AutoTile.SPIKES)
	add_child(layer)
