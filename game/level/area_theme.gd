class_name AreaTheme
extends Resource
## Look, sound and rooms of one area of a run (PLAN.md section 29). Each area has its own
## .tres in game/run/areas/. Rooms are ASCII maps using the Level legend.

@export var display_name: String = "NEON SLUMS"
## Shown under the name on the area title card.
@export var subtitle: String = ""
## World canvas light between the level lights (darker = moodier).
@export var ambient: Color = Color(0.5, 0.56, 0.68)
@export var backdrop_tint: Color = Color.WHITE
@export var terrain_tint: Color = Color.WHITE
@export var rain_amount: int = 120
## Building rooftops behind the level, in tiles from the top of the map (min, max).
@export var roof_range: Vector2i = Vector2i(12, 30)
@export_file("*.wav") var music: String = "res://audio/music/neon_rain.wav"
## Room maps by name: "slums/market_alley" is res://game/run/rooms/slums/market_alley.txt.
## (Names, not res:// paths: exports drop res:// strings that point at non-resource files.)
## A run picks rooms_per_run of them.
@export var rooms: PackedStringArray = []
@export var rooms_per_run: int = 3
## Map letters a '?' marker can become (feet enemies: H Hound, L Linked Citizen).
@export var random_enemies: PackedStringArray = ["H"]

const ROOMS_DIR := "res://game/run/rooms/"


## The map file for a room name.
static func room_path(room_name: String) -> String:
	return ROOMS_DIR + room_name + ".txt"
