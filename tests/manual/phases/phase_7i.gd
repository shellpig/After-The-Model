extends "res://tests/manual/phases/phase_7j.gd"

func _run_phase_7i() -> void:
	# 23. Verify Phase 7-I Turn-in Quest to Wan
	print("Verifying Phase 7-I Turn-in Quest to Wan...")

	# 1. Reset state
	GameState.reset_for_new_game()

	# 2. Start quest and advance to found_activation_box
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")

	# 3. Add item A and B to inventory
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
	GameState.add_item("early_ai_assistant_activation_box", 1)
	GameState.add_item("old_ai_authorization_module", 1)
	QuestManager.set_flag("alley_backrooms_3f", "found_old_ai_authorization_module", true)

	# Verify items exist
	if not GameState.has_item("early_ai_assistant_activation_box", 1) or not GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: Failed to populate items A and B for turn-in test!")
		get_tree().quit(1)
		return

	# 4. Instantiate dialogue tree for Wan and verify options in retalk node
	runner = DialogueRunner.new()
	DialogueDB = load("res://data/dialogue/dialogue_db.gd")
	wan_tree = DialogueDB.get_tree_for("wan")

	# Set met_wan flag so start goes to retalk
	GameState.set_flag("met_wan", true)
	runner.start(wan_tree)

	var cur = runner.current()
	# Current should be retalk
	if cur.get("text", "") == "":
		printerr("FAIL: Dialogue tree failed to start on Wan tree!")
		get_tree().quit(1)
		return

	# Check retalk choices to ensure choice index 3 is '我找到那個啟用盒了。'
	var choices = cur.get("choices", [])
	var turn_in_choice = null
	for choice in choices:
		if tr(choice.get("label", "")) == "我找到那個啟用盒了。":
			turn_in_choice = choice
			break

	if not turn_in_choice:
		printerr("FAIL: Turn-in choice '我找到那個啟用盒了。' not visible in retalk node!")
		get_tree().quit(1)
		return

	# 5. Choose turn-in option (we have B, so this routes to turn_in_found_module choice node)
	runner.choose(turn_in_choice.get("index"))

	# 6. Verify transition to turn_in_found_module
	var after_choice = runner.current()
	if not tr(after_choice.get("text", "")).contains("底下還藏了什麼寶貝"):
		printerr("FAIL: Choice did not transition to turn_in_found_module node! Text got: ", tr(after_choice.get("text")))
		get_tree().quit(1)
		return

	# Verify two choices present
	var end_choices = after_choice.get("choices", [])
	if end_choices.size() != 2:
		printerr("FAIL: turn_in_found_module should have 2 choices, got: ", end_choices.size())
		get_tree().quit(1)
		return

	# Choose Choice 0: Only turn in plain box (Ending B)
	var idx_plain = end_choices[0].get("index")
	runner.choose(idx_plain)

	var plain_node = runner.current()
	if not tr(plain_node.get("text", "")).contains("開玩笑的啦"):
		printerr("FAIL: turn_in_plain text incorrect! Got: ", tr(plain_node.get("text")))
		get_tree().quit(1)
		return

	# Advance to trigger effects
	runner.advance()

	# Verify Ending B state: A removed, B retained, completed, credits = 800 (300 + 500), note B
	if GameState.has_item("early_ai_assistant_activation_box", 1):
		printerr("FAIL: early_ai_assistant_activation_box (A) was not removed in Ending B!")
		get_tree().quit(1)
		return
	if not GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: old_ai_authorization_module (B) was removed in Ending B!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("alley_backrooms_3f") != "completed":
		printerr("FAIL: Quest status is not 'completed' in Ending B!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 800:
		printerr("FAIL: Ending B credits should be 800, got: ", GameState.get_credits())
		get_tree().quit(1)
		return
	var notes_b = GameState.get_notes("工作")
	if notes_b.is_empty() or notes_b[0].get("status") != "completed" or not _tr_body(notes_b[0].get("body")).contains("留在了自己身上"):
		printerr("FAIL: Work note for Ending B incorrect!")
		get_tree().quit(1)
		return
	print("PASS: Ending B (Kept module) verified successfully.")

	# --- Test Ending C (Gave module) ---
	# Reset state
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
	GameState.add_item("early_ai_assistant_activation_box", 1)
	GameState.add_item("old_ai_authorization_module", 1)
	QuestManager.set_flag("alley_backrooms_3f", "found_old_ai_authorization_module", true)

	runner = DialogueRunner.new()
	GameState.set_flag("met_wan", true)
	runner.start(wan_tree)
	runner.choose(turn_in_choice.get("index"))

	# Select Choice 1: 連舊模組也一起遞過去 (Ending C)
	end_choices = runner.current().get("choices", [])
	runner.choose(end_choices[1].get("index"))

	var full_node = runner.current()
	if not tr(full_node.get("text", "")).contains("舊式授權晶片"):
		printerr("FAIL: turn_in_full text incorrect! Got: ", tr(full_node.get("text")))
		get_tree().quit(1)
		return

	# Advance to trigger effects
	runner.advance()

	# Verify Ending C state: A and B removed, completed, credits = 1300 (300 + 1000), affinity_wan = 2, gave_wan_old_module = true, note C
	if GameState.has_item("early_ai_assistant_activation_box", 1) or GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: Items A or B not removed in Ending C!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("alley_backrooms_3f") != "completed":
		printerr("FAIL: Quest status not completed in Ending C!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 1300:
		printerr("FAIL: Ending C credits should be 1300, got: ", GameState.get_credits())
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_wan") != 2 or not GameState.get_flag("gave_wan_old_module"):
		printerr("FAIL: Ending C flags/affinity not updated correctly!")
		get_tree().quit(1)
		return
	var notes_c = GameState.get_notes("工作")
	if notes_c.is_empty() or notes_c[0].get("status") != "completed" or not _tr_body(notes_c[0].get("body")).contains("託付"):
		printerr("FAIL: Work note for Ending C incorrect!")
		get_tree().quit(1)
		return
	print("PASS: Ending C (Gave module) verified successfully.")

	# Verify retalk_close routing
	runner = DialogueRunner.new()
	runner.start(wan_tree)
	var close_node = runner.current()
	if not tr(close_node.get("text", "")).contains("擠擠"):
		printerr("FAIL: Start did not route to retalk_close after Ending C! Got: ", tr(close_node.get("text")))
		get_tree().quit(1)
		return

	# Select choice 0: "陪妳站會兒。"
	var close_choices = close_node.get("choices", [])
	runner.choose(close_choices[0].get("index"))

	# Verify affinity increment and transition to end_close
	if GameState.get_flag("affinity_wan") != 3:
		printerr("FAIL: retalk_close choice 0 did not increment affinity_wan! Got: ", GameState.get_flag("affinity_wan"))
		get_tree().quit(1)
		return
	var close_end = runner.current()
	if not tr(close_end.get("text", "")).contains("別把雨聲"):
		printerr("FAIL: retalk_close did not transition to end_close! Got: ", tr(close_end.get("text")))
		get_tree().quit(1)
		return
	print("PASS: retalk_close dialogue flow verified successfully.")

	# --- Test Ending A (Plain box only) ---
	# Reset state
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
	GameState.add_item("early_ai_assistant_activation_box", 1)
	QuestManager.set_flag("alley_backrooms_3f", "found_old_ai_authorization_module", false)

	runner = DialogueRunner.new()
	GameState.set_flag("met_wan", true)
	runner.start(wan_tree)

	# Select turn-in option (routes to turn_in_plain since we don't have B)
	runner.choose(turn_in_choice.get("index"))

	var plain_node_a = runner.current()
	if not tr(plain_node_a.get("text", "")).contains("開玩笑的啦"):
		printerr("FAIL: Ending A did not route directly to turn_in_plain! Got text: ", tr(plain_node_a.get("text")))
		get_tree().quit(1)
		return

	# Advance to trigger effects
	runner.advance()

	# Verify Ending A state: A removed, completed, credits = 800 (+500), note A, gave_wan_old_module false
	if GameState.has_item("early_ai_assistant_activation_box", 1):
		printerr("FAIL: early_ai_assistant_activation_box was not removed in Ending A!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("alley_backrooms_3f") != "completed":
		printerr("FAIL: Quest status is not 'completed' in Ending A!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 800:
		printerr("FAIL: Ending A credits should be 800, got: ", GameState.get_credits())
		get_tree().quit(1)
		return
	if GameState.get_flag("gave_wan_old_module", false):
		printerr("FAIL: gave_wan_old_module should be false in Ending A!")
		get_tree().quit(1)
		return
	var notes_a = GameState.get_notes("工作")
	if notes_a.is_empty() or notes_a[0].get("status") != "completed" or not _tr_body(notes_a[0].get("body")).contains("錯過"):
		printerr("FAIL: Work note for Ending A incorrect!")
		get_tree().quit(1)
		return
	print("PASS: Ending A (Plain box only) verified successfully.")

	# 9. Verify defensive case: if A is not in inventory, turn-in fails and quest is NOT completed
	# Reset for clean test state with active quest at found_activation_box
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")

	# Clear inventory (ensure NO activation box A is present)
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})

	# Instantiate tree and force enter turn-in node directly (routes to turn_in_plain since no B)
	runner = DialogueRunner.new()
	wan_tree = DialogueDB.get_tree_for("wan")
	runner.start(wan_tree, "alley_backrooms_turn_in")

	# Advance dialogue to trigger effects
	runner.advance()

	# Since A was missing, remove_item effect should fail and abort completion
	if QuestManager.get_status("alley_backrooms_3f") == "completed":
		printerr("FAIL: Quest status was marked completed even when A was missing during turn-in!")
		get_tree().quit(1)
		return

	var notes_defensive = GameState.get_notes("工作")
	if notes_defensive.is_empty() or notes_defensive[0].get("status") == "completed":
		printerr("FAIL: Work note status was marked completed even when A was missing during turn-in!")
		get_tree().quit(1)
		return
	print("PASS: Turn-in defensive constraint verified (missing item aborts quest completion).")

	print("PASS: Phase 7-I Turn-in Quest to Wan verified successfully.")

