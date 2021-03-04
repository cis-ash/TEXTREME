extends LineEdit

signal on_characters_removed(string, positions, position_before_first, font, is_repeated)
signal on_characters_added(string, positions, position_before_first, font, is_repeated)

export var character_pixel_offset := Vector2()
export var left_content_margin := 0
export var right_content_margin := 0
export var special_characters := ""
export(String, "None", "Alphabet", "Restricted") var special_character_mode := "None"
export var time_until_repeat_buffer_reset := 1 / 15.0
export var MAX_REJECTED_AT_ONCE := 100
export var MAX_REMOVED_AT_ONCE := 100
export var MAX_ADDED_AT_ONCE := 100


var old_text := ""

var prev_added := ""
var prev_removed := ""

var is_repeating := false

onready var current_character_position : Control = $CurrentCharacterPosition
onready var reset_buffers_timer : Timer = $ResetBuffers

func _reset_previous_buffers():
	prev_added = ""
	prev_removed = ""

func _ready():
	
	connect("text_changed", self, "_on_text_changed")
	
	_update_position_debug_display() 
	
	reset_buffers_timer.wait_time = time_until_repeat_buffer_reset
	
	if !OS.has_feature("debug"):
		current_character_position.hide()
	

func _update_position_debug_display():
	current_character_position.rect_position = _get_position_from_carret(text, caret_position)

func _revese_string(string : String) -> String:
	var result := ""
	
	for i in range(string.length()):
		result += string[string.length() - 1 - i]
	
	return result

func _find_prefix_idx(old_str : String, new_str : String) -> int:
	var idx := 0
	
	var min_length = min(old_str.length(), new_str.length())
	
	while (idx < min_length && old_str[idx] == new_str[idx]):
			idx += 1
	
	return idx

func _get_string_size(string : String) -> Vector2:
	return get_font("font").get_string_size(string)

func _get_position_from_carret(string : String, carret : int) -> Vector2:
	
	var text_before = string.substr(0, carret)
	var string_size : Vector2 = _get_string_size(text_before)
	
	var result : Vector2 = Vector2(string_size.x, rect_size.y / 2)
	
	result.x += left_content_margin
	result += character_pixel_offset
	
	return result
	

func _get_character_positions(source : String, substr : String, prefix_end : int) -> PoolVector2Array:
	var idx := prefix_end
	var result := PoolVector2Array()
	while idx < source.length() && (idx - prefix_end) < substr.length():
		var current := _get_position_from_carret(source, idx + 1)
		current = get_global_transform() * current
		result.push_back(current)
		idx += 1
	return result

func _process_added(source : String, added : String, prefix_end : int):
	if added == "":
		return
	
	if added.length() > MAX_ADDED_AT_ONCE:
		added = added.substr(0, MAX_ADDED_AT_ONCE)
	
	var result := _get_character_positions(source, added, prefix_end)
	
	var position_before_first = _get_position_from_carret(source, prefix_end)
	
	position_before_first = get_global_transform() * position_before_first
	
	emit_signal("on_characters_added", added, result, position_before_first, get_font("font"), is_repeating)

func _process_removed(source : String, removed : String, prefix_end : int):
	if removed == "":
		return
	
	if removed.length() > MAX_REMOVED_AT_ONCE:
		removed = removed.substr(0, MAX_REMOVED_AT_ONCE)
	
	var result := _get_character_positions(source, removed, prefix_end)
	
	var position_before_first = _get_position_from_carret(source, prefix_end)
	
	position_before_first = get_global_transform() * position_before_first
	
	emit_signal("on_characters_removed", removed, result, position_before_first, get_font("font"), is_repeating)

func _process_rejected(source : String, rejected : String, prefix_end : int):
	_process_removed(source, rejected, prefix_end)

func _process_not_enough_space(source : String, destroyed : String, prefix_end : int):
	_process_removed(source, destroyed, prefix_end)

func _find_added_removed(source_text : String, new_text : String, caret : int) -> DeltaString:
	var new_suffix_start := caret
	
	var new_pre_suffix := new_text.substr(0, new_suffix_start)
	
	var all_prefix_end := _find_prefix_idx(source_text, new_pre_suffix)
	
	var added_text := new_text.substr(all_prefix_end, new_suffix_start - all_prefix_end)
	
	if new_text.length() > source_text.length() && added_text == "":
		var delta_length := new_text.length() - source_text.length()
		added_text = new_text.substr(all_prefix_end, delta_length)
		all_prefix_end = new_suffix_start - delta_length
	
	var old_suffix_length := new_text.length() - added_text.length() - (all_prefix_end)
	
	var old_suffix_start := source_text.length() - old_suffix_length
	
	var removed_text := source_text.substr(all_prefix_end, old_suffix_start - all_prefix_end)
	
	var result := DeltaString.new()
	
	result.added = added_text
	result.removed = removed_text
	result.prefix_end = all_prefix_end
	
	return result
	

class SanitizedString:
	var content : String = ""
	var removed : int = 0

func _process_updated_text(source_text : String, new_text : String, caret : int) -> SanitizedString:
	var cleaned_string := SanitizedString.new();
	var rejected := []
	match special_character_mode:
		"Alphabet":
			var idx := 0
			for i in new_text:
				if special_characters.find(i) != -1:
					cleaned_string.content += i
				else:
					rejected.append([i, idx])
					cleaned_string.removed += 1
				idx += 1
		"Restricted":
			var idx := 0
			for i in new_text:
				if special_characters.find(i) == -1:
					cleaned_string.content += i
				else:
					rejected.append([i, idx])
					cleaned_string.removed += 1
				idx += 1
		"None":
			cleaned_string.content = new_text
	
	var string_size : Vector2 = get_font("font").get_string_size(cleaned_string.content) 
	
	var difference := _find_added_removed(source_text, new_text, caret)
	
	if difference.added == prev_added && difference.removed == prev_removed:
		is_repeating = true
	
	prev_added = difference.added
	prev_removed = difference.removed
	reset_buffers_timer.stop()
	reset_buffers_timer.start()
	
	if string_size.x > rect_size.x - (left_content_margin + right_content_margin):
		_process_not_enough_space(new_text, difference.added, difference.prefix_end)
		var result := SanitizedString.new()
		result.content = source_text
		result.removed = new_text.length() - source_text.length()
		is_repeating = false
		return result
	else:
		
		_process_added(new_text, difference.added, difference.prefix_end)
		_process_removed(source_text, difference.removed, difference.prefix_end)
		
		var count := 0
		for i in rejected:
			_process_rejected(new_text, i[0], i[1])
			count += 1
			if count > MAX_REJECTED_AT_ONCE:
				break
		
		is_repeating = false
		
		return cleaned_string
	

class DeltaString:
	var added : String
	var removed : String
	var prefix_end : int

func _on_text_changed(new_text : String):
	
	var actual_carret := caret_position
	
	if !has_focus():
		var inverted_suffix_prestart := _find_prefix_idx(_revese_string(old_text), _revese_string(new_text))
		var suffix_prestart := new_text.length() - 1 - inverted_suffix_prestart
		var suffix_start := suffix_prestart + 1
		actual_carret = suffix_start
	
	var result := _process_updated_text(old_text, new_text, actual_carret)
	
	new_text = result.content
	
#	print(actual_carret, result)
	
#	var difference := _find_added_removed(old_text, new_text, caret_position)
	
	var saved_caret = caret_position - result.removed
	
	old_text = new_text
	text = new_text
	caret_position = saved_caret
	
#	_process_added(difference.added, difference.prefix_end)
#	_process_removed(difference.removed, difference.prefix_end)
	
	_update_position_debug_display()

func _input(event : InputEvent):
	if event is InputEventKey:
		if event.scancode in [KEY_RIGHT, KEY_LEFT, KEY_UP, KEY_DOWN]:
			_update_position_debug_display()