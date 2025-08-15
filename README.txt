Algorithm:
	1. Convert image to grayscale
	2. Create target grayscale palette (number of desired colors * 2 - 1)
	3. For each pixel:
		a. if nearest color in the palette is in an even index, change to that color
		b. else change to nearest even index and propogate error to surrounding pixels
	
	
	
	
	2. Bin each pixel according to grayscale intensity (0, 1, 2, etc.)
	3. Round each pixel to its nearest grayscale value
	4. Dither each odd color index using the indexes above and below
	5. Map grayscale values to a different color palette and swap
