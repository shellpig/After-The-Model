extends "res://tests/manual/phases/phase_9a.gd"

func _run_phase_8h() -> void:
	# Phase 8-H: 回歸與存讀檔驗證
	# ============================================================
	print("Verifying Phase 8-H: regression & save/restore...")

	# 1. Pre-Quest Save/Load Check
	GameState.reset_for_new_game()
	GameState.set_flag("talked_outside_vendor", true)
	GameState.set_flag("talked_store_robot", true)
	GameState._maybe_set_discovered_vendor_error()
	GameState.set_flag("used_room_computer_once", true)

	var save_8h_p1 = SaveSystem.capture("apartment", 200.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_8h_p1):
		printerr("FAIL 8-H: Failed to write save_8h_p1 to scratch slot!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	var loaded_8h_p1 = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	SaveSystem.apply(loaded_8h_p1)

	if not GameState.get_flag("discovered_vendor_error", false) or not GameState.get_flag("used_room_computer_once", false) or not GameState.has_note("clue_vendor_error_lead"):
		printerr("FAIL 8-H: Pre-quest flags or lead note not restored correctly!")
		get_tree().quit(1)
		return
	print("PASS: Pre-quest save/load verified.")

	# 2. Quest Active & Clues Collected Save/Load Check
	GameState.reset_for_new_game()
	QuestManager.start("repair_vendor_bot")
	GameState.add_knowledge({
		"id": "clue_cabinet_notes",
		"category": "線索",
		"title": "置物櫃的便條",
		"body": "置物櫃門縫夾著一張紙條，上面歪歪斜斜地寫著一些關於保修期和登入密碼的塗鴉。"
	})
	QuestManager.set_flag("repair_vendor_bot", "mainframe_revealed", true)
	QuestManager.set_flag("repair_vendor_bot", "understood_robot_truth", true)

	var save_8h_p2 = SaveSystem.capture("convenience_store", 500.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_8h_p2):
		printerr("FAIL 8-H: Failed to write save_8h_p2 to scratch slot!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	var loaded_8h_p2 = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	SaveSystem.apply(loaded_8h_p2)

	if QuestManager.get_status("repair_vendor_bot") != "active":
		printerr("FAIL 8-H: Quest state not restored correctly!")
		get_tree().quit(1)
		return
	if not GameState.has_note("clue_cabinet_notes"):
		printerr("FAIL 8-H: Clue notes not restored correctly!")
		get_tree().quit(1)
		return
	if not QuestManager.get_flag("repair_vendor_bot", "mainframe_revealed", false) or not QuestManager.get_flag("repair_vendor_bot", "understood_robot_truth", false):
		printerr("FAIL 8-H: Quest flags (mainframe/truth) not restored correctly!")
		get_tree().quit(1)
		return
	print("PASS: Quest active & clues save/load verified.")

	# 3. Repaired Reset Ending Save/Load Check
	GameState.reset_for_new_game()
	GameState.set_flag("vendor_bot_repaired", true)
	GameState.set_flag("store_robot_resolution", "reset")
	QuestManager.start("repair_vendor_bot")
	QuestManager.complete("repair_vendor_bot")

	var save_8h_p3 = SaveSystem.capture("convenience_store", 500.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_8h_p3):
		printerr("FAIL 8-H: Failed to write save_8h_p3 to scratch slot!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	var loaded_8h_p3 = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	SaveSystem.apply(loaded_8h_p3)

	if not GameState.get_flag("vendor_bot_repaired", false) or GameState.get_flag("store_robot_resolution", "") != "reset":
		printerr("FAIL 8-H: Repaired reset flags not restored correctly!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("repair_vendor_bot") != "completed":
		printerr("FAIL 8-H: Quest completed state not restored correctly for reset ending!")
		get_tree().quit(1)
		return

	var note_reset_8h = GameState.get_notes("工作")
	if note_reset_8h.is_empty() or not _tr_body(note_reset_8h[0].get("body", "")).contains("直接重置"):
		printerr("FAIL 8-H: Reset work note not restored correctly!")
		get_tree().quit(1)
		return
	print("PASS: Repaired reset ending save/load verified.")

	# 4. Repaired Gleaned Ending Save/Load Check
	GameState.reset_for_new_game()
	GameState.set_flag("vendor_bot_repaired", true)
	GameState.set_flag("store_robot_resolution", "gleaned")
	QuestManager.start("repair_vendor_bot")
	QuestManager.complete("repair_vendor_bot")
	GameState.add_item("clerk_echo_recording", 1)

	var save_8h_p4 = SaveSystem.capture("convenience_store", 500.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_8h_p4):
		printerr("FAIL 8-H: Failed to write save_8h_p4 to scratch slot!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	var loaded_8h_p4 = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	SaveSystem.apply(loaded_8h_p4)

	if not GameState.get_flag("vendor_bot_repaired", false) or GameState.get_flag("store_robot_resolution", "") != "gleaned":
		printerr("FAIL 8-H: Repaired gleaned flags not restored correctly!")
		get_tree().quit(1)
		return
	if not GameState.has_item("clerk_echo_recording", 1):
		printerr("FAIL 8-H: clerk_echo_recording not restored correctly!")
		get_tree().quit(1)
		return

	var note_gleaned_8h = GameState.get_notes("工作")
	if note_gleaned_8h.is_empty() or not _tr_body(note_gleaned_8h[0].get("body", "")).contains("殘響"):
		printerr("FAIL 8-H: Gleaned work note not restored correctly!")
		get_tree().quit(1)
		return
	print("PASS: Repaired gleaned ending save/load verified.")

	# 5. Dialogue greeting routing check after load
	var robot_tree_8h = DialogueDB.get_tree_for("store_robot")
	var runner_8h = DialogueRunner.new()
	runner_8h.start(robot_tree_8h, "start")
	if runner_8h._current_node_id != "repaired_gleaned":
		printerr("FAIL 8-H: Dialogue runner should route directly to repaired_gleaned! Got: ", runner_8h._current_node_id)
		get_tree().quit(1)
		return
	print("PASS: Repaired dialogue greeting routing after load verified.")

	# 6. Shop stocks availability check after load
	if GameState.get_shop_stock("street_vending").is_empty() or GameState.get_shop_stock("convenience_store").is_empty():
		printerr("FAIL 8-H: Shop stocks not initialized correctly after load!")
		get_tree().quit(1)
		return
	print("PASS: Shop stocks availability after load verified.")

	# Cleanup 8-F
	GameState.story_flags.erase("vendor_bot_repaired")
	GameState.story_flags.erase("store_robot_resolution")
	GameState.story_flags.erase("talked_outside_vendor")
	GameState.shop_states.clear()
	GameState.notes.clear()
	GameState.inventory = inv_backup_8f
	GameState.set_credits(credits_backup_8f)
	GameState.inventory_changed.emit()
	gate_runner_8f = null
	await get_tree().process_frame

	print("PASS: Phase 8-F & 8-G commerce core & ShopPanel verified successfully.")

	# ============================================================
