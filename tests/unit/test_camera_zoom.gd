extends TestCase
## Camera zoom must give whole screen pixels per world pixel (crisp pixel art) and a
## view close to the target height.


func test_720p_window() -> void:
	# 1280×720 window, 640×360 viewport: 3 screen px per world px, 240 px visible.
	var z := CameraRig.pixel_perfect_zoom(720.0, 360.0, 240.0)
	assert_near(z, 1.5)
	assert_near(360.0 / z, 240.0)


func test_1080p_window_uses_whole_pixels() -> void:
	var z := CameraRig.pixel_perfect_zoom(1080.0, 360.0, 240.0)
	var screen_pixels_per_world_pixel := z * 1080.0 / 360.0
	assert_near(screen_pixels_per_world_pixel, roundf(screen_pixels_per_world_pixel))
	assert_true(360.0 / z >= 200.0 and 360.0 / z <= 280.0, "view height near the target")


func test_tiny_window_never_zooms_below_one_pixel() -> void:
	var z := CameraRig.pixel_perfect_zoom(200.0, 360.0, 240.0)
	assert_near(z * 200.0 / 360.0, 1.0)
