extends "res://tests/manual/phases/phase_23b.gd"

func _run_phase_23a() -> void:
	# ===================== Phase 23-A: Act 3 夜總會保全四解小解謎骨架 =====================
	print("--- Phase 23-A: Act 3 夜總會保全四解小解謎骨架 ---")

	# 重置狀態
	GameState.reset_for_new_game()

	# 1. 驗證 biometric_gate 劇情拍子（不設 flag、不扣款）
	var inst_entrance = load("res://scenes/levels/nightclub/nightclub_entrance.tscn").instantiate()
	var gate_node = inst_entrance.get_node("Interactables/BiometricGateArea")
	inst_entrance.current_interactable = gate_node

	print("DEBUG: gate_node.interaction_id = ", gate_node.interaction_id)
	print("DEBUG: current_interactable = ", inst_entrance.current_interactable)

	var captured_msg_p23a: Dictionary = {}
	inst_entrance.interaction_requested.connect(func(data):
		print("DEBUG: interaction_requested received: ", data)
		captured_msg_p23a.merge(data, true)
	)
	inst_entrance._trigger_interaction()

	print("DEBUG: captured_msg_p23a = ", captured_msg_p23a)

	if captured_msg_p23a.get("type", "") != "message":
		printerr("FAIL 23-A: biometric_gate should trigger message!")
		get_tree().quit(1)
		return

	var gate_msg_key = inst_entrance.MESSAGES.get("biometric_gate", "")
	if captured_msg_p23a.get("message_text", "") != gate_msg_key:
		printerr("FAIL 23-A: biometric_gate message text mismatch!")
		get_tree().quit(1)
		return

	if GameState.get_flag("found_staff_pass", false) or GameState.get_flag("passed_nightclub_security", false):
		printerr("FAIL 23-A: biometric_gate should not set flags!")
		get_tree().quit(1)
		return

	inst_entrance.free()

	# 2. 驗證未通過安全檢驗時 back_door 被擋
	var inst_nightclub = load("res://scenes/levels/nightclub/nightclub.tscn").instantiate()
	var door_node = inst_nightclub.get_node("Interactables/BackDoorArea")
	inst_nightclub.current_interactable = door_node

	var captured_door_msg: Dictionary = {}
	inst_nightclub.interaction_requested.connect(func(data):
		captured_door_msg.merge(data, true)
	)
	inst_nightclub._trigger_interaction()

	if captured_door_msg.get("type", "") != "message":
		printerr("FAIL 23-A: back_door should trigger message when blocked!")
		get_tree().quit(1)
		return

	if captured_door_msg.get("message_text", "") != GameState.STORY_MESSAGES["nightclub_security_blocked"]:
		printerr("FAIL 23-A: Blocked message text mismatch!")
		get_tree().quit(1)
		return

	# 3. 驗證工牌 examine 與背包滿防呆
	# 塞滿背包
	while GameState.add_item("canned_food", 1):
		pass

	var pass_node = inst_nightclub.get_node("Interactables/StaffPassExamine")
	inst_nightclub.current_interactable = pass_node

	var captured_pass_msg: Dictionary = {}
	# 重新連結 interaction_requested 訊號
	for conn in inst_nightclub.interaction_requested.get_connections():
		inst_nightclub.interaction_requested.disconnect(conn.callable)
	inst_nightclub.interaction_requested.connect(func(data):
		captured_pass_msg.merge(data, true)
	)

	inst_nightclub._trigger_interaction()

	if captured_pass_msg.get("message_text", "") != GameState.STORY_MESSAGES["nightclub_examine_pass_bag_full"]:
		printerr("FAIL 23-A: Should show bag full message when picking staff pass with full inventory!")
		get_tree().quit(1)
		return

	if GameState.get_flag("found_staff_pass", false):
		printerr("FAIL 23-A: found_staff_pass flag should not be set when bag is full!")
		get_tree().quit(1)
		return

	# 清空背包第一格
	GameState.inventory[0] = {}

	# 重置 captured_pass_msg
	captured_pass_msg.clear()

	inst_nightclub._trigger_interaction()

	if not GameState.get_flag("found_staff_pass", false):
		printerr("FAIL 23-A: found_staff_pass flag should be set after successful picking!")
		get_tree().quit(1)
		return

	if not GameState.has_item("nightclub_staff_pass"):
		printerr("FAIL 23-A: nightclub_staff_pass item should be in inventory!")
		get_tree().quit(1)
		return

	if captured_pass_msg.get("message_text", "") != GameState.STORY_MESSAGES["nightclub_staff_pass_found"]:
		printerr("FAIL 23-A: Staff pass found message text mismatch!")
		get_tree().quit(1)
		return

	# 驗證物件被隱藏
	if pass_node.visible or pass_node.process_mode != ProcessMode.PROCESS_MODE_DISABLED:
		printerr("FAIL 23-A: StaffPassExamine node should be hidden and disabled!")
		get_tree().quit(1)
		return

	# 4. 驗證通過安全檢驗後 back_door 轉場正常
	GameState.set_flag("passed_nightclub_security", true)
	inst_nightclub.current_interactable = door_node

	var captured_trans: Dictionary = {}
	inst_nightclub.scene_transition_requested.connect(func(scene_id, entry_point_id, payload):
		captured_trans.merge({"scene": scene_id, "entry": entry_point_id}, true)
	)
	inst_nightclub._trigger_interaction()

	if captured_trans.get("scene", "") != "nightclub_back" or captured_trans.get("entry", "") != "from_lobby":
		printerr("FAIL 23-A: Should transition to nightclub_back after security passed!")
		get_tree().quit(1)
		return

	# 5. 驗證保全 NPC 互動會派發對話（dialogue_id dispatch，實機唯一入口）
	var bodyguard_node_p23a = inst_nightclub.get_node("Interactables/Bodyguard")
	inst_nightclub.current_interactable = bodyguard_node_p23a

	var captured_dialogue_p23a: Dictionary = {}
	for conn_p23a in inst_nightclub.interaction_requested.get_connections():
		inst_nightclub.interaction_requested.disconnect(conn_p23a.callable)
	inst_nightclub.interaction_requested.connect(func(data):
		captured_dialogue_p23a.merge(data, true)
	)

	inst_nightclub._trigger_interaction()

	if captured_dialogue_p23a.get("type", "") != "dialogue" or captured_dialogue_p23a.get("dialogue_id", "") != "nightclub_bodyguard":
		printerr("FAIL 23-A: Bodyguard interaction should dispatch dialogue 'nightclub_bodyguard', got: ", captured_dialogue_p23a)
		get_tree().quit(1)
		return

	inst_nightclub.free()

	print("PASS: Phase 23-A bodyguard, back_door block, and staff_pass_examine verified.")

