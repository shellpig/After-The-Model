extends "res://tests/manual/phases/phase_25a.gd"

func _run_phase_24c() -> void:
	# ===================== Phase 24-C: 深隧道追逐 + 兩去處選單接線 =====================
	print("--- Phase 24-C: 深隧道追逐 + 兩去處選單接線 ---")

	# 1. 目的地選單對話樹加載
	var travel_tree_p24c = DialogueDB.get_tree_for("travel_deep_tunnel")
	if travel_tree_p24c == null or not travel_tree_p24c.has("start"):
		printerr("FAIL 24-C: travel_deep_tunnel dialogue tree missing or empty!")
		get_tree().quit(1)
		return

	# 2. 測試場景加載與結構
	var chase1_scene_p24c = load("res://scenes/levels/tunnel_chase/tunnel_chase.tscn")
	if chase1_scene_p24c == null:
		printerr("FAIL 24-C: tunnel_chase.tscn could not be loaded!")
		get_tree().quit(1)
		return
	var chase1_inst_p24c = chase1_scene_p24c.instantiate()
	if chase1_inst_p24c == null:
		printerr("FAIL 24-C: tunnel_chase.tscn could not be instantiated!")
		get_tree().quit(1)
		return
	if not chase1_inst_p24c.has_node("Player") or not chase1_inst_p24c.has_node("Camera2D") or not chase1_inst_p24c.has_node("Interactables/ChaseLadder") or not chase1_inst_p24c.has_node("Interactables/ChaseDoor"):
		printerr("FAIL 24-C: tunnel_chase.tscn missing critical nodes!")
		get_tree().quit(1)
		return
	chase1_inst_p24c.free()

	var chase2_scene_p24c = load("res://scenes/levels/tunnel_chase/tunnel_chase_right.tscn")
	if chase2_scene_p24c == null:
		printerr("FAIL 24-C: tunnel_chase_right.tscn could not be loaded!")
		get_tree().quit(1)
		return
	var chase2_inst_p24c = chase2_scene_p24c.instantiate()
	if chase2_inst_p24c == null:
		printerr("FAIL 24-C: tunnel_chase_right.tscn could not be instantiated!")
		get_tree().quit(1)
		return
	if not chase2_inst_p24c.has_node("Player") or not chase2_inst_p24c.has_node("Camera2D") or not chase2_inst_p24c.has_node("Interactables/ChaseLadder") or not chase2_inst_p24c.has_node("Interactables/ChaseExit0") or not chase2_inst_p24c.has_node("Interactables/ChaseBacktrack"):
		printerr("FAIL 24-C: tunnel_chase_right.tscn missing critical nodes!")
		get_tree().quit(1)
		return
	chase2_inst_p24c.free()

	# 3. 測試隨機真出口與 reset 歸零
	GameState.reset_for_new_game()
	var exit_val_p24c = GameState.tunnel_chase_true_exit
	if exit_val_p24c < 0 or exit_val_p24c > 2:
		printerr("FAIL 24-C: tunnel_chase_true_exit should be between 0 and 2 after reset!")
		get_tree().quit(1)
		return
	if GameState._tunnel_chase_time_left != 180.0:
		printerr("FAIL 24-C: _tunnel_chase_time_left should be initialized to 180 after reset!")
		get_tree().quit(1)
		return

	# 4. 測試存讀檔持久化 round-trip
	GameState.set_flag("deep_tunnel_opened", true)
	GameState.tunnel_chase_true_exit = 1
	var save_data_p24c = SaveSystem.capture("underground_settlement_right", 100.0, 1)

	GameState.reset_for_new_game()
	SaveSystem.apply(save_data_p24c)
	if not GameState.get_flag("deep_tunnel_opened", false) or GameState.tunnel_chase_true_exit != 1:
		printerr("FAIL 24-C: Save/Load round-trip for chase state failed!")
		get_tree().quit(1)
		return

	# 5. 測試 undergound_settlement_right 深隧道口路由
	var settlement_r_scene_p24c = load("res://scenes/levels/underground_settlement/underground_settlement_right.tscn")
	var settlement_r_inst_p24c = settlement_r_scene_p24c.instantiate()
	add_child(settlement_r_inst_p24c)

	# Case A: deep_tunnel_opened = false
	GameState.set_flag("deep_tunnel_opened", false)
	var deep_tunnel_node_p24c = settlement_r_inst_p24c.get_node("Interactables/DeepTunnelArea")
	settlement_r_inst_p24c.current_interactable = deep_tunnel_node_p24c

	# Hook transition requested signal to verify target
	var transition_result_p24c := {"target": ""}
	settlement_r_inst_p24c.scene_transition_requested.connect(func(scene_id, _entry, _payload):
		transition_result_p24c["target"] = scene_id
	)
	var interaction_result_p24c := {"dialogue_id": ""}
	settlement_r_inst_p24c.interaction_requested.connect(func(data):
		if data.get("type") == "dialogue":
			interaction_result_p24c["dialogue_id"] = data.get("dialogue_id")
	)

	settlement_r_inst_p24c._trigger_interaction()
	if transition_result_p24c["target"] != "tunnel_combat":
		printerr("FAIL 24-C: when deep_tunnel_opened=false, deep_tunnel interaction must route to tunnel_combat transition! Got: ", transition_result_p24c["target"])
		get_tree().quit(1)
		return

	# Case B: deep_tunnel_opened = true
	GameState.set_flag("deep_tunnel_opened", true)
	settlement_r_inst_p24c._trigger_interaction()
	if interaction_result_p24c["dialogue_id"] != "travel_deep_tunnel":
		printerr("FAIL 24-C: when deep_tunnel_opened=true, deep_tunnel interaction must route to travel_deep_tunnel dialogue! Got: ", interaction_result_p24c["dialogue_id"])
		get_tree().quit(1)
		return

	remove_child(settlement_r_inst_p24c)
	settlement_r_inst_p24c.free()

	# 6. 測試 undergound_settlement 小岑條件式移除
	var settlement_l_scene_p24c = load("res://scenes/levels/underground_settlement/underground_settlement.tscn")

	# Case A: cen_voiceprint_exposed = false
	GameState.set_flag("cen_voiceprint_exposed", false)
	var settlement_l_inst_a_p24c = settlement_l_scene_p24c.instantiate()
	add_child(settlement_l_inst_a_p24c)
	settlement_l_inst_a_p24c.set_entry_point("from_subway")
	var npc_cen_node_a_p24c = settlement_l_inst_a_p24c.get_node_or_null("Interactables/NpcCen")
	var empty_tent_node_a_p24c = settlement_l_inst_a_p24c.get_node_or_null("Interactables/EmptyTentArea")
	if npc_cen_node_a_p24c == null or npc_cen_node_a_p24c.is_queued_for_deletion():
		printerr("FAIL 24-C: Cen NPC should be present when cen_voiceprint_exposed is false!")
		get_tree().quit(1)
		return
	if empty_tent_node_a_p24c != null and empty_tent_node_a_p24c.visible:
		printerr("FAIL 24-C: Empty tent area should be hidden/disabled when cen_voiceprint_exposed is false!")
		get_tree().quit(1)
		return
	remove_child(settlement_l_inst_a_p24c)
	settlement_l_inst_a_p24c.free()

	# Case B: cen_voiceprint_exposed = true
	GameState.set_flag("cen_voiceprint_exposed", true)
	var settlement_l_inst_b_p24c = settlement_l_scene_p24c.instantiate()
	add_child(settlement_l_inst_b_p24c)
	settlement_l_inst_b_p24c.set_entry_point("from_subway")
	var npc_cen_node_b_p24c = settlement_l_inst_b_p24c.get_node_or_null("Interactables/NpcCen")
	var empty_tent_node_b_p24c = settlement_l_inst_b_p24c.get_node_or_null("Interactables/EmptyTentArea")
	if npc_cen_node_b_p24c != null and not npc_cen_node_b_p24c.is_queued_for_deletion():
		printerr("FAIL 24-C: Cen NPC should be queue_free when cen_voiceprint_exposed is true!")
		get_tree().quit(1)
		return
	if empty_tent_node_b_p24c == null or not empty_tent_node_b_p24c.visible:
		printerr("FAIL 24-C: Empty tent area should be active/visible when cen_voiceprint_exposed is true!")
		get_tree().quit(1)
		return
	remove_child(settlement_l_inst_b_p24c)
	settlement_l_inst_b_p24c.free()

	# 7. 測試結算後 retalk 不進追逐
	GameState.reset_for_new_game()
	GameState.set_flag("seven_betrayal_triggered", true)
	GameState.set_flag("seven_betrayal_pending", false)
	GameState.set_flag("met_seven", true)
	var seven_tree_p24c = DialogueDB.get_tree_for("seven")
	var target_node_p24c := ""
	for branch in seven_tree_p24c["start"]["goto"]:
		var cond = branch.get("condition")
		var matched = true
		if cond is Array:
			for item in cond:
				var f = item.get("flag")
				var op = item.get("op")
				var val = item.get("value")
				var current_val = GameState.get_flag(f, false)
				if op == "==" and current_val != val:
					matched = false
					break
				elif op == "!=" and current_val == val:
					matched = false
					break
		elif cond is Dictionary:
			var f = cond.get("flag")
			var op = cond.get("op")
			var val = cond.get("value")
			var current_val = GameState.get_flag(f, false)
			if op == "==" and current_val != val:
				matched = false
			elif op == "!=" and current_val == val:
				matched = false
		else:
			matched = true

		if matched:
			target_node_p24c = branch.get("target")
			break

	if target_node_p24c == "betrayal_start":
		printerr("FAIL 24-C: Seven dialogue should not route to betrayal_start after quest completes!")
		get_tree().quit(1)
		return
	if target_node_p24c != "retalk":
		printerr("FAIL 24-C: Seven dialogue should route to retalk when seven_betrayal_pending=false and met_seven=true! Got: ", target_node_p24c)
		get_tree().quit(1)
		return

	print("PASS: Phase 24-C deep tunnel chase & travel menu verified.")

