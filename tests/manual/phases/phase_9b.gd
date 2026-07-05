extends "res://tests/manual/phases/phase_9c.gd"

func _run_phase_9b() -> void:
	# Phase 9-B: 時鐘取模組 + 線索筆記
	# ============================================================
	print("Verifying Phase 9-B: Clock module extraction and guards...")

	var inv_backup_9b = GameState.inventory.duplicate(true)
	var credits_backup_9b = GameState.get_credits()
	var echo_progress_backup_9b = GameState.echo_progress.duplicate(true)
	var story_flags_backup_9b = GameState.story_flags.duplicate(true)
	var notes_backup_9b = GameState.notes.duplicate(true)
	var knowledge_backup_9b = GameState.knowledge.duplicate(true)

	GameState.reset_for_new_game()

	# Load apartment room scene
	var room_scene_9b = load("res://scenes/levels/apartment/apartment_room.tscn")
	var room_inst_9b = room_scene_9b.instantiate()
	add_child(room_inst_9b)
	room_inst_9b.prepare_entry_point("from_street")
	room_inst_9b.set_entry_point("from_street")
	await get_tree().process_frame

	# 1. Before puzzle completion: Clock exists
	var clock_node = room_inst_9b.get_node_or_null("Interactables/ProjectionClockArea")
	if not clock_node:
		printerr("FAIL 9-B: Clock node should exist initially in unsolved room!")
		get_tree().quit(1)
		return

	# If we enter clock but don't have the note, it should NOT be interactable
	room_inst_9b._on_interactable_entered(clock_node)
	room_inst_9b._refresh_current_interactable()
	print("DEBUG 9-B step 1: current_interactable without note is ", room_inst_9b.current_interactable)
	if room_inst_9b.current_interactable == clock_node:
		printerr("FAIL 9-B: Clock should not be closest interactable before clue_projection_clock note is acquired!")
		get_tree().quit(1)
		return
	room_inst_9b._on_interactable_exited(clock_node)

	# Now add clue note, it should become interactable
	GameState.add_knowledge(GameState.STORY_NOTES["clue_projection_clock"])
	room_inst_9b._on_interactable_entered(clock_node)
	room_inst_9b._refresh_current_interactable()
	print("DEBUG 9-B step 1: current_interactable with note is ", room_inst_9b.current_interactable)
	if room_inst_9b.current_interactable != clock_node:
		printerr("FAIL 9-B: Clock should be interactable once clue_projection_clock note is acquired!")
		get_tree().quit(1)
		return

	# Interact should start sonar but NOT give 9-B module
	room_inst_9b._trigger_interaction()
	if GameState.has_item("old_probe_module") or GameState.get_flag("probe_module_taken", false):
		printerr("FAIL 9-B: Should not retrieve module before door is unlocked!")
		get_tree().quit(1)
		return
	room_inst_9b._on_interactable_exited(clock_node)

	# 2. Complete puzzle (sonar revealed), but no door unlock knowledge yet -> clock is removed
	GameState.apartment_sonar_revealed = true
	room_inst_9b.free()
	await get_tree().process_frame

	room_inst_9b = room_scene_9b.instantiate()
	add_child(room_inst_9b)
	room_inst_9b.prepare_entry_point("from_street")
	room_inst_9b.set_entry_point("from_street")
	await get_tree().process_frame

	clock_node = room_inst_9b.get_node_or_null("Interactables/ProjectionClockArea")
	print("DEBUG 9-B step 2: clock_node after sonar reveal without door unlock is ", clock_node)
	if clock_node != null:
		printerr("FAIL 9-B: Clock should be deleted if puzzle is solved but door unlock is not known!")
		get_tree().quit(1)
		return

	# 3. Add door unlock knowledge -> Clock reappears upon re-entry
	GameState.add_knowledge(GameState.STORY_NOTES["identity_door_unlock_method"])
	room_inst_9b.free()
	await get_tree().process_frame

	room_inst_9b = room_scene_9b.instantiate()
	add_child(room_inst_9b)
	room_inst_9b.prepare_entry_point("from_street")
	room_inst_9b.set_entry_point("from_street")
	await get_tree().process_frame

	clock_node = room_inst_9b.get_node_or_null("Interactables/ProjectionClockArea")
	print("DEBUG 9-B step 3: clock_node after door unlock is ", clock_node)
	if not clock_node:
		printerr("FAIL 9-B: Clock should reappear for 9-B module extraction when door unlock method is known!")
		get_tree().quit(1)
		return

	# 4. Fill inventory to test the backpack full guard
	# GameState.inventory has 20 slots. Let's fill all of them.
	GameState.inventory.clear()
	for i in range(20):
		GameState.inventory.append({
			"instance_id": "dummy_" + str(i),
			"item_id": "canned_food",
			"quantity": 5
		})
	GameState.inventory_changed.emit()

	# Interact with clock while inventory is full
	var interaction_msg_tracker := {
		"got_msg": false,
		"text": ""
	}
	_temp_callable = func(data):
		print("DEBUG 9-B step 4: received interaction request event: ", data)
		if data.get("type") == "message":
			interaction_msg_tracker["got_msg"] = true
			interaction_msg_tracker["text"] = data.get("message_text", "")
	room_inst_9b.interaction_requested.connect(_temp_callable)

	room_inst_9b._on_interactable_entered(clock_node)
	room_inst_9b._refresh_current_interactable()
	print("DEBUG 9-B step 4: current_interactable before interact is ", room_inst_9b.current_interactable)
	room_inst_9b._trigger_interaction()

	# M2-C：payload 的 message_text 為翻譯 key，view 端 tr() 後才是顯示文字；測試需鏡像同一鏈。
	if not interaction_msg_tracker["got_msg"] or not tr(interaction_msg_tracker["text"]).contains("背包太滿"):
		printerr("FAIL 9-B: Full inventory guard did not show backpack full message! Msg: ", interaction_msg_tracker["text"])
		get_tree().quit(1)
		return

	if GameState.has_item("old_probe_module") or GameState.get_flag("probe_module_taken", false):
		printerr("FAIL 9-B: Should not grant item or set flag when inventory is full!")
		get_tree().quit(1)
		return

	# Make sure the clock still exists and is interactable
	clock_node = room_inst_9b.get_node_or_null("Interactables/ProjectionClockArea")
	if not clock_node:
		printerr("FAIL 9-B: Clock should still exist after failed interaction due to full inventory!")
		get_tree().quit(1)
		return

	# 5. Free up space in inventory and interact again
	GameState.inventory.clear()
	for i in range(20):
		GameState.inventory.append({})
	GameState.inventory_changed.emit()

	interaction_msg_tracker["got_msg"] = false
	interaction_msg_tracker["text"] = ""

	# Make sure current_interactable is set correctly
	room_inst_9b._refresh_current_interactable()
	room_inst_9b._trigger_interaction()
	await get_tree().process_frame

	if not interaction_msg_tracker["got_msg"] or not tr(interaction_msg_tracker["text"]).contains("獲得了「老舊探測模組」"):
		printerr("FAIL 9-B: Failed to extract module after inventory space cleared! Msg: ", interaction_msg_tracker["text"])
		get_tree().quit(1)
		return

	# Verify item, flags, notes
	if not GameState.has_item("old_probe_module"):
		printerr("FAIL 9-B: Player should have old_probe_module in inventory after successful extraction!")
		get_tree().quit(1)
		return

	if not GameState.get_flag("probe_module_taken", false):
		printerr("FAIL 9-B: probe_module_taken flag should be set to true!")
		get_tree().quit(1)
		return

	if not GameState.has_note("clue_probe_module_lead"):
		printerr("FAIL 9-B: clue_probe_module_lead note should be added to notes!")
		get_tree().quit(1)
		return

	# Verify clock is removed
	clock_node = room_inst_9b.get_node_or_null("Interactables/ProjectionClockArea")
	if clock_node != null:
		printerr("FAIL 9-B: Clock should be queue_freed from room after successful extraction!")
		get_tree().quit(1)
		return

	# Cleanup signal
	room_inst_9b.interaction_requested.disconnect(_temp_callable)

	# 6. Verify non-discardable and non-sellable rules for old_probe_module and fingerless_gloves
	if GameState.is_sellable("old_probe_module") or GameState.is_sellable("fingerless_gloves"):
		printerr("FAIL 9-B: old_probe_module and fingerless_gloves must NOT be sellable!")
		get_tree().quit(1)
		return

	# Verify discardable is false in metadata
	if GameState.ITEMS_DB["old_probe_module"].get("discardable", true) != false or GameState.ITEMS_DB["fingerless_gloves"].get("discardable", true) != false:
		printerr("FAIL 9-B: old_probe_module and fingerless_gloves must be non-discardable!")
		get_tree().quit(1)
		return

	# Clean up instances
	room_inst_9b.free()

	# Restore state backups
	GameState.reset_for_new_game()
	GameState.inventory = inv_backup_9b
	GameState.set_credits(credits_backup_9b)
	GameState.echo_progress = echo_progress_backup_9b
	GameState.story_flags = story_flags_backup_9b
	GameState.notes = notes_backup_9b
	GameState.knowledge = knowledge_backup_9b
	GameState.inventory_changed.emit()
	await get_tree().process_frame

	print("PASS 9-B: Clock module extraction and guards verified.")

	# ----------------------------------------------------
