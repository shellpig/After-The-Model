extends "res://tests/manual/phases/phase_23a.gd"

func _run_phase_21f() -> void:
	# ===================== Phase 21-F: 可賣 + 回歸 + 存讀檔 =====================
	print("--- Phase 21-F: 可賣 + 回歸 + 存讀檔 ---")

	# 重置狀態
	GameState.reset_for_new_game()

	# 1. 驗證未集滿時不可賣
	if GameState.sell_echo("echo_linfei"):
		printerr("FAIL 21-F: sell_echo should return false on incomplete echo_linfei!")
		get_tree().quit(1)
		return

	# 2. 採集完畢
	GameState.record_full_echo("echo_linfei")
	if not GameState.is_echo_complete("echo_linfei"):
		printerr("FAIL 21-F: echo_linfei should be complete after record_full_echo!")
		get_tree().quit(1)
		return

	# 3. 驗證可賣
	var initial_credits_phase21 = GameState.get_credits()
	var initial_trace_phase21 = GameState.get_trace()
	if not GameState.sell_echo("echo_linfei"):
		printerr("FAIL 21-F: sell_echo failed on completed echo_linfei!")
		get_tree().quit(1)
		return

	# 4. 驗證 credits 增加 (400) 且 trace 減少 (TRACE_DELTA_SELL = -1)
	if GameState.get_credits() != initial_credits_phase21 + 400:
		printerr("FAIL 21-F: Wrong credits rewarded: ", GameState.get_credits())
		get_tree().quit(1)
		return
	if GameState.get_trace() != initial_trace_phase21 - 1:
		printerr("FAIL 21-F: Wrong trace change: ", GameState.get_trace())
		get_tree().quit(1)
		return

	# 5. 驗證 sold_linfei_echo 旗標已設為 true
	if not GameState.get_flag("sold_linfei_echo", false):
		printerr("FAIL 21-F: sold_linfei_echo flag is not set after selling echo_linfei!")
		get_tree().quit(1)
		return

	# 6. 存讀檔 round-trip 驗證
	var save_dict_phase21 = SaveSystem.capture("nightclub", 100.0, 1)
	GameState.reset_for_new_game()
	if GameState.get_flag("sold_linfei_echo", false):
		printerr("FAIL 21-F: sold_linfei_echo should be reset on new game!")
		get_tree().quit(1)
		return

	SaveSystem.apply(save_dict_phase21)
	if not GameState.get_flag("sold_linfei_echo", false):
		printerr("FAIL 21-F: sold_linfei_echo flag was not restored after save load!")
		get_tree().quit(1)
		return
	if not GameState.is_echo_sold("echo_linfei"):
		printerr("FAIL 21-F: echo_linfei sold status was not restored after save load!")
		get_tree().quit(1)
		return

	# 7. 驗證 Dialogue 系統中的 op sell_echo 能在 Lu Qichen 的對話流程中正確運作
	var eff_sell_linfei = {"op": "sell_echo", "value": "echo_linfei"}
	GameState.reset_for_new_game()
	GameState.record_full_echo("echo_linfei")
	var runner_phase21 = load("res://scripts/dialogue/dialogue_runner.gd").new()
	runner_phase21.start(DialogueDB.get_tree_for("lu_qichen"))
	# execute dialogue runner effect
	runner_phase21._apply_effect(eff_sell_linfei)
	if not GameState.is_echo_sold("echo_linfei") or not GameState.get_flag("sold_linfei_echo", false):
		printerr("FAIL 21-F: sell_echo effect did not sell the echo or set flag in dialogue runner!")
		get_tree().quit(1)
		return

	print("PASS: Phase 21-F sellable, regression, and save/load verified.")

