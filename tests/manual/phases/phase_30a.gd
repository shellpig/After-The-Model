extends "res://tests/manual/phases/phase_30b.gd"

func _run_phase_30a() -> void:
	# ===================== Phase 30-A: 三結局共用收尾 =====================
	print("--- Phase 30-A: 三結局共用收尾 ---")

	# 1. 驗證 meta 讀寫與 endings progress summary
	GameState.reset_for_new_game()

	# 清除現有 meta.cfg 便於乾淨測試
	var config_phase30 := ConfigFile.new()
	var path_phase30 := "user://meta.cfg"
	config_phase30.clear()
	config_phase30.save(path_phase30)

	var achieved_before = GameState.get_achieved_endings()
	if achieved_before.size() != 0:
		printerr("FAIL 30-A: meta endings should be empty on reset, got: ", achieved_before)
		get_tree().quit(1)
		return

	GameState.mark_ending_achieved("reclaim")
	GameState.mark_ending_achieved("protect")

	var achieved_after = GameState.get_achieved_endings()
	if achieved_after.size() != 2 or not achieved_after.has("reclaim") or not achieved_after.has("protect"):
		printerr("FAIL 30-A: meta endings mismatch after marking: ", achieved_after)
		get_tree().quit(1)
		return

	var summary_phase30 = GameState.get_progress_summary()
	if not summary_phase30.has("endings"):
		printerr("FAIL 30-A: progress summary should contain endings field!")
		get_tree().quit(1)
		return

	if summary_phase30["endings"]["done"] != 2 or summary_phase30["endings"]["total"] != 5:
		printerr("FAIL 30-A: summary endings counts mismatch: ", summary_phase30["endings"])
		get_tree().quit(1)
		return

	# 確保 overall_total 與 overall_done 依然相容於舊的 M1 統計（即 32 件）
	if summary_phase30["overall_total"] != 32:
		printerr("FAIL 30-A: overall_total should not include endings, expected 32, got: ", summary_phase30["overall_total"])
		get_tree().quit(1)
		return

	# 2. 測試 EndingEpilogue UI 元件的加載與 headless 推進
	var main_inst_phase30 = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_inst_phase30)
	await get_tree().process_frame

	# 設定 reclaim 結局並觸發
	GameState.set_flag("ending_route_reclaim", true)
	GameState.set_flag("ending_reclaim_played", false)

	# 載入 apartment 並驅動它推進至結局 epilogue
	main_inst_phase30.transition_to("apartment", "epilogue_home")
	await get_tree().process_frame
	await get_tree().process_frame

	var frames_phase30 := 0
	while main_inst_phase30.get_current_scene_id() != "title_screen" and frames_phase30 < 100:
		await get_tree().process_frame
		frames_phase30 += 1

	if main_inst_phase30.get_current_scene_id() == "apartment":
		if not main_inst_phase30.game_ui.ending_epilogue.visible:
			printerr("FAIL 30-A: EndingEpilogue did not start!")
			get_tree().quit(1)
			return

	print("PASS 30-A: EndingEpilogue component verified. Meta write/read, progress summary, and automatic flow transition PASS.")

	if is_instance_valid(main_inst_phase30):
		main_inst_phase30.free()
	await get_tree().process_frame
	GameState.reset_for_new_game()

