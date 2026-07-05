extends "res://tests/manual/phases/phase_27c.gd"

func _run_phase_27b() -> void:
	# ===================== Phase 27-B: 三結局路由 own_backup =====================
	print("--- Phase 27-B: 三結局路由 own_backup ---")

	GameState.reset_for_new_game()

	var find_choice_phase27b = func(curr: Dictionary, substr: String) -> int:
		for c in curr.get("choices", []):
			if substr in tr(c.get("label", "")):
				return c.get("index")
		return -1

	var own_backup_tree_phase27b = DialogueDB.get_tree_for("own_backup")
	if own_backup_tree_phase27b.is_empty():
		printerr("FAIL 27-B: DialogueDB own_backup tree not found!")
		get_tree().quit(1)
		return

	# ---- Test 1: level dispatch 四層分派鏈 ----
	var core_inst_phase27b = load("res://scenes/levels/datacenter_backup_core/datacenter_backup_core.tscn").instantiate()
	add_child(core_inst_phase27b)

	var own_backup_area_phase27b = core_inst_phase27b.get_node_or_null("Interactables/OwnBackupArea")
	if own_backup_area_phase27b == null:
		printerr("FAIL 27-B: datacenter_backup_core missing OwnBackupArea node!")
		get_tree().quit(1)
		return

	var captured_27b: Dictionary = {}
	core_inst_phase27b.interaction_requested.connect(func(data):
		captured_27b.clear()
		captured_27b.merge(data, true)
	)
	core_inst_phase27b.current_interactable = own_backup_area_phase27b

	# 1a. 碎片前：中性佔位（26-D 不變）
	core_inst_phase27b._trigger_interaction()
	if captured_27b.get("message_text", "") != "MSG_DATACENTER_OWN_BACKUP_PLACEHOLDER":
		printerr("FAIL 27-B: expected placeholder before fragment collected, got: ", captured_27b)
		get_tree().quit(1)
		return

	# 1b. 碎片後：TRUTH + 武裝 stood_before_own_backup（26-D 不變）
	GameState.set_flag("mem_frag_chose_deletion", true)
	core_inst_phase27b._trigger_interaction()
	if captured_27b.get("message_text", "") != "MSG_DATACENTER_OWN_BACKUP_TRUTH" or not GameState.get_flag("stood_before_own_backup", false):
		printerr("FAIL 27-B: expected TRUTH text + stood_before_own_backup armed, got: ", captured_27b)
		get_tree().quit(1)
		return

	# 1c. 重看：開三選對話（stood_before_own_backup 已武裝、尚未鎖點）
	core_inst_phase27b._trigger_interaction()
	if captured_27b.get("type", "") != "dialogue" or captured_27b.get("dialogue_id", "") != "own_backup":
		printerr("FAIL 27-B: re-examining own_backup after stood_before_own_backup should open dialogue 'own_backup', got: ", captured_27b)
		get_tree().quit(1)
		return
	print("PASS 27-B: level dispatch layers 1-3 (placeholder -> TRUTH+armament -> open own_backup dialogue) verified.")

	# 1d. 鎖點後：DECIDED（不可重選）
	GameState.set_flag("ending_route_reclaim", true)
	core_inst_phase27b._trigger_interaction()
	if captured_27b.get("message_text", "") != "MSG_DATACENTER_OWN_BACKUP_DECIDED":
		printerr("FAIL 27-B: expected DECIDED message once a route flag is set, got: ", captured_27b)
		get_tree().quit(1)
		return
	print("PASS 27-B: level dispatch layer 4 (DECIDED, no longer re-openable) verified.")

	core_inst_phase27b.free()
	await get_tree().process_frame
	GameState.reset_for_new_game()

	# ---- Test 2: 存檔提示一次性 pre-node ----
	var runner_27b := DialogueRunner.new()
	runner_27b.start(own_backup_tree_phase27b, "start")
	if runner_27b._current_node_id != "save_hint":
		printerr("FAIL 27-B: start should route to save_hint before ending_save_hint_seen is set! Got: ", runner_27b._current_node_id)
		get_tree().quit(1)
		return
	if not GameState.get_flag("ending_save_hint_seen", false):
		printerr("FAIL 27-B: entering save_hint should immediately set ending_save_hint_seen!")
		get_tree().quit(1)
		return
	runner_27b.advance()
	if runner_27b._current_node_id != "anchor":
		printerr("FAIL 27-B: save_hint should advance straight into anchor! Got: ", runner_27b._current_node_id)
		get_tree().quit(1)
		return

	# 旗標已設，重開應直入重錨定（不重播提示）
	runner_27b.start(own_backup_tree_phase27b, "start")
	if runner_27b._current_node_id != "anchor":
		printerr("FAIL 27-B: with ending_save_hint_seen already set, start should skip straight to anchor! Got: ", runner_27b._current_node_id)
		get_tree().quit(1)
		return
	print("PASS 27-B: one-shot save hint pre-node (sets flag once, skipped on re-open) verified.")

	# ---- Test 3: anchor 四選項（三動詞 + 退開）----
	var anchor_curr_27b = runner_27b.current()
	for expect_label in ["灌回去", "刪掉它", "拷貝走", "退開"]:
		if find_choice_phase27b.call(anchor_curr_27b, expect_label) == -1:
			printerr("FAIL 27-B: anchor choices missing expected option: ", expect_label, " got: ", anchor_curr_27b)
			get_tree().quit(1)
			return

	# ---- Test 4: 退開 -> 無 effect、不寫旗標、可重開 ----
	runner_27b.choose(find_choice_phase27b.call(anchor_curr_27b, "退開"))
	if runner_27b._current_node_id != "withdraw":
		printerr("FAIL 27-B: 退開 should land on withdraw node! Got: ", runner_27b._current_node_id)
		get_tree().quit(1)
		return
	if GameState.get_flag("ending_route_reclaim", false) or GameState.get_flag("ending_route_protect", false) or GameState.get_flag("ending_route_expose", false):
		printerr("FAIL 27-B: withdrawing must not write any ending_route_* flag!")
		get_tree().quit(1)
		return
	print("PASS 27-B: 退開 (withdraw) writes no route flag and dialogue stays re-openable.")

	# ---- Test 5: 回去再想 -> 退回 anchor，不寫旗標 ----
	runner_27b.start(own_backup_tree_phase27b, "start")
	anchor_curr_27b = runner_27b.current()
	runner_27b.choose(find_choice_phase27b.call(anchor_curr_27b, "灌回去"))
	if runner_27b._current_node_id != "confirm_reclaim":
		printerr("FAIL 27-B: 灌回去 should route to confirm_reclaim! Got: ", runner_27b._current_node_id)
		get_tree().quit(1)
		return
	var confirm_curr_27b = runner_27b.current()
	runner_27b.choose(find_choice_phase27b.call(confirm_curr_27b, "回去再想"))
	if runner_27b._current_node_id != "anchor":
		printerr("FAIL 27-B: 回去再想 should return to anchor (第 3 拍)! Got: ", runner_27b._current_node_id)
		get_tree().quit(1)
		return
	if GameState.get_flag("ending_route_reclaim", false):
		printerr("FAIL 27-B: reconsidering must not write ending_route_reclaim!")
		get_tree().quit(1)
		return
	print("PASS 27-B: 回去再想 (reconsider) returns to anchor without writing a route flag.")

	# ---- Test 6: 灌回去鎖點 -> ending_route_reclaim 唯一為真 ----
	anchor_curr_27b = runner_27b.current()
	runner_27b.choose(find_choice_phase27b.call(anchor_curr_27b, "灌回去"))
	confirm_curr_27b = runner_27b.current()
	runner_27b.choose(find_choice_phase27b.call(confirm_curr_27b, "就這麼做"))
	if runner_27b._current_node_id != "reclaim_lock":
		printerr("FAIL 27-B: 就這麼做 (reclaim) should land on reclaim_lock! Got: ", runner_27b._current_node_id)
		get_tree().quit(1)
		return
	if not GameState.get_flag("ending_route_reclaim", false) or GameState.get_flag("ending_route_protect", false) or GameState.get_flag("ending_route_expose", false):
		printerr("FAIL 27-B: reclaim lock should set ending_route_reclaim and leave the other two routes false!")
		get_tree().quit(1)
		return
	print("PASS 27-B: 灌回去 lock-in sets ending_route_reclaim exclusively.")

	# ---- Test 7: 刪掉它鎖點 -> ending_route_protect 唯一為真 ----
	GameState.reset_for_new_game()
	GameState.set_flag("ending_save_hint_seen", true)
	runner_27b.start(own_backup_tree_phase27b, "start")
	anchor_curr_27b = runner_27b.current()
	runner_27b.choose(find_choice_phase27b.call(anchor_curr_27b, "刪掉它"))
	confirm_curr_27b = runner_27b.current()
	runner_27b.choose(find_choice_phase27b.call(confirm_curr_27b, "就這麼做"))
	if runner_27b._current_node_id != "protect_lock":
		printerr("FAIL 27-B: 就這麼做 (protect) should land on protect_lock! Got: ", runner_27b._current_node_id)
		get_tree().quit(1)
		return
	if not GameState.get_flag("ending_route_protect", false) or GameState.get_flag("ending_route_reclaim", false) or GameState.get_flag("ending_route_expose", false):
		printerr("FAIL 27-B: protect lock should set ending_route_protect and leave the other two routes false!")
		get_tree().quit(1)
		return
	print("PASS 27-B: 刪掉它 lock-in sets ending_route_protect exclusively.")

	# ---- Test 8: 拷貝走鎖點 -> ending_route_expose 唯一為真 + 單向轉場 broadcast_station ----
	GameState.reset_for_new_game()
	GameState.set_flag("ending_save_hint_seen", true)
	runner_27b.start(own_backup_tree_phase27b, "start")
	anchor_curr_27b = runner_27b.current()
	runner_27b.choose(find_choice_phase27b.call(anchor_curr_27b, "拷貝走"))
	confirm_curr_27b = runner_27b.current()
	runner_27b.choose(find_choice_phase27b.call(confirm_curr_27b, "就這麼做"))
	if runner_27b._current_node_id != "expose_lock":
		printerr("FAIL 27-B: 就這麼做 (expose) should land on expose_lock! Got: ", runner_27b._current_node_id)
		get_tree().quit(1)
		return
	if not GameState.get_flag("ending_route_expose", false) or GameState.get_flag("ending_route_reclaim", false) or GameState.get_flag("ending_route_protect", false):
		printerr("FAIL 27-B: expose lock should set ending_route_expose and leave the other two routes false!")
		get_tree().quit(1)
		return
	if runner_27b.pending_travel.get("scene_id", "") != "broadcast_station" or runner_27b.pending_travel.get("entry_point_id", "") != "from_backup_core":
		printerr("FAIL 27-B: expose lock should queue a one-way travel to broadcast_station:from_backup_core! Got: ", runner_27b.pending_travel)
		get_tree().quit(1)
		return
	print("PASS 27-B: 拷貝走 lock-in sets ending_route_expose exclusively and queues travel to broadcast_station:from_backup_core.")

	GameState.reset_for_new_game()
	print("PASS: Phase 27-B three-ending routing (own_backup dialogue: save-hint one-shot + anchor four choices + reconsider + mutually exclusive lock-in + Expose one-way travel + level DECIDED gate) verified.")

