extends Control

export var MAX_EFFECT_COUNT := 1000

#func spawn_flash(position):
#	var flash = preload("res://Effects\\flash.tscn").instance()
#	StartTextPosition.add_child(flash);
#	position.y += charsize.y*1.5
#	flash.rect_size.x = StartTextPosition.global_position.x + $UIBase.rect_size.x
#	flash.rect_position.y = position.y - StartTextPosition.global_position.y
#	flash.rect_position.x = -StartTextPosition.global_position.x
#
#func spawnsparks(position):
#	var sparkler = preload("res://Effects\\sparkler.tscn").instance()
#	StartTextPosition.add_child(sparkler)
#	position.x += charsize.x*1.5
#	position.y += charsize.y
#	sparkler.global_position = position + StartTextPosition.global_position
#
#func spawndoteffects(position):
#	var explosion = preload("res://Effects\\dot.tscn").instance()
#	StartTextPosition.add_child(explosion)
#	position.y += charsize.y*0.75
#	position.x += charsize.x*0.5
#	explosion.global_position = position + StartTextPosition.global_position
#
#func spawndasheffects(position):
#	var dash = preload("res://Effects\\dash.tscn").instance()
#	StartTextPosition.add_child(dash)
#	position.y += charsize.y*0.5
#	position.x += charsize.x*0.5
#	dash.global_position = position + StartTextPosition.global_position
#
#func spawnexclamation(position):
#	var exclamation = preload("res://Effects\\exclamationmark.tscn").instance()
#	StartTextPosition.add_child(exclamation)
#	position.y += charsize.y*0.5
#	position.x += charsize.x*0.5
#	exclamation.global_position = position + StartTextPosition.global_position
#
#func spawnquestion(position):
#	var question = preload("res://Effects\\questionmark.tscn").instance()
#	StartTextPosition.add_child(question)
#	position.y += charsize.y*0.5
#	position.x += charsize.x*0.5
#	question.global_position = position + StartTextPosition.global_position

func spawn_scene(text : String, positions : PoolVector2Array, position_before : Vector2, 
			scene_to_spawn : PackedScene, font : Font = null):
	
	if scene_to_spawn == null || get_child_count() >= MAX_EFFECT_COUNT:
		return
	
	#TODO type check
	var new_scene = scene_to_spawn.instance()
	
	add_child(new_scene)
	
	new_scene.setup_effect(text, positions, position_before, font)
	

func spawn_letter(text : String, position : Vector2):
	assert(text.length() == 1)
	var cross = preload("res://Effects\\cross.tscn").instance()
	add_child(cross)
#	position.y += charsize.y*0.5
#	position.x += -charsize.x*0.5
	cross.letter = text
	cross.global_position = position
#	cross.global_position = Vector2()
