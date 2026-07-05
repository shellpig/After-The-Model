extends "res://tests/manual/phases/phase_18.gd"

func _run_phase_17c() -> void:
	# ===================== Phase 17-C: Regression and Save/Load Guards =====================
	print("--- Phase 17-C: Regression and Save/Load Guards ---")

	# 1. Verify duplicate collection safety
	GameState.reset_for_new_game()
	var collect1 = GameState.collect_echo_segment("echo_settlement_erased", "s1")
	if not collect1:
		printerr("FAIL 17-C: First collect_echo_segment should succeed!")
		get_tree().quit(1)
		return
	var collect2 = GameState.collect_echo_segment("echo_settlement_erased", "s1")
	if collect2:
		printerr("FAIL 17-C: Second collect_echo_segment should fail (no-op)!")
		get_tree().quit(1)
		return

	# 2. Verify media layer optionality (no crash when fields are absent)
	var echo_rec_17 = EchoDB.get_echo("echo_settlement_erased")
	if echo_rec_17.has("image_path") or echo_rec_17.has("audio_path"):
		printerr("FAIL 17-C: echo_settlement_erased should not have hardcoded image_path or audio_path (media layer must be optional)!")
		get_tree().quit(1)
		return

	# 3. Verify echo_progress round-trip with collection completion & sold status
	GameState.reset_for_new_game()
	GameState.collect_echo_segment("echo_settlement_erased", "s1")
	GameState.collect_echo_segment("echo_settlement_erased", "s2")
	if not GameState.is_echo_complete("echo_settlement_erased"):
		printerr("FAIL 17-C: echo_settlement_erased should be complete after collecting s1 and s2!")
		get_tree().quit(1)
		return

	var sell_res = GameState.sell_echo("echo_settlement_erased")
	if not sell_res:
		printerr("FAIL 17-C: sell_echo failed on completed echo_settlement_erased!")
		get_tree().quit(1)
		return

	if not GameState.is_echo_sold("echo_settlement_erased"):
		printerr("FAIL 17-C: echo_settlement_erased sold flag should be true!")
		get_tree().quit(1)
		return

	# Round-trip save/load for sold status
	var save_p17c = SaveSystem.capture("underground_settlement_right", 100.0, 1)
	if not save_p17c or save_p17c.is_empty():
		printerr("FAIL 17-C: Failed to capture save for Phase 17-C!")
		get_tree().quit(1)
		return

	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_p17c):
		printerr("FAIL 17-C: Failed to write save to scratch slot!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	if GameState.is_echo_sold("echo_settlement_erased"):
		printerr("FAIL 17-C: Sold status did not reset after new game!")
		get_tree().quit(1)
		return

	var load_p17c = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	if load_p17c.is_empty():
		printerr("FAIL 17-C: Failed to read save from scratch slot!")
		get_tree().quit(1)
		return
	SaveSystem.apply(load_p17c)

	if not GameState.is_echo_sold("echo_settlement_erased"):
		printerr("FAIL 17-C: Sold status not restored from save!")
		get_tree().quit(1)
		return

	if not GameState.has_echo_segment("echo_settlement_erased", "s1") or not GameState.has_echo_segment("echo_settlement_erased", "s2"):
		printerr("FAIL 17-C: Echo segments not restored after save load!")
		get_tree().quit(1)
		return

	# 4. Narrative assertion: no forbidden words in the echo segments or memory fragment
	for seg in echo_rec_17.get("segments", []):
		if "林霏" in seg.get("text", ""):
			printerr("FAIL 17-C: Forbidden word '林霏' found in segment!")
			get_tree().quit(1)
			return

	var msg_p17 = GameState.STORY_MESSAGES.get("mem_frag_commute_topside", "")
	if "林霏" in msg_p17:
		printerr("FAIL 17-C: Forbidden word '林霏' found in mem_frag_commute_topside!")
		get_tree().quit(1)
		return

	# Clean up scratch slot
	if dir and dir.file_exists(TEST_SCRATCH_SAVE_FILE):
		dir.remove(TEST_SCRATCH_SAVE_FILE)

	print("PASS: Phase 17-C Regression and Save/Load Guards verified.")

