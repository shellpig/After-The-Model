extends "res://tests/manual/phases/phase_29.gd"

func _run_phase_28d() -> void:
	# ===================== Phase 28-D: 回歸 + 存讀檔 =====================
	print("--- Phase 28-D: 回歸 + 存讀檔 ---")

	# ---- Test 1: 2 旗標 round-trip（各自獨立存讀，讀檔不重播已演出序列）----
	GameState.reset_for_new_game()
	GameState.set_flag("ending_route_reclaim", true)
	GameState.set_flag("ending_reclaim_played", true)
	GameState.mark_scene_visited("apartment")

	var save_reclaim_played_phase28d = SaveSystem.capture("apartment", 400.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_reclaim_played_phase28d):
		printerr("FAIL 28-D: write_slot failed for ending_reclaim_played round-trip save!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	var main_rt1_phase28d = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_rt1_phase28d)
	await get_tree().process_frame

	if not main_rt1_phase28d.load_game_slot(TEST_SCRATCH_SAVE_SLOT):
		printerr("FAIL 28-D: load_game_slot(scratch slot) failed to load the ending_reclaim_played save!")
		get_tree().quit(1)
		return
	await get_tree().process_frame

	if main_rt1_phase28d.get_current_scene_id() != "apartment":
		printerr("FAIL 28-D: an already-played Reclaim save should load straight back into apartment (not treated as an orphan), got: ", main_rt1_phase28d.get_current_scene_id())
		get_tree().quit(1)
		return
	if not GameState.get_flag("ending_route_reclaim", false) or not GameState.get_flag("ending_reclaim_played", false):
		printerr("FAIL 28-D: ending_route_reclaim / ending_reclaim_played did not survive save/load round-trip!")
		get_tree().quit(1)
		return
	if UIMode.get_mode() != UIMode.Mode.NONE:
		printerr("FAIL 28-D: reloading an already-played Reclaim save must not re-arm the epilogue sequence (entry point is 'restore', not 'epilogue_home'), got UIMode=", UIMode.get_mode())
		get_tree().quit(1)
		return
	print("PASS 28-D: ending_reclaim_played + ending_route_reclaim round-trip cleanly and reloading does not replay the already-finished sequence.")

	if is_instance_valid(main_rt1_phase28d):
		main_rt1_phase28d.free()
	await get_tree().process_frame
	GameState.reset_for_new_game()

	GameState.set_flag("ending_route_protect", true)
	GameState.set_flag("ending_protect_played", true)
	GameState.mark_scene_visited("apartment")

	var save_protect_played_phase28d = SaveSystem.capture("apartment", 400.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_protect_played_phase28d):
		printerr("FAIL 28-D: write_slot failed for ending_protect_played round-trip save!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	var main_rt2_phase28d = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_rt2_phase28d)
	await get_tree().process_frame

	if not main_rt2_phase28d.load_game_slot(TEST_SCRATCH_SAVE_SLOT):
		printerr("FAIL 28-D: load_game_slot(scratch slot) failed to load the ending_protect_played save!")
		get_tree().quit(1)
		return
	await get_tree().process_frame

	if main_rt2_phase28d.get_current_scene_id() != "apartment":
		printerr("FAIL 28-D: an already-played Protect save should load straight back into apartment (not treated as an orphan), got: ", main_rt2_phase28d.get_current_scene_id())
		get_tree().quit(1)
		return
	if not GameState.get_flag("ending_route_protect", false) or not GameState.get_flag("ending_protect_played", false):
		printerr("FAIL 28-D: ending_route_protect / ending_protect_played did not survive save/load round-trip!")
		get_tree().quit(1)
		return
	if UIMode.get_mode() != UIMode.Mode.NONE:
		printerr("FAIL 28-D: reloading an already-played Protect save must not re-arm the epilogue sequence, got UIMode=", UIMode.get_mode())
		get_tree().quit(1)
		return
	print("PASS 28-D: ending_protect_played + ending_route_protect round-trip cleanly and reloading does not replay the already-finished sequence.")

	if is_instance_valid(main_rt2_phase28d):
		main_rt2_phase28d.free()
	await get_tree().process_frame
	GameState.reset_for_new_game()

	# ---- Test 2: 選擇前留檔，讀檔三次分別自動跑完整序列，各自抵達正確終站 + 旗標 ----
	# （route 3 = Reclaim ; route 4 = Protect not-B ; route 5 = Protect Branch B）
	GameState.set_flag("stood_before_own_backup", true)
	GameState.set_flag("ending_save_hint_seen", true)
	GameState.mark_scene_visited("datacenter_backup_core")

	var save_pre_choice_phase28d = SaveSystem.capture("datacenter_backup_core", 100.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_pre_choice_phase28d):
		printerr("FAIL 28-D: write_slot failed for pre-choice save!")
		get_tree().quit(1)
		return

	var own_backup_tree_phase28d = DialogueDB.get_tree_for("own_backup")
	if own_backup_tree_phase28d.is_empty():
		printerr("FAIL 28-D: DialogueDB own_backup tree not found!")
		get_tree().quit(1)
		return

	var find_choice_phase28d = func(curr: Dictionary, substr: String) -> int:
		for c in curr.get("choices", []):
			if substr in tr(c.get("label", "")):
				return c.get("index")
		return -1

	# 路 3：讀檔 -> 灌回去 -> 全程自動跑完 Reclaim 三站
	GameState.reset_for_new_game()
	SaveSystem.apply(SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT))
	var runner_r_phase28d := DialogueRunner.new()
	runner_r_phase28d.start(own_backup_tree_phase28d, "start")
	var anchor_r_phase28d = runner_r_phase28d.current()
	runner_r_phase28d.choose(find_choice_phase28d.call(anchor_r_phase28d, "灌回去"))
	var confirm_r_phase28d = runner_r_phase28d.current()
	runner_r_phase28d.choose(find_choice_phase28d.call(confirm_r_phase28d, "就這麼做"))
	if not GameState.get_flag("ending_route_reclaim", false):
		printerr("FAIL 28-D: route 3 (Reclaim) choice from the pre-choice save did not set ending_route_reclaim!")
		get_tree().quit(1)
		return

	var main_r_phase28d = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_r_phase28d)
	await get_tree().process_frame
	main_r_phase28d.transition_to("datacenter_backup_core", "from_backup")
	await get_tree().process_frame

	var drive_r_phase28d = await _drive_ending_sequence_phase28d(main_r_phase28d)
	if main_r_phase28d.get_current_scene_id() != "apartment" or main_r_phase28d.get_current_entry_point_id() != "epilogue_home":
		printerr("FAIL 28-D: route 3 (Reclaim) full auto-drive should land on apartment:epilogue_home, got scene=", main_r_phase28d.get_current_scene_id(), " entry=", main_r_phase28d.get_current_entry_point_id(), " after ", drive_r_phase28d.get("frames", -1), " frames")
		get_tree().quit(1)
		return
	if not GameState.get_flag("ending_reclaim_played", false):
		printerr("FAIL 28-D: route 3 (Reclaim) full auto-drive did not set ending_reclaim_played!")
		get_tree().quit(1)
		return
	if drive_r_phase28d.get("save_ever_unlocked", true):
		printerr("FAIL 28-D: route 3 (Reclaim) should have kept can_save_here == false for the entire sequence!")
		get_tree().quit(1)
		return
	if SaveSystem.can_save_here:
		printerr("FAIL 28-D: can_save_here should remain false at Reclaim's frozen final station!")
		get_tree().quit(1)
		return
	print("PASS 28-D: pre-choice save route 3 (Reclaim) full auto-drive reaches apartment:epilogue_home, sets ending_reclaim_played, and keeps can_save_here locked throughout.")

	if is_instance_valid(main_r_phase28d):
		main_r_phase28d.free()
	await get_tree().process_frame
	GameState.reset_for_new_game()

	# 路 4：重讀同一份存檔 -> 刪掉它 -> 全程自動跑完 Protect not-B（cen_voiceprint_exposed 預設 false）三站
	SaveSystem.apply(SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT))
	var runner_p_notb_phase28d := DialogueRunner.new()
	runner_p_notb_phase28d.start(own_backup_tree_phase28d, "start")
	var anchor_p_notb_phase28d = runner_p_notb_phase28d.current()
	runner_p_notb_phase28d.choose(find_choice_phase28d.call(anchor_p_notb_phase28d, "刪掉它"))
	var confirm_p_notb_phase28d = runner_p_notb_phase28d.current()
	runner_p_notb_phase28d.choose(find_choice_phase28d.call(confirm_p_notb_phase28d, "就這麼做"))
	if not GameState.get_flag("ending_route_protect", false):
		printerr("FAIL 28-D: route 4 (Protect not-B) choice from the pre-choice save did not set ending_route_protect!")
		get_tree().quit(1)
		return

	var main_p_notb_phase28d = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_p_notb_phase28d)
	await get_tree().process_frame
	main_p_notb_phase28d.transition_to("datacenter_backup_core", "from_backup")
	await get_tree().process_frame

	var drive_p_notb_phase28d = await _drive_ending_sequence_phase28d(main_p_notb_phase28d)
	if main_p_notb_phase28d.get_current_scene_id() != "apartment" or main_p_notb_phase28d.get_current_entry_point_id() != "epilogue_home":
		printerr("FAIL 28-D: route 4 (Protect not-B) full auto-drive should land on apartment:epilogue_home, got scene=", main_p_notb_phase28d.get_current_scene_id(), " entry=", main_p_notb_phase28d.get_current_entry_point_id(), " after ", drive_p_notb_phase28d.get("frames", -1), " frames")
		get_tree().quit(1)
		return
	if not GameState.get_flag("ending_protect_played", false) or not GameState.get_flag("ending_protect_cen_seen", false):
		printerr("FAIL 28-D: route 4 (Protect not-B) full auto-drive did not set ending_protect_played / ending_protect_cen_seen (28-C not-B middle station)!")
		get_tree().quit(1)
		return
	if drive_p_notb_phase28d.get("save_ever_unlocked", true):
		printerr("FAIL 28-D: route 4 (Protect not-B) should have kept can_save_here == false for the entire sequence!")
		get_tree().quit(1)
		return
	print("PASS 28-D: pre-choice save route 4 (Protect, cen_voiceprint_exposed==false) full auto-drive reaches apartment:epilogue_home via subway_station's 28-C middle station, sets ending_protect_played, and keeps can_save_here locked throughout.")

	if is_instance_valid(main_p_notb_phase28d):
		main_p_notb_phase28d.free()
	await get_tree().process_frame
	GameState.reset_for_new_game()

	# 路 5：重讀同一份存檔 -> 刪掉它 + cen_voiceprint_exposed=true -> 全程自動跑完 Protect Branch B 三站
	SaveSystem.apply(SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT))
	var runner_p_b_phase28d := DialogueRunner.new()
	runner_p_b_phase28d.start(own_backup_tree_phase28d, "start")
	var anchor_p_b_phase28d = runner_p_b_phase28d.current()
	runner_p_b_phase28d.choose(find_choice_phase28d.call(anchor_p_b_phase28d, "刪掉它"))
	var confirm_p_b_phase28d = runner_p_b_phase28d.current()
	runner_p_b_phase28d.choose(find_choice_phase28d.call(confirm_p_b_phase28d, "就這麼做"))
	GameState.set_flag("cen_voiceprint_exposed", true)
	if not GameState.get_flag("ending_route_protect", false):
		printerr("FAIL 28-D: route 5 (Protect Branch B) choice from the pre-choice save did not set ending_route_protect!")
		get_tree().quit(1)
		return

	var main_p_b_phase28d = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_p_b_phase28d)
	await get_tree().process_frame
	main_p_b_phase28d.transition_to("datacenter_backup_core", "from_backup")
	await get_tree().process_frame

	var drive_p_b_phase28d = await _drive_ending_sequence_phase28d(main_p_b_phase28d)
	if main_p_b_phase28d.get_current_scene_id() != "apartment" or main_p_b_phase28d.get_current_entry_point_id() != "epilogue_home":
		printerr("FAIL 28-D: route 5 (Protect Branch B) full auto-drive should land on apartment:epilogue_home, got scene=", main_p_b_phase28d.get_current_scene_id(), " entry=", main_p_b_phase28d.get_current_entry_point_id(), " after ", drive_p_b_phase28d.get("frames", -1), " frames")
		get_tree().quit(1)
		return
	if not GameState.get_flag("ending_protect_played", false) or not GameState.get_flag("ending_protect_wu_seen", false):
		printerr("FAIL 28-D: route 5 (Protect Branch B) full auto-drive did not set ending_protect_played / ending_protect_wu_seen (28-C Branch B middle station)!")
		get_tree().quit(1)
		return
	if drive_p_b_phase28d.get("save_ever_unlocked", true):
		printerr("FAIL 28-D: route 5 (Protect Branch B) should have kept can_save_here == false for the entire sequence!")
		get_tree().quit(1)
		return
	print("PASS 28-D: pre-choice save route 5 (Protect, cen_voiceprint_exposed==true) full auto-drive reaches apartment:epilogue_home via underground_settlement's 28-C Branch B middle station, sets ending_protect_played, and keeps can_save_here locked throughout.")

	if is_instance_valid(main_p_b_phase28d):
		main_p_b_phase28d.free()
	await get_tree().process_frame
	GameState.reset_for_new_game()

	print("PASS 28-D: a single pre-choice save reloaded three times independently drives all three reachable endings (Reclaim / Protect not-B / Protect Branch B) end-to-end to their frozen final station.")

	# ---- Test 3: 孤兒檔救援 —— route 已設、played 未設的舊檔讀入時無視存檔場景，強制回站 1 ----
	GameState.reset_for_new_game()
	GameState.set_flag("ending_route_reclaim", true)
	GameState.mark_scene_visited("convenience_store")

	var save_orphan_r_phase28d = SaveSystem.capture("convenience_store", 300.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_orphan_r_phase28d):
		printerr("FAIL 28-D: write_slot failed for the Reclaim orphan save!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	var main_orphan_r_phase28d = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_orphan_r_phase28d)
	await get_tree().process_frame

	if not main_orphan_r_phase28d.load_game_slot(TEST_SCRATCH_SAVE_SLOT):
		printerr("FAIL 28-D: load_game_slot failed for the Reclaim orphan save!")
		get_tree().quit(1)
		return
	await get_tree().process_frame
	await get_tree().process_frame

	if main_orphan_r_phase28d.get_current_scene_id() != "datacenter_backup_core":
		printerr("FAIL 28-D: an orphaned ending_route_reclaim save (route set, not played, saved outside the sequence) should be rescued back to datacenter_backup_core regardless of the saved scene, got: ", main_orphan_r_phase28d.get_current_scene_id())
		get_tree().quit(1)
		return
	var orphan_core_lvl_r_phase28d = main_orphan_r_phase28d.world_root.get_children()[-1]
	if not orphan_core_lvl_r_phase28d._reclaim_active:
		printerr("FAIL 28-D: orphan rescue should auto-resume the Reclaim sequence at station 1!")
		get_tree().quit(1)
		return
	print("PASS 28-D: orphan Reclaim save (route set, not played, saved in convenience_store) is rescued back to datacenter_backup_core and auto-resumes station 1.")

	if is_instance_valid(main_orphan_r_phase28d):
		main_orphan_r_phase28d.free()
	await get_tree().process_frame
	GameState.reset_for_new_game()

	GameState.set_flag("ending_route_protect", true)
	GameState.mark_scene_visited("collector_shop")

	var save_orphan_p_phase28d = SaveSystem.capture("collector_shop", 150.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_orphan_p_phase28d):
		printerr("FAIL 28-D: write_slot failed for the Protect orphan save!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	var main_orphan_p_phase28d = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_orphan_p_phase28d)
	await get_tree().process_frame

	if not main_orphan_p_phase28d.load_game_slot(TEST_SCRATCH_SAVE_SLOT):
		printerr("FAIL 28-D: load_game_slot failed for the Protect orphan save!")
		get_tree().quit(1)
		return
	await get_tree().process_frame
	await get_tree().process_frame

	if main_orphan_p_phase28d.get_current_scene_id() != "datacenter_backup_core":
		printerr("FAIL 28-D: an orphaned ending_route_protect save (route set, not played, saved outside the sequence) should be rescued back to datacenter_backup_core regardless of the saved scene, got: ", main_orphan_p_phase28d.get_current_scene_id())
		get_tree().quit(1)
		return
	var orphan_core_lvl_p_phase28d = main_orphan_p_phase28d.world_root.get_children()[-1]
	if not orphan_core_lvl_p_phase28d._protect_active:
		printerr("FAIL 28-D: orphan rescue should auto-resume the Protect sequence at station 1!")
		get_tree().quit(1)
		return
	print("PASS 28-D: orphan Protect save (route set, not played, saved in collector_shop) is rescued back to datacenter_backup_core and auto-resumes station 1.")

	if is_instance_valid(main_orphan_p_phase28d):
		main_orphan_p_phase28d.free()
	await get_tree().process_frame
	GameState.reset_for_new_game()

	# 控制組：沒有任何 pending ending route 的一般存檔不應被誤判為孤兒檔
	GameState.mark_scene_visited("convenience_store")
	var save_control_phase28d = SaveSystem.capture("convenience_store", 300.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_control_phase28d):
		printerr("FAIL 28-D: write_slot failed for the control (no ending route) save!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	var main_control_phase28d = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_control_phase28d)
	await get_tree().process_frame

	if not main_control_phase28d.load_game_slot(TEST_SCRATCH_SAVE_SLOT):
		printerr("FAIL 28-D: load_game_slot failed for the control save!")
		get_tree().quit(1)
		return
	await get_tree().process_frame

	if main_control_phase28d.get_current_scene_id() != "convenience_store":
		printerr("FAIL 28-D: a save with no ending route flags set must NOT be redirected by the orphan-rescue check, got: ", main_control_phase28d.get_current_scene_id())
		get_tree().quit(1)
		return
	print("PASS 28-D: a save with no pending ending route loads normally into its saved scene (orphan-rescue check does not false-positive).")

	if is_instance_valid(main_control_phase28d):
		main_control_phase28d.free()
	await get_tree().process_frame
	GameState.reset_for_new_game()
	if dir and dir.file_exists(TEST_SCRATCH_SAVE_FILE):
		dir.remove(TEST_SCRATCH_SAVE_FILE)

	# ---- Test 4: 回歸 Phase 1~27 不退化（含 28 改動觸及的 4 個場景之原有 entry point）----
	var main_inst_phase28d_r = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_inst_phase28d_r)
	await get_tree().process_frame

	main_inst_phase28d_r.transition_to("apartment", "wake_bed")
	await get_tree().process_frame
	if main_inst_phase28d_r.get_current_scene_id() != "apartment":
		printerr("FAIL 28-D: apartment:wake_bed (原開場入口) should still work after Phase 28 changes!")
		get_tree().quit(1)
		return

	main_inst_phase28d_r.transition_to("apartment_entrance", "from_apartment")
	await get_tree().process_frame
	if main_inst_phase28d_r.get_current_scene_id() != "apartment_entrance":
		printerr("FAIL 28-D: apartment_entrance:from_apartment (原有入口) should still work after Phase 28 changes!")
		get_tree().quit(1)
		return

	main_inst_phase28d_r.transition_to("subway_station", "from_street")
	await get_tree().process_frame
	if main_inst_phase28d_r.get_current_scene_id() != "subway_station":
		printerr("FAIL 28-D: subway_station:from_street (原有入口) should still work after Phase 28 changes!")
		get_tree().quit(1)
		return

	main_inst_phase28d_r.transition_to("underground_settlement", "from_subway")
	await get_tree().process_frame
	if main_inst_phase28d_r.get_current_scene_id() != "underground_settlement":
		printerr("FAIL 28-D: underground_settlement:from_subway (原有入口) should still work after Phase 28 changes!")
		get_tree().quit(1)
		return

	main_inst_phase28d_r.transition_to("datacenter_entrance", "from_nightclub")
	await get_tree().process_frame
	if main_inst_phase28d_r.get_current_scene_id() != "datacenter_entrance":
		printerr("FAIL 28-D: datacenter_entrance (25 travel gate) should still be reachable after Phase 28 changes!")
		get_tree().quit(1)
		return

	main_inst_phase28d_r.transition_to("datacenter_backup", "from_entrance")
	await get_tree().process_frame
	if main_inst_phase28d_r.get_current_scene_id() != "datacenter_backup":
		printerr("FAIL 28-D: datacenter_backup (25 門禁 gate 後動線) should still be reachable after Phase 28 changes!")
		get_tree().quit(1)
		return

	main_inst_phase28d_r.transition_to("datacenter_backup_core", "from_backup")
	await get_tree().process_frame
	if main_inst_phase28d_r.get_current_scene_id() != "datacenter_backup_core":
		printerr("FAIL 28-D: datacenter_backup_core (own_backup 三選掛點) should still be reachable after Phase 28 changes!")
		get_tree().quit(1)
		return

	main_inst_phase28d_r.transition_to("broadcast_station", "from_backup_core")
	await get_tree().process_frame
	if main_inst_phase28d_r.get_current_scene_id() != "broadcast_station":
		printerr("FAIL 28-D: broadcast_station (Phase 27 Expose 掛點) should still be reachable after Phase 28 changes!")
		get_tree().quit(1)
		return

	main_inst_phase28d_r.transition_to("tunnel_chase", "from_settlement")
	await get_tree().process_frame
	if main_inst_phase28d_r.get_current_scene_id() != "tunnel_chase":
		printerr("FAIL 28-D: tunnel_chase (Phase 24 追逐) should still be reachable after Phase 28 changes!")
		get_tree().quit(1)
		return

	main_inst_phase28d_r.transition_to("underground_settlement_right", "from_left")
	await get_tree().process_frame
	if main_inst_phase28d_r.get_current_scene_id() != "underground_settlement_right":
		printerr("FAIL 28-D: underground_settlement_right (聚落往返) should still be reachable after Phase 28 changes!")
		get_tree().quit(1)
		return

	if is_instance_valid(main_inst_phase28d_r):
		main_inst_phase28d_r.free()
	await get_tree().process_frame
	GameState.reset_for_new_game()

	print("PASS: Phase 28-D regression (Phase 1~27 core routes + the four Phase-28-touched scenes' original entry points intact) and save/load guardrails (two-flag round-trip + pre-choice save reaches all three endings end-to-end + orphan-route rescue back to station 1 + non-orphan saves unaffected) verified.")

