class_name DissolveTextures
extends RefCounted
## Procedural dissolve shader textures for enemy death VFX.

const NOISE_SIZE := 64


static func make_noise_texture() -> ImageTexture:
	var noise_img := Image.create(NOISE_SIZE, NOISE_SIZE, false, Image.FORMAT_L8)
	var pixels := noise_img.get_data()
	for i in range(pixels.size()):
		pixels[i] = randi() % 256
	noise_img.set_data(NOISE_SIZE, NOISE_SIZE, false, Image.FORMAT_L8, pixels)
	return ImageTexture.create_from_image(noise_img)


static func make_overlay_texture() -> ImageTexture:
	var overlay_img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	overlay_img.fill(Color.WHITE)
	return ImageTexture.create_from_image(overlay_img)
