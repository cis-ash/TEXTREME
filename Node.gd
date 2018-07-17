extends CanvasLayer

#visual effects for keypresses. Change exported variables in the inspector or else it wont work
export var keyoffother = 2
export var keyoffspace = 4
export var keyoffenter = 8
export var keyoffdelete = 4

export var keytimeother = 0.1
export var keytimespace = 0.2
export var keytimeenter = 0.4
export var keytimedelete = 0.2

export var flashtimeother = 0.1
export var flashtimespace = 0.2
export var flashtimeenter = 0.4
export var flashtimedelete = 0.2

#charactersize in pixels. If you use a non monospace font the locatecursor() function wont work at all
export var charsize = Vector2(8.0,8.0)
export var metronomevolume = -10

#no toucch
var lastlineheight = 0
var flashwait = 0.0

#basic colors for misc use. the only really important ones are black and white
const cyan = Color(0,1,1,1)
const magenta = Color(1,0,1,1)
const black = Color(0,0,0,1)
const white = Color(1,1,1,1)

#array of colors the screen can flash in, feel free to add more
var colors = [ColorN("cyan",1),ColorN("magenta",1),ColorN("orchid",1),ColorN("pink",1),ColorN("orangered",1),ColorN("dodgerblue",1),ColorN("orange",1),ColorN("turquoise",1),ColorN("violet",1),ColorN("teal",1)]

var savename = ""
var saved = false
var fpath = ""

#runs on boot up, basic setup
func _ready():
	$Control.rect_size = get_viewport().get_visible_rect().size
	$Control/TextEdit.grab_focus()
	loadsyntax()
	pass

#runs every frame
func _process(delta):
	#$Control/Beatslider.rect_global_position = locatecursor() + $Position2D.global_position - $Control/Beatslider/center.position*$Control/Beatslider.rect_scale + charsize*0.5
	pass

#loads syntax from file, replace the "\\syntax.txt" by any other file name with syntax in it
#if you dont want the user to acces this file add it to the games folder and replace the OS.get_exec.. with a "res://" then add filename
func loadsyntax():
	var info = File.new()
	info.open(OS.get_executable_path().get_base_dir() + "\\syntax.txt", info.READ)
	var i = 0;
	var infoarray = info.get_csv_line()
	while infoarray.size() != 0:
		var word = infoarray[0]
		var color = ColorN(infoarray[1],1)
		$Control/TextEdit.add_keyword_color(word, color)
		infoarray = info.get_csv_line()


func _on_Load_pressed():
	$Control/LoadDialog.visible = true
	$Control/LoadDialog/LineEdit.grab_focus()
	pass 

#saves given text to a given file
func save(text,fname):
	savename = fname
	var file = File.new()
	file.open(OS.get_system_dir(0) + "\\" + fname + ".txt", file.WRITE)
	file.store_string(text)
	file.close()

func lload(fname):
	var file = File.new()
	file.open(OS.get_system_dir(0) + "\\" + fname + ".txt", file.READ)
	var content = file.get_as_text()
	file.close()
	return content

func _on_SaveButton_pressed():
	$Control/SaveDialog.visible = false
	save($Control/TextEdit.text, $Control/SaveDialog/LineEdit.text)
	savename = $Control/SaveDialog/LineEdit.text
	saved = true
	$Control/TextEdit.grab_focus()
	pass


func _on_Save_AS_pressed():
	$Control/SaveDialog.visible = true
	$Control/SaveDialog/LineEdit.grab_focus()
	pass 


func _on_Save_pressed():
	if saved:
		save($Control/TextEdit.text,savename)
	else:
		$Control/SaveDialog.visible = true
		$Control/SaveDialog/LineEdit.grab_focus()
	pass 

func _on_LoadButton_pressed():
	$Control/TextEdit.text = lload($Control/LoadDialog/LineEdit.text)
	$Control/LoadDialog.visible = false
	$Control/TextEdit.grab_focus()
	pass 


#a function used to organize all buttonpress effects, receives the name of the effect, then executes it
func typejerk(type):
	match type:
		"other":
			$Camera2D.recoil(Vector2(1,0).rotated(rand_range(0,TAU)),keytimeother,keyoffother)
			$Camera2D.flash(colors[randi()%colors.size()],black,flashtimeother)
			$Keystroke.volume_db = -8
			$Keystroke.play()
			spawnsparks(locatecursor())
		"space":
			$Camera2D.recoil(Vector2(1,0).rotated(rand_range(0,TAU)),keytimespace,keyoffspace)
			$Camera2D.flash(colors[randi()%colors.size()],black,flashtimespace)
			$Keystroke.volume_db = -5
			$Keystroke.play()
		"enter":
			$Camera2D.recoil(Vector2(0,1).rotated(rand_range(-PI*0.25,PI*0.25)),keytimeenter,keyoffenter)
			$Camera2D.flash(colors[6],black,flashtimeenter)
			$Ding.volume_db = -5
			$Ding.play()
			spawnflash(locatecursor())
			
		"delete":
			$Camera2D.recoil(Vector2(0,1).rotated(rand_range(-PI*0.25,PI*0.25)+PI/2),keytimedelete,keyoffdelete)
			$Camera2D.flash(colors[1],black,flashtimedelete)
			$Keystroke.volume_db = -8
			$Keystroke.play()
			spawncross(locatecursor()+charsize*Vector2(1,0))
		
		"backspace":
			$Camera2D.recoil(Vector2(0,1).rotated(rand_range(-PI*0.25,PI*0.25)-PI/2),keytimedelete,keyoffdelete)
			$Camera2D.flash(colors[1],black,flashtimedelete)
			$Keystroke.volume_db = -8
			$Keystroke.play()
			spawncross(locatecursor())
			
		"repeat":
			$Camera2D.recoil(Vector2(1,0).rotated(rand_range(0,TAU)),0.05,1)
			$Camera2D.flash(colors[randi()%colors.size()],black,0.05)
			$Keystroke.volume_db = -15
			$Keystroke.play()
			spawnsparks(locatecursor())
		
		"dot":
			$Camera2D.shake(0.1,0.05,5)
			$Camera2D.flash(colors[randi()%colors.size()],black,0.2)
			$Keystroke.volume_db = 0
			$Keystroke.play()
			spawndoteffects(locatecursor())
		
		"dash":
			$Camera2D.recoil(Vector2(0,1).rotated(rand_range(-PI*0.25,PI*0.25)-PI*0.5),0.2,4)
			$Camera2D.flash(colors[randi()%colors.size()],black,0.2)
			$Keystroke.volume_db = -5
			$Keystroke.play()
			spawndasheffects(locatecursor())
		
		"exclamation":
			$Camera2D.shake(0.2,0.05,8)
			$Camera2D.flash(colors[randi()%colors.size()],black,0.2)
			$Keystroke.volume_db = 0
			$Keystroke.play()
			spawnexclamation(locatecursor())
		
		"question":
			$Camera2D.shake(0.2,0.05,8)
			$Camera2D.flash(colors[randi()%colors.size()],black,0.2)
			$Keystroke.volume_db = 0
			$Keystroke.play()
			spawnquestion(locatecursor())


#input handler, all events are read top to bottom, please avoid triggering 2 effects in a single frame
#btw, no adequate human types 2 characters per frame, dont worry about it
#custom names for keys presses or combos of such are made in [project > input map]
func _input(event):
	if (event is InputEventKey && event.pressed && $Control/TextEdit.has_focus()):
		if $Control/Beatslider.checktiming() && !event.is_echo() && $Control/Beatslider.isactive:
			spawnhitconfirm()
			$Camera2D.shake(0.05,0.05,4)
		elif !$Control/Beatslider.checktiming() && !event.is_echo() && $Control/Beatslider.isactive:
			spawnhitfail()
		
		
		if Input.is_action_pressed("space"):
			typejerk("space")
		elif Input.is_action_pressed("enter"):
			typejerk("enter")
		elif Input.is_action_pressed("delete"):
			typejerk("delete")
		elif Input.is_action_pressed("backspace"):
			typejerk("backspace")
		elif Input.is_action_pressed("exclamation"):
			typejerk("exclamation")
		elif Input.is_action_pressed("question"):
			typejerk("question")
		elif Input.is_action_pressed("dot"):
			typejerk("dot")
		elif Input.is_action_pressed("dash"):
			typejerk("dash")
		elif event.is_echo():
			typejerk("repeat")
		elif !Input.is_action_just_pressed("ignore"):
			typejerk("other")

func visiblelines():
	return


#its a miracle that this thing even works, touch at your own risk
#to work properly, the Position2D node must be placed at the top-leftmost pixel of the first character in Control/TextEdit
#also the charsize must be accurate
func locatecursor():
	var cursorpos = Vector2($Control/TextEdit.cursor_get_column()-$Control/TextEdit.get_children()[0].value/charsize.x, $Control/TextEdit.cursor_get_line()-$Control/TextEdit.get_children()[1].value)
	var linetext = $Control/TextEdit.get_line(cursorpos.y)
	
	linetext = linetext.left($Control/TextEdit.cursor_get_column())
	
	#"\t" is basically TAB, this is a fix that counts tab as 4 characters instead of 1
	while linetext.find("\t",0) != -1:
		linetext.erase(linetext.find("\t",0), 1)
		cursorpos.x +=3
	
	cursorpos *= charsize
	if lastlineheight < $Control/TextEdit.get_children()[1].value:
		lastlineheight = $Control/TextEdit.get_children()[1].value
		cursorpos.y -= charsize.y
	return cursorpos

#to keep the effects function clean and neat all of the function that spawn in a node with and effects are stored here

func spawnflash(position):
	var flash = preload("res://flash.tscn").instance()
	$Position2D.add_child(flash);
	position.y += charsize.y*1.5
	flash.get_node("Sprite").global_position = position + $Position2D.global_position

func spawnsparks(position):
	var sparkler = preload("res://sparkler.tscn").instance()
	$Position2D.add_child(sparkler)
	position.x += charsize.x*1.5
	position.y += charsize.y
	sparkler.global_position = position + $Position2D.global_position

func spawndoteffects(position):
	var explosion = preload("res://dot.tscn").instance()
	$Position2D.add_child(explosion)
	position.y += charsize.y*0.75
	position.x += charsize.x*0.5
	explosion.global_position = position + $Position2D.global_position

func spawndasheffects(position):
	var dash = preload("res://dash.tscn").instance()
	$Position2D.add_child(dash)
	position.y += charsize.y*0.5
	position.x += charsize.x*0.5
	dash.global_position = position + $Position2D.global_position

func spawnexclamation(position):
	var exclamation = preload("res://exclamationmark.tscn").instance()
	$Position2D.add_child(exclamation)
	position.y += charsize.y*0.5
	position.x += charsize.x*0.5
	exclamation.global_position = position + $Position2D.global_position

func spawnquestion(position):
	var question = preload("res://questionmark.tscn").instance()
	$Position2D.add_child(question)
	position.y += charsize.y*0.5
	position.x += charsize.x*0.5
	question.global_position = position + $Position2D.global_position

func spawncross(position):
	var cross = preload("res://cross.tscn").instance()
	$Position2D.add_child(cross)
	position.y += charsize.y*0.5
	position.x += -charsize.x*0.5
	cross.global_position = position + $Position2D.global_position

func spawnhitconfirm():
	var confirm = preload("res://hit confirm.tscn").instance()
	$Position2D.add_child(confirm)
	confirm.global_position = $Control/Beatslider/center.global_position
	confirm.scale = $Control/Beatslider.rect_scale
	confirm.modulate = $Control/Beatslider.modulate

func spawnhitfail():
	var fail = preload("res://fail.tscn").instance()
	$Position2D.add_child(fail)
	fail.global_position = $Control/Beatslider/center.global_position
	fail.scale = $Control/Beatslider.rect_scale
	fail.modulate = $Control/Beatslider.modulate

#triggers every time the metronome value is changed
func _on_BPMcontroller_value_changed(value):
	if value == 0:
		$Metronome.volume_db = -100
		$Control/Beatslider.isactive = false
	else:
		$Metronome.volume_db = metronomevolume
		$Control/Beatslider.isactive = $Control/CheckBox.pressed
		$Metronometimer.stop()
		$Metronometimer.wait_time = 60/value
		$Metronometimer.start()
		flashwait = 60/value
		$Control/Beatslider.timepertick = flashwait
		$Control/Beatslider.timesincelasttick = 0.0
	pass 
	

#triggers every time a metronome would tick
func _on_Metronometimer_timeout():
	$Metronometimer.start()
	$Metronome.play()
	$Control/Beatslider.timesincelasttick = 0.0 #a dirty fix for metronome tick and the beatsliders being not in sync
	pass 


#activates/deactivates the beatsliders
func _on_CheckBox_toggled(button_pressed):
	if $Control/BPMcontroller.value != 0:
		$Control/Beatslider.isactive = button_pressed
		$Control/Beatslider.timepertick = 60/$Control/BPMcontroller.value
	else:
		$Control/Beatslider.isactive = false
	pass
