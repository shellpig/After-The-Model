extends "res://tests/manual/phases/phase_28a.gd"

func _run_phase_27d() -> void:
	# ===================== Phase 27-D: 回歸 + 存讀檔 =====================
	print("--- Phase 27-D: 回歸 + 存讀檔 ---")

	var find_choice_phase27d = func(curr: Dictionary, substr: String) -> int:
		for c in curr.get("choices", []):
			if substr in tr(c.get("label", "")):
				return c.get("index")
		return -1

	var own_backup_tree_phase27d = DialogueDB.get_tree_for("own_backup")
	if own_backup_tree_phase27d.is_empty():
		printerr("FAIL 27-D: DialogueDB own_backup tree not found!")
		get_tree().quit(1)
		return

	# ---- Test 1: 6 旗標 + 廣播站場景 round-trip（決定後狀態：Expose + 已清洗上傳）----
	GameState.reset_for_new_game()
	GameState.set_flag("ending_route_expose", true)
	GameState.set_flag("expose_upload_cleaned", true)
	GameState.set_flag("expose_upload_done", true)
	GameState.set_flag("ending_save_hint_seen", true)
	GameState.mark_scene_visited("broadcast_station")

	var save_dict_phase27d = SaveSystem.capture("broadcast_station", 2200.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_dict_phase27d):
		printerr("FAIL 27-D: SaveSystem.write_slot failed for Phase 27 decided-state save!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()

	var main_scene_phase27d = load("res://scenes/main/main.tscn")
	var main_instance_phase27d = main_scene_phase27d.instantiate()
	add_child(main_instance_phase27d)
	await get_tree().process_frame

	if not main_instance_phase27d.load_game_slot(TEST_SCRATCH_SAVE_SLOT):
		printerr("FAIL 27-D: load_game_slot(scratch slot) failed to load Phase 27 decided-state save!")
		get_tree().quit(1)
		return
	await get_tree().process_frame

	if main_instance_phase27d.get_current_scene_id() != "broadcast_station":
		printerr("FAIL 27-D: current scene should restore to broadcast_station after load, got: ", main_instance_phase27d.get_current_scene_id())
		get_tree().quit(1)
		return

	if not GameState.get_flag("ending_route_expose", false) \
		or GameState.get_flag("ending_route_reclaim", false) \
		or GameState.get_flag("ending_route_protect", false) \
		or not GameState.get_flag("expose_upload_cleaned", false) \
		or not GameState.get_flag("expose_upload_done", false) \
		or not GameState.get_flag("ending_save_hint_seen", false):
		printerr("FAIL 27-D: the six Phase 27 flags did not all survive save/load round-trip!")
		get_tree().quit(1)
		return

	# 讀檔回場不重播進場 MessageBox（6-B 慣例）
	var captured_27d: Dictionary = {}
	var bc_level_phase27d = main_instance_phase27d.world_root.get_children()[-1]
	bc_level_phase27d.interaction_requested.connect(func(data):
		captured_27d.clear()
		captured_27d.merge(data, true)
	)
	if not captured_27d.is_empty():
		printerr("FAIL 27-D: loading a save inside broadcast_station must not replay the arrival MessageBox, got: ", captured_27d)
		get_tree().quit(1)
		return

	# expose_upload_done 持久化：上傳終端讀檔後仍是 idle 變體，不重開清洗閘樹
	var upload_terminal_phase27d = bc_level_phase27d.get_node_or_null("Interactables/UploadTerminal")
	if upload_terminal_phase27d == null:
		printerr("FAIL 27-D: broadcast_station missing UploadTerminal after load!")
		get_tree().quit(1)
		return
	bc_level_phase27d.current_interactable = upload_terminal_phase27d
	bc_level_phase27d._trigger_interaction()
	if captured_27d.get("message_text", "") != "MSG_BROADCAST_UPLOAD_DONE_IDLE":
		printerr("FAIL 27-D: after cross-save/load, upload terminal should stay in the idle variant (expose_upload_done persisted), got: ", captured_27d)
		get_tree().quit(1)
		return

	if is_instance_valid(main_instance_phase27d):
		main_instance_phase27d.free()
	await get_tree().process_frame
	GameState.reset_for_new_game()

	print("PASS 27-D: six-flag + broadcast_station scene round-trip (route exclusivity + cleaned/done + save-hint + no arrival replay + upload terminal idle gate persisted) verified.")

	# ---- Test 2: 三選前留檔，讀檔後三路皆可達（同一份存檔各自獨立走三路）----
	GameState.reset_for_new_game()
	GameState.set_flag("stood_before_own_backup", true)
	GameState.set_flag("ending_save_hint_seen", true)
	GameState.mark_scene_visited("datacenter_backup_core")

	var save_dict_pre_choice_phase27d = SaveSystem.capture("datacenter_backup_core", 100.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_dict_pre_choice_phase27d):
		printerr("FAIL 27-D: SaveSystem.write_slot failed for pre-choice save!")
		get_tree().quit(1)
		return

	var runner_phase27d := DialogueRunner.new()

	# 路 1：讀檔 -> 灌回去
	GameState.reset_for_new_game()
	if not SaveSystem.validate(SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)):
		printerr("FAIL 27-D: pre-choice save failed SaveSystem.validate!")
		get_tree().quit(1)
		return
	SaveSystem.apply(SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT))
	runner_phase27d.start(own_backup_tree_phase27d, "start")
	if runner_phase27d._current_node_id != "anchor":
		printerr("FAIL 27-D: with ending_save_hint_seen persisted, reopening own_backup after load should skip straight to anchor (提示不重播)! Got: ", runner_phase27d._current_node_id)
		get_tree().quit(1)
		return
	var anchor_curr_phase27d = runner_phase27d.current()
	runner_phase27d.choose(find_choice_phase27d.call(anchor_curr_phase27d, "灌回去"))
	var confirm_curr_phase27d = runner_phase27d.current()
	runner_phase27d.choose(find_choice_phase27d.call(confirm_curr_phase27d, "就這麼做"))
	if not GameState.get_flag("ending_route_reclaim", false) or GameState.get_flag("ending_route_protect", false) or GameState.get_flag("ending_route_expose", false):
		printerr("FAIL 27-D: route 1 (Reclaim) from the pre-choice save did not lock ending_route_reclaim exclusively!")
		get_tree().quit(1)
		return

	# 路 2：重讀同一份存檔 -> 刪掉它
	GameState.reset_for_new_game()
	SaveSystem.apply(SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT))
	runner_phase27d.start(own_backup_tree_phase27d, "start")
	if runner_phase27d._current_node_id != "anchor":
		printerr("FAIL 27-D: route 2 re-load should also skip straight to anchor! Got: ", runner_phase27d._current_node_id)
		get_tree().quit(1)
		return
	anchor_curr_phase27d = runner_phase27d.current()
	runner_phase27d.choose(find_choice_phase27d.call(anchor_curr_phase27d, "刪掉它"))
	confirm_curr_phase27d = runner_phase27d.current()
	runner_phase27d.choose(find_choice_phase27d.call(confirm_curr_phase27d, "就這麼做"))
	if not GameState.get_flag("ending_route_protect", false) or GameState.get_flag("ending_route_reclaim", false) or GameState.get_flag("ending_route_expose", false):
		printerr("FAIL 27-D: route 2 (Protect) from the pre-choice save did not lock ending_route_protect exclusively!")
		get_tree().quit(1)
		return

	# 路 3：重讀同一份存檔 -> 拷貝走
	GameState.reset_for_new_game()
	SaveSystem.apply(SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT))
	runner_phase27d.start(own_backup_tree_phase27d, "start")
	if runner_phase27d._current_node_id != "anchor":
		printerr("FAIL 27-D: route 3 re-load should also skip straight to anchor! Got: ", runner_phase27d._current_node_id)
		get_tree().quit(1)
		return
	anchor_curr_phase27d = runner_phase27d.current()
	runner_phase27d.choose(find_choice_phase27d.call(anchor_curr_phase27d, "拷貝走"))
	confirm_curr_phase27d = runner_phase27d.current()
	runner_phase27d.choose(find_choice_phase27d.call(confirm_curr_phase27d, "就這麼做"))
	if not GameState.get_flag("ending_route_expose", false) or GameState.get_flag("ending_route_reclaim", false) or GameState.get_flag("ending_route_protect", false):
		printerr("FAIL 27-D: route 3 (Expose) from the pre-choice save did not lock ending_route_expose exclusively!")
		get_tree().quit(1)
		return
	if runner_phase27d.pending_travel.get("scene_id", "") != "broadcast_station" or runner_phase27d.pending_travel.get("entry_point_id", "") != "from_backup_core":
		printerr("FAIL 27-D: route 3 (Expose) from the pre-choice save did not queue travel to broadcast_station:from_backup_core!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	print("PASS 27-D: a single pre-choice save reloaded three times independently reaches all three ending routes (Reclaim / Protect / Expose), with the save-hint staying suppressed on every reload.")

	# ---- Test 3: 回歸 Phase 1~26 不退化（尤其 25 travel / 門禁、24 追逐 / 攤牌、聚落往返、27 廣播站新掛點）----
	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)
	GameState.set_flag("seven_stopped_full", true)
	GameState.add_item("old_work_badge", 1)
	GameState.set_flag("read_old_work_order", true)

	var main_scene_phase27d_r = load("res://scenes/main/main.tscn")
	var main_instance_phase27d_r = main_scene_phase27d_r.instantiate()
	add_child(main_instance_phase27d_r)
	await get_tree().process_frame

	main_instance_phase27d_r.transition_to("datacenter_entrance", "from_nightclub")
	await get_tree().process_frame
	if main_instance_phase27d_r.get_current_scene_id() != "datacenter_entrance":
		printerr("FAIL 27-D: datacenter_entrance (25 travel gate) should still be reachable after Phase 27 changes!")
		get_tree().quit(1)
		return

	main_instance_phase27d_r.transition_to("datacenter_backup", "from_entrance")
	await get_tree().process_frame
	if main_instance_phase27d_r.get_current_scene_id() != "datacenter_backup":
		printerr("FAIL 27-D: datacenter_backup (25 門禁 gate 後動線) should still be reachable after Phase 27 changes!")
		get_tree().quit(1)
		return

	main_instance_phase27d_r.transition_to("datacenter_backup_core", "from_backup")
	await get_tree().process_frame
	if main_instance_phase27d_r.get_current_scene_id() != "datacenter_backup_core":
		printerr("FAIL 27-D: datacenter_backup_core (戰鬥③ 抵達門後動線) should still be reachable after Phase 27 changes!")
		get_tree().quit(1)
		return

	main_instance_phase27d_r.transition_to("broadcast_station", "from_backup_core")
	await get_tree().process_frame
	if main_instance_phase27d_r.get_current_scene_id() != "broadcast_station":
		printerr("FAIL 27-D: broadcast_station (Phase 27 新掛點) should still be reachable after Phase 27-C changes!")
		get_tree().quit(1)
		return

	main_instance_phase27d_r.transition_to("tunnel_chase", "from_settlement")
	await get_tree().process_frame
	if main_instance_phase27d_r.get_current_scene_id() != "tunnel_chase":
		printerr("FAIL 27-D: tunnel_chase (Phase 24 追逐房間1) should still be reachable after Phase 27 changes!")
		get_tree().quit(1)
		return

	main_instance_phase27d_r.transition_to("tunnel_chase_right", "from_left")
	await get_tree().process_frame
	if main_instance_phase27d_r.get_current_scene_id() != "tunnel_chase_right":
		printerr("FAIL 27-D: tunnel_chase_right (Phase 24 攤牌) should still be reachable after Phase 27 changes!")
		get_tree().quit(1)
		return

	main_instance_phase27d_r.transition_to("underground_settlement_right", "from_left")
	await get_tree().process_frame
	if main_instance_phase27d_r.get_current_scene_id() != "underground_settlement_right":
		printerr("FAIL 27-D: underground_settlement_right (聚落往返) should still be reachable after Phase 27 changes!")
		get_tree().quit(1)
		return

	main_instance_phase27d_r.transition_to("underground_settlement", "from_right")
	await get_tree().process_frame
	if main_instance_phase27d_r.get_current_scene_id() != "underground_settlement":
		printerr("FAIL 27-D: underground_settlement round-trip (聚落往返) should still work after Phase 27 changes!")
		get_tree().quit(1)
		return

	if is_instance_valid(main_instance_phase27d_r):
		main_instance_phase27d_r.free()

	GameState.reset_for_new_game()
	if dir and dir.file_exists(TEST_SCRATCH_SAVE_FILE):
		dir.remove(TEST_SCRATCH_SAVE_FILE)

	print("PASS: Phase 27-D regression (Phase 1~26 core routes + new broadcast_station leg intact) and save/load guardrails (six flags round-trip + pre-choice save reaches all three routes + save-hint suppressed on reload) verified.")

