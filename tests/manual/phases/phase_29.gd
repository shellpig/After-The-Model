extends "res://tests/manual/phases/phase_30a.gd"

func _run_phase_29() -> void:
	# ===================== Phase 29: Expose 結局三判定序列 =====================
	print("--- Phase 29: Expose 結局三判定序列 ---")

	# ---- Test 1: 經濟補正與判定矩陣（獨立輕量實例）----
	# 門檻為 3，檢驗四個判定分支組合
	# 組合 1: 未清洗 + trace < 3 -> A
	GameState.reset_for_new_game()
	GameState.set_flag("expose_upload_cleaned", false)
	GameState.set_flag("expose_upload_done", true)
	GameState.add_trace(2)
	var lvl_phase29_a = load("res://scenes/levels/broadcast/broadcast_station.tscn").instantiate()
	add_child(lvl_phase29_a)
	await get_tree().process_frame
	if lvl_phase29_a._expose_verdict != "a":
		printerr("FAIL 29-A: expected verdict a, got: ", lvl_phase29_a._expose_verdict)
		get_tree().quit(1)
		return
	lvl_phase29_a.free()
	await get_tree().process_frame

	# 組合 2: 已清洗 + trace < 3 -> B (29-B 實作)
	GameState.reset_for_new_game()
	GameState.set_flag("expose_upload_cleaned", true)
	GameState.set_flag("expose_upload_done", true)
	GameState.add_trace(2)
	var lvl_phase29_b = load("res://scenes/levels/broadcast/broadcast_station.tscn").instantiate()
	add_child(lvl_phase29_b)
	await get_tree().process_frame
	if lvl_phase29_b._expose_verdict != "b":
		printerr("FAIL 29-B: expected verdict b, got: ", lvl_phase29_b._expose_verdict)
		get_tree().quit(1)
		return
	lvl_phase29_b.free()
	await get_tree().process_frame

	# 組合 3: 未清洗 + trace >= 3 -> C
	GameState.reset_for_new_game()
	GameState.set_flag("expose_upload_cleaned", false)
	GameState.set_flag("expose_upload_done", true)
	GameState.add_trace(3)
	var lvl_phase29_c1 = load("res://scenes/levels/broadcast/broadcast_station.tscn").instantiate()
	add_child(lvl_phase29_c1)
	await get_tree().process_frame
	if lvl_phase29_c1._expose_verdict != "c":
		printerr("FAIL 29-C: expected verdict c for dirty+trace>=3, got: ", lvl_phase29_c1._expose_verdict)
		get_tree().quit(1)
		return
	lvl_phase29_c1.free()
	await get_tree().process_frame

	# 組合 4: 已清洗 + trace >= 3 -> C
	GameState.reset_for_new_game()
	GameState.set_flag("expose_upload_cleaned", true)
	GameState.set_flag("expose_upload_done", true)
	GameState.add_trace(3)
	var lvl_phase29_c2 = load("res://scenes/levels/broadcast/broadcast_station.tscn").instantiate()
	add_child(lvl_phase29_c2)
	await get_tree().process_frame
	if lvl_phase29_c2._expose_verdict != "c":
		printerr("FAIL 29-C: expected verdict c for cleaned+trace>=3, got: ", lvl_phase29_c2._expose_verdict)
		get_tree().quit(1)
		return
	lvl_phase29_c2.free()
	await get_tree().process_frame
	print("PASS 29: four-combination verdict matrix correct.")

	# ---- Test 2: B 分支全自動跑完演出與 played 旗標 ----
	GameState.reset_for_new_game()
	GameState.set_flag("expose_upload_cleaned", true)

	var main_inst_phase29 = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_inst_phase29)
	await get_tree().process_frame
	await get_tree().process_frame

	main_inst_phase29.transition_to("broadcast_station", "restore")
	var lvl_inst_phase29 = main_inst_phase29.world_root.get_children()[-1]
	await get_tree().process_frame
	await get_tree().process_frame

	if lvl_inst_phase29._expose_active:
		printerr("FAIL 29-B: expose sequence should not start before expose_upload_done is set!")
		get_tree().quit(1)
		return

	GameState.set_flag("expose_upload_done", true)
	await get_tree().process_frame
	await get_tree().process_frame

	if not lvl_inst_phase29._expose_active:
		printerr("FAIL 29-B: expose sequence did not start automatically!")
		get_tree().quit(1)
		return
	if SaveSystem.can_save_here:
		printerr("FAIL 29-B: SaveSystem should be locked during the sequence!")
		get_tree().quit(1)
		return
	if not main_inst_phase29.game_ui.is_touch_toggle_blocked():
		printerr("FAIL 29-B: is_touch_toggle_blocked should be true during endings!")
		get_tree().quit(1)
		return
	var old_touch_enabled_phase29 = TouchControls.touch_buttons_enabled
	TouchControls.touch_buttons_enabled = true
	TouchControls._update_dynamic_button_visibility()
	if TouchControls.get_node("Control/Menus/BtnBag").visible:
		printerr("FAIL 29-B: Bag button should not be visible when touch toggle is blocked!")
		get_tree().quit(1)
		return
	TouchControls.touch_buttons_enabled = old_touch_enabled_phase29
	TouchControls._update_dynamic_button_visibility()

	var frames_phase29 := 0
	while lvl_inst_phase29._expose_active and frames_phase29 < 100:
		await get_tree().process_frame
		frames_phase29 += 1

	if lvl_inst_phase29._expose_active:
		printerr("FAIL 29-B: expose sequence did not finish after 100 frames!")
		get_tree().quit(1)
		return

	if not GameState.get_flag("ending_expose_b_played", false):
		printerr("FAIL 29-B: ending_expose_b_played flag not set after B sequence finished!")
		get_tree().quit(1)
		return
	if SaveSystem.can_save_here:
		printerr("FAIL 29-B: SaveSystem should remain locked after Verdict B completes!")
		get_tree().quit(1)
		return
	print("PASS 29-B: Verdict B sequence auto-runs, locks save, and sets ending_expose_b_played.")

	if is_instance_valid(main_inst_phase29):
		main_inst_phase29.free()
	await get_tree().process_frame

	# ---- Test 3: A 分支全自動跑完演出與 played 旗標 ----
	GameState.reset_for_new_game()
	GameState.set_flag("expose_upload_cleaned", false)

	var main_inst_phase29_a = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_inst_phase29_a)
	await get_tree().process_frame
	await get_tree().process_frame

	main_inst_phase29_a.transition_to("broadcast_station", "restore")
	var lvl_inst_phase29_a = main_inst_phase29_a.world_root.get_children()[-1]
	await get_tree().process_frame
	await get_tree().process_frame

	GameState.set_flag("expose_upload_done", true)
	await get_tree().process_frame
	await get_tree().process_frame

	if not lvl_inst_phase29_a._expose_active:
		printerr("FAIL 29-A: Verdict A sequence did not start automatically!")
		get_tree().quit(1)
		return
	if SaveSystem.can_save_here:
		printerr("FAIL 29-A: SaveSystem should be locked during the sequence!")
		get_tree().quit(1)
		return
	if not main_inst_phase29_a.game_ui.is_touch_toggle_blocked():
		printerr("FAIL 29-A: is_touch_toggle_blocked should be true during endings!")
		get_tree().quit(1)
		return
	var old_touch_enabled_phase29_a = TouchControls.touch_buttons_enabled
	TouchControls.touch_buttons_enabled = true
	TouchControls._update_dynamic_button_visibility()
	if TouchControls.get_node("Control/Menus/BtnBag").visible:
		printerr("FAIL 29-A: Bag button should not be visible when touch toggle is blocked!")
		get_tree().quit(1)
		return
	TouchControls.touch_buttons_enabled = old_touch_enabled_phase29_a
	TouchControls._update_dynamic_button_visibility()

	var frames_phase29_a := 0
	while lvl_inst_phase29_a._expose_active and frames_phase29_a < 150:
		if main_inst_phase29_a.game_ui.is_photo_viewer_open():
			main_inst_phase29_a.game_ui.close_photo_viewer()
		await get_tree().process_frame
		frames_phase29_a += 1

	if lvl_inst_phase29_a._expose_active:
		printerr("FAIL 29-A: Verdict A sequence did not finish after 150 frames!")
		get_tree().quit(1)
		return

	if not GameState.get_flag("ending_expose_a_played", false):
		printerr("FAIL 29-A: ending_expose_a_played flag not set after A sequence finished!")
		get_tree().quit(1)
		return
	if SaveSystem.can_save_here:
		printerr("FAIL 29-A: SaveSystem should remain locked after Verdict A completes!")
		get_tree().quit(1)
		return
	print("PASS 29-A: Verdict A sequence auto-runs, locks save, handles CG, and sets ending_expose_a_played.")

	if is_instance_valid(main_inst_phase29_a):
		main_inst_phase29_a.free()
	await get_tree().process_frame

	# ---- Test 4: C 分支全自動跑完演出與 played 旗標 ----
	GameState.reset_for_new_game()
	GameState.add_trace(3)

	var main_inst_phase29_c = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_inst_phase29_c)
	await get_tree().process_frame
	await get_tree().process_frame

	main_inst_phase29_c.transition_to("broadcast_station", "restore")
	var lvl_inst_phase29_c = main_inst_phase29_c.world_root.get_children()[-1]
	await get_tree().process_frame
	await get_tree().process_frame

	GameState.set_flag("expose_upload_done", true)
	await get_tree().process_frame
	await get_tree().process_frame

	if not lvl_inst_phase29_c._expose_active:
		printerr("FAIL 29-C: Verdict C sequence did not start automatically!")
		get_tree().quit(1)
		return
	if SaveSystem.can_save_here:
		printerr("FAIL 29-C: SaveSystem should be locked during the sequence!")
		get_tree().quit(1)
		return
	if not main_inst_phase29_c.game_ui.is_touch_toggle_blocked():
		printerr("FAIL 29-C: is_touch_toggle_blocked should be true during endings!")
		get_tree().quit(1)
		return
	var old_touch_enabled_phase29_c = TouchControls.touch_buttons_enabled
	TouchControls.touch_buttons_enabled = true
	TouchControls._update_dynamic_button_visibility()
	if TouchControls.get_node("Control/Menus/BtnBag").visible:
		printerr("FAIL 29-C: Bag button should not be visible when touch toggle is blocked!")
		get_tree().quit(1)
		return
	TouchControls.touch_buttons_enabled = old_touch_enabled_phase29_c
	TouchControls._update_dynamic_button_visibility()

	var frames_phase29_c := 0
	while lvl_inst_phase29_c._expose_active and frames_phase29_c < 250:
		await get_tree().process_frame
		frames_phase29_c += 1

	if lvl_inst_phase29_c._expose_active:
		printerr("FAIL 29-C: Verdict C sequence did not finish after 250 frames!")
		get_tree().quit(1)
		return

	if not GameState.get_flag("ending_expose_c_played", false):
		printerr("FAIL 29-C: ending_expose_c_played flag not set after C sequence finished!")
		get_tree().quit(1)
		return
	if SaveSystem.can_save_here:
		printerr("FAIL 29-C: SaveSystem should remain locked after Verdict C completes!")
		get_tree().quit(1)
		return
	print("PASS 29-C: Verdict C sequence auto-runs, locks save, fades to black, and sets ending_expose_c_played.")

	if is_instance_valid(main_inst_phase29_c):
		main_inst_phase29_c.free()
	await get_tree().process_frame

	# ---- Test 5: Expose 孤兒檔救援 ----
	GameState.reset_for_new_game()
	GameState.set_flag("expose_upload_done", true)
	GameState.set_flag("expose_upload_cleaned", false)
	GameState.add_trace(2) # Verdict A

	var save_orphan_phase29 = SaveSystem.capture("convenience_store", 300.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_orphan_phase29):
		printerr("FAIL 29-D: write_slot failed for the Expose orphan save!")
		get_tree().quit(1)
		return

	var main_orphan_phase29 = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_orphan_phase29)
	await get_tree().process_frame
	await get_tree().process_frame

	if not main_orphan_phase29.load_game_slot(TEST_SCRATCH_SAVE_SLOT):
		printerr("FAIL 29-D: load_game_slot failed for the Expose orphan save!")
		get_tree().quit(1)
		return

	await get_tree().process_frame
	await get_tree().process_frame

	if main_orphan_phase29.get_current_scene_id() != "broadcast_station":
		printerr("FAIL 29-D: an orphaned expose_upload_done save should be rescued to broadcast_station, got: ", main_orphan_phase29.get_current_scene_id())
		get_tree().quit(1)
		return

	var orphan_lvl_phase29 = main_orphan_phase29.world_root.get_children()[-1]
	if not orphan_lvl_phase29._expose_active:
		printerr("FAIL 29-D: orphan rescue should auto-resume the Expose sequence!")
		get_tree().quit(1)
		return
	if orphan_lvl_phase29._expose_verdict != "a":
		printerr("FAIL 29-D: expected verdict a, got: ", orphan_lvl_phase29._expose_verdict)
		get_tree().quit(1)
		return

	print("PASS 29-D: orphan Expose save is rescued back to broadcast_station and auto-resumes sequence.")

	if is_instance_valid(main_orphan_phase29):
		main_orphan_phase29.free()
	await get_tree().process_frame

	# ---- Test 6: 經濟補正與採集 trace 增長邏輯 ----
	for key in ["echo_clerk", "echo_song_rain_doesnt_stop", "echo_lu_family", "echo_settlement_erased", "echo_ada_reset", "echo_linfei"]:
		var echo_data = EchoDB.get_echo(key)
		if echo_data.get("trace_on_collect", 0) != 1:
			printerr("FAIL 29-A: echo ", key, " is missing trace_on_collect = 1!")
			get_tree().quit(1)
			return

	GameState.reset_for_new_game()
	var initial_trace_phase29 = GameState.get_trace()
	if initial_trace_phase29 != 0:
		printerr("FAIL 29-A: trace should be 0 on new game!")
		get_tree().quit(1)
		return

	var clerk_echo_phase29 = EchoDB.get_echo("echo_clerk")
	for seg in clerk_echo_phase29.get("segments", []):
		GameState.collect_echo_segment("echo_clerk", seg.get("id", ""))

	if GameState.get_trace() != 1:
		printerr("FAIL 29-A: trace should be 1 after collecting echo_clerk, got: ", GameState.get_trace())
		get_tree().quit(1)
		return

	for seg in clerk_echo_phase29.get("segments", []):
		GameState.collect_echo_segment("echo_clerk", seg.get("id", ""))
	if GameState.get_trace() != 1:
		printerr("FAIL 29-A: trace should not increase on duplicate collect, got: ", GameState.get_trace())
		get_tree().quit(1)
		return
	print("PASS 29-A: trace economic correction and collector increments verified.")

