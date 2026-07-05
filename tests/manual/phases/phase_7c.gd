extends "res://tests/manual/phases/phase_7d.gd"

func _run_phase_7c() -> void:
	# 19. Verify Phase 7-C apartment_entrance alley_view quest event
	print("Verifying Phase 7-C apartment_entrance alley_view quest event...")

	# Reset state first
	GameState.reset_for_new_game()

	# Transition into apartment_entrance
	main_instance.transition_to("apartment_entrance", "from_apartment")
	await get_tree().process_frame

	var active_street = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("apartment_entrance.gd"):
			active_street = child
			break

	if not active_street:
		printerr("FAIL: Current scene is not apartment_entrance after transition!")
		get_tree().quit(1)
		return

	# Find alley_view interactable node in active_street
	var alley_area = active_street.get_node_or_null("Interactables/AlleyViewArea")
	if not alley_area:
		printerr("FAIL: AlleyViewArea not found under active_street/Interactables!")
		get_tree().quit(1)
		return

	# Test BEFORE quest is started (should return default message)
	var last_interaction_data = {}
	_temp_callable = func(data):
		last_interaction_data.clear()
		last_interaction_data.merge(data)
	active_street.interaction_requested.connect(_temp_callable)

	active_street.current_interactable = alley_area
	active_street._trigger_interaction()

	if last_interaction_data.get("type") != "message":
		printerr("FAIL: Interaction type is not 'message' before quest started! Got data: ", last_interaction_data)
		get_tree().quit(1)
		return
	if not "右側暗巷深得像" in last_interaction_data.get("message_text", ""):
		printerr("FAIL: Default alley_view message is wrong! Got: ", last_interaction_data.get("message_text"))
		get_tree().quit(1)
		return
	print("PASS: Default alley_view message verified when quest is not active.")

	# Test AFTER quest is started (should advance quest and show danger message)
	QuestManager.start("alley_backrooms_3f")
	if QuestManager.get_status("alley_backrooms_3f") != "active" or QuestManager.get_step("alley_backrooms_3f") != "started":
		printerr("FAIL: Failed to initialize quest state to started!")
		get_tree().quit(1)
		return

	last_interaction_data.clear()
	active_street._trigger_interaction()

	if not "暗巷深處有幾具損毀" in last_interaction_data.get("message_text", ""):
		printerr("FAIL: Danger alley_view message is wrong! Got: ", last_interaction_data.get("message_text"))
		get_tree().quit(1)
		return
	if last_interaction_data.get("note_title", "") == "":
		printerr("FAIL: note_title should be present to show note update toast!")
		get_tree().quit(1)
		return

	# Check if quest stepped advanced
	if QuestManager.get_step("alley_backrooms_3f") != "checked_alley":
		printerr("FAIL: Quest step did not advance to 'checked_alley' after interaction!")
		get_tree().quit(1)
		return
	print("PASS: Quest advanced and danger message shown on first active interaction.")

	# Test SECOND interaction when quest step is checked_alley (should show danger message but NOT change state)
	last_interaction_data.clear()
	active_street._trigger_interaction()

	if not "暗巷深處有幾具損毀" in last_interaction_data.get("message_text", ""):
		printerr("FAIL: Danger message should be shown on subsequent active interactions!")
		get_tree().quit(1)
		return
	if QuestManager.get_step("alley_backrooms_3f") != "checked_alley":
		printerr("FAIL: Quest step changed incorrectly on duplicate interaction!")
		get_tree().quit(1)
		return
	print("PASS: Duplicate interaction does not alter quest step.")

	# Clean up signal connection
	active_street.interaction_requested.disconnect(_temp_callable)

