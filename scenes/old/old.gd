class_name Old
extends Node

const WEIGHT_R : float = 0.2126
const WEIGHT_G : float = 0.7152
const WEIGHT_B : float = 0.0722

func _get_pixel(image_data : PackedByteArray, image_width : int, x : int, y : int) -> Color:
	var index_start : int = (x + y * image_width) * 3
	var color : Color = Color()
	color.r = image_data[index_start]
	color.g = image_data[index_start + 1]
	color.b = image_data[index_start + 2]
	color.a = image_data[index_start + 3]
	return color

func _set_pixel(image_data : PackedByteArray, image_width : int, x : int, y : int, color : Color) -> void:
	var index_start : int = (x + y * image_width) * 3
	image_data[index_start] = color.r
	image_data[index_start + 1] = color.g
	image_data[index_start + 2] = color.b
	image_data[index_start + 3] = color.a
	return

func convert_to_grayscale2(image_data : PackedByteArray, image_size : Vector2i) -> void:
	for row : int in range(image_size.y):
		for col : int in range(image_size.x):
			var pixel : Color = _get_pixel(image_data, image_size.x, col, row)
			var intensity : float = (WEIGHT_R * pixel.r) + (WEIGHT_G * pixel.g) + (WEIGHT_B * pixel.b)
			var pixel_grayscale : Color = Color(intensity, intensity, intensity, pixel.a)
			_set_pixel(image_data, image_size.x, col, row, pixel_grayscale)
	return
