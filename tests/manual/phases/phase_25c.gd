extends "res://tests/manual/phases/phase_26a.gd"

func _run_phase_25c() -> void:
	# ===================== Phase 25-C: 回歸 + 存讀檔護欄 =====================
	print("--- Phase 25-C: 回歸 + 存讀檔護欄 ---")

	# 1. 綜合存讀檔 round-trip：Phase 25 門禁道具/旗標與 Phase 24 終端旗標 / 追逐狀態同存同讀，互不干擾（無新存讀檔欄位）
	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)
	GameState.set_flag("seven_stopped_full", true)
	GameState.set_flag("deep_tunnel_opened", true)
	GameState.tunnel_chase_true_exit = 2
	GameState.add_item("old_work_badge", 1)
	GameState.set_flag("read_old_work_order", true)
	GameState.mark_scene_visited("datacenter_backup_core")

	var save_dict_phase25c = SaveSystem.capture("datacenter_backup_core", 100.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_dict_phase25c):
		printerr("FAIL 25-C: SaveSystem.write_slot failed for combined Phase 24/25 flags!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()

	var main_scene_phase25c = load("res://scenes/main/main.tscn")
	var main_instance_phase25c = main_scene_phase25c.instantiate()
	add_child(main_instance_phase25c)
	await get_tree().process_frame

	if not main_instance_phase25c.load_game_slot(TEST_SCRATCH_SAVE_SLOT):
		printerr("FAIL 25-C: load_game_slot(scratch slot) failed to load combined Phase 24/25 save!")
		get_tree().quit(1)
		return
	await get_tree().process_frame

	if main_instance_phase25c.get_current_scene_id() != "datacenter_backup_core":
		printerr("FAIL 25-C: current scene should restore to datacenter_backup_core after load, got: ", main_instance_phase25c.get_current_scene_id())
		get_tree().quit(1)
		return
	if not GameState.get_flag("passed_nightclub_security", false) or not GameState.get_flag("seven_stopped_full", false):
		printerr("FAIL 25-C: Phase 24 terminal flags did not survive save/load alongside Phase 25 datacenter state!")
		get_tree().quit(1)
		return
	if not GameState.has_item("old_work_badge") or not GameState.get_flag("read_old_work_order", false):
		printerr("FAIL 25-C: Phase 25 gate item/flag did not survive save/load!")
		get_tree().quit(1)
		return
	if GameState.tunnel_chase_true_exit != 2 or not GameState.get_flag("deep_tunnel_opened", false):
		printerr("FAIL 25-C: Phase 24 chase state did not survive save/load alongside Phase 25 datacenter save!")
		get_tree().quit(1)
		return
	if not GameState.visited_scenes.has("datacenter_backup_core"):
		printerr("FAIL 25-C: visited_scenes should retain datacenter_backup_core after save/load (M1, no new save field needed)!")
		get_tree().quit(1)
		return

	# 2. 迴歸抽樣：Phase 25 SceneRegistry / nightclub_entrance 動線改動後，Phase 24 核心動線仍可達
	main_instance_phase25c.transition_to("underground_settlement_right", "from_left")
	await get_tree().process_frame
	if main_instance_phase25c.get_current_scene_id() != "underground_settlement_right":
		printerr("FAIL 25-C: underground_settlement_right should still be reachable after Phase 25 registry changes!")
		get_tree().quit(1)
		return

	main_instance_phase25c.transition_to("underground_settlement", "from_right")
	await get_tree().process_frame
	if main_instance_phase25c.get_current_scene_id() != "underground_settlement":
		printerr("FAIL 25-C: underground_settlement round-trip (聚落往返) should still work after Phase 25 registry changes!")
		get_tree().quit(1)
		return

	main_instance_phase25c.transition_to("tunnel_combat", "from_settlement")
	await get_tree().process_frame
	if main_instance_phase25c.get_current_scene_id() != "tunnel_combat":
		printerr("FAIL 25-C: tunnel_combat entry should still be reachable after Phase 25 registry changes!")
		get_tree().quit(1)
		return

	main_instance_phase25c.transition_to("tunnel_chase", "from_settlement")
	await get_tree().process_frame
	if main_instance_phase25c.get_current_scene_id() != "tunnel_chase":
		printerr("FAIL 25-C: tunnel_chase (Phase 24 追逐房間1) should still be reachable after Phase 25 registry changes!")
		get_tree().quit(1)
		return

	main_instance_phase25c.transition_to("tunnel_chase_right", "from_left")
	await get_tree().process_frame
	if main_instance_phase25c.get_current_scene_id() != "tunnel_chase_right":
		printerr("FAIL 25-C: tunnel_chase_right (Phase 24 追逐房間2 / 攤牌) should still be reachable after Phase 25 registry changes!")
		get_tree().quit(1)
		return

	main_instance_phase25c.transition_to("nightclub_entrance", "from_street")
	await get_tree().process_frame
	if main_instance_phase25c.get_current_scene_id() != "nightclub_entrance":
		printerr("FAIL 25-C: nightclub_entrance should still be reachable after adding the AI 資料中心 travel destination!")
		get_tree().quit(1)
		return

	if is_instance_valid(main_instance_phase25c):
		main_instance_phase25c.free()

	# 3. 迴歸抽樣：Phase 21 echo_linfei 採集流程不受 Phase 25 影響
	GameState.reset_for_new_game()
	GameState.collect_echo_segment("echo_linfei", "s1")
	GameState.collect_echo_segment("echo_linfei", "s2")
	GameState.collect_echo_segment("echo_linfei", "s3")
	if not GameState.is_echo_audio_unlocked("echo_linfei"):
		printerr("FAIL 25-C: echo_linfei audio unlock (Phase 21) regressed after Phase 25 changes!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	if dir and dir.file_exists(TEST_SCRATCH_SAVE_FILE):
		dir.remove(TEST_SCRATCH_SAVE_FILE)

	print("PASS: Phase 25-C regression (Phase 1~24 core routes intact) and save/load guardrails verified.")

