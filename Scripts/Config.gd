extends Node

const LOAD_PATH := "user://config.cfg"
const UPDATE_INTERVAL := 0.5

var _settings := {
	"audio" : {
		"volume": 100,
		"mute": false
	},
	"sfx" : {
		"flashing_intensity": 100,
		"shaking_intensity": 100,
		"writer_mode": false,
		"sound_set": 0
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
		save_current_settings_to_file(LOAD_PATH)
	call_deferred("_reload_settings", LOAD_PATH)

func _reload_settings(path):
	while true:
		load_settings(path)
		yield(get_tree().create_timer(UPDATE_INTERVAL), "timeout")
#		print(randi())

func save_current_settings_to_file(path):
	var _config_file := ConfigFile.new()
	for section in _settings.keys():
		for key in _settings[section]:
			_config_file.set_value(section, key, _settings[section][key])
	_config_file.save(path)

func notify_listeners():
	get_tree().call_group("settings_listener", "on_settings_updated")

func load_settings(path) -> bool:
	var _config_file := ConfigFile.new()
	var error := _config_file.load(path)
	if error != OK:
		printerr("Failed to load settings file. Error code: %s" % error)
		return false
	
	var are_any_different := false
	var are_any_missing := false
	for section in _settings.keys():
		for key in _settings[section]:
			
			if !_config_file.has_section_key(section, key):
				are_any_missing = true
			
			var value = _config_file.get_value(section, key, _settings[section][key])
			if typeof(value) == typeof(_settings[section][key]):
				if value != _settings[section][key]:
					_settings[section][key] = value
					are_any_different = true
	if are_any_different:
		call_deferred("notify_listeners")
	if are_any_missing:
		save_current_settings_to_file(LOAD_PATH)
	return true

func get_setting(category, key):
	return _settings[category][key]