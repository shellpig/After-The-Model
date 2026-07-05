extends "res://tests/manual/phases/phase_6b.gd"

func _run_phase_6a() -> void:
	# 15. Verify Phase 6-A SaveSystem Autoload & State Serialization
	print("Verifying Phase 6-A SaveSystem Autoload & State Serialization...")

	# Prepare some state changes
	GameState.reset_for_new_game()
	if GameState.get_credits() != 300:
		printerr("FAIL: GameState reset_for_new_game did not set default credits!")
		get_tree().quit(1)
		return

	GameState.set_credits(500)
	GameState.set_flag("test_story_flag", 42)
	GameState.apartment_sonar_revealed = true

	# Add item and verify it exists
	if not GameState.add_item("canned_food", 3):
		printerr("FAIL: Could not add canned_food for test!")
		get_tree().quit(1)
		return

	var inventory_before = GameState.get_inventory()
	var credits_before = GameState.get_credits()

	# Capture state
	var save_data = SaveSystem.capture("apartment", 425.0, -1)
	if not SaveSystem.validate(save_data):
		printerr("FAIL: Captured save data failed validation!")
		get_tree().quit(1)
		return
	print("PASS: Capture and validate verified.")

	# Write slot and read back
	var slot_idx := TEST_VALID_SAVE_SLOT
	dir = DirAccess.open("user://")
	if dir and dir.file_exists(TEST_VALID_SAVE_FILE):
		dir.remove(TEST_VALID_SAVE_FILE)

	var slots_list_before = SaveSystem.list_slots()
	if not slots_list_before[0]["empty"]:
		printerr("FAIL: Slot 1 should be empty before writing!")
		get_tree().quit(1)
		return

	if not SaveSystem.write_slot(slot_idx, save_data):
		printerr("FAIL: Failed to write to slot 1!")
		get_tree().quit(1)
		return
	print("PASS: Write slot verified.")

	var slots_list_after = SaveSystem.list_slots()
	if slots_list_after[0]["empty"] or slots_list_after[0]["meta"]["credits"] != 500:
		printerr("FAIL: list_slots did not report written slot 1 metadata correctly!")
		get_tree().quit(1)
		return
	print("PASS: list_slots verified with active slot.")

	# Read slot
	var read_data = SaveSystem.read_slot(slot_idx)
	if not SaveSystem.validate(read_data):
		printerr("FAIL: Read save data failed validation!")
		get_tree().quit(1)
		return
	if read_data["data"]["player_x"] != 425.0 or read_data["data"]["player_facing"] != -1:
		printerr("FAIL: Read data fields did not match captured fields!")
		get_tree().quit(1)
		return
	print("PASS: Read slot and validation verified.")

	# Corrupt slot simulation
	var corrupt_slot_idx := TEST_SCRATCH_SAVE_SLOT
	var corrupt_file = FileAccess.open("user://%s" % TEST_SCRATCH_SAVE_FILE, FileAccess.WRITE)
	if corrupt_file:
		corrupt_file.store_string("THIS IS NOT A VALID SAV OBJECT")
		corrupt_file.close()

	var slots_list_corrupt = SaveSystem.list_slots()
	if slots_list_corrupt[1]["empty"] or not slots_list_corrupt[1].get("corrupt", false):
		printerr("FAIL: list_slots did not identify corrupt slot 2!")
		get_tree().quit(1)
		return
	print("PASS: list_slots corrupt detection verified.")

	# Clean up corrupt file
	if dir:
		dir.remove(TEST_SCRATCH_SAVE_FILE)

	# Reset state and apply read data
	GameState.reset_for_new_game()
	if GameState.get_credits() != 300 or GameState.story_flags.has("test_story_flag"):
		printerr("FAIL: reset_for_new_game failed to clear state before load!")
		get_tree().quit(1)
		return

	SaveSystem.apply(read_data)

	# Verify restored state
	var inventory_after = GameState.get_inventory()
	var credits_after = GameState.get_credits()

	if credits_after != credits_before:
		printerr("FAIL: Credits mismatch after applying save!")
		get_tree().quit(1)
		return
	if GameState.get_flag("test_story_flag") != 42:
		printerr("FAIL: Story flags mismatch after applying save!")
		get_tree().quit(1)
		return
	if not GameState.apartment_sonar_revealed:
		printerr("FAIL: Apartment sonar state mismatch after applying save!")
		get_tree().quit(1)
		return

	# Compare inventory arrays
	if inventory_after.size() != inventory_before.size():
		printerr("FAIL: Inventory slot count mismatch after applying save!")
		get_tree().quit(1)
		return
	for i in range(inventory_after.size()):
		var slot_a = inventory_after[i]
		var slot_b = inventory_before[i]
		if slot_a.get("item_id") != slot_b.get("item_id") or slot_a.get("quantity") != slot_b.get("quantity"):
			printerr("FAIL: Inventory slot content mismatch after applying save!")
			get_tree().quit(1)
			return
	print("PASS: SaveSystem state application and validation matches perfectly.")

	room_instance2.queue_free()

