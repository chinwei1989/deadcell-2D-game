class_name FrameTime
## Frame data is written in 60 fps frames (like fighting games) but must be measured
## in game time, not by counting physics ticks. During Focus slow motion Godot still runs
## 60 physics ticks per real second and only shrinks delta, so counted ticks would not
## slow down. Accumulate delta and compare against FrameTime.seconds(frames).

const FPS := 60.0
## Tolerance for float rounding when comparing accumulated time against frame counts.
const EPSILON := 0.0001


static func seconds(frames: int) -> float:
	return frames / FPS
