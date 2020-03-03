extends Node

onready var current_sound_set : Node = get_child(0)

func on_settings_updated():
	var bus_idx := AudioServer.get_bus_index("Master")
	var is_muted : bool = Config.get_setting("audio", "mute")
	if is_muted:
		AudioServer.set_bus_volume_db(bus_idx, -INF)
	else:
		var volume : int = Config.get_setting("audio", "volume")
		volume = clamp(volume, 0, 100)
		var linear_volume := volume / 100.0
		var volume_db := linear2db(linear_volume)
		AudioServer.set_bus_volume_db(bus_idx, volume_db)
	
	var new_sound_set_number : int = Config.get_setting("sfx", "sound_set")
	new_sound_set_number = min(new_sound_set_number, get_child_count() - 1)
	
	current_sound_set = get_child(new_sound_set_number)
	

func play_sound(sound_name : String, volume : float):
	var sound : AudioStreamPlayer = current_sound_set.get_node(sound_name)
	
	sound.volume_db = volume
	sound.play()
