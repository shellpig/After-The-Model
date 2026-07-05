extends "res://tests/manual/phases/phase_7h.gd"

func _run_phase_7g() -> void:
	# Test 21: Verify 7-G Fire Escape Target Box Search & Activation Box Retrieval
	print("Verifying Phase 7-G Fire Escape Target Box Search & Retrieval...")
	# 1. Load fire escape scene
	var escape_scene = load("res://scenes/levels/apartment_fire_escape/apartment_fire_escape.tscn")
	if not escape_scene:
		printerr("FAIL: Could not load apartment_fire_escape.tscn!")
		get_tree().quit(1)
		return
	escape_instance = escape_scene.instantiate()
	add_child(escape_instance)

	# 2. Reset quest states and inventory
	GameState.reset_for_new_game()

	# 3. Initially, when quest not started, target box interaction should show locked message
	var box_area = escape_instance.get_node("Interactables/QuestBox")
	if not box_area:
		printerr("FAIL: QuestBox interactable not found in fire escape scene!")
		get_tree().quit(1)
		return

	escape_instance._on_interactable_entered(box_area)

	var test_state = {
		"message_text": "",
		"on_closed": Callable()
	}
	var test_callback = func(data):
		if data.get("type") == "message":
			test_state["message_text"] = data.get("message_text", "")
			test_state["on_closed"] = data.get("on_closed", Callable())
	escape_instance.interaction_requested.connect(test_callback)

	# Trigger E interaction when quest is not started
	escape_instance._handle_primary_interaction()
	if test_state["message_text"] != escape_instance.MESSAGES["quest_box_locked"]:
		printerr("FAIL: Box interaction should be locked when quest not started! Got: ", test_state["message_text"])
		get_tree().quit(1)
		return
	print("PASS: Locked message shown correctly when quest is not started.")

	# 4. Start quest, but step is not checked_alley (it's started)
	QuestManager.start("alley_backrooms_3f")
	test_state["message_text"] = ""
	test_state["on_closed"] = Callable()
	escape_instance._handle_primary_interaction()
	if test_state["message_text"] != escape_instance.MESSAGES["quest_box_locked"]:
		printerr("FAIL: Box interaction should be locked when quest step is started! Got: ", test_state["message_text"])
		get_tree().quit(1)
		return
	print("PASS: Locked message shown correctly when quest step is started.")

	# 5. Advance quest to checked_alley, but fill player inventory (so item add fails)
	QuestManager.advance("alley_backrooms_3f", "checked_alley")

	# Fill all inventory slots (simulate bag full)
	for i in range(GameState.inventory_slots):
		GameState.inventory[i] = {
			"instance_id": GameState.generate_instance_id(),
			"item_id": "canned_food",
			"quantity": 5
		}

	test_state["message_text"] = ""
	test_state["on_closed"] = Callable()
	escape_instance._handle_primary_interaction()

	if test_state["message_text"] != escape_instance.MESSAGES["quest_box_search_quiet"]:
		printerr("FAIL: Box search message should be shown when step is checked_alley! Got: ", test_state["message_text"])
		get_tree().quit(1)
		return

	# Call on_closed to simulate search complete
	if test_state["on_closed"].is_null():
		printerr("FAIL: on_closed callback is null when searching box!")
		get_tree().quit(1)
		return

	var on_closed_callback_full = test_state["on_closed"]
	test_state["message_text"] = ""
	test_state["on_closed"] = Callable()

	on_closed_callback_full.call()

	if test_state["message_text"] != escape_instance.MESSAGES["inventory_full_for_activation_box"]:
		printerr("FAIL: Inventory full warning not shown! Got: ", test_state["message_text"])
		get_tree().quit(1)
		return

	# Quest state and flag should remain unchanged
	if QuestManager.get_step("alley_backrooms_3f") != "checked_alley" or QuestManager.get_flag("alley_backrooms_3f", "found_activation_box", false):
		printerr("FAIL: Quest state advanced even when inventory was full!")
		get_tree().quit(1)
		return
	print("PASS: Box search correctly handles inventory full state without changing quest flags.")

	# 6. Clear inventory space and try again
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})

	test_state["message_text"] = ""
	test_state["on_closed"] = Callable()
	escape_instance._handle_primary_interaction()

	if test_state["message_text"] != escape_instance.MESSAGES["quest_box_search_quiet"]:
		printerr("FAIL: Box search message should be shown again! Got: ", test_state["message_text"])
		get_tree().quit(1)
		return

	# Call on_closed again (now bag has space)
	var on_closed_callback_ok = test_state["on_closed"]
	test_state["message_text"] = ""
	test_state["on_closed"] = Callable()

	on_closed_callback_ok.call()

	# Item should be in inventory
	if not GameState.has_item("early_ai_assistant_activation_box", 1):
		printerr("FAIL: activation box item was not added to inventory!")
		get_tree().quit(1)
		return

	# Quest state should be advanced to found_activation_box
	if QuestManager.get_step("alley_backrooms_3f") != "found_activation_box":
		printerr("FAIL: Quest step did not advance to found_activation_box! Got: ", QuestManager.get_step("alley_backrooms_3f"))
		get_tree().quit(1)
		return

	if not QuestManager.get_flag("alley_backrooms_3f", "found_activation_box", false):
		printerr("FAIL: found_activation_box flag was not set on quest!")
		get_tree().quit(1)
		return

	# The final box obtained message should be shown
	if test_state["message_text"] != escape_instance.MESSAGES["quest_box_obtained_box"]:
		printerr("FAIL: Box obtained message was incorrect! Got: ", test_state["message_text"])
		get_tree().quit(1)
		return

	print("PASS: Box search correctly advanced and final message shown.")

	# 7. Once found, closest interactable check should ignore the quest box
	escape_instance.interaction_requested.disconnect(test_callback)
	escape_instance._refresh_current_interactable()
	if escape_instance.current_interactable == box_area:
		printerr("FAIL: Quest box should be ignored once activation box has been found!")
		get_tree().quit(1)
		return
	print("PASS: Quest box ignored once item has been retrieved.")

