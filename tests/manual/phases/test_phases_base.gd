extends Node

const TEST_VALID_SAVE_SLOT := 1
const TEST_SCRATCH_SAVE_SLOT := 2
const TEST_VALID_SAVE_FILE := "save_01.sav"
const TEST_SCRATCH_SAVE_FILE := "save_02.sav"

var _temp_callable: Callable

# 遞迴列出 root 下所有副檔名為 ext 的檔案（res:// 路徑）
func _m2b_list_files(root: String, ext: String, out: Array) -> void:
	var da := DirAccess.open(root)
	if da == null:
		return
	da.list_dir_begin()
	var fname := da.get_next()
	while fname != "":
		if fname != "." and fname != "..":
			var full := root.path_join(fname)
			if da.current_is_dir():
				_m2b_list_files(full, ext, out)
			elif fname.ends_with(ext):
				out.append(full)
		fname = da.get_next()
	da.list_dir_end()

# M2-C 翻譯 key 格式判斷：全大寫字母 / 數字 / 底線；不允許混入 CJK / 標點。
# 抓「整欄忘了 key 化」——例如 STORY_NOTES.title 還是「AI 善後員」中文字面量、ITEMS_DB.name 殘留中文。
func _m2c_is_translation_key(s: String) -> bool:
	if s.is_empty():
		return false
	for ch in s:
		var c_code := ch.unicode_at(0)
		var is_upper := (c_code >= 65 and c_code <= 90)       # A-Z
		var is_digit := (c_code >= 48 and c_code <= 57)       # 0-9
		var is_under := (c_code == 95)                         # _
		if not (is_upper or is_digit or is_under):
			return false
	return true

# 記錄一筆 CSV 缺漏的 key 參照（去重，保留首次出現的檔案）
func _m2b_check_ref(key: String, file: String, keyset: Dictionary, missing: Dictionary) -> void:
	if key == "":
		return
	if not keyset.has(key) and not missing.has(key):
		missing[key] = file

# 最小 CSV 解析器：支援雙引號包裹欄位、欄內逗號/換行、"" 轉義（ui.csv 的多行劇情欄需要）
func _m2b_parse_csv(path: String) -> Array:
	var fa := FileAccess.open(path, FileAccess.READ)
	if fa == null:
		return []
	var content := fa.get_as_text()
	fa.close()
	# 正規化換行（檔案為 CRLF；.translation 內存 LF），避免欄內 \r 造成比對不符
	content = content.replace("\r\n", "\n").replace("\r", "\n")
	var records: Array = []
	var record: Array = []
	var field := ""
	var in_quotes := false
	var i := 0
	var n := content.length()
	while i < n:
		var c := content[i]
		if in_quotes:
			if c == '"':
				if i + 1 < n and content[i + 1] == '"':
					field += '"'
					i += 1
				else:
					in_quotes = false
			else:
				field += c
		else:
			if c == '"':
				in_quotes = true
			elif c == ',':
				record.append(field)
				field = ""
			elif c == '\n':
				record.append(field)
				records.append(record)
				record = []
				field = ""
			elif c != '\r':
				field += c
		i += 1
	if field != "" or record.size() > 0:
		record.append(field)
		records.append(record)
	return records

func _tr_body(raw_body: String) -> String:
	if raw_body.is_empty():
		return ""
	var parts := raw_body.split("\n\n")
	var out: Array = []
	for p in parts:
		out.append(tr(p))
	return "\n\n".join(out)

# 回傳排序後的佔位型別簽章（如 "ds"），用於三語比對：
# 比多重集而非順序，允許跨語言換序，但能抓出 %s/%d 型別錯置或數量不符。
func _m2e_placeholder_signature(text: String) -> String:
	var specs: Array = []
	var i := 0
	var n := text.length()
	while i < n:
		if text[i] == '%':
			if i + 1 < n and text[i+1] == '%':
				# Literal %%, skip both
				i += 2
				continue
			i += 1
			# Skip formatting flags, width, precision
			while i < n and ((text[i] >= "0" and text[i] <= "9") or text[i] == '.' or text[i] == '-' or text[i] == '+'):
				i += 1
			if i < n and (text[i] == 's' or text[i] == 'd' or text[i] == 'f' or text[i] == 'x' or text[i] == 'o' or text[i] == 'X'):
				specs.append(text[i])
		i += 1
	specs.sort()
	return "".join(specs)

# Phase 28-D：headless 全自動跑完一條 R / P 結局序列直到終站 apartment。
# 各站的 begin_message 頁面在 headless 下已自動翻頁（各 level script 自帶）；本 helper 只補
# 兩個仍需外部驅動的環節——CG（photo_viewer）手動關閉、wan_epilogue 對話手動 confirm——
# 並沿途斷言 can_save_here 全程未曾解鎖（序列站禁存）。
func _drive_ending_sequence_phase28d(main_inst: Node) -> Dictionary:
	var save_ever_unlocked := false
	var frames := 0
	while main_inst.get_current_scene_id() != "apartment" and frames < 600:
		if SaveSystem.can_save_here:
			save_ever_unlocked = true
		if main_inst.game_ui.is_photo_viewer_open():
			main_inst.game_ui.close_photo_viewer()
		if UIMode.get_mode() == UIMode.Mode.DIALOGUE:
			main_inst.game_ui.dialogue_confirm()
		await get_tree().process_frame
		frames += 1
	return {"frames": frames, "save_ever_unlocked": save_ever_unlocked}

# Phase 30-B: 全主線脊椎回歸測試推進核心 helper
# Phase 30-B: 全主線脊椎回歸測試推進核心 helper
func _run_mainline_spine_phase30(ending_variant_phase30: String) -> void:
	print("--- Spine Regression Test: ", ending_variant_phase30, " ---")

	# 1. 重設與初始化
	GameState.reset_for_new_game()

	# 清除現有 meta.cfg 便於乾淨測試
	var config_phase30 := ConfigFile.new()
	var path_phase30 := "user://meta.cfg"
	config_phase30.clear()
	config_phase30.save(path_phase30)

	# 2. 建立 Main 實例並轉場到 apartment
	var main_phase30 = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_phase30)
	await get_tree().process_frame

	main_phase30.transition_to("apartment", "wake_bed")
	await get_tree().process_frame

	# 模擬公寓開場
	var apt_phase30 = main_phase30.world_root.get_children()[-1]
	# 模擬公寓解謎：手套、方塊解密、大門解鎖
	GameState.add_item("fingerless_gloves")
	GameState.add_item("decoder_cube")

	# 手套裝備
	var gloves_instance_id_phase30 := ""
	for item_phase30 in GameState.get_inventory():
		if item_phase30.get("item_id") == "fingerless_gloves":
			gloves_instance_id_phase30 = item_phase30.get("instance_id")
			break
	if not gloves_instance_id_phase30.is_empty():
		GameState.equip(gloves_instance_id_phase30)

	# 插槽解鎖
	GameState.apartment_sonar_revealed = true
	GameState.apartment_slot_unlocked = true
	GameState.add_knowledge(GameState.STORY_NOTES["identity_door_unlock_method"])

	# 模擬與大門互動，轉場到街道
	var door_area_phase30 = apt_phase30.get_node("Interactables/DoorExitArea")
	apt_phase30._on_interactable_entered(door_area_phase30)
	apt_phase30._trigger_interaction()
	await get_tree().process_frame
	await get_tree().process_frame

	if main_phase30.get_current_scene_id() != "apartment_entrance":
		printerr("FAIL Spine [", ending_variant_phase30, "]: failed to travel to apartment_entrance, got: ", main_phase30.get_current_scene_id())
		get_tree().quit(1)
		return

	# 3. 街道：與晚互動接任務
	var street_phase30 = main_phase30.world_root.get_children()[-1]
	# 模擬與晚對話接任務：對話三次以湊足好感度接下任務
	for i_phase30 in range(3):
		main_phase30.game_ui.start_dialogue("wan")
		var first_meet_selector_phase30 = func(node_phase30):
			for choice_phase30 in node_phase30.get("choices", []):
				var lbl_phase30 = choice_phase30.get("label", "")
				if lbl_phase30 == "DLG_WAN_WATCH_CHOICE1" or lbl_phase30 == "DLG_WAN_RETALK_CHOICE1":
					return choice_phase30.get("index", 0)
			return -1
		await _advance_dialogue_to_end_phase30(main_phase30, first_meet_selector_phase30)

	# 驗證任務 alley_backrooms_3f 已啟動
	if QuestManager.get_status("alley_backrooms_3f") != "active":
		printerr("FAIL Spine [", ending_variant_phase30, "]: quest alley_backrooms_3f not started!")
		get_tree().quit(1)
		return

	# 4. 防火梯：取得物品 A 推進任務
	main_phase30.transition_to("apartment_fire_escape", "from_window")
	await get_tree().process_frame
	# 模擬搜索箱子取得 A 物品 (舊式 AI 授權模組)
	QuestManager.advance("alley_backrooms_3f", "checked_alley")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	GameState.add_item("old_ai_authorization_module")
	QuestManager.set_flag("alley_backrooms_3f", "found_old_ai_authorization_module", true)

	# 5. 回到街道：向晚交任務，交回物品以推進
	main_phase30.transition_to("apartment_entrance", "from_apartment")
	await get_tree().process_frame

	# 模擬與晚交還對話
	main_phase30.game_ui.start_dialogue("wan")
	var report_selector_phase30 = func(node_phase30):
		var choices_phase30 = node_phase30.get("choices", [])
		for i_choice_phase30 in range(choices_phase30.size()):
			var lbl_phase30 = tr(choices_phase30[i_choice_phase30].get("label", ""))
			if "還" in lbl_phase30 or "交" in lbl_phase30:
				return i_choice_phase30
		return -1
	await _advance_dialogue_to_end_phase30(main_phase30, report_selector_phase30)

	# 6. 地鐵與聚落推進，準備回執相關分岔
	main_phase30.transition_to("subway_station", "from_street")
	await get_tree().process_frame
	main_phase30.transition_to("underground_settlement", "from_subway")
	await get_tree().process_frame

	# 模擬戰鬥與取得回執
	main_phase30.transition_to("tunnel_combat", "from_settlement")
	await get_tree().process_frame
	GameState.set_flag("tunnel_combat_won", true)
	# 取得回執
	GameState.add_item("childcare_supply_receipt")

	# 再次回到地鐵月台與晚對話，決定賣回執以鎖死和平線，或交回給七號以解鎖和平分支
	main_phase30.transition_to("subway_station", "from_street")
	await get_tree().process_frame

	if ending_variant_phase30 == "protect_b":
		# 選擇賣掉回執鎖死和平線
		main_phase30.game_ui.start_dialogue("wan")
		var sell_selector_phase30 = func(node_phase30):
			var choices_phase30 = node_phase30.get("choices", [])
			for i_choice_phase30 in range(choices_phase30.size()):
				var lbl_phase30 = tr(choices_phase30[i_choice_phase30].get("label", ""))
				if "賣" in lbl_phase30 or "credits" in lbl_phase30:
					return i_choice_phase30
			return -1
		await _advance_dialogue_to_end_phase30(main_phase30, sell_selector_phase30)
		# 這會設定 peace_line_locked = true
	else:
		# 和平線：交還給七號
		main_phase30.transition_to("underground_settlement", "from_subway")
		await get_tree().process_frame

		# 模擬與七號對話交付回執
		main_phase30.game_ui.start_dialogue("seven")
		var seven_selector_phase30 = func(node_phase30):
			var node_id_phase30 = node_phase30.get("node_id", "")
			if node_id_phase30 in ["receipt_probe", "receipt_probe_s2", "receipt_probe_s3"]:
				return 2
			var choices_phase30 = node_phase30.get("choices", [])
			for i_choice_phase30 in range(choices_phase30.size()):
				var lbl_phase30 = tr(choices_phase30[i_choice_phase30].get("label", ""))
				if "回執" in lbl_phase30 or "收據" in lbl_phase30:
					return i_choice_phase30
			return -1
		await _advance_dialogue_to_end_phase30(main_phase30, seven_selector_phase30)
		# 這會設定 seven_peace_branch_d = true 且 peace_line_locked = false

	# 7. 深隧道追逐與岑的暴露
	if ending_variant_phase30 == "protect_b":
		GameState.set_flag("cen_voiceprint_exposed", true)
	else:
		GameState.set_flag("cen_voiceprint_exposed", false)

	# 8. 殘響採集與 Trace 湊分岔
	if ending_variant_phase30 == "expose_c":
		# 採集三個殘響，使 trace >= 3
		for echo_key_phase30 in ["echo_clerk", "echo_song_rain_doesnt_stop", "echo_lu_family"]:
			var echo_data_phase30 = EchoDB.get_echo(echo_key_phase30)
			for seg_phase30 in echo_data_phase30.get("segments", []):
				GameState.collect_echo_segment(echo_key_phase30, seg_phase30.get("id", ""))
		# 強制設定 trace 以確保 >= 3
		GameState.add_trace(3)
	else:
		# Expose A / B，trace 保持 < 3
		# 採集一個殘響，以證明 trace 邏輯被正確跑過
		var echo_data_phase30 = EchoDB.get_echo("echo_clerk")
		for seg_phase30 in echo_data_phase30.get("segments", []):
			GameState.collect_echo_segment("echo_clerk", seg_phase30.get("id", ""))

	# 設定晚的好感度
	if ending_variant_phase30 == "reclaim":
		GameState.set_flag("affinity_wan", 2) # warm ending
	else:
		GameState.set_flag("affinity_wan", 1)

	# 9. 前往夜總會與資料中心 core
	main_phase30.transition_to("nightclub_entrance", "from_street")
	await get_tree().process_frame
	main_phase30.transition_to("nightclub", "from_entrance")
	await get_tree().process_frame
	main_phase30.transition_to("nightclub_back", "from_lobby")
	await get_tree().process_frame

	# 進入資料中心
	main_phase30.transition_to("datacenter_entrance", "from_nightclub")
	await get_tree().process_frame
	main_phase30.transition_to("datacenter_backup", "from_entrance")
	await get_tree().process_frame
	main_phase30.transition_to("datacenter_backup_core", "from_backup")
	await get_tree().process_frame

	# 10. 在 core 觸發 endings 結局路由
	# 30-C: 最後可存點留檔 -> 讀回 -> 繼續走完結局 (Reclaim / Protect)
	if not SaveSystem.can_save_here:
		printerr("FAIL 30-C Spine [", ending_variant_phase30, "]: SaveSystem.can_save_here should be true before own_backup!")
		get_tree().quit(1)
		return

	var save_data_own_backup_phase30 = SaveSystem.capture(main_phase30.get_current_scene_id(), 100.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_data_own_backup_phase30):
		printerr("FAIL 30-C Spine [", ending_variant_phase30, "]: failed to write pre-choice save slot!")
		get_tree().quit(1)
		return

	main_phase30.free()
	await get_tree().process_frame
	GameState.reset_for_new_game()

	main_phase30 = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_phase30)
	await get_tree().process_frame

	if not main_phase30.load_game_slot(TEST_SCRATCH_SAVE_SLOT):
		printerr("FAIL 30-C Spine [", ending_variant_phase30, "]: load_game_slot failed in own_backup round-trip!")
		get_tree().quit(1)
		return
	await get_tree().process_frame
	await get_tree().process_frame

	# 模擬觸發 own_backup 結局路由對話
	main_phase30.game_ui.start_dialogue("own_backup")
	var core_selector_phase30 = func(node_phase30):
		var search_text_phase30 = ""
		if ending_variant_phase30 == "reclaim":
			search_text_phase30 = "灌"
		elif ending_variant_phase30.begins_with("protect"):
			search_text_phase30 = "刪"
		else:
			search_text_phase30 = "拷"

		var choices_phase30 = node_phase30.get("choices", [])
		for i_choice_phase30 in range(choices_phase30.size()):
			var lbl_phase30 = tr(choices_phase30[i_choice_phase30].get("label", ""))
			if search_text_phase30 in lbl_phase30:
				return i_choice_phase30
		for i_choice_phase30 in range(choices_phase30.size()):
			var lbl_phase30 = tr(choices_phase30[i_choice_phase30].get("label", ""))
			if "就" in lbl_phase30 or "做" in lbl_phase30 or "確" in lbl_phase30 or "Lock" in lbl_phase30:
				return i_choice_phase30
		return -1
	await _advance_dialogue_to_end_phase30(main_phase30, core_selector_phase30)

	# 11. 驅動結局演出推進
	if ending_variant_phase30.begins_with("expose"):
		# Expose 進入廣播站，觸發清洗閘
		if main_phase30.get_current_scene_id() != "broadcast_station":
			printerr("FAIL Spine [", ending_variant_phase30, "]: failed to travel to broadcast_station, got: ", main_phase30.get_current_scene_id())
			get_tree().quit(1)
			return

		# 30-C: 最後可存點留檔 -> 讀回 -> 繼續走完結局 (Expose)
		if not SaveSystem.can_save_here:
			printerr("FAIL 30-C Spine [", ending_variant_phase30, "]: SaveSystem.can_save_here should be true before broadcast_upload!")
			get_tree().quit(1)
			return

		var save_data_broadcast_phase30 = SaveSystem.capture(main_phase30.get_current_scene_id(), 100.0, 1)
		if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_data_broadcast_phase30):
			printerr("FAIL 30-C Spine [", ending_variant_phase30, "]: failed to write broadcast pre-choice save slot!")
			get_tree().quit(1)
			return

		main_phase30.free()
		await get_tree().process_frame
		GameState.reset_for_new_game()

		main_phase30 = load("res://scenes/main/main.tscn").instantiate()
		add_child(main_phase30)
		await get_tree().process_frame

		if not main_phase30.load_game_slot(TEST_SCRATCH_SAVE_SLOT):
			printerr("FAIL 30-C Spine [", ending_variant_phase30, "]: load_game_slot failed in broadcast_upload round-trip!")
			get_tree().quit(1)
			return
		await get_tree().process_frame
		await get_tree().process_frame

		# 觸發廣播站對話 (清洗或保留)
		main_phase30.game_ui.start_dialogue("broadcast_upload")
		var broadcast_selector_phase30 = func(node_phase30):
			var target_word_phase30 = "清" if ending_variant_phase30 == "expose_b" else "原"
			var choices_phase30 = node_phase30.get("choices", [])
			for i_choice_phase30 in range(choices_phase30.size()):
				var lbl_phase30 = tr(choices_phase30[i_choice_phase30].get("label", ""))
				if target_word_phase30 in lbl_phase30 or ("洗" in lbl_phase30 and target_word_phase30 == "清") or ("留" in lbl_phase30 and target_word_phase30 == "原"):
					return i_choice_phase30
			return -1
		await _advance_dialogue_to_end_phase30(main_phase30, broadcast_selector_phase30)

		# 寫入 expose_upload_done 觸發 Expose 結局
		GameState.set_flag("expose_upload_done", true)
		await get_tree().process_frame
		await get_tree().process_frame

	# 結局自動前進
	# 驅動 epilogue 直到回到標題畫面
	var frames_phase30 := 0
	var max_frames_phase30 := 1000
	while main_phase30.get_current_scene_id() != "title_screen" and frames_phase30 < max_frames_phase30:
		if SaveSystem.can_save_here:
			printerr("FAIL Spine [", ending_variant_phase30, "]: SaveSystem should be locked during ending sequences!")
			get_tree().quit(1)
			return
		if main_phase30.game_ui.is_photo_viewer_open():
			main_phase30.game_ui.close_photo_viewer()
		if UIMode.get_mode() == UIMode.Mode.DIALOGUE:
			main_phase30.game_ui.dialogue_confirm()

		var ep_phase30 = main_phase30.game_ui.ending_epilogue

		if ep_phase30.visible:
			# 整合測試下，直接呼叫內部的 _advance_page() 推進 epilogue 拍數
			if frames_phase30 % 10 == 0:
				ep_phase30._advance_page()
		await get_tree().process_frame
		frames_phase30 += 1

	# 斷言回到標題畫面
	if main_phase30.get_current_scene_id() != "title_screen":
		printerr("FAIL Spine [", ending_variant_phase30, "]: failed to return to title screen after ", frames_phase30, " frames!")
		get_tree().quit(1)
		return

	# 12. 斷言 endings played 旗標、meta.cfg、Notebook summary endings 欄位
	var expected_played_flag_phase30 := ""
	var expected_meta_key_phase30 := ""
	match ending_variant_phase30:
		"reclaim":
			expected_played_flag_phase30 = "ending_reclaim_played"
			expected_meta_key_phase30 = "reclaim"
		"protect_not_b", "protect_b":
			expected_played_flag_phase30 = "ending_protect_played"
			expected_meta_key_phase30 = "protect"
		"expose_a":
			expected_played_flag_phase30 = "ending_expose_a_played"
			expected_meta_key_phase30 = "expose_a"
		"expose_b":
			expected_played_flag_phase30 = "ending_expose_b_played"
			expected_meta_key_phase30 = "expose_b"
		"expose_c":
			expected_played_flag_phase30 = "ending_expose_c_played"
			expected_meta_key_phase30 = "expose_c"

	if not GameState.get_flag(expected_played_flag_phase30, false):
		printerr("FAIL Spine [", ending_variant_phase30, "]: expected played flag ", expected_played_flag_phase30, " not set!")
		get_tree().quit(1)
		return

	var achieved_phase30 = GameState.get_achieved_endings()
	if not achieved_phase30.has(expected_meta_key_phase30):
		printerr("FAIL Spine [", ending_variant_phase30, "]: expected meta key ", expected_meta_key_phase30, " not in achieved list: ", achieved_phase30)
		get_tree().quit(1)
		return

	var summary_phase30 = GameState.get_progress_summary()
	if summary_phase30["endings"]["done"] != 1:
		printerr("FAIL Spine [", ending_variant_phase30, "]: expected endings.done == 1, got: ", summary_phase30["endings"])
		get_tree().quit(1)
		return

	print("PASS Spine [", ending_variant_phase30, "]: successfully driven end-to-end and verified in meta!")

	if is_instance_valid(main_phase30):
		main_phase30.free()
	await get_tree().process_frame
	GameState.reset_for_new_game()

# 安全推進當前對話直到結束的 helper
func _advance_dialogue_to_end_phase30(main_phase30: Node, choice_selector_phase30: Callable = Callable()) -> void:
	await get_tree().process_frame
	while main_phase30.game_ui.has_active_dialogue():
		var dp_phase30 = main_phase30.game_ui.dialogue_panel
		var runner_phase30 = dp_phase30._runner
		if runner_phase30:
			var curr_node_phase30 = runner_phase30.current()
			if not curr_node_phase30.get("choices", []).is_empty():
				var choice_idx_phase30 = 0
				if choice_selector_phase30.is_valid():
					var selected_idx_phase30 = choice_selector_phase30.call(curr_node_phase30)
					if selected_idx_phase30 != -1:
						choice_idx_phase30 = selected_idx_phase30
				runner_phase30.choose(choice_idx_phase30)
			else:
				runner_phase30.advance()
		await get_tree().process_frame
