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
const COLOR_CHANNEL_RESOLUTION : float = (1.0 / 256.0)
const COLOR_CHANNEL_MIN8 : int = 0
const COLOR_CHANNEL_MAX8 : int = 255

const ONE_THIRD : float = float(1.0 / 3.0)

const GRAYSCALE_METHOD_INDEX_R : int = 0
const GRAYSCALE_METHOD_INDEX_G : int = 1
const GRAYSCALE_METHOD_INDEX_B : int = 2
const GRAYSCALE_STANDARD : Array[float] = [ONE_THIRD, ONE_THIRD, ONE_THIRD]
const GRAYSCALE_BT709 : Array[float] = [0.2126, 0.7152, 0.0722]
const GRAYSCALE_BT601 : Array[float] = [0.299, 0.587, 0.114]
const GRAYSCALE_PHOTOSHOP : Array[float] = [0.30, 0.59, 0.11]
const GRAYSCALE_R_CHANNEL : Array[float] = [1.0, 0.0, 0.0]
const GRAYSCALE_G_CHANNEL : Array[float] = [0.0, 1.0, 0.0]
const GRAYSCALE_B_CHANNEL : Array[float] = [0.0, 0.0, 1.0]
const GRAYSCALE_RG_CHANNEL : Array[float] = [0.5, 0.5, 0.0]
const GRAYSCALE_RB_CHANNEL : Array[float] = [0.5, 0.0, 0.5]
const GRAYSCALE_GB_CHANNEL : Array[float] = [0.0, 0.5, 0.5]

const PALETTE_SIZE_MIN : int = 2
const PALETTE_SIZE_MAX : int = 12

# shorthand for all of the vectors denoting relative position in the error matrix
const VR : Vector2i = Vector2i.RIGHT
const VRR : Vector2i = Vector2i.RIGHT + Vector2i.RIGHT
const VLLD : Vector2i = Vector2i.LEFT + Vector2i.LEFT + Vector2i.DOWN
const VLD : Vector2i = Vector2i.LEFT + Vector2i.DOWN
const VD : Vector2i = Vector2i.DOWN
const VRD : Vector2i = Vector2i.RIGHT + Vector2i.DOWN
const VRRD : Vector2i = Vector2i.RIGHT + Vector2i.RIGHT + Vector2i.DOWN
const VLLDD : Vector2i = Vector2i.LEFT + Vector2i.LEFT + Vector2i.DOWN + Vector2i.DOWN
const VLDD : Vector2i = Vector2i.LEFT + Vector2i.DOWN + Vector2i.DOWN
const VDD : Vector2i = Vector2i.DOWN + Vector2i.DOWN
const VRDD : Vector2i = Vector2i.RIGHT + Vector2i.DOWN + Vector2i.DOWN
const VRRDD : Vector2i = Vector2i.RIGHT + Vector2i.RIGHT + Vector2i.DOWN + Vector2i.DOWN

const ERROR_COORDINATES_LINEAR : Array[Vector2i] = [
	VR
]

const ERROR_SCALARS_LINEAR : Dictionary[Vector2i, float] = {
	VR : 1.0
}

const ERROR_COORDINATES_FLOYD_STEINBERG : Array[Vector2i] = [
	VR,
	VLD, VD, VRD
]

const ERROR_SCALARS_FLOYD_STEINBERG : Dictionary[Vector2i, float] = {
	VR : 7.0 / 16.0,
	VLD : 3.0 / 16.0,
	VD : 5.0 / 16.0,
	VRD : 1.0 / 16.0
}

const ERROR_COORDINATES_STUCKI : Array[Vector2i] = [
	VR, VRR,
	VLLD, VLD, VD, VRD, VRRD,
	VLLDD, VLDD, VDD, VRDD, VRRDD
]

const ERROR_SCALARS_STUCKI : Dictionary[Vector2i, float] = {
	VR : 8.0 / 42.0,
	VRR : 4.0 / 42.0,
	VLLD : 2.0 / 42.0,
	VLD : 4.0 / 42.0,
	VD : 8.0 / 42.0,
	VRD : 4.0 / 42.0,
	VRRD : 2.0 / 42.0,
	VLLDD : 1.0 / 42.0,
	VLDD : 2.0 / 42.0,
	VDD : 4.0 / 42.0,
	VRDD : 2.0 / 42.0,
	VRRDD : 1.0 / 42.0
}
#endregion

var image : Image = null
var palette : Array[Color] = []
var intensity_range8 : Vector2i = Vector2(COLOR_CHANNEL_MAX8, COLOR_CHANNEL_MIN8)

# sets local variables to default values
func reset() -> void:
	image = null
	palette = []
	intensity_range8 = Vector2(COLOR_CHANNEL_MAX8, COLOR_CHANNEL_MIN8)
	return

# converts image to grayscale by applying rgb weights supplied in method
# also calculates intensity range to prevent having to loop through all pixels again
func grayscale8(method : Array[float]) -> void:
	if(image == null):
		print("error: grayscale called with no image")
		return
	intensity_range8 = Vector2i(COLOR_CHANNEL_MAX8, COLOR_CHANNEL_MIN8)
	for row : int in range(image.get_height()):
		for col : int in range(image.get_width()):
			var pixel : Color = image.get_pixel(col, row)
			var intensity : int = int((method[GRAYSCALE_METHOD_INDEX_R] * float(pixel.r8)) + (method[GRAYSCALE_METHOD_INDEX_G] * float(pixel.g8)) + (method[GRAYSCALE_METHOD_INDEX_B] * float(pixel.b8)))
			if(intensity < intensity_range8.x):
				intensity_range8.x = intensity
			if(intensity > intensity_range8.y):
				intensity_range8.y = intensity
			var pixel_grayscale : Color = Color.from_rgba8(intensity, intensity, intensity, pixel.a8)
			image.set_pixel(col, row, pixel_grayscale)
	if(intensity_range8.x == intensity_range8.y):
		intensity_range8 = Vector2i(COLOR_CHANNEL_MIN8, COLOR_CHANNEL_MAX8)
	return

# condenses the palette present in image into num_colors, evenly spaced in the intensity range
# also populates the palette array to prevent having to loop through all pixels again
func reduce_palette8(technique : Main.DitheringTechnique, num_colors : int) -> void:
	# safety checks
	if(image == null):
		print("error: reduce_palette called with no image")
		return
	elif(intensity_range8.x > intensity_range8.y):
		print("error: reduce_palette called with invalid intensity range - ", intensity_range8)
		return
	
	var palette_size : int = num_colors
	
	# safety checks
	if(technique == Main.DitheringTechnique.INTERMEDIATE):
		palette_size = (num_colors * 2) - 1
		if(palette_size < PALETTE_SIZE_MIN or palette_size > (PALETTE_SIZE_MAX * 2) - 1 or palette_size % 2 != 1):
			print("error: reduce_palette called with invalid palette size - ", num_colors)
			return
	elif(technique == Main.DitheringTechnique.CONTINUOUS):
		if(palette_size < PALETTE_SIZE_MIN or palette_size >  PALETTE_SIZE_MAX):
			print("error: reduce_palette called with invalid palette size - ", num_colors)
			return
	
	var step : int = int(float(intensity_range8.y - intensity_range8.x) / float(palette_size - 1))
	# fill palette with possible colors based on num_colors and intensity range
	palette.resize(palette_size)
	var intensity_palette : int = intensity_range8.x
	for index_palette : int in range(palette.size()):
		var pixel_palette : Color = Color.from_rgba8(intensity_palette, intensity_palette, intensity_palette, COLOR_CHANNEL_MAX8)
		palette[index_palette] = pixel_palette
		intensity_palette += step
	
	for row : int in range(image.get_height()):
		for col : int in range(image.get_width()):
			var pixel : Color = image.get_pixel(col, row)
			var intensity : int = snappedi(pixel.r8, step) + intensity_range8.x
			var pixel_reduced : Color = Color.from_rgba8(intensity, intensity, intensity, pixel.a8)
			if(technique == Main.DitheringTechnique.INTERMEDIATE):
				var nearest_palette_index : int = _nearest_palette_index(pixel_reduced)
				if(not _is_even(nearest_palette_index)):
					# for intermediate techniques, we only want to dither odd indexes, so skip if even
					continue
			image.set_pixel(col, row, pixel_reduced)
	return

# dithers image using intermediate, standard algorithm
func dither_intermediate_standard8(num_colors : int) -> void:
	# safety checks
	if(image == null):
		print("error: dither_intermediate_standard called with no image")
		return
	elif(intensity_range8.x > intensity_range8.y):
		print("error: dither_intermediate_standard called with invalid intensity range - ", intensity_range8)
		return
	
	var palette_size : int = (num_colors * 2) - 1
	
	# safety checks
	if(palette_size < PALETTE_SIZE_MIN or palette_size > (PALETTE_SIZE_MAX * 2) - 1):
		print("error: dither_intermediate_standard called with invalid palette size - ", palette_size)
		return
	
	# fill palette with possible colors based on num_colors and intensity range
	_build_palette_from_intensity_range8(palette_size)
	
	# process image
	for row : int in range(image.get_height()):
		for col : int in range(image.get_width()):
			var pixel : Color = image.get_pixel(col, row)
			var pixel_dithered : Color = Color()
			var nearest_palette_index : int = _nearest_palette_index(pixel)
			if(_is_even(nearest_palette_index)):
				# even indexes get rounded to the nearest palette color
				pixel_dithered = palette[nearest_palette_index]
			else:
				# odd (intermediate) indexes get dithered, checkerboard pattern
				if(_is_even(row + col)):
					pixel_dithered = palette[nearest_palette_index - 1]
				else:
					pixel_dithered = palette[nearest_palette_index + 1]
			image.set_pixel(col, row, pixel_dithered)
	
	# intermediate algorithms create extra palette indexes, so remove them
	_strip_palette()
	return

# dithers image using continuous technique and applies error matrix according to selected algorithm
func dither8(technique : Main.DitheringTechnique, algorithm : Main.DitheringAlgorithm, num_colors : int) -> void:
	# safety checks
	if(image == null):
		print("error: dither called with no image")
		return
	elif(intensity_range8.x > intensity_range8.y):
		# intensity_range is calculated during grayscale conversion, so we should have it here
		print("error: dither called with invalid intensity range - ", intensity_range8)
		return
	
	var palette_size : int = num_colors
	
	# safety checks
	if(technique == Main.DitheringTechnique.INTERMEDIATE):
		palette_size = (num_colors * 2) - 1
		if(palette_size < PALETTE_SIZE_MIN or palette_size > (PALETTE_SIZE_MAX * 2) - 1):
			print("error: dither called with invalid palette size - ", palette_size)
			return
	elif(technique == Main.DitheringTechnique.CONTINUOUS):
		if(palette_size < PALETTE_SIZE_MIN or palette_size >  PALETTE_SIZE_MAX):
			print("error: dither called with invalid palette size - ", palette_size)
			return
	else:
		print("error: invalid dithering technique - ", technique)
	
	# fill palette with possible colors based on num_colors and intensity range
	_build_palette_from_intensity_range8(palette_size)
	
	# initialize error array
	var error : Array[Array] = []
	var error_coordinates : Array[Vector2i] = []
	var error_scalars : Dictionary[Vector2i, float] = {}
	error.resize(image.get_height())
	error.fill([])
	for row : int in range(image.get_height()):
		var error_row : Array[float] = []
		error_row.resize(image.get_width())
		error_row.fill(0.0)
		error[row] = error_row
	
	# set error coordinates and scalars
	match algorithm:
		Main.DitheringAlgorithm.LINEAR:
			error_coordinates = ERROR_COORDINATES_LINEAR
			error_scalars = ERROR_SCALARS_LINEAR
		Main.DitheringAlgorithm.FLOYD_STEINBERG:
			error_coordinates = ERROR_COORDINATES_FLOYD_STEINBERG
			error_scalars = ERROR_SCALARS_FLOYD_STEINBERG
		Main.DitheringAlgorithm.STUCKI:
			error_coordinates = ERROR_COORDINATES_STUCKI
			error_scalars = ERROR_SCALARS_STUCKI
	
	# process image
	if(technique == Main.DitheringTechnique.INTERMEDIATE):
		for row : int in range(image.get_height()):
			for col : int in range(image.get_width()):
				var pixel : Color = image.get_pixel(col, row)
				var pixel_dithered : Color = Color()
				var nearest_palette_index : int = _nearest_palette_index(pixel)
				if(_is_even(nearest_palette_index)):
					# even indexes get rounded to the nearest palette color
					pixel_dithered = palette[nearest_palette_index]
				else:
					# odd (intermediate) indexes get dithered
					var pixel_error : float = error[row][col]
					var pixel_value_adjusted : int = int(float(pixel.r8) + (pixel_error * float(COLOR_CHANNEL_MAX8)))
					var pixel_adjusted : Color = Color.from_rgba8(pixel_value_adjusted, pixel_value_adjusted, pixel_value_adjusted, pixel.a8)
					var palette_index : int = _nearest_palette_index_even(pixel_adjusted)
					pixel_dithered = palette[palette_index]
					pixel_error = _color_distance(pixel_dithered, pixel_adjusted)
					for error_coordinate : Vector2i in error_coordinates:
						var new_row : int = row + error_coordinate.y
						var new_col : int = col + error_coordinate.x
						if(new_row < 0 or new_row >= error.size() or new_col < 0 or new_col >= error[0].size()):
							continue
						error[new_row][new_col] += pixel_error * error_scalars[error_coordinate]
				image.set_pixel(col, row, pixel_dithered)
	elif(technique == Main.DitheringTechnique.CONTINUOUS):
		for row : int in range(image.get_height()):
			for col : int in range(image.get_width()):
				var pixel : Color = image.get_pixel(col, row)
				var pixel_error : float = error[row][col]
				var pixel_dithered : Color = Color()
				var pixel_value_adjusted : int = int(float(pixel.r8) + (pixel_error * float(COLOR_CHANNEL_MAX8)))
				var pixel_adjusted : Color = Color.from_rgba8(pixel_value_adjusted, pixel_value_adjusted, pixel_value_adjusted, pixel.a8)
				var palette_index : int = _nearest_palette_index(pixel_adjusted)
				pixel_dithered = palette[palette_index]
				pixel_error = _color_distance(pixel_dithered, pixel_adjusted)
				for error_coordinate : Vector2i in error_coordinates:
					var new_row : int = row + error_coordinate.y
					var new_col : int = col + error_coordinate.x
					if(new_row < 0 or new_row >= error.size() or new_col < 0 or new_col >= error[0].size()):
						continue
					error[new_row][new_col] += pixel_error * error_scalars[error_coordinate]
				image.set_pixel(col, row, pixel_dithered)
	
	if(technique == Main.DitheringTechnique.INTERMEDIATE):
		# intermediate algorithms create extra palette indexes, so remove them
		_strip_palette()
	return

# swaps the current palette for a new palette
func palette_swap(new_palette : Array[Color]) -> void:
	# safety checks
	if(image == null):
		print("error: reduce_palette called with no image")
		return
	elif(palette.size() != new_palette.size()):
		print("error: mismatched palette sizes - ", palette.size(), " ", new_palette.size())
		return
	
	# process image
	for row : int in range(image.get_height()):
		for col : int in range(image.get_width()):
			var pixel : Color = image.get_pixel(col, row)
			for index_palette : int in range(palette.size()):
				if(_colors_grayscale_equal(pixel, palette[index_palette])):
					image.set_pixel(col, row, new_palette[index_palette])
	
	# replace old palette with new one
	for index_palette : int in range(palette.size()):
		palette[index_palette] = new_palette[index_palette]
	return

# checks the equality of two colors
func _colors_grayscale_equal(color_1 : Color, color_2 : Color) -> bool:
	return abs(color_1.r8 - color_2.r8) < 2

# removes odd indexes from the palette, called after applying intermediate dithering algorithm
func _strip_palette() -> void:
	# we have stripped out intermediate colors from the palette, so reduce the palette to its new size
	var palette_stripped : Array[Color] = []
	# keep only even indexes of the palette
	for index_palette : int in range(0, palette.size(), 2):
		palette_stripped.append(palette[index_palette])
	palette = palette_stripped
	return

# replaces the palette and intensity_range with the colors currently in the image
func _update_palette_intensity_range() -> void:
	palette.resize(0)
	intensity_range8 = Vector2(COLOR_CHANNEL_MAX8, COLOR_CHANNEL_MIN8)
	for row : int in range(image.get_height()):
		for col : int in range(image.get_width()):
			var pixel : Color = image.get_pixel(col, row)
			if(not pixel in palette):
				palette.append(pixel)
			if(pixel.r8 < intensity_range8.x):
				intensity_range8.x = pixel.r8
			if(pixel.r8 > intensity_range8.y):
				intensity_range8.y = pixel.r8
	for index_primary : int in range(0, palette.size() - 1):
		for index_secondary : int in range(index_primary, palette.size()):
			if(palette[index_secondary].r < palette[index_primary].r):
				var temp : Color = palette[index_primary]
				palette[index_primary] = palette[index_secondary]
				palette[index_secondary] = temp
	return

# replaces the intensity_range with the colors currently in the image
func _update_intensity_range() -> void:
	intensity_range8 = Vector2(COLOR_CHANNEL_MAX8, COLOR_CHANNEL_MIN8)
	for row : int in range(image.get_height()):
		for col : int in range(image.get_width()):
			var pixel : Color = image.get_pixel(col, row)
			if(pixel.r8 < intensity_range8.x):
				intensity_range8.x = pixel.r8
			if(pixel.r8 > intensity_range8.y):
				intensity_range8.y = pixel.r8
	return

# fill palette with possible colors based on num_colors and intensity range
func _build_palette_from_intensity_range8(num_colors : int) -> void:
	var step : int = int(float(intensity_range8.y - intensity_range8.x) / float(num_colors - 1))
	palette.resize(num_colors)
	var intensity_palette : int = intensity_range8.x
	for index_palette : int in range(palette.size()):
		var pixel_palette : Color = Color.from_rgba8(intensity_palette, intensity_palette, intensity_palette, COLOR_CHANNEL_MAX8)
		palette[index_palette] = pixel_palette
		intensity_palette += step
	return

# returns the index of the color in the palette that most closely resembles the given color
func _nearest_palette_index(color : Color) -> int:
	var index_nearest : int = -1
	var distance : float = 1.0
	for index_palette : int in range(palette.size()):
		var current_color_distance : float = _color_distance(palette[index_palette], color)
		if(abs(current_color_distance) < distance):
			index_nearest = index_palette
			distance = current_color_distance
	return index_nearest

# returns the index of the color in the palette that is even and most closely resembles the given color
func _nearest_palette_index_even(color : Color) -> int:
	var index_nearest : int = -1
	var distance : float = 1.0
	for index_palette : int in range(0, palette.size(), 2):
		var current_color_distance : float = _color_distance(palette[index_palette], color)
		if(abs(current_color_distance) < distance):
			index_nearest = index_palette
			distance = current_color_distance
	return index_nearest

# returns the euclidean distance between two colors, negative if the manhattan distance is negative (color2 - color1)
func _color_distance(color1 : Color, color2 : Color) -> float:
	var distance : float = 0
	if(color1.r8 == color1.g8 and color1.r8 == color1.b8 and color2.r8 == color2.g8 and color2.r8 == color2.b8):
		# colors are grayscale, so we can use less expensive distance algorithm
		distance = color2.r - color1.r
	else:
		# colors are not grayscale, so we must use euclidean distance formula
		distance = sqrt((color2.r - color1.r) * (color2.r - color1.r) +
					(color2.g - color1.g) * (color2.g - color1.g) +
					(color2.b - color1.b) * (color2.b - color1.b))
		if((color2.r8 + color2.g8 + color2.b8) < (color1.r8 + color1.g8 + color1.b8)):
			distance *= -1.0
	return distance

func _is_even(value : int) -> bool:
	return value % 2 == 0
