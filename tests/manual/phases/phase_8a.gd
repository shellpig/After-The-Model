extends "res://tests/manual/phases/phase_8b.gd"

func _run_phase_8a() -> void:
	# 26. Verify Phase 8-A Convenience Store Scene Skeleton & Transitions
	print("Verifying Phase 8-A Convenience Store scene skeleton & transitions...")

	GameState.reset_for_new_game()
	ui_instance.close_message()
	await get_tree().process_frame

	# 26.1 SceneRegistry checks
	var scenes_dict_8a = main_instance.get("SCENES")
	if not scenes_dict_8a.has("convenience_store"):
		printerr("FAIL: SCENES registry is missing 'convenience_store' key!")
		get_tree().quit(1)
		return
	var store_cfg = scenes_dict_8a["convenience_store"]
	if store_cfg.get("path") != "res://scenes/levels/convenience_store/convenience_store.tscn":
		printerr("FAIL: convenience_store registry path is wrong! Got: ", store_cfg.get("path"))
		get_tree().quit(1)
		return
	if not "from_street" in store_cfg.get("entry_points", []) or store_cfg.get("default_entry_point_id") != "from_street":
		printerr("FAIL: convenience_store entry point 'from_street' not registered correctly!")
		get_tree().quit(1)
		return
	if not "from_store" in scenes_dict_8a["apartment_entrance"].get("entry_points", []):
		printerr("FAIL: apartment_entrance entry point 'from_store' not registered!")
		get_tree().quit(1)
		return
	print("PASS: SceneRegistry contains convenience_store (from_street) and apartment_entrance gains from_store.")

	# 26.2 Load & instantiate standalone, verify level contract + entry point
	var store_scene = load("res://scenes/levels/convenience_store/convenience_store.tscn")
	if not store_scene:
		printerr("FAIL: Could not load convenience_store.tscn!")
		get_tree().quit(1)
		return
	var store_instance = store_scene.instantiate()
	add_child(store_instance)

	if not store_instance.has_signal("current_interactable_changed") \
		or not store_instance.has_signal("interaction_requested") \
		or not store_instance.has_signal("scene_transition_requested"):
		printerr("FAIL: convenience_store is missing level contract signals!")
		get_tree().quit(1)
		return
	if not store_instance.has_method("prepare_entry_point") or not store_instance.has_method("set_entry_point"):
		printerr("FAIL: convenience_store is missing entry point API!")
		get_tree().quit(1)
		return

	store_instance.set_entry_point("from_street", {})
	var store_spawn = store_instance.get_node_or_null("SpawnPoints/from_street")
	if not store_spawn:
		printerr("FAIL: SpawnPoints/from_street not found in convenience_store!")
		get_tree().quit(1)
		return
	var store_player = store_instance.get_node("Player")
	if abs(store_player.global_position.x - store_spawn.global_position.x) > 1.0:
		printerr("FAIL: Player not positioned at from_street spawn! Got: ", store_player.global_position)
		get_tree().quit(1)
		return
	if not SaveSystem.can_save_here:
		printerr("FAIL: can_save_here is not true inside convenience_store!")
		get_tree().quit(1)
		return
	print("PASS: convenience_store loads with contract signals, from_street spawn, and can_save_here true.")

	# 26.3 Auto door emits transition back to street at from_store
	var store_transition_data = {}
	_temp_callable = func(scene_id, entry_point_id, payload):
		store_transition_data["scene_id"] = scene_id
		store_transition_data["entry_point_id"] = entry_point_id
		store_transition_data["payload"] = payload
	store_instance.scene_transition_requested.connect(_temp_callable)

	var auto_door_area = store_instance.get_node_or_null("Interactables/AutoDoorArea")
	if not auto_door_area:
		printerr("FAIL: AutoDoorArea not found in convenience_store!")
		get_tree().quit(1)
		return
	store_instance.current_interactable = auto_door_area
	store_instance._trigger_interaction()

	if store_transition_data.get("scene_id") != "apartment_entrance" or store_transition_data.get("entry_point_id") != "from_store":
		printerr("FAIL: Auto door transition request is wrong! Got: ", store_transition_data)
		get_tree().quit(1)
		return
	store_instance.scene_transition_requested.disconnect(_temp_callable)
	print("PASS: Store auto door emits scene_transition_requested(apartment_entrance, from_store).")

	# 26.4 Locked back door shows message only
	var store_interaction_data = {}
	_temp_callable = func(data):
		store_interaction_data.clear()
		store_interaction_data.merge(data)
	store_instance.interaction_requested.connect(_temp_callable)

	var back_door_area = store_instance.get_node_or_null("Interactables/BackDoorArea")
	if not back_door_area:
		printerr("FAIL: BackDoorArea not found in convenience_store!")
		get_tree().quit(1)
		return
	store_instance.current_interactable = back_door_area
	store_instance._trigger_interaction()

	if store_interaction_data.get("type") != "message" \
		or store_interaction_data.get("message_text") != store_instance.MESSAGES["back_door"]:
		printerr("FAIL: Back door did not show locked message! Got: ", store_interaction_data)
		get_tree().quit(1)
		return
	store_instance.interaction_requested.disconnect(_temp_callable)
	store_instance.free()
	print("PASS: Locked back door shows message only.")

	# 26.5 Street store_front now emits transition into the store
	main_instance.transition_to("apartment_entrance", "from_apartment")
	await get_tree().process_frame

	var street_8a = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("apartment_entrance.gd"):
			street_8a = child
			break
	if not street_8a:
		printerr("FAIL: Current scene is not apartment_entrance after transition!")
		get_tree().quit(1)
		return

	if not street_8a.get_node_or_null("SpawnPoints/from_store"):
		printerr("FAIL: SpawnPoints/from_store not found in apartment_entrance!")
		get_tree().quit(1)
		return

	var store_front_area = street_8a.get_node_or_null("Interactables/StoreFrontArea")
	if not store_front_area:
		printerr("FAIL: StoreFrontArea not found in apartment_entrance!")
		get_tree().quit(1)
		return

	store_transition_data.clear()
	_temp_callable = func(scene_id, entry_point_id, payload):
		store_transition_data["scene_id"] = scene_id
		store_transition_data["entry_point_id"] = entry_point_id
		store_transition_data["payload"] = payload
	street_8a.scene_transition_requested.connect(_temp_callable)

	street_8a.current_interactable = store_front_area
	street_8a._trigger_interaction()

	if store_transition_data.get("scene_id") != "convenience_store" or store_transition_data.get("entry_point_id") != "from_street":
		printerr("FAIL: store_front transition request is wrong! Got: ", store_transition_data)
		get_tree().quit(1)
		return
	street_8a.scene_transition_requested.disconnect(_temp_callable)
	print("PASS: Street store_front emits scene_transition_requested(convenience_store, from_street).")

	# 26.6 Real two-way transition through the SceneRouter
	main_instance.transition_to("convenience_store", "from_street")
	await get_tree().process_frame

	var active_store = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("convenience_store.gd"):
			active_store = child
			break
	if not active_store:
		printerr("FAIL: Current scene is not convenience_store after router transition!")
		get_tree().quit(1)
		return
	if not SaveSystem.can_save_here:
		printerr("FAIL: can_save_here is not true after router transition into store!")
		get_tree().quit(1)
		return

	main_instance.transition_to("apartment_entrance", "from_store")
	await get_tree().process_frame

	var street_back_8a = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("apartment_entrance.gd"):
			street_back_8a = child
			break
	if not street_back_8a:
		printerr("FAIL: Current scene is not apartment_entrance after leaving store!")
		get_tree().quit(1)
		return
	var street_back_spawn = street_back_8a.get_node("SpawnPoints/from_store")
	var street_back_player = street_back_8a.get_node("Player")
	if abs(street_back_player.global_position.x - street_back_spawn.global_position.x) > 1.0:
		printerr("FAIL: Player not positioned at from_store spawn after leaving store! Got: ", street_back_player.global_position)
		get_tree().quit(1)
		return
	print("PASS: Two-way street <-> store transition via SceneRouter verified.")

	# 26.7 Save/load round-trip inside the store
	main_instance.transition_to("convenience_store", "from_street")
	await get_tree().process_frame

	var save_store = SaveSystem.capture("convenience_store", 900.0, -1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_store):
		printerr("FAIL: Failed to write store save to scratch slot!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	if not main_instance.load_game_slot(TEST_SCRATCH_SAVE_SLOT):
		printerr("FAIL: load_game_slot(scratch slot) failed for store save!")
		get_tree().quit(1)
		return
	await get_tree().process_frame

	var restored_store = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("convenience_store.gd"):
			restored_store = child
			break
	if not restored_store:
		printerr("FAIL: Loaded scene is not convenience_store after store save round-trip!")
		get_tree().quit(1)
		return
	var restored_player = restored_store.get_node("Player")
	if abs(restored_player.global_position.x - 900.0) > 1.0:
		printerr("FAIL: Player x not restored to 900 in store! Got: ", restored_player.global_position.x)
		get_tree().quit(1)
		return
	if restored_player.get_facing() != -1:
		printerr("FAIL: Player facing not restored to -1 in store!")
		get_tree().quit(1)
		return
	if not SaveSystem.can_save_here:
		printerr("FAIL: can_save_here is not true after loading a store save!")
		get_tree().quit(1)
		return
	print("PASS: Store save/load round-trip restores scene, position, and facing.")

	# Clean up scratch slot and release store scene reference
	if dir and dir.file_exists(TEST_SCRATCH_SAVE_FILE):
		dir.remove(TEST_SCRATCH_SAVE_FILE)
	store_scene = null

	print("PASS: Phase 8-A Convenience Store scene skeleton & transitions verified successfully.")
