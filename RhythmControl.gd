extends Control

export var allowance = 0.3
export var metronomevolume = -15

var timepertick = 1.0
var timesincelasttick = 0.0
var isactive = false
var ready = false

onready var BeatSliderLeft = $Beatslider/left
onready var BeatSliderRight = $Beatslider/right
onready var BeatSliderCenter = $Beatslider/center

onready var BeatSlider = $Beatslider

func _process(delta):
	if !isactive:
		BeatSlider.hide()
		return
	
	if !(timesincelasttick/timepertick > 1-allowance || timesincelasttick/timepertick < allowance*0.5):
		ready = true
	
	BeatSlider.show()
	BeatSliderLeft.position.y = BeatSlider.rect_size.y/2
	BeatSliderLeft.position.x = 0
	BeatSliderRight.position.y = BeatSlider.rect_size.y/2
	BeatSliderRight.position.x = BeatSlider.rect_size.x
	BeatSliderCenter.position = BeatSlider.rect_size/2
	
	timesincelasttick += delta
	if timesincelasttick >= timepertick:
		timesincelasttick -= timepertick
	
	BeatSliderLeft.get_node("slider1").position = BeatSlider.rect_size*(Vector2(0.25,0)*timesincelasttick/timepertick)
	BeatSliderLeft.get_node("slider2").position = BeatSlider.rect_size*(Vector2(0.25,0)*timesincelasttick/timepertick+Vector2(0.25,0))
	
	BeatSliderRight.get_node("slider1").position = BeatSlider.rect_size*(Vector2(-0.25,0)*timesincelasttick/timepertick)
	BeatSliderRight.get_node("slider2").position = BeatSlider.rect_size*(Vector2(-0.25,0)*timesincelasttick/timepertick+Vector2(-0.25,0))
	
	pass

#triggers every time the metronome value is changed
func _on_BPMcontroller_value_changed(value):
	if value == 0:
		$Metronome.volume_db = -100
		isactive = false
	else:
		$Metronome.volume_db = metronomevolume
		isactive = $CheckBox.pressed
		$Metronometimer.stop()
		$Metronometimer.wait_time = 60/value
		$Metronometimer.start()
		timepertick = 60/value
		timesincelasttick = 0.0
	pass 

#triggers every time a metronome would tick
func _on_Metronometimer_timeout():
	$Metronometimer.start()
	$Metronome.play()
	timesincelasttick = 0.0 #a dirty fix for metronome tick and the beatsliders being not in sync
	pass 


#activates/deactivates the beatsliders
func _on_CheckBox_toggled(button_pressed):
	if $BPMcontroller.value != 0:
		isactive = button_pressed
		timepertick = 60/$BPMcontroller.value
	else:
		isactive = false
	pass

#says whether you hit or not
func checktiming():
	if (timesincelasttick/timepertick > 1-allowance || timesincelasttick/timepertick < allowance*0.5) && ready:
		ready = false
		return true
	else:
		return false
