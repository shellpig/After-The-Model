extends "res://tests/manual/phases/phase_19b.gd"

func _run_phase_19a() -> void:
	# ===================== Phase 19-A: Ada's Echo in Underground Settlement Left =====================
	print("--- Phase 19-A: Ada's Echo in Underground Settlement Left ---")

	# Verify EchoDB config
	if not EchoDB.has_echo("echo_ada_reset"):
		printerr("FAIL 19-A: EchoDB missing 'echo_ada_reset' record!")
		get_tree().quit(1)
		return

	var seg_count_19a = EchoDB.get_segment_count("echo_ada_reset")
	if seg_count_19a != 1:
		printerr("FAIL 19-A: Expected 1 segment for 'echo_ada_reset', got: ", seg_count_19a)
		get_tree().quit(1)
		return

	var echo_data_19a = EchoDB.get_echo("echo_ada_reset")
	if echo_data_19a.get("trace_on_collect", 0) != 1:
		printerr("FAIL 19-A: echo_ada_reset missing trace_on_collect = 1!")
		get_tree().quit(1)
		return

	# Verify media layers path
	if echo_data_19a.get("image_path", "") != "res://assets/images/echoes/echo_ada_reset.jpeg":
		printerr("FAIL 19-A: echo_ada_reset image_path is incorrect or missing!")
		get_tree().quit(1)
		return

	# Verify EchoPoint node in underground_settlement.tscn
	var settlement_left_scene = load("res://scenes/levels/underground_settlement/underground_settlement.tscn")
	if settlement_left_scene == null:
		printerr("FAIL 19-A: could not load underground_settlement.tscn!")
		get_tree().quit(1)
		return

	var left_instance = settlement_left_scene.instantiate()
	var echo_point_node_19a = left_instance.find_child("EchoPoint", true, false)
	if echo_point_node_19a == null:
		printerr("FAIL 19-A: EchoPoint node not found in underground_settlement.tscn!")
		get_tree().quit(1)
		return

	if echo_point_node_19a.echo_id != "echo_ada_reset" or echo_point_node_19a.segment_id != "s1":
		printerr("FAIL 19-A: EchoPoint properties mismatch in underground_settlement.tscn!")
		get_tree().quit(1)
		return
	left_instance.free()

	# Verify collection mechanics
	GameState.reset_for_new_game()
	GameState.add_item("gleaner_gloves")

	# Find gloves instance ID
	var gloves_inst := ""
	for slot in GameState.inventory:
		if not slot.is_empty() and slot.get("item_id") == "gleaner_gloves":
			gloves_inst = slot.get("instance_id")
			break
	if gloves_inst.is_empty():
		printerr("FAIL 19-A: gloves_inst not found in inventory!")
		get_tree().quit(1)
		return
	GameState.equip(gloves_inst)

	var initial_trace = GameState.get_trace()
	if initial_trace != 0:
		printerr("FAIL 19-A: Initial trace is not 0!")
		get_tree().quit(1)
		return

	var collect_success = GameState.collect_echo_segment("echo_ada_reset", "s1")
	if not collect_success:
		printerr("FAIL 19-A: collect_echo_segment failed for echo_ada_reset!")
		get_tree().quit(1)
		return

	if not GameState.has_echo_segment("echo_ada_reset", "s1"):
		printerr("FAIL 19-A: segment not marked collected after collect!")
		get_tree().quit(1)
		return

	if not GameState.is_echo_complete("echo_ada_reset"):
		printerr("FAIL 19-A: echo_ada_reset not complete after segment collect!")
		get_tree().quit(1)
		return

	var post_collect_trace = GameState.get_trace()
	if post_collect_trace != 1:
		printerr("FAIL 19-A: trace did not increment by 1 after complete! Got: ", post_collect_trace)
		get_tree().quit(1)
		return

	# Try double collect
	var double_collect = GameState.collect_echo_segment("echo_ada_reset", "s1")
	if double_collect:
		printerr("FAIL 19-A: collect_echo_segment returned true for already collected segment!")
		get_tree().quit(1)
		return

	if GameState.get_trace() != 1:
		printerr("FAIL 19-A: trace changed on double collect attempt!")
		get_tree().quit(1)
		return

	# Verify selling echo reduces trace
	var sell_res_19a = GameState.sell_echo("echo_ada_reset")
	if not sell_res_19a:
		printerr("FAIL 19-A: sell_echo failed for echo_ada_reset!")
		get_tree().quit(1)
		return

	if GameState.get_trace() != 0:
		printerr("FAIL 19-A: trace did not decrease by 1 after sell! Got: ", GameState.get_trace())
		get_tree().quit(1)
		return

	# Verification of forbidden words
	LocaleManager.set_locale("zh_TW")
	if "林霏" in tr("ECHO_ADA_RESET_TITLE") or "林霏" in tr("ECHO_ADA_RESET_SEG_S1") or "林霏" in tr("ECHO_ADA_RESET_COMMENT"):
		printerr("FAIL 19-A: Forbidden word '林霏' found in zh_TW!")
		get_tree().quit(1)
		return

	LocaleManager.set_locale("zh_CN")
	if "林霏" in tr("ECHO_ADA_RESET_TITLE") or "林霏" in tr("ECHO_ADA_RESET_SEG_S1") or "林霏" in tr("ECHO_ADA_RESET_COMMENT"):
		printerr("FAIL 19-A: Forbidden word '林霏' found in zh_CN!")
		get_tree().quit(1)
		return

	LocaleManager.set_locale("en")
	var lower_en_title = tr("ECHO_ADA_RESET_TITLE").to_lower()
	var lower_en_seg = tr("ECHO_ADA_RESET_SEG_S1").to_lower()
	var lower_en_comment = tr("ECHO_ADA_RESET_COMMENT").to_lower()
	if "lin fei" in lower_en_title or "linfei" in lower_en_title or \
	   "lin fei" in lower_en_seg or "linfei" in lower_en_seg or \
	   "lin fei" in lower_en_comment or "linfei" in lower_en_comment:
		printerr("FAIL 19-A: Forbidden word 'Lin Fei/Linfei' found in en!")
		get_tree().quit(1)
		return

	LocaleManager.set_locale("zh_TW")
	print("PASS: Phase 19-A Ada's Echo and trace_on_collect verified.")

