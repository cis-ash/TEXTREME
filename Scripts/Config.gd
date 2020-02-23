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
		"flashing_bg": true,
		"shaking": true
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

func apply_sound_volume():
	var bus_idx = AudioServer.get_bus_index("Master")
	if _settings["audio"]["mute"]:
		AudioServer.set_bus_volume_db(bus_idx, -INF)
	else:
		var volume : int = _settings["audio"]["volume"]
		volume = clamp(volume, 0, 100)
		var linear_volume = volume / 100.0
		var volume_db = linear2db(linear_volume)
		AudioServer.set_bus_volume_db(bus_idx, volume_db)

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
	apply_sound_volume()
	return true

func get_setting(category, key):
	return _settings[category][key]