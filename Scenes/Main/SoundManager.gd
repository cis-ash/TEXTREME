extends Node

func play_sound(sound_name : String, volume : float):
	var sound : AudioStreamPlayer = get_node(sound_name)
	
	sound.volume_db = volume
	sound.play()
