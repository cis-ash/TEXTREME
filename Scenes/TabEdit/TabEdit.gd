extends Control

signal on_display_name_changed

onready var text_edit : TextEdit = $SpecialTextEdit

var current_tab_idx : int

var is_titled := false
var current_open_path := ""
var current_file_name := "UNTITLED"
var is_modified := false
var is_read_only := false

var old_focus_mode := FOCUS_NONE
var prev_is_syntax_disabled := false

func _ready():
	update_editor_syntax(current_open_path.get_extension())

func set_is_readonly(new_value : bool):
	var was_read_only := is_read_only
	is_read_only = new_value
	if is_read_only:
		old_focus_mode = text_edit.focus_mode
		text_edit.focus_mode = FOCUS_NONE
		text_edit.highlight_current_line = false
	elif was_read_only:
		text_edit.focus_mode = old_focus_mode
		text_edit.highlight_current_line = true

func on_settings_updated():
	text_edit.wrap_enabled = Config.get_setting("text_editor", "line_wrap")
	text_edit.show_line_numbers = Config.get_setting("text_editor", 
													"line_numbers")
	var is_syntax_disabled : bool = Config.get_setting("text_editor", 
													"disable_syntax")
	
	if is_syntax_disabled == prev_is_syntax_disabled:
		return
	
	prev_is_syntax_disabled = is_syntax_disabled
	
	if is_syntax_disabled:
		disable_editor_syntax()
	else:
		update_editor_syntax(current_open_path.get_extension())

func set_is_editor_enabled(is_enabled : bool):
	if !is_read_only:
		text_edit.set_is_editor_enabled(is_enabled)
	on_settings_updated()

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

func disable_editor_syntax():
	text_edit.syntax_highlighting = false

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

