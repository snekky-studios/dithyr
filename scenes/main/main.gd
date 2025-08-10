class_name Main
extends Node

const DIR_INPUT : String = "res://assets/input/"
const DIR_OUTPUT : String = "res://assets/output/"
const FILE_EXTENSION : String = ".png"

func _ready() -> void:
	var time_start : float = Time.get_ticks_usec()
	var file_name : String = "desert2"
	var image : Image = _load(file_name)
	var image_grayscale : Image = ImageProcessor.process_image_grayscale(image, 5)
	_save(image_grayscale, file_name + "_processed")
	#var time_start : float = Time.get_ticks_usec()
	#
	#var time_grayscale_start : float = Time.get_ticks_usec()
	#convert_to_grayscale(image)
	#_save(image, file_name + "_grayscale")
	#var time_grayscale_end : float = Time.get_ticks_usec()
	#
	#var time_reduce_start : float = Time.get_ticks_usec()
	#var intensity_range : Vector2 = get_intensity_range(image)
	#reduce_colors(image, 7, intensity_range)
	#_save(image, file_name + "_reduced")
	#var time_reduce_end : float = Time.get_ticks_usec()
	#
	#var time_dithering_start : float = Time.get_ticks_usec()
	#var image_colors : Array[Color] = get_colors(image)
	#add_dithering(image, image_colors, intensity_range)
	#_save(image, file_name + "_dithered")
	#var time_dithering_end : float = Time.get_ticks_usec()
	#
	var time_end : float = Time.get_ticks_usec()
	#
	#print("Time Grayscale: ", time_grayscale_end - time_grayscale_start)
	#print("Time Reduce: ", time_reduce_end - time_reduce_start)
	#print("Time Dither: ", time_dithering_end - time_dithering_start)
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

## returns the range of color intensity present in the image as Vector2(intensity_min, intensity_max)
#func get_intensity_range(image : Image) -> Vector2:
	## preset range variable with highest min and lowest max
	#var intensity_range : Vector2 = Vector2(1.0, 0.0)
	#for row : int in range(image.get_height()):
		#for col : int in range(image.get_width()):
			#var pixel : Color = image.get_pixel(col, row)
			#if(pixel.r < intensity_range.x):
				#intensity_range.x = pixel.r
			#if(pixel.r > intensity_range.y):
				#intensity_range.y = pixel.r
	#return intensity_range
#
## returns an array of colors present in the image, ordered from least intense (black) to most intense (white)
#func get_colors(image : Image) -> Array[Color]:
	#var colors : Array[Color] = []
	#for row : int in range(image.get_height()):
		#for col : int in range(image.get_width()):
			#var pixel : Color = image.get_pixel(col, row)
			#if(not pixel in colors):
				#colors.append(pixel)
	#for index_primary : int in range(0, colors.size() - 1):
		#for index_secondary : int in range(index_primary, colors.size()):
			#if(colors[index_secondary].r < colors[index_primary].r):
				#var temp : Color = colors[index_primary]
				#colors[index_primary] = colors[index_secondary]
				#colors[index_secondary] = temp
	#return colors
#
#func convert_to_grayscale(image : Image) -> void:
	#for row : int in range(image.get_height()):
		#for col : int in range(image.get_width()):
			#var pixel : Color = image.get_pixel(col, row)
			#var intensity : float = (WEIGHT_R * pixel.r) + (WEIGHT_G * pixel.g) + (WEIGHT_B * pixel.b)
			#var pixel_grayscale : Color = Color(intensity, intensity, intensity, pixel.a)
			#image.set_pixel(col, row, pixel_grayscale)
	#return
#
#func reduce_colors(image : Image, num_colors : int, intensity_range : Vector2) -> void:
	#var step : float = (intensity_range.y - intensity_range.x) / float(num_colors - 1)
	#for row : int in range(image.get_height()):
		#for col : int in range(image.get_width()):
			#var pixel : Color = image.get_pixel(col, row)
			#var intensity : float = snappedf(pixel.r, step)
			#var pixel_reduced : Color = Color(intensity, intensity, intensity, pixel.a)
			#image.set_pixel(col, row, pixel_reduced)
	#return
#
#func add_dithering(image : Image, colors : Array[Color], intensity_range : Vector2) -> void:
	#if(colors.size() % 2 != 1):
		#print("error: number of colors must be odd for dithering - ", colors.size())
		#return
	#
	#var dithering_indexes : Array[int] = []
	#for index_colors : int in range(1, colors.size(), 2):
		#dithering_indexes.append(index_colors)
	#
	#var color_intensity_dither : float = (intensity_range.y - intensity_range.x) / 2.0
	#for row : int in range(image.get_height()):
		#for col : int in range(image.get_width()):
			#var pixel : Color = image.get_pixel(col, row)
			#for index_dithering : int in dithering_indexes:
				#if(is_equal_approx(snappedf(pixel.r, 0.01), snappedf(colors[index_dithering].r, 0.01))):
					#var pixel_dithered : Color = Color()
					#if((row + col) % 2 == 0):
						#pixel_dithered = colors[index_dithering - 1]
					#else:
						#pixel_dithered = colors[index_dithering + 1]
					#image.set_pixel(col, row, pixel_dithered)
	#return
