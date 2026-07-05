extends "res://tests/manual/phases/phase_27b.gd"

func _run_phase_27a() -> void:
	# ===================== Phase 27-A: `broadcast_station` 正式場景 =====================
	print("--- Phase 27-A: broadcast_station 正式場景 ---")

	var main_scene_phase27a_r = load("res://scenes/main/main.tscn")
	var main_instance_phase27a_r = main_scene_phase27a_r.instantiate()
	add_child(main_instance_phase27a_r)
	await get_tree().process_frame

	# 1. SceneRegistry / SaveSystem 顯示名
	if not "broadcast_station" in main_instance_phase27a_r.SCENES:
		printerr("FAIL 27-A: SceneRegistry missing broadcast_station!")
		get_tree().quit(1)
		return
	var bc_config_phase27a: Dictionary = main_instance_phase27a_r.SCENES["broadcast_station"]
	if bc_config_phase27a.get("default_entry_point_id", "") != "from_backup_core" or not "from_backup_core" in bc_config_phase27a.get("entry_points", []):
		printerr("FAIL 27-A: broadcast_station entry_points/default_entry_point_id misconfigured: ", bc_config_phase27a)
		get_tree().quit(1)
		return
	if SaveSystem.get_scene_display_name("broadcast_station") == "未知區域":
		printerr("FAIL 27-A: SaveSystem SCENE_NAMES missing broadcast_station!")
		get_tree().quit(1)
		return

	# 2. 場景骨架：唯一 spawn、無回資料中心出口、四個互動物欄位正確
	var bc_packed_phase27a = load("res://scenes/levels/broadcast/broadcast_station.tscn")
	var bc_inst_phase27a = bc_packed_phase27a.instantiate()
	add_child(bc_inst_phase27a)
	await get_tree().process_frame

	var bc_spawns_phase27a = bc_inst_phase27a.get_node("SpawnPoints").get_children()
	if bc_spawns_phase27a.size() != 1 or bc_spawns_phase27a[0].name != "from_backup_core":
		printerr("FAIL 27-A: broadcast_station should have exactly one spawn point, from_backup_core!")
		get_tree().quit(1)
		return

	for interactable_phase27a in bc_inst_phase27a.get_node("Interactables").get_children():
		var iid_phase27a: String = interactable_phase27a.interaction_id
		if iid_phase27a.contains("exit") or iid_phase27a.contains("return"):
			printerr("FAIL 27-A: broadcast_station must have no return-to-datacenter exit (單向), found: ", iid_phase27a)
			get_tree().quit(1)
			return

	var upload_terminal_phase27a = bc_inst_phase27a.get_node_or_null("Interactables/UploadTerminal")
	if upload_terminal_phase27a == null or upload_terminal_phase27a.dialogue_id != "broadcast_upload":
		printerr("FAIL 27-A: UploadTerminal missing or dialogue_id != broadcast_upload!")
		get_tree().quit(1)
		return

	for flavor_name_phase27a in ["FlavorTransmitterArea", "FlavorOldMediaArea", "FlavorPredecessorArea"]:
		if bc_inst_phase27a.get_node_or_null("Interactables/" + flavor_name_phase27a) == null:
			printerr("FAIL 27-A: broadcast_station missing flavor examine node: ", flavor_name_phase27a)
			get_tree().quit(1)
			return

	bc_inst_phase27a.free()
	await get_tree().process_frame

	# 3. 轉場 + 進場一次性 MessageBox（entry_point_id == from_backup_core 才播）+ can_save_here
	SaveSystem.can_save_here = false
	main_instance_phase27a_r.transition_to("broadcast_station", "from_backup_core")

	if main_instance_phase27a_r.get_current_scene_id() != "broadcast_station":
		printerr("FAIL 27-A: broadcast_station should be reachable via transition_to!")
		get_tree().quit(1)
		return
	if not SaveSystem.can_save_here:
		printerr("FAIL 27-A: broadcast_station should set can_save_here = true!")
		get_tree().quit(1)
		return

	# 訊號連線必須搶在 call_deferred 進場訊息真正 flush 之前（transition_to 內同步 add_child/_ready 已排入 deferred queue，尚未觸發）
	# 用 get_children()[-1]，因為 transition_to 清舊場景用 queue_free（延遲），舊子節點此刻仍在 index 0
	var captured_arrival_phase27a: Dictionary = {}
	var bc_level_phase27a = main_instance_phase27a_r.world_root.get_children()[-1]
	bc_level_phase27a.interaction_requested.connect(func(data):
		captured_arrival_phase27a.merge(data, true)
	)
	await get_tree().process_frame
	await get_tree().process_frame
	if captured_arrival_phase27a.get("message_text", "") != "MSG_BROADCAST_ARRIVAL":
		printerr("FAIL 27-A: entering via from_backup_core should auto-play MSG_BROADCAST_ARRIVAL once, got: ", captured_arrival_phase27a)
		get_tree().quit(1)
		return

	# 4. 場景內存讀 round-trip；讀檔回場（entry_point_id == restore）不重播進場 MessageBox
	var save_dict_phase27a = SaveSystem.capture("broadcast_station", 2200.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_dict_phase27a):
		printerr("FAIL 27-A: SaveSystem.write_slot failed for broadcast_station save!")
		get_tree().quit(1)
		return

	if is_instance_valid(main_instance_phase27a_r):
		main_instance_phase27a_r.free()
	await get_tree().process_frame

	var main_scene_phase27a = load("res://scenes/main/main.tscn")
	var main_instance_phase27a = main_scene_phase27a.instantiate()
	add_child(main_instance_phase27a)
	await get_tree().process_frame

	if not main_instance_phase27a.load_game_slot(TEST_SCRATCH_SAVE_SLOT):
		printerr("FAIL 27-A: load_game_slot(scratch slot) failed to load broadcast_station save!")
		get_tree().quit(1)
		return
	await get_tree().process_frame

	if main_instance_phase27a.get_current_scene_id() != "broadcast_station":
		printerr("FAIL 27-A: current scene should restore to broadcast_station after load, got: ", main_instance_phase27a.get_current_scene_id())
		get_tree().quit(1)
		return

	var captured_reload_phase27a: Dictionary = {}
	var bc_level_reload_phase27a = main_instance_phase27a.world_root.get_children()[-1]
	bc_level_reload_phase27a.interaction_requested.connect(func(data):
		captured_reload_phase27a.merge(data, true)
	)
	await get_tree().process_frame
	await get_tree().process_frame
	if not captured_reload_phase27a.is_empty():
		printerr("FAIL 27-A: loading a save inside broadcast_station must not replay the arrival MessageBox, got: ", captured_reload_phase27a)
		get_tree().quit(1)
		return

	if is_instance_valid(main_instance_phase27a):
		main_instance_phase27a.free()

	GameState.reset_for_new_game()
	SaveSystem.can_save_here = true
	if dir and dir.file_exists(TEST_SCRATCH_SAVE_FILE):
		dir.remove(TEST_SCRATCH_SAVE_FILE)

	print("PASS: Phase 27-A broadcast_station scene (skeleton + one-shot arrival + no return exit + can_save_here + in-scene save/load) verified.")

