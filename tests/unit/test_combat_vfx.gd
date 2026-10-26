extends TestCase
## Sprite-sheet blade tracks and the sword trail's arc filling.

const RONIN := "res://art/sprites/ronin.png"


func test_ronin_sheet_tracks_the_blade_in_every_attack() -> void:
	for anim: StringName in [&"slash1", &"slash2", &"slash3", &"slash_up", &"slash_down", &"draw_strike", &"slam"]:
		var tips := SpriteSheet.track(RONIN, anim, &"blade_tip")
		var bases := SpriteSheet.track(RONIN, anim, &"blade_base")
		var frames := SpriteSheet.frames(RONIN).get_frame_count(anim)
		assert_eq(tips.size(), frames, "%s tip per frame" % anim)
		assert_eq(bases.size(), frames, "%s base per frame" % anim)


func test_missing_track_is_empty() -> void:
	assert_eq(SpriteSheet.track(RONIN, &"idle", &"nope").size(), 0)


func test_trail_fills_big_swings_with_an_arc() -> void:
	var trail := SwordTrail.new()
	trail.add_blade(Vector2.ZERO, Vector2(-30, 0)) # Blade pointing back...
	trail.add_blade(Vector2.ZERO, Vector2(30, 0)) # ...swung to the front in one frame.
	var samples: Array = trail.get("_samples")
	assert_eq(samples.size(), 1 + SwordTrail.ARC_STEPS, "arc steps inserted between poses")
	# Arc points stay at blade length from the base (a circle, not a straight line).
	for sample: Dictionary in samples:
		assert_near((sample["tip"] as Vector2).length(), 30.0, 0.5)
	trail.free()


func test_trail_stop_breaks_the_stroke() -> void:
	var trail := SwordTrail.new()
	trail.add_blade(Vector2.ZERO, Vector2(10, 0))
	trail.stop()
	trail.add_blade(Vector2.ZERO, Vector2(-10, 0))
	var samples: Array = trail.get("_samples")
	assert_eq(samples.size(), 2, "no arc across a stopped stroke")
	assert_true(bool(samples[1]["stroke_start"]))
	trail.free()


func test_fire_blade_follows_the_blade() -> void:
	var fire := FireBlade.new()
	for part in ["_flames", "_swing_fire", "_smoke", "_embers"]:
		fire.set(part, CPUParticles2D.new())
	fire.set("_light", PointLight2D.new())
	fire.set_blade(Vector2(10, 0), Vector2(40, 0))
	var flames: CPUParticles2D = fire.get("_flames")
	var swing: CPUParticles2D = fire.get("_swing_fire")
	assert_eq(flames.emission_points.size(), FireBlade.FLAME_POINTS)
	assert_true(flames.emitting)
	assert_false(swing.emitting, "swing fire only while attacking")
	fire.intensity = 1.0
	fire.set_blade(Vector2(10, 0), Vector2(40, 0))
	assert_true(swing.emitting)
	fire.hide_blade()
	assert_false(flames.emitting)
	for part in ["_flames", "_swing_fire", "_smoke", "_embers", "_light"]:
		(fire.get(part) as Node).free()
	fire.free()


func test_sprite_frames_show_their_own_region() -> void:
	# Regression: frames once got wrapped in CanvasTextures, which ignore atlas regions and
	# froze the hero on the first idle frame.
	var frames := SpriteSheet.frames(RONIN)
	var first := frames.get_frame_texture(&"run", 0) as AtlasTexture
	var later := frames.get_frame_texture(&"run", 5) as AtlasTexture
	assert_true(first != null and later != null, "frames are AtlasTextures")
	if first and later:
		assert_true(first.region != later.region, "each frame shows a different part of the sheet")
	assert_true(SpriteSheet.material(RONIN).get_shader_parameter(&"use_normals"), "normal map applied by the shader")


func test_attack_phases_map_to_frame_data() -> void:
	var durations: Array[float] = [0.1, 0.05, 0.2]
	var counts := PackedInt32Array([3, 3, 4])
	assert_eq(Player.phase_frame(0.0, durations, counts), 0)
	assert_eq(Player.phase_frame(0.099, durations, counts), 2, "last wind-up frame at the end of startup")
	assert_eq(Player.phase_frame(0.101, durations, counts), 3, "strike starts with the active frames")
	assert_eq(Player.phase_frame(0.149, durations, counts), 5)
	assert_eq(Player.phase_frame(0.16, durations, counts), 6, "recovery after the active frames")
	assert_eq(Player.phase_frame(5.0, durations, counts), 9, "holds the last frame")


func test_ronin_attacks_have_phases() -> void:
	for anim: StringName in [&"slash1", &"slash2", &"slash3", &"slash_up", &"slash_down"]:
		var counts := SpriteSheet.phases("res://art/sprites/ronin.png", anim)
		assert_eq(counts.size(), 3, "%s has wind-up/strike/recovery" % anim)
		var total := 0
		for c in counts:
			total += c
		assert_eq(total, SpriteSheet.frames("res://art/sprites/ronin.png").get_frame_count(anim), "%s phases cover every frame" % anim)
	SpriteSheet.clear_cache()
