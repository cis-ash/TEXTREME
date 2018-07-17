extends Control
export var allowance = 0.3
var timepertick = 1.0
var timesincelasttick = 0.0
var isactive = false
var ready = true

func _ready():
	pass

func _process(delta):
	if isactive:
		
		if !(timesincelasttick/timepertick > 1-allowance || timesincelasttick/timepertick < allowance*0.5):
			ready = true
		
		visible = true
		$left.position.y = rect_size.y/2
		$left.position.x = 0
		$right.position.y = rect_size.y/2
		$right.position.x = rect_size.x
		$center.position = rect_size/2
		
		timesincelasttick += delta
		if timesincelasttick >= timepertick:
			timesincelasttick -= timepertick
		
		$left/slider1.position = rect_size*(Vector2(0.25,0)*timesincelasttick/timepertick)
		$right/slider1.position = rect_size*(Vector2(-0.25,0)*timesincelasttick/timepertick)
		$left/slider2.position = rect_size*(Vector2(0.25,0)*timesincelasttick/timepertick+Vector2(0.25,0))
		$right/slider2.position = rect_size*(Vector2(-0.25,0)*timesincelasttick/timepertick+Vector2(-0.25,0))
	else:
		visible = false
	pass

#says whether you hit or not
func checktiming():
	if (timesincelasttick/timepertick > 1-allowance || timesincelasttick/timepertick < allowance*0.5) && ready:
		ready = false
		return true
	else:
		return false
