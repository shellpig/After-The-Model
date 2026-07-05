extends "res://tests/manual/phases/phase_7g.gd"

func _run_phase_7d() -> void:
	# 20. Verify Phase 7-D Apartment Window conditional entry
	print("Verifying Phase 7-D Apartment Window conditional entry...")

	# Reset state first
	GameState.reset_for_new_game()

	# Transition into apartment
	main_instance.transition_to("apartment", "wake_bed")
	await get_tree().process_frame

	var active_apartment = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("apartment_room.gd"):
			active_apartment = child
			break

	if not active_apartment:
		printerr("FAIL: Current scene is not apartment after transition!")
		get_tree().quit(1)
		return

	# Find ApartmentWindow interactable node in active_apartment
	var window_area = active_apartment.get_node_or_null("Interactables/ApartmentWindow")
	if not window_area:
		printerr("FAIL: ApartmentWindow not found under active_apartment/Interactables!")
		get_tree().quit(1)
		return

	# Test 20.1: Window NOT available before checked_alley (not started, or active but started step)
	# Case A: status = "" (not started)
	active_apartment._on_interactable_entered(window_area)

	active_apartment._refresh_current_interactable()
	if active_apartment.current_interactable == window_area:
		printerr("FAIL: Window should not be interactable when quest is not started!")
		get_tree().quit(1)
		return
	print("PASS: Window interaction correctly disabled when quest is not started.")

	active_apartment._on_interactable_exited(window_area)

	# Case B: active + step=started (started, but not yet checked_alley)
	QuestManager.start("alley_backrooms_3f")
	if QuestManager.get_status("alley_backrooms_3f") != "active" or QuestManager.get_step("alley_backrooms_3f") != "started":
		printerr("FAIL: Quest not correctly initialized to started state!")
		get_tree().quit(1)
		return

	active_apartment._on_interactable_entered(window_area)
	active_apartment._refresh_current_interactable()
	if active_apartment.current_interactable == window_area:
		printerr("FAIL: Window should not be interactable when quest step is started!")
		get_tree().quit(1)
		return
	print("PASS: Window interaction correctly disabled when quest step is started.")

	active_apartment._on_interactable_exited(window_area)

	# Test 20.2: Start quest and advance to checked_alley
	QuestManager.advance("alley_backrooms_3f", "checked_alley")
	if QuestManager.get_step("alley_backrooms_3f") != "checked_alley":
		printerr("FAIL: Quest step is not checked_alley!")
		get_tree().quit(1)
		return

	active_apartment._on_interactable_entered(window_area)
	active_apartment._refresh_current_interactable()
	if active_apartment.current_interactable != window_area:
		printerr("FAIL: Window should be interactable when quest step is checked_alley!")
		get_tree().quit(1)
		return
	if not "爬出窗外" in tr(active_apartment.current_interactable.prompt_text):
		printerr("FAIL: Window prompt text is wrong! Got: ", active_apartment.current_interactable.prompt_text)
		get_tree().quit(1)
		return
	print("PASS: Window interaction enabled with correct prompt after checked_alley.")

	# Test 20.3: Interact with window and verify transition request
	var last_transition_data = {}
	_temp_callable = func(scene_id, entry_point_id, payload):
		last_transition_data["scene_id"] = scene_id
		last_transition_data["entry_point_id"] = entry_point_id
		last_transition_data["payload"] = payload
	active_apartment.scene_transition_requested.connect(_temp_callable)

	active_apartment._trigger_interaction()

	if last_transition_data.get("scene_id") != "apartment_fire_escape":
		printerr("FAIL: Transition scene_id is not apartment_fire_escape! Got: ", last_transition_data)
		get_tree().quit(1)
		return
	if last_transition_data.get("entry_point_id") != "from_window":
		printerr("FAIL: Transition entry_point_id is not from_window! Got: ", last_transition_data)
		get_tree().quit(1)
		return
	print("PASS: Window interaction correctly emits scene_transition_requested to fire escape.")

	active_apartment.scene_transition_requested.disconnect(_temp_callable)
	active_apartment._on_interactable_exited(window_area)

	# Test 20.4: Verify from_fire_escape entry point positioning and monologue suppression
	GameState.reset_for_new_game()

	main_instance.transition_to("apartment", "from_fire_escape")
	await get_tree().process_frame

	var active_apartment_from_escape = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("apartment_room.gd"):
			active_apartment_from_escape = child
			break

	if not active_apartment_from_escape:
		printerr("FAIL: Current scene is not apartment after transition from fire escape!")
		get_tree().quit(1)
		return

	var player_node = active_apartment_from_escape.get_node("Player")
	if abs(player_node.global_position.x - 1000.0) > 1.0 or abs(player_node.global_position.y - 700.0) > 1.0:
		printerr("FAIL: Player position is not near window at (1000, 700)! Got: ", player_node.global_position)
		get_tree().quit(1)
		return

	if active_apartment_from_escape._opening_monologue_active:
		printerr("FAIL: Opening monologue should be suppressed when entering from_fire_escape!")
		get_tree().quit(1)
		return

	print("PASS: from_fire_escape entry point positioning and monologue suppression verified.")

