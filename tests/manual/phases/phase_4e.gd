extends "res://tests/manual/phases/phase_5a.gd"

func _run_phase_4e() -> void:
	# 11. Verify Phase 4-E Entry Point methods on apartment_room
	print("Verifying Phase 4-E Entry Point APIs on apartment_room...")
	if not room_instance.has_method("prepare_entry_point") or not room_instance.has_method("set_entry_point"):
		printerr("FAIL: apartment_room.gd lacks prepare_entry_point or set_entry_point API!")
		get_tree().quit(1)
		return
	print("PASS: apartment_room prepare_entry_point & set_entry_point APIs verified.")

	# 12. Verify Room State Persistence
	print("Verifying room state persistence...")
	# Verify initial room state (unsolved)
	var clock = room_instance.get_node_or_null("Interactables/ProjectionClockArea")
	if not clock:
		printerr("FAIL: ProjectionClockArea should exist in unsolved room initial load!")
		get_tree().quit(1)
		return
	if room_instance.CONTAINERS.has("apartment_slot"):
		printerr("FAIL: CONTAINERS should not have apartment_slot in unsolved room initial load!")
		get_tree().quit(1)
		return
	print("PASS: Unsolved room layout verified (clock exists, slot hidden).")

	# Clean up first instantiation
	room_instance.queue_free()
	# Wait for queue_free to process
	await get_tree().process_frame

	# Simulate puzzle completion in GameState
	GameState.apartment_sonar_revealed = true
	GameState.apartment_slot_unlocked = true
	GameState.apartment_beyond_door_bgm_triggered = true

	# Instantiate the apartment room scene a second time (simulating re-entry)
	room_instance2 = room_scene.instantiate()
	add_child(room_instance2)
	room_instance2.prepare_entry_point("from_street")
	room_instance2.set_entry_point("from_street")

	# Wait for queue_free to process on clock
	await get_tree().process_frame

	var clock2 = room_instance2.get_node_or_null("Interactables/ProjectionClockArea")
	if clock2 != null:
		printerr("FAIL: ProjectionClockArea should be deleted/removed in solved room re-entry!")
		get_tree().quit(1)
		return
	if not room_instance2.CONTAINERS.has("apartment_slot"):
		printerr("FAIL: CONTAINERS should have apartment_slot in solved room re-entry!")
		get_tree().quit(1)
		return
	if room_instance2.CONTAINERS["apartment_slot"]["title"] != "隱藏插槽":
		printerr("FAIL: Apartment slot should be dynamically registered!")
		get_tree().quit(1)
		return
	print("PASS: Solved room layout verified (clock removed, slot revealed).")

