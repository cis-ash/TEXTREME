extends Node2D

func _ready():
	$Explosion.emitting = true

func on_setup_done():
	position = (get_parent() as Effect).positions[0]