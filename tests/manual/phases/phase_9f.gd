extends "res://tests/manual/phases/phase_9g.gd"

func _run_phase_9f() -> void:
	# Phase 9-F Verification
	# ----------------------------------------------------
	print("Running 9-F Integration tests...")

	# 1. Verify files exist
	if not FileAccess.file_exists("res://assets/images/echoes/echo_room401_tenant.png"):
		printerr("FAIL 9-F: echo_room401_tenant.png is missing!")
		get_tree().quit(1)
		return

	if not FileAccess.file_exists("res://assets/bgm/Vintage Media Shop.mp3"):
		printerr("FAIL 9-F: Vintage Media Shop.mp3 is missing!")
		get_tree().quit(1)
		return

	# 2. Verify EchoPoints in scenes
	var scene_tests = [
		{
			"path": "res://scenes/levels/apartment_fire_escape/apartment_fire_escape.tscn",
			"points": [
				{"node": "Interactables/EchoPointS1", "echo": "echo_room401_tenant", "seg": "s1"},
				{"node": "Interactables/EchoPoint", "echo": "echo_room401_tenant", "seg": "s2"}
			]
		},
		{
			"path": "res://scenes/levels/apartment_entrance.tscn",
			"points": [
				{"node": "Interactables/EchoPoint1", "echo": "echo_room401_tenant", "seg": "s3"},
				{"node": "Interactables/EchoPoint2", "echo": "echo_song_rain_doesnt_stop", "seg": "s1"},
				{"node": "Interactables/EchoPoint3", "echo": "echo_song_rain_doesnt_stop", "seg": "s2"}
			]
		},
		{
			"path": "res://scenes/levels/convenience_store/convenience_store.tscn",
			"points": [
				{"node": "Interactables/EchoPoint", "echo": "echo_song_rain_doesnt_stop", "seg": "s3"}
			]
		},
		{
			"path": "res://scenes/levels/collector_shop/collector_shop.tscn",
			"points": [
				{"node": "Interactables/EchoPoint", "echo": "echo_lu_family", "seg": "s1"}
			]
		}
	]

	for s_info in scene_tests:
		var scene_path = s_info["path"]
		var scene_res = load(scene_path)
		if not scene_res:
			printerr("FAIL 9-F: Could not load scene: ", scene_path)
			get_tree().quit(1)
			return
		var inst = scene_res.instantiate()
		for p_info in s_info["points"]:
			var node_path = p_info["node"]
			var pt = inst.get_node_or_null(node_path)
			if not pt:
				printerr("FAIL 9-F: EchoPoint not found at path: ", node_path, " in scene: ", scene_path)
				inst.free()
				get_tree().quit(1)
				return
			if pt.echo_id != p_info["echo"] or pt.segment_id != p_info["seg"]:
				printerr("FAIL 9-F: Incorrect configuration on EchoPoint: ", node_path, " in scene: ", scene_path, " - Got: ", pt.echo_id, "/", pt.segment_id)
				inst.free()
				get_tree().quit(1)
				return

			# Verify that it has a CollisionShape2D with a CircleShape2D shape
			var col = pt.get_node_or_null("CollisionShape2D")
			if not col or not col.shape is CircleShape2D:
				printerr("FAIL 9-F: EchoPoint at ", node_path, " is missing a CircleShape2D CollisionShape!")
				inst.free()
				get_tree().quit(1)
				return
		inst.free()

	# Verify collector_shop plays the new BGM by checking the script source directly
	var shop_script = load("res://scenes/levels/collector_shop/collector_shop.gd")
	var script_src = shop_script.source_code
	if not "res://assets/bgm/Vintage Media Shop.mp3" in script_src:
		printerr("FAIL 9-F: collector_shop.gd does not reference 'res://assets/bgm/Vintage Media Shop.mp3'!")
		get_tree().quit(1)
		return

	print("PASS 9-F: All 7 EchoPoints configured across level scenes, BGM path and old-photo asset presence verified.")

	# ----------------------------------------------------
