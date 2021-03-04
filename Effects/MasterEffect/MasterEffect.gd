extends Node2D

class_name Effect

signal on_setup_done

var text : String
var positions : PoolVector2Array
var position_before : Vector2
var font : Font

func setup_effect(n_text : String, n_positions : PoolVector2Array, 
			n_position_before : Vector2, n_font : Font):
	
	text = n_text
	positions = n_positions
	position_before = n_position_before
	font = n_font
	
	emit_signal("on_setup_done")
