class_name UI
extends Control

signal file_open(file_path : String)
signal file_save(file_path : String)

const COLOR_SELECTOR : PackedScene = preload("res://scenes/ui/color_selector/color_selector.tscn")

const NUM_COLOR_SELECTOR_MAX : int = 11

var color_selectors_palette : Array[ColorSelector] = []
var color_selectors_grayscale : Array[ColorSelector] = []

var label_file_open : Label = null
var label_file_save : Label = null

var vbox_container_palette : VBoxContainer = null
var vbox_container_grayscale : VBoxContainer = null

var texture_rect_image : TextureRect = null

var file_dialog_open : FileDialog = null
var file_dialog_save : FileDialog = null

func _ready() -> void:
	label_file_open = %LabelFileOpen
	label_file_save = %LabelFileSave
	vbox_container_palette = %VBoxContainerPalette
	vbox_container_grayscale = %VBoxContainerGrayscale
	texture_rect_image = %TextureRectImage
	file_dialog_open = %FileDialogOpen
	file_dialog_save = %FileDialogSave
	return




func add_color_selector_palette(color : Color = Color()) -> void:
	if(color_selectors_palette.size() >= NUM_COLOR_SELECTOR_MAX):
		return
	var color_selector : ColorSelector = COLOR_SELECTOR.instantiate()
	vbox_container_palette.add_child(color_selector)
	color_selectors_palette.append(color_selector)
	color_selector.icon_right()
	color_selector.set_color(color, false)
	return

func add_color_selector_array_palette(colors : Array[Color]) -> void:
	for color : Color in colors:
		add_color_selector_palette(color)
	return

func add_color_selector_grayscale(color : Color = Color()) -> void:
	if(color_selectors_grayscale.size() >= NUM_COLOR_SELECTOR_MAX):
		return
	var color_selector : ColorSelector = COLOR_SELECTOR.instantiate()
	vbox_container_grayscale.add_child(color_selector)
	color_selectors_grayscale.append(color_selector)
	color_selector.icon_left()
	color_selector.set_color(color, true)
	return

func add_color_selector_array_grayscale(colors : Array[Color]) -> void:
	for color : Color in colors:
		add_color_selector_grayscale(color)
	return

func remove_color_selector_palette() -> void:
	var num_colors_palette : int = color_selectors_palette.size()
	if(num_colors_palette <= 0):
		return
	color_selectors_palette[num_colors_palette - 1].queue_free()
	color_selectors_palette.resize(num_colors_palette - 1)
	return

func remove_color_selector_grayscale() -> void:
	var num_colors_grayscale : int = color_selectors_grayscale.size()
	if(num_colors_grayscale <= 0):
		return
	color_selectors_grayscale[num_colors_grayscale - 1].queue_free()
	color_selectors_grayscale.resize(num_colors_grayscale - 1)
	return

func get_colors_palette() -> Array[Color]:
	var colors : Array[Color] = []
	colors.resize(color_selectors_palette.size())
	colors.fill(Color())
	for index_colors : int in range(colors.size()):
		colors[index_colors] = color_selectors_palette[index_colors].color
	return colors

func get_colors_grayscale() -> Array[Color]:
	var colors : Array[Color] = []
	colors.resize(color_selectors_grayscale.size())
	colors.fill(Color())
	for index_colors : int in range(colors.size()):
		colors[index_colors] = color_selectors_grayscale[index_colors].color
	return colors

func set_image(image : Image) -> void:
	texture_rect_image.texture = ImageTexture.create_from_image(image)
	return

func _on_button_add_palette_color_pressed() -> void:
	add_color_selector_palette()
	return

func _on_button_remove_palette_color_pressed() -> void:
	remove_color_selector_palette()
	return

func _on_button_add_grayscale_color_pressed() -> void:
	add_color_selector_grayscale()
	return

func _on_button_remove_grayscale_color_pressed() -> void:
	remove_color_selector_grayscale()
	return

func _on_file_dialog_open_file_selected(path: String) -> void:
	label_file_open.text = path
	file_open.emit(path)
	return

func _on_file_dialog_save_file_selected(path: String) -> void:
	label_file_save.text = path
	file_save.emit(path)
	return

func _on_button_open_pressed() -> void:
	file_dialog_open.popup_centered_ratio()
	return

func _on_button_save_pressed() -> void:
	file_dialog_save.popup_centered_ratio()
	return
