extends Node2D

export(Array, NodePath) var particles : Array = []

func _ready():
	for i in particles:
		get_node(i).emitting = true

func on_setup_done():
	position = (get_parent() as Effect).positions[0]