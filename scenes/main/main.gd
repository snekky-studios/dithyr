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

func _ready() -> void:
	var time_start : float = Time.get_ticks_usec()
	var file_name : String = "desert1"
	
	var image : Image = _load(file_name)
	var image_grayscale : Image = ImageProcessor.process_image_grayscale(image, 4)
	_save(image_grayscale, file_name + "_grayscale")
	
	var image_colors : Array[Color] = ImageProcessor.get_colors(image_grayscale)
	var image_palette : Image = ImageProcessor.apply_pallete(image_grayscale, image_colors, PALETTE_CRIMSON)
	_save(image_palette, file_name + "_crimson")
	
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
