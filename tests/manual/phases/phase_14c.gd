extends "res://tests/manual/phases/phase_14d.gd"

func _run_phase_14c() -> void:
	# ===================== Phase 14-C: Store Robot Hook =====================
	print("--- Phase 14-C: Store Robot Hook ---")

	# Case 1: mem_frag_linfei_1 = false
	GameState.reset_for_new_game()
	GameState.set_flag("vendor_bot_repaired", false)
	GameState.set_flag("mem_frag_linfei_1", false)
	GameState.set_flag("ada_misrecognized", false)
	var robot_runner_1 = DialogueRunner.new()
	robot_runner_1.start(DialogueDB.get_tree_for("store_robot"))
	if robot_runner_1._current_node_id != "babble_intro":
		printerr("FAIL 14-C: Store robot tree did not route to babble_intro when mem_frag_linfei_1 is false! Got: ", robot_runner_1._current_node_id)
		get_tree().quit(1)
		return

	# Case 2: mem_frag_linfei_1 = true, ada_misrecognized = false
	GameState.reset_for_new_game()
	GameState.set_flag("vendor_bot_repaired", false)
	GameState.set_flag("mem_frag_linfei_1", true)
	GameState.set_flag("ada_misrecognized", false)
	var robot_runner_2 = DialogueRunner.new()
	robot_runner_2.start(DialogueDB.get_tree_for("store_robot"))
	if robot_runner_2._current_node_id != "ada_misrecognized_hook":
		printerr("FAIL 14-C: Store robot tree did not route to ada_misrecognized_hook when mem_frag_linfei_1 is true! Got: ", robot_runner_2._current_node_id)
		get_tree().quit(1)
		return

	if not GameState.get_flag("ada_misrecognized", false):
		printerr("FAIL 14-C: ada_misrecognized flag not set after entering ada_misrecognized_hook!")
		get_tree().quit(1)
		return

	if not GameState.get_flag("talked_store_robot", false):
		printerr("FAIL 14-C: talked_store_robot flag not set after entering ada_misrecognized_hook!")
		get_tree().quit(1)
		return

	# Case 3: ada_misrecognized = true
	var robot_runner_3 = DialogueRunner.new()
	robot_runner_3.start(DialogueDB.get_tree_for("store_robot"))
	if robot_runner_3._current_node_id != "babble_intro":
		printerr("FAIL 14-C: Store robot tree did not route to babble_intro when ada_misrecognized is true! Got: ", robot_runner_3._current_node_id)
		get_tree().quit(1)
		return

	# Case 4: quest repair_vendor_bot is active
	GameState.reset_for_new_game()
	GameState.set_flag("vendor_bot_repaired", false)
	GameState.set_flag("mem_frag_linfei_1", true)
	GameState.set_flag("ada_misrecognized", false)
	QuestManager.start("repair_vendor_bot")
	var robot_runner_4 = DialogueRunner.new()
	robot_runner_4.start(DialogueDB.get_tree_for("store_robot"))
	if robot_runner_4._current_node_id != "diagnose_intro":
		printerr("FAIL 14-C: Store robot tree did not route to diagnose_intro when quest is active! Got: ", robot_runner_4._current_node_id)
		get_tree().quit(1)
		return

	# Case 5: vendor_bot_repaired is true
	GameState.reset_for_new_game()
	GameState.set_flag("vendor_bot_repaired", true)
	GameState.set_flag("mem_frag_linfei_1", true)
	GameState.set_flag("ada_misrecognized", false)
	var robot_runner_5 = DialogueRunner.new()
	robot_runner_5.start(DialogueDB.get_tree_for("store_robot"))
	if robot_runner_5._current_node_id != "repaired_reset":
		printerr("FAIL 14-C: Store robot tree did not route to repaired_reset when repaired is true! Got: ", robot_runner_5._current_node_id)
		get_tree().quit(1)
		return

	print("PASS: Phase 14-C store robot hook verified.")

