extends "res://tests/manual/phases/phase_17c.gd"

func _run_phase_17b() -> void:
	# ===================== Phase 17-B: EchoPoint in underground_settlement_right =====================
	print("--- Phase 17-B: EchoPoint in underground_settlement_right ---")

	# 1. Verify EchoDB registry and data constraints
	if not EchoDB.has_echo("echo_settlement_erased"):
		printerr("FAIL 17-B: EchoDB missing 'echo_settlement_erased' record!")
		get_tree().quit(1)
		return

	var seg_count_17b = EchoDB.get_segment_count("echo_settlement_erased")
	if seg_count_17b != 2:
		printerr("FAIL 17-B: Expected 2 segments for 'echo_settlement_erased', got: ", seg_count_17b)
		get_tree().quit(1)
		return

	var echo_data_17b = EchoDB.get_echo("echo_settlement_erased")
	for seg in echo_data_17b.get("segments", []):
		if "林霏" in seg.get("text", ""):
			printerr("FAIL 17-B: Forbidden word '林霏' found in settlement echo text!")
			get_tree().quit(1)
			return

	# 2. Verify EchoPoint node in underground_settlement_right.tscn
	var settlement_right_scene = load("res://scenes/levels/underground_settlement/underground_settlement_right.tscn")
	var settlement_right_inst = settlement_right_scene.instantiate()
	get_tree().root.add_child(settlement_right_inst)
	var echo_point_node = settlement_right_inst.find_child("EchoPoint", true, false)
	if echo_point_node == null:
		printerr("FAIL 17-B: EchoPoint node not found in underground_settlement_right.tscn!")
		get_tree().quit(1)
		return

	if echo_point_node.echo_id != "echo_settlement_erased" or echo_point_node.segment_id != "s1":
		printerr("FAIL 17-B: EchoPoint properties mismatch! Got: echo_id=", echo_point_node.echo_id, " segment_id=", echo_point_node.segment_id)
		get_tree().quit(1)
		return

	# Verify position avoids NPC Wu, Seven, and Deep Tunnel
	var ep_pos = echo_point_node.position
	if ep_pos.x < 2200 or ep_pos.x > 3200:
		printerr("FAIL 17-B: EchoPoint position.x (", ep_pos.x, ") is not placed in the safe mid-right zone!")
		get_tree().quit(1)
		return

	# 3. Simulate equipment active state & collection mechanics
	# Set up environment
	GameState.reset_for_new_game()

	# Verify inactive without gloves
	echo_point_node._update_active_state()
	if echo_point_node.active:
		printerr("FAIL 17-B: EchoPoint should be inactive when gleaner_gloves are not equipped!")
		get_tree().quit(1)
		return

	# Equip gloves
	# We manually place gleaner_gloves in inventory and equip it
	GameState.add_item("gleaner_gloves")
	var gloves_instance_id_17b = ""
	for slot in GameState.get_inventory():
		if not slot.is_empty() and slot.get("item_id") == "gleaner_gloves":
			gloves_instance_id_17b = slot.get("instance_id")
			break
	GameState.equip(gloves_instance_id_17b)
	echo_point_node._update_active_state()

	if not echo_point_node.active:
		printerr("FAIL 17-B: EchoPoint should be active when gleaner_gloves are equipped!")
		get_tree().quit(1)
		return

	# Call collect on EchoPoint (this triggers collection and deactivates it)
	echo_point_node.collect()

	if not GameState.has_echo_segment("echo_settlement_erased", "s1"):
		printerr("FAIL 17-B: Echo segment not collected in GameState after collect()!")
		get_tree().quit(1)
		return

	# Re-evaluate active state (should be false since collected)
	echo_point_node._update_active_state()
	if echo_point_node.active:
		printerr("FAIL 17-B: EchoPoint should be inactive after collection!")
		get_tree().quit(1)
		return

	# 4. Save/Load (round-trip) verification for echo_progress
	GameState.reset_for_new_game()
	GameState.collect_echo_segment("echo_settlement_erased", "s1")
	var save_p17b = SaveSystem.capture("underground_settlement_right", 100.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_p17b):
		printerr("FAIL 17-B: Failed to write Phase 17-B save to scratch slot!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	if GameState.has_echo_segment("echo_settlement_erased", "s1"):
		printerr("FAIL 17-B: Echo segment flag not reset to false!")
		get_tree().quit(1)
		return

	var load_p17b = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	if load_p17b.is_empty():
		printerr("FAIL 17-B: Failed to read Phase 17-B save from scratch slot!")
		get_tree().quit(1)
		return
	SaveSystem.apply(load_p17b)

	if not GameState.has_echo_segment("echo_settlement_erased", "s1"):
		printerr("FAIL 17-B: Echo segment flag not restored from save!")
		get_tree().quit(1)
		return

	# Cleanup
	get_tree().root.remove_child(settlement_right_inst)
	settlement_right_inst.free()
	settlement_right_scene = null

	if dir and dir.file_exists(TEST_SCRATCH_SAVE_FILE):
		dir.remove(TEST_SCRATCH_SAVE_FILE)

	print("PASS: Phase 17-B EchoPoint and registry verified.")

