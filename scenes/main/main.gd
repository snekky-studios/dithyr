class_name Main
extends Node

#region Constants
enum GrayscaleMethod {
	BT709,
	BT601,
	PHOTOSHOP
}

enum DitheringTechnique {
	INTERMEDIATE,
	CONTINUOUS
}

enum DitheringAlgorithm {
	STANDARD,
	LINEAR,
	STUCKI
}

const PALETTE_CRIMSON : Array[Color] = [
	Color(0.106, 0.012, 0.149),
	Color(0.478, 0.11, 0.294),
	Color(0.729, 0.314, 0.267),
	Color(0.937, 0.976, 0.839)
]

const PALETTE_TWILIGHT : Array[Color] = [
	Color(0.161, 0.157, 0.192),
	Color(0.2, 0.247, 0.345),
	Color(0.29, 0.478, 0.588),
	Color(0.933, 0.525, 0.584),
	Color(0.984, 0.733, 0.678)
]

const PALETTE_NEO : Array[Color] = [
	Color(0.055, 0.055, 0.055),
	Color(0.329, 0.2, 0.745),
	Color(0.902, 0.141, 0.686),
	Color(0.239, 0.976, 0.918),
	Color(0.937, 0.98, 0.98)
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
#endregion

var image_processor : ImageProcessor = null
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
	
	image_processor = ImageProcessor.new()
	return

func _load(file_path : String) -> Image:
	var texture : Texture2D = load(file_path)
	var image : Image = texture.get_image()
	return image

func _save(image : Image, file_path : String) -> void:
	var error : Error = image_processor.image.save_png(file_path)
	assert(error == OK, "Save error: " + str(error))
	return

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
		GrayscaleMethod.BT709:
			image_processor.grayscale(ImageProcessor.GRAYSCALE_BT709)
		GrayscaleMethod.BT601:
			image_processor.grayscale(ImageProcessor.GRAYSCALE_BT601)
		GrayscaleMethod.PHOTOSHOP:
			image_processor.grayscale(ImageProcessor.GRAYSCALE_PHOTOSHOP)
		_:
			print("error: invalid grayscale method - ", grayscale_method)
	ui.set_image(image_processor.image)
	
	match dithering_technique:
		DitheringTechnique.INTERMEDIATE:
			image_processor.reduce_palette(7)
			ui.set_image(image_processor.image)
			match dithering_algorithm:
				DitheringAlgorithm.STANDARD:
					image_processor.dither_intermediate_standard()
				DitheringAlgorithm.LINEAR:
					image_processor.dither_intermediate_linear()
				DitheringAlgorithm.STUCKI:
					image_processor.dither_intermediate_stucki()
				_:
					print("error: invalid dithering algorithm - ", dithering_algorithm)
		DitheringTechnique.CONTINUOUS:
			pass
		_:
			print("error: invalid dithering technique - ", dithering_technique)
	ui.set_image(image_processor.image)

	image_processor.palette_swap(PALETTE_CRIMSON)
	ui.set_image(image_processor.image)
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
