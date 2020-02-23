extends Control

signal on_display_name_changed

onready var text_edit : TextEdit = $SpecialTextEdit

var current_tab_idx : int

var is_titled := false
var current_open_path := ""
var current_file_name := "UNTITLED"
var is_modified := false

func _ready():
	update_editor_syntax(current_open_path.get_extension())

func tab_editor_grab_focus():
	text_edit.grab_focus()

func set_is_tab_editor_enabled(is_enabled : bool):
	text_edit.readonly = !is_enabled
	

func get_file_path() -> String:
	return current_open_path

func get_is_file_titled() -> bool:
	return is_titled

func get_is_file_modified() -> bool:
	return is_modified

func on_file_opened(path : String, contents : String):
	current_open_path = path
	text_edit.set_text(contents)
	text_edit.update_prev()
	is_modified = false
	is_titled = true
	current_open_path = path
	current_file_name = path.get_file()
	update_editor_syntax(current_open_path.get_extension())
	emit_signal("on_display_name_changed")

func on_file_saved(path : String) -> String:
	is_modified = false
	is_titled = true
	current_open_path = path
	current_file_name = path.get_file() 
	emit_signal("on_display_name_changed")
	update_editor_syntax(current_open_path.get_extension())
	return text_edit.get_text()

func update_editor_syntax(file_extention):
	var info := File.new()
	text_edit.clear_colors()
	var baseExecFolder := OS.get_executable_path().get_base_dir()
	
	#In-editor load from project folder
	if OS.has_feature("debug"):
		baseExecFolder = "res://TEXTREME"
	
	info.open(baseExecFolder + "/Syntax/{ext}-syntax.txt".format({"ext":file_extention}), info.READ)
	
	if !info.is_open():
		printerr("Failed to load custom syntax!")
		text_edit.syntax_highlighting = false
		return
	
	text_edit.syntax_highlighting = true
	
	while !info.eof_reached():
		var infoarray := info.get_csv_line()
		if infoarray.size() >= 2:
			text_edit.add_keyword_color(infoarray[0], Color(infoarray[1]))
	
	info.close()

func get_display_name() -> String:
	var result := current_file_name
	
	if is_modified:
		result += "*"
	
	return result

func get_editor_node() -> Node:
	return text_edit

func _on_text_modified():
	is_modified = true
	emit_signal("on_display_name_changed")

