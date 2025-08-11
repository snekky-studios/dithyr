class_name Main
extends Node

const DIR_INPUT : String = "res://assets/input/"
const DIR_OUTPUT : String = "res://assets/output/"
const FILE_EXTENSION : String = ".png"

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

var image : Image = null

var ui : UI = null

func _ready() -> void:
	ui = %UI
	
	ui.file_open.connect(_on_file_open)
	ui.file_save.connect(_on_file_save)
	
	#var time_start : float = Time.get_ticks_usec()
	#var file_name : String = "desert2"
	#
	#var image : Image = _load(file_name)
	#var image_grayscale : Image = image.duplicate()
	#ImageProcessor._convert_to_grayscale(image_grayscale)
	#var image_grayscale_original : Image = ImageProcessor.process_image_grayscale(image, 2)
	#_save(image_grayscale_original, file_name + "_original")
#
	#var intensity_range : Vector2 = ImageProcessor._get_intensity_range(image_grayscale)
	#
	#var image_linear_dither : Image = ImageProcessor._linear_dither(image_grayscale, 3, intensity_range)
	#_save(image_linear_dither, file_name + "_linear")
	#
	#var image_stucki_dither : Image = ImageProcessor._stucki_dither(image_grayscale, 3, intensity_range)
	#_save(image_stucki_dither, file_name + "_stucki")
	
	#var image_colors : Array[Color] = ImageProcessor.get_colors(image_grayscale_original)
	#var image_original_crimson : Image = ImageProcessor.apply_pallete(image_grayscale_original, image_colors, PALETTE_CRIMSON)
	#_save(image_original_crimson, file_name + "_original_crimson")
	#
	#var image_stucki_crimson : Image = ImageProcessor.apply_pallete(image_stucki_dither, image_colors, PALETTE_CRIMSON)
	#_save(image_stucki_crimson, file_name + "_stucki_crimson")
	
	#var time_end : float = Time.get_ticks_usec()
	#print("Time Total: ", time_end - time_start)
	return

func _load(file_path : String) -> Image:
	#var file_path : String = DIR_INPUT + file_name + FILE_EXTENSION
	var texture : Texture2D = load(file_path)
	var image : Image = texture.get_image()
	return image

func _save(image : Image, file_path : String) -> void:
	#var file_path : String = DIR_OUTPUT + file_name + FILE_EXTENSION
	#var image_grayscale_original : Image = ImageProcessor.process_image_grayscale(image, 4)
	var error : Error = image.save_png(file_path)
	assert(error == OK, "Save error: " + str(error))
	return

func _on_file_open(file_name : String) -> void:
	image = _load(file_name)
	ui.set_image(image)
	return

func _on_file_save(file_name : String) -> void:
	_save(image, file_name)
	return
