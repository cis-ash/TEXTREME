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

#no toucch
var lineafter = ""
var lastlineheight = 0
var linebefore = ""
var y_was = 0
var queue_check = false
#basic colors for misc use. the only really important ones are black and white
const cyan = Color(0,1,1,1)
const magenta = Color(1,0,1,1)
const black = Color(0,0,0,1)
const white = Color(1,1,1,1)

#array of colors the screen can flash in, feel free to add more
var flash_colors := ["cyan","magenta","orchid", "pink", "orangered", "dodgerblue", "orange", "turquoise", "violet", "teal"]

var current_file_path := ""
var current_file_name := "Untitled"
var file_ext := ""
var does_saved_file_exist := false
var is_file_modified := false

onready var TextEditWindow = $UIBase/TextEdit
onready var load_dialog = $UIBase/LoadDialog
onready var save_dialog = $UIBase/SaveDialog
onready var bpm_dialog = $UIBase/BPMDialog
onready var StartTextPosition = $StartTextPosition

onready var RythmControl = $UIBase/RhythmControl

func update_file_name_display():
	if is_file_modified:
		$UIBase/FileName.text = "*" + current_file_name
	else:
		$UIBase/FileName.text = current_file_name

func set_new_is_file_modified(new_is_modified : bool):
	is_file_modified = new_is_modified
	update_file_name_display()

func set_new_file_name(new_file_name : String):
	current_file_name = new_file_name
	file_ext = current_file_name.get_extension()
	update_file_name_display()

#runs on boot up, basic setup
func _ready():
	var config = get_node("/root/config")
	var font = TextEditWindow.get_font("", "")
	font.size = int(abs(config.get_setting("text", "size")))
	print(font.size)
	TextEditWindow.grab_focus()
	
	
	TextEditWindow.connect("text_changed", self, "set_new_is_file_modified", [true])
	bpm_dialog.connect("on_text_entered", self, "_on_bpm_confirmed")
	save_dialog.connect("on_text_entered", self, "_on_file_save_confirmed")
	load_dialog.connect("on_text_entered", self, "_on_file_load_confirmed")
	

#runs every frame
func _process(delta):
	if queue_check:
		lineafter = TextEditWindow.get_line(TextEditWindow.cursor_get_line())
		var removed = what_removed(linebefore)
		if(removed != ""):
			typejerk("delete")
			spawnletter(locatecursor(), removed)
		analyze_input(what_added(linebefore))
		queue_check = false
		linebefore = lineafter
	
	$StartTextPosition/Cursor.position = locatecursor()
	y_was = TextEditWindow.cursor_get_line()
	#var line = TextEditWindow.get_line_count()
	#TextEditWindow.cursor_set_line(line)

func _on_text_modified():
	is_file_modified = true

func get_flash_color(idx):
	return ColorN(flash_colors[idx], 1)

func get_random_flash_color():
	return ColorN(flash_colors[randi() % flash_colors.size()], 1)

#loads syntax from file, replace the "\\syntax.txt" by any other file name with syntax in it
#if you dont want the user to acces this file add it to the games folder and replace the OS.get_exec.. with a "res://" then add filename
func loadsyntax():
	var info = File.new()
	TextEditWindow.clear_colors()
	var baseExecFolder = OS.get_executable_path().get_base_dir()
	
	#In-editor load from project folder
	if OS.has_feature("debug"):
		baseExecFolder = "res://TEXTREME"
	
	info.open(baseExecFolder + "/Syntax/{ext}-syntax.txt".format({"ext":file_ext}), info.READ)
	
	if !info.is_open():
		printerr("Failed to load custom syntax!")
		return
		
	while !info.eof_reached():
		var infoarray = info.get_csv_line()
		if infoarray.size() >= 2:
			TextEditWindow.add_keyword_color(infoarray[0], Color(infoarray[1]))
	
	info.close()

func _load_file():
	load_dialog.popup_centered()

#saves given text to a given file
func _save_text_to_file(text : String, file_name : String):
	var file := File.new()
	file.open(file_name, file.WRITE)
	
	if file.is_open():
		set_new_file_name(file_name)
		set_new_is_file_modified(false)
		does_saved_file_exist = true
		file.store_string(text)
		file.close()
		loadsyntax()
	else:
		printerr("Failed to save the file!")
	

func _get_text_from_file(file_name : String):
	var file := File.new()
	
	file.open(file_name, file.READ)
	
	if file.is_open():
		var content := file.get_as_text()
		set_new_file_name(file_name)
		set_new_is_file_modified(false)
		does_saved_file_exist = true
		file.close()
		loadsyntax()
		return content
	else:
		set_new_file_name("Untitled")
		set_new_is_file_modified(false)
		does_saved_file_exist = false
		return ""

#When save dialog is confirmed
func _on_file_save_confirmed(file_name : String):
	_save_text_to_file(TextEditWindow.text, file_name)
	does_saved_file_exist = true
	TextEditWindow.grab_focus()

func _save_file_as():
	save_dialog.popup_centered()

func _save_file():
	if does_saved_file_exist:
		_save_text_to_file(TextEditWindow.text, current_file_name)
	else:
		_save_file_as()

#When load dialog is confirmed
func _on_file_load_confirmed(file_name : String):
	TextEditWindow.text = _get_text_from_file(file_name)
	TextEditWindow.grab_focus()

func _set_bpm():
	bpm_dialog.popup_centered()

func _on_bpm_confirmed(bpm : String):
	RythmControl.set_bpm(int(bpm))

func process_key(recoilAngle, keytime, keyoff, flashcolor, flashtime, sound, soundVolume, funcname, cursoroffset=Vector2()):
	$EffectManager.recoil(Vector2(1,0).rotated(recoilAngle),keytime,keyoff)
	$EffectManager.flash(flashcolor,black,flashtime)
	sound.volume_db = soundVolume
	sound.play()
	
	if funcname != "nofunc":
		funcref(self, funcname).call_func(locatecursor()+cursoroffset)

#Function used to organize all buttonpress effects, receives the name of the effect, then executes it
func typejerk(type):
	match type:
		"other":
			process_key(rand_range(0,TAU), keytimeother, keyoffother, 
						get_random_flash_color(), flashtimeother, $Keystroke, -8, "spawnsparks")
		"space":
			process_key(rand_range(0,TAU), keytimespace, keyoffspace, 
						get_random_flash_color(), flashtimespace, $Keystroke, -5, "nofunc")
		"enter":
			process_key(rand_range(-PI*0.25,PI*0.25), keytimeenter, keyoffenter, 
						get_flash_color(6), flashtimeenter, $Ding, -5, "spawnflash")
		"delete":
			process_key(rand_range(-PI*0.25,PI*0.25)+PI/2, keytimedelete, keyoffdelete, 
						get_flash_color(1), flashtimedelete, $Keystroke, -8, "nofunc", charsize*Vector2(1,0))
		"repeat":
			process_key(rand_range(0,TAU), 0.05, 1, 
						get_random_flash_color(), 0.05, $Keystroke, -15, "spawnsparks")
		"dot":
			process_key(0.1,0.05,5, 
						get_random_flash_color(),0.2, $Keystroke, 0, "spawndoteffects")
		"dash":
			process_key(rand_range(-PI*0.25,PI*0.25)-PI*0.5, 0.2, 4, 
						get_random_flash_color(), 0.2, $Keystroke, -5, "spawndasheffects")
		"exclamation":
			process_key(0.2,0.05,8, 
						get_random_flash_color(), 0.2, $Keystroke, 0, "spawnexclamation")
		"question":
			process_key(0.2,0.05,8, 
						get_random_flash_color(), 0.2, $Keystroke, 0, "spawnquestion")

#input handler, all events are read top to bottom, please avoid triggering 2 effects in a single frame
#btw, no adequate human types 2 characters per frame, dont worry about it
#custom names for keys presses or combos of such are made in [project > input map]
func _input(event):
	if event is InputEventKey:
		if event.is_action("editor_save") && Input.is_action_just_pressed("editor_save"):
			_save_file()
		elif event.is_action("editor_save_as") && Input.is_action_just_pressed("editor_save_as"):
			_save_file_as()
		elif event.is_action("editor_load") && Input.is_action_just_pressed("editor_load"):
			_load_file()
		elif event.is_action("editor_set_bpm") && Input.is_action_just_pressed("editor_set_bpm"):
			_set_bpm()
		elif event.is_action("editor_line_wrap") && Input.is_action_just_pressed("editor_line_wrap"):
			TextEditWindow.wrap_enabled = !TextEditWindow.wrap_enabled
		elif event.pressed && TextEditWindow.has_focus():
			if event.is_action("enter"):
				typejerk("enter")
			else:
				queue_check = true
			
			if $UIBase/RhythmControl.get_is_active():
				if $UIBase/RhythmControl.is_hitting():
					spawnhitconfirm()
				else:
					spawnhitfail()

func analyze_input(input):
	if input != "":
		match input:
			".": typejerk("dot")
			"-": typejerk("dash")
			"!": typejerk("exclamation")
			"?": typejerk("question")
			" ": typejerk("space")
			_: typejerk("other")

#its a miracle that this thing even works, touch at your own risk
#to work properly, the Position2D node must be placed at the top-leftmost pixel of the first character in TextEditWindow
#also the charsize must be accurate
func locatecursor():
	var cursorpos = Vector2(TextEditWindow.cursor_get_column()-TextEditWindow.get_child(0).value/charsize.x,
							TextEditWindow.cursor_get_line()-TextEditWindow.get_child(1).value)
	var linetext = TextEditWindow.get_line(TextEditWindow.cursor_get_line())
	
	linetext = linetext.left(TextEditWindow.cursor_get_column())
	#"\t" is basically TAB, this is a fix that counts tab as 4 characters instead of 1
	while linetext.find("\t",0) != -1:
		linetext.erase(linetext.find("\t",0), 1)
		cursorpos.x +=3
	cursorpos *= charsize
	if lastlineheight < TextEditWindow.get_child(1).value:
		lastlineheight = TextEditWindow.get_child(1).value
		cursorpos.y -= charsize.y
	return cursorpos

#to keep the effects function clean and neat all of the function that spawn in a node with and effects are stored here

func spawnflash(position):
	var flash = preload("res://Effects\\flash.tscn").instance()
	StartTextPosition.add_child(flash);
	position.y += charsize.y*1.5
	flash.rect_size.x = StartTextPosition.global_position.x + $UIBase.rect_size.x
	flash.rect_position.y = position.y - StartTextPosition.global_position.y
	flash.rect_position.x = -StartTextPosition.global_position.x

func spawnsparks(position):
	var sparkler = preload("res://Effects\\sparkler.tscn").instance()
	StartTextPosition.add_child(sparkler)
	position.x += charsize.x*1.5
	position.y += charsize.y
	sparkler.global_position = position + StartTextPosition.global_position

func spawndoteffects(position):
	var explosion = preload("res://Effects\\dot.tscn").instance()
	StartTextPosition.add_child(explosion)
	position.y += charsize.y*0.75
	position.x += charsize.x*0.5
	explosion.global_position = position + StartTextPosition.global_position

func spawndasheffects(position):
	var dash = preload("res://Effects\\dash.tscn").instance()
	StartTextPosition.add_child(dash)
	position.y += charsize.y*0.5
	position.x += charsize.x*0.5
	dash.global_position = position + StartTextPosition.global_position

func spawnexclamation(position):
	var exclamation = preload("res://Effects\\exclamationmark.tscn").instance()
	StartTextPosition.add_child(exclamation)
	position.y += charsize.y*0.5
	position.x += charsize.x*0.5
	exclamation.global_position = position + StartTextPosition.global_position

func spawnquestion(position):
	var question = preload("res://Effects\\questionmark.tscn").instance()
	StartTextPosition.add_child(question)
	position.y += charsize.y*0.5
	position.x += charsize.x*0.5
	question.global_position = position + StartTextPosition.global_position

func spawnletter(position, text):
	var cross = preload("res://Effects\\cross.tscn").instance()
	StartTextPosition.add_child(cross)
	position.y += charsize.y*0.5
	position.x += -charsize.x*0.5
	cross.letter = text
	cross.global_position = position + StartTextPosition.global_position

func spawnhitconfirm():
	var confirm = preload("res://Effects\\hit confirm.tscn").instance()
	StartTextPosition.add_child(confirm)
	confirm.global_position = RythmControl.get_node("center").global_position
	confirm.scale = RythmControl.rect_scale
	confirm.modulate = RythmControl.modulate

func spawnhitfail():
	var fail = preload("res://Effects\\fail.tscn").instance()
	StartTextPosition.add_child(fail)
	fail.global_position = RythmControl.get_node("center").global_position
	fail.scale = RythmControl.rect_scale
	fail.modulate = RythmControl.modulate

func what_added(linebefore):	
	if linebefore.is_subsequence_of(lineafter) && !lineafter.is_subsequence_of(linebefore) && y_was == TextEditWindow.cursor_get_line():
		if lineafter.length() <= 0:
			print("i fucked up")
			return ""
		elif lineafter.length() == 1:
			return lineafter
		else:
			return lineafter[TextEditWindow.cursor_get_column()-1]
	else:
		return ""
		

func what_removed(linebefore):
	var cursorpos = Vector2(TextEditWindow.cursor_get_column()-TextEditWindow.get_child(0).value/charsize.x,TextEditWindow.cursor_get_line()-TextEditWindow.get_child(1).value)
	
	if lineafter.is_subsequence_of(linebefore) && !linebefore.is_subsequence_of(lineafter) && y_was == TextEditWindow.cursor_get_line():
		if linebefore.length() == 1:
			return linebefore
		else:
			return linebefore[TextEditWindow.cursor_get_column()]
	else:
		return ""
	
	