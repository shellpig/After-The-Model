extends "res://tests/manual/phases/phase_24c.gd"

func _run_phase_24b() -> void:
	# ===================== Phase 24-B: 分支判定 + 伍姐 / 小岑提前警告 =====================
	print("--- Phase 24-B: 分支判定 + 伍姐 / 小岑提前警告 ---")

	# 1. 驗證對話樹是否有 warning 節點
	var wu_tree_p24b = load("res://data/dialogue/wu.gd").TREE
	if not wu_tree_p24b.has("warning"):
		printerr("FAIL 24-B: wu.gd missing 'warning' node!")
		get_tree().quit(1)
		return
	var cen_tree_p24b = load("res://data/dialogue/cen.gd").TREE
	if not cen_tree_p24b.has("warning"):
		printerr("FAIL 24-B: cen.gd missing 'warning' node!")
		get_tree().quit(1)
		return

	# 2. 模擬 DialogueRunner 評估警告條件 (Wu)
	var runner_wu_p24b = load("res://scripts/dialogue/dialogue_runner.gd").new()
	# Case 24B-1: met_wu=true, affinity_wu=2, heard_wu_warning=false -> goto warning
	GameState.reset_for_new_game()
	GameState.set_flag("met_wu", true)
	GameState.set_flag("affinity_wu", 2)
	runner_wu_p24b.start(wu_tree_p24b)
	if runner_wu_p24b._current_node_id != "warning":
		printerr("FAIL 24-B: Wu dialogue should route to 'warning' when met_wu=true and affinity_wu=2!")
		get_tree().quit(1)
		return

	# 推進對話，確認設了 heard_wu_warning 並進入 retalk
	runner_wu_p24b.advance() # 進入 warning node 會執行 set_flag heard_wu_warning
	if GameState.get_flag("heard_wu_warning", false) != true:
		printerr("FAIL 24-B: heard_wu_warning flag not set after warning node!")
		get_tree().quit(1)
		return

	# Case 24B-2: met_wu=true, affinity_wu=2, heard_wu_warning=true -> goto retalk
	var runner_wu_retalk_p24b = load("res://scripts/dialogue/dialogue_runner.gd").new()
	runner_wu_retalk_p24b.start(wu_tree_p24b)
	if runner_wu_retalk_p24b._current_node_id != "retalk":
		printerr("FAIL 24-B: Wu dialogue should route to 'retalk' when warning already heard!")
		get_tree().quit(1)
		return

	# 3. 模擬 DialogueRunner 評估警告條件 (Cen)
	var runner_cen_p24b = load("res://scripts/dialogue/dialogue_runner.gd").new()
	GameState.reset_for_new_game()
	GameState.set_flag("met_cen", true)
	GameState.set_flag("affinity_cen", 2)
	runner_cen_p24b.start(cen_tree_p24b)
	if runner_cen_p24b._current_node_id != "warning":
		printerr("FAIL 24-B: Cen dialogue should route to 'warning' when met_cen=true and affinity_cen=2!")
		get_tree().quit(1)
		return
	runner_cen_p24b.advance()
	if GameState.get_flag("heard_cen_warning", false) != true:
		printerr("FAIL 24-B: heard_cen_warning flag not set after warning node!")
		get_tree().quit(1)
		return

	# 4. 驗證對話 i18n 翻譯是否齊全
	for loc_p24b in ["zh_TW", "zh_CN", "en"]:
		TranslationServer.set_locale(loc_p24b)
		for key_p24b in ["DLG_WU_WARNING_TEXT", "DLG_CEN_WARNING_TEXT"]:
			var tr_text = tr(key_p24b)
			if tr_text == key_p24b or tr_text.is_empty():
				printerr("FAIL 24-B: missing translation for " + key_p24b + " in locale: " + loc_p24b)
				get_tree().quit(1)
				return

	# 還原 locale
	TranslationServer.set_locale("zh_TW")

	# 5. 驗證 24-B 分支判定公式與攔截結算
	var SevenBetrayal_p24b = load("res://data/quests/seven_betrayal.gd")

	# Case 24B-3: trace = 2, no warning -> Branch A (stopped_full)
	GameState.reset_for_new_game()
	GameState.add_trace(2)
	GameState.set_flag("affinity_wu", 0)
	GameState.set_flag("affinity_cen", 0)
	if SevenBetrayal_p24b.get_betrayal_branch() != "stopped_full":
		printerr("FAIL 24-B: trace=2 should result in stopped_full!")
		get_tree().quit(1)
		return

	# Settle Case 24B-3 and check outputs (Idempotency test)
	QuestManager.start("seven_betrayal")
	var initial_seven_aff_p24b = GameState.get_flag("affinity_seven", 0)
	var initial_wu_aff_p24b = GameState.get_flag("affinity_wu", 0)

	var res_first_p24b = SevenBetrayal_p24b.resolve_betrayal_results()
	if not res_first_p24b:
		printerr("FAIL 24-B: first resolve_betrayal_results() call should return true!")
		get_tree().quit(1)
		return

	var res_second_p24b = SevenBetrayal_p24b.resolve_betrayal_results()
	if res_second_p24b:
		printerr("FAIL 24-B: second resolve_betrayal_results() call should return false (not idempotent)!")
		get_tree().quit(1)
		return

	if GameState.get_flag("seven_stopped_full", false) != true or GameState.get_flag("seven_stopped_partial", false) == true:
		printerr("FAIL 24-B: Settle trace=2 failed stopped_full or mutual exclusion failed!")
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_seven", 0) != initial_seven_aff_p24b - 2:
		printerr("FAIL 24-B: stopped_full should reduce affinity_seven by 2, and no further on second call!")
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_wu", 0) != initial_wu_aff_p24b:
		printerr("FAIL 24-B: stopped_full should not change affinity_wu!")
		get_tree().quit(1)
		return
	if GameState.get_flag("seven_betrayal_pending", false) == true:
		printerr("FAIL 24-B: betrayal_pending should be false after resolution!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("seven_betrayal") != "completed":
		printerr("FAIL 24-B: seven_betrayal quest should be completed after resolution!")
		get_tree().quit(1)
		return

	# Case 24B-4: trace = 3, no warning -> Branch B (stopped_partial)
	GameState.reset_for_new_game()
	GameState.add_trace(3)
	GameState.set_flag("affinity_wu", 0)
	GameState.set_flag("affinity_cen", 0)
	if SevenBetrayal_p24b.get_betrayal_branch() != "stopped_partial":
		printerr("FAIL 24-B: trace=3 without warnings should result in stopped_partial!")
		get_tree().quit(1)
		return

	# Settle Case 24B-4 and check outputs
	QuestManager.start("seven_betrayal")
	initial_seven_aff_p24b = GameState.get_flag("affinity_seven", 0)
	initial_wu_aff_p24b = GameState.get_flag("affinity_wu", 0)
	SevenBetrayal_p24b.resolve_betrayal_results()
	if GameState.get_flag("seven_stopped_partial", false) != true or GameState.get_flag("seven_stopped_full", false) == true:
		printerr("FAIL 24-B: Settle trace=3 failed stopped_partial or mutual exclusion failed!")
		get_tree().quit(1)
		return
	if GameState.get_flag("cen_voiceprint_exposed", false) != true:
		printerr("FAIL 24-B: stopped_partial should expose Cen's voiceprint!")
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_seven", 0) != initial_seven_aff_p24b - 1:
		printerr("FAIL 24-B: stopped_partial should reduce affinity_seven by 1!")
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_wu", 0) != initial_wu_aff_p24b - 1:
		printerr("FAIL 24-B: stopped_partial should reduce affinity_wu by 1!")
		get_tree().quit(1)
		return

	# Case 24B-5: trace = 3, wu warning -> Branch A (stopped_full)
	GameState.reset_for_new_game()
	GameState.add_trace(3)
	GameState.set_flag("affinity_wu", 2)
	GameState.set_flag("affinity_cen", 0)
	if SevenBetrayal_p24b.get_betrayal_branch() != "stopped_full":
		printerr("FAIL 24-B: trace=3 with wu warning should result in stopped_full!")
		get_tree().quit(1)
		return

	# Case 24B-6: trace = 3, cen warning -> Branch A (stopped_full)
	GameState.reset_for_new_game()
	GameState.add_trace(3)
	GameState.set_flag("affinity_wu", 0)
	GameState.set_flag("affinity_cen", 2)
	if SevenBetrayal_p24b.get_betrayal_branch() != "stopped_full":
		printerr("FAIL 24-B: trace=3 with cen warning should result in stopped_full!")
		get_tree().quit(1)
		return

	print("PASS: Phase 24-B warning dialogues and routing verified.")
	print("PASS: Phase 24-B branch formula boundary and settlement verified.")

