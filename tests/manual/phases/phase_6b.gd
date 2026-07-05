extends "res://tests/manual/phases/phase_6de.gd"

func _run_phase_6b() -> void:
	# 16. Verify Phase 6-B Load Game Entry Path & Dual Validation
	print("Verifying Phase 6-B Load Game Entry Path & Dual Validation...")

	# Reset state first
	GameState.reset_for_new_game()

	# Load slot 1 (which we saved in 6-A with player_x = 425.0, facing = -1)
	var load_success = main_instance.load_game_slot(TEST_VALID_SAVE_SLOT)
	if not load_success:
		printerr("FAIL: load_game_slot(1) failed to load valid slot!")
		get_tree().quit(1)
		return

	var active_level = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion():
			active_level = child
			break
	if not active_level or not active_level.get_script() or not active_level.get_script().resource_path.contains("apartment_room.gd"):
		printerr("FAIL: Restored scene is not ApartmentRoom! Script was: ", active_level.get_script().resource_path if active_level and active_level.get_script() else "null")
		get_tree().quit(1)
		return

	if active_level.get("_opening_monologue_active"):
		printerr("FAIL: Monologue was not bypassed during restore load!")
		get_tree().quit(1)
		return
	print("PASS: Monologue bypass verified.")

	var active_player = active_level.get_node("Player")
	if active_player.get_save_x() != 425.0:
		printerr("FAIL: Restored player position is wrong! Got: ", active_player.get_save_x())
		get_tree().quit(1)
		return
	if active_player.get_facing() != -1:
		printerr("FAIL: Restored player facing is wrong! Got: ", active_player.get_facing())
		get_tree().quit(1)
		return
	print("PASS: Player position and facing restore verified.")

	# Verify dual stage validation failures
	# 1. Validation fail due to invalid scene registry on Main
	var invalid_scene_payload = SaveSystem.capture("apartment", 425.0, -1)
	invalid_scene_payload["data"]["current_scene_id"] = "nonexistent_scene_id"
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, invalid_scene_payload):
		printerr("FAIL: Failed to write test payload to scratch slot!")
		get_tree().quit(1)
		return

	# Set some check value in GameState
	GameState.set_credits(9999)
	var load_invalid_success = main_instance.load_game_slot(TEST_SCRATCH_SAVE_SLOT)
	if load_invalid_success:
		printerr("FAIL: load_game_slot(scratch slot) should have failed due to invalid scene ID registry check!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 9999:
		printerr("FAIL: GameState applied half-validated save changes! GameState must be intact.")
		get_tree().quit(1)
		return
	print("PASS: Scene registry validation failure correctly aborted load and left GameState intact.")

	# Clean up scratch slot
	if dir and dir.file_exists(TEST_SCRATCH_SAVE_FILE):
		dir.remove(TEST_SCRATCH_SAVE_FILE)

	# 2. Validation fail due to corrupted payload (validate() check)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, {}): # Empty payload
		printerr("FAIL: Failed to write empty dict to scratch slot!")
		get_tree().quit(1)
		return
	var load_empty_success = main_instance.load_game_slot(TEST_SCRATCH_SAVE_SLOT)
	if load_empty_success:
		printerr("FAIL: load_game_slot(scratch slot) should have failed due to validate check on empty payload!")
		get_tree().quit(1)
		return
	print("PASS: Payload validation failure correctly aborted load.")

	# Clean up scratch slot
	if dir and dir.file_exists(TEST_SCRATCH_SAVE_FILE):
		dir.remove(TEST_SCRATCH_SAVE_FILE)

	# Verify start_new_game resets state and plays monologue
	main_instance.start_new_game()
	var new_level = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion():
			new_level = child
			break
	if not new_level or not new_level.get_script() or not new_level.get_script().resource_path.contains("apartment_room.gd"):
		printerr("FAIL: New game scene is not ApartmentRoom! Script was: ", new_level.get_script().resource_path if new_level and new_level.get_script() else "null")
		get_tree().quit(1)
		return
	if not new_level.get("_opening_monologue_active"):
		printerr("FAIL: New game did not start opening monologue!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 300:
		printerr("FAIL: New game did not reset credits to 300!")
		get_tree().quit(1)
		return
	print("PASS: start_new_game monologue and reset verified.")

