class_name ColorText
extends LineEdit

const MAX_LENGTH : int = 7 # enough for # + six digits

func _ready() -> void:
	text_changed.connect(_on_text_changed)
	return

func _on_text_changed() -> void:
	if(text.length() > MAX_LENGTH):
		text = text.substr(0, MAX_LENGTH)
	return
