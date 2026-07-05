extends "res://tests/manual/phases/phase_8a.gd"

func _run_phase_7j() -> void:
	# 24. Verify Phase 7-J Regression & Save/Restore
	print("Verifying Phase 7-J Regression & Save/Restore...")

	# 1. Quest Started Save/Load Check
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")

	var save_p1 = SaveSystem.capture("apartment", 100.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_p1):
		printerr("FAIL: Failed to write save_p1 to scratch slot!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	var loaded_p1 = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	SaveSystem.apply(loaded_p1)

	if QuestManager.get_status("alley_backrooms_3f") != "active" or QuestManager.get_step("alley_backrooms_3f") != "started":
		printerr("FAIL: Quest status/step was not restored correctly in started check!")
		get_tree().quit(1)
		return

	var notes_p1 = GameState.get_notes("工作")
	if notes_p1.is_empty() or notes_p1[0].get("id") != "quest_alley_backrooms_3f":
		printerr("FAIL: Quest work note not restored correctly in started check!")
		get_tree().quit(1)
		return
	print("PASS: Quest started state successfully saved and restored.")

	# 2. Alley Checked Save/Load Check
	QuestManager.advance("alley_backrooms_3f", "checked_alley")
	var save_p2 = SaveSystem.capture("apartment", 100.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_p2):
		printerr("FAIL: Failed to write save_p2 to scratch slot!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	var loaded_p2 = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	SaveSystem.apply(loaded_p2)

	if QuestManager.get_step("alley_backrooms_3f") != "checked_alley":
		printerr("FAIL: Quest step was not restored to checked_alley!")
		get_tree().quit(1)
		return

	# Verify window interaction gate in apartment_room
	var room_instance_j = room_scene.instantiate()
	add_child(room_instance_j)
	var win_area_j = room_instance_j.get_node_or_null("Interactables/ApartmentWindow")
	if not win_area_j:
		printerr("FAIL: ApartmentWindow not found in room_instance_j!")
		get_tree().quit(1)
		return
	room_instance_j._on_interactable_entered(win_area_j)
	room_instance_j._refresh_current_interactable()
	if room_instance_j.current_interactable != win_area_j:
		printerr("FAIL: ApartmentWindow was not interactable after restore from checked_alley!")
		get_tree().quit(1)
		return
	room_instance_j.queue_free()
	print("PASS: Checked_alley state and window interaction gate successfully saved and restored.")

	# 3. Activation Box Found Save/Load Check (Inspectable A)
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
	GameState.add_item("early_ai_assistant_activation_box", 1)

	var save_p3 = SaveSystem.capture("apartment", 100.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_p3):
		printerr("FAIL: Failed to write save_p3 to scratch slot!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	var loaded_p3 = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	SaveSystem.apply(loaded_p3)

	if not GameState.has_item("early_ai_assistant_activation_box", 1) or GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: Items not restored correctly in found_activation_box check!")
		get_tree().quit(1)
		return

	# Retrieve box instance id and verify we can inspect A to get B
	var box_inst_id := ""
	for slot in GameState.get_inventory():
		if slot.get("item_id", "") == "early_ai_assistant_activation_box":
			box_inst_id = slot.get("instance_id", "")
			break

	# Instantiate UI for modal check
	ui_instance_j = ui_scene.instantiate()
	add_child(ui_instance_j)
	ui_instance_j.open_inventory()
	ui_instance_j._on_bag_item_action("view", box_inst_id)
	ui_instance_j.force_finish_message()
	var view_callback = ui_instance_j._message_on_closed
	ui_instance_j.close_message()
	view_callback.call()

	if not GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: old_ai_authorization_module (B) was not obtained on inspect after load!")
		get_tree().quit(1)
		return
	print("PASS: Item A state restored, and inspect-to-obtain-B functionality verified after load.")

	# 4. Authorization Module Obtained Save/Load Check
	var save_p4 = SaveSystem.capture("apartment", 100.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_p4):
		printerr("FAIL: Failed to write save_p4 to scratch slot!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	var loaded_p4 = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	SaveSystem.apply(loaded_p4)

	if not GameState.has_item("early_ai_assistant_activation_box", 1) or not GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: Items A/B not restored in authorization module obtained check!")
		get_tree().quit(1)
		return

	# Try inspect A again and check it doesn't give duplicate B
	var box_inst_id_p4 := ""
	for slot in GameState.get_inventory():
		if slot.get("item_id", "") == "early_ai_assistant_activation_box":
			box_inst_id_p4 = slot.get("instance_id", "")
			break
	ui_instance_j._message_on_closed = Callable()
	ui_instance_j._on_bag_item_action("view", box_inst_id_p4)
	if ui_instance_j._message_on_closed.is_valid():
		printerr("FAIL: Subsequent inspect after load triggered message box flow!")
		get_tree().quit(1)
		return
	print("PASS: Item A and B state, and single-inspect constraint successfully saved and restored.")

	# 5. Quest Completed Save/Load Check
	GameState.remove_item("early_ai_assistant_activation_box", 1)
	QuestManager.complete("alley_backrooms_3f")

	var save_p5 = SaveSystem.capture("apartment", 100.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_p5):
		printerr("FAIL: Failed to write save_p5 to scratch slot!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	var loaded_p5 = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	SaveSystem.apply(loaded_p5)

	if GameState.has_item("early_ai_assistant_activation_box", 1) or not GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: Item states incorrect after load in completed check!")
		get_tree().quit(1)
		return

	if QuestManager.get_status("alley_backrooms_3f") != "completed":
		printerr("FAIL: Quest status not 'completed' after load in completed check!")
		get_tree().quit(1)
		return

	var notes_p5 = GameState.get_notes("工作")
	if notes_p5.is_empty() or notes_p5[0].get("status") != "completed":
		printerr("FAIL: Work note status not 'completed' after load in completed check!")
		get_tree().quit(1)
		return
	print("PASS: Quest completed state, item states, and work note states successfully saved and restored.")

	# 25. Verify Quest Ending Message Boxes Triggering
	print("Verifying Quest Ending Message Boxes Triggering...")

	# Test case 1: Ending 1 (Did not retrieve the hidden module)
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	QuestManager.complete("alley_backrooms_3f")
	QuestManager.set_flag("alley_backrooms_3f", "found_old_ai_authorization_module", false)
	GameState.story_flags.erase("alley_backrooms_ended")

	UIMode.set_mode(UIMode.Mode.DIALOGUE)
	UIMode.set_mode(UIMode.Mode.NONE)
	await get_tree().process_frame

	if UIMode.get_mode() != UIMode.Mode.MESSAGE:
		printerr("FAIL: Ending 1 did not trigger MESSAGE mode!")
		get_tree().quit(1)
		return
	if not ui_instance.message_box.visible:
		printerr("FAIL: Ending 1 message box not visible!")
		get_tree().quit(1)
		return
	if not ui_instance.message_label.text.contains("結局 1"):
		printerr("FAIL: Ending 1 text incorrect! Got: ", ui_instance.message_label.text)
		get_tree().quit(1)
		return
	print("PASS: Ending 1 messagebox triggered successfully.")

	# Close the message box
	ui_instance.close_message()
	await get_tree().process_frame

	# Verify it doesn't trigger again
	UIMode.set_mode(UIMode.Mode.DIALOGUE)
	UIMode.set_mode(UIMode.Mode.NONE)
	await get_tree().process_frame
	if UIMode.get_mode() != UIMode.Mode.NONE:
		printerr("FAIL: Ending triggered repeatedly!")
		get_tree().quit(1)
		return
	print("PASS: Ending single-trigger constraint verified.")

	# Test case 2: Ending 2 (Retrieved the hidden module)
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	QuestManager.set_flag("alley_backrooms_3f", "found_old_ai_authorization_module", true)
	QuestManager.complete("alley_backrooms_3f")
	GameState.story_flags.erase("alley_backrooms_ended")

	UIMode.set_mode(UIMode.Mode.DIALOGUE)
	UIMode.set_mode(UIMode.Mode.NONE)
	await get_tree().process_frame

	if UIMode.get_mode() != UIMode.Mode.MESSAGE:
		printerr("FAIL: Ending 2 did not trigger MESSAGE mode!")
		get_tree().quit(1)
		return
	if not ui_instance.message_box.visible:
		printerr("FAIL: Ending 2 message box not visible!")
		get_tree().quit(1)
		return
	if not ui_instance.message_label.text.contains("結局 2"):
		printerr("FAIL: Ending 2 text incorrect! Got: ", ui_instance.message_label.text)
		get_tree().quit(1)
		return
	print("PASS: Ending 2 messagebox triggered successfully.")

	# Close the message box
	ui_instance.close_message()
	await get_tree().process_frame

	# Test case 3: Ending 3 (Gave the module)
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	QuestManager.complete("alley_backrooms_3f")
	GameState.story_flags.erase("alley_backrooms_ended")
	GameState.set_flag("gave_wan_old_module", true)

	UIMode.set_mode(UIMode.Mode.DIALOGUE)
	UIMode.set_mode(UIMode.Mode.NONE)
	await get_tree().process_frame

	if UIMode.get_mode() != UIMode.Mode.MESSAGE:
		printerr("FAIL: Ending 3 did not trigger MESSAGE mode!")
		get_tree().quit(1)
		return
	if not ui_instance.message_box.visible:
		printerr("FAIL: Ending 3 message box not visible!")
		get_tree().quit(1)
		return
	if not ui_instance.message_label.text.contains("結局 3"):
		printerr("FAIL: Ending 3 text incorrect! Got: ", ui_instance.message_label.text)
		get_tree().quit(1)
		return
	print("PASS: Ending 3 messagebox triggered successfully.")

	# Close the message box
	ui_instance.close_message()
	await get_tree().process_frame

	# Test case 4: Convenience Store Ending 1 (Direct Reset / "reset" resolution)
	GameState.reset_for_new_game()
	QuestManager.start("repair_vendor_bot")
	QuestManager.complete("repair_vendor_bot")
	GameState.set_flag("store_robot_resolution", "reset")
	GameState.story_flags.erase("repair_vendor_bot_ended")

	UIMode.set_mode(UIMode.Mode.DIALOGUE)
	UIMode.set_mode(UIMode.Mode.NONE)
	await get_tree().process_frame

	if UIMode.get_mode() != UIMode.Mode.MESSAGE:
		printerr("FAIL: Convenience Ending 1 did not trigger MESSAGE mode!")
		get_tree().quit(1)
		return
	if not ui_instance.message_box.visible:
		printerr("FAIL: Convenience Ending 1 message box not visible!")
		get_tree().quit(1)
		return
	if not ui_instance.message_label.text.contains("高效的系統"):
		printerr("FAIL: Convenience Ending 1 text incorrect! Got: ", ui_instance.message_label.text)
		get_tree().quit(1)
		return
	print("PASS: Convenience store Ending 1 messagebox triggered successfully.")

	# Close the message box
	ui_instance.close_message()
	await get_tree().process_frame

	# Verify it doesn't trigger again
	UIMode.set_mode(UIMode.Mode.DIALOGUE)
	UIMode.set_mode(UIMode.Mode.NONE)
	await get_tree().process_frame
	if UIMode.get_mode() != UIMode.Mode.NONE:
		printerr("FAIL: Convenience store Ending triggered repeatedly!")
		get_tree().quit(1)
		return
	print("PASS: Convenience store Ending single-trigger constraint verified.")

	# Test case 5: Convenience Store Ending 2 (Glean recording / "gleaned" resolution)
	GameState.reset_for_new_game()
	QuestManager.start("repair_vendor_bot")
	QuestManager.complete("repair_vendor_bot")
	GameState.set_flag("store_robot_resolution", "gleaned")
	GameState.story_flags.erase("repair_vendor_bot_ended")

	UIMode.set_mode(UIMode.Mode.DIALOGUE)
	UIMode.set_mode(UIMode.Mode.NONE)
	await get_tree().process_frame

	if UIMode.get_mode() != UIMode.Mode.MESSAGE:
		printerr("FAIL: Convenience Ending 2 did not trigger MESSAGE mode!")
		get_tree().quit(1)
		return
	if not ui_instance.message_box.visible:
		printerr("FAIL: Convenience Ending 2 message box not visible!")
		get_tree().quit(1)
		return
	if not ui_instance.message_label.text.contains("溫存的殘響"):
		printerr("FAIL: Convenience Ending 2 text incorrect! Got: ", ui_instance.message_label.text)
		get_tree().quit(1)
		return
	print("PASS: Convenience store Ending 2 messagebox triggered successfully.")

	# Close the message box
	ui_instance.close_message()
	await get_tree().process_frame

