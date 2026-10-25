extends TestCase

var health: HealthComponent


func before_each() -> void:
	health = HealthComponent.new()
	health.max_health = 30.0
	health.reset()


func after_each() -> void:
	health.free()


func test_damage_and_death() -> void:
	assert_false(health.damage(10.0))
	assert_near(health.current, 20.0)
	assert_true(health.damage(25.0), "this hit kills")
	assert_true(health.is_dead())
	assert_false(health.damage(5.0), "already dead")


func test_heal_is_capped_and_ignored_when_dead() -> void:
	health.damage(10.0)
	health.heal(50.0)
	assert_near(health.current, 30.0)
	health.damage(30.0)
	health.heal(10.0)
	assert_near(health.current, 0.0)
