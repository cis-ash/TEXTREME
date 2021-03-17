extends FileDialog

signal on_popup_load
signal on_popup_save

export var pop_up_offset := Vector2(0, 0)

onready var custom_line_edit : LineEdit = $SpacialLineEdit
onready var custom_path_edit : LineEdit = $SpacialLineEdit2

onready var top_bar : Control = get_vbox().get_child(0)
onready var stock_path_bar : LineEdit = top_bar.get_child(3)
onready var bottom_bar : Control = get_vbox().get_child(3)

var saved_path_caret : int = 0
var is_carret_lost := false
var original_position := Vector2()
var old_file_name := ""
var old_path := ""

func get_special_line_edits() -> Array:
	return [custom_line_edit, custom_path_edit]

func get_special_line_edit() -> Control:
	return custom_line_edit

func _disable_default_nodes():
	#Hides everything
	for i in top_bar.get_children():
		i.hide()
	
	#Shows label "Path:"
	top_bar.get_child(1).show()
	
	#Adds custom line edit
	remove_child(custom_path_edit)
	top_bar.add_child(custom_path_edit)
	top_bar.move_child(custom_path_edit, 3)
	
	#Silent Text set
	custom_path_edit.text = stock_path_bar.text
	old_path = stock_path_bar.text
	
	#Hides bottom parts
	for i in bottom_bar.get_children():
		i.hide()
	
	#Shows Label "File:"
	bottom_bar.get_child(0).show()
	
	#Adds custom line edit
	remove_child(custom_line_edit)
	
	bottom_bar.add_child(custom_line_edit)
	bottom_bar.move_child(custom_line_edit, 2)
	custom_line_edit.show()
	
	#Sets up focus for better navigation
	var file_container : Control = get_vbox().get_child(2).get_child(0)
	file_container.focus_neighbour_top = file_container.get_path_to(custom_path_edit)
	
	#Hides dialog buttons
	get_child(2).hide()
	

func _on_new_path_entered(text : String):
	stock_path_bar.text = text
	stock_path_bar.emit_signal("text_entered", text)
	is_carret_lost = true
	

func _on_path_changed(text : String):
	custom_path_edit.text = text
	custom_path_edit.emit_signal("text_changed")

func pop_up_in_rect(bounds : Rect2):
	popup()
	invalidate()
	original_position = bounds.position + pop_up_offset
	rect_position = original_position
	rect_size = bounds.size - pop_up_offset
	
	if mode == MODE_SAVE_FILE:
		top_bar.get_child(6).hide()
		emit_signal("on_popup_save")
	else:
		emit_signal("on_popup_load")
	
	get_vbox().get_child(2).get_child(0).grab_focus()
	

func _ready():
	set_process_input(false)
	call_deferred("_disable_default_nodes")
	

func _process(delta : float):
	#Makes popup scale and stay in place
	rect_position = original_position
	var parent := get_parent() as Control
	if parent != null:
		rect_size = get_parent().get_rect().size - pop_up_offset
	
	#Checks if file name has changed
	if old_file_name != get_line_edit().text:
		custom_line_edit.text = get_line_edit().text
		old_file_name = get_line_edit().text
		custom_line_edit.emit_signal("text_changed", custom_line_edit.text)
	
	#Checks if path has changed
	if old_path != stock_path_bar.text:
		custom_path_edit.text = stock_path_bar.text
		old_path = custom_path_edit.text
		custom_path_edit.emit_signal("text_changed", custom_path_edit.text)
	
	if !is_carret_lost:
		saved_path_caret = custom_path_edit.caret_position
	else:
		custom_path_edit.caret_position = saved_path_caret
		is_carret_lost = false
	

func _input(event : InputEvent):
	if event.is_action("file_selector_refresh") && event.pressed && !event.echo:
		invalidate()
	if event.is_action("file_selector_create_folder") && event.pressed && !event.echo:
		print("yes")
		if mode == MODE_SAVE_FILE:
			top_bar.get_child(6).emit_signal("pressed")
			

func on_file_name_entered(new_text : String):
	get_line_edit().text = new_text
	get_line_edit().emit_signal("text_entered", new_text)
