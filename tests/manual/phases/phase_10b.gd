extends "res://tests/manual/phases/phase_10c.gd"

func _run_phase_10b() -> void:
	# 10-B. Verify unlayered visual base nodes (rain particles + vignette)
	# Note: CanvasModulate night tint was tried and dropped (didn't look good).
	print("Verifying Phase 10-B visual base...")
	var rain_far = street_instance.get_node_or_null("Camera2D/RainFar")
	var rain_near = street_instance.get_node_or_null("Camera2D/RainNear")
	var rain_splash = street_instance.get_node_or_null("Camera2D/RainSplash")
	if not rain_far or not rain_near or not rain_splash:
		printerr("FAIL 10-B: RainFar/RainNear/RainSplash particle nodes missing under Camera2D!")
		get_tree().quit(1)
		return
	if rain_far.texture == null or rain_near.texture == null or rain_splash.texture == null:
		printerr("FAIL 10-B: Rain particle textures failed to load!")
		get_tree().quit(1)
		return
	if not rain_far.emitting or not rain_near.emitting or not rain_splash.emitting:
		printerr("FAIL 10-B: Rain particle layers should be emitting by default!")
		get_tree().quit(1)
		return
	var vignette_layer = street_instance.get_node_or_null("Vignette")
	var vignette_rect = street_instance.get_node_or_null("Vignette/VignetteRect")
	if not vignette_layer or not vignette_rect or vignette_rect.material == null:
		printerr("FAIL 10-B: Vignette CanvasLayer/ColorRect or shader material missing!")
		get_tree().quit(1)
		return
	print("PASS: Phase 10-B visual base nodes (rain particles, vignette) verified.")

