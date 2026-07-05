extends "res://tests/manual/phases/phase_27d.gd"

func _run_phase_27c() -> void:
	# ===================== Phase 27-C: 上傳前清洗閘五拍 =====================
	print("--- Phase 27-C: 上傳前清洗閘五拍 ---")

	GameState.reset_for_new_game()

	var find_choice_phase27c = func(curr: Dictionary, substr: String) -> int:
		for c in curr.get("choices", []):
			if substr in tr(c.get("label", "")):
				return c.get("index")
		return -1

	var broadcast_upload_tree_phase27c = DialogueDB.get_tree_for("broadcast_upload")
	if broadcast_upload_tree_phase27c.is_empty():
		printerr("FAIL 27-C: DialogueDB broadcast_upload tree not found!")
		get_tree().quit(1)
		return

	# ---- Test 1: level dispatch (upload_terminal) ----
	var bc_inst_phase27c = load("res://scenes/levels/broadcast/broadcast_station.tscn").instantiate()
	add_child(bc_inst_phase27c)

	var upload_terminal_area_phase27c = bc_inst_phase27c.get_node_or_null("Interactables/UploadTerminal")
	if upload_terminal_area_phase27c == null or upload_terminal_area_phase27c.interaction_id != "upload_terminal":
		printerr("FAIL 27-C: broadcast_station missing UploadTerminal (interaction_id='upload_terminal')!")
		get_tree().quit(1)
		return

	var captured_27c: Dictionary = {}
	bc_inst_phase27c.interaction_requested.connect(func(data):
		captured_27c.clear()
		captured_27c.merge(data, true)
	)
	bc_inst_phase27c.current_interactable = upload_terminal_area_phase27c

	bc_inst_phase27c._trigger_interaction()
	if captured_27c.get("type", "") != "dialogue" or captured_27c.get("dialogue_id", "") != "broadcast_upload":
		printerr("FAIL 27-C: before expose_upload_done, UploadTerminal should dispatch dialogue 'broadcast_upload', got: ", captured_27c)
		get_tree().quit(1)
		return

	GameState.set_flag("expose_upload_done", true)
	bc_inst_phase27c._trigger_interaction()
	if captured_27c.get("message_text", "") != "MSG_BROADCAST_UPLOAD_DONE_IDLE":
		printerr("FAIL 27-C: once expose_upload_done is set, UploadTerminal should show idle message, not reopen the tree, got: ", captured_27c)
		get_tree().quit(1)
		return
	print("PASS 27-C: level dispatch (open broadcast_upload dialogue -> idle examine once expose_upload_done is set) verified.")

	bc_inst_phase27c.free()
	await get_tree().process_frame
	GameState.reset_for_new_game()

	# ---- Test 2: 掃描拍 echo_count 兩檔變體 ----
	var runner_27c := DialogueRunner.new()

	# 少：只收 1 段
	GameState.collect_echo_segment("echo_clerk", "s1")
	runner_27c.start(broadcast_upload_tree_phase27c, "start")
	if runner_27c._current_node_id != "scan_low":
		printerr("FAIL 27-C: low echo_count should route to scan_low! Got: ", runner_27c._current_node_id)
		get_tree().quit(1)
		return

	# 多：收滿 9 段（剛好觸及門檻）
	GameState.reset_for_new_game()
	GameState.collect_echo_segment("echo_room401_tenant", "s1")
	GameState.collect_echo_segment("echo_room401_tenant", "s2")
	GameState.collect_echo_segment("echo_room401_tenant", "s3")
	GameState.collect_echo_segment("echo_settlement_erased", "s1")
	GameState.collect_echo_segment("echo_settlement_erased", "s2")
	GameState.collect_echo_segment("echo_ada_reset", "s1")
	GameState.collect_echo_segment("echo_linfei", "s1")
	GameState.collect_echo_segment("echo_linfei", "s2")
	GameState.collect_echo_segment("echo_linfei", "s3")
	if GameState.get_collected_echo_segment_count() != 9:
		printerr("FAIL 27-C: test setup expected exactly 9 collected segments, got: ", GameState.get_collected_echo_segment_count())
		get_tree().quit(1)
		return
	runner_27c.start(broadcast_upload_tree_phase27c, "start")
	if runner_27c._current_node_id != "scan_high":
		printerr("FAIL 27-C: echo_count >= 9 should route to scan_high! Got: ", runner_27c._current_node_id)
		get_tree().quit(1)
		return
	print("PASS 27-C: scan beat echo_count two-tier variant (low -> scan_low, >=9 -> scan_high) verified.")

	# ---- Test 3: 中性警告 seven_stopped_partial 變體 ----
	runner_27c.advance()
	if runner_27c._current_node_id != "warning_base":
		printerr("FAIL 27-C: without seven_stopped_partial, warning should route to warning_base! Got: ", runner_27c._current_node_id)
		get_tree().quit(1)
		return

	GameState.set_flag("seven_stopped_partial", true)
	runner_27c.start(broadcast_upload_tree_phase27c, "start")
	if runner_27c._current_node_id != "scan_high":
		printerr("FAIL 27-C: seven_stopped_partial must not affect the scan tier! Got: ", runner_27c._current_node_id)
		get_tree().quit(1)
		return
	runner_27c.advance()
	if runner_27c._current_node_id != "warning_branch_b":
		printerr("FAIL 27-C: with seven_stopped_partial, warning should route to warning_branch_b! Got: ", runner_27c._current_node_id)
		get_tree().quit(1)
		return
	print("PASS 27-C: warning beat seven_stopped_partial Branch B variant verified.")

	# ---- Test 4: 反諷＋首選三選項 ----
	runner_27c.advance()
	if runner_27c._current_node_id != "irony":
		printerr("FAIL 27-C: warning_branch_b should advance into irony! Got: ", runner_27c._current_node_id)
		get_tree().quit(1)
		return
	var irony_curr_27c = runner_27c.current()
	for expect_label in ["動手清洗", "原樣保留", "退開"]:
		if find_choice_phase27c.call(irony_curr_27c, expect_label) == -1:
			printerr("FAIL 27-C: irony choices missing expected option: ", expect_label, " got: ", irony_curr_27c)
			get_tree().quit(1)
			return

	# ---- Test 5: 退開（首選層）-> 無 effect、不留半套狀態 ----
	runner_27c.choose(find_choice_phase27c.call(irony_curr_27c, "退開"))
	if runner_27c._current_node_id != "withdraw":
		printerr("FAIL 27-C: 退開 at irony should land on withdraw! Got: ", runner_27c._current_node_id)
		get_tree().quit(1)
		return
	if GameState.get_flag("expose_upload_cleaned", false) or GameState.get_flag("expose_upload_done", false):
		printerr("FAIL 27-C: withdrawing at irony must not write any expose_upload_* flag!")
		get_tree().quit(1)
		return
	print("PASS 27-C: 退開 at irony writes no flag (no half-committed state).")

	# ---- Test 6: 動手清洗 -> expose_upload_cleaned=true + expose_upload_done=true ----
	runner_27c.start(broadcast_upload_tree_phase27c, "start")
	runner_27c.advance() # -> warning_branch_b
	runner_27c.advance() # -> irony
	irony_curr_27c = runner_27c.current()
	runner_27c.choose(find_choice_phase27c.call(irony_curr_27c, "動手清洗"))
	if runner_27c._current_node_id != "cost_clean":
		printerr("FAIL 27-C: 動手清洗 should route to cost_clean! Got: ", runner_27c._current_node_id)
		get_tree().quit(1)
		return
	runner_27c.advance()
	if runner_27c._current_node_id != "confirm_clean":
		printerr("FAIL 27-C: cost_clean should advance into confirm_clean! Got: ", runner_27c._current_node_id)
		get_tree().quit(1)
		return
	var confirm_curr_27c = runner_27c.current()
	runner_27c.choose(find_choice_phase27c.call(confirm_curr_27c, "開始上傳"))
	if runner_27c._current_node_id != "upload_clean_lock":
		printerr("FAIL 27-C: 開始上傳 (clean) should land on upload_clean_lock! Got: ", runner_27c._current_node_id)
		get_tree().quit(1)
		return
	if not GameState.get_flag("expose_upload_cleaned", false) or not GameState.get_flag("expose_upload_done", false):
		printerr("FAIL 27-C: clean upload lock should set both expose_upload_cleaned and expose_upload_done true!")
		get_tree().quit(1)
		return
	print("PASS 27-C: 動手清洗 lock-in sets expose_upload_cleaned=true + expose_upload_done=true.")

	# ---- Test 7: 原樣保留 -> expose_upload_cleaned=false + expose_upload_done=true ----
	GameState.reset_for_new_game()
	GameState.collect_echo_segment("echo_clerk", "s1")
	runner_27c.start(broadcast_upload_tree_phase27c, "start")
	runner_27c.advance() # -> warning_base
	runner_27c.advance() # -> irony
	irony_curr_27c = runner_27c.current()
	runner_27c.choose(find_choice_phase27c.call(irony_curr_27c, "原樣保留"))
	if runner_27c._current_node_id != "cost_raw":
		printerr("FAIL 27-C: 原樣保留 should route to cost_raw! Got: ", runner_27c._current_node_id)
		get_tree().quit(1)
		return
	runner_27c.advance()
	if runner_27c._current_node_id != "confirm_raw":
		printerr("FAIL 27-C: cost_raw should advance into confirm_raw! Got: ", runner_27c._current_node_id)
		get_tree().quit(1)
		return
	confirm_curr_27c = runner_27c.current()
	runner_27c.choose(find_choice_phase27c.call(confirm_curr_27c, "開始上傳"))
	if runner_27c._current_node_id != "upload_raw_lock":
		printerr("FAIL 27-C: 開始上傳 (raw) should land on upload_raw_lock! Got: ", runner_27c._current_node_id)
		get_tree().quit(1)
		return
	if GameState.get_flag("expose_upload_cleaned", false) or not GameState.get_flag("expose_upload_done", false):
		printerr("FAIL 27-C: raw upload lock should set expose_upload_cleaned=false and expose_upload_done=true!")
		get_tree().quit(1)
		return
	print("PASS 27-C: 原樣保留 lock-in sets expose_upload_cleaned=false + expose_upload_done=true.")

	# ---- Test 8: 退開（最終確認層）-> 無 effect、不留半套狀態、可重走整段 ----
	GameState.reset_for_new_game()
	GameState.collect_echo_segment("echo_clerk", "s1")
	runner_27c.start(broadcast_upload_tree_phase27c, "start")
	runner_27c.advance() # -> warning_base
	runner_27c.advance() # -> irony
	irony_curr_27c = runner_27c.current()
	runner_27c.choose(find_choice_phase27c.call(irony_curr_27c, "動手清洗"))
	runner_27c.advance() # -> confirm_clean
	confirm_curr_27c = runner_27c.current()
	runner_27c.choose(find_choice_phase27c.call(confirm_curr_27c, "退開"))
	if runner_27c._current_node_id != "withdraw":
		printerr("FAIL 27-C: 退開 at final confirm should land on withdraw! Got: ", runner_27c._current_node_id)
		get_tree().quit(1)
		return
	if GameState.get_flag("expose_upload_cleaned", false) or GameState.get_flag("expose_upload_done", false):
		printerr("FAIL 27-C: withdrawing at final confirm must leave no half-committed state (clean choice is not preserved)!")
		get_tree().quit(1)
		return
	# 可重走整段：重開直接回到 scan（不記得先前選過清洗）
	runner_27c.start(broadcast_upload_tree_phase27c, "start")
	if runner_27c._current_node_id != "scan_low":
		printerr("FAIL 27-C: re-opening after withdrawing at final confirm should restart from the scan beat! Got: ", runner_27c._current_node_id)
		get_tree().quit(1)
		return
	print("PASS 27-C: 退開 at final confirm leaves no half-committed state and the whole beat replays from scratch.")

	GameState.reset_for_new_game()
	print("PASS: Phase 27-C cleaning gate (five beats: echo_count scan variant + seven_stopped_partial warning variant + clean/raw/withdraw choice + cost beat + mutually-exclusive-with-no-partial-state final lock + level idle gate) verified.")

