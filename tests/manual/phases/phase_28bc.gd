extends "res://tests/manual/phases/phase_28d.gd"

func _run_phase_28bc() -> void:
	# ===================== Phase 28-B/28-C: Protect 結局三站序列（含中間站分岔）=====================
	print("--- Phase 28-B/28-C: Protect 結局三站序列 ---")

	# ---- Test 1: wan_epilogue 對話樹 Protect 分派（覆蓋 28-A 未觸及的 route_protect 分支）----
	GameState.reset_for_new_game()
	var wan_epilogue_tree_phase28b = DialogueDB.get_tree_for("wan_epilogue")
	if wan_epilogue_tree_phase28b.is_empty():
		printerr("FAIL 28-B: DialogueDB wan_epilogue tree not found!")
		get_tree().quit(1)
		return

	GameState.set_flag("ending_route_protect", true)
	var runner_protect_phase28b := DialogueRunner.new()
	runner_protect_phase28b.start(wan_epilogue_tree_phase28b)
	if runner_protect_phase28b._current_node_id != "protect_p1":
		printerr("FAIL 28-B: ending_route_protect should route start -> protect_p1! Got: ", runner_protect_phase28b._current_node_id)
		get_tree().quit(1)
		return
	if not GameState.get_flag("ending_protect_wan_seen", false):
		printerr("FAIL 28-B: entering protect_p1 should set ending_protect_wan_seen (NpcAutoDialogueArea seen_flag)!")
		get_tree().quit(1)
		return
	runner_protect_phase28b.advance()
	if runner_protect_phase28b._current_node_id != "protect_p2":
		printerr("FAIL 28-B: protect_p1 should chain to protect_p2! Got: ", runner_protect_phase28b._current_node_id)
		get_tree().quit(1)
		return
	runner_protect_phase28b.advance()
	if runner_protect_phase28b._current_node_id != "protect_p3":
		printerr("FAIL 28-B: protect_p2 should chain to protect_p3! Got: ", runner_protect_phase28b._current_node_id)
		get_tree().quit(1)
		return
	if not runner_protect_phase28b.current().get("is_terminal", false):
		printerr("FAIL 28-B: protect_p3 should be the terminal beat of the fixed three-line farewell!")
		get_tree().quit(1)
		return
	if runner_protect_phase28b.pending_travel.get("scene_id", "") != "apartment" or runner_protect_phase28b.pending_travel.get("entry_point_id", "") != "epilogue_home":
		printerr("FAIL 28-B: protect_p3's effect should queue travel to apartment:epilogue_home! Got: ", runner_protect_phase28b.pending_travel)
		get_tree().quit(1)
		return
	print("PASS 28-B: wan_epilogue dialogue tree routes ending_route_protect to the fixed three-line farewell (protect_p1 -> p2 -> p3) and queues travel to apartment:epilogue_home.")

	GameState.reset_for_new_game()

	# ---- Test 2: 全鏈（main.tscn）站 1 短刪除演出（與 Reclaim 五頁不對稱）+ 序列站禁存 ----
	var main_inst_phase28b = load("res://scenes/main/main.tscn").instantiate()
	add_child(main_inst_phase28b)
	await get_tree().process_frame
	await get_tree().process_frame

	main_inst_phase28b.transition_to("datacenter_backup_core", "from_backup")
	var core_lvl_phase28b = main_inst_phase28b.world_root.get_children()[-1]
	await get_tree().process_frame
	await get_tree().process_frame

	if core_lvl_phase28b._protect_active:
		printerr("FAIL 28-B: protect sequence should not be active before ending_route_protect is set!")
		get_tree().quit(1)
		return

	GameState.set_flag("ending_route_protect", true)
	await get_tree().process_frame
	await get_tree().process_frame
	if not core_lvl_phase28b._protect_active:
		printerr("FAIL 28-B: protect sequence should auto-start (route 旗標分派) once ending_route_protect is set!")
		get_tree().quit(1)
		return
	if SaveSystem.can_save_here:
		printerr("FAIL 28-B: can_save_here should be false once the Protect sequence starts (序列站禁存)!")
		get_tree().quit(1)
		return
	if core_lvl_phase28b.PROTECT_DELETE_PAGES.size() != 2 or core_lvl_phase28b.PROTECT_DELETE_PAGES[0] != "MSG_EPILOGUE_PROTECT_P1" or core_lvl_phase28b.PROTECT_DELETE_PAGES[1] != "MSG_EPILOGUE_PROTECT_P2":
		printerr("FAIL 28-B: station 1 should play exactly two short delete pages (刻意與 Reclaim 五頁不對稱), got: ", core_lvl_phase28b.PROTECT_DELETE_PAGES)
		get_tree().quit(1)
		return
	print("PASS 28-B: station 1 auto-starts on route flag (locks can_save_here); short two-page delete sequence confirmed (Reclaim 五頁不對稱).")

	# ---- Test 3: headless 自動翻頁播完兩頁 -> 依 cen_voiceprint_exposed（預設 false）travel subway_station:epilogue_cen ----
	var frames_waited_phase28b := 0
	while main_inst_phase28b.get_current_scene_id() == "datacenter_backup_core" and frames_waited_phase28b < 60:
		await get_tree().process_frame
		frames_waited_phase28b += 1
	if main_inst_phase28b.get_current_scene_id() != "subway_station" or main_inst_phase28b.get_current_entry_point_id() != "epilogue_cen":
		printerr("FAIL 28-B: station 1 should auto-complete its two pages and travel to subway_station:epilogue_cen (not-B branch, cen_voiceprint_exposed default false), got scene=", main_inst_phase28b.get_current_scene_id(), " entry=", main_inst_phase28b.get_current_entry_point_id(), " after ", frames_waited_phase28b, " frames")
		get_tree().quit(1)
		return
	print("PASS 28-B: station 1 headless-auto-advances through both short pages and dispatches 28-C not-B branch to subway_station:epilogue_cen.")

	# ---- Test 4: 28-C not-B 中間站 — 復駛廣播 -> 小岑過閘台詞 -> CG -> 移除 + travel ----
	var subway_lvl_phase28c = main_inst_phase28b.world_root.get_children()[-1]
	if not subway_lvl_phase28c._cen_epilogue_active:
		printerr("FAIL 28-C: entering subway_station via epilogue_cen should arm _cen_epilogue_active!")
		get_tree().quit(1)
		return
	if SaveSystem.can_save_here:
		printerr("FAIL 28-C: can_save_here should remain false at the 28-C middle station (序列站禁存)!")
		get_tree().quit(1)
		return

	var cen_frames_waited_phase28c := 0
	while subway_lvl_phase28c._cen_epilogue_stage != 2 and cen_frames_waited_phase28c < 30:
		await get_tree().process_frame
		cen_frames_waited_phase28c += 1
	if subway_lvl_phase28c._cen_epilogue_stage != 2:
		printerr("FAIL 28-C: cen epilogue should progress to stage 2 (CG) after the broadcast + line pages, stuck at stage=", subway_lvl_phase28c._cen_epilogue_stage)
		get_tree().quit(1)
		return
	var cen_node_phase28c = subway_lvl_phase28c.get_node_or_null("NpcCenEpilogue")
	if cen_node_phase28c == null or not cen_node_phase28c.visible:
		printerr("FAIL 28-C: NpcCenEpilogue sprite should be visible once the resume/line pages have played!")
		get_tree().quit(1)
		return
	if not main_inst_phase28b.game_ui.is_photo_viewer_open():
		printerr("FAIL 28-C: photo_viewer should be visible once cen epilogue reaches stage 2 (cg_gate_pass)!")
		get_tree().quit(1)
		return
	print("PASS 28-C: not-B branch plays resume broadcast + Cen's line, shows the idle sprite, and opens the cg_gate_pass CG.")

	main_inst_phase28b.game_ui.close_photo_viewer()
	await get_tree().process_frame
	await get_tree().process_frame
	if not GameState.get_flag("ending_protect_cen_seen", false) or not cen_node_phase28c.is_queued_for_deletion():
		printerr("FAIL 28-C: closing the CG should set ending_protect_cen_seen and permanently remove NpcCenEpilogue (頭也不回走了)!")
		get_tree().quit(1)
		return
	if main_inst_phase28b.get_current_scene_id() != "apartment_entrance" or main_inst_phase28b.get_current_entry_point_id() != "epilogue_wan":
		printerr("FAIL 28-C: closing the CG should travel to apartment_entrance:epilogue_wan, got scene=", main_inst_phase28b.get_current_scene_id(), " entry=", main_inst_phase28b.get_current_entry_point_id())
		get_tree().quit(1)
		return
	print("PASS 28-C: closing the CG marks the beat seen, removes Cen permanently, and travels to apartment_entrance:epilogue_wan.")

	# ---- Test 5: 站 3 晚固定三句台詞（不消失）-> travel apartment:epilogue_home ----
	var entrance_lvl_phase28b = main_inst_phase28b.world_root.get_children()[-1]
	if SaveSystem.can_save_here:
		printerr("FAIL 28-B: can_save_here should remain false at station 3 (序列站禁存)!")
		get_tree().quit(1)
		return
	var wan_protect_trigger_phase28b = entrance_lvl_phase28b.get_node_or_null("Interactables/WanEpilogueProtectTriggerArea")
	var wan_npc_phase28b = entrance_lvl_phase28b.get_node_or_null("Interactables/NpcWan")
	if wan_protect_trigger_phase28b == null or wan_npc_phase28b == null:
		printerr("FAIL 28-B: apartment_entrance missing WanEpilogueProtectTriggerArea/NpcWan node!")
		get_tree().quit(1)
		return
	if UIMode.get_mode() != UIMode.Mode.DIALOGUE:
		printerr("FAIL 28-B: WanEpilogueProtectTriggerArea should have auto-fired wan_epilogue on spawn overlap, UIMode=", UIMode.get_mode())
		get_tree().quit(1)
		return
	print("PASS 28-B: station 3 auto-trigger fires wan_epilogue (Protect route) on spawn overlap; can_save_here stays locked.")

	# 三句固定台詞（protect_p1 -> p2 -> p3 皆非選項節點）需 3 次 confirm 才會關閉對話；
	# 第 3 次 confirm 會直接觸發 protect_p3 的 travel effect（同一 frame 內同步切場景），
	# 故「晚不消失」需在最後一句關閉之前檢查——切場景後整棵舊場景樹（含 NpcWan）本就會被
	# queue_free()，那是任何場景轉場都有的實作細節，不是 Reclaim/Protect 的敘事差異本身。
	main_inst_phase28b.game_ui.dialogue_confirm()
	main_inst_phase28b.game_ui.dialogue_confirm()
	if not is_instance_valid(wan_npc_phase28b) or wan_npc_phase28b.is_queued_for_deletion():
		printerr("FAIL 28-B: Protect farewell must NOT remove NpcWan before the final line (晚不消失，留在原地) — Reclaim/Protect asymmetry!")
		get_tree().quit(1)
		return
	main_inst_phase28b.game_ui.dialogue_confirm()
	await get_tree().process_frame
	await get_tree().process_frame
	if UIMode.get_mode() == UIMode.Mode.DIALOGUE:
		printerr("FAIL 28-B: three-beat fixed farewell should close after three confirms (its travel effect chains straight into station 3b's frozen MessageBox, see test 6 below), still stuck in DIALOGUE mode!")
		get_tree().quit(1)
		return
	if main_inst_phase28b.get_current_scene_id() != "apartment" or main_inst_phase28b.get_current_entry_point_id() != "epilogue_home":
		printerr("FAIL 28-B: closing the fixed farewell should travel to apartment:epilogue_home, got scene=", main_inst_phase28b.get_current_scene_id(), " entry=", main_inst_phase28b.get_current_entry_point_id())
		get_tree().quit(1)
		return
	print("PASS 28-B: three-beat fixed farewell plays through, Wan stays present through all three lines (unlike Reclaim's mid-sequence removal), and travels to apartment:epilogue_home.")

	# ---- Test 6: 站 3b 公寓收尾 -> ending_protect_played 旗標寫入 + 序列站禁存 + 靜止停 ----
	if not GameState.get_flag("ending_protect_played", false):
		printerr("FAIL 28-B: entering apartment via epilogue_home with ending_route_protect set should set ending_protect_played (旗標寫入)!")
		get_tree().quit(1)
		return
	if SaveSystem.can_save_here:
		printerr("FAIL 28-B: can_save_here should be false at station 3b (序列站禁存)!")
		get_tree().quit(1)
		return
	if UIMode.get_mode() != UIMode.Mode.MESSAGE:
		printerr("FAIL 28-B: station 3b should freeze on the final home MessageBox (靜止停，30-A 接手點)!")
		get_tree().quit(1)
		return
	print("PASS 28-B: station 3b sets ending_protect_played, locks can_save_here, and freezes on the final MessageBox.")

	if is_instance_valid(main_inst_phase28b):
		main_inst_phase28b.free()
	await get_tree().process_frame
	UIMode.set_mode(UIMode.Mode.NONE)
	GameState.reset_for_new_game()

	# ---- Test 7: 28-C Branch B（cen_voiceprint_exposed == true）中間站分岔 — 聚落空帳篷 + 伍姐沉默搖頭 ----
	GameState.set_flag("ending_route_protect", true)
	GameState.set_flag("cen_voiceprint_exposed", true)
	# 本測試不經由 Main，直接掛裸場景；_start_wu_epilogue() 靠 @onready game_ui 驅動
	# begin_message/is_message_finished()，故需先在樹裡放一個真的 GameUI（8-C 既有慣例）。
	var ui_instance_phase28c = load("res://scenes/ui/game_ui.tscn").instantiate()
	add_child(ui_instance_phase28c)
	await get_tree().process_frame

	var settlement_inst_phase28c = load("res://scenes/levels/underground_settlement/underground_settlement.tscn").instantiate()
	settlement_inst_phase28c.prepare_entry_point("epilogue_settlement")
	var wu_travel_phase28c := {}
	settlement_inst_phase28c.scene_transition_requested.connect(func(scene_id, entry_point_id, _payload):
		wu_travel_phase28c.clear()
		wu_travel_phase28c.merge({"scene_id": scene_id, "entry_point_id": entry_point_id})
	)
	add_child(settlement_inst_phase28c)
	await get_tree().process_frame
	await get_tree().process_frame

	if not settlement_inst_phase28c._wu_epilogue_active:
		printerr("FAIL 28-C: Branch B (cen_voiceprint_exposed==true) should arm _wu_epilogue_active on epilogue_settlement entry!")
		get_tree().quit(1)
		return
	if SaveSystem.can_save_here:
		printerr("FAIL 28-C: can_save_here should be false at the Branch B middle station (序列站禁存)!")
		get_tree().quit(1)
		return

	var wu_frames_waited_phase28c := 0
	while wu_travel_phase28c.is_empty() and wu_frames_waited_phase28c < 30:
		await get_tree().process_frame
		wu_frames_waited_phase28c += 1
	if wu_travel_phase28c.get("scene_id", "") != "apartment_entrance" or wu_travel_phase28c.get("entry_point_id", "") != "epilogue_wan":
		printerr("FAIL 28-C: Branch B (empty tent + Wu's silent head-shake) should travel to apartment_entrance:epilogue_wan, got: ", wu_travel_phase28c)
		get_tree().quit(1)
		return
	if not GameState.get_flag("ending_protect_wu_seen", false):
		printerr("FAIL 28-C: Branch B sequence should set ending_protect_wu_seen once played!")
		get_tree().quit(1)
		return
	print("PASS 28-C: Branch B (cen_voiceprint_exposed==true) plays the empty-tent + Wu silent head-shake beats (no dialogue tree, no CG) and travels to apartment_entrance:epilogue_wan.")

	if is_instance_valid(settlement_inst_phase28c):
		settlement_inst_phase28c.free()
	if is_instance_valid(ui_instance_phase28c):
		ui_instance_phase28c.free()
	await get_tree().process_frame
	GameState.reset_for_new_game()

	print("PASS: Phase 28-B/28-C Protect ending sequence (short asymmetric delete pages + branch-correct 28-C middle station dispatch for both cen_voiceprint_exposed states + fixed non-disappearing farewell + ending_protect_played flag write, three-station can_save_here lock throughout) verified.")

