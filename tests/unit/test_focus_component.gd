extends TestCase

var focus: FocusComponent
var activations: int = 0
var deactivations: int = 0


func before_each() -> void:
	focus = FocusComponent.new()
	focus.max_seconds = 3.0
	focus.min_to_activate = 0.25
	focus.reset()
	focus.activated.connect(func() -> void: activations += 1)
	focus.deactivated.connect(func() -> void: deactivations += 1)


func after_each() -> void:
	focus.free()


func test_toggle_starts_and_stops() -> void:
	focus.toggle()
	assert_true(focus.active)
	focus.toggle()
	assert_false(focus.active)
	assert_eq(activations, 1)
	assert_eq(deactivations, 1)


func test_drains_and_stops_when_empty() -> void:
	focus.toggle()
	focus.tick(1.0)
	assert_near(focus.seconds, 2.0)
	focus.tick(5.0)
	assert_near(focus.seconds, 0.0)
	assert_false(focus.active)


func test_needs_minimum_meter_to_start() -> void:
	focus.toggle()
	focus.tick(2.9)
	focus.toggle() # Stop with 0.1 s left.
	focus.toggle() # Not enough to restart.
	assert_false(focus.active)


func test_refill_is_capped() -> void:
	focus.toggle()
	focus.tick(2.0)
	focus.refill(10.0)
	assert_near(focus.seconds, 3.0)


func test_no_drain_while_inactive() -> void:
	focus.tick(2.0)
	assert_near(focus.seconds, 3.0)
