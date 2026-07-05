extends "res://tests/manual/phases/phase_14c.gd"

func _run_phase_14b() -> void:
	# ===================== Phase 14-B: Dialogue Hooks =====================
	print("--- Phase 14-B: Dialogue Hooks ---")

	# Lu Qichen test cases
	# Case 1: mem_frag_linfei_1 = false
	GameState.reset_for_new_game()
	GameState.set_flag("met_lu", true)
	GameState.set_flag("mem_frag_linfei_1", false)
	GameState.set_flag("lu_hinted_topside", false)
	var lu_runner_1 = DialogueRunner.new()
	lu_runner_1.start(DialogueDB.get_tree_for("lu_qichen"))
	if lu_runner_1._current_node_id != "hub":
		printerr("FAIL 14-B: Lu Qichen tree did not route to hub when mem_frag_linfei_1 is false! Got: ", lu_runner_1._current_node_id)
		get_tree().quit(1)
		return

	# Case 2: mem_frag_linfei_1 = true, lu_hinted_topside = false
	GameState.reset_for_new_game()
	GameState.set_flag("met_lu", true)
	GameState.set_flag("mem_frag_linfei_1", true)
	GameState.set_flag("lu_hinted_topside", false)
	var lu_runner_2 = DialogueRunner.new()
	lu_runner_2.start(DialogueDB.get_tree_for("lu_qichen"))
	if lu_runner_2._current_node_id != "lu_daze_hook":
		printerr("FAIL 14-B: Lu Qichen tree did not route to lu_daze_hook when mem_frag_linfei_1 is true and lu_hinted_topside is false! Got: ", lu_runner_2._current_node_id)
		get_tree().quit(1)
		return

	if not GameState.get_flag("lu_hinted_topside", false):
		printerr("FAIL 14-B: lu_hinted_topside flag not set after entering lu_daze_hook!")
		get_tree().quit(1)
		return

	# Case 3: lu_hinted_topside = true
	var lu_runner_3 = DialogueRunner.new()
	lu_runner_3.start(DialogueDB.get_tree_for("lu_qichen"))
	if lu_runner_3._current_node_id != "hub":
		printerr("FAIL 14-B: Lu Qichen tree did not route to hub when lu_hinted_topside is true! Got: ", lu_runner_3._current_node_id)
		get_tree().quit(1)
		return

	# Wan test cases
	# Case 1: mem_frag_linfei_1 = false
	GameState.reset_for_new_game()
	GameState.set_flag("met_wan", true)
	GameState.set_flag("mem_frag_linfei_1", false)
	GameState.set_flag("wan_noticed_daze", false)
	var wan_runner_1 = DialogueRunner.new()
	wan_runner_1.start(DialogueDB.get_tree_for("wan"))
	if wan_runner_1._current_node_id != "retalk":
		printerr("FAIL 14-B: Wan tree did not route to retalk when mem_frag_linfei_1 is false! Got: ", wan_runner_1._current_node_id)
		get_tree().quit(1)
		return

	# Case 2: mem_frag_linfei_1 = true, wan_noticed_daze = false
	GameState.reset_for_new_game()
	GameState.set_flag("met_wan", true)
	GameState.set_flag("mem_frag_linfei_1", true)
	GameState.set_flag("wan_noticed_daze", false)
	var wan_runner_2 = DialogueRunner.new()
	wan_runner_2.start(DialogueDB.get_tree_for("wan"))
	if wan_runner_2._current_node_id != "wan_daze_hook":
		printerr("FAIL 14-B: Wan tree did not route to wan_daze_hook when mem_frag_linfei_1 is true and wan_noticed_daze is false! Got: ", wan_runner_2._current_node_id)
		get_tree().quit(1)
		return

	if not GameState.get_flag("wan_noticed_daze", false):
		printerr("FAIL 14-B: wan_noticed_daze flag not set after entering wan_daze_hook!")
		get_tree().quit(1)
		return

	# Case 3: wan_noticed_daze = true
	var wan_runner_3 = DialogueRunner.new()
	wan_runner_3.start(DialogueDB.get_tree_for("wan"))
	if wan_runner_3._current_node_id != "retalk":
		printerr("FAIL 14-B: Wan tree did not route to retalk when wan_noticed_daze is true! Got: ", wan_runner_3._current_node_id)
		get_tree().quit(1)
		return

	print("PASS: Phase 14-B dialogue hooks verified.")

