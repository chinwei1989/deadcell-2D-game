extends TestCase

var posture: PostureComponent


func before_each() -> void:
	posture = PostureComponent.new()
	posture.max_posture = 30.0
	posture.recovery_delay = 1.0
	posture.recovery_rate = 10.0
	posture.stagger_time = 2.0


func after_each() -> void:
	posture.free()


func test_full_posture_staggers() -> void:
	posture.add(20.0)
	assert_false(posture.is_staggered())
	posture.add(15.0)
	assert_true(posture.is_staggered())
	assert_near(posture.value, 30.0)


func test_no_posture_gain_while_staggered() -> void:
	posture.add(30.0)
	posture.add(10.0)
	assert_near(posture.value, 30.0)


func test_stagger_ends_and_resets() -> void:
	posture.add(30.0)
	posture.tick(2.1)
	assert_false(posture.is_staggered())
	assert_near(posture.value, 0.0)


func test_recovers_only_after_delay() -> void:
	posture.add(20.0)
	posture.tick(0.5)
	assert_near(posture.value, 20.0, 0.001, "still within recovery delay")
	posture.tick(0.5)
	posture.tick(1.0)
	assert_near(posture.value, 10.0, 0.001)
