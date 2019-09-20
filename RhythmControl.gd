extends Control

export var allowance := 0.3
export var metronome_volume := -15

var time_per_tick := 1.0
var time_since_last_tick := 0.0
var is_active := false
var is_already_hit := true

onready var beat_slider_left : Node2D = $left
onready var beat_slider_right : Node2D = $right
onready var beat_slider_center : Node2D = $center
onready var metronome_timer : Timer = $MetronomeTimer
onready var metronome_sound : AudioStreamPlayer = $Metronome

func get_is_active() -> bool:
	return is_active

func _ready():
	set_bpm(0)

func set_bpm(value : int):
	if value == 0:
		metronome_sound.volume_db = -100
		metronome_sound.stop()
		is_active = false
		hide()
	else:
		is_active = true
		metronome_sound.volume_db = metronome_volume
		metronome_sound.play()
		metronome_timer.stop()
		time_per_tick = 60 / float(value)
		metronome_timer.wait_time = time_per_tick
		metronome_timer.start()
		time_since_last_tick = 0.0
		show()
	
	set_physics_process(is_active)

func _process(delta):
	
	var tick_percent = time_since_last_tick / time_per_tick
	
	if !(tick_percent > 1 - allowance || tick_percent < allowance * 0.5):
		is_already_hit = false
	
	beat_slider_left.position.y = rect_size.y/2
	beat_slider_left.position.x = 0
	beat_slider_right.position.y = rect_size.y/2
	beat_slider_right.position.x = rect_size.x
	beat_slider_center.position = rect_size/2
	
	time_since_last_tick += delta
	if time_since_last_tick >= time_per_tick:
		time_since_last_tick -= time_per_tick
	
	beat_slider_left.get_node("slider1").position = rect_size * Vector2(tick_percent / 4.0,0)
	beat_slider_left.get_node("slider2").position = rect_size * Vector2(tick_percent / 4.0 + 0.25,0)
	
	beat_slider_right.get_node("slider1").position = rect_size * Vector2(-tick_percent / 4.0,0)
	beat_slider_right.get_node("slider2").position = rect_size * Vector2(-(tick_percent / 4.0 + 0.25),0)

#Called every time a metronome would tick
func _on_metronome_timer_timeout():
	metronome_timer.start()
	metronome_sound.play()
	time_since_last_tick = 0.0 #a dirty fix for metronome tick and the beatsliders being not in sync

#Returns whether you hit or not
func is_hitting() -> bool:
	if (time_since_last_tick / time_per_tick > 1 - allowance 
		|| time_since_last_tick/time_per_tick < allowance*0.5) && !is_already_hit:
		is_already_hit = true
		return true
	else:
		return false
