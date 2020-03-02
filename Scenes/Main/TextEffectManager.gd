extends Node

export(NodePath) var camera_manager_p := NodePath()
export(NodePath) var particle_effect_spawner_p := NodePath()
export(NodePath) var sound_manager_p := NodePath()

onready var camera_manager = get_node(camera_manager_p)
onready var particle_effect_spawner = get_node(particle_effect_spawner_p)
onready var sound_manager = get_node(sound_manager_p)

var flash_colors := ["cyan","magenta","orchid", "pink", "orangered", "dodgerblue", "orange", "turquoise", "violet", "teal"]

func text_added(string : String, positions : PoolVector2Array, position_before_first : Vector2, font : Font, is_repeated : bool):
	
	#One character added
	if string.length() == 1:
		
		var data : EffectParameters = null
		match string:
			".":
				data = $DotAdd
			"-":
				data = $DashAdd
			"!":
				data = $ExplamationAdd
			"?":
				data = $QuestionAdd
			" ", "\t":
				data = $WhiteSpaceAdded
			"\n":
				data = $Lazer
			_:
				data = $OtherOneAdd
		
		particle_effect_spawner.spawn_scene(string, positions, position_before_first, data.effect_scene, font)
		_handle_recoil_flash_sound(data, is_repeated)
	else:
		var data : EffectParameters = $Paste
		particle_effect_spawner.spawn_scene(string, positions, position_before_first, data.effect_scene, font)
		_handle_recoil_flash_sound(data, is_repeated)
	

func text_removed(string : String, positions : PoolVector2Array, position_before_first : Vector2, font : Font, is_repeated : bool):
	
	var idx := 0
	
	var data : EffectParameters = $OtherOneRemoval
	
	while idx < positions.size():
		particle_effect_spawner.spawn_scene(string[idx], [positions[idx]], position_before_first, data.effect_scene, font)
		idx += 1
	
	_handle_recoil_flash_sound(data, is_repeated)
	

func _get_random_color() -> Color:
	return ColorN(flash_colors[randi() % flash_colors.size()])

func _handle_recoil_flash_sound(data : EffectParameters, is_repeated : bool):
	if Config.get_setting("sfx", "shaking"):
		camera_manager.recoil(data.get_random_vector(), data.recoil_time, data.recoil_offset)
		camera_manager.slap(data.slap_offset)
	
	var source_color := data.flash_color
	
	if data.is_color_random:
		source_color = _get_random_color()
	
	#TODO fix hardcoded color
	if Config.get_setting("sfx", "flashing_bg"):
		camera_manager.flash(source_color, Color(), data.flash_time)
	
	var actual_sound_volume := data.sound_volume_db
	
	if is_repeated:
		if actual_sound_volume > 0.0:
			actual_sound_volume /= 2
		else:
			actual_sound_volume *= 2
	
	sound_manager.play_sound(data.sound_name, actual_sound_volume)
	
	
