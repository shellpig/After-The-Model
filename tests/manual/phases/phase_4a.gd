extends "res://tests/manual/phases/phase_4e.gd"

func _run_phase_4a() -> void:
	# 10. Verify Phase 4-A Main Scene, SceneRouter & SceneRegistry
	print("Verifying Phase 4-A Main Scene configuration...")
	var main_scene_setting = ProjectSettings.get_setting("application/run/main_scene")
	if main_scene_setting != "res://scenes/ui/title_screen.tscn":
		printerr("FAIL: Main scene setting in project.godot is not 'res://scenes/ui/title_screen.tscn'! Got: ", main_scene_setting)
		get_tree().quit(1)
		return
	print("PASS: project.godot configured to use res://scenes/ui/title_screen.tscn.")

	print("Loading res://scenes/main/main.tscn...")
	var main_scene = load("res://scenes/main/main.tscn")
	if not main_scene:
		printerr("FAIL: Could not load main.tscn!")
		get_tree().quit(1)
		return
	print("PASS: main.tscn loaded successfully.")

	main_instance = main_scene.instantiate()
	add_child(main_instance)
	print("PASS: main.tscn instantiated in scene tree.")

	print("Verifying Main scene hierarchy...")
	var world_root_node = main_instance.get_node_or_null("WorldRoot")
	if not world_root_node:
		printerr("FAIL: WorldRoot node not found in Main scene!")
		get_tree().quit(1)
		return
	print("PASS: WorldRoot node exists in Main.")

	print("Verifying SceneRouter APIs on Main...")
	var required_methods = [
		"transition_to", "reload_current_scene",
		"get_current_scene_id", "get_current_entry_point_id"
	]
	for method in required_methods:
		if not main_instance.has_method(method):
			printerr("FAIL: Main script lacks required SceneRouter method: " + method)
			get_tree().quit(1)
			return
		print("PASS: Main script has method: " + method)

	print("Verifying SceneRegistry config on Main...")
	if not "SCENES" in main_instance:
		printerr("FAIL: SCENES registry dictionary not found in main.gd!")
		get_tree().quit(1)
		return
	var scenes_dict = main_instance.get("SCENES")
	if not scenes_dict.has("apartment") or not scenes_dict.has("apartment_entrance"):
		printerr("FAIL: SCENES registry is missing 'apartment' or 'apartment_entrance' keys!")
		get_tree().quit(1)
		return

	var apartment_config = scenes_dict["apartment"]
	if apartment_config.get("path") != "res://scenes/levels/apartment/apartment_room.tscn":
		printerr("FAIL: apartment path in registry is wrong!")
		get_tree().quit(1)
		return
	if apartment_config.get("default_entry_point_id") != "wake_bed":
		printerr("FAIL: apartment default_entry_point_id is wrong!")
		get_tree().quit(1)
		return

	var street_config = scenes_dict["apartment_entrance"]
	if street_config.get("path") != "res://scenes/levels/apartment_entrance.tscn":
		printerr("FAIL: apartment_entrance path in registry is wrong!")
		get_tree().quit(1)
		return
	print("PASS: SceneRegistry config verified.")

	print("Loading res://scenes/levels/apartment_entrance.tscn...")
	var street_scene = load("res://scenes/levels/apartment_entrance.tscn")
	if not street_scene:
		printerr("FAIL: Could not load apartment_entrance.tscn!")
		get_tree().quit(1)
		return
	print("PASS: apartment_entrance.tscn loaded successfully.")

	street_instance = street_scene.instantiate()
	add_child(street_instance)
	print("PASS: apartment_entrance.tscn instantiated in scene tree.")
	UIMode.set_mode(UIMode.Mode.NONE)

	if not street_instance.has_signal("current_interactable_changed") or not street_instance.has_signal("interaction_requested") or not street_instance.has_signal("scene_transition_requested"):
		printerr("FAIL: apartment_entrance lacks Level interaction contract signals!")
		get_tree().quit(1)
		return
	if not street_instance.has_method("prepare_entry_point") or not street_instance.has_method("set_entry_point"):
		printerr("FAIL: apartment_entrance lacks prepare_entry_point or set_entry_point API!")
		get_tree().quit(1)
		return

	street_instance.set_entry_point("from_apartment", {})
	var street_background = street_instance.get_node_or_null("Background")
	if not street_background or street_background.texture == null:
		printerr("FAIL: apartment_entrance Background texture failed to load!")
		get_tree().quit(1)
		return
	var street_camera = street_instance.get_node_or_null("Camera2D")
	if not street_camera or not street_camera.enabled:
		printerr("FAIL: apartment_entrance Camera2D is missing or disabled!")
		get_tree().quit(1)
		return
	var street_player = street_instance.get_node_or_null("Player")
	if not street_player:
		printerr("FAIL: apartment_entrance Player node missing!")
		get_tree().quit(1)
		return
	if street_player.global_position != Vector2(730, 675):
		printerr("FAIL: apartment_entrance from_apartment spawn is wrong! Got: ", street_player.global_position)
		get_tree().quit(1)
		return
	if street_player.get("walk_line_y") != 665.0 or street_player.get("min_x") != 80.0 or street_player.get("max_x") != 4000.0:
		printerr("FAIL: apartment_entrance player walk bounds are wrong!")
		get_tree().quit(1)
		return
	if not street_instance.get_node_or_null("Interactables/BackToApartmentArea"):
		printerr("FAIL: apartment_entrance back_to_apartment interactable missing!")
		get_tree().quit(1)
		return

	# Verify NpcWan properties
	var npc_wan = street_instance.get_node_or_null("Interactables/NpcWan")
	if not npc_wan:
		printerr("FAIL: NpcWan node not found in apartment_entrance scene!")
		get_tree().quit(1)
		return
	if npc_wan.interaction_id != "talk_wan" or npc_wan.dialogue_id != "wan" or npc_wan.prompt_text != "PROMPT_TALK":
		printerr("FAIL: NpcWan interaction properties are incorrect!")
		get_tree().quit(1)
		return

	var npc_sprite_anim = npc_wan.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if not npc_sprite_anim or npc_sprite_anim.sprite_frames == null:
		printerr("FAIL: NpcWan AnimatedSprite2D or sprite_frames is missing!")
		get_tree().quit(1)
		return
	print("PASS: NpcWan node structure and texture verified.")

	# Verify generalized dialogue dispatch
	var dispatch_signal_received = {"emitted": false, "dialogue_id": ""}
	street_instance.interaction_requested.connect(func(data):
		if data.get("type") == "dialogue":
			dispatch_signal_received["emitted"] = true
			dispatch_signal_received["dialogue_id"] = data.get("dialogue_id", "")
	)

	# Simulate player entering NPC interaction range and triggering E
	street_instance._on_interactable_entered(npc_wan)
	Input.action_press("interact_primary")
	street_instance._process(0.0)
	Input.action_release("interact_primary")

	if not dispatch_signal_received["emitted"] or dispatch_signal_received["dialogue_id"] != "wan":
		printerr("FAIL: Generalized dialogue dispatch failed to emit interaction_requested signal!")
		get_tree().quit(1)
		return
	print("PASS: Generalized dialogue dispatch verified.")

	print("PASS: apartment_entrance map scene, spawn, bounds, and contract verified.")

