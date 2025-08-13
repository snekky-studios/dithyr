class_name Main
extends Node

#region Constants and Enums
enum GrayscaleMethod {
	STANDARD,
	BT709,
	BT601,
	PHOTOSHOP,
	R_CHANNEL,
	G_CHANNEL,
	B_CHANNEL,
	RG_CHANNEL,
	RB_CHANNEL,
	GB_CHANNEL
}

enum DitheringTechnique {
	NONE,
	REDUCE_ONLY,
	INTERMEDIATE,
	CONTINUOUS
}

enum DitheringAlgorithm {
	NONE,
	STANDARD,
	LINEAR,
	STUCKI
}

enum PalettePreset {
	SLS08,
	_1BIT_MONITOR_GLOW,
	MIDNIGHT_ABLAZE,
	TWILIGHT5,
	BLESSING,
	CRIMSON,
	BERRY_NEBULA,
	NEO5
}

const PalettePresetPalette : Dictionary[PalettePreset, Array] = {
	PalettePreset.SLS08 : PALETTE_SLSO8,
	PalettePreset._1BIT_MONITOR_GLOW : PALETTE_1BIT_MONITOR_GLOW,
	PalettePreset.MIDNIGHT_ABLAZE : PALETTE_MIDNIGHT_ABLAZE,
	PalettePreset.TWILIGHT5 : PALETTE_TWILIGHT5,
	PalettePreset.BLESSING : PALETTE_BLESSING,
	PalettePreset.CRIMSON : PALETTE_CRIMSON,
	PalettePreset.BERRY_NEBULA : PALETTE_BERRY_NEBULA,
	PalettePreset.NEO5 : PALETTE_NEO5,
}

const PALETTE_SLSO8 : Array[Color] = [
	Color(0.051, 0.169, 0.271),
	Color(0.125, 0.235, 0.337),
	Color(0.329, 0.306, 0.408),
	Color(0.553, 0.412, 0.478),
	Color(0.816, 0.506, 0.349),
	Color(1.0, 0.667, 0.369),
	Color(1.0, 0.831, 0.639),
	Color(1.0, 0.925, 0.839)
]

const PALETTE_1BIT_MONITOR_GLOW : Array[Color] = [
	Color(0.133, 0.137, 0.137),
	Color(0.941, 0.965, 0.941)
]

const PALETTE_MIDNIGHT_ABLAZE : Array[Color] = [
	Color(0.075, 0.008, 0.031),
	Color(0.122, 0.02, 0.063),
	Color(0.192, 0.02, 0.118),
	Color(0.275, 0.055, 0.169),
	Color(0.486, 0.094, 0.235),
	Color(0.835, 0.235, 0.416),
	Color(1.0, 0.51, 0.455)
]

const PALETTE_TWILIGHT5 : Array[Color] = [
	Color(0.161, 0.157, 0.192),
	Color(0.2, 0.247, 0.345),
	Color(0.29, 0.478, 0.588),
	Color(0.933, 0.525, 0.584),
	Color(0.984, 0.733, 0.678)
]

const PALETTE_BLESSING : Array[Color] = [
	Color(0.455, 0.337, 0.608),
	Color(0.588, 0.984, 0.78),
	Color(1.0, 0.702, 0.796),
	Color(0.847, 0.749, 0.847),
	Color(0.969, 1.0, 0.682)
]

const PALETTE_CRIMSON : Array[Color] = [
	Color(0.106, 0.012, 0.149),
	Color(0.478, 0.11, 0.294),
	Color(0.729, 0.314, 0.267),
	Color(0.937, 0.976, 0.839)
]

const PALETTE_BERRY_NEBULA : Array[Color] = [
	Color(0.051, 0.0, 0.102),
	Color(0.18, 0.039, 0.188),
	Color(0.31, 0.078, 0.275),
	Color(0.435, 0.114, 0.361),
	Color(0.431, 0.318, 0.506),
	Color(0.427, 0.522, 0.647),
	Color(0.424, 0.725, 0.788),
	Color(0.424, 0.929, 0.929)
]

const PALETTE_NEO5 : Array[Color] = [
	Color(0.055, 0.055, 0.055),
	Color(0.329, 0.2, 0.745),
	Color(0.902, 0.141, 0.686),
	Color(0.239, 0.976, 0.918),
	Color(0.937, 0.98, 0.98)
]
#endregion

var image_processor : ImageProcessor = null
var new_palette : Array[Color] = []
var grayscale_method : GrayscaleMethod = GrayscaleMethod.BT709
var dithering_technique : DitheringTechnique = DitheringTechnique.INTERMEDIATE
var dithering_algorithm : DitheringAlgorithm = DitheringAlgorithm.STANDARD

var ui : UI = null

func _ready() -> void:
	ui = %UI
	
	ui.file_open.connect(_on_file_open)
	ui.file_save.connect(_on_file_save)
	ui.process.connect(_on_process)
	ui.grayscale_method_selected.connect(_on_grayscale_method_selected)
	ui.dithering_technique_selected.connect(_on_dithering_technique_selected)
	ui.dithering_algorithm_selected.connect(_on_dithering_algorithm_selected)
	ui.palette_preset_selected.connect(_on_palette_preset_selected)
	ui.new_palette_changed.connect(_on_new_palette_changed)
	ui.apply_new_palette.connect(_on_apply_new_palette)
	
	image_processor = ImageProcessor.new()
	
	new_palette = ui.get_colors_new_palette()
	return

func _load(file_path : String) -> Image:
	var texture : Texture2D = load(file_path)
	var image : Image = texture.get_image()
	return image

func _save(image : Image, file_path : String) -> void:
	var error : Error = image_processor.image.save_png(file_path)
	assert(error == OK, "Save error: " + str(error))
	return

#region Callbacks
func _on_file_open(file_name : String) -> void:
	image_processor.reset()
	image_processor.image = _load(file_name)
	ui.set_image(image_processor.image)
	return

func _on_file_save(file_name : String) -> void:
	_save(image_processor.image, file_name)
	return

func _on_process() -> void:
	match grayscale_method:
		GrayscaleMethod.STANDARD:
			image_processor.grayscale(ImageProcessor.GRAYSCALE_STANDARD)
		GrayscaleMethod.BT709:
			image_processor.grayscale(ImageProcessor.GRAYSCALE_BT709)
		GrayscaleMethod.BT601:
			image_processor.grayscale(ImageProcessor.GRAYSCALE_BT601)
		GrayscaleMethod.PHOTOSHOP:
			image_processor.grayscale(ImageProcessor.GRAYSCALE_PHOTOSHOP)
		GrayscaleMethod.R_CHANNEL:
			image_processor.grayscale(ImageProcessor.GRAYSCALE_R_CHANNEL)
		GrayscaleMethod.G_CHANNEL:
			image_processor.grayscale(ImageProcessor.GRAYSCALE_G_CHANNEL)
		GrayscaleMethod.B_CHANNEL:
			image_processor.grayscale(ImageProcessor.GRAYSCALE_B_CHANNEL)
		GrayscaleMethod.RG_CHANNEL:
			image_processor.grayscale(ImageProcessor.GRAYSCALE_RG_CHANNEL)
		GrayscaleMethod.RB_CHANNEL:
			image_processor.grayscale(ImageProcessor.GRAYSCALE_RB_CHANNEL)
		GrayscaleMethod.GB_CHANNEL:
			image_processor.grayscale(ImageProcessor.GRAYSCALE_GB_CHANNEL)
		_:
			print("error: invalid grayscale method - ", grayscale_method)
	ui.set_image(image_processor.image)
	
	match dithering_technique:
		DitheringTechnique.NONE:
			pass
		DitheringTechnique.REDUCE_ONLY:
			image_processor.reduce_palette(new_palette.size())
			ui.set_image(image_processor.image)
		DitheringTechnique.INTERMEDIATE:
			image_processor.reduce_palette((new_palette.size() * 2) - 1)
			match dithering_algorithm:
				DitheringAlgorithm.STANDARD:
					image_processor.dither_intermediate_standard()
				DitheringAlgorithm.LINEAR:
					image_processor.dither_intermediate_linear()
				DitheringAlgorithm.STUCKI:
					image_processor.dither_intermediate_stucki()
				_:
					print("error: invalid dithering algorithm - ", dithering_algorithm)
			ui.set_image(image_processor.image)
		DitheringTechnique.CONTINUOUS:
			pass
		_:
			print("error: invalid dithering technique - ", dithering_technique)
	ui.set_image(image_processor.image)
	ui.remove_all_color_selectors_current_palette()
	ui.add_color_selector_array_current_palette(image_processor.palette)
	return

func _on_grayscale_method_selected(value : GrayscaleMethod) -> void:
	grayscale_method = value
	return

func _on_dithering_technique_selected(value : DitheringTechnique) -> void:
	dithering_technique = value
	return

func _on_dithering_algorithm_selected(value : DitheringAlgorithm) -> void:
	dithering_algorithm = value
	return

func _on_palette_preset_selected(value : PalettePreset) -> void:
	new_palette = PalettePresetPalette[value]
	ui.remove_all_color_selectors_new_palette()
	ui.add_color_selector_array_new_palette(new_palette)
	return

func _on_new_palette_changed(value : Array[Color]) -> void:
	new_palette = value
	return

func _on_apply_new_palette() -> void:
	image_processor.palette_swap(new_palette)
	ui.set_image(image_processor.image)
	ui.remove_all_color_selectors_current_palette()
	ui.add_color_selector_array_current_palette(image_processor.palette)
	return
#endregion
