extends "res://tests/manual/phases/phase_23c.gd"

func _run_phase_23b() -> void:
	# ===================== Phase 23-B: Act 3 夜總會保全對話與智取 =====================
	print("--- Phase 23-B: Act 3 夜總會保全對話與智取 ---")

	var dialogue_runner_script = load("res://scripts/dialogue/dialogue_runner.gd")
	if not dialogue_runner_script:
		printerr("FAIL 23-B: Could not load dialogue_runner.gd")
		get_tree().quit(1)
		return

	# 1. 驗證 credits condition (op >= 500) 在 DialogueRunner 中正常評估
	GameState.reset_for_new_game()
	GameState.set_credits(499)

	var runner_p23b = dialogue_runner_script.new()
	var bodyguard_tree = DialogueDB.get_tree_for("nightclub_bodyguard")
	if bodyguard_tree.is_empty():
		printerr("FAIL 23-B: nightclub_bodyguard tree not found in DialogueDB!")
		get_tree().quit(1)
		return

	# 2. 測試：Credits 不足時，賄賂分流走向 bribe_fail
	runner_p23b.start(bodyguard_tree, "lobby")
	# 選擇 0 (賄賂)
	runner_p23b.choose(0)
	var state_fail = runner_p23b.current()
	if state_fail.get("text", "") != "DLG_BODYGUARD_BRIBE_FAIL_TEXT":
		printerr("FAIL 23-B: Bribe with 499 credits should fail, got text: ", state_fail.get("text"))
		get_tree().quit(1)
		return
	if GameState.get_credits() != 499 or GameState.get_flag("passed_nightclub_security", false):
		printerr("FAIL 23-B: Failed bribe should not deduct credits or set security flag!")
		get_tree().quit(1)
		return

	# 3. 測試：Credits 足夠時，賄賂成功走向 bribe_success
	GameState.reset_for_new_game()
	GameState.set_credits(500)
	var runner_success = dialogue_runner_script.new()
	runner_success.start(bodyguard_tree, "lobby")
	runner_success.choose(0)
	var state_success = runner_success.current()
	if state_success.get("text", "") != "DLG_BODYGUARD_BRIBE_SUCCESS_TEXT":
		printerr("FAIL 23-B: Bribe with 500 credits should succeed, got text: ", state_success.get("text"))
		get_tree().quit(1)
		return
	if GameState.get_credits() != 0 or not GameState.get_flag("passed_nightclub_security", false):
		printerr("FAIL 23-B: Bribe success should deduct 500 credits and set security flag!")
		get_tree().quit(1)
		return

	# 4. 測試：無工牌時，假裝身份走向 fake_identity_fail
	GameState.reset_for_new_game()
	var runner_fake_fail = dialogue_runner_script.new()
	runner_fake_fail.start(bodyguard_tree, "lobby")
	runner_fake_fail.choose(1) # 選擇 1 (假裝身份)
	var state_fake_fail = runner_fake_fail.current()
	if state_fake_fail.get("text", "") != "DLG_BODYGUARD_FAKE_IDENTITY_FAIL_TEXT":
		printerr("FAIL 23-B: Pretend without pass should fail, got text: ", state_fake_fail.get("text"))
		get_tree().quit(1)
		return
	if GameState.get_flag("passed_nightclub_security", false):
		printerr("FAIL 23-B: Failed fake identity should not set security flag!")
		get_tree().quit(1)
		return

	# 5. 測試：有工牌時，假裝身份走向 fake_identity_success
	GameState.reset_for_new_game()
	GameState.set_flag("found_staff_pass", true)
	var runner_fake_ok = dialogue_runner_script.new()
	runner_fake_ok.start(bodyguard_tree, "lobby")
	runner_fake_ok.choose(1)
	var state_fake_ok = runner_fake_ok.current()
	if state_fake_ok.get("text", "") != "DLG_BODYGUARD_FAKE_IDENTITY_SUCCESS_TEXT":
		printerr("FAIL 23-B: Pretend with pass should succeed, got text: ", state_fake_ok.get("text"))
		get_tree().quit(1)
		return
	if not GameState.get_flag("passed_nightclub_security", false):
		printerr("FAIL 23-B: Fake identity success should set security flag!")
		get_tree().quit(1)
		return

	# 6. 測試：已通關狀態下，對話會直接進入 already_passed
	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)
	var runner_passed = dialogue_runner_script.new()
	runner_passed.start(bodyguard_tree, "start")
	var state_passed = runner_passed.current()
	if state_passed.get("text", "") != "DLG_BODYGUARD_ALREADY_PASSED_TEXT":
		printerr("FAIL 23-B: Start when already passed should go to already_passed node, got text: ", state_passed.get("text"))
		get_tree().quit(1)
		return

	print("PASS: Phase 23-B bodyguard dialogue, bribe logic, fake identity, and credits condition verified.")

