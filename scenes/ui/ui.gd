class_name UI
extends Control

signal file_open(file_path : String)
signal file_save(file_path : String)
signal process
signal grayscale_method_selected(value : Main.GrayscaleMethod)
signal dithering_technique_selected(value : Main.DitheringTechnique)
signal dithering_algorithm_selected(value : Main.DitheringAlgorithm)

const COLOR_SELECTOR : PackedScene = preload("res://scenes/ui/color_selector/color_selector.tscn")

const NUM_COLOR_SELECTOR_MAX : int = 11

const INDEX_GRAYSCALE_METHOD_BT709 : int = 0
const INDEX_GRAYSCALE_METHOD_BT601 : int = 1
const INDEX_GRAYSCALE_METHOD_PHOTOSHOP : int = 2

const INDEX_DITHERING_TECHNIQUE_INTERMEDIATE : int = 0
const INDEX_DITHERING_TECHNIQUE_CONTINUOUS : int = 1

const INDEX_DITHERING_ALGORITHM_STANDARD : int = 0
const INDEX_DITHERING_ALGORITHM_LINEAR : int = 0
const INDEX_DITHERING_ALGORITHM_STUCKI : int = 0

var color_selectors_new_palette : Array[ColorSelector] = []
var color_selectors_current_palette : Array[ColorSelector] = []

var label_file_open : Label = null
var label_file_save : Label = null

var vbox_container_new_palette : VBoxContainer = null
var vbox_container_current_palette : VBoxContainer = null

var texture_rect_image : TextureRect = null

var panel_container_options : PanelContainer = null

var file_dialog_open : FileDialog = null
var file_dialog_save : FileDialog = null

func _ready() -> void:
	label_file_open = %LabelFileOpen
	label_file_save = %LabelFileSave
	vbox_container_new_palette = %VBoxContainerNewPalette
	vbox_container_current_palette = %VBoxContainerCurrentPalette
	texture_rect_image = %TextureRectImage
	panel_container_options = %PanelContainerOptions
	file_dialog_open = %FileDialogOpen
	file_dialog_save = %FileDialogSave
	return

func add_color_selector_new_palette(color : Color = Color()) -> void:
	if(color_selectors_new_palette.size() >= NUM_COLOR_SELECTOR_MAX):
		return
	var color_selector : ColorSelector = COLOR_SELECTOR.instantiate()
	vbox_container_new_palette.add_child(color_selector)
	color_selectors_new_palette.append(color_selector)
	color_selector.icon_right()
	color_selector.set_color(color, false)
	return

func add_color_selector_array_new_palette(colors : Array[Color]) -> void:
	for color : Color in colors:
		add_color_selector_new_palette(color)
	return

func add_color_selector_current_palette(color : Color = Color()) -> void:
	if(color_selectors_current_palette.size() >= NUM_COLOR_SELECTOR_MAX):
		return
	var color_selector : ColorSelector = COLOR_SELECTOR.instantiate()
	vbox_container_current_palette.add_child(color_selector)
	color_selectors_current_palette.append(color_selector)
	color_selector.icon_left()
	color_selector.set_color(color, true)
	return

func add_color_selector_array_grayscale(colors : Array[Color]) -> void:
	for color : Color in colors:
		add_color_selector_current_palette(color)
	return

func remove_color_selector_palette() -> void:
	var num_colors_palette : int = color_selectors_new_palette.size()
	if(num_colors_palette <= 0):
		return
	color_selectors_new_palette[num_colors_palette - 1].queue_free()
	color_selectors_new_palette.resize(num_colors_palette - 1)
	return

func remove_color_selector_grayscale() -> void:
	var num_colors_grayscale : int = color_selectors_current_palette.size()
	if(num_colors_grayscale <= 0):
		return
	color_selectors_current_palette[num_colors_grayscale - 1].queue_free()
	color_selectors_current_palette.resize(num_colors_grayscale - 1)
	return

func get_colors_palette() -> Array[Color]:
	var colors : Array[Color] = []
	colors.resize(color_selectors_new_palette.size())
	colors.fill(Color())
	for index_colors : int in range(colors.size()):
		colors[index_colors] = color_selectors_new_palette[index_colors].color
	return colors

func get_colors_grayscale() -> Array[Color]:
	var colors : Array[Color] = []
	colors.resize(color_selectors_current_palette.size())
	colors.fill(Color())
	for index_colors : int in range(colors.size()):
		colors[index_colors] = color_selectors_current_palette[index_colors].color
	return colors

func set_image(image : Image) -> void:
	texture_rect_image.texture = ImageTexture.create_from_image(image)
	return

func _on_button_add_new_palette_color_pressed() -> void:
	add_color_selector_new_palette()
	return

func _on_button_remove_new_palette_color_pressed() -> void:
	remove_color_selector_palette()
	return

func _on_button_add_current_palette_color_pressed() -> void:
	add_color_selector_current_palette()
	return

func _on_button_remove_current_palette_color_pressed() -> void:
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

func _on_button_options_pressed() -> void:
	panel_container_options.show()
	return

func _on_button_process_pressed() -> void:
	process.emit()
	return

func _on_button_save_pressed() -> void:
	file_dialog_save.popup_centered_ratio()
	return

func _on_option_button_grayscale_item_selected(index: int) -> void:
	match index:
		INDEX_GRAYSCALE_METHOD_BT709:
			grayscale_method_selected.emit(Main.GrayscaleMethod.BT709)
		INDEX_GRAYSCALE_METHOD_BT601:
			grayscale_method_selected.emit(Main.GrayscaleMethod.BT601)
		INDEX_GRAYSCALE_METHOD_PHOTOSHOP:
			grayscale_method_selected.emit(Main.GrayscaleMethod.PHOTOSHOP)
	return

func _on_option_button_dithering_technique_item_selected(index: int) -> void:
	match index:
		INDEX_DITHERING_TECHNIQUE_INTERMEDIATE:
			dithering_technique_selected.emit(Main.DitheringTechnique.INTERMEDIATE)
		INDEX_DITHERING_TECHNIQUE_CONTINUOUS:
			dithering_technique_selected.emit(Main.DitheringTechnique.CONTINUOUS)
	return

func _on_option_button_dithering_algorithm_item_selected(index: int) -> void:
	match index:
		INDEX_DITHERING_ALGORITHM_STANDARD:
			dithering_algorithm_selected.emit(Main.DitheringAlgorithm.STANDARD)
		INDEX_DITHERING_ALGORITHM_LINEAR:
			dithering_algorithm_selected.emit(Main.DitheringAlgorithm.LINEAR)
		INDEX_DITHERING_ALGORITHM_STUCKI:
			dithering_algorithm_selected.emit(Main.DitheringAlgorithm.STUCKI)
	return

func _on_button_options_ok_pressed() -> void:
	panel_container_options.hide()
	return
