class_name ColorText
extends LineEdit

const MAX_LENGTH : int = 7 # enough for # + six digits

var color : Color = Color()

func _ready() -> void:
	text_changed.connect(_on_text_changed)
	return

func _on_text_changed(new_text : String) -> void:
	var hex : int = new_text.substr(1, MAX_LENGTH).hex_to_int()
	hex = (hex << 8) + 0xFF # add 255 to the end for full alpha
	color = Color.hex(hex)
	return
