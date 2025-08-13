class_name UI
extends Control

signal file_open(file_path : String)
signal file_save(file_path : String)
signal process
signal grayscale_method_selected(value : Main.GrayscaleMethod)
signal dithering_technique_selected(value : Main.DitheringTechnique)
signal dithering_algorithm_selected(value : Main.DitheringAlgorithm)
signal palette_preset_selected(value : Main.PalettePreset)
signal new_palette_changed(value : Array[Color])
signal apply_new_palette

#region Constants
const COLOR_SELECTOR : PackedScene = preload("res://scenes/ui/color_selector/color_selector.tscn")

const INDEX_GRAYSCALE_METHOD_STANDARD : int = 0
const INDEX_GRAYSCALE_METHOD_BT709 : int = 1
const INDEX_GRAYSCALE_METHOD_BT601 : int = 2
const INDEX_GRAYSCALE_METHOD_PHOTOSHOP : int = 3
const INDEX_GRAYSCALE_METHOD_R_CHANNEL : int = 4
const INDEX_GRAYSCALE_METHOD_G_CHANNEL : int = 5
const INDEX_GRAYSCALE_METHOD_B_CHANNEL : int = 6
const INDEX_GRAYSCALE_METHOD_RG_CHANNEL : int = 7
const INDEX_GRAYSCALE_METHOD_RB_CHANNEL : int = 8
const INDEX_GRAYSCALE_METHOD_GB_CHANNEL : int = 9

const INDEX_DITHERING_TECHNIQUE_NONE : int = 0
const INDEX_DITHERING_TECHNIQUE_REDUCE_ONLY : int = 1
const INDEX_DITHERING_TECHNIQUE_INTERMEDIATE : int = 2
const INDEX_DITHERING_TECHNIQUE_CONTINUOUS : int = 3

const INDEX_DITHERING_ALGORITHM_NONE : int = 0
const INDEX_DITHERING_ALGORITHM_STANDARD : int = 1
const INDEX_DITHERING_ALGORITHM_LINEAR : int = 2
const INDEX_DITHERING_ALGORITHM_STUCKI : int = 3

const INDEX_PALETTE_SLSO8 : int = 0
const INDEX_PALETTE_1BIT_MONITOR_GLOW : int = 1
const INDEX_PALETTE_MIDNIGHT_ABLAZE : int = 2
const INDEX_PALETTE_TWILIGHT5 : int = 3
const INDEX_PALETTE_BLESSING : int = 4
const INDEX_PALETTE_CRIMSON : int = 5
const INDEX_PALETTE_BERRY_NEBULA : int = 6
const INDEX_PALETTE_NEO5 : int = 7
const INDEX_PALETTE_CANCEL : int = 8
#endregion

var color_selectors_new_palette : Array[ColorSelector] = []
var color_selectors_current_palette : Array[ColorSelector] = []

#region Node Declarations
var vbox_container_new_palette : VBoxContainer = null
var vbox_container_current_palette : VBoxContainer = null

var menu_button_load : MenuButton = null

var texture_rect_image : TextureRect = null

var panel_container_options : PanelContainer = null
var option_button_grayscale : OptionButton = null
var option_button_dithering_technique : OptionButton = null
var option_button_dithering_algorithm : OptionButton = null
var panel_container_help : PanelContainer = null
var panel_container_about : PanelContainer = null

var file_dialog_open : FileDialog = null
var file_dialog_save : FileDialog = null
#endregion

func _ready() -> void:
	vbox_container_new_palette = %VBoxContainerNewPalette
	vbox_container_current_palette = %VBoxContainerCurrentPalette
	menu_button_load = %MenuButtonLoad
	texture_rect_image = %TextureRectImage
	panel_container_options = %PanelContainerOptions
	option_button_grayscale = %OptionButtonGrayscale
	option_button_dithering_technique = %OptionButtonDitheringTechnique
	option_button_dithering_algorithm = %OptionButtonDitheringAlgorithm
	panel_container_help = %PanelContainerHelp
	panel_container_about = %PanelContainerAbout
	file_dialog_open = %FileDialogOpen
	file_dialog_save = %FileDialogSave
	
	menu_button_load.get_popup().id_pressed.connect(_on_popup_menu_load_id_pressed)
	
	for index_color_selector_new_palette : int in range(ImageProcessor.PALETTE_SIZE_MIN):
		add_color_selector_new_palette()
	return

func add_color_selector_new_palette(color : Color = Color()) -> void:
	if(color_selectors_new_palette.size() >= ImageProcessor.PALETTE_SIZE_MAX):
		return
	var color_selector : ColorSelector = COLOR_SELECTOR.instantiate()
	vbox_container_new_palette.add_child(color_selector)
	color_selectors_new_palette.append(color_selector)
	color_selector.icon_right()
	color_selector.set_color(color, false)
	color_selector.color_changed.connect(_on_color_selector_color_changed)
	new_palette_changed.emit(get_colors_new_palette())
	return

func add_color_selector_array_new_palette(colors : Array[Color]) -> void:
	for color : Color in colors:
		add_color_selector_new_palette(color)
	new_palette_changed.emit(get_colors_new_palette())
	return

func add_color_selector_current_palette(color : Color = Color()) -> void:
	if(color_selectors_current_palette.size() >= ImageProcessor.PALETTE_SIZE_MAX):
		return
	var color_selector : ColorSelector = COLOR_SELECTOR.instantiate()
	vbox_container_current_palette.add_child(color_selector)
	color_selectors_current_palette.append(color_selector)
	color_selector.icon_left()
	color_selector.set_color(color, true)
	return

func add_color_selector_array_current_palette(colors : Array[Color]) -> void:
	for color : Color in colors:
		add_color_selector_current_palette(color)
	return

func remove_color_selector_new_palette() -> void:
	var num_colors_palette : int = color_selectors_new_palette.size()
	if(num_colors_palette <= ImageProcessor.PALETTE_SIZE_MIN):
		return
	color_selectors_new_palette[num_colors_palette - 1].color_changed.disconnect(_on_color_selector_color_changed)
	color_selectors_new_palette[num_colors_palette - 1].queue_free()
	color_selectors_new_palette.resize(num_colors_palette - 1)
	new_palette_changed.emit(get_colors_new_palette())
	return

func remove_all_color_selectors_new_palette() -> void:
	for index_color_selectors_new_palette : int in range(color_selectors_new_palette.size()):
		color_selectors_new_palette[index_color_selectors_new_palette].queue_free()
	color_selectors_new_palette.resize(0)
	return

func remove_color_selector_current_palette() -> void:
	var num_colors_grayscale : int = color_selectors_current_palette.size()
	if(num_colors_grayscale <= ImageProcessor.PALETTE_SIZE_MIN):
		return
	color_selectors_current_palette[num_colors_grayscale - 1].queue_free()
	color_selectors_current_palette.resize(num_colors_grayscale - 1)
	return

func remove_all_color_selectors_current_palette() -> void:
	for index_color_selectors_current_palette : int in range(color_selectors_current_palette.size()):
		color_selectors_current_palette[index_color_selectors_current_palette].queue_free()
	color_selectors_current_palette.resize(0)
	return

func get_colors_new_palette() -> Array[Color]:
	var colors : Array[Color] = []
	colors.resize(color_selectors_new_palette.size())
	colors.fill(Color())
	for index_colors : int in range(colors.size()):
		colors[index_colors] = color_selectors_new_palette[index_colors].color
	return colors

func get_colors_current_palette() -> Array[Color]:
	var colors : Array[Color] = []
	colors.resize(color_selectors_current_palette.size())
	colors.fill(Color())
	for index_colors : int in range(colors.size()):
		colors[index_colors] = color_selectors_current_palette[index_colors].color
	return colors

func set_image(image : Image) -> void:
	if(not image):
		return
	texture_rect_image.texture = ImageTexture.create_from_image(image)
	return

func close_popups() -> void:
	panel_container_options.hide()
	panel_container_help.hide()
	panel_container_about.hide()
	return

#region Callbacks
func _on_color_selector_color_changed() -> void:
	new_palette_changed.emit(get_colors_new_palette())
	return

func _on_file_dialog_open_file_selected(path: String) -> void:
	file_open.emit(path)
	return

func _on_file_dialog_save_file_selected(path: String) -> void:
	file_save.emit(path)
	return

func _on_button_open_pressed() -> void:
	close_popups()
	file_dialog_open.popup_centered_ratio()
	return

func _on_button_options_pressed() -> void:
	close_popups()
	panel_container_options.show()
	return

func _on_button_process_pressed() -> void:
	close_popups()
	process.emit()
	return

func _on_button_save_pressed() -> void:
	close_popups()
	file_dialog_save.popup_centered_ratio()
	return

func _on_button_help_pressed() -> void:
	close_popups()
	panel_container_help.show()
	return

func _on_button_about_pressed() -> void:
	close_popups()
	panel_container_about.show()
	return

func _on_option_button_grayscale_item_selected(index: int) -> void:
	match index:
		INDEX_GRAYSCALE_METHOD_STANDARD:
			grayscale_method_selected.emit(Main.GrayscaleMethod.STANDARD)
		INDEX_GRAYSCALE_METHOD_BT709:
			grayscale_method_selected.emit(Main.GrayscaleMethod.BT709)
		INDEX_GRAYSCALE_METHOD_BT601:
			grayscale_method_selected.emit(Main.GrayscaleMethod.BT601)
		INDEX_GRAYSCALE_METHOD_PHOTOSHOP:
			grayscale_method_selected.emit(Main.GrayscaleMethod.PHOTOSHOP)
		INDEX_GRAYSCALE_METHOD_R_CHANNEL:
			grayscale_method_selected.emit(Main.GrayscaleMethod.R_CHANNEL)
		INDEX_GRAYSCALE_METHOD_G_CHANNEL:
			grayscale_method_selected.emit(Main.GrayscaleMethod.G_CHANNEL)
		INDEX_GRAYSCALE_METHOD_B_CHANNEL:
			grayscale_method_selected.emit(Main.GrayscaleMethod.B_CHANNEL)
		INDEX_GRAYSCALE_METHOD_RG_CHANNEL:
			grayscale_method_selected.emit(Main.GrayscaleMethod.RG_CHANNEL)
		INDEX_GRAYSCALE_METHOD_RB_CHANNEL:
			grayscale_method_selected.emit(Main.GrayscaleMethod.RB_CHANNEL)
		INDEX_GRAYSCALE_METHOD_GB_CHANNEL:
			grayscale_method_selected.emit(Main.GrayscaleMethod.GB_CHANNEL)
	return

func _on_option_button_dithering_technique_item_selected(index: int) -> void:
	match index:
		INDEX_DITHERING_TECHNIQUE_NONE:
			option_button_dithering_algorithm.select(INDEX_DITHERING_ALGORITHM_NONE)
			dithering_technique_selected.emit(Main.DitheringTechnique.NONE)
		INDEX_DITHERING_TECHNIQUE_REDUCE_ONLY:
			option_button_dithering_algorithm.select(INDEX_DITHERING_ALGORITHM_NONE)
			dithering_technique_selected.emit(Main.DitheringTechnique.REDUCE_ONLY)
		INDEX_DITHERING_TECHNIQUE_INTERMEDIATE:
			dithering_technique_selected.emit(Main.DitheringTechnique.INTERMEDIATE)
		INDEX_DITHERING_TECHNIQUE_CONTINUOUS:
			dithering_technique_selected.emit(Main.DitheringTechnique.CONTINUOUS)
	return

func _on_option_button_dithering_algorithm_item_selected(index: int) -> void:
	match index:
		INDEX_DITHERING_ALGORITHM_NONE:
			option_button_dithering_technique.select(INDEX_DITHERING_ALGORITHM_NONE)
			dithering_algorithm_selected.emit(Main.DitheringAlgorithm.NONE)
		INDEX_DITHERING_ALGORITHM_STANDARD:
			dithering_algorithm_selected.emit(Main.DitheringAlgorithm.STANDARD)
		INDEX_DITHERING_ALGORITHM_LINEAR:
			dithering_algorithm_selected.emit(Main.DitheringAlgorithm.LINEAR)
		INDEX_DITHERING_ALGORITHM_STUCKI:
			dithering_algorithm_selected.emit(Main.DitheringAlgorithm.STUCKI)
	return

func _on_button_options_ok_pressed() -> void:
	close_popups()
	return

func _on_button_help_ok_pressed() -> void:
	close_popups()
	return

func _on_button_about_ok_pressed() -> void:
	close_popups()
	return

func _on_button_palette_add_color_pressed() -> void:
	close_popups()
	add_color_selector_new_palette()
	return

func _on_button_palette_remove_color_pressed() -> void:
	close_popups()
	remove_color_selector_new_palette()
	return

func _on_popup_menu_load_id_pressed(id : int) -> void:
	match id:
		INDEX_PALETTE_SLSO8:
			palette_preset_selected.emit(Main.PalettePreset.SLS08)
		INDEX_PALETTE_1BIT_MONITOR_GLOW:
			palette_preset_selected.emit(Main.PalettePreset._1BIT_MONITOR_GLOW)
		INDEX_PALETTE_MIDNIGHT_ABLAZE:
			palette_preset_selected.emit(Main.PalettePreset.MIDNIGHT_ABLAZE)
		INDEX_PALETTE_TWILIGHT5:
			palette_preset_selected.emit(Main.PalettePreset.TWILIGHT5)
		INDEX_PALETTE_BLESSING:
			palette_preset_selected.emit(Main.PalettePreset.BLESSING)
		INDEX_PALETTE_CRIMSON:
			palette_preset_selected.emit(Main.PalettePreset.CRIMSON)
		INDEX_PALETTE_BERRY_NEBULA:
			palette_preset_selected.emit(Main.PalettePreset.BERRY_NEBULA)
		INDEX_PALETTE_NEO5:
			palette_preset_selected.emit(Main.PalettePreset.NEO5)
		INDEX_PALETTE_CANCEL:
			pass
		_:
			print("error: invalid load palette selection - ", id)
	return

func _on_button_palette_apply_pressed() -> void:
	close_popups()
	apply_new_palette.emit()
	return
#endregion
