class_name RngStreams
extends RefCounted
## Deterministic random number streams derived from one run seed (PLAN.md section 27.1).
## The same seed + stream name gives the same sequence on every platform, which co-op
## and daily runs rely on. Use separate streams per system (e.g. &"level", &"loot",
## &"enemies") so using one never shifts another. Visual-only effects should use their
## own local RandomNumberGenerator instead.

var run_seed: int
var _streams: Dictionary = {}


func _init(seed_value: int) -> void:
	run_seed = seed_value


func stream(stream_name: StringName) -> RandomNumberGenerator:
	if not _streams.has(stream_name):
		var rng := RandomNumberGenerator.new()
		rng.seed = derive_seed(run_seed, String(stream_name))
		_streams[stream_name] = rng
	return _streams[stream_name]


## 32-bit FNV-1a over "<seed>:<salt>". Fixed algorithm (not hash()) so values never
## change between Godot versions or platforms.
static func derive_seed(base_seed: int, salt: String) -> int:
	var h := 2166136261
	for byte in (str(base_seed) + ":" + salt).to_utf8_buffer():
		h = ((h ^ byte) * 16777619) & 0xFFFFFFFF
	return h
