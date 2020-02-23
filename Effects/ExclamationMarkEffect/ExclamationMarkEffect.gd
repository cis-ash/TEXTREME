extends Node2D

func _ready():
	$Explosion.emitting = true

func on_setup_done():
	var parent : Effect = get_parent()
	var label : Label = $Label
	var explosion : Particles2D = $Explosion
	
	set("custom_font/font", parent.font)
	
	label.rect_pivot_offset = label.rect_size / 2.0
	
	position = parent.positions[0]
	
