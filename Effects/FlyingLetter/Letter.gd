extends Node2D

export var rotations_per_s_min := 7.0
export var rotations_per_s_max := 13.0

export var x_speed_min := -300.0
export var x_speed_max := -100.0

export var y_speed_min := -220.0
export var y_speed_max := -108.0

export var gravity_min := 300.0
export var gravity_max := 400.0

var linear_velocity := Vector2()
var angular_velocity := 0.0
var gravity := 0.0

func on_setup_done():
	var parent : Effect = get_parent()
	var label : Label = $Text
	
	label.set("custom_fonts/font", parent.font)
	label.rect_size = Vector2()
	label.text = parent.text
	
	$VisibilityNotifier2D.rect = label.get_rect()
	
	global_position = parent.positions[0]
	
	var effect_scale = parent.font.get_height() / 12.0
	
	var temp_x : float = rand_range(x_speed_min / effect_scale, x_speed_max / effect_scale)
	var temp_y : float = rand_range(y_speed_min, y_speed_max)
	
	linear_velocity = Vector2(temp_x, temp_y)
	gravity = rand_range(gravity_min * effect_scale, gravity_max * effect_scale)
	angular_velocity = rand_range(rotations_per_s_min / effect_scale, rotations_per_s_max / effect_scale)
	

func _process(delta : float):
	position += linear_velocity * delta
	rotation += angular_velocity * delta
	linear_velocity += Vector2(0, gravity * delta)
	
