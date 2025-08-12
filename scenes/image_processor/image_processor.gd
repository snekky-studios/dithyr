class_name ImageProcessor
extends Node
# Contains grayscale and dithering algorithms
# 
# Algorithms are either "continuous" or "intermediate":
# - Continuous algorithms apply the dithering technique to the whole image
# - Continuous algorithms are called after converting the image to grayscale
# - Intermediate algorithms apply the dithering technique only to odd (intermediate) indexes
# - Intermediate algorithms are called after reducing the image to a set number of colors
# - Before calling an intermediate algorithm, image should be reduced to (N * 2) + 1 number of colors,
#   where N is the number of colors desired in the final image
# A variety of dithering techniques are available:
# - Standard technique applies an even, checkboard dither across the entire area
# - Error Diffusion technique keeps a running account of error along a single axis, resulting in denser
#   or sparser dithering depending on the intensity of the color along the axis
# - Stucki technique keeps track of error along two dimensions according to a weighted grid


#region Constants
const GRAYSCALE_METHOD_INDEX_R : int = 0
const GRAYSCALE_METHOD_INDEX_G : int = 1
const GRAYSCALE_METHOD_INDEX_B : int = 2
const GRAYSCALE_BT709 : Array[float] = [0.2126, 0.7152, 0.0722]
const GRAYSCALE_BT601 : Array[float] = [0.299, 0.587, 0.114]
const GRAYSCALE_PHOTOSHOP : Array[float] = [0.30, 0.59, 0.11]

const PALETTE_SIZE_MAX : int = 10

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
#endregion

var image : Image = null
var palette : Array[Color] = []
var intensity_range : Vector2 = Vector2(1.0, 0.0)

func _ready() -> void:
	
	return

func reset() -> void:
	image = null
	palette = []
	intensity_range = Vector2(1.0, 0.0)
	return

# converts image to grayscale by applying rgb weights supplied in method
# also calculates intensity range to prevent having to loop through all pixels again
func grayscale(method : Array[float]) -> void:
	if(image == null):
		print("error: grayscale called with no image")
		return
	for row : int in range(image.get_height()):
		for col : int in range(image.get_width()):
			var pixel : Color = image.get_pixel(col, row)
			var intensity : float = (method[GRAYSCALE_METHOD_INDEX_R] * pixel.r) + (method[GRAYSCALE_METHOD_INDEX_G] * pixel.g) + (method[GRAYSCALE_METHOD_INDEX_B] * pixel.b)
			if(intensity < intensity_range.x):
				intensity_range.x = pixel.r
			if(intensity > intensity_range.y):
				intensity_range.y = pixel.r
			var pixel_grayscale : Color = Color(intensity, intensity, intensity, pixel.a)
			image.set_pixel(col, row, pixel_grayscale)
	return

# condenses the palette present in image into num_colors, evenly spaced in the intensity range
# also populates the palette array to prevent having to loop through all pixels again
func reduce_palette(num_colors : int) -> void:
	if(image == null):
		print("error: reduce_palette called with no image")
		return
	elif(intensity_range.x > intensity_range.y):
		print("error: reduce_palette called with invalid intensity range - ", intensity_range)
		return
	elif(num_colors < 1 or num_colors > PALETTE_SIZE_MAX):
		print("error: reduce_palette called with invalid number of colors - ", num_colors)
		return
	var step : float = (intensity_range.y - intensity_range.x) / float(num_colors - 1)
	for row : int in range(image.get_height()):
		for col : int in range(image.get_width()):
			var pixel : Color = image.get_pixel(col, row)
			var intensity : float = snappedf(pixel.r, step)
			var pixel_reduced : Color = Color(intensity, intensity, intensity, pixel.a)
			if(not pixel_reduced in palette):
				palette.append(pixel_reduced)
			image.set_pixel(col, row, pixel_reduced)
	# sort palette array from least intense (black) to most intense (white)
	for index_primary : int in range(0, palette.size() - 1):
		for index_secondary : int in range(index_primary, palette.size()):
			if(palette[index_secondary].r < palette[index_primary].r):
				var temp : Color = palette[index_primary]
				palette[index_primary] = palette[index_secondary]
				palette[index_secondary] = temp
	return

# dithers image using intermediate, standard algorithm
func dither_intermediate_standard() -> void:
	if(image == null):
		print("error: dither_intermediate_standard called with no image")
		return
	elif(intensity_range.x > intensity_range.y):
		print("error: dither_intermediate_standard called with invalid intensity range - ", intensity_range)
		return
	elif(palette.size() < 1 or palette.size() > PALETTE_SIZE_MAX or palette.size() % 2 != 1):
		print("error: dither_intermediate_standard called with invalid palette size - ", palette.size())
		return
	# mark odd, "intermediate", indexes for dithering
	var dithering_indexes : Array[int] = []
	for index_palette : int in range(1, palette.size(), 2):
		dithering_indexes.append(index_palette)
	for row : int in range(image.get_height()):
		for col : int in range(image.get_width()):
			var pixel : Color = image.get_pixel(col, row)
			for index_dithering : int in dithering_indexes:
				# TODO: is_equal_approx and snappedf necessary due to some rounding bug?
				if(is_equal_approx(snappedf(pixel.r, 0.01), snappedf(palette[index_dithering].r, 0.01))):
					var pixel_dithered : Color = Color()
					# creates a checkerboard dithering pattern by applying alternating pixels as the color index above or below the intermediate index
					if((row + col) % 2 == 0):
						pixel_dithered = palette[index_dithering - 1]
					else:
						pixel_dithered = palette[index_dithering + 1]
					image.set_pixel(col, row, pixel_dithered)
	_strip_palette()
	return

# dithers image using intermediate, linear (error diffusion) algorithm
func dither_intermediate_linear() -> void:
	if(image == null):
		print("error: dither_intermediate_linear called with no image")
		return
	elif(intensity_range.x > intensity_range.y):
		print("error: dither_intermediate_linear called with invalid intensity range - ", intensity_range)
		return
	elif(palette.size() < 1 or palette.size() > PALETTE_SIZE_MAX or palette.size() % 2 != 1):
		print("error: dither_intermediate_linear called with invalid palette size - ", palette.size())
		return
	var step : float = (intensity_range.y - intensity_range.x) / float(palette.size() - 1)
	# reduce number of colors and build color array
	for row : int in range(image.get_height()):
		var error : float = 0.0
		for col : int in range(image.get_width()):
			var pixel : Color = image.get_pixel(col, row)
			var intensity : float = snappedf(pixel.r, step)
			var pixel_dithered : Color = Color()
			# odd, or "intermediate" color indexes
			if(int(intensity / step) % 2 == 1):
				var pixel_value_adjusted : float = pixel.r + error
				if(pixel_value_adjusted > intensity):
					intensity += step
				else:
					intensity -= step
				error = pixel_value_adjusted - intensity
			pixel_dithered = Color(intensity, intensity, intensity, pixel.a)
			image.set_pixel(col, row, pixel_dithered)
	_strip_palette()
	return

# dithers image using intermediate, stucki algorithm
func dither_intermediate_stucki() -> void:
	if(image == null):
		print("error: dither_intermediate_stucki called with no image")
		return
	elif(intensity_range.x > intensity_range.y):
		print("error: dither_intermediate_stucki called with invalid intensity range - ", intensity_range)
		return
	elif(palette.size() < 1 or palette.size() > PALETTE_SIZE_MAX or palette.size() % 2 != 1):
		print("error: dither_intermediate_stucki called with invalid palette size - ", palette.size())
		return
	var step : float = (intensity_range.y - intensity_range.x) / float(palette.size() - 1)
	var error : Array[Array] = []
	## initialize error array
	error.resize(image.get_height())
	error.fill([])
	for row : int in range(image.get_height()):
		var error_row : Array[float] = []
		error_row.resize(image.get_width())
		error_row.fill(0.0)
		error[row] = error_row
	for row : int in range(image.get_height()):
		for col : int in range(image.get_width()):
			var pixel_error : float = error[row][col]
			var pixel : Color = image.get_pixel(col, row)
			var intensity : float = snappedf(pixel.r, step)
			var pixel_dithered : Color = Color()
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
			pixel_dithered = Color(intensity, intensity, intensity, pixel.a)
			image.set_pixel(col, row, pixel_dithered)
	_strip_palette()
	return

# swaps the current palette for a new palette
func palette_swap(new_palette : Array[Color]) -> void:
	if(image == null):
		print("error: reduce_palette called with no image")
		return
	elif(palette.size() != new_palette.size()):
		print("error: mismatched palette sizes - ", palette.size(), " ", new_palette.size())
		return
	for row : int in range(image.get_height()):
		for col : int in range(image.get_width()):
			var pixel : Color = image.get_pixel(col, row)
			for index_palette : int in range(palette.size()):
				# TODO: is_equal_approx and snappedf necessary due to rounding bug?
				if(is_equal_approx(snappedf(pixel.r, 0.01), snappedf(palette[index_palette].r, 0.01))):
					image.set_pixel(col, row, new_palette[index_palette])
	return

# removes odd indexes from the palette, called after applying intermediate dithering algorithm
func _strip_palette() -> void:
	# we have stripped out intermediate colors from the palette, so reduce the palette to its new size
	var palette_stripped : Array[Color] = []
	# keep only even indexes of the palette
	for index_palette : int in range(0, palette.size(), 2):
		palette_stripped.append(palette[index_palette])
	palette = palette_stripped
	return



#static func process_image_grayscale(image_to_process : Image, num_colors : int) -> Image:
	#var image : Image = image_to_process.duplicate()
	#_convert_to_grayscale(image)
	#var intensity_range : Vector2 = _get_intensity_range(image)
	#var num_colors_grayscale : int = (num_colors * 2) - 1 # add an extra color between each two color indexes to be the dithered shade
	#_reduce_colors(image, num_colors_grayscale, intensity_range)
	#var image_colors : Array[Color] = get_colors(image)
	#_add_dithering(image, image_colors)
	#return image
#
## returns an array of colors present in the image, ordered from least intense (black) to most intense (white)
#static func get_colors(new_image : Image) -> Array[Color]:
	#var colors : Array[Color] = []
	#for row : int in range(new_image.get_height()):
		#for col : int in range(new_image.get_width()):
			#var pixel : Color = new_image.get_pixel(col, row)
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
#static func apply_pallete(image_grayscale : Image, grayscale_colors : Array[Color], palette : Array[Color]) -> Image:
	#if(grayscale_colors.size() != palette.size()):
		#print("error: mismatched grayscale colors/palette size - ", grayscale_colors.size(), " ", palette.size())
		#return
	#var image : Image = image_grayscale.duplicate()
	#for row : int in range(image.get_height()):
		#for col : int in range(image.get_width()):
			#var pixel : Color = image.get_pixel(col, row)
			#for index_palette : int in range(palette.size()):
				#if(pixel.r == grayscale_colors[index_palette].r):
					#image.set_pixel(col, row, palette[index_palette])
	#return image
#
## returns the range of color intensity present in the image as Vector2(intensity_min, intensity_max)
#static func _get_intensity_range(image : Image) -> Vector2:
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
#static func _convert_to_grayscale(image : Image) -> void:
	#for row : int in range(image.get_height()):
		#for col : int in range(image.get_width()):
			#var pixel : Color = image.get_pixel(col, row)
			##var intensity : float = (WEIGHT_R * pixel.r) + (WEIGHT_G * pixel.g) + (WEIGHT_B * pixel.b)
			##var pixel_grayscale : Color = Color(intensity, intensity, intensity, pixel.a)
			##image.set_pixel(col, row, pixel_grayscale)
	#return
#
#static func _reduce_colors(image : Image, num_colors : int, intensity_range : Vector2) -> void:
	#var step : float = (intensity_range.y - intensity_range.x) / float(num_colors - 1)
	#for row : int in range(image.get_height()):
		#for col : int in range(image.get_width()):
			#var pixel : Color = image.get_pixel(col, row)
			#var intensity : float = snappedf(pixel.r, step)
			#var pixel_reduced : Color = Color(intensity, intensity, intensity, pixel.a)
			#image.set_pixel(col, row, pixel_reduced)
	#return
#
#static func _add_dithering(image : Image, colors : Array[Color]) -> void:
	#if(colors.size() % 2 != 1):
		#print("error: number of colors must be odd for dithering - ", colors.size())
		#return
	#
	#var dithering_indexes : Array[int] = []
	#for index_colors : int in range(1, colors.size(), 2):
		#dithering_indexes.append(index_colors)
	#
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
#
#static func _linear_dither(image_grayscale : Image, num_colors : int, intensity_range : Vector2) -> Image:
	#var image : Image = image_grayscale.duplicate()
	#var step : float = (intensity_range.y - intensity_range.x) / float(num_colors - 1)
	## reduce number of colors and build color array
	#for row : int in range(image.get_height()):
		#var error : float = 0.0
		#for col : int in range(image.get_width()):
			#var pixel : Color = image.get_pixel(col, row)
			#var intensity : float = snappedf(pixel.r, step)
			#var pixel_reduced : Color = Color()
			## odd, or "intermediate" color indexes
			#if(int(intensity / step) % 2 == 1):
				#var pixel_value_adjusted : float = pixel.r + error
				#if(pixel_value_adjusted > intensity):
					#intensity += step
				#else:
					#intensity -= step
				#error = pixel_value_adjusted - intensity
			#pixel_reduced = Color(intensity, intensity, intensity, pixel.a)
			#image.set_pixel(col, row, pixel_reduced)
	#return image
#
#static func _stucki_dither(image_grayscale : Image, num_colors : int, intensity_range : Vector2) -> Image:
	#var image : Image = image_grayscale.duplicate()
	#var step : float = (intensity_range.y - intensity_range.x) / float(num_colors - 1)
	#var error : Array[Array] = []
	### initialize error array
	#error.resize(image.get_height())
	#error.fill([])
	#for row : int in range(image.get_height()):
		#var error_row : Array[float] = []
		#error_row.resize(image.get_width())
		#error_row.fill(0.0)
		#error[row] = error_row
	## reduce number of colors and build color array
	#for row : int in range(image.get_height()):
		#for col : int in range(image.get_width()):
			#var pixel_error : float = error[row][col]
			#var pixel : Color = image.get_pixel(col, row)
			#var intensity : float = snappedf(pixel.r, step)
			#var pixel_reduced : Color = Color()
			## odd, or "intermediate" color indexes
			#if(int(intensity / step) % 2 == 1):
				#var pixel_value_adjusted : float = pixel.r + pixel_error
				#if(pixel_value_adjusted > intensity):
					#intensity += step
				#else:
					#intensity -= step
				#pixel_error = pixel_value_adjusted - intensity
				#for error_coordinate : Vector2i in ERROR_COORDINATES_STUCKI:
					#var new_row : int = row + error_coordinate.y
					#var new_col : int = col + error_coordinate.x
					#if(new_row < 0 or new_row >= error.size() or new_col >= error[0].size()):
						#continue
					#error[new_row][new_col] = pixel_error * ERROR_MAGNITUDE_STUCKI[error_coordinate] / ERROR_DIVISOR_STUCKI
			#pixel_reduced = Color(intensity, intensity, intensity, pixel.a)
			#image.set_pixel(col, row, pixel_reduced)
	#return image
