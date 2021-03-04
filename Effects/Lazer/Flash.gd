extends Control

func _ready():
	call_deferred("start")

func start():
	var parent := (get_parent() as Effect)
	rect_position.y = parent.positions[0].y - parent.font.get_height() / 2
	rect_size.y = parent.font.get_height()
	$AnimationPlayer.play("Fadeout")
