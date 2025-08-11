class_name ColorSelector
extends HBoxContainer

const MAX_LENGTH : int = 7 # enough for # + six digits

var color : Color = Color()

var line_edit : LineEdit = null
var color_rect_left : ColorRect = null
var color_rect_right : ColorRect = null

func _ready() -> void:
	line_edit = %LineEdit
	color_rect_left = %ColorRectLeft
	color_rect_right = %ColorRectRight
	
	line_edit.text_changed.connect(_on_text_changed)
	return

func set_color(value : Color, locked : bool) -> void:
	color = value
	var rgba32 : int = color.to_rgba32()
	rgba32 = rgba32 >> 8 # remove alpha values from the end
	var hex_string : String = "#%0*x" % [6, rgba32] # format as a string of hex digits of minimum width 6, with a # at the beginning
	line_edit.text = hex_string
	if(locked):
		line_edit.editable = false
	color_rect_left.color = color
	color_rect_right.color = color
	return

func icon_right() -> void:
	color_rect_left.hide()
	color_rect_right.show()
	return

func icon_left() -> void:
	color_rect_left.show()
	color_rect_right.hide()
	return

func _is_valid_hex_string(string : String) -> bool:
	var regex : RegEx = RegEx.new()
	# Matches # followed by 6 hex characters (case-insensitive)
	regex.compile("^#([a-fA-F0-9]{6})")
	return regex.search(string) != null

func _on_text_changed(new_text : String) -> void:
	if(not _is_valid_hex_string(new_text)):
		return
	var hex : int = new_text.substr(1, MAX_LENGTH).hex_to_int()
	hex = (hex << 8) + 0xFF # add 255 to the end for full alpha
	color = Color.hex(hex)
	color_rect_left.color = color
	color_rect_right.color = color
	return
