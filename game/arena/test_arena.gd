extends Node2D
## Gray-box test arena for tuning movement and combat. Geometry is built from tile
## rectangles below. Real rooms will be TileMapLayer scenes combined by the level
## generator (PLAN.md section 29).

const TILE := 16
const PLAYER_SCENE := preload("res://characters/player/player.tscn")
const DUMMY_SCENE := preload("res://enemies/training_dummy/training_dummy.tscn")
const DemoDriver := preload("res://dev/demo_driver.gd")

## Rect2i(x, y, width, height) in tiles.
const SOLID: Array[Rect2i] = [
	Rect2i(0, 20, 80, 3), # Floor
	Rect2i(0, 0, 1, 20), # Left wall
	Rect2i(79, 0, 1, 20), # Right wall
	Rect2i(45, 17, 4, 3), # Steps
	Rect2i(49, 14, 4, 6),
	Rect2i(60, 5, 2, 15), # Wall-jump column
]
const ONE_WAY: Array[Rect2i] = [
	Rect2i(10, 15, 6, 1),
	Rect2i(20, 12, 6, 1),
	Rect2i(30, 9, 6, 1),
	Rect2i(66, 12, 6, 1),
]
const SPIKES: Array[Rect2i] = [Rect2i(54, 19, 4, 1)]
## Tile positions of the dummies' feet.
const DUMMIES: Array[Vector2i] = [Vector2i(18, 20), Vector2i(38, 20), Vector2i(72, 20)]
const PLAYER_SPAWN := Vector2i(4, 20)
const ARENA_SIZE := Vector2i(80, 23)

const SOLID_COLOR := Color("1f3a44")
const ONE_WAY_COLOR := Color("2d5560")
const EDGE_COLOR := Color("4fd1c5")

@onready var _camera: CameraRig = $CameraRig
@onready var _hud: Hud = $Hud


func _ready() -> void:
	RunState.start_run()
	for rect in SOLID:
		_add_block(rect, false)
	for rect in ONE_WAY:
		_add_block(rect, true)
	for rect in SPIKES:
		var spikes := Spikes.new()
		spikes.position = Vector2(rect.position * TILE)
		spikes.size = Vector2(rect.size * TILE)
		add_child(spikes)
	for cell in DUMMIES:
		var dummy := DUMMY_SCENE.instantiate() as Node2D
		dummy.position = Vector2(cell * TILE)
		add_child(dummy)

	var player := PLAYER_SCENE.instantiate() as Player
	player.position = Vector2(PLAYER_SPAWN * TILE) + Vector2(TILE / 2.0, -22.0)
	add_child(player)

	_camera.target = player
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = ARENA_SIZE.x * TILE
	_camera.limit_bottom = ARENA_SIZE.y * TILE
	_camera.snap_to_target()
	_hud.bind_player(player)

	if "--demo" in OS.get_cmdline_user_args():
		add_child(DemoDriver.new())


func _add_block(tiles: Rect2i, one_way: bool) -> void:
	var rect := Rect2(Vector2(tiles.position * TILE), Vector2(tiles.size * TILE))
	var body := StaticBody2D.new()
	body.collision_layer = Layers.ONE_WAY if one_way else Layers.WORLD
	body.collision_mask = 0

	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.position = rect.get_center()
	shape.one_way_collision = one_way
	body.add_child(shape)

	var fill := Polygon2D.new()
	fill.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	fill.color = ONE_WAY_COLOR if one_way else SOLID_COLOR
	body.add_child(fill)

	var edge := Line2D.new()
	edge.points = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y)])
	edge.width = 1.0
	edge.default_color = EDGE_COLOR
	body.add_child(edge)
	add_child(body)
