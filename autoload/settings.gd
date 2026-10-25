extends Node
## Player settings stored in user://settings.cfg. Read with get_value(); every key needs
## a default in DEFAULTS.

const PATH := "user://settings.cfg"
const DEFAULTS: Dictionary = {
	"audio": {"master": 1.0, "music": 0.8, "sfx": 1.0},
	"feel": {"screen_shake": 1.0, "vibration": true},
	"online": {"crossplay": true},
}

var _config := ConfigFile.new()


func _ready() -> void:
	_config.load(PATH) # A missing file is fine: defaults are used.


func get_value(section: String, key: String) -> Variant:
	return _config.get_value(section, key, DEFAULTS[section][key])


func set_value(section: String, key: String, value: Variant) -> void:
	_config.set_value(section, key, value)


func save_settings() -> Error:
	return _config.save(PATH)
