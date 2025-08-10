class_name ImageProcessor
extends Node

const WEIGHT_R : float = 0.2126
const WEIGHT_G : float = 0.7152
const WEIGHT_B : float = 0.0722

static func process_image_grayscale(image_to_process : Image, num_colors : int) -> Image:
	var image : Image = image_to_process.duplicate()
	_convert_to_grayscale(image)
	var intensity_range : Vector2 = _get_intensity_range(image)
	var num_colors_grayscale : int = (num_colors * 2) - 1 # add an extra color between each two color indexes to be the dithered shade
	_reduce_colors(image, num_colors_grayscale, intensity_range)
	var image_colors : Array[Color] = get_colors(image)
	_add_dithering(image, image_colors, intensity_range)
	return image

# returns an array of colors present in the image, ordered from least intense (black) to most intense (white)
static func get_colors(image : Image) -> Array[Color]:
	var colors : Array[Color] = []
	for row : int in range(image.get_height()):
		for col : int in range(image.get_width()):
			var pixel : Color = image.get_pixel(col, row)
			if(not pixel in colors):
				colors.append(pixel)
	for index_primary : int in range(0, colors.size() - 1):
		for index_secondary : int in range(index_primary, colors.size()):
			if(colors[index_secondary].r < colors[index_primary].r):
				var temp : Color = colors[index_primary]
				colors[index_primary] = colors[index_secondary]
				colors[index_secondary] = temp
	return colors

static func apply_pallete(image_grayscale : Image, grayscale_colors : Array[Color], palette : Array[Color]) -> Image:
	if(grayscale_colors.size() != palette.size()):
		print("error: mismatched grayscale colors/palette size - ", grayscale_colors.size(), " ", palette.size())
		return
	var image : Image = image_grayscale.duplicate()
	for row : int in range(image.get_height()):
		for col : int in range(image.get_width()):
			var pixel : Color = image.get_pixel(col, row)
			for index_palette : int in range(palette.size()):
				if(pixel.r == grayscale_colors[index_palette].r):
					image.set_pixel(col, row, palette[index_palette])
	return image

# returns the range of color intensity present in the image as Vector2(intensity_min, intensity_max)
static func _get_intensity_range(image : Image) -> Vector2:
	# preset range variable with highest min and lowest max
	var intensity_range : Vector2 = Vector2(1.0, 0.0)
	for row : int in range(image.get_height()):
		for col : int in range(image.get_width()):
			var pixel : Color = image.get_pixel(col, row)
			if(pixel.r < intensity_range.x):
				intensity_range.x = pixel.r
			if(pixel.r > intensity_range.y):
				intensity_range.y = pixel.r
	return intensity_range

static func _convert_to_grayscale(image : Image) -> void:
	for row : int in range(image.get_height()):
		for col : int in range(image.get_width()):
			var pixel : Color = image.get_pixel(col, row)
			var intensity : float = (WEIGHT_R * pixel.r) + (WEIGHT_G * pixel.g) + (WEIGHT_B * pixel.b)
			var pixel_grayscale : Color = Color(intensity, intensity, intensity, pixel.a)
			image.set_pixel(col, row, pixel_grayscale)
	return

static func _reduce_colors(image : Image, num_colors : int, intensity_range : Vector2) -> void:
	var step : float = (intensity_range.y - intensity_range.x) / float(num_colors - 1)
	for row : int in range(image.get_height()):
		for col : int in range(image.get_width()):
			var pixel : Color = image.get_pixel(col, row)
			var intensity : float = snappedf(pixel.r, step)
			var pixel_reduced : Color = Color(intensity, intensity, intensity, pixel.a)
			image.set_pixel(col, row, pixel_reduced)
	return

static func _add_dithering(image : Image, colors : Array[Color], intensity_range : Vector2) -> void:
	if(colors.size() % 2 != 1):
		print("error: number of colors must be odd for dithering - ", colors.size())
		return
	
	var dithering_indexes : Array[int] = []
	for index_colors : int in range(1, colors.size(), 2):
		dithering_indexes.append(index_colors)
	
	for row : int in range(image.get_height()):
		for col : int in range(image.get_width()):
			var pixel : Color = image.get_pixel(col, row)
			for index_dithering : int in dithering_indexes:
				if(is_equal_approx(snappedf(pixel.r, 0.01), snappedf(colors[index_dithering].r, 0.01))):
					var pixel_dithered : Color = Color()
					if((row + col) % 2 == 0):
						pixel_dithered = colors[index_dithering - 1]
					else:
						pixel_dithered = colors[index_dithering + 1]
					image.set_pixel(col, row, pixel_dithered)
	return
