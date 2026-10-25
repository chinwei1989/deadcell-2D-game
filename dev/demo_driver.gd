extends Node
## Presses input actions on a fixed timeline so a run can be recorded without a person
## (scripted playtests, PLAN.md section 34). Enabled by the test arena with the user
## argument --demo, e.g. to record frames with Movie Maker mode:
##   godot --path . --write-movie /tmp/frames/frame.png --fixed-fps 60 --quit-after 330 -- --demo

## [time in seconds, action, pressed]
const TIMELINE: Array[Array] = [
	[0.2, &"move_right", true],
	[0.9, &"jump", true],
	[1.1, &"jump", false],
	[2.75, &"move_right", false],
	[2.85, &"slash", true], [2.9, &"slash", false],
	[3.1, &"slash", true], [3.15, &"slash", false],
	[3.35, &"slash", true], [3.4, &"slash", false],
	[4.0, &"dodge", true], [4.05, &"dodge", false],
	[4.4, &"move_up", true],
	[4.4, &"slash", true], [4.45, &"slash", false],
	[4.7, &"move_up", false],
]

var _time: float = 0.0
var _next: int = 0


func _physics_process(delta: float) -> void:
	_time += delta
	while _next < TIMELINE.size() and _time >= float(TIMELINE[_next][0]):
		var step: Array = TIMELINE[_next]
		if step[2]:
			Input.action_press(step[1])
		else:
			Input.action_release(step[1])
		_next += 1
