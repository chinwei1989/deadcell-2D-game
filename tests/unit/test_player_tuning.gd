extends TestCase

const RONIN := preload("res://characters/ronin/ronin_tuning.tres")


func test_jump_reaches_tuned_heights() -> void:
	var t: PlayerTuning = RONIN
	# Peak height of v^2 / (2g) must equal the tuned height.
	assert_near(pow(t.jump_velocity(), 2) / (2.0 * t.gravity_up), t.jump_height, 0.01)
	assert_near(pow(t.min_jump_velocity(), 2) / (2.0 * t.gravity_up), t.min_jump_height, 0.01)
	assert_true(t.min_jump_velocity() < t.jump_velocity(), "tap jump is lower than held jump")


func test_combo_arrays_have_matching_lengths() -> void:
	var t: PlayerTuning = RONIN
	var n := t.combo_length()
	assert_true(n > 0)
	for values: Array in [t.slash_posture, t.slash_startup_frames, t.slash_active_frames, t.slash_recovery_frames, t.slash_hit_freeze, t.slash_knockback]:
		assert_eq(values.size(), n)


func test_dodge_iframes_fit_inside_dodge() -> void:
	var t: PlayerTuning = RONIN
	assert_true(t.dodge_iframe_start < t.dodge_iframe_end)
	assert_true(t.dodge_iframe_end <= t.dodge_duration)
