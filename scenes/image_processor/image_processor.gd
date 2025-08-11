class_name ImageProcessor
extends Node

const WEIGHT_R : float = 0.2126
const WEIGHT_G : float = 0.7152
const WEIGHT_B : float = 0.0722

const ERROR_COORDINATES_STUCKI : Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(2, 0),
	Vector2i(-2, 1),
	Vector2i(-1, 1),
	Vector2i(0, 1),
	Vector2i(1, 1),
	Vector2i(2, 1),
	Vector2i(-2, 2),
	Vector2i(-1, 2),
	Vector2i(0, 2),
	Vector2i(1, 2),
	Vector2i(2, 2)
]

const ERROR_DIVISOR_STUCKI : float = 42.0

const ERROR_MAGNITUDE_STUCKI : Dictionary[Vector2i, float] = {
	Vector2i(1, 0) : 8.0,
	Vector2i(2, 0) : 4.0,
	Vector2i(-2, 1) : 2.0,
	Vector2i(-1, 1) : 4.0,
	Vector2i(0, 1) : 8.0,
	Vector2i(1, 1) : 4.0,
	Vector2i(2, 1) : 2.0,
	Vector2i(-2, 2) : 1.0,
	Vector2i(-1, 2) : 2.0,
	Vector2i(0, 2) : 4.0,
	Vector2i(1, 2) : 2.0,
	Vector2i(2, 2) : 1.0
}

static func process_image_grayscale(image_to_process : Image, num_colors : int) -> Image:
	var image : Image = image_to_process.duplicate()
	_convert_to_grayscale(image)
	var intensity_range : Vector2 = _get_intensity_range(image)
	var num_colors_grayscale : int = (num_colors * 2) - 1 # add an extra color between each two color indexes to be the dithered shade
	_reduce_colors(image, num_colors_grayscale, intensity_range)
	var image_colors : Array[Color] = get_colors(image)
	_add_dithering(image, image_colors)
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

static func _add_dithering(image : Image, colors : Array[Color]) -> void:
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

static func _linear_dither(image_grayscale : Image, num_colors : int, intensity_range : Vector2) -> Image:
	var image : Image = image_grayscale.duplicate()
	var step : float = (intensity_range.y - intensity_range.x) / float(num_colors - 1)
	# reduce number of colors and build color array
	for row : int in range(image.get_height()):
		var error : float = 0.0
		for col : int in range(image.get_width()):
			var pixel : Color = image.get_pixel(col, row)
			var intensity : float = snappedf(pixel.r, step)
			var pixel_reduced : Color = Color()
			# odd, or "intermediate" color indexes
			if(int(intensity / step) % 2 == 1):
				var pixel_value_adjusted : float = pixel.r + error
				if(pixel_value_adjusted > intensity):
					intensity += step
				else:
					intensity -= step
				error = pixel_value_adjusted - intensity
			pixel_reduced = Color(intensity, intensity, intensity, pixel.a)
			image.set_pixel(col, row, pixel_reduced)
	return image

static func _stucki_dither(image_grayscale : Image, num_colors : int, intensity_range : Vector2) -> Image:
	var image : Image = image_grayscale.duplicate()
	var step : float = (intensity_range.y - intensity_range.x) / float(num_colors - 1)
	var error : Array[Array] = []
	## initialize error array
	error.resize(image.get_height())
	error.fill([])
	for row : int in range(image.get_height()):
		var error_row : Array[float] = []
		error_row.resize(image.get_width())
		error_row.fill(0.0)
		error[row] = error_row
	# reduce number of colors and build color array
	for row : int in range(image.get_height()):
		for col : int in range(image.get_width()):
			var pixel_error : float = error[row][col]
			var pixel : Color = image.get_pixel(col, row)
			var intensity : float = snappedf(pixel.r, step)
			var pixel_reduced : Color = Color()
			# odd, or "intermediate" color indexes
			if(int(intensity / step) % 2 == 1):
				var pixel_value_adjusted : float = pixel.r + pixel_error
				if(pixel_value_adjusted > intensity):
					intensity += step
				else:
					intensity -= step
				pixel_error = pixel_value_adjusted - intensity
				for error_coordinate : Vector2i in ERROR_COORDINATES_STUCKI:
					var new_row : int = row + error_coordinate.y
					var new_col : int = col + error_coordinate.x
					if(new_row < 0 or new_row >= error.size() or new_col >= error[0].size()):
						continue
					error[new_row][new_col] = pixel_error * ERROR_MAGNITUDE_STUCKI[error_coordinate] / ERROR_DIVISOR_STUCKI
			pixel_reduced = Color(intensity, intensity, intensity, pixel.a)
			image.set_pixel(col, row, pixel_reduced)
	return image
