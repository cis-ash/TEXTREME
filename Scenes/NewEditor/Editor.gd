extends Control

signal on_font_size_increase
signal on_font_size_decrease

export var effect_manager_path : NodePath = ""
export var effect_manager_on_text_added := ""
export var effect_manager_on_text_removed := ""
export var hint_path : NodePath = ""
export var packed_editor_scene : PackedScene = null
export var tab_left_margin := 0.0
export var tab_right_margin := 0.0

onready var tab_container : TabContainer = $ActualEditorContainer/TabContainer
onready var file_dialog : FileDialog = $ActualEditorContainer/FileDialog
onready var close_dialog : ConfirmationDialog = $ActualEditorContainer/CloseDialog

onready var more_tabs_left : TextureRect = $ActualEditorContainer/MoreTabsLeft
onready var more_tabs_right : TextureRect = $ActualEditorContainer/MoreTabsRight

var page_start_idx := 0
var are_tabs_unrolled := false

var new_tab_id = 0

var left_tab_stash := []
var right_tab_stash := []

var is_loading := false
var is_disk_action_processed := false

func _connect_effect_signals(node : Node):
	var effect_manager : Node = get_node(effect_manager_path)
	if effect_manager == null:
		return
	node.connect("on_characters_added", effect_manager, effect_manager_on_text_added)
	node.connect("on_characters_removed", effect_manager, effect_manager_on_text_removed)

func _get_side_margin() -> int:
	return tab_container.get_constant("side_margin")

func _get_header_width() -> float:
	return tab_container.rect_size.x - 2 * _get_side_margin()

func _get_tab_left_margin() -> float:
	return tab_left_margin

func _get_tab_right_margin() -> float:
	return tab_right_margin

#Gets tab width in px, idx doesnt include stashed tabs
func _get_tab_width(tab_idx : int) -> float:
	var string := tab_container.get_tab_title(tab_idx - left_tab_stash.size())
	
	#TODO finish
	var style_box := tab_container.get_stylebox("tab_bg")
	
	var string_width := tab_container.get_font("font").get_string_size(string).x
#	print(string_width)
	
	return string_width + style_box.get_minimum_size().x

func _get_current_tab_idx() -> int:
	return tab_container.current_tab + left_tab_stash.size()

func _set_current_tab_idx(new_idx : int):
	_unroll_tabs()
	tab_container.current_tab = new_idx
	_roll_tabs()
	

#Sets tabs title to display name
func _update_name(tab_idx : int) -> void:
	_unroll_tabs()
	var tab := tab_container.get_tab_control(tab_idx)
	tab_container.set_tab_title(tab_idx, tab.get_display_name())
	_roll_tabs()
	tab_container.update()
	

#Moves tabs from position to new position
func _move_tab(tab_idx : int, new_idx : int):
	_unroll_tabs()
	var tab_control := tab_container.get_tab_control(tab_idx)
	tab_container.move_child(tab_control, new_idx)
	_roll_tabs()
	

#Destroys tab without asking
func _close_tab(tab_idx : int):
	_unroll_tabs()
	var tab : Control = tab_container.get_tab_control(tab_idx)
	tab_container.remove_child(tab)
	tab.queue_free()
	_roll_tabs()

func _close_current_tab(is_handing_rolls : bool = true):
	var actual_current = tab_container.current_tab + left_tab_stash.size()
	_close_tab(tab_container.current_tab)
	
	actual_current -= 1
	if actual_current == -1:
		actual_current = 0
	
	_unroll_tabs()
	
	if tab_container.get_child_count() == 0:
		_create_new_tab()
	
	tab_container.current_tab = actual_current
	
	_roll_tabs()
	tab_container.get_current_tab_control().tab_editor_grab_focus()

func _create_new_tab() -> Control:
	_unroll_tabs()
	var new_tab : Control = packed_editor_scene.instance()
	new_tab.name = "Tab" + str(new_tab_id)
	new_tab_id += 1
	
	tab_container.add_child(new_tab)
	_connect_effect_signals(new_tab.get_editor_node())
	
#	var random_content := str(randi() % 256)
#	new_tab.on_file_opened(random_content, random_content)
	_update_name(tab_container.get_tab_count() - 1)
	new_tab.connect("on_display_name_changed", self, "_on_tab_name_changed", [new_tab])
	_roll_tabs()
	return new_tab

func _ready():
	#TODO CLI
	_create_new_tab()
	
	for i in file_dialog.get_special_line_edits():
		_connect_effect_signals(i)
	
	tab_container.get_current_tab_control().tab_editor_grab_focus()
	

func _set_is_input_enabled(is_listening : bool):
	
#	for i in tab_container.get_children():
#		i.set_is_tab_editor_enabled(is_listening)
	
	if !is_listening:
#		tab_container.mouse_filter = MOUSE_FILTER_IGNORE
		set_process(false)
	else:
#		tab_container.mouse_filter = MOUSE_FILTER_STOP
		set_process(true)
		tab_container.get_current_tab_control().tab_editor_grab_focus()
	
	
	

func _on_file_dialog_show(is_loading_new : bool):
	
	is_loading = is_loading_new
	_set_is_input_enabled(false)
	
	if get_node(hint_path) != null:
		get_node(hint_path).hide()
	
	if is_loading:
		file_dialog.mode = FileDialog.MODE_OPEN_FILE
	else:
		file_dialog.mode = FileDialog.MODE_SAVE_FILE
	
	var global_rect_pos : Vector2 = $ActualEditorContainer.get_global_rect().position
	var global_rect_size : Vector2 = $ActualEditorContainer.rect_size
	
	file_dialog.pop_up_in_rect(Rect2(global_rect_pos, global_rect_size))
	
	is_disk_action_processed = false
	

func set_is_editor_hint_visible(new_value : bool):
	if get_node(hint_path) != null:
		get_node(hint_path).visible = new_value

#TODO fix typing in help
func generic_pop_up_start(target : Popup):
	_set_is_input_enabled(false)
	set_is_editor_hint_visible(false)
	target.popup()
	target.rect_position = get_global_rect().position
	target.rect_size = rect_size

func on_generic_pop_up_finish():
	_set_is_input_enabled(true)
	set_is_editor_hint_visible(true)

func on_info_pop_up_closed():
	_set_is_input_enabled(true)

func on_file_pop_up_closed():
	
	if is_disk_action_processed:
		return
	
	_set_is_input_enabled(true)
	
	set_is_editor_hint_visible(true)
	
#	print("closed")
	

func _on_tab_name_changed(tab_control : Control):
	
	_unroll_tabs()
	var result := 0
	for i in tab_container.get_children():
		if i == tab_control:
			break
		result += 1
	
	assert(tab_container.get_tab_control(result) == tab_control)
	_roll_tabs()
	
	_update_name(result)
	
	

func _save_current_tab_to_path(path : String) -> bool:
	var file : File = File.new()
	file.open(path, File.WRITE)
	
	if !file.is_open():
		return false
	
	var actual_current_tab := _get_current_tab_idx()
	var current_tab := tab_container.get_tab_control(actual_current_tab)
	
	_unroll_tabs()
	var content : String = current_tab.on_file_saved(path)
#	_update_name(actual_current_tab)
	_roll_tabs()
	
#	tab_container.current_tab = actual_current_tab - left_tab_stash.size()
	
	file.store_string(content)
	file.close()
	
	return true

func _load_new_tab_from_path(path : String) -> bool:
	
	var file : File = File.new()
	file.open(path, File.READ)
	
	if !file.is_open():
		return false
	
	var content := file.get_as_text()
	
	file.close()
	
	var actual_current_tab := _get_current_tab_idx()
	
	_unroll_tabs()
	var new_tab = _create_new_tab()
	new_tab.on_file_opened(path, content)
	tab_container.move_child(new_tab, actual_current_tab + 1)
	tab_container.current_tab = actual_current_tab + 1
	_update_name(actual_current_tab + 1)
	_roll_tabs()
	
#	tab_container.current_tab = actual_current_tab + 1 # - left_tab_stash.size()
	
	return true

func _ask_close_permission():
	close_dialog.popup_centered()
	_set_is_input_enabled(false)

func on_file_pop_up_result(path : String):
	
	is_disk_action_processed = true
	
	var result := false
	
	var desired_position := tab_container.current_tab + left_tab_stash.size()
	
#	_unroll_tabs()
	if is_loading:
		result = _load_new_tab_from_path(path)
		desired_position += 1
	else:
		result = _save_current_tab_to_path(path)
#	_roll_tabs(desired_position)
	tab_container.current_tab = desired_position - left_tab_stash.size()
#	print(path)
	
	if !result:
		#TODO POPUP to say failed to save/load
		pass
	
	_set_is_input_enabled(true)
	

func _unroll_tabs():
	
	if are_tabs_unrolled:
		return

	are_tabs_unrolled = true
	
	var actual_idx := _get_current_tab_idx()
	
	while !left_tab_stash.empty():
		var new_child : Control = left_tab_stash.pop_back()
		tab_container.add_child(new_child)
		tab_container.move_child(new_child, 0)
	
	while !right_tab_stash.empty():
		var new_child : Control = right_tab_stash.pop_back()
		tab_container.add_child(new_child)
	
	tab_container.current_tab = actual_idx
	

#Hides extra tabs such that desired current tab is visible
func _roll_tabs(desired_current_tab : int = 0):
	
	desired_current_tab = _get_current_tab_idx()
	
	if !are_tabs_unrolled:
		return

	are_tabs_unrolled = false
	
	#sets desired tab as current left most displayed 
	if desired_current_tab < page_start_idx:
		page_start_idx = desired_current_tab
	
	var width := 0
	
	for i in range(page_start_idx, desired_current_tab + 1):
		width += _get_tab_width(i)
	
	#Reduse page from the left
	while width > _get_header_width():
		width -= _get_tab_width(page_start_idx)
		page_start_idx += 1
	
	var right_bound := desired_current_tab + 1
	
	#Increase page to the right
	while width <= _get_header_width() && right_bound < tab_container.get_tab_count():
		width += _get_tab_width(right_bound)
		right_bound += 1
	
	#Remove last tab if we took too much
	if width > _get_header_width():
		right_bound -= 1
		width -= _get_tab_width(right_bound)
	
	#Increase page to the left
	while width <= _get_header_width() && page_start_idx > 0:
		page_start_idx -= 1
		width += _get_tab_width(page_start_idx)
	
	#Decrease page if we took too much
	if width > _get_header_width():
		width -= _get_tab_width(page_start_idx)
		page_start_idx += 1
	
	var tab_amount := tab_container.get_tab_count()
	
	for i in range(page_start_idx):
		var child = tab_container.get_child(0)
		left_tab_stash.append(child)
		tab_container.remove_child(child)
	
	for i in range(tab_amount - right_bound):
		var child = tab_container.get_child(tab_container.get_child_count() - 1)
		right_tab_stash.append(child)
		tab_container.remove_child(child)
	
	tab_container.current_tab = desired_current_tab - left_tab_stash.size()
	

func _on_editor_resized():
	var current_tab := tab_container.current_tab + left_tab_stash.size()
	_unroll_tabs()
	_roll_tabs(current_tab)
	

var checked_events := [
	"editor_save",
	"editor_save_as",
	"editor_load",
	"editor_new_file",
	"editor_settings",
	"editor_help",
	"editor_select_left_tab", 
	"editor_select_right_tab",
	"editor_close_tab",
	"editor_move_tab_left",
	"editor_move_tab_right",
	"editor_increase_font_size",
	"editor_decrease_font_size",
]

func _get_total_tab_count() -> int:
	return tab_container.get_child_count() + left_tab_stash.size() + right_tab_stash.size()

func _process(delta : float):
	
	update()
	
	var any := false
	for i in checked_events:
		if Input.is_action_just_pressed(i):
			any = true
			break
	
	if !any:
		return
	
	var actual_current_tab := _get_current_tab_idx()
	var desired_current_tab := actual_current_tab
	
	if Input.is_action_just_pressed("editor_new_file"):
		var new_tab = _create_new_tab()
		_move_tab(_get_total_tab_count() - 1, actual_current_tab + 1)
		_set_current_tab_idx(actual_current_tab + 1)
	elif Input.is_action_just_pressed("editor_move_tab_right"):
		if actual_current_tab != _get_total_tab_count() - 1:
			_move_tab(actual_current_tab, actual_current_tab + 1)
			_set_current_tab_idx(actual_current_tab + 1)
	elif Input.is_action_just_pressed("editor_move_tab_left"):
		if actual_current_tab != 0:
			_move_tab(actual_current_tab, actual_current_tab - 1)
			_set_current_tab_idx(actual_current_tab - 1)
	elif Input.is_action_just_pressed("editor_select_left_tab"):
		if actual_current_tab != 0:
			_set_current_tab_idx(actual_current_tab - 1)
	elif Input.is_action_just_pressed("editor_select_right_tab"):
		if actual_current_tab != _get_total_tab_count() - 1:
			_set_current_tab_idx(actual_current_tab + 1)
	elif Input.is_action_just_pressed("editor_close_tab"):
		if tab_container.get_current_tab_control().get_is_file_modified():
			_ask_close_permission()
		else:
			_close_current_tab()
			_set_current_tab_idx(max(desired_current_tab - 1, 0))
	elif Input.is_action_just_pressed("editor_load"):
		_on_file_dialog_show(true)
	elif Input.is_action_just_pressed("editor_save_as"):
		_on_file_dialog_show(false)
	elif Input.is_action_just_pressed("editor_save"):
		var current_tab : Control = tab_container.get_current_tab_control()
		if current_tab.get_is_file_titled():
			_save_current_tab_to_path(current_tab.get_file_path())
		else:
			_on_file_dialog_show(false)
	elif Input.is_action_just_pressed("editor_help"):
		generic_pop_up_start($ActualEditorContainer/Help)
	elif Input.is_action_just_pressed("editor_increase_font_size"):
		emit_signal("on_font_size_increase")
	elif Input.is_action_just_pressed("editor_decrease_font_size"):
		emit_signal("on_font_size_decrease")
	elif Input.is_action_just_pressed("editor_settings"):
		_load_new_tab_from_path(Config.get_config_path())
	
	more_tabs_left.visible = !left_tab_stash.empty()
	more_tabs_right.visible = !right_tab_stash.empty()
	
	if is_processing():
		#Possible crash here
		tab_container.get_current_tab_control().tab_editor_grab_focus()
	