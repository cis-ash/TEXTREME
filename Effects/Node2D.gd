extends Node2D

var speed = Vector2(rand_range(-100,-300),rand_range(-108,-220))
var rps = rand_range(7,13)
var gravity = rand_range(300,400)

func _process(delta):
	position += speed*delta
	rotation += rps*delta
	speed.y += gravity*delta

