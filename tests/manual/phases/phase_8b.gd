extends "res://tests/manual/phases/phase_8c.gd"

func _run_phase_8b() -> void:
	# 27. Verify Phase 8-B Babble Dialogues & discovered_vendor_error Aggregation
	print("Verifying Phase 8-B babble dialogues & discovered_vendor_error aggregation...")

	GameState.reset_for_new_game()

	# 27.1 Street vending machine babble message + talked_outside_vendor (single side: no discovery)
	main_instance.transition_to("apartment_entrance", "from_apartment")
	await get_tree().process_frame

	var street_8b = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("apartment_entrance.gd"):
			street_8b = child
			break
	if not street_8b:
		printerr("FAIL: Current scene is not apartment_entrance for 8-B vending check!")
		get_tree().quit(1)
		return

	var vending_area_8b = street_8b.get_node_or_null("Interactables/VendingMachineArea")
	if not vending_area_8b:
		printerr("FAIL: VendingMachineArea not found in apartment_entrance!")
		get_tree().quit(1)
		return

	var vending_interaction_data = {}
	_temp_callable = func(data):
		vending_interaction_data.clear()
		vending_interaction_data.merge(data)
	street_8b.interaction_requested.connect(_temp_callable)

	street_8b.current_interactable = vending_area_8b
	street_8b._trigger_interaction()

	if vending_interaction_data.get("type") != "message" \
		or vending_interaction_data.get("message_text") != street_8b.MESSAGES["vending_machine"]:
		printerr("FAIL: Vending machine did not show babble message! Got: ", vending_interaction_data)
		get_tree().quit(1)
		return
	if not "辭呈" in vending_interaction_data.get("message_text", ""):
		printerr("FAIL: Vending babble text lacks the malfunction echo! Got: ", vending_interaction_data.get("message_text"))
		get_tree().quit(1)
		return
	if not GameState.has_flag("talked_outside_vendor"):
		printerr("FAIL: talked_outside_vendor not set after vending interaction!")
		get_tree().quit(1)
		return
	if GameState.has_flag("discovered_vendor_error"):
		printerr("FAIL: discovered_vendor_error set after only ONE machine was talked to!")
		get_tree().quit(1)
		return
	if GameState.has_note("clue_vendor_error_lead"):
		printerr("FAIL: clue_vendor_error_lead note added after only ONE machine was talked to!")
		get_tree().quit(1)
		return
	print("PASS: Vending machine babble sets talked_outside_vendor without premature discovery.")

	# 27.2 Robot babble tree: routing, anomaly text, talked_store_robot, aggregation completes
	DialogueDB = load("res://data/dialogue/dialogue_db.gd")
	var robot_tree = DialogueDB.get_tree_for("store_robot")
	if robot_tree.is_empty():
		printerr("FAIL: DialogueDB could not fetch store_robot tree!")
		get_tree().quit(1)
		return

	runner = DialogueRunner.new()
	var robot_dialogue_finished = {"value": false}
	var robot_finished_callable := func():
		robot_dialogue_finished["value"] = true
	runner.finished.connect(robot_finished_callable)
	runner.start(robot_tree)

	var robot_curr = runner.current()
	if tr(robot_curr.get("speaker")) != "店控機器人":
		printerr("FAIL: store_robot speaker is wrong! Got: ", tr(robot_curr.get("speaker")))
		get_tree().quit(1)
		return
	if not "排班表" in tr(robot_curr.get("text", "")):
		printerr("FAIL: babble_intro text lacks the schedule anomaly! Got: ", tr(robot_curr.get("text")))
		get_tree().quit(1)
		return
	if not GameState.has_flag("talked_store_robot"):
		printerr("FAIL: talked_store_robot not set on babble_intro entry!")
		get_tree().quit(1)
		return
	if not GameState.has_flag("discovered_vendor_error"):
		printerr("FAIL: discovered_vendor_error not set after talking to BOTH machines!")
		get_tree().quit(1)
		return
	if not GameState.has_note("clue_vendor_error_lead"):
		printerr("FAIL: clue_vendor_error_lead note not added after talking to BOTH machines!")
		get_tree().quit(1)
		return
	print("PASS: Robot babble sets talked_store_robot and completes discovered_vendor_error aggregation.")

	# 27.3 Babble branch flow: deny choice reveals "not a vending machine", terminal finishes cleanly
	if robot_curr.get("choices", []).size() != 2:
		printerr("FAIL: babble_intro should expose 2 choices! Got: ", robot_curr.get("choices"))
		get_tree().quit(1)
		return
	runner.choose(0)
	robot_curr = runner.current()
	if not "我不是販賣機" in tr(robot_curr.get("text", "")):
		printerr("FAIL: babble_deny text lacks identity denial! Got: ", tr(robot_curr.get("text")))
		get_tree().quit(1)
		return
	runner.advance()
	robot_curr = runner.current()
	if not robot_curr.get("is_terminal", false):
		printerr("FAIL: babble_end should be a terminal node! Got: ", robot_curr)
		get_tree().quit(1)
		return
	runner.advance()
	if not robot_dialogue_finished["value"]:
		printerr("FAIL: store_robot babble dialogue did not emit finished!")
		get_tree().quit(1)
		return
	runner.finished.disconnect(robot_finished_callable)
	print("PASS: Babble branch flow (deny -> end -> finished) verified.")

	# 27.4 Robot-only path: no discovery until vending machine is also talked to; repeats stay idempotent
	GameState.reset_for_new_game()
	runner = DialogueRunner.new()
	runner.start(robot_tree)
	if not GameState.has_flag("talked_store_robot"):
		printerr("FAIL: talked_store_robot not set in robot-only path!")
		get_tree().quit(1)
		return
	if GameState.has_flag("talked_outside_vendor") or GameState.has_flag("discovered_vendor_error") or GameState.has_note("clue_vendor_error_lead"):
		printerr("FAIL: Robot-only path leaked vendor/discovery/note flags!")
		get_tree().quit(1)
		return
	print("PASS: Robot-only path does not set discovered_vendor_error.")

	street_8b._trigger_interaction()
	if not GameState.has_flag("discovered_vendor_error"):
		printerr("FAIL: discovered_vendor_error not set once both sides are talked to (robot first)!")
		get_tree().quit(1)
		return
	if not GameState.has_note("clue_vendor_error_lead"):
		printerr("FAIL: clue_vendor_error_lead not set once both sides are talked to (robot first)!")
		get_tree().quit(1)
		return

	street_8b._trigger_interaction()
	runner = DialogueRunner.new()
	runner.start(robot_tree)
	if not (GameState.has_flag("talked_outside_vendor") and GameState.has_flag("talked_store_robot") and GameState.has_flag("discovered_vendor_error")):
		printerr("FAIL: Flags regressed after repeated interactions!")
		get_tree().quit(1)
		return
	street_8b.interaction_requested.disconnect(_temp_callable)
	print("PASS: Reverse order discovery and repeated-interaction idempotence verified.")

	# 27.5 Store robot interactable dispatches dialogue (not examine message)
	var store_scene = load("res://scenes/levels/convenience_store/convenience_store.tscn")
	var store_instance_8b = store_scene.instantiate()
	add_child(store_instance_8b)

	var robot_area_8b = store_instance_8b.get_node_or_null("Interactables/StoreRobotArea")
	if not robot_area_8b:
		printerr("FAIL: StoreRobotArea not found in convenience_store!")
		get_tree().quit(1)
		return
	if robot_area_8b.dialogue_id != "store_robot":
		printerr("FAIL: StoreRobotArea dialogue_id is not 'store_robot'! Got: ", robot_area_8b.dialogue_id)
		get_tree().quit(1)
		return

	var robot_dispatch_data = {}
	_temp_callable = func(data):
		robot_dispatch_data.clear()
		robot_dispatch_data.merge(data)
	store_instance_8b.interaction_requested.connect(_temp_callable)
	store_instance_8b.current_interactable = robot_area_8b
	store_instance_8b._trigger_interaction()

	if robot_dispatch_data.get("type") != "dialogue" or robot_dispatch_data.get("dialogue_id") != "store_robot":
		printerr("FAIL: Store robot interaction did not dispatch dialogue! Got: ", robot_dispatch_data)
		get_tree().quit(1)
		return
	store_instance_8b.interaction_requested.disconnect(_temp_callable)
	store_instance_8b.free()
	store_scene = null
	print("PASS: Store robot interactable dispatches store_robot dialogue.")

	print("PASS: Phase 8-B babble dialogues & discovered_vendor_error verified successfully.")

	# ==============================================================
