extends "res://tests/manual/phases/test_phases_base.gd"

func _run_phase_30c() -> void:
	# ===================== Phase 30-C: 三結局存讀檔矩陣與 i18n 驗證 =====================
	print("--- Phase 30-C: 三結局存讀檔矩陣與 i18n 驗證 ---")

	# 1. 驗證 10 種結局與和平線組合的文字選中與 epilogue 元件正確渲染
	var ending_variants_30c = ["reclaim", "protect", "expose_a", "expose_b", "expose_c"]
	var peace_variants_30c = [false, true]
	for ev_30c in ending_variants_30c:
		for pv_30c in peace_variants_30c:
			GameState.reset_for_new_game()
			# 設定 played 旗標
			GameState.set_flag("ending_%s_played" % ev_30c, true)
			GameState.set_flag("seven_peace_branch_d", pv_30c)

			var ep_inst_30c = load("res://scenes/ui/ending_epilogue.tscn").instantiate()
			add_child(ep_inst_30c)
			ep_inst_30c.start_epilogue()
			ep_inst_30c._start_beat_1()

			# 斷言 _ending_id 與 _is_peace
			if ep_inst_30c._ending_id != ev_30c:
				printerr("FAIL 30-C: expected epilogue _ending_id: ", ev_30c, ", got: ", ep_inst_30c._ending_id)
				get_tree().quit(1)
				return
			if ep_inst_30c._is_peace != pv_30c:
				printerr("FAIL 30-C: expected epilogue _is_peace: ", pv_30c, ", got: ", ep_inst_30c._is_peace)
				get_tree().quit(1)
				return

			# 拍 1: MSG_ENDING_SHARED_P1
			if ep_inst_30c._full_text != tr("MSG_ENDING_SHARED_P1"):
				printerr("FAIL 30-C: page 1 shared P1 mismatch for variant ", ev_30c, " peace ", pv_30c)
				get_tree().quit(1)
				return

			# 推進到 P2
			ep_inst_30c._advance_page()
			if ep_inst_30c._full_text != tr("MSG_ENDING_SHARED_P2"):
				printerr("FAIL 30-C: page 1 shared P2 mismatch")
				get_tree().quit(1)
				return

			# 推進到 拍 2
			ep_inst_30c._advance_page()
			var expected_key_30c = "MSG_ENDING_ORANGE_%s" % ev_30c.to_upper()
			if pv_30c:
				expected_key_30c += "_PEACE"
			if ep_inst_30c._full_text != tr(expected_key_30c):
				printerr("FAIL 30-C: page 2 orange mismatch, expected key: ", expected_key_30c, ", got text: ", ep_inst_30c._full_text)
				get_tree().quit(1)
				return

			# 推進到 拍 3
			ep_inst_30c._advance_page()
			if ep_inst_30c._full_text != tr("MSG_ENDING_FINAL_LINE"):
				printerr("FAIL 30-C: page 3 final line mismatch")
				get_tree().quit(1)
				return

			ep_inst_30c.free()
	print("PASS 30-C: 10 ending-epilogue text combinations verified successfully.")

	# 2. 驗證 meta 結局記錄隔離與 reset 不清
	GameState.reset_for_new_game()

	# 清除現有 meta.cfg 便於測試
	var conf_30c := ConfigFile.new()
	conf_30c.clear()
	conf_30c.save("user://meta.cfg")

	# 寫入結局成就
	GameState.mark_ending_achieved("expose_c")

	# 抓取 SaveSystem state dict
	var save_dict_30c = SaveSystem.capture("apartment", 100.0, 1)
	if save_dict_30c.has("endings") or save_dict_30c.get("data", {}).has("endings"):
		printerr("FAIL 30-C: SaveSystem state dict should NOT contain endings meta, got data keys: ", save_dict_30c.get("data", {}).keys())
		get_tree().quit(1)
		return

	# 測試 reset_for_new_game 不清 meta
	GameState.reset_for_new_game()
	var achieved_after_reset_30c = GameState.get_achieved_endings()
	if not achieved_after_reset_30c.has("expose_c"):
		printerr("FAIL 30-C: meta endings should survive reset_for_new_game, got: ", achieved_after_reset_30c)
		get_tree().quit(1)
		return

	# 清理 meta 避免影響後續
	conf_30c.clear()
	conf_30c.save("user://meta.cfg")
	print("PASS 30-C: meta endings isolation and reset behavior verified.")

	# 3. 重驗 28 孤兒檔救援並直通 30-A (Reclaim)
	GameState.reset_for_new_game()
	GameState.set_flag("ending_route_reclaim", true)
	GameState.set_flag("ending_reclaim_played", false)
	# 模擬在 convenience_store 存檔
	var orphan_save_28_30c = SaveSystem.capture("convenience_store", 200.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, orphan_save_28_30c):
		printerr("FAIL 30-C: write_slot failed for 28 orphan save!")
		get_tree().quit(1)
		return

	var main_orphan_28_30c = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_orphan_28_30c)
	await get_tree().process_frame

	if not main_orphan_28_30c.load_game_slot(TEST_SCRATCH_SAVE_SLOT):
		printerr("FAIL 30-C: load_game_slot failed for 28 orphan save!")
		get_tree().quit(1)
		return
	await get_tree().process_frame
	await get_tree().process_frame

	# 斷言已被救援回 datacenter_backup_core 並且自動前進
	if main_orphan_28_30c.get_current_scene_id() != "datacenter_backup_core":
		printerr("FAIL 30-C: 28 orphan save should load back into datacenter_backup_core, got: ", main_orphan_28_30c.get_current_scene_id())
		get_tree().quit(1)
		return

	# 驅動它直通結局到標題
	var frames_orphan_28 := 0
	while main_orphan_28_30c.get_current_scene_id() != "title_screen" and frames_orphan_28 < 1000:
		if main_orphan_28_30c.game_ui.is_photo_viewer_open():
			main_orphan_28_30c.game_ui.close_photo_viewer()
		if UIMode.get_mode() == UIMode.Mode.DIALOGUE:
			main_orphan_28_30c.game_ui.dialogue_confirm()

		var ep_node_28 = main_orphan_28_30c.game_ui.ending_epilogue
		if ep_node_28.visible:
			if frames_orphan_28 % 10 == 0:
				ep_node_28._advance_page()
		await get_tree().process_frame
		frames_orphan_28 += 1

	if main_orphan_28_30c.get_current_scene_id() != "title_screen":
		printerr("FAIL 30-C: 28 orphan save did not drive end-to-end to title screen!")
		get_tree().quit(1)
		return

	if not GameState.get_flag("ending_reclaim_played", false):
		printerr("FAIL 30-C: 28 orphan rescue did not set ending_reclaim_played!")
		get_tree().quit(1)
		return

	main_orphan_28_30c.free()
	await get_tree().process_frame
	print("PASS 30-C: 28 orphan save rescue end-to-end verified.")

	# 4. 重驗 29 孤兒檔救援並直通 30-A (Expose A)
	GameState.reset_for_new_game()
	GameState.set_flag("expose_upload_done", true)
	GameState.set_flag("ending_expose_a_played", false)
	GameState.set_flag("ending_expose_b_played", false)
	GameState.set_flag("ending_expose_c_played", false)
	# 為了決定 Expose A：expose_upload_cleaned = false 且 trace < 3
	GameState.set_flag("expose_upload_cleaned", false)
	# 模擬在 convenience_store 存檔
	var orphan_save_29_30c = SaveSystem.capture("convenience_store", 200.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, orphan_save_29_30c):
		printerr("FAIL 30-C: write_slot failed for 29 orphan save!")
		get_tree().quit(1)
		return

	var main_orphan_29_30c = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_orphan_29_30c)
	await get_tree().process_frame

	if not main_orphan_29_30c.load_game_slot(TEST_SCRATCH_SAVE_SLOT):
		printerr("FAIL 30-C: load_game_slot failed for 29 orphan save!")
		get_tree().quit(1)
		return
	await get_tree().process_frame
	await get_tree().process_frame

	# 斷言已被救援回 broadcast_station
	if main_orphan_29_30c.get_current_scene_id() != "broadcast_station":
		printerr("FAIL 30-C: 29 orphan save should load back into broadcast_station, got: ", main_orphan_29_30c.get_current_scene_id())
		get_tree().quit(1)
		return

	# 驅動它直通結局到標題
	var frames_orphan_29 := 0
	while main_orphan_29_30c.get_current_scene_id() != "title_screen" and frames_orphan_29 < 1000:
		if main_orphan_29_30c.game_ui.is_photo_viewer_open():
			main_orphan_29_30c.game_ui.close_photo_viewer()
		if UIMode.get_mode() == UIMode.Mode.DIALOGUE:
			main_orphan_29_30c.game_ui.dialogue_confirm()

		var ep_node_29 = main_orphan_29_30c.game_ui.ending_epilogue
		if ep_node_29.visible:
			if frames_orphan_29 % 10 == 0:
				ep_node_29._advance_page()
		await get_tree().process_frame
		frames_orphan_29 += 1

	if main_orphan_29_30c.get_current_scene_id() != "title_screen":
		printerr("FAIL 30-C: 29 orphan save did not drive end-to-end to title screen!")
		get_tree().quit(1)
		return

	if not GameState.get_flag("ending_expose_a_played", false):
		printerr("FAIL 30-C: 29 orphan rescue did not set ending_expose_a_played!")
		get_tree().quit(1)
		return

	main_orphan_29_30c.free()
	await get_tree().process_frame
	print("PASS 30-C: 29 orphan save rescue end-to-end verified.")

	# 5. 驗證新 key 三語 CSV lint
	var keys_to_check_30c = [
		"MSG_ENDING_SHARED_P1", "MSG_ENDING_SHARED_P2", "MSG_ENDING_FINAL_LINE",
		"MSG_ENDING_ORANGE_RECLAIM", "MSG_ENDING_ORANGE_PROTECT",
		"MSG_ENDING_ORANGE_EXPOSE_A", "MSG_ENDING_ORANGE_EXPOSE_B", "MSG_ENDING_ORANGE_EXPOSE_C",
		"MSG_ENDING_ORANGE_RECLAIM_PEACE", "MSG_ENDING_ORANGE_PROTECT_PEACE",
		"MSG_ENDING_ORANGE_EXPOSE_A_PEACE", "MSG_ENDING_ORANGE_EXPOSE_B_PEACE", "MSG_ENDING_ORANGE_EXPOSE_C_PEACE"
	]

	for target_lang_30c in ["zh_TW", "zh_CN", "en"]:
		LocaleManager.set_locale(target_lang_30c)
		for key_30c in keys_to_check_30c:
			var translated_val_30c = tr(key_30c)
			if translated_val_30c == key_30c or translated_val_30c.is_empty():
				printerr("FAIL 30-C i18n: key ", key_30c, " is missing or empty in locale: ", target_lang_30c)
				get_tree().quit(1)
				return
	# 還原語系
	LocaleManager.set_locale("zh_TW")
	print("PASS 30-C: New ending keys' i18n coverage verified across all 3 locales.")
