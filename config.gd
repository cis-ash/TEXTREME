extends Node


const LOAD_PATH = "config.cfg"

var _config_file = ConfigFile.new()
var _settings = {
      "text": {
        "size": 12
      },
      "audio" : {
        "volume": 100,
        "mute": false
      }
}

func _ready():
  load_settings(LOAD_PATH)

func load_settings(path):
  var error = _config_file.load(path)
  if error != OK:
    printerr("Failed to load settings file. Error code: %s" % error)
    return null

  for section in _settings.keys():
    for key in _settings[section]:
      _settings[section][key] = _config_file.get_value(section, key, null)

func get_setting(category, key):
	return _settings[category][key]