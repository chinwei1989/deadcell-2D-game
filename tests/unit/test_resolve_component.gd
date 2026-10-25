extends TestCase

var resolve: ResolveComponent


func before_each() -> void:
	resolve = ResolveComponent.new()
	resolve.max_pips = 4.0
	resolve.invulnerability_time = 0.8
	resolve.reset()


func after_each() -> void:
	resolve.free()


func test_hit_costs_a_pip_and_grants_invulnerability() -> void:
	assert_eq(resolve.take_hit(), ResolveComponent.HitResult.HURT)
	assert_near(resolve.pips, 3.0)
	assert_true(resolve.is_invulnerable())
	assert_eq(resolve.take_hit(), ResolveComponent.HitResult.IGNORED, "second hit during invulnerability")
	assert_near(resolve.pips, 3.0)


func test_invulnerability_wears_off() -> void:
	resolve.take_hit()
	resolve.tick(0.81)
	assert_false(resolve.is_invulnerable())


func test_hit_at_zero_pips_kills() -> void:
	resolve.max_pips = 1.0
	resolve.reset()
	assert_eq(resolve.take_hit(), ResolveComponent.HitResult.HURT)
	assert_near(resolve.pips, 0.0)
	resolve.tick(1.0)
	assert_eq(resolve.take_hit(), ResolveComponent.HitResult.KILLED)


func test_restore_is_capped_and_supports_half_pips() -> void:
	resolve.take_hit(2.0)
	resolve.restore(0.5)
	assert_near(resolve.pips, 2.5)
	resolve.restore(10.0)
	assert_near(resolve.pips, 4.0)
