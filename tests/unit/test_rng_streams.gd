extends TestCase


func test_same_seed_gives_same_sequence() -> void:
	var a := RngStreams.new(1234).stream(&"level")
	var b := RngStreams.new(1234).stream(&"level")
	for i in 20:
		assert_eq(a.randi(), b.randi(), "value %d" % i)


func test_streams_are_independent() -> void:
	var streams := RngStreams.new(1234)
	streams.stream(&"loot").randi() # Using another stream must not shift "level".
	var level_value := streams.stream(&"level").randi()
	assert_eq(level_value, RngStreams.new(1234).stream(&"level").randi())
	assert_true(RngStreams.derive_seed(1234, "level") != RngStreams.derive_seed(1234, "loot"))


func test_derive_seed_is_stable() -> void:
	# Locked value. If this changes, daily-run seeds and co-op level sync break.
	assert_eq(RngStreams.derive_seed(42, "level"), 3620016219)
