extends "res://tests/manual/phases/phase_10d.gd"

func _run_phase_10c() -> void:
	# 10-C-1. Verify BillboardScreen Polygon2D and screen shader
	print("Verifying Phase 10-C-1 BillboardScreen...")
	var billboard = street_instance.get_node_or_null("BillboardScreen")
	if not billboard:
		printerr("FAIL 10-C-1: BillboardScreen Polygon2D not found in apartment_entrance!")
		get_tree().quit(1)
		return
	if billboard.material == null:
		printerr("FAIL 10-C-1: BillboardScreen has no ShaderMaterial!")
		get_tree().quit(1)
		return
	var ad_paths := []
	for carousel in street_instance.BILLBOARD_CAROUSELS:
		ad_paths.append_array(carousel.get("ads", []))
	var loaded_ads := 0
	for ad_path in ad_paths:
		if ResourceLoader.exists(ad_path):
			loaded_ads += 1
	if loaded_ads < 2:
		printerr("FAIL 10-C-1: billboard carousel needs >=2 loadable ad stills, found %d!" % loaded_ads)
		get_tree().quit(1)
		return
	if (billboard.material as ShaderMaterial).get_shader_parameter("glitch_amount") == null:
		printerr("FAIL 10-C-1: billboard shader missing glitch_amount uniform for carousel transitions!")
		get_tree().quit(1)
		return
	print("PASS: Phase 10-C-1 BillboardScreen carousel (%d ads) and glitch uniform verified." % loaded_ads)

	# 10-C-2. Verify GlowLayers, ReflectionStrip, StreetLights
	print("Verifying Phase 10-C-2 nodes (glow overlays, reflection, lights)...")
	var glow_layers = street_instance.get_node_or_null("GlowLayers")
	if not glow_layers or glow_layers.get_child_count() == 0:
		printerr("FAIL 10-C-2: GlowLayers node missing or empty!")
		get_tree().quit(1)
		return
	var alley_glow = street_instance.get_node_or_null("GlowLayers/AlleyNeonGlow")
	if not alley_glow or (alley_glow as Polygon2D).material == null:
		printerr("FAIL 10-C-2: AlleyNeonGlow Polygon2D or its CanvasItemMaterial missing!")
		get_tree().quit(1)
		return
	var reflection = street_instance.get_node_or_null("ReflectionStrip")
	if not reflection or (reflection as Polygon2D).material == null:
		printerr("FAIL 10-C-2: ReflectionStrip Polygon2D or its ShaderMaterial missing!")
		get_tree().quit(1)
		return
	var street_lights = street_instance.get_node_or_null("StreetLights")
	if not street_lights or street_lights.get_child_count() == 0:
		printerr("FAIL 10-C-2: StreetLights node missing or empty!")
		get_tree().quit(1)
		return
	print("PASS: Phase 10-C-2 GlowLayers / ReflectionStrip / StreetLights verified.")

