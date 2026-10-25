class_name TestCase
extends RefCounted
## Base class for unit tests. Every method starting with "test_" in a file under
## res://tests/unit/ is run by res://tests/run_tests.gd, each on a fresh instance.

var failures: PackedStringArray = []


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		failures.append("expected true. " + message)


func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		failures.append("expected false. " + message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("expected %s, got %s. %s" % [var_to_str(expected), var_to_str(actual), message])


func assert_near(actual: float, expected: float, tolerance: float = 0.001, message: String = "") -> void:
	if absf(actual - expected) > tolerance:
		failures.append("expected %f ± %f, got %f. %s" % [expected, tolerance, actual, message])
