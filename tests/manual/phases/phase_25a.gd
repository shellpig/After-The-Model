extends "res://tests/manual/phases/phase_25b.gd"

func _run_phase_25a() -> void:
	# ===================== Phase 25-A: Act 4 備份區三場景骨架 =====================
	print("--- Phase 25-A: Act 4 備份區三場景骨架 ---")

	# 1. 驗證 SceneRegistry
	var datacenter_main_scene_phase25 = load("res://scenes/main/main.tscn")
	var main_instance_phase25 = datacenter_main_scene_phase25.instantiate()
	add_child(main_instance_phase25)
	await get_tree().process_frame

	var scenes_phase25 = main_instance_phase25.SCENES
	if not "datacenter_entrance" in scenes_phase25 or not "datacenter_backup" in scenes_phase25 or not "datacenter_backup_core" in scenes_phase25:
		printerr("FAIL 25-A: SceneRegistry missing datacenter scenes!")
		get_tree().quit(1)
		return

	if not "from_datacenter" in scenes_phase25["nightclub_entrance"].get("entry_points", []):
		printerr("FAIL 25-A: nightclub_entrance entry points missing from_datacenter!")
		get_tree().quit(1)
		return

	if SaveSystem.get_scene_display_name("datacenter_entrance") == "未知區域" or SaveSystem.get_scene_display_name("datacenter_backup_core") == "未知區域":
		printerr("FAIL 25-A: SaveSystem SCENE_NAMES missing datacenter scenes!")
		get_tree().quit(1)
		return

	# 2. 驗證 travel_datacenter 對話樹 gate（passed_nightclub_security AND (D OR A OR B)）
	DialogueDB = load("res://data/dialogue/dialogue_db.gd")
	var travel_tree_phase25 = DialogueDB.get_tree_for("travel_datacenter")

	# 2a. 全無旗標：鎖住
	GameState.reset_for_new_game()
	var runner_locked_phase25 = DialogueRunner.new()
	runner_locked_phase25.start(travel_tree_phase25)
	if runner_locked_phase25.current().get("text", "") != "DLG_TRAVEL_DATACENTER_LOCKED_TEXT":
		printerr("FAIL 25-A: travel_datacenter should be locked with no flags set!")
		get_tree().quit(1)
		return

	# 2b. 只過夜總會安檢、無終端旗標：仍鎖住
	GameState.set_flag("passed_nightclub_security", true)
	var runner_no_ending_phase25 = DialogueRunner.new()
	runner_no_ending_phase25.start(travel_tree_phase25)
	if runner_no_ending_phase25.current().get("text", "") != "DLG_TRAVEL_DATACENTER_LOCKED_TEXT":
		printerr("FAIL 25-A: travel_datacenter should stay locked without a Seven ending flag!")
		get_tree().quit(1)
		return

	# 2c. D 分支解鎖 + 晚 flavor + travel effect
	GameState.set_flag("seven_peace_branch_d", true)
	var runner_d_phase25 = DialogueRunner.new()
	runner_d_phase25.start(travel_tree_phase25)
	if runner_d_phase25.current().get("text", "") != "DLG_TRAVEL_DATACENTER_MENU_TEXT":
		printerr("FAIL 25-A: travel_datacenter should unlock the menu when seven_peace_branch_d is true!")
		get_tree().quit(1)
		return
	runner_d_phase25.choose(0)
	if runner_d_phase25.current().get("speaker", "") != "SPEAKER_WAN":
		printerr("FAIL 25-A: choosing to travel should show the Wan flavor beat first!")
		get_tree().quit(1)
		return
	runner_d_phase25.advance()
	if runner_d_phase25.pending_travel.get("scene_id", "") != "datacenter_entrance" or runner_d_phase25.pending_travel.get("entry_point_id", "") != "from_nightclub":
		printerr("FAIL 25-A: travel_datacenter payload incorrect: ", runner_d_phase25.pending_travel)
		get_tree().quit(1)
		return

	# 2d. A 分支（seven_stopped_full）獨立解鎖
	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)
	GameState.set_flag("seven_stopped_full", true)
	var runner_a_phase25 = DialogueRunner.new()
	runner_a_phase25.start(travel_tree_phase25)
	if runner_a_phase25.current().get("text", "") != "DLG_TRAVEL_DATACENTER_MENU_TEXT":
		printerr("FAIL 25-A: travel_datacenter should unlock when seven_stopped_full is true!")
		get_tree().quit(1)
		return

	# 2e. B 分支（seven_stopped_partial）獨立解鎖
	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)
	GameState.set_flag("seven_stopped_partial", true)
	var runner_b_phase25 = DialogueRunner.new()
	runner_b_phase25.start(travel_tree_phase25)
	if runner_b_phase25.current().get("text", "") != "DLG_TRAVEL_DATACENTER_MENU_TEXT":
		printerr("FAIL 25-A: travel_datacenter should unlock when seven_stopped_partial is true!")
		get_tree().quit(1)
		return

	# 2f. 取消分支不觸發 travel
	var runner_cancel_phase25 = DialogueRunner.new()
	runner_cancel_phase25.start(travel_tree_phase25)
	runner_cancel_phase25.choose(1)
	if runner_cancel_phase25.current().get("text", "") != "DLG_TRAVEL_DATACENTER_END_TEXT" or not runner_cancel_phase25.pending_travel.is_empty():
		printerr("FAIL 25-A: Cancelling travel_datacenter should not set pending_travel!")
		get_tree().quit(1)
		return

	# 3. 驗證三場景載入、相機邊界、spawn points
	var datacenter_specs_phase25 := {
		"datacenter_entrance": {
			"path": "res://scenes/levels/datacenter_entrance/datacenter_entrance.tscn",
			"limit_right": 1376,
			"spawns": ["from_nightclub", "from_backup"]
		},
		"datacenter_backup": {
			"path": "res://scenes/levels/datacenter_backup/datacenter_backup.tscn",
			"limit_right": 4768,
			"spawns": ["from_entrance", "from_core"]
		},
		"datacenter_backup_core": {
			"path": "res://scenes/levels/datacenter_backup_core/datacenter_backup_core.tscn",
			"limit_right": 4768,
			"spawns": ["from_backup"]
		}
	}

	for scene_id_phase25 in datacenter_specs_phase25:
		var spec_phase25 = datacenter_specs_phase25[scene_id_phase25]
		var packed_phase25 = load(spec_phase25["path"])
		if not packed_phase25:
			printerr("FAIL 25-A: Could not load scene ", spec_phase25["path"])
			get_tree().quit(1)
			return

		var inst_phase25 = packed_phase25.instantiate()
		add_child(inst_phase25)
		await get_tree().process_frame

		var camera_phase25 = inst_phase25.get_node("Camera2D")
		if not camera_phase25 or camera_phase25.limit_right != spec_phase25["limit_right"]:
			printerr("FAIL 25-A: Camera limit_right incorrect for ", scene_id_phase25)
			get_tree().quit(1)
			return

		for spawn_phase25 in spec_phase25["spawns"]:
			if not inst_phase25.has_node("SpawnPoints/" + spawn_phase25):
				printerr("FAIL 25-A: Missing spawn point ", spawn_phase25, " in ", scene_id_phase25)
				get_tree().quit(1)
				return

		inst_phase25.free()

	# 4. 驗證善後員門禁 gate：缺 read_old_work_order 擋、齊全放行
	GameState.reset_for_new_game()
	var inst_entrance_phase25 = load("res://scenes/levels/datacenter_entrance/datacenter_entrance.tscn").instantiate()
	var gate_node_phase25 = inst_entrance_phase25.get_node("Interactables/MainGateArea")
	inst_entrance_phase25.current_interactable = gate_node_phase25

	var captured_denied_phase25: Dictionary = {}
	inst_entrance_phase25.interaction_requested.connect(func(data):
		captured_denied_phase25.merge(data, true)
	)
	var captured_trans_denied_phase25: Dictionary = {}
	inst_entrance_phase25.scene_transition_requested.connect(func(scene_id, entry_point_id, payload):
		captured_trans_denied_phase25.merge({"scene": scene_id, "entry": entry_point_id}, true)
	)
	inst_entrance_phase25._trigger_interaction()

	if captured_denied_phase25.get("message_text", "") != GameState.STORY_MESSAGES["datacenter_access_denied"]:
		printerr("FAIL 25-A: main_gate should show access-denied message without badge/read_old_work_order!")
		get_tree().quit(1)
		return
	if not captured_trans_denied_phase25.is_empty():
		printerr("FAIL 25-A: main_gate should not transition when access is denied!")
		get_tree().quit(1)
		return

	# 給齊兩條件（皆既有）：old_work_badge 正常玩流是公寓開場既有 key item（apartment_room.gd 首次鋪世界時發放），
	# 此處直接補發模擬該既有前置狀態；read_old_work_order 為 19-B 揭露旗標。
	GameState.add_item("old_work_badge", 1)
	GameState.set_flag("read_old_work_order", true)

	inst_entrance_phase25._trigger_interaction()
	if captured_trans_denied_phase25.get("scene", "") != "datacenter_backup" or captured_trans_denied_phase25.get("entry", "") != "from_entrance":
		printerr("FAIL 25-A: main_gate should transition to datacenter_backup once badge + read_old_work_order are satisfied!")
		get_tree().quit(1)
		return

	# 5. 驗證入口其餘互動（flavor examine + 回夜總會）
	var delivery_bot_node_phase25 = inst_entrance_phase25.get_node("Interactables/DeliveryBotArea")
	inst_entrance_phase25.current_interactable = delivery_bot_node_phase25
	var captured_flavor_phase25: Dictionary = {}
	for conn_phase25 in inst_entrance_phase25.interaction_requested.get_connections():
		inst_entrance_phase25.interaction_requested.disconnect(conn_phase25.callable)
	inst_entrance_phase25.interaction_requested.connect(func(data):
		captured_flavor_phase25.merge(data, true)
	)
	inst_entrance_phase25._trigger_interaction()
	if captured_flavor_phase25.get("message_text", "") != GameState.STORY_MESSAGES["datacenter_delivery_bot_flavor"]:
		printerr("FAIL 25-A: delivery_bot flavor examine text mismatch!")
		get_tree().quit(1)
		return

	var exit_nightclub_node_phase25 = inst_entrance_phase25.get_node("Interactables/ExitToNightclubArea")
	inst_entrance_phase25.current_interactable = exit_nightclub_node_phase25
	captured_trans_denied_phase25.clear()
	inst_entrance_phase25._trigger_interaction()
	if captured_trans_denied_phase25.get("scene", "") != "nightclub_entrance" or captured_trans_denied_phase25.get("entry", "") != "from_datacenter":
		printerr("FAIL 25-A: entrance exit should return to nightclub_entrance:from_datacenter!")
		get_tree().quit(1)
		return

	inst_entrance_phase25.free()

	# 6. 驗證 backup <-> core 雙向轉場 + core 中性佔位 examine
	var inst_backup_phase25 = load("res://scenes/levels/datacenter_backup/datacenter_backup.tscn").instantiate()
	var exit_to_entrance_node_phase25 = inst_backup_phase25.get_node("Interactables/ExitToEntranceArea")
	var exit_to_core_node_phase25 = inst_backup_phase25.get_node("Interactables/ExitToCoreArea")
	var captured_backup_trans_phase25: Dictionary = {}
	inst_backup_phase25.scene_transition_requested.connect(func(scene_id, entry_point_id, payload):
		captured_backup_trans_phase25.merge({"scene": scene_id, "entry": entry_point_id}, true)
	)

	inst_backup_phase25.current_interactable = exit_to_entrance_node_phase25
	inst_backup_phase25._trigger_interaction()
	if captured_backup_trans_phase25.get("scene", "") != "datacenter_entrance" or captured_backup_trans_phase25.get("entry", "") != "from_backup":
		printerr("FAIL 25-A: datacenter_backup left exit should return to datacenter_entrance:from_backup!")
		get_tree().quit(1)
		return

	captured_backup_trans_phase25.clear()
	inst_backup_phase25.current_interactable = exit_to_core_node_phase25
	inst_backup_phase25._trigger_interaction()
	if captured_backup_trans_phase25.get("scene", "") != "datacenter_backup_core" or captured_backup_trans_phase25.get("entry", "") != "from_backup":
		printerr("FAIL 25-A: datacenter_backup right door should transition to datacenter_backup_core:from_backup!")
		get_tree().quit(1)
		return

	inst_backup_phase25.free()

	var inst_core_phase25 = load("res://scenes/levels/datacenter_backup_core/datacenter_backup_core.tscn").instantiate()
	var exit_to_backup_node_phase25 = inst_core_phase25.get_node("Interactables/ExitToBackupArea")
	var own_backup_node_phase25 = inst_core_phase25.get_node("Interactables/OwnBackupArea")
	var captured_core_trans_phase25: Dictionary = {}
	inst_core_phase25.scene_transition_requested.connect(func(scene_id, entry_point_id, payload):
		captured_core_trans_phase25.merge({"scene": scene_id, "entry": entry_point_id}, true)
	)

	inst_core_phase25.current_interactable = exit_to_backup_node_phase25
	inst_core_phase25._trigger_interaction()
	if captured_core_trans_phase25.get("scene", "") != "datacenter_backup" or captured_core_trans_phase25.get("entry", "") != "from_core":
		printerr("FAIL 25-A: datacenter_backup_core exit should return to datacenter_backup:from_core!")
		get_tree().quit(1)
		return

	var captured_own_backup_phase25: Dictionary = {}
	inst_core_phase25.interaction_requested.connect(func(data):
		captured_own_backup_phase25.merge(data, true)
	)
	inst_core_phase25.current_interactable = own_backup_node_phase25
	inst_core_phase25._trigger_interaction()
	if captured_own_backup_phase25.get("message_text", "") != GameState.STORY_MESSAGES["datacenter_own_backup_placeholder"]:
		printerr("FAIL 25-A: own_backup placeholder message text mismatch!")
		get_tree().quit(1)
		return
	if not captured_core_trans_phase25.get("scene", "") == "datacenter_backup":
		printerr("FAIL 25-A: own_backup examine should not trigger any further scene transition (no ending route yet)!")
		get_tree().quit(1)
		return

	inst_core_phase25.free()

	# 7. 驗證 main.gd 全鏈雙向轉場 + BGM（entrance -> backup -> core -> backup -> entrance -> nightclub）
	GameState.reset_for_new_game()
	GameState.set_flag("read_old_work_order", true)

	main_instance_phase25.transition_to("datacenter_entrance", "from_nightclub")
	await get_tree().process_frame
	if main_instance_phase25._current_bgm_path != "res://assets/bgm/The Cold Mirror (Loop).mp3":
		printerr("FAIL 25-A: datacenter_entrance BGM should be The Cold Mirror (Loop).mp3, got: ", main_instance_phase25._current_bgm_path)
		get_tree().quit(1)
		return

	main_instance_phase25.transition_to("datacenter_backup", "from_entrance")
	await get_tree().process_frame
	if main_instance_phase25._current_bgm_path != "res://assets/bgm/Heartbeat of the Machine.mp3":
		printerr("FAIL 25-A: datacenter_backup BGM should be Heartbeat of the Machine.mp3, got: ", main_instance_phase25._current_bgm_path)
		get_tree().quit(1)
		return

	main_instance_phase25.transition_to("datacenter_backup_core", "from_backup")
	await get_tree().process_frame
	if main_instance_phase25._current_bgm_path != "res://assets/bgm/The Cold Mirror (Loop).mp3":
		printerr("FAIL 25-A: datacenter_backup_core BGM should be The Cold Mirror (Loop).mp3, got: ", main_instance_phase25._current_bgm_path)
		get_tree().quit(1)
		return

	main_instance_phase25.transition_to("datacenter_backup", "from_core")
	await get_tree().process_frame
	main_instance_phase25.transition_to("datacenter_entrance", "from_backup")
	await get_tree().process_frame
	main_instance_phase25.transition_to("nightclub_entrance", "from_datacenter")
	await get_tree().process_frame
	if main_instance_phase25._current_bgm_path != "res://assets/bgm/nightclub-1.mp3":
		printerr("FAIL 25-A: nightclub_entrance BGM should revert to nightclub-1.mp3 after returning from datacenter, got: ", main_instance_phase25._current_bgm_path)
		get_tree().quit(1)
		return

	if is_instance_valid(main_instance_phase25):
		main_instance_phase25.free()

	# 8. 驗證 Phase 1~24 不退化：apartment 仍可正常載入（抽樣回歸）
	var regression_main_phase25 = datacenter_main_scene_phase25.instantiate()
	add_child(regression_main_phase25)
	await get_tree().process_frame
	regression_main_phase25.transition_to("apartment", "wake_bed")
	await get_tree().process_frame
	if regression_main_phase25.get_current_scene_id() != "apartment":
		printerr("FAIL 25-A: apartment scene should still load after Phase 25-A registry changes!")
		get_tree().quit(1)
		return
	if is_instance_valid(regression_main_phase25):
		regression_main_phase25.free()

	# 9. 三語翻譯覆蓋 + 「林霏」/"Lin Fei" 禁字檢查
	var keys_phase25 = [
		"DLG_TRAVEL_DATACENTER_LOCKED_TEXT",
		"DLG_TRAVEL_DATACENTER_MENU_TEXT",
		"DLG_TRAVEL_DATACENTER_WAN_FLAVOR_TEXT",
		"DLG_TRAVEL_DATACENTER_TRAVEL_TEXT",
		"MSG_DATACENTER_ACCESS_DENIED",
		"MSG_DATACENTER_OWN_BACKUP_PLACEHOLDER",
		"MSG_DATACENTER_DELIVERY_BOT_FLAVOR",
		"PROMPT_NIGHTCLUB_ENTRANCE_TRAVEL_DATACENTER"
	]
	for k_phase25 in keys_phase25:
		for lang_phase25 in ["zh_TW", "zh_CN", "en"]:
			LocaleManager.set_locale(lang_phase25)
			var txt_phase25 = tr(k_phase25)
			if txt_phase25 == k_phase25:
				printerr("FAIL 25-A: key ", k_phase25, " has no ", lang_phase25, " translation.")
				get_tree().quit(1)
				return
			if lang_phase25 == "en":
				var lower_txt_phase25 = txt_phase25.to_lower()
				if "lin fei" in lower_txt_phase25 or "linfei" in lower_txt_phase25:
					printerr("FAIL 25-A: Forbidden word Lin Fei found in key ", k_phase25)
					get_tree().quit(1)
					return
			else:
				if "林霏" in txt_phase25:
					printerr("FAIL 25-A: Forbidden word 林霏 found in key ", k_phase25)
					get_tree().quit(1)
					return
	LocaleManager.set_locale("zh_TW")

	print("PASS: Phase 25-A datacenter skeleton, travel gate, access gate, and transitions verified.")

