extends "res://tests/manual/phases/phase_24b.gd"

func _run_phase_24a() -> void:
	# ===================== Phase 24-A: 七號事件 quest 化 + 爆發 gate =====================
	print("--- Phase 24-A: 七號事件 quest 化 + 爆發 gate ---")

	# 1. 測試任務資料與 resolver 預設分流
	var QuestDB_p24a = load("res://data/quests/quest_db.gd")
	var quest_data_p24a = QuestDB_p24a.get_quest_data("seven_betrayal")
	if quest_data_p24a == null:
		printerr("FAIL 24-A: seven_betrayal quest data not registered in QuestDB!")
		get_tree().quit(1)
		return

	# 模擬 resolve_completed_note 分支
	# A: 預設/成功攔下
	GameState.reset_for_new_game()
	var note_full_p24a = quest_data_p24a.resolve_completed_note()
	if note_full_p24a.get("title", "") != "QUEST_SEVEN_BETRAYAL_COMPLETED_FULL_TITLE":
		printerr("FAIL 24-A: resolve_completed_note() should return full completion note by default!")
		get_tree().quit(1)
		return

	# B: 部分攔下
	GameState.set_flag("seven_stopped_partial", true)
	var note_partial_p24a = quest_data_p24a.resolve_completed_note()
	if note_partial_p24a.get("title", "") != "QUEST_SEVEN_BETRAYAL_COMPLETED_PARTIAL_TITLE":
		printerr("FAIL 24-A: resolve_completed_note() should return partial completion note when seven_stopped_partial is true!")
		get_tree().quit(1)
		return

	# D: 和平線
	GameState.set_flag("seven_stopped_partial", false)
	GameState.set_flag("seven_peace_branch_d", true)
	var note_peace_p24a = quest_data_p24a.resolve_completed_note()
	if note_peace_p24a.get("title", "") != "QUEST_SEVEN_BETRAYAL_COMPLETED_PEACE_TITLE":
		printerr("FAIL 24-A: resolve_completed_note() should return peace completion note when seven_peace_branch_d is true!")
		get_tree().quit(1)
		return

	# 2. 測試爆發 gate
	# A: 未通關夜總會 -> 不爆發
	GameState.reset_for_new_game()
	var level_p24a = load("res://scenes/levels/underground_settlement/underground_settlement_right.tscn").instantiate()
	add_child(level_p24a)
	level_p24a.set_entry_point("from_left")
	if GameState.get_flag("seven_betrayal_triggered", false):
		printerr("FAIL 24-A: betrayal should not trigger before nightclub security is passed!")
		get_tree().quit(1)
		return
	remove_child(level_p24a)
	level_p24a.free()

	# B: 已通關夜總會，未走 D -> 爆發
	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)
	level_p24a = load("res://scenes/levels/underground_settlement/underground_settlement_right.tscn").instantiate()
	add_child(level_p24a)
	level_p24a.set_entry_point("from_left")
	if not GameState.get_flag("seven_betrayal_triggered", false) or not GameState.get_flag("seven_betrayal_pending", false):
		printerr("FAIL 24-A: betrayal trigger gate failed to activate seven_betrayal_triggered/pending!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("seven_betrayal") != "active":
		printerr("FAIL 24-A: seven_betrayal quest should be active after trigger!")
		get_tree().quit(1)
		return
	remove_child(level_p24a)
	level_p24a.free()

	# C: 已通關夜總會，已走 D -> 不爆發
	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)
	GameState.set_flag("seven_peace_branch_d", true)
	level_p24a = load("res://scenes/levels/underground_settlement/underground_settlement_right.tscn").instantiate()
	add_child(level_p24a)
	level_p24a.set_entry_point("from_left")
	if GameState.get_flag("seven_betrayal_triggered", false):
		printerr("FAIL 24-A: betrayal should not trigger when seven_peace_branch_d is true!")
		get_tree().quit(1)
		return
	remove_child(level_p24a)
	level_p24a.free()

	# 3. 驗證 i18n 翻譯（測試 M2 系統是否可正確 resolve）
	for loc_p24a in ["zh_TW", "zh_CN", "en"]:
		TranslationServer.set_locale(loc_p24a)
		var tr_title = tr("QUEST_SEVEN_BETRAYAL_STEP_STARTED_TITLE")
		if tr_title == "QUEST_SEVEN_BETRAYAL_STEP_STARTED_TITLE" or tr_title.is_empty():
			printerr("FAIL 24-A: missing translation for QUEST_SEVEN_BETRAYAL_STEP_STARTED_TITLE in locale: " + loc_p24a)
			get_tree().quit(1)
			return

	# 還原 locale 到 zh_TW
	TranslationServer.set_locale("zh_TW")

	print("PASS: Phase 24-A questification and trigger gate verified.")

