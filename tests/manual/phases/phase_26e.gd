extends "res://tests/manual/phases/phase_27a.gd"

func _run_phase_26e() -> void:
	# ===================== Phase 26-E: 回歸 + 存讀檔 + GUI =====================
	print("--- Phase 26-E: 回歸 + 存讀檔 + GUI ---")

	# 1. 四旗標存讀檔 round-trip
	GameState.reset_for_new_game()
	GameState.set_flag("wan_act4_pull_seen", true)
	GameState.set_flag("ada_final_words_seen", true)
	GameState.set_flag("mem_frag_chose_deletion", true)
	GameState.set_flag("stood_before_own_backup", true)
	GameState.mark_scene_visited("datacenter_backup_core")

	var save_dict_phase26e = SaveSystem.capture("datacenter_backup_core", 100.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_dict_phase26e):
		printerr("FAIL 26-E: SaveSystem.write_slot failed for Phase 26 flags!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()

	var main_scene_phase26e = load("res://scenes/main/main.tscn")
	var main_instance_phase26e = main_scene_phase26e.instantiate()
	add_child(main_instance_phase26e)
	await get_tree().process_frame

	if not main_instance_phase26e.load_game_slot(TEST_SCRATCH_SAVE_SLOT):
		printerr("FAIL 26-E: load_game_slot(scratch slot) failed to load Phase 26 save!")
		get_tree().quit(1)
		return
	await get_tree().process_frame

	if not GameState.get_flag("wan_act4_pull_seen", false) or not GameState.get_flag("ada_final_words_seen", false) or \
	   not GameState.get_flag("mem_frag_chose_deletion", false) or not GameState.get_flag("stood_before_own_backup", false):
		printerr("FAIL 26-E: four Phase 26 flags did not all survive save/load round-trip!")
		get_tree().quit(1)
		return

	if is_instance_valid(main_instance_phase26e):
		main_instance_phase26e.free()
	await get_tree().process_frame

	# 2. 26-A/B 一次性跨存讀不重播：旗標已跨存讀持久化，重進場景 Ada 不生成、晚觸發區不再自動觸發、路由已是 retalk
	var entrance_inst_phase26e = load("res://scenes/levels/datacenter_entrance/datacenter_entrance.tscn").instantiate()
	add_child(entrance_inst_phase26e)
	await get_tree().process_frame

	if entrance_inst_phase26e.get_node_or_null("Interactables/AdaNPC") != null or entrance_inst_phase26e.get_node_or_null("Interactables/AdaTriggerArea") != null:
		printerr("FAIL 26-E: Ada must stay permanently gone after cross-save/load (ada_final_words_seen persisted)!")
		get_tree().quit(1)
		return

	var wan_trigger_phase26e = entrance_inst_phase26e.get_node_or_null("Interactables/WanPullTriggerArea")
	var wan_npc_phase26e = entrance_inst_phase26e.get_node_or_null("Interactables/WanDatacenterNPC")
	if wan_trigger_phase26e == null or wan_npc_phase26e == null:
		printerr("FAIL 26-E: WanPullTriggerArea / WanDatacenterNPC missing after cross-save/load!")
		get_tree().quit(1)
		return

	var captured_wan_phase26e: Dictionary = {}
	entrance_inst_phase26e.interaction_requested.connect(func(data):
		captured_wan_phase26e.merge(data, true)
	)
	var fake_player_phase26e := Node2D.new()
	fake_player_phase26e.name = "Player"
	wan_trigger_phase26e._on_body_entered(fake_player_phase26e)
	if not captured_wan_phase26e.is_empty():
		printerr("FAIL 26-E: WanPullTriggerArea must not re-fire the auto-trigger after cross-save/load (wan_act4_pull_seen persisted)!")
		get_tree().quit(1)
		return

	var wan_dc_tree_phase26e = DialogueDB.get_tree_for("wan_datacenter")
	var runner_retalk_phase26e = DialogueRunner.new()
	runner_retalk_phase26e.start(wan_dc_tree_phase26e)
	if runner_retalk_phase26e.current().get("text", "") != "DLG_WAN_DATACENTER_RETALK_TEXT":
		printerr("FAIL 26-E: wan_datacenter should route to retalk after cross-save/load!")
		get_tree().quit(1)
		return

	fake_player_phase26e.free()
	entrance_inst_phase26e.free()
	await get_tree().process_frame

	# 3. 回歸：Phase 1~25 不退化（尤其 25 travel / 門禁 gate、戰鬥③ 抵達門後動線、24 追逐 / 攤牌、聚落往返）
	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)
	GameState.set_flag("seven_stopped_full", true)
	GameState.add_item("old_work_badge", 1)
	GameState.set_flag("read_old_work_order", true)

	var main_scene_phase26e_r = load("res://scenes/main/main.tscn")
	var main_instance_phase26e_r = main_scene_phase26e_r.instantiate()
	add_child(main_instance_phase26e_r)
	await get_tree().process_frame

	main_instance_phase26e_r.transition_to("datacenter_entrance", "from_nightclub")
	await get_tree().process_frame
	if main_instance_phase26e_r.get_current_scene_id() != "datacenter_entrance":
		printerr("FAIL 26-E: datacenter_entrance (25 travel gate) should still be reachable after Phase 26 changes!")
		get_tree().quit(1)
		return

	main_instance_phase26e_r.transition_to("datacenter_backup", "from_entrance")
	await get_tree().process_frame
	if main_instance_phase26e_r.get_current_scene_id() != "datacenter_backup":
		printerr("FAIL 26-E: datacenter_backup (25 門禁 gate 後動線) should still be reachable after Phase 26 changes!")
		get_tree().quit(1)
		return

	main_instance_phase26e_r.transition_to("datacenter_backup_core", "from_backup")
	await get_tree().process_frame
	if main_instance_phase26e_r.get_current_scene_id() != "datacenter_backup_core":
		printerr("FAIL 26-E: datacenter_backup_core (戰鬥③ 抵達門後動線) should still be reachable after Phase 26 changes!")
		get_tree().quit(1)
		return

	main_instance_phase26e_r.transition_to("tunnel_chase", "from_settlement")
	await get_tree().process_frame
	if main_instance_phase26e_r.get_current_scene_id() != "tunnel_chase":
		printerr("FAIL 26-E: tunnel_chase (Phase 24 追逐房間1) should still be reachable after Phase 26 changes!")
		get_tree().quit(1)
		return

	main_instance_phase26e_r.transition_to("tunnel_chase_right", "from_left")
	await get_tree().process_frame
	if main_instance_phase26e_r.get_current_scene_id() != "tunnel_chase_right":
		printerr("FAIL 26-E: tunnel_chase_right (Phase 24 攤牌) should still be reachable after Phase 26 changes!")
		get_tree().quit(1)
		return

	main_instance_phase26e_r.transition_to("underground_settlement_right", "from_left")
	await get_tree().process_frame
	if main_instance_phase26e_r.get_current_scene_id() != "underground_settlement_right":
		printerr("FAIL 26-E: underground_settlement_right (聚落往返) should still be reachable after Phase 26 changes!")
		get_tree().quit(1)
		return

	main_instance_phase26e_r.transition_to("underground_settlement", "from_right")
	await get_tree().process_frame
	if main_instance_phase26e_r.get_current_scene_id() != "underground_settlement":
		printerr("FAIL 26-E: underground_settlement round-trip (聚落往返) should still work after Phase 26 changes!")
		get_tree().quit(1)
		return

	if is_instance_valid(main_instance_phase26e_r):
		main_instance_phase26e_r.free()

	GameState.reset_for_new_game()
	if dir and dir.file_exists(TEST_SCRATCH_SAVE_FILE):
		dir.remove(TEST_SCRATCH_SAVE_FILE)

	print("PASS: Phase 26-E regression (Phase 1~25 core routes intact) and save/load guardrails (four flags round-trip + 26-A/B one-shot persists across cross-save/load) verified.")

