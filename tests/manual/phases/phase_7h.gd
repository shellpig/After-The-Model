extends "res://tests/manual/phases/phase_7i.gd"

func _run_phase_7h() -> void:
	# Test 22: Verify 7-H R Inspect Grants Item Flow
	print("Verifying Phase 7-H R Inspect Grants Item Flow...")

	# 1. Reset for clean test state with active quest at found_activation_box
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	QuestManager.set_flag("alley_backrooms_3f", "found_old_ai_authorization_module", false)

	# 2. Add activation box (A) to inventory
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
	GameState.add_item("early_ai_assistant_activation_box", 1)

	var box_instance_id := ""
	for slot in GameState.get_inventory():
		if slot.get("item_id", "") == "early_ai_assistant_activation_box":
			box_instance_id = slot.get("instance_id", "")
			break

	if box_instance_id.is_empty():
		printerr("FAIL: Could not add activation box to inventory!")
		get_tree().quit(1)
		return

	# 3. Fill remaining slots to simulate bag full
	for i in range(GameState.inventory_slots):
		if GameState.inventory[i].is_empty():
			GameState.inventory[i] = {
				"instance_id": GameState.generate_instance_id(),
				"item_id": "canned_food",
				"quantity": 5
			}

	# 4. Open inventory UI to put UI in correct mode/state
	ui_instance.open_inventory()

	# 5. Trigger view action (R inspect) on A while bag is full
	ui_instance._on_bag_item_action("view", box_instance_id)

	# Force message to finish writing, and verify message contents
	ui_instance.force_finish_message()
	if not ui_instance.message_label.text.contains("你仔細端詳啟用盒的底部"):
		printerr("FAIL: First inspect message did not show! Got: ", ui_instance.message_label.text)
		get_tree().quit(1)
		return

	# Simulate closing the first message box
	var first_callback = ui_instance._message_on_closed
	if first_callback.is_null():
		printerr("FAIL: first_callback is null!")
		get_tree().quit(1)
		return
	ui_instance.close_message()
	first_callback.call()

	# Since bag is full, warning message should be shown next
	ui_instance.force_finish_message()
	if not ui_instance.message_label.text.contains("你發現了啟用盒底部的夾層") or not ui_instance.message_label.text.contains("但你的背包太滿了"):
		printerr("FAIL: Inventory full warning message did not show! Got: ", ui_instance.message_label.text)
		get_tree().quit(1)
		return

	# Flags and items should remain unchanged
	if QuestManager.get_flag("alley_backrooms_3f", "found_old_ai_authorization_module", false):
		printerr("FAIL: flag set even when inventory is full!")
		get_tree().quit(1)
		return
	if GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: old_ai_authorization_module added even when inventory is full!")
		get_tree().quit(1)
		return

	# Simulate closing the warning message box, which should restore the detail modal
	var warning_callback = ui_instance._message_on_closed
	if warning_callback.is_null():
		printerr("FAIL: warning_callback is null!")
		get_tree().quit(1)
		return
	ui_instance.close_message()
	warning_callback.call()

	if not ui_instance.item_detail_modal.visible:
		printerr("FAIL: Item detail modal not opened after warning closed!")
		get_tree().quit(1)
		return

	# Close the detail modal
	ui_instance.item_detail_modal.close_modal()
	if ui_instance.item_detail_modal.visible:
		printerr("FAIL: Detail modal did not close!")
		get_tree().quit(1)
		return

	# 6. Clear space and test successful retrieval
	for i in range(1, GameState.inventory_slots):
		GameState.inventory[i] = {}

	# Trigger view action (R inspect) again
	ui_instance._on_bag_item_action("view", box_instance_id)
	ui_instance.force_finish_message()

	var success_callback = ui_instance._message_on_closed
	if success_callback.is_null():
		printerr("FAIL: success_callback is null!")
		get_tree().quit(1)
		return
	ui_instance.close_message()
	success_callback.call()

	# Verify flag is set, and old_ai_authorization_module (B) is added to inventory, and A remains
	if not QuestManager.get_flag("alley_backrooms_3f", "found_old_ai_authorization_module", false):
		printerr("FAIL: flag not set on successful inspect!")
		get_tree().quit(1)
		return
	if not GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: old_ai_authorization_module not added on successful inspect!")
		get_tree().quit(1)
		return
	if not GameState.has_item("early_ai_assistant_activation_box", 1):
		printerr("FAIL: early_ai_assistant_activation_box consumed on successful inspect!")
		get_tree().quit(1)
		return

	# Verify detail modal is now open
	if not ui_instance.item_detail_modal.visible:
		printerr("FAIL: Detail modal not opened after successful inspect message closed!")
		get_tree().quit(1)
		return

	# Close the detail modal
	ui_instance.item_detail_modal.close_modal()

	# 7. Test subsequent inspections of A (should open detail modal directly without messages)
	ui_instance._message_on_closed = Callable()
	ui_instance._on_bag_item_action("view", box_instance_id)

	if ui_instance._message_on_closed.is_valid():
		printerr("FAIL: Subsequent inspect triggered message box flow!")
		get_tree().quit(1)
		return

	if not ui_instance.item_detail_modal.visible:
		printerr("FAIL: Detail modal not opened directly on subsequent inspect!")
		get_tree().quit(1)
		return

	ui_instance.item_detail_modal.close_modal()
	ui_instance.close_all_ui()

	print("PASS: Phase 7-H R Inspect Grants Item Flow verified successfully.")

