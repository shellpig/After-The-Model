extends "res://tests/manual/phases/phase_1abc.gd"

func _run_phase_32() -> void:
	print("--- Phase 32: Act 3→4 決意拍測試落地 ---")

	DialogueDB = load("res://data/dialogue/dialogue_db.gd")
	var travel_tree_phase32 = DialogueDB.get_tree_for("travel_datacenter")

	# ===================== 1. gate 迴歸 =====================
	print("Checking gate regression...")
	
	# 無旗標：鎖住
	GameState.reset_for_new_game()
	var runner_locked_phase32 = DialogueRunner.new()
	runner_locked_phase32.start(travel_tree_phase32)
	if runner_locked_phase32.current().get("text", "") != "DLG_TRAVEL_DATACENTER_LOCKED_TEXT":
		printerr("FAIL 32-B: (gate) should be locked with no flags set!")
		get_tree().quit(1)
		return

	# 只過夜總會安檢、無終端旗標：仍鎖住
	GameState.set_flag("passed_nightclub_security", true)
	var runner_no_seven_phase32 = DialogueRunner.new()
	runner_no_seven_phase32.start(travel_tree_phase32)
	if runner_no_seven_phase32.current().get("text", "") != "DLG_TRAVEL_DATACENTER_LOCKED_TEXT":
		printerr("FAIL 32-B: (gate) should stay locked with only passed_nightclub_security true!")
		get_tree().quit(1)
		return

	# D 分支解鎖且過安檢 -> 進入 menu_peace -> 前往 -> prelude_d -> confirm_by_wan_d
	GameState.set_flag("seven_peace_branch_d", true)
	var runner_d_phase32 = DialogueRunner.new()
	runner_d_phase32.start(travel_tree_phase32)
	if runner_d_phase32.current().get("text", "") != "DLG_TRAVEL_DATACENTER_MENU_PEACE_TEXT":
		printerr("FAIL 32-B: (gate) D branch should open menu_peace!")
		get_tree().quit(1)
		return
	runner_d_phase32.choose(0) # 前往
	if runner_d_phase32.current().get("text", "") != "DLG_TRAVEL_DATACENTER_PRELUDE_D_TEXT":
		printerr("FAIL 32-B: (gate) D branch should route to prelude_d!")
		get_tree().quit(1)
		return
	runner_d_phase32.advance()
	if runner_d_phase32.current().get("text", "") != "DLG_TRAVEL_DATACENTER_CONFIRM_D_TEXT":
		printerr("FAIL 32-B: (gate) D branch should show confirm_d!")
		get_tree().quit(1)
		return

	# A 分支解鎖且過安檢 -> 進入 menu_track -> 前往 -> prelude_a -> confirm_by_wan_track
	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)
	GameState.set_flag("seven_stopped_full", true)
	var runner_a_phase32 = DialogueRunner.new()
	runner_a_phase32.start(travel_tree_phase32)
	if runner_a_phase32.current().get("text", "") != "DLG_TRAVEL_DATACENTER_MENU_TEXT":
		printerr("FAIL 32-B: (gate) A branch should open menu_track!")
		get_tree().quit(1)
		return
	runner_a_phase32.choose(0) # 前往
	if runner_a_phase32.current().get("text", "") != "DLG_TRAVEL_DATACENTER_PRELUDE_A_TEXT":
		printerr("FAIL 32-B: (gate) A branch should route to prelude_a!")
		get_tree().quit(1)
		return
	runner_a_phase32.advance()
	if runner_a_phase32.current().get("text", "") != "DLG_TRAVEL_DATACENTER_CONFIRM_TRACK_TEXT":
		printerr("FAIL 32-B: (gate) A branch should show confirm_track!")
		get_tree().quit(1)
		return

	# B 分支解鎖且過安檢 -> 進入 menu_track -> 前往 -> prelude_b -> confirm_by_wan_track
	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)
	GameState.set_flag("seven_stopped_partial", true)
	var runner_b_phase32 = DialogueRunner.new()
	runner_b_phase32.start(travel_tree_phase32)
	if runner_b_phase32.current().get("text", "") != "DLG_TRAVEL_DATACENTER_MENU_TEXT":
		printerr("FAIL 32-B: (gate) B branch should open menu_track!")
		get_tree().quit(1)
		return
	runner_b_phase32.choose(0) # 前往
	if runner_b_phase32.current().get("text", "") != "DLG_TRAVEL_DATACENTER_PRELUDE_B_TEXT":
		printerr("FAIL 32-B: (gate) B branch should route to prelude_b!")
		get_tree().quit(1)
		return
	runner_b_phase32.advance()
	if runner_b_phase32.current().get("text", "") != "DLG_TRAVEL_DATACENTER_CONFIRM_TRACK_TEXT":
		printerr("FAIL 32-B: (gate) B branch should show confirm_track!")
		get_tree().quit(1)
		return

	print("PASS: Gate regression verified successfully.")

	# ===================== 2. 筆記時序 =====================
	print("Checking note timeline...")
	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)
	GameState.set_flag("seven_peace_branch_d", true)

	var runner_note_phase32 = DialogueRunner.new()
	if GameState.has_note("note_datacenter_route"):
		printerr("FAIL 32-B: (note) note_datacenter_route should not exist before entering menu!")
		get_tree().quit(1)
		return

	runner_note_phase32.start(travel_tree_phase32)
	if not GameState.has_note("note_datacenter_route"):
		printerr("FAIL 32-B: (note) note_datacenter_route should be written immediately on entering menu!")
		get_tree().quit(1)
		return

	var note_obj_phase32 = null
	for n in GameState.get_notes("工作"):
		if n.get("id") == "note_datacenter_route":
			note_obj_phase32 = n
			break
	if note_obj_phase32 == null or note_obj_phase32.get("category", "") != "工作":
		printerr("FAIL 32-B: (note) note category is not '工作'!")
		get_tree().quit(1)
		return

	# 選擇取消 (choose(1))
	runner_note_phase32.choose(1)
	if runner_note_phase32.current().get("text", "") != "DLG_TRAVEL_DATACENTER_END_TEXT":
		printerr("FAIL 32-B: (note) cancel path check failed!")
		get_tree().quit(1)
		return

	# 取消後筆記保留、pending_travel 空、committed 未設
	if not GameState.has_note("note_datacenter_route"):
		printerr("FAIL 32-B: (note) note should still exist after cancel!")
		get_tree().quit(1)
		return
	if not runner_note_phase32.pending_travel.is_empty():
		printerr("FAIL 32-B: (note) pending_travel should be empty on cancel!")
		get_tree().quit(1)
		return
	if GameState.get_flag("datacenter_travel_committed"):
		printerr("FAIL 32-B: (note) committed flag should be false on cancel!")
		get_tree().quit(1)
		return

	# 重進確認冪等不重複
	var runner_note2_phase32 = DialogueRunner.new()
	runner_note2_phase32.start(travel_tree_phase32)
	if not GameState.has_note("note_datacenter_route"):
		printerr("FAIL 32-B: (note) note disappeared on second entry!")
		get_tree().quit(1)
		return

	print("PASS: Note timeline verified successfully.")

	# ===================== 3. confirm 兩路 =====================
	print("Checking confirm two paths...")

	# 先離開路徑
	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)
	GameState.set_flag("seven_peace_branch_d", true)
	var runner_leave_phase32 = DialogueRunner.new()
	runner_leave_phase32.start(travel_tree_phase32)
	runner_leave_phase32.choose(0) # 前往
	runner_leave_phase32.advance() # prelude
	runner_leave_phase32.choose(1) # 先離開
	if runner_leave_phase32.current().get("text", "") != "DLG_TRAVEL_DATACENTER_END_TEXT":
		printerr("FAIL 32-B: (confirm) leave choice failed to route to end node!")
		get_tree().quit(1)
		return
	if not runner_leave_phase32.pending_travel.is_empty():
		printerr("FAIL 32-B: (confirm) pending_travel should be empty when choosing leave!")
		get_tree().quit(1)
		return
	if GameState.get_flag("datacenter_travel_committed"):
		printerr("FAIL 32-B: (confirm) committed flag should not be set when choosing leave!")
		get_tree().quit(1)
		return

	# 進去路徑
	var runner_enter_phase32 = DialogueRunner.new()
	runner_enter_phase32.start(travel_tree_phase32)
	runner_enter_phase32.choose(0) # 前往
	runner_enter_phase32.advance() # prelude
	runner_enter_phase32.choose(0) # 進去
	if not GameState.get_flag("datacenter_travel_committed"):
		printerr("FAIL 32-B: (confirm) committed flag must be set when choosing enter!")
		get_tree().quit(1)
		return
	if runner_enter_phase32.current().get("text", "") != "DLG_TRAVEL_DATACENTER_TRAVEL_TEXT":
		printerr("FAIL 32-B: (confirm) enter choice failed to route to travel node!")
		get_tree().quit(1)
		return
	if runner_enter_phase32.pending_travel.get("scene_id", "") != "datacenter_entrance" or runner_enter_phase32.pending_travel.get("entry_point_id", "") != "from_nightclub":
		printerr("FAIL 32-B: (confirm) pending_travel payload mismatch!")
		get_tree().quit(1)
		return

	print("PASS: Confirm paths verified successfully.")

	# ===================== 4. committed round-trip =====================
	print("Checking committed round-trip...")
	GameState.reset_for_new_game()
	GameState.set_flag("datacenter_travel_committed", true)

	var save_dict_phase32 = SaveSystem.capture("apartment", 100.0, TEST_SCRATCH_SAVE_SLOT)
	GameState.reset_for_new_game()
	if GameState.get_flag("datacenter_travel_committed"):
		printerr("FAIL 32-B: (round-trip) reset failed to clear committed flag!")
		get_tree().quit(1)
		return

	SaveSystem.apply(save_dict_phase32)
	if not GameState.get_flag("datacenter_travel_committed"):
		printerr("FAIL 32-B: (round-trip) apply failed to restore committed flag!")
		get_tree().quit(1)
		return

	print("PASS: Committed flag round-trip verified successfully.")

	# ===================== 5. menu_repeat 去重 =====================
	print("Checking menu_repeat behavior...")
	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)
	GameState.set_flag("seven_peace_branch_d", true)
	GameState.set_flag("datacenter_travel_committed", true)

	var runner_repeat_phase32 = DialogueRunner.new()
	runner_repeat_phase32.start(travel_tree_phase32)
	if runner_repeat_phase32.current().get("text", "") != "DLG_TRAVEL_DATACENTER_MENU_REPEAT_TEXT":
		printerr("FAIL 32-B: (repeat) committed state should route directly to menu_repeat!")
		get_tree().quit(1)
		return

	runner_repeat_phase32.choose(0) # 前往
	if runner_repeat_phase32.current().get("text", "") != "DLG_TRAVEL_DATACENTER_TRAVEL_TEXT":
		printerr("FAIL 32-B: (repeat) menu_repeat choice 0 should route directly to travel!")
		get_tree().quit(1)
		return
	if runner_repeat_phase32.pending_travel.get("scene_id", "") != "datacenter_entrance":
		printerr("FAIL 32-B: (repeat) repeat path travel destination mismatch!")
		get_tree().quit(1)
		return

	print("PASS: menu_repeat behavior verified successfully.")
