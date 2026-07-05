extends "res://tests/manual/phases/phase_m2a.gd"

func _run_phase_m1() -> void:
	# 拆檔補宣告：原為 _ready() 早期區域變數，本段先寫後讀（scratch 重用）
	var room_scene
	var ui_scene
	var main_scene
	var street_scene
	var title_scene
	var escape_scene
	var p18_combat_scene
	var runner
	var press_e
	# ===================== Phase M1: Progress Page Integration Verification =====================
	print("--- Phase M1: Progress Page Integration Verification ---")

	GameState.reset_for_new_game()

	# 1. Verify initial empty status
	var summary = GameState.get_progress_summary()
	if summary["scenes"]["done"] != 0 or summary["scenes"]["total"] != 10:
		printerr("FAIL M1: Initial scene count mismatch")
		get_tree().quit(1)
		return
	if summary["npcs"]["done"] != 0 or summary["npcs"]["total"] != 6:
		printerr("FAIL M1: Initial npc count mismatch")
		get_tree().quit(1)
		return
	if summary["quests"]["done"] != 0 or summary["quests"]["total"] != 3:
		printerr("FAIL M1: Initial quest count mismatch")
		get_tree().quit(1)
		return
	if summary["echoes"]["done"] != 0 or summary["echoes"]["total"] != 5:
		printerr("FAIL M1: Initial echo count mismatch")
		get_tree().quit(1)
		return
	if summary["special"]["done"] != 0 or summary["special"]["total"] != 8:
		printerr("FAIL M1: Initial special item count mismatch")
		get_tree().quit(1)
		return
	if summary["overall_done"] != 0 or summary["overall_total"] != 32 or summary["overall_pct"] != 0:
		printerr("FAIL M1: Initial overall counts mismatch")
		get_tree().quit(1)
		return

	# 2. Scene visiting
	GameState.mark_scene_visited("apartment")
	summary = GameState.get_progress_summary()
	if summary["scenes"]["done"] != 1:
		printerr("FAIL M1: mark_scene_visited did not increment scenes.done")
		get_tree().quit(1)
		return
	# Test Idempotency
	GameState.mark_scene_visited("apartment")
	summary = GameState.get_progress_summary()
	if summary["scenes"]["done"] != 1:
		printerr("FAIL M1: mark_scene_visited is not idempotent")
		get_tree().quit(1)
		return

	# 3. NPC talking
	GameState.mark_npc_talked("wan")
	summary = GameState.get_progress_summary()
	if summary["npcs"]["done"] != 1:
		printerr("FAIL M1: mark_npc_talked did not increment npcs.done")
		get_tree().quit(1)
		return
	# Whitelist check
	GameState.mark_npc_talked("travel_street_east")
	summary = GameState.get_progress_summary()
	if summary["npcs"]["done"] != 1:
		printerr("FAIL M1: mark_npc_talked whitelist guard failed")
		get_tree().quit(1)
		return

	# 4. Quest completion
	GameState.set_flag("left_apartment_once", true)
	summary = GameState.get_progress_summary()
	if summary["quests"]["done"] != 1:
		printerr("FAIL M1: left_apartment_once flag did not increment quests.done")
		get_tree().quit(1)
		return
	GameState.quest_states["repair_vendor_bot"] = {"status": "completed"}
	summary = GameState.get_progress_summary()
	if summary["quests"]["done"] != 2:
		printerr("FAIL M1: quest completed status did not increment quests.done")
		get_tree().quit(1)
		return

	# 5. Echoes
	GameState.record_full_echo("echo_clerk")
	summary = GameState.get_progress_summary()
	if summary["echoes"]["done"] != 1:
		printerr("FAIL M1: record_full_echo did not increment echoes.done")
		get_tree().quit(1)
		return

	# 6. Special Items collection & retention
	GameState.add_item("childcare_supply_receipt", 1)
	summary = GameState.get_progress_summary()
	if summary["special"]["done"] != 1:
		printerr("FAIL M1: add_item did not increment special.done")
		get_tree().quit(1)
		return
	# Remove item and ensure it stays completed (persistence)
	GameState.remove_item("childcare_supply_receipt", 1)
	summary = GameState.get_progress_summary()
	if summary["special"]["done"] != 1:
		printerr("FAIL M1: remove_item unticked progress")
		get_tree().quit(1)
		return

	# 7. Non-whitelist special item check
	GameState.add_item("old_work_badge", 1)
	summary = GameState.get_progress_summary()
	if summary["special"]["done"] != 1:
		printerr("FAIL M1: non-whitelist special item added to progress")
		get_tree().quit(1)
		return

	# 8. Overall percentage calculation
	if summary["overall_done"] != 6 or summary["overall_pct"] != 19:
		printerr("FAIL M1: overall calculations mismatch, done: ", summary["overall_done"], " pct: ", summary["overall_pct"])
		get_tree().quit(1)
		return

	# 9. Save/Load round-trip & backward compatibility
	var pM1_save_dict = SaveSystem.capture("apartment", 200.0, 1)
	GameState.reset_for_new_game()

	# Load compatibility check
	var m1_compat_save_dict = p18_save_dict.duplicate(true)
	m1_compat_save_dict["data"].erase("visited_scenes")
	m1_compat_save_dict["data"].erase("talked_npcs")
	m1_compat_save_dict["data"].erase("collected_special_items")

	SaveSystem.apply(m1_compat_save_dict)
	summary = GameState.get_progress_summary()
	if summary["scenes"]["done"] != 0 or summary["npcs"]["done"] != 0 or summary["special"]["done"] != 0:
		printerr("FAIL M1: Backward compatibility loading failed to clear progress")
		get_tree().quit(1)
		return

	# Restore to M1 state
	SaveSystem.apply(pM1_save_dict)
	summary = GameState.get_progress_summary()
	if summary["scenes"]["done"] != 1 or summary["npcs"]["done"] != 1 or summary["quests"]["done"] != 2 or summary["echoes"]["done"] != 1 or summary["special"]["done"] != 1:
		printerr("FAIL M1: Save/Load round-trip did not restore progress values")
		get_tree().quit(1)
		return

	# 10. change_item_id marks special items (transform path: worn_rubiks_cube -> decoder_cube)
	var special_before = GameState.get_progress_summary()["special"]["done"]
	GameState.add_item("worn_rubiks_cube", 1)
	var cube_inst := ""
	for slot in GameState.inventory:
		if not slot.is_empty() and slot.get("item_id") == "worn_rubiks_cube":
			cube_inst = slot.get("instance_id")
			break
	if cube_inst.is_empty():
		printerr("FAIL M1: could not seed worn_rubiks_cube for change_item_id test")
		get_tree().quit(1)
		return
	GameState.change_item_id(cube_inst, "decoder_cube")
	summary = GameState.get_progress_summary()
	if summary["special"]["done"] != special_before + 1:
		printerr("FAIL M1: change_item_id did not mark decoder_cube as collected")
		get_tree().quit(1)
		return

	# 11. unknown_total echo (鹿家記事) counts complete once its segment is collected (frozen decision guard)
	var echoes_before = GameState.get_progress_summary()["echoes"]["done"]
	GameState.record_full_echo("echo_lu_family")
	summary = GameState.get_progress_summary()
	if summary["echoes"]["done"] != echoes_before + 1:
		printerr("FAIL M1: unknown_total echo (echo_lu_family) not counted complete for progress")
		get_tree().quit(1)
		return

	print("PASS M1: Progress page metrics, whitelists, persistence, save/load, and backward compatibility verified.")
	print("PASS M1: change_item_id special-item marking and unknown_total echo progress rule verified.")

	# Cleanup Phase 18 test nodes
	p18_arena.queue_free()
	p18_combat_scene = null
	await get_tree().process_frame

	# Clean up scratch slot
	if dir and dir.file_exists(TEST_SCRATCH_SAVE_FILE):
		dir.remove(TEST_SCRATCH_SAVE_FILE)

	# Clean up temporary instances
	ui_instance_j.free()

	# Clean up fire escape test instance
	escape_instance.free()
	escape_scene = null

	# Clean up instantiated test nodes
	if is_instance_valid(ui_instance):
		ui_instance.free()
	if is_instance_valid(street_instance):
		street_instance.free()
	if is_instance_valid(main_instance):
		main_instance.free()

	# Wait a frame to let queue_free'd nodes actually get deleted
	await get_tree().process_frame

	# Release RefCounted resources explicitly to prevent exit leaks
	room_scene = null
	ui_scene = null
	main_scene = null
	street_scene = null
	DialogueDB = null
	title_scene = null
	runner = null
	press_e = Callable()
	_temp_callable = Callable()

