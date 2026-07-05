extends "res://tests/manual/phases/phase_21b.gd"

func _run_phase_21a() -> void:
	# ===================== Phase 21-A: Act 3 夜總會場景骨架與轉場 =====================
	print("--- Phase 21-A: Act 3 夜總會場景骨架與轉場 ---")

	# 重新實例化一個 main 供 Phase 21-A 測試使用
	var nightclub_main_scene = load("res://scenes/main/main.tscn")
	main_instance = nightclub_main_scene.instantiate()
	add_child(main_instance)
	await get_tree().process_frame

	# 1. 驗證 SceneRegistry
	var scenes21 = main_instance.SCENES
	if not "nightclub_entrance" in scenes21 or not "nightclub" in scenes21 or not "nightclub_back" in scenes21:
		printerr("FAIL 21-A: SceneRegistry missing nightclub scenes!")
		get_tree().quit(1)
		return

	if not "from_topside" in scenes21["apartment_entrance"].get("entry_points", []):
		printerr("FAIL 21-A: apartment_entrance entry points missing from_topside!")
		get_tree().quit(1)
		return

	if SaveSystem.get_scene_display_name("nightclub_entrance") == "未知區域" or SaveSystem.get_scene_display_name("nightclub") == "未知區域" or SaveSystem.get_scene_display_name("nightclub_back") == "未知區域":
		printerr("FAIL 21-A: SaveSystem SCENE_NAMES missing nightclub scenes!")
		get_tree().quit(1)
		return

	# 2. 驗證 learned_topside_shortcut 預設與存讀檔
	GameState.reset_for_new_game()
	if GameState.get_flag("learned_topside_shortcut", false):
		printerr("FAIL 21-A: learned_topside_shortcut should default to false!")
		get_tree().quit(1)
		return

	GameState.set_flag("learned_topside_shortcut", true)
	var captured_save = SaveSystem.capture("nightclub", 200.0)
	GameState.reset_for_new_game()
	SaveSystem.apply(captured_save)
	if not GameState.get_flag("learned_topside_shortcut", false):
		printerr("FAIL 21-A: learned_topside_shortcut flag not restored from save!")
		get_tree().quit(1)
		return

	# 3. 模擬月台 commuter_screen 互動解鎖
	GameState.reset_for_new_game()
	var packed_platform = load("res://scenes/levels/subway_station/subway_station_platform.tscn")
	var platform_inst = packed_platform.instantiate()
	# 模擬 commuter_screen 互動
	platform_inst.current_interactable = platform_inst.get_node("Interactables/CommuterScreenArea")
	platform_inst._trigger_interaction()
	if not GameState.get_flag("learned_topside_shortcut", false):
		printerr("FAIL 21-A: commuter_screen interaction should set learned_topside_shortcut to true!")
		get_tree().quit(1)
		return

	# i18n: commuter_screen flavour resolves through tr() in all 3 locales and
	# reflects the corrected route (back on the street, head left to the old
	# maintenance corridor up to the Upper District — not "deep in the subway").
	var commuter_msg_key_21: String = platform_inst.MESSAGES["commuter_screen"]
	if not commuter_msg_key_21.begins_with("MSG_"):
		printerr("FAIL 21-A: commuter_screen message should be an i18n key, got: ", commuter_msg_key_21)
		get_tree().quit(1)
		return
	for loc_21 in ["zh_TW", "zh_CN", "en"]:
		LocaleManager.set_locale(loc_21)
		if tr(commuter_msg_key_21) == commuter_msg_key_21:
			printerr("FAIL 21-A: commuter_screen key has no %s translation." % loc_21)
			get_tree().quit(1)
			return
	LocaleManager.set_locale("zh_TW")
	var commuter_zh_21: String = tr(commuter_msg_key_21)
	if not ("向左" in commuter_zh_21 and "舊維修通道" in commuter_zh_21):
		printerr("FAIL 21-A: commuter_screen zh_TW missing corrected route wording, got: ", commuter_zh_21)
		get_tree().quit(1)
		return
	if "地鐵站深處" in commuter_zh_21:
		printerr("FAIL 21-A: commuter_screen still contains the old wrong 'deep in the subway' wording!")
		get_tree().quit(1)
		return
	platform_inst.free()

	# 4. 驗證 travel_street_west 對話樹分流
	DialogueDB = load("res://data/dialogue/dialogue_db.gd")
	var travel_tree21 = DialogueDB.get_tree_for("travel_street_west")

	# Case A: learned_topside_shortcut = false, lu_hinted_topside = true (地鐵解鎖但捷徑未解鎖)
	GameState.reset_for_new_game()
	GameState.set_flag("lu_hinted_topside", true)
	var travel_runner_no_shortcut = DialogueRunner.new()
	travel_runner_no_shortcut.start(travel_tree21)
	var labels_no_shortcut := []
	for choice in travel_runner_no_shortcut.current().get("choices", []):
		labels_no_shortcut.append(tr(choice.get("label", "")))
	if labels_no_shortcut.has("前往上層區") or tr("DLG_TRAVEL_STREET_WEST_MENU_CHOICE2") in labels_no_shortcut:
		printerr("FAIL 21-A: Go to Upper District choice should be hidden when learned_topside_shortcut is false!")
		get_tree().quit(1)
		return

	# Case B: learned_topside_shortcut = true, lu_hinted_topside = true (兩者皆解鎖)
	GameState.set_flag("learned_topside_shortcut", true)
	var travel_runner_has_shortcut = DialogueRunner.new()
	travel_runner_has_shortcut.start(travel_tree21)
	var choices_21a = travel_runner_has_shortcut.current().get("choices", [])
	var upper_district_choice_idx := -1
	for idx in range(choices_21a.size()):
		if choices_21a[idx].get("label", "") == "DLG_TRAVEL_STREET_WEST_MENU_CHOICE2":
			upper_district_choice_idx = idx
			break
	if upper_district_choice_idx == -1:
		printerr("FAIL 21-A: Go to Upper District choice not found in choices when learned_topside_shortcut is true!")
		get_tree().quit(1)
		return

	travel_runner_has_shortcut.choose(upper_district_choice_idx)
	if travel_runner_has_shortcut.pending_travel.get("scene_id", "") != "nightclub_entrance" or travel_runner_has_shortcut.pending_travel.get("entry_point_id", "") != "from_street":
		printerr("FAIL 21-A: travel payload incorrect for nightclub transition: ", travel_runner_has_shortcut.pending_travel)
		get_tree().quit(1)
		return

	# 5. 驗證夜總會三場景載入與雙向轉場
	var nightclub_specs := {
		"nightclub_entrance": {
			"path": "res://scenes/levels/nightclub/nightclub_entrance.tscn",
			"limit_right": 1376,
			"spawns": ["from_street", "from_lobby"],
			"transitions": [
				{"area": "Interactables/ExitToStreetArea", "target_scene": "apartment_entrance", "target_entry": "from_topside"},
				{"area": "Interactables/ServiceDoorArea", "target_scene": "nightclub", "target_entry": "from_entrance"}
			]
		},
		"nightclub": {
			"path": "res://scenes/levels/nightclub/nightclub.tscn",
			"limit_right": 4288,
			"spawns": ["from_entrance", "from_back"],
			"transitions": [
				{"area": "Interactables/ExitToEntranceArea", "target_scene": "nightclub_entrance", "target_entry": "from_lobby"},
				{"area": "Interactables/BackDoorArea", "target_scene": "nightclub_back", "target_entry": "from_lobby"}
			]
		},
		"nightclub_back": {
			"path": "res://scenes/levels/nightclub/nightclub_back.tscn",
			"limit_right": 4800,
			"spawns": ["from_lobby"],
			"transitions": [
				{"area": "Interactables/ExitToLobbyArea", "target_scene": "nightclub", "target_entry": "from_back"}
			]
		}
	}

	# Pre-set passed_nightclub_security so that back_door transition check succeeds
	GameState.set_flag("passed_nightclub_security", true)

	for scene_id in nightclub_specs:
		var spec = nightclub_specs[scene_id]
		var packed = load(spec["path"])
		if not packed:
			printerr("FAIL 21-A: Could not load scene ", spec["path"])
			get_tree().quit(1)
			return

		var inst = packed.instantiate()
		add_child(inst)
		await get_tree().process_frame

		# 檢查相機邊界
		var camera = inst.get_node("Camera2D")
		if not camera or camera.limit_right != spec["limit_right"]:
			printerr("FAIL 21-A: Camera limit_right incorrect for ", scene_id)
			get_tree().quit(1)
			return

		# 檢查 spawn points
		for spawn in spec["spawns"]:
			if not inst.has_node("SpawnPoints/" + spawn):
				printerr("FAIL 21-A: Missing spawn point ", spawn, " in ", scene_id)
				get_tree().quit(1)
				return

		# 檢查轉場 Area2D
		for trans in spec["transitions"]:
			var captured_trans := {}
			inst.scene_transition_requested.connect(func(t_scene: String, t_entry: String, payload: Dictionary):
				captured_trans["scene"] = t_scene
				captured_trans["entry"] = t_entry
			)
			var area_node = inst.get_node(trans["area"])
			if not area_node:
				printerr("FAIL 21-A: Missing transition area node ", trans["area"], " in ", scene_id)
				get_tree().quit(1)
				return
			inst.current_interactable = area_node
			inst._trigger_interaction()
			if captured_trans.get("scene", "") != trans["target_scene"] or captured_trans.get("entry", "") != trans["target_entry"]:
				printerr("FAIL 21-A: Transition target mismatch for area ", trans["area"], " in ", scene_id, ": ", captured_trans)
				get_tree().quit(1)
				return

		inst.free()

	# 6. 驗證 BGM 播放與過門換曲
	# 街道 -> 大門口 (播 nightclub-1.mp3)
	main_instance.transition_to("nightclub_entrance", "from_street")
	await get_tree().process_frame
	if main_instance._current_bgm_path != "res://assets/bgm/nightclub-1.mp3":
		printerr("FAIL 21-A: nightclub_entrance BGM should be nightclub-1.mp3, got: ", main_instance._current_bgm_path)
		get_tree().quit(1)
		return

	# 大門口 -> 門面廳 (依然是 nightclub-1.mp3)
	main_instance.transition_to("nightclub", "from_entrance")
	await get_tree().process_frame
	if main_instance._current_bgm_path != "res://assets/bgm/nightclub-1.mp3":
		printerr("FAIL 21-A: nightclub lobby BGM should be nightclub-1.mp3, got: ", main_instance._current_bgm_path)
		get_tree().quit(1)
		return

	# 門面廳 -> 後場包廂 (過門換曲成 nightclub-2.mp3)
	main_instance.transition_to("nightclub_back", "from_lobby")
	await get_tree().process_frame
	if main_instance._current_bgm_path != "res://assets/bgm/nightclub-2.mp3":
		printerr("FAIL 21-A: nightclub_back BGM should be nightclub-2.mp3, got: ", main_instance._current_bgm_path)
		get_tree().quit(1)
		return

	# 7. 驗證三語翻譯禁字 "林霏" (Lin Fei) 檢查
	var keys_21a = [
		"DLG_TRAVEL_STREET_WEST_MENU_CHOICE2",
		"DLG_TRAVEL_STREET_WEST_TRAVEL_TO_NIGHTCLUB_TEXT"
	]
	for k in keys_21a:
		for lang in ["zh_TW", "zh_CN", "en"]:
			LocaleManager.set_locale(lang)
			var txt = tr(k)
			if lang == "en":
				var lower_txt = txt.to_lower()
				if "lin fei" in lower_txt or "linfei" in lower_txt:
					printerr("FAIL 21-A: Forbidden word Lin Fei found in key ", k, " for lang ", lang)
					get_tree().quit(1)
					return
			else:
				if "林霏" in txt:
					printerr("FAIL 21-A: Forbidden word 林霏 found in key ", k, " for lang ", lang)
					get_tree().quit(1)
					return
	LocaleManager.set_locale("zh_TW")
	if is_instance_valid(main_instance):
		main_instance.free()
	print("PASS: Phase 21-A nightclub skeleton and transitions verified.")

