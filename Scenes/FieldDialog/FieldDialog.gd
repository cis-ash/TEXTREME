extends WindowDialog

signal on_text_entered(text)

export var query_text := "SAMPLE TEXT"
export var button_text := "B SAMPLE TEXT"
export var characters := ""
export var forbidden_texts : PoolStringArray = PoolStringArray([])
export(int, "Forbidden", "Only ones allowed") var characters_status = 0 
export var max_characters := 32

func _ready():
	$Label.text = query_text
	$ConfirmButton.text = button_text
	$LineEdit.max_length = max_characters
	
	$LineEdit.connect("gui_input", self, "_on_field_gui_input")
	$LineEdit.connect("text_changed", self, "_on_field_text_changed")
	$ConfirmButton.connect("button_down", self, "_on_text_entered")
	connect("about_to_show", self, "_pre_show_setup")

func _pre_show_setup():
	$LineEdit.text = ""
	get_node("LineEdit").call_deferred("grab_focus")

func _on_text_entered():
	var desired_text : String = $LineEdit.text.strip_edges()
	
	var is_fobidden := false
	
	for i in forbidden_texts:
		if desired_text == i:
			is_fobidden = true
			break
	
	if is_fobidden:
		printerr("Cant use {0}!".format([desired_text]))
		#TODO signal errors
	else:
		emit_signal("on_text_entered", desired_text)
	
	hide()

func _on_field_text_changed(new_text : String):
	var processed_text := ""
	var carret_pos : int = $LineEdit.caret_position
	
	if characters_status == 0:
		processed_text = new_text
		for i in characters:
			processed_text = processed_text.replace(i, "")
	else:
		for i in new_text:
			if characters.find(i) != -1:
				processed_text += i
	
	if processed_text != new_text:
		carret_pos -= 1
	
	$LineEdit.text = processed_text
	$LineEdit.caret_position = carret_pos

func _on_field_gui_input(event : InputEvent):
	if event is InputEventKey && event.scancode == KEY_ENTER:
		_on_text_entered()