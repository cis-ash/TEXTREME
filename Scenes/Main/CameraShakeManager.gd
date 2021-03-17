extends Node

var recoiltime = 1.0
var jerklength = 1.0

#frames of certain process are brought up in some variables
#its a leftover from the times when the effects were frame based, now its all working off Delta (hence the float  values)
var lastdirection = Vector2(0,0)
var jerkoff = Vector2(0,0);
var recoilframe = 0.0

var currentcol = Color(0,0,0,0)
var fromcol = Color(0,0,0,0)
var tocol = Color(0,0,0,0)
var flashframe = 0.0
var flashlength = 1.0

var current_shake_offset = 0.0
var shake_time_left = 0.0
var current_recovery_length = 0.0

var slap_spring_offset = 0.0
var slap_spring_direction = Vector2(0,0);
var slap_spring_lerp = 20.0;
var slap_spring_speed = 0.0;

func _process(delta):
	
	#the part that makes the camera actually shake
	if shake_time_left > 0.0:
		recoil(Vector2(1,0).rotated(rand_range(-PI,PI)),current_recovery_length,current_shake_offset)
	
	shake_time_left = max(shake_time_left-delta, 0)
	
	if recoiltime == 0:
		recoiltime = 1
	
	#recovers from jerk
	jerkoff.x = lerp(0, jerklength*lastdirection.x,recoilframe/recoiltime)
	jerkoff.y = lerp(0, jerklength*lastdirection.y,recoilframe/recoiltime)
	recoilframe = max(recoilframe-delta, 0)
	
	slap_spring_speed = lerp(slap_spring_speed, (0 - slap_spring_offset)/1, delta*slap_spring_lerp)
	slap_spring_offset += slap_spring_speed*delta*60
	
	jerkoff += slap_spring_offset*slap_spring_direction
	
	get_parent().offset = jerkoff 
	# to fix certain issues in the game it had to use a canvas layer as the main node. 
	#Its glued to your screen so shaking the camera wont work. 
	#Thats why it is offseted to imitate the movement of a camera
	
	#recovers from flash

	currentcol.r = lerp(tocol.r,fromcol.r, flashframe/flashlength)
	currentcol.g = lerp(tocol.g,fromcol.g, flashframe/flashlength)
	currentcol.b = lerp(tocol.b,fromcol.b, flashframe/flashlength)
	currentcol.a = 1
	flashframe = max(flashframe-delta, 0)
	get_parent().get_node("BackgroundColor").color = currentcol

#jerks the camera in a certain direction after which it will linerly recover
func recoil(direction : Vector2, length : float, offset : float):
	jerklength = offset
	recoiltime = length
	
	jerkoff = direction.normalized()*jerklength
	lastdirection = direction.normalized()
	recoilframe = recoiltime
	pass

#flashes the screen a requested color after which fades to the second specified color. 
#That color is then the resting color untill the function is called again 
func flash(souce_color : Color, target_color : Color, transitionframes):
	flashlength = transitionframes
	fromcol = souce_color
	tocol = target_color
	flashframe = flashlength

#initiate camera shake
func shake(length,recoverlength,offsetlength):
	shake_time_left = length
	current_shake_offset = offsetlength
	current_recovery_length = recoverlength

func slap(slap : Vector2):
	slap_spring_offset = (slap_spring_offset*slap_spring_direction + slap).length()
	slap_spring_direction = (slap_spring_offset*slap_spring_direction + slap).normalized()
