extends Node

const LOAD_PATH := "user://config.cfg"
const UPDATE_INTERVAL := 0.5

var _config_file := ConfigFile.new()
var _settings := {
	"audio" : {
		"volume": 100,
		"mute": false
	},
	"sfx" : {
		"flashing_intensity": 100,
		"shaking": true,
		"writer_mode": false
	},
	"text_editor" : {
		"line_wrap": true,
		"line_numbers": true,
		"disable_syntax": false
	}
}

func get_config_path() -> String:
	return LOAD_PATH

func _ready():
	if !load_settings(LOAD_PATH):
		create_default_file(LOAD_PATH)
	call_deferred("_reload_settings", LOAD_PATH)

func _reload_settings(path):
	while true:
		load_settings(path)
		yield(get_tree().create_timer(UPDATE_INTERVAL), "timeout")
#		print(randi())

func create_default_file(path):
	for section in _settings.keys():
		for key in _settings[section]:
			_config_file.set_value(section, key, _settings[section][key])
	_config_file.save(path)

func notify_listeners():
	get_tree().call_group("settings_listener", "on_settings_updated")

func load_settings(path) -> bool:
	var error := _config_file.load(path)
	if error != OK:
		printerr("Failed to load settings file. Error code: %s" % error)
		return false
	
	for section in _settings.keys():
		for key in _settings[section]:
			var value = _config_file.get_value(section, key, _settings[section][key])
			if typeof(value) == typeof(_settings[section][key]):
				_settings[section][key] = value
	call_deferred("notify_listeners")
	return true

func get_setting(category, key):
	return _settings[category][key]