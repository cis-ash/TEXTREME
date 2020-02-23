extends TextEdit

signal on_characters_added(string, positions, position_before_first, font, is_repeated)
signal on_characters_removed(string, positions, position_before_first, font, is_repeated)

export var time_until_repeat_buffer_reset := 1 / 15.0
export var const_up_margin := 0
export var const_down_margin := 0
export var const_left_margin := 0
export var const_right_margin := 0
export var const_line_spacing := 3

onready var reset_buffer_timer : Timer = $ResetBuffers

onready var current_font : Font = get_font("font")
onready var current_line_height : int = _get_line_height()

#var saved_wraped_result : WrapResult = null

var old_line_count_log_10 := 0
var old_text := ""

var previous_added := ""
var previous_removed := ""

func _reset_previous_buffers():
	previous_added = ""
	previous_removed = ""
	

func update_prev():
	old_text = text

func update_editor_font_parameters():
	current_line_height = _get_line_height()
	char_width_buffer.clear()
	_update_wrap()

#_get_*_ margin set of functions need to be implemented correctly to support custom themes
#for now these implementations will do
func _get_up_margin() -> int:
	return const_up_margin

func _get_down_margin() -> int:
	return const_down_margin

func _get_left_margin() -> int:
	return const_left_margin

func _get_right_margin() -> int:
	return const_right_margin

func _get_line_spacing() -> int:
	return const_line_spacing

func _get_line_height() -> float:
	return current_font.get_height() + _get_line_spacing()

#returns the text capacity of one line when wrapped
func _get_wrap_at() -> float:
	return rect_size.x - _get_right_margin() - _get_left_margin() - 10.0 - _get_line_start_x_offset()

func _is_symbol(character : String):
	assert(character.length() == 1)
	
	var c := character
	
	return c != '_' && ((c >= '!' && c <= '/') || (c >= ':' && c <= '@') || (c >= '[' && c <= '`') || (c >= '{' && c <= '~') || c == '\t' || c == ' ');

#Returns amount of spaces before the line starts
func _get_indent_level(string : String, start : int) -> int:
	
	var tab_count := 0;
	var whitespace_count := 0;
	var line_length := string.length();
	for i in range(start, line_length):
		if string[i] == '\t':
			tab_count += 1
		elif string[i] == ' ':
			whitespace_count += 1
		else:
			break
		
	
	return tab_count * 4 + whitespace_count;

var char_width_buffer := {}

#Returns character width + kerning with the next character 
func _get_char_width(string : String, c : int, next_c : int, px : int) -> int:
	
	var next_s : String = string[next_c] if next_c < string.length() else ""
	var desired_string := string[c] + next_s
	if char_width_buffer.has(desired_string):
		return char_width_buffer[desired_string]
	
	var w := 0

	if string[c] == '\t':
		var tab_w : int = _get_string_size(" ").x * 4
		
		var left := px % tab_w
		if left == 0:
			w = tab_w
		else:
			w = tab_w - px % tab_w
	else:
		w = _get_string_size(desired_string).x - _get_string_size(next_s).x
		char_width_buffer[desired_string] = w
	
	return w

func _get_font() -> Font:
	return current_font

const tab_mod_pos_to_space_str := ["    ", "   ", "  ", " "]

func _get_string_size(string : String) -> Vector2:
	var actual_string := ""
	for i in string:
		if i == "\t":
			actual_string += tab_mod_pos_to_space_str[actual_string.length() % 4]
		else:
			actual_string += i
	
	return current_font.get_string_size(actual_string)

func _get_line_start_x_offset() -> float:
	
	var width : float = 0.0
	
	if show_line_numbers:
		#This code is basically a stripped copy of godots source
		
		var line_count : int = get_line_count()
		
		while line_count > 0:
			width += 1
			line_count /= 10
		
		width += 1
		
		width *= _get_string_size("0").x
	
	width += _get_left_margin()
	
	return width

func _find_caret_data(string : String, caret_line : int, caret_column : int) -> Array:
	
	var absolute_caret := 0
	var line_caret := 0
	var current_line := 0
	
	#Finds where carret is in the get_text string
	for i in range(string.length()):
		if current_line != caret_line:
			if string[i] == "\n":
				current_line += 1
			absolute_caret += 1
		else:
			if line_caret == caret_column:
				break
			absolute_caret += 1
			line_caret += 1
	
	var c := string[absolute_caret - 1] if absolute_caret != 0 else ""
	var position := Vector2(0, current_line_height)
	
	if absolute_caret != 0:
		if wrap_enabled:
			var wraped_result := wrap_string(string)
			position = wraped_result.text_positions[absolute_caret - 1]
		else:
			var result := find_unwraped_text_positions(string)
			position = result[absolute_caret - 1]
	
	position.x += _get_line_start_x_offset()
	position = get_global_transform() * _correct_position(position)

	return [position, c]

enum {
	VISIBLE_ABSOLUTELY,
	VISIBLE_AT_ALL
}

func _is_string_visible_global(string : String, position : Vector2, check_type : int = VISIBLE_AT_ALL) -> bool:
	
	var size := _get_string_size(string)
	var coord := size
	
	var global_coord = coord
	
#	print(global_coord, " ", position)
	
	var check_rect := Rect2()
	check_rect.position = (get_global_transform().inverse() * (position - global_coord)) + get_rect().position
	check_rect.end = (get_global_transform().inverse() * position) + get_rect().position
#
#	$ColorRect.set_begin(check_rect.position) # get_global_transform().inverse() * 
#	$ColorRect.set_end(check_rect.end)
#
#	print(get_rect())

	if check_type == VISIBLE_AT_ALL:
		return get_rect().intersects(check_rect)
	elif check_type == VISIBLE_ABSOLUTELY:
		return get_rect().encloses(check_rect)
	else:
		printerr("Unknown visibily type")
		return false
	

#Return struct
class WrapResult:
	var height : float
	var text_positions : PoolVector2Array
	

#Helper function
func _append_source_to_buffer_with_offset(buffer : Array, source : Array, offset : int, start_idx : int):
	for i in range(source.size()):
		buffer[i + start_idx] = source[i] + offset
	

#Helper function
func _push_into_buffer_n(buffer : Array, source : int, times : int, start_idx : int):
	for i in range(times):
		buffer[start_idx + i] = source

#func _get_saved_wrap_current_text() -> WrapResult:
#	if saved_wraped_result == null:
#		saved_wraped_result = wrap_string(text)
#		return saved_wraped_result
#	else:
#		return saved_wraped_result

var saved_wraps := {}

func wrap_string(string : String) -> WrapResult:
	
	if saved_wraps.has(string):
		return saved_wraps[string]
	
	var result := WrapResult.new()
	var text_x_px := []
	var text_y_px := []
	
	var next_available_x := 0
	var next_available_y := 0
	
	text_x_px.resize(string.length())
	text_y_px.resize(string.length())
	
	
	var px : int = 0;
	var col : int = 0;
	var line_text : String = string;
	
	var word_px : int = 0;
	var word_buffer := []
	
	var cur_wrap_index : int = 0;
	var cur_line_height : int = 1
	
	var wrap_at := _get_wrap_at()
	var space_size := _get_string_size(" ").x
	
	var tab_offset_px := _get_indent_level(string, 0) * _get_string_size(" ").x;
	if tab_offset_px >= wrap_at:
		tab_offset_px = 0;
	
	var indent_ofs : int = 0
	
	while col < line_text.length():
		var c := string[col];
		var w : int = _get_char_width(string, col, col + 1, px + word_px)
		
		indent_ofs = (tab_offset_px if cur_wrap_index != 0 else 0);
		
		if c == "\n":
			_append_source_to_buffer_with_offset(text_x_px, word_buffer, indent_ofs + px, next_available_x)
			_push_into_buffer_n(text_y_px, cur_line_height * current_line_height, word_buffer.size(), next_available_y)
			
			next_available_x += word_buffer.size()
			next_available_y += word_buffer.size()
			
			cur_line_height += 1
			
			text_x_px[next_available_x] = _get_string_size("\n").x
			text_y_px[next_available_y] = cur_line_height * current_line_height
			next_available_x += 1
			next_available_y += 1
			
			cur_wrap_index = 0
			px = 0
			word_buffer = []
			word_px = 0
			
			tab_offset_px = _get_indent_level(string, col + 1) * space_size;
			if tab_offset_px >= wrap_at:
				tab_offset_px = 0;
			
		elif indent_ofs + word_px + w > wrap_at:
			_append_source_to_buffer_with_offset(text_x_px, word_buffer, indent_ofs, next_available_x)
			_push_into_buffer_n(text_y_px, cur_line_height * current_line_height, word_buffer.size(), next_available_y)
			
			next_available_x += word_buffer.size()
			next_available_y += word_buffer.size()
			
			cur_wrap_index += 1
			cur_line_height += 1
			px = 0
			
			word_px = w
			word_buffer = [w]
			
		else:
			word_px += w
			word_buffer.push_back(word_px)
			if c == ' ':
				_append_source_to_buffer_with_offset(text_x_px, word_buffer, indent_ofs + px, next_available_x)
				_push_into_buffer_n(text_y_px, cur_line_height * current_line_height, word_buffer.size(), next_available_y)
				
				next_available_x += word_buffer.size()
				next_available_y += word_buffer.size()
				
				px += word_px
				word_buffer = []
				word_px = 0
			
			if indent_ofs + px + word_px > wrap_at:
				cur_wrap_index += 1
				cur_line_height += 1
				px = 0
				
			
		
		col += 1
	
	result.height = cur_line_height * current_line_height
	
	indent_ofs = (tab_offset_px if cur_wrap_index != 0 else 0);
	
	_append_source_to_buffer_with_offset(text_x_px, word_buffer, indent_ofs + px, next_available_x)
	_push_into_buffer_n(text_y_px, cur_line_height * current_line_height, word_buffer.size(), next_available_y)
	
	var text_positions := PoolVector2Array()
	
	text_positions.resize(text_x_px.size())
	
	for i in range(text_x_px.size()):
		text_positions[i] = Vector2(text_x_px[i], text_y_px[i])
	
	result.text_positions = text_positions
	
	saved_wraps[string] = result
	
	return result

func _log_10(value : int) -> int:
	var result := 0
	while value != 0:
		value /= 10
		result += 1
	return result

#Invokes a couple of internal functions by resizing
var update_flip_flop := false
func _update_wrap():
	if update_flip_flop:
		rect_size.y += 1
	else:
		rect_size.y -= 1
	update_flip_flop = !update_flip_flop

func _ready():
	_update_wrap()
	old_line_count_log_10 = _log_10(get_line_count())
	
	reset_buffer_timer.wait_time = time_until_repeat_buffer_reset
	

#Corrects position in local space to account for scrollbars
func _correct_position(position : Vector2) -> Vector2:
	var scroll_v : ScrollBar = get_child(1)
	if scroll_v.visible:
		position.y -= scroll_v.value * current_line_height
	
	var scroll_h : ScrollBar = get_child(0)
	if scroll_h.visible:
		position.x -= scroll_h.value
	
	return position

#Needed for finding the difference between strings
func _find_prefix_idx(old_str : String, new_str : String) -> int:
	var idx := 0
	
	var min_length = min(old_str.length(), new_str.length())
	
	while (idx < min_length && old_str[idx] == new_str[idx]):
			idx += 1
	
	return idx

#Return data type
class DeltaString:
	var added : String
	var removed : String
	var prefix_end : int

#Finds the difference between strings
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
	

#Processes change when text is wrapped
func _process_wraped_delta(source : String, delta : String, signal_name : String, wrap_result : WrapResult, prefix_end : int, suffix_start : int, is_repeated : bool) -> void:
	
	if delta == "":
		return
	
	var cropped_array := PoolVector2Array()
	var cropped_string := ""
	
	var offset_to_local := Vector2(_get_line_start_x_offset(), _get_up_margin())
#	if wrap_result.text_positions.size() != 0:
#		$ColorRect.rect_position = wrap_result.text_positions[1]
#		print(wrap_result.text_positions)
	
	for i in range(source.length()):
		if i >= prefix_end && i < suffix_start:
			var id := i
			var element := wrap_result.text_positions[i] + offset_to_local
			element = get_global_transform() * _correct_position(element)
				
			if _is_string_visible_global(delta[i - prefix_end], element):
				cropped_array.push_back(element)
				cropped_string += delta[i - prefix_end]
			
	
	if cropped_string == "":
		return 
	
	var position_before_first := get_global_transform() * (offset_to_local + Vector2(0, current_line_height))
	
	if prefix_end != 0:
		var temp := wrap_result.text_positions[prefix_end - 1]
		position_before_first = get_global_transform() * (temp + offset_to_local)
		position_before_first = _correct_position(position_before_first)
	
	emit_signal(signal_name, delta, cropped_array, position_before_first, current_font, is_repeated)
	

func _process_unwraped_delta(source : String, delta : String, signal_name : String, unwraped_positions : PoolVector2Array, prefix_end : int, suffix_start : int, is_repeated : bool) -> void:
	
	if delta == "":
		return
	
	var cropped_array := PoolVector2Array()
	var cropped_string := ""
	
	var offset_to_local := Vector2(_get_line_start_x_offset(), _get_up_margin())
	
	#TODO use resize instead of pushback
	for i in range(prefix_end, suffix_start):
		var local_uncorreted := unwraped_positions[i] + offset_to_local
		var local_corrected := _correct_position(local_uncorreted)
		var element := get_global_transform() * local_corrected
		
		if _is_string_visible_global(delta[i - prefix_end], element):
				cropped_array.push_back(element)
				cropped_string += delta[i - prefix_end]
	
	if cropped_string == "":
		return
	
	var position_before_first := get_global_transform() * (offset_to_local + Vector2(0, current_line_height))
	
	if prefix_end != 0:
		var temp := unwraped_positions[prefix_end - 1]
		position_before_first = get_global_transform() * (temp + offset_to_local)
		position_before_first = _correct_position(position_before_first)
	
	emit_signal(signal_name, delta, cropped_array, position_before_first, current_font, is_repeated)

func find_unwraped_text_positions(source : String) -> PoolVector2Array:
	var result := PoolVector2Array()
	var px := 0.0
	var py : float = current_line_height
	
	for i in range(source.length()):
		var added := _get_char_width(source, i, i + 1, px)
		px += added
		if (source[i] == '\n'):
			px = 0
			py += current_line_height
		result.push_back(Vector2(px, py))
	
	return result

func _find_and_signal_difference(source_text : String, new_text : String, caret_line : int, carret_column : int) -> void:
	
	var absolute_caret := 0
	var line_caret := 0
	var current_line := 0
	
	#Finds where carret is in the get_text string
	for i in range(new_text.length()):
		if current_line != caret_line:
			if new_text[i] == "\n":
				current_line += 1
			absolute_caret += 1
		else:
			if line_caret == carret_column:
				break
			absolute_caret += 1
			line_caret += 1
	
	var suffix_start := absolute_caret
	#Finding diff
	var result := _find_added_removed(source_text, new_text, suffix_start)
	
	#checking for repeats
	var is_repeating := (result.added == previous_added && result.removed == previous_removed)
	reset_buffer_timer.stop()
	reset_buffer_timer.start()
	
	previous_added = result.added
	previous_removed = result.removed
	
	#Processing 2 main cases 
	if wrap_enabled:
		var wrap_result := wrap_string(new_text)
		
		_process_wraped_delta(new_text, result.added, "on_characters_added", wrap_result, result.prefix_end, suffix_start, is_repeating)
		
		var old_suffix_start := result.prefix_end + result.removed.length()
		
		wrap_result = wrap_string(source_text)
		
		_process_wraped_delta(source_text, result.removed, "on_characters_removed", wrap_result, result.prefix_end, old_suffix_start, is_repeating)
	else:
		
		var unwraped_result := find_unwraped_text_positions(new_text)
		
		_process_unwraped_delta(new_text, result.added, "on_characters_added", unwraped_result, result.prefix_end, suffix_start, is_repeating)
		
		var old_suffix_start := result.prefix_end + result.removed.length()
		
		unwraped_result = find_unwraped_text_positions(source_text)
		
		_process_unwraped_delta(source_text, result.removed, "on_characters_removed", unwraped_result, result.prefix_end, old_suffix_start, is_repeating)
		
	

func _fix_scrolls(current_text : String):
	var result := _find_caret_data(current_text, cursor_get_line(), cursor_get_column())

	var scroll_v : ScrollBar = get_child(1)
	
	if cursor_get_line() == get_line_count() - 1 && !_is_string_visible_global(result[1], result[0], VISIBLE_ABSOLUTELY):
		scroll_v.value += scroll_v.max_value - scroll_v.value
	_update_wrap()

func process_changed_text():
	saved_wraps.clear()
	_update_wrap()
#	prints(get_child(1).value, get_child(1).page, get_child(1).max_value, cursor_get_line())
	var current_text := get_text()
	
	_fix_scrolls(current_text)

	is_cursor_updated = true

	#Needed to sync the effects correctly
	var new_log_10 := _log_10(get_line_count())
	if old_line_count_log_10 != new_log_10:
		_update_wrap()
		old_line_count_log_10 = new_log_10
	else:
		_update_wrap()
	
	
	
	_find_and_signal_difference(old_text, current_text, cursor_get_line(), cursor_get_column())
	
	old_text = current_text

var is_cursor_updated := false
func _on_cursor_changed():
	saved_wraps.clear()
	if !is_cursor_updated:
		_fix_scrolls(get_text())
	
	is_cursor_updated = !is_cursor_updated
	pass

func _on_text_changed():
#	saved_wraped_result = null
	call_deferred("process_changed_text")
	