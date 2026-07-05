extends "res://tests/manual/phases/phase_24a.gd"

func _run_phase_23d() -> void:
	# ===================== Phase 23-D: Act 3 夜總會回歸、存讀檔與進度驗證 =====================
	print("--- Phase 23-D: Act 3 夜總會回歸、存讀檔與進度驗證 ---")
	GameState.reset_for_new_game()

	# 1. 測試：在新遊戲重置狀態下，各旗標應為 false/空，進度為 0
	if GameState.get_flag("passed_nightclub_security", false) or GameState.get_flag("found_staff_pass", false) or GameState.has_item("nightclub_staff_pass"):
		printerr("FAIL 23-D: New game reset failed to clear Phase 23 states!")
		get_tree().quit(1)
		return

	# 2. 測試：特殊道具進度因取得工牌打勾，且不退勾
	var added_pass_p23d := GameState.add_item("nightclub_staff_pass", 1)
	if not added_pass_p23d:
		printerr("FAIL 23-D: Could not add nightclub_staff_pass during progress check!")
		get_tree().quit(1)
		return

	var progress_summary_p23d = GameState.get_progress_summary()
	var collected_items_p23d = GameState.collected_special_items
	if not collected_items_p23d.get("nightclub_staff_pass", false):
		printerr("FAIL 23-D: nightclub_staff_pass should mark progress special items collected!")
		get_tree().quit(1)
		return

	var badge_instance_id_p23d = ""
	for item in GameState.get_inventory():
		if item != null and item.get("item_id", "") == "nightclub_staff_pass":
			badge_instance_id_p23d = item.get("instance_id", "")
			break
	if badge_instance_id_p23d != "":
		GameState.remove_item(badge_instance_id_p23d)

	if not GameState.collected_special_items.get("nightclub_staff_pass", false):
		printerr("FAIL 23-D: progress special items should remain marked after item removal (no unticking)!")
		get_tree().quit(1)
		return

	# 3. 測試：存讀檔 round-trip
	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)
	GameState.set_flag("found_staff_pass", true)
	var added_pass_again_p23d = GameState.add_item("nightclub_staff_pass", 1)
	if not added_pass_again_p23d:
		printerr("FAIL 23-D: Setup failed for save/load test!")
		get_tree().quit(1)
		return

	var save_dict_p23d = SaveSystem.capture("nightclub", 100.0, 1)

	GameState.reset_for_new_game()
	if GameState.get_flag("passed_nightclub_security", false) or GameState.get_flag("found_staff_pass", false) or GameState.has_item("nightclub_staff_pass"):
		printerr("FAIL 23-D: State reset failed during save/load check!")
		get_tree().quit(1)
		return

	if not SaveSystem.validate(save_dict_p23d):
		printerr("FAIL 23-D: SaveSystem.validate() failed for save_dict_p23d!")
		get_tree().quit(1)
		return
	SaveSystem.apply(save_dict_p23d)

	if not GameState.get_flag("passed_nightclub_security", false) or not GameState.get_flag("found_staff_pass", false):
		printerr("FAIL 23-D: Save/load failed to restore story flags!")
		get_tree().quit(1)
		return
	if not GameState.has_item("nightclub_staff_pass"):
		printerr("FAIL 23-D: Save/load failed to restore nightclub_staff_pass in inventory!")
		get_tree().quit(1)
		return
	if not GameState.collected_special_items.get("nightclub_staff_pass", false):
		printerr("FAIL 23-D: Save/load failed to restore special item progress!")
		get_tree().quit(1)
		return

	# 4. 測試：缺鍵/歷史存檔相容性
	var compat_dict_p23d = save_dict_p23d.duplicate(true)
	var data_dict_p23d = compat_dict_p23d.get("data", {})
	if data_dict_p23d.has("story_flags"):
		data_dict_p23d["story_flags"].erase("passed_nightclub_security")
		data_dict_p23d["story_flags"].erase("found_staff_pass")
	if data_dict_p23d.has("collected_special_items"):
		data_dict_p23d["collected_special_items"].erase("nightclub_staff_pass")

	GameState.reset_for_new_game()
	if not SaveSystem.validate(compat_dict_p23d):
		printerr("FAIL 23-D: SaveSystem.validate() failed for compat_dict_p23d!")
		get_tree().quit(1)
		return
	SaveSystem.apply(compat_dict_p23d)
	if GameState.get_flag("passed_nightclub_security", false) or GameState.get_flag("found_staff_pass", false) or GameState.collected_special_items.get("nightclub_staff_pass", false):
		printerr("FAIL 23-D: Compatibility load should restore missing keys to false!")
		get_tree().quit(1)
		return

	print("PASS: Phase 23-D regression, save/load, and M1 progress integration verified.")

