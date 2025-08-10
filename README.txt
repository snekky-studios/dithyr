Algorithm:
	1. Convert image to grayscale
	2. Bin each pixel according to grayscale intensity (0, 1, 2, etc.)
	3. Round each pixel to its nearest grayscale value
	4. Dither each odd color index using the indexes above and below
	5. Map grayscale values to a different color palette and swap
