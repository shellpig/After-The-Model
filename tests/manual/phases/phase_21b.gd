extends "res://tests/manual/phases/phase_21c.gd"

func _run_phase_21b() -> void:
	# ===================== Phase 21-B: 林霏核心殘響資料與分段媒體 =====================
	print("--- Phase 21-B: 林霏核心殘響資料與分段媒體 ---")

	# 1. 登記與翻譯驗證
	if not EchoDB.has_echo("echo_linfei"):
		printerr("FAIL 21-B: EchoDB registry missing echo_linfei!")
		get_tree().quit(1)
		return

	if EchoDB.get_segment_count("echo_linfei") != 6:
		printerr("FAIL 21-B: echo_linfei segments size incorrect (expected 6, got ", EchoDB.get_segment_count("echo_linfei"), ")")
		get_tree().quit(1)
		return

	# 1b. 場景內 EchoPoint 跨圖佈點驗證（防止資料層通過但世界裡採不到的假綠燈）
	var linfei_point_scenes := {
		"res://scenes/levels/nightclub/nightclub_entrance.tscn": ["s1"],
		"res://scenes/levels/subway_station/subway_station_platform.tscn": ["s2"],
		"res://scenes/levels/underground_settlement/underground_settlement.tscn": ["s3"],
		"res://scenes/levels/nightclub/nightclub.tscn": ["s4"],
		"res://scenes/levels/nightclub/nightclub_back.tscn": ["s5", "s6"]
	}
	var found_linfei_segments := {}
	for scene_path in linfei_point_scenes:
		var packed_lf = load(scene_path)
		if not packed_lf:
			printerr("FAIL 21-B: Could not load scene for EchoPoint placement check: ", scene_path)
			get_tree().quit(1)
			return
		var inst_lf = packed_lf.instantiate()
		var scene_segments := []
		for area in inst_lf.find_children("*", "Area2D", true, false):
			if area.get("echo_id") == "echo_linfei":
				scene_segments.append(area.get("segment_id"))
				found_linfei_segments[area.get("segment_id")] = true
		inst_lf.free()
		for expected_seg in linfei_point_scenes[scene_path]:
			if not expected_seg in scene_segments:
				printerr("FAIL 21-B: echo_linfei EchoPoint segment ", expected_seg, " not authored in ", scene_path, " (found: ", scene_segments, ")")
				get_tree().quit(1)
				return
	for seg in ["s1", "s2", "s3", "s4", "s5", "s6"]:
		if not seg in found_linfei_segments:
			printerr("FAIL 21-B: echo_linfei segment ", seg, " has no EchoPoint placed in any scene!")
			get_tree().quit(1)
			return

	var keys_21b = [
		"ECHO_LINFEI_TITLE",
		"ECHO_LINFEI_SEG_S1",
		"ECHO_LINFEI_SEG_S2",
		"ECHO_LINFEI_SEG_S3",
		"ECHO_LINFEI_SEG_S4",
		"ECHO_LINFEI_SEG_S5",
		"ECHO_LINFEI_SEG_S6",
		"ECHO_LINFEI_COMMENT"
	]
	for k in keys_21b:
		for lang in ["zh_TW", "zh_CN", "en"]:
			LocaleManager.set_locale(lang)
			var txt = tr(k)
			if lang == "en":
				var lower_txt = txt.to_lower()
				if "lin fei" in lower_txt or "linfei" in lower_txt:
					printerr("FAIL 21-B: Forbidden word Lin Fei found in key ", k, " for lang ", lang)
					get_tree().quit(1)
					return
			else:
				if "林霏" in txt:
					printerr("FAIL 21-B: Forbidden word 林霏 found in key ", k, " for lang ", lang)
					get_tree().quit(1)
					return
	LocaleManager.set_locale("zh_TW")

	# 2. 分段媒體門檻功能測試
	GameState.reset_for_new_game()
	# 0 段
	if GameState.is_echo_audio_unlocked("echo_linfei") or GameState.is_echo_image_unlocked("echo_linfei"):
		printerr("FAIL 21-B: echo_linfei media unlocked at 0 segments collected!")
		get_tree().quit(1)
		return

	# 1~2 段
	GameState.collect_echo_segment("echo_linfei", "s1")
	GameState.collect_echo_segment("echo_linfei", "s2")
	if GameState.is_echo_audio_unlocked("echo_linfei") or GameState.is_echo_image_unlocked("echo_linfei"):
		printerr("FAIL 21-B: echo_linfei media unlocked at 2 segments collected!")
		get_tree().quit(1)
		return

	# 3 段（達半數門檻）
	GameState.collect_echo_segment("echo_linfei", "s3")
	if not GameState.is_echo_audio_unlocked("echo_linfei"):
		printerr("FAIL 21-B: echo_linfei audio should unlock at 3 segments collected!")
		get_tree().quit(1)
		return
	if GameState.is_echo_image_unlocked("echo_linfei"):
		printerr("FAIL 21-B: echo_linfei image should NOT unlock at 3 segments collected!")
		get_tree().quit(1)
		return
	if GameState.get_echo_audio_path("echo_linfei") != "res://assets/audio/echoes/echo_linfei_song.mp3":
		printerr("FAIL 21-B: echo_linfei audio path mismatch: ", GameState.get_echo_audio_path("echo_linfei"))
		get_tree().quit(1)
		return

	# 4~5 段
	GameState.collect_echo_segment("echo_linfei", "s4")
	GameState.collect_echo_segment("echo_linfei", "s5")
	if not GameState.is_echo_audio_unlocked("echo_linfei"):
		printerr("FAIL 21-B: audio unlocked state lost at 5 segments!")
		get_tree().quit(1)
		return
	if GameState.is_echo_image_unlocked("echo_linfei"):
		printerr("FAIL 21-B: echo_linfei image should NOT unlock at 5 segments!")
		get_tree().quit(1)
		return

	# 6 段（全收集）
	GameState.collect_echo_segment("echo_linfei", "s6")
	if not GameState.is_echo_audio_unlocked("echo_linfei") or not GameState.is_echo_image_unlocked("echo_linfei"):
		printerr("FAIL 21-B: echo_linfei all media should unlock at 6 segments collected!")
		get_tree().quit(1)
		return
	if GameState.get_echo_image_path("echo_linfei") != "res://assets/images/echoes/echo_linfei.jpeg":
		printerr("FAIL 21-B: echo_linfei image path mismatch: ", GameState.get_echo_image_path("echo_linfei"))
		get_tree().quit(1)
		return

	# 3. 既有普通殘響退化驗證 (以 echo_clerk 為例)
	GameState.reset_for_new_game()
	# 未集滿
	if GameState.is_echo_audio_unlocked("echo_clerk"):
		printerr("FAIL 21-B: legacy echo clerk audio unlocked when incomplete!")
		get_tree().quit(1)
		return
	# 集滿
	GameState.collect_echo_segment("echo_clerk", "s1")
	if not GameState.is_echo_audio_unlocked("echo_clerk"):
		printerr("FAIL 21-B: legacy echo clerk audio NOT unlocked when complete!")
		get_tree().quit(1)
		return
	if GameState.get_echo_audio_path("echo_clerk") != "res://assets/audio/echoes/echo_clerk.ogg":
		printerr("FAIL 21-B: legacy echo clerk audio path incorrect: ", GameState.get_echo_audio_path("echo_clerk"))
		get_tree().quit(1)
		return

	# 4. 存讀檔 persistence round-trip 驗證
	GameState.reset_for_new_game()
	GameState.collect_echo_segment("echo_linfei", "s1")
	GameState.collect_echo_segment("echo_linfei", "s2")
	GameState.collect_echo_segment("echo_linfei", "s3") # 半滿
	var save_data_21b = SaveSystem.capture("nightclub", 100.0)
	GameState.reset_for_new_game()
	SaveSystem.apply(save_data_21b)
	if GameState.get_collected_segment_count("echo_linfei") != 3:
		printerr("FAIL 21-B: echo_linfei collected segments count not restored: ", GameState.get_collected_segment_count("echo_linfei"))
		get_tree().quit(1)
		return
	if not GameState.is_echo_audio_unlocked("echo_linfei") or GameState.is_echo_image_unlocked("echo_linfei"):
		printerr("FAIL 21-B: echo_linfei media unlock states not restored correctly after load!")
		get_tree().quit(1)
		return

	print("PASS: Phase 21-B linfei echo database registration and segmented media verified.")

