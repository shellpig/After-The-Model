extends "res://tests/manual/phases/phase_13f.gd"

func _run_phase_13d() -> void:
	# ===================== Phase 13-D: combat loss =====================
	print("--- Phase 13-D: combat loss ---")

	var combat_proto_scene = load("res://scenes/levels/combat_proto/combat_proto.tscn")
	if combat_proto_scene == null:
		printerr("FAIL 13-D: could not load combat_proto.tscn!")
		get_tree().quit(1)
		return
	print("PASS 13-D: combat_proto.tscn loaded.")

	var combat_inst = combat_proto_scene.instantiate()
	add_child(combat_inst)
	await get_tree().process_frame

	var combat_walker = combat_inst.find_child("Walker01", true, false)
	if combat_walker == null:
		printerr("FAIL 13-D: combat_proto missing Walker01 node!")
		get_tree().quit(1)
		return
	print("PASS 13-D: combat_proto has Walker01 node.")

	var combat_loss_node = combat_walker.find_child("CombatLoss", true, false)
	if combat_loss_node == null:
		printerr("FAIL 13-D: Walker01 missing CombatLoss child node!")
		get_tree().quit(1)
		return
	print("PASS 13-D: Walker01 has CombatLoss child node.")

	var test_player = combat_inst.find_child("Player", true, false)
	if test_player == null:
		printerr("FAIL 13-D: combat_proto missing Player node!")
		get_tree().quit(1)
		return
	print("PASS 13-D: combat_proto has Player node.")

	# Verify initial flag is false
	GameState.set_flag("combat_proto_failed", false)
	if GameState.get_flag("combat_proto_failed", false):
		printerr("FAIL 13-D: combat_proto_failed flag should start as false!")
		get_tree().quit(1)
		return

	# Case 1: When enemy is stunned, player entering CombatLoss Area2D does NOT trigger loss
	combat_walker._enter_state(2) # Force State.PRONE
	if not combat_walker.is_stunned():
		printerr("FAIL 13-D: Walker01 should be stunned in State.PRONE!")
		get_tree().quit(1)
		return

	# Simulate collision while stunned
	combat_loss_node._on_body_entered(test_player)
	if GameState.get_flag("combat_proto_failed", false):
		printerr("FAIL 13-D: CombatLoss should not trigger when enemy is stunned!")
		get_tree().quit(1)
		return
	print("PASS 13-D: Stunned enemy does not trigger loss on contact.")

	# Case 2: When enemy is NOT stunned, player entering CombatLoss Area2D triggers loss
	# We force Walker01 to recover from stun back to PATROL state
	combat_walker._enter_state(0) # State.PATROL
	if combat_walker.is_stunned():
		printerr("FAIL 13-D: Walker01 should not be stunned after recovering!")
		get_tree().quit(1)
		return

	# Place player at a specific location to verify teleportation works
	test_player.global_position = Vector2(800.0, 700.0)
	if "walk_line_y" in test_player:
		test_player.walk_line_y = 700.0

	var interaction_state = { "message_received": "" }
	var on_interaction = func(data):
		if data.get("type") == "message":
			interaction_state["message_received"] = data.get("message_text", "")

	combat_inst.interaction_requested.connect(on_interaction)

	# Simulate collision while active
	combat_loss_node._on_body_entered(test_player)

	# Verify flag
	if not GameState.get_flag("combat_proto_failed", false):
		printerr("FAIL 13-D: combat_proto_failed flag not set to true after contact!")
		get_tree().quit(1)
		return
	print("PASS 13-D: combat_proto_failed flag set to true after contact.")

	# Verify teleportation
	var expected_safe_point = Vector2(250.0, 690.0)
	if test_player.global_position != expected_safe_point:
		printerr("FAIL 13-D: Player not teleported to safe point! Found: ", test_player.global_position)
		get_tree().quit(1)
		return
	if test_player.walk_line_y != expected_safe_point.y:
		printerr("FAIL 13-D: Player walk_line_y not updated to safe point Y! Found: ", test_player.walk_line_y)
		get_tree().quit(1)
		return
	print("PASS 13-D: Player successfully teleported to safe point.")

	# Verify message
	if interaction_state["message_received"] == "":
		printerr("FAIL 13-D: Level did not emit interaction_requested message on loss!")
		get_tree().quit(1)
		return
	print("PASS 13-D: Level emitted interaction_requested message: ", interaction_state["message_received"])

	# Cleanup
	combat_inst.interaction_requested.disconnect(on_interaction)
	combat_inst.queue_free()
	await get_tree().process_frame
	print("PASS: Phase 13-D combat loss verified.")

