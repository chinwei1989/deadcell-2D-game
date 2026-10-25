extends Node
## First scene. Autoloads (settings, profile) are ready by now; go to the first screen.
## Until the title screen exists, this opens the test arena.


func _ready() -> void:
	Game.goto(&"test_arena", Game.Mode.IN_RUN)
