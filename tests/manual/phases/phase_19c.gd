extends "res://tests/manual/phases/phase_m1.gd"

func _run_phase_19c() -> void:
	# ===================== Phase 19-C: Memory Fragment "You Erased Ada"收束 =====================
	print("--- Phase 19-C: Memory Fragment 'You Erased Ada' verified ---")

	# 1. Verify MemoryFragmentErasedAda node in underground_settlement.tscn
	var settlement_scene_19c = load("res://scenes/levels/underground_settlement/underground_settlement.tscn")
	if settlement_scene_19c == null:
		printerr("FAIL 19-C: could not load underground_settlement.tscn!")
		get_tree().quit(1)
		return

	var settlement_inst_19c = settlement_scene_19c.instantiate()
	var fragment_node = settlement_inst_19c.find_child("MemoryFragmentErasedAda", true, false)
	if fragment_node == null:
		printerr("FAIL 19-C: MemoryFragmentErasedAda node not found in underground_settlement.tscn!")
		get_tree().quit(1)
		return

	if fragment_node.fragment_flag != "mem_frag_erased_ada" or \
	   fragment_node.message_id != "mem_frag_erased_ada" or \
	   fragment_node.require_flag != "read_old_work_order":
		printerr("FAIL 19-C: MemoryFragmentErasedAda properties mismatch!")
		get_tree().quit(1)
		return

	# 2. Test trigger before read_old_work_order is true
	GameState.reset_for_new_game()

	var last_frag_msg = {"text": ""}
	var on_frag_msg = func(data: Dictionary):
		if data.get("type") == "message":
			last_frag_msg["text"] = data.get("message_text", "")
	settlement_inst_19c.interaction_requested.connect(on_frag_msg)

	var player_node_phase19c_frag = settlement_inst_19c.find_child("Player", true, false)
	fragment_node._on_body_entered(player_node_phase19c_frag)

	if last_frag_msg["text"] != "":
		printerr("FAIL 19-C: Fragment triggered before read_old_work_order flag is true!")
		get_tree().quit(1)
		return

	if GameState.get_flag("mem_frag_erased_ada", false):
		printerr("FAIL 19-C: mem_frag_erased_ada flag set prematurely!")
		get_tree().quit(1)
		return

	# 3. Test trigger after read_old_work_order is true
	GameState.set_flag("read_old_work_order", true)
	fragment_node._on_body_entered(player_node_phase19c_frag)

	if last_frag_msg["text"] != "MSG_MEM_FRAG_ERASED_ADA":
		printerr("FAIL 19-C: Expected MSG_MEM_FRAG_ERASED_ADA, got: ", last_frag_msg["text"])
		get_tree().quit(1)
		return

	if not GameState.get_flag("mem_frag_erased_ada", false):
		printerr("FAIL 19-C: mem_frag_erased_ada flag not set to true after trigger!")
		get_tree().quit(1)
		return

	# 4. Test one-shot guard (does not trigger again)
	last_frag_msg["text"] = ""
	fragment_node._on_body_entered(player_node_phase19c_frag)

	if last_frag_msg["text"] != "":
		printerr("FAIL 19-C: Fragment triggered twice!")
		get_tree().quit(1)
		return

	# 5. Verification of forbidden words
	for lang in ["zh_TW", "zh_CN", "en"]:
		LocaleManager.set_locale(lang)
		var txt = tr("MSG_MEM_FRAG_ERASED_ADA")
		if lang == "en":
			var lower_txt = txt.to_lower()
			if "lin fei" in lower_txt or "linfei" in lower_txt:
				printerr("FAIL 19-C: Forbidden word Lin Fei found in MSG_MEM_FRAG_ERASED_ADA for lang: ", lang)
				get_tree().quit(1)
				return
		else:
			if "林霏" in txt:
				printerr("FAIL 19-C: Forbidden word 林霏 found in MSG_MEM_FRAG_ERASED_ADA for lang: ", lang)
				get_tree().quit(1)
				return

	LocaleManager.set_locale("zh_TW")
	settlement_inst_19c.free()
	print("PASS: Phase 19-C Memory Fragment 'You Erased Ada' verified.")

