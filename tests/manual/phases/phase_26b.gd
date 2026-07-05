extends "res://tests/manual/phases/phase_26c.gd"

func _run_phase_26b() -> void:
	# ===================== Phase 26-B: 阿達④本人短暫登場 =====================
	print("--- Phase 26-B: 阿達④本人短暫登場 ---")
	UIMode.current_mode = UIMode.Mode.NONE

	# 1. 順序護欄：缺 read_old_work_order 時本趟不登場（④不得早於③）
	GameState.reset_for_new_game()
	var entrance_inst_phase26b_gate = load("res://scenes/levels/datacenter_entrance/datacenter_entrance.tscn").instantiate()
	add_child(entrance_inst_phase26b_gate)
	await get_tree().process_frame
	if entrance_inst_phase26b_gate.get_node_or_null("Interactables/AdaNPC") != null or entrance_inst_phase26b_gate.get_node_or_null("Interactables/AdaTriggerArea") != null:
		printerr("FAIL 26-B: Ada should not spawn this visit without read_old_work_order (順序護欄 ④不早於③)!")
		get_tree().quit(1)
		return
	entrance_inst_phase26b_gate.free()
	await get_tree().process_frame

	# 2. 已看過（ada_final_words_seen=true）：即使補上 read_old_work_order，重進場景也永久不生成
	GameState.reset_for_new_game()
	GameState.set_flag("read_old_work_order", true)
	GameState.set_flag("ada_final_words_seen", true)
	var entrance_inst_phase26b_seen = load("res://scenes/levels/datacenter_entrance/datacenter_entrance.tscn").instantiate()
	add_child(entrance_inst_phase26b_seen)
	await get_tree().process_frame
	if entrance_inst_phase26b_seen.get_node_or_null("Interactables/AdaNPC") != null or entrance_inst_phase26b_seen.get_node_or_null("Interactables/AdaTriggerArea") != null:
		printerr("FAIL 26-B: Ada must stay permanently gone once ada_final_words_seen is true!")
		get_tree().quit(1)
		return
	entrance_inst_phase26b_seen.free()
	await get_tree().process_frame

	# 3. 齊全條件：首次到場自動觸發，對話一拍無選項並立即設旗標
	GameState.reset_for_new_game()
	GameState.set_flag("read_old_work_order", true)
	var entrance_inst_phase26b = load("res://scenes/levels/datacenter_entrance/datacenter_entrance.tscn").instantiate()
	add_child(entrance_inst_phase26b)
	await get_tree().process_frame

	var ada_npc_phase26b = entrance_inst_phase26b.get_node_or_null("Interactables/AdaNPC")
	var ada_trigger_phase26b = entrance_inst_phase26b.get_node_or_null("Interactables/AdaTriggerArea")
	if ada_npc_phase26b == null or ada_trigger_phase26b == null:
		printerr("FAIL 26-B: Ada should spawn once read_old_work_order is satisfied and he hasn't spoken yet!")
		get_tree().quit(1)
		return

	var captured_ada_phase26b: Dictionary = {}
	entrance_inst_phase26b.interaction_requested.connect(func(data):
		captured_ada_phase26b.merge(data, true)
	)

	var fake_player_phase26b := Node2D.new()
	fake_player_phase26b.name = "Player"
	ada_trigger_phase26b._on_body_entered(fake_player_phase26b)
	if captured_ada_phase26b.get("type", "") != "dialogue" or captured_ada_phase26b.get("dialogue_id", "") != "ada":
		printerr("FAIL 26-B: AdaTriggerArea body_entered should dispatch the ada dialogue!")
		get_tree().quit(1)
		return

	var ada_tree_phase26b = DialogueDB.get_tree_for("ada")
	if ada_tree_phase26b.is_empty():
		printerr("FAIL 26-B: ada dialogue tree not registered in DialogueDB!")
		get_tree().quit(1)
		return

	var runner_ada_phase26b = DialogueRunner.new()
	runner_ada_phase26b.start(ada_tree_phase26b)
	if runner_ada_phase26b.current().get("text", "") != "DLG_ADA_FINAL_WORDS_TEXT":
		printerr("FAIL 26-B: ada dialogue should open directly on the final-words line (一拍、無選項)!")
		get_tree().quit(1)
		return
	if not runner_ada_phase26b.current().get("is_terminal", false):
		printerr("FAIL 26-B: ada dialogue should be a single terminal beat with no choices!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("ada_final_words_seen", false):
		printerr("FAIL 26-B: ada_final_words_seen should be set as soon as the final-words line is entered!")
		get_tree().quit(1)
		return

	# 4. 對話結束（UIMode 回 NONE）後：Tween 淡出 + 永久停用 AdaNPC / 觸發區
	UIMode.current_mode = UIMode.Mode.NONE
	entrance_inst_phase26b._update_ada_fade()
	if not entrance_inst_phase26b._ada_faded:
		printerr("FAIL 26-B: Ada should start fading out once ada_final_words_seen is true and UIMode is NONE!")
		get_tree().quit(1)
		return
	if entrance_inst_phase26b.get_node_or_null("Interactables/AdaTriggerArea") != null:
		printerr("FAIL 26-B: AdaTriggerArea should be removed immediately once the fade-out starts!")
		get_tree().quit(1)
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(ada_npc_phase26b) or ada_npc_phase26b.modulate.a >= 1.0:
		printerr("FAIL 26-B: AdaNPC should be tweening its modulate alpha down once the pull sequence finishes!")
		get_tree().quit(1)
		return

	# 5. Fade 窗口內（AdaNPC 尚未 queue_free）E 重談應失效，不可對半透明的阿達重播最後一句
	if ada_npc_phase26b.dialogue_id != "":
		printerr("FAIL 26-B: AdaNPC.dialogue_id should be cleared immediately once fade starts, to block E re-talk mid-fade!")
		get_tree().quit(1)
		return
	captured_ada_phase26b.clear()
	entrance_inst_phase26b.current_interactable = ada_npc_phase26b
	entrance_inst_phase26b._trigger_interaction()
	if not captured_ada_phase26b.is_empty():
		printerr("FAIL 26-B: pressing E on the fading AdaNPC must not replay the ada dialogue!")
		get_tree().quit(1)
		return

	fake_player_phase26b.free()
	entrance_inst_phase26b.free()
	await get_tree().process_frame

	GameState.reset_for_new_game()
	print("PASS: Phase 26-B Ada final appearance (sequencing guard + one-shot trigger + fade-out + permanent removal) verified.")

