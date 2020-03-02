tool
extends Polygon2D
class_name EffectParameters

#the slap offset that will be sent to the camera
export var slap_offset:= Vector2(0,0)

#How much screen recoils with this effect applied
export var recoil_offset := 0
#How long it takes to recover from effect
export var recoil_time := 0.0
#How long it takes for flash to disappear
export var flash_time := 0.0
export var is_color_random := true
export(Color, RGB) var flash_color := Color()
#Scene to be spawned when this effect is applied
export(PackedScene) var effect_scene : PackedScene = null
#Sound to be played
export(String, "Keystroke", "Ding") var sound_name := "Keystroke"
#Volume of the sound to be played
export var sound_volume_db := -80.0

#Update atleast once so it works ingame
onready var start_angle : float = $Start.position.angle()
onready var end_angle : float = $End.position.angle()

#Get random angle within given constaints
func get_random_vector() -> Vector2:
	
	var start_vector := Vector2(cos(start_angle), sin(start_angle))
	var end_vector := Vector2(cos(end_angle), sin(end_angle))
	
	var cos_delta_angle := start_vector.dot(end_vector)
	
	var delta_angle := acos(cos_delta_angle)
	
	#Check the side of the end_vector relative to the start_vector
	#and invert the angle if is on the negative side
	if start_vector.cross(end_vector) < 0.0:
		delta_angle = 2 * PI - delta_angle
	
	#Generate point on the arc of length delta_angle starting at start_angle 
	var picked_angle := rand_range(0, delta_angle) + start_angle
	
	return Vector2(cos(picked_angle), sin(picked_angle))

func _ready():
	#Hide if is in game
	if !Engine.editor_hint:
		hide()
	
	if sound_name == "":
		sound_name = "Keystroke"

func _notification(what : int):
	#Disable updates if is hidden
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		set_process(visible)

func _process(delta : float):
	set_process(visible)
	#Update variables
	start_angle = $Start.position.angle()
	end_angle = $End.position.angle()
	
	#Update shader parameters of the preview
	material.set_shader_param("angle_start", start_angle)
	material.set_shader_param("angle_end", end_angle)
	