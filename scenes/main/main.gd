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

func _ready() -> void:
	var time_start : float = Time.get_ticks_usec()
	var file_name : String = "desert2"
	
	var image : Image = _load(file_name)
	var image_grayscale : Image = ImageProcessor.process_image_grayscale(image, 8)
	_save(image_grayscale, file_name + "_grayscale")
	
	var image_colors : Array[Color] = ImageProcessor.get_colors(image_grayscale)
	var image_palette : Image = ImageProcessor.apply_pallete(image_grayscale, image_colors, PALETTE_BERRY_NEBULA)
	_save(image_palette, file_name + "_berry_nebula")
	
	var time_end : float = Time.get_ticks_usec()
	print("Time Total: ", time_end - time_start)
	return

func _load(file_name : String) -> Image:
	var file_path : String = DIR_INPUT + file_name + FILE_EXTENSION
	return load(file_path)

func _save(image : Image, file_name : String) -> void:
	var file_path : String = DIR_OUTPUT + file_name + FILE_EXTENSION
	var error : Error = image.save_png(file_path)
	assert(error == OK, "Save error: " + str(error))
	return
