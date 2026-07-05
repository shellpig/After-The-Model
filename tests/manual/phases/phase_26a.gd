extends "res://tests/manual/phases/phase_26b.gd"

func _run_phase_26a() -> void:
	# ===================== Phase 26-A: 晚拉扯演出 =====================
	print("--- Phase 26-A: 晚拉扯演出 ---")

	GameState.reset_for_new_game()
	var entrance_inst_phase26a = load("res://scenes/levels/datacenter_entrance/datacenter_entrance.tscn").instantiate()

	var wan_trigger_phase26a = entrance_inst_phase26a.get_node("Interactables/WanPullTriggerArea")
	var wan_npc_phase26a = entrance_inst_phase26a.get_node("Interactables/WanDatacenterNPC")
	if wan_trigger_phase26a == null or wan_npc_phase26a == null:
		printerr("FAIL 26-A: datacenter_entrance missing WanPullTriggerArea / WanDatacenterNPC nodes!")
		get_tree().quit(1)
		return

	var captured_pull_phase26a: Dictionary = {}
	entrance_inst_phase26a.interaction_requested.connect(func(data):
		captured_pull_phase26a.merge(data, true)
	)

	var fake_player_phase26a := Node2D.new()
	fake_player_phase26a.name = "Player"

	# 1. UIMode 非 NONE 時不觸發
	UIMode.current_mode = UIMode.Mode.DIALOGUE
	wan_trigger_phase26a._on_body_entered(fake_player_phase26a)
	if not captured_pull_phase26a.is_empty():
		printerr("FAIL 26-A: WanPullTriggerArea should not fire while UIMode is not NONE!")
		get_tree().quit(1)
		return
	UIMode.current_mode = UIMode.Mode.NONE

	# 2. 首次走近觸發 dialogue 派發
	wan_trigger_phase26a._on_body_entered(fake_player_phase26a)
	if captured_pull_phase26a.get("type", "") != "dialogue" or captured_pull_phase26a.get("dialogue_id", "") != "wan_datacenter":
		printerr("FAIL 26-A: WanPullTriggerArea body_entered should dispatch wan_datacenter dialogue!")
		get_tree().quit(1)
		return

	# 3. 對話樹兩句拍板台詞一次給足 + 結尾設旗標（模擬 DialoguePanel 走完整段）
	var wan_dc_tree_phase26a = DialogueDB.get_tree_for("wan_datacenter")
	if wan_dc_tree_phase26a.is_empty():
		printerr("FAIL 26-A: wan_datacenter dialogue tree not registered in DialogueDB!")
		get_tree().quit(1)
		return

	var runner_pull_phase26a = DialogueRunner.new()
	runner_pull_phase26a.start(wan_dc_tree_phase26a)
	if runner_pull_phase26a.current().get("text", "") != "DLG_WAN_DATACENTER_PULL_SAFE_TEXT":
		printerr("FAIL 26-A: first-time wan_datacenter dialogue should open on the safe-version pull line!")
		get_tree().quit(1)
		return
	if GameState.get_flag("wan_act4_pull_seen", false):
		printerr("FAIL 26-A: wan_act4_pull_seen must not be set before the private line is reached!")
		get_tree().quit(1)
		return
	# DialogueRunner applies node-level "effect" immediately on entering a node
	# (see scripts/dialogue/dialogue_runner.gd _enter_node), so the flag flips
	# as soon as advance() moves into "pull_private", not on a further advance().
	runner_pull_phase26a.advance()
	if runner_pull_phase26a.current().get("text", "") != "DLG_WAN_DATACENTER_PULL_PRIVATE_TEXT":
		printerr("FAIL 26-A: wan_datacenter dialogue should follow with the private-version pull line!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("wan_act4_pull_seen", false):
		printerr("FAIL 26-A: wan_act4_pull_seen should be set once the private-version pull line is reached!")
		get_tree().quit(1)
		return

	# 4. 旗標已設後：觸發區重入不重播
	captured_pull_phase26a.clear()
	wan_trigger_phase26a._on_body_entered(fake_player_phase26a)
	if not captured_pull_phase26a.is_empty():
		printerr("FAIL 26-A: WanPullTriggerArea must not re-fire once wan_act4_pull_seen is true!")
		get_tree().quit(1)
		return

	# 5. 旗標已設後：對話重講走 retalk 短版
	var runner_retalk_phase26a = DialogueRunner.new()
	runner_retalk_phase26a.start(wan_dc_tree_phase26a)
	if runner_retalk_phase26a.current().get("text", "") != "DLG_WAN_DATACENTER_RETALK_TEXT":
		printerr("FAIL 26-A: wan_datacenter should route to retalk once wan_act4_pull_seen is true!")
		get_tree().quit(1)
		return

	# 6. 標準 E 互動（WanDatacenterNPC）走 dialogue_id 標準派發鏈（datacenter_entrance.gd dispatch）
	captured_pull_phase26a.clear()
	entrance_inst_phase26a.current_interactable = wan_npc_phase26a
	entrance_inst_phase26a._trigger_interaction()
	if captured_pull_phase26a.get("type", "") != "dialogue" or captured_pull_phase26a.get("dialogue_id", "") != "wan_datacenter":
		printerr("FAIL 26-A: WanDatacenterNPC standard E-interact should dispatch wan_datacenter dialogue!")
		get_tree().quit(1)
		return

	# 7. 拉扯不擋門禁：齊備 badge + read_old_work_order 後，門禁仍正常放行
	GameState.add_item("old_work_badge", 1)
	GameState.set_flag("read_old_work_order", true)
	var captured_gate_trans_phase26a: Dictionary = {}
	entrance_inst_phase26a.scene_transition_requested.connect(func(scene_id, entry_point_id, payload):
		captured_gate_trans_phase26a.merge({"scene": scene_id, "entry": entry_point_id}, true)
	)
	entrance_inst_phase26a.current_interactable = entrance_inst_phase26a.get_node("Interactables/MainGateArea")
	entrance_inst_phase26a._trigger_interaction()
	if captured_gate_trans_phase26a.get("scene", "") != "datacenter_backup" or captured_gate_trans_phase26a.get("entry", "") != "from_entrance":
		printerr("FAIL 26-A: main_gate should still transition normally after the Wan pull sequence (拉扯不擋門禁)!")
		get_tree().quit(1)
		return

	fake_player_phase26a.free()
	entrance_inst_phase26a.free()

	GameState.reset_for_new_game()
	print("PASS: Phase 26-A Wan pull performance (auto-trigger + retalk routing + standard E-interact dispatch + gate unaffected) verified.")

