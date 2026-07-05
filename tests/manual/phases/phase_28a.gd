extends "res://tests/manual/phases/phase_28bc.gd"

func _run_phase_28a() -> void:
	# ===================== Phase 28-A: Reclaim 結局三站序列 =====================
	print("--- Phase 28-A: Reclaim 結局三站序列 ---")

	# ---- Test 1: trace 高檔壓垮拍（獨立輕量實例，僅驗證 _reclaim_pages 選字）----
	# 門檻 2026-07-04 拍板 3；取恰等於門檻的邊界值驗 >= 判斷。
	GameState.reset_for_new_game()
	GameState.set_flag("ending_route_reclaim", true)
	GameState.add_trace(3)
	var core_inst_hi_phase28a = load("res://scenes/levels/datacenter_backup_core/datacenter_backup_core.tscn").instantiate()
	add_child(core_inst_hi_phase28a)
	await get_tree().process_frame
	if core_inst_hi_phase28a._reclaim_pages.size() != 6 or core_inst_hi_phase28a._reclaim_pages[5] != "MSG_EPILOGUE_RECLAIM_CRUSH_HIGH":
		printerr("FAIL 28-A: trace >= RECLAIM_CRUSH_TRACE_THRESHOLD should pick CRUSH_HIGH, got: ", core_inst_hi_phase28a._reclaim_pages)
		get_tree().quit(1)
		return
	print("PASS 28-A: trace >= RECLAIM_CRUSH_TRACE_THRESHOLD picks CRUSH_HIGH（兩處染色兩檔分派之一）.")
	core_inst_hi_phase28a.free()
	await get_tree().process_frame

	# ---- Test 2: 全鏈（main.tscn）站 1 觸發 gate + 五枚碎片頁序 + trace 低檔壓垮拍 + 序列站禁存 ----
	GameState.reset_for_new_game()

	var main_inst_phase28a = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_inst_phase28a)
	await get_tree().process_frame
	await get_tree().process_frame

	main_inst_phase28a.transition_to("datacenter_backup_core", "from_backup")
	var core_lvl_phase28a = main_inst_phase28a.world_root.get_children()[-1]
	await get_tree().process_frame
	await get_tree().process_frame

	if core_lvl_phase28a._reclaim_active:
		printerr("FAIL 28-A: reclaim sequence should not be active before ending_route_reclaim is set!")
		get_tree().quit(1)
		return

	GameState.set_flag("ending_route_reclaim", true)
	await get_tree().process_frame
	await get_tree().process_frame
	if not core_lvl_phase28a._reclaim_active:
		printerr("FAIL 28-A: reclaim sequence should auto-start (route 旗標分派) once ending_route_reclaim is set!")
		get_tree().quit(1)
		return
	if SaveSystem.can_save_here:
		printerr("FAIL 28-A: can_save_here should be false once the Reclaim sequence starts (序列站禁存)!")
		get_tree().quit(1)
		return

	var expect_fragment_pages_phase28a = [
		"MSG_EPILOGUE_RECLAIM_P1", "MSG_EPILOGUE_RECLAIM_P2", "MSG_EPILOGUE_RECLAIM_P3",
		"MSG_EPILOGUE_RECLAIM_P4", "MSG_EPILOGUE_RECLAIM_P5"
	]
	if core_lvl_phase28a._reclaim_pages.size() != 6:
		printerr("FAIL 28-A: expected 5 fragment pages + 1 crush page, got: ", core_lvl_phase28a._reclaim_pages)
		get_tree().quit(1)
		return
	for i in range(5):
		if core_lvl_phase28a._reclaim_pages[i] != expect_fragment_pages_phase28a[i]:
			printerr("FAIL 28-A: fragment page order mismatch at index ", i, ": ", core_lvl_phase28a._reclaim_pages)
			get_tree().quit(1)
			return
	if core_lvl_phase28a._reclaim_pages[5] != "MSG_EPILOGUE_RECLAIM_CRUSH_LOW":
		printerr("FAIL 28-A: trace below threshold should pick CRUSH_LOW, got: ", core_lvl_phase28a._reclaim_pages[5])
		get_tree().quit(1)
		return
	print("PASS 28-A: station 1 auto-starts on route flag (locks can_save_here); five-fragment page order correct; trace-low picks CRUSH_LOW.")

	# ---- Test 3: 六頁不可跳過、headless 自動翻頁播完 -> travel apartment_entrance:epilogue_wan ----
	var frames_waited_phase28a := 0
	while main_inst_phase28a.get_current_scene_id() == "datacenter_backup_core" and frames_waited_phase28a < 60:
		await get_tree().process_frame
		frames_waited_phase28a += 1
	if main_inst_phase28a.get_current_scene_id() != "apartment_entrance" or main_inst_phase28a.get_current_entry_point_id() != "epilogue_wan":
		printerr("FAIL 28-A: station 1 should auto-complete its six unskippable pages and travel to apartment_entrance:epilogue_wan, got scene=", main_inst_phase28a.get_current_scene_id(), " entry=", main_inst_phase28a.get_current_entry_point_id(), " after ", frames_waited_phase28a, " frames")
		get_tree().quit(1)
		return
	print("PASS 28-A: station 1 headless-auto-advances through all six unskippable pages and travels to apartment_entrance:epilogue_wan.")

	# ---- Test 4: 站 2 自動觸發（26-A NpcAutoDialogueArea 元件複用）+ 序列站禁存 ----
	# spawn 座標刻意疊在 WanEpilogueTriggerArea 碰撞範圍內（凍結期無自由走動），故經過前面
	# 幾個 await frame 的真實物理處理，body_entered 應已自動觸發過 wan_epilogue（非本測試手動模擬）。
	var entrance_lvl_phase28a = main_inst_phase28a.world_root.get_children()[-1]
	if not entrance_lvl_phase28a._reclaim_farewell_active:
		printerr("FAIL 28-A: entering apartment_entrance via epilogue_wan should arm _reclaim_farewell_active!")
		get_tree().quit(1)
		return
	if SaveSystem.can_save_here:
		printerr("FAIL 28-A: can_save_here should remain false at station 2 (序列站禁存)!")
		get_tree().quit(1)
		return

	var wan_trigger_phase28a = entrance_lvl_phase28a.get_node_or_null("Interactables/WanEpilogueTriggerArea")
	var wan_npc_phase28a = entrance_lvl_phase28a.get_node_or_null("Interactables/NpcWan")
	if wan_trigger_phase28a == null or wan_npc_phase28a == null:
		printerr("FAIL 28-A: apartment_entrance missing WanEpilogueTriggerArea/NpcWan node!")
		get_tree().quit(1)
		return

	if UIMode.get_mode() != UIMode.Mode.DIALOGUE or not GameState.get_flag("ending_reclaim_wan_farewell_seen", false):
		printerr("FAIL 28-A: WanEpilogueTriggerArea should have auto-fired wan_epilogue on spawn overlap (26-A pattern reused), UIMode=", UIMode.get_mode(), " seen_flag=", GameState.get_flag("ending_reclaim_wan_farewell_seen", false))
		get_tree().quit(1)
		return
	print("PASS 28-A: station 2 auto-trigger fires wan_epilogue on spawn overlap via NpcAutoDialogueArea (26-A pattern reused); can_save_here stays locked.")

	# 走完冷版兩拍（affinity_wan 預設 0 < 2）-> 對話應關閉回 UIMode.NONE
	main_inst_phase28a.game_ui.dialogue_confirm()
	main_inst_phase28a.game_ui.dialogue_confirm()
	if UIMode.get_mode() != UIMode.Mode.NONE:
		printerr("FAIL 28-A: two-beat cold farewell should close back to UIMode.NONE after two confirms, got mode=", UIMode.get_mode())
		get_tree().quit(1)
		return
	print("PASS 28-A: two-beat cold farewell (affinity_wan < 2) plays through and closes.")

	# ---- Test 5: wan_epilogue 對話樹 affinity_wan 兩檔分派（染色兩檔分派之二）----
	var wan_epilogue_tree_phase28a = DialogueDB.get_tree_for("wan_epilogue")
	if wan_epilogue_tree_phase28a.is_empty():
		printerr("FAIL 28-A: DialogueDB wan_epilogue tree not found!")
		get_tree().quit(1)
		return

	GameState.set_flag("ending_reclaim_wan_farewell_seen", false)
	var runner_cold_phase28a := DialogueRunner.new()
	runner_cold_phase28a.start(wan_epilogue_tree_phase28a)
	if runner_cold_phase28a._current_node_id != "reclaim_cold_p1":
		printerr("FAIL 28-A: affinity_wan < 2 should route to reclaim_cold_p1! Got: ", runner_cold_phase28a._current_node_id)
		get_tree().quit(1)
		return
	if not GameState.get_flag("ending_reclaim_wan_farewell_seen", false):
		printerr("FAIL 28-A: entering cold branch should set ending_reclaim_wan_farewell_seen (NpcAutoDialogueArea seen_flag)!")
		get_tree().quit(1)
		return
	runner_cold_phase28a.advance()
	if runner_cold_phase28a._current_node_id != "reclaim_cold_p2":
		printerr("FAIL 28-A: cold branch should chain reclaim_cold_p1 -> reclaim_cold_p2! Got: ", runner_cold_phase28a._current_node_id)
		get_tree().quit(1)
		return
	if not runner_cold_phase28a.current().get("is_terminal", false):
		printerr("FAIL 28-A: reclaim_cold_p2 should be the terminal beat of the cold farewell!")
		get_tree().quit(1)
		return
	print("PASS 28-A: affinity_wan < 2 routes to two-beat cold farewell + sets seen_flag on first beat.")

	GameState.set_flag("ending_reclaim_wan_farewell_seen", false)
	GameState.set_flag("affinity_wan", 2)
	var runner_warm_phase28a := DialogueRunner.new()
	runner_warm_phase28a.start(wan_epilogue_tree_phase28a)
	if runner_warm_phase28a._current_node_id != "reclaim_warm_p1":
		printerr("FAIL 28-A: affinity_wan >= 2 should route to reclaim_warm_p1! Got: ", runner_warm_phase28a._current_node_id)
		get_tree().quit(1)
		return
	runner_warm_phase28a.advance()
	if runner_warm_phase28a._current_node_id != "reclaim_warm_p2":
		printerr("FAIL 28-A: warm branch should chain p1 -> p2! Got: ", runner_warm_phase28a._current_node_id)
		get_tree().quit(1)
		return
	runner_warm_phase28a.advance()
	if runner_warm_phase28a._current_node_id != "reclaim_warm_p3":
		printerr("FAIL 28-A: warm branch should chain p2 -> p3! Got: ", runner_warm_phase28a._current_node_id)
		get_tree().quit(1)
		return
	if not runner_warm_phase28a.current().get("is_terminal", false):
		printerr("FAIL 28-A: reclaim_warm_p3 should be the terminal beat of the warm farewell!")
		get_tree().quit(1)
		return
	print("PASS 28-A: affinity_wan >= 2 routes to three-beat warm farewell (兩處染色兩檔分派之二).")

	# ---- Test 6: farewell 讀完 -> CG 開啟；關閉 CG -> 永久移除晚 + travel apartment:epilogue_home ----
	GameState.set_flag("ending_reclaim_wan_farewell_seen", true)
	entrance_lvl_phase28a._update_reclaim_farewell()
	if not entrance_lvl_phase28a._reclaim_cg_shown:
		printerr("FAIL 28-A: CG should open once ending_reclaim_wan_farewell_seen is set and UIMode is NONE!")
		get_tree().quit(1)
		return
	if not main_inst_phase28a.game_ui.is_photo_viewer_open():
		printerr("FAIL 28-A: photo_viewer should be visible after the farewell CG opens!")
		get_tree().quit(1)
		return
	print("PASS 28-A: CG opens once the farewell dialogue's seen_flag is set and world is idle.")

	main_inst_phase28a.game_ui.close_photo_viewer()
	entrance_lvl_phase28a._update_reclaim_farewell()
	if not wan_npc_phase28a.is_queued_for_deletion() or not wan_trigger_phase28a.is_queued_for_deletion():
		printerr("FAIL 28-A: NpcWan/WanEpilogueTriggerArea should be permanently removed once the farewell CG closes!")
		get_tree().quit(1)
		return

	await get_tree().process_frame
	await get_tree().process_frame
	if main_inst_phase28a.get_current_scene_id() != "apartment" or main_inst_phase28a.get_current_entry_point_id() != "epilogue_home":
		printerr("FAIL 28-A: station 2 should travel to apartment:epilogue_home once the CG closes, got scene=", main_inst_phase28a.get_current_scene_id(), " entry=", main_inst_phase28a.get_current_entry_point_id())
		get_tree().quit(1)
		return
	print("PASS 28-A: closing the CG permanently removes Wan and travels to apartment:epilogue_home.")

	# ---- Test 7: 站 3 公寓痕跡拍 -> ending_reclaim_played 旗標寫入 + 序列站禁存 + 靜止停 ----
	if not GameState.get_flag("ending_reclaim_played", false):
		printerr("FAIL 28-A: entering apartment via epilogue_home with ending_route_reclaim set should set ending_reclaim_played (旗標寫入)!")
		get_tree().quit(1)
		return
	if SaveSystem.can_save_here:
		printerr("FAIL 28-A: can_save_here should be false at station 3 (序列站禁存)!")
		get_tree().quit(1)
		return
	if UIMode.get_mode() != UIMode.Mode.MESSAGE:
		printerr("FAIL 28-A: station 3 should freeze on the final trace MessageBox (靜止停，30-A 接手點)!")
		get_tree().quit(1)
		return
	print("PASS 28-A: station 3 sets ending_reclaim_played, locks can_save_here, and freezes on the final MessageBox.")

	if is_instance_valid(main_inst_phase28a):
		main_inst_phase28a.free()
	await get_tree().process_frame
	UIMode.set_mode(UIMode.Mode.NONE)
	GameState.reset_for_new_game()

	print("PASS: Phase 28-A Reclaim ending sequence (own_backup route dispatch reused unmodified + trace/affinity two-tier branching + three-station can_save_here lock + ending_reclaim_played flag write) verified.")

