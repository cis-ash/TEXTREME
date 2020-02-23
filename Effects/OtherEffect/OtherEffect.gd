extends Node2D

func _ready():
	$Sparks.emitting = true

func on_setup_done():
	var parent := get_parent() as Effect
	position = parent.positions[0]
	scale = Vector2(1, 1) * (parent.font.get_height() / 12.0)
