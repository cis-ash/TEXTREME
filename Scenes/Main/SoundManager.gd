extends Node

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
	#TODO different sound sets

func play_sound(sound_name : String, volume : float):
	var sound : AudioStreamPlayer = get_node(sound_name)
	
	sound.volume_db = volume
	sound.play()
