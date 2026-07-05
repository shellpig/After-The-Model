extends "res://tests/manual/phases/phase_8e.gd"

func _run_phase_8d() -> void:
	# ---- Phase 8-D: 蒐證 + 診斷對話樹 ----
	print("Verifying Phase 8-D: clues examine & store robot diagnostic tree...")

	var store_scene = load("res://scenes/levels/convenience_store/convenience_store.tscn")
	if not store_scene:
		printerr("FAIL 8-D: Could not load convenience_store.tscn!")
		get_tree().quit(1)
		return

	var store_instance = store_scene.instantiate()
	add_child(store_instance)
	await get_tree().process_frame

	var locker_area = store_instance.get_node_or_null("Interactables/ClerkLockerArea")
	var diary_area = store_instance.get_node_or_null("Interactables/ClerkDiaryArea")
	var notice_area = store_instance.get_node_or_null("Interactables/TerminationNoticeArea")
	var photo_area = store_instance.get_node_or_null("Interactables/CounterPhotoArea")
	var plate_area = store_instance.get_node_or_null("Interactables/RobotPlateArea")
	var host_area = store_instance.get_node_or_null("Interactables/StoreRegistryHostArea")

	if not locker_area or not diary_area or not notice_area or not photo_area or not plate_area or not host_area:
		printerr("FAIL 8-D: Clue areas or host area not found in convenience_store.tscn!")
		get_tree().quit(1)
		return
	print("PASS 8-D: Clue areas and host area exist in convenience_store.tscn.")

	# ---- Test 1: Gating before quest is active ----
	if GameState.quest_states.has("repair_vendor_bot"):
		GameState.quest_states.erase("repair_vendor_bot")

	store_instance.nearby_interactables.clear()
	for area in [locker_area, diary_area, notice_area, photo_area, plate_area, host_area]:
		store_instance.nearby_interactables.append(area)
	var closest_before = store_instance._get_closest_interactable()
	if closest_before != null:
		printerr("FAIL 8-D: Clues and host should be gated and ignored before quest is active! Got: ", closest_before.name)
		get_tree().quit(1)
		return
	print("PASS 8-D: Clue areas and host area are gated before quest is active.")

	# ---- Test 2: Gating after quest is active ----
	QuestManager.start("repair_vendor_bot")
	# Clues should now be accessible, but host is still gated since mainframe_revealed is false
	store_instance.nearby_interactables.clear()
	store_instance.nearby_interactables.append(locker_area)
	var closest_after_locker = store_instance._get_closest_interactable()
	if closest_after_locker != locker_area:
		printerr("FAIL 8-D: locker_area should be accessible after quest is active!")
		get_tree().quit(1)
		return

	store_instance.nearby_interactables.clear()
	store_instance.nearby_interactables.append(host_area)
	var closest_after_host = store_instance._get_closest_interactable()
	if closest_after_host != null:
		printerr("FAIL 8-D: host_area should remain gated before mainframe_revealed is true!")
		get_tree().quit(1)
		return
	print("PASS 8-D: Clue areas accessible and host area remains gated after quest is active.")

	# ---- Test 3: Clue examine & note creation ----
	GameState.notes.clear()
	var clue_emit_data = {}
	_temp_callable = func(data):
		clue_emit_data.clear()
		clue_emit_data.merge(data)
	store_instance.interaction_requested.connect(_temp_callable)

	var clue_areas = [locker_area, diary_area, notice_area, photo_area, plate_area]
	var expected_note_ids = ["clue_clerk_locker", "clue_clerk_diary", "clue_termination_notice", "clue_counter_photo", "clue_robot_plate"]

	for i in range(clue_areas.size()):
		var area = clue_areas[i]
		var note_id = expected_note_ids[i]

		# First examine
		store_instance.current_interactable = area
		store_instance._trigger_interaction()

		if clue_emit_data.get("type") != "message" or clue_emit_data.get("note_title", "") == "":
			printerr("FAIL 8-D: First examine on " + area.name + " should show message and note_title toast! Got: ", clue_emit_data)
			get_tree().quit(1)
			return

		if not GameState.has_note(note_id):
			printerr("FAIL 8-D: GameState should have note: " + note_id)
			get_tree().quit(1)
			return

		# Second examine: toast should be empty (no duplicate note notification)
		clue_emit_data.clear()
		store_instance._trigger_interaction()
		if clue_emit_data.get("note_title", "") != "":
			printerr("FAIL 8-D: Repeated examine on " + area.name + " should not toast note_title!")
			get_tree().quit(1)
			return

		var notes_list = GameState.get_notes("線索")
		var note_count = 0
		for n in notes_list:
			if n.get("id") == note_id:
				note_count += 1
		if note_count != 1:
			printerr("FAIL 8-D: Note " + note_id + " should not be duplicated! Got count: ", note_count)
			get_tree().quit(1)
			return

	print("PASS 8-D: All 5 clues successfully examined, notes created and deduplicated.")

	# ---- Test 4: Dialogue option gating depending on note presence ----
	var robot_tree = DialogueDB.get_tree_for("store_robot")
	if robot_tree.is_empty():
		printerr("FAIL 8-D: DialogueDB store_robot tree not found!")
		get_tree().quit(1)
		return

	var diag_runner = DialogueRunner.new()

	# Clear clue notes temporarily to test gating
	GameState.notes.clear()
	diag_runner.start(robot_tree, "diagnose_intro")

	var node_identity = robot_tree["diagnose_identity"]
	diag_runner._enter_node("diagnose_identity")
	var curr_identity = diag_runner.current()

	var choices_identity = curr_identity.get("choices", [])
	# Without clues, correct option (index 1) should be hidden, leaving only index 0 and 2
	var found_correct_identity := false
	for choice in choices_identity:
		if choice.get("index") == 1:
			found_correct_identity = true
	if found_correct_identity:
		printerr("FAIL 8-D: Correct identity choice should be gated/hidden without clues!")
		get_tree().quit(1)
		return
	print("PASS 8-D: Correct identity choice gated without clues.")

	# ---- Test 5: Dialogue tree full-truth path flow (all clues found) ----
	# Restore all clue notes
	for note_id in expected_note_ids:
		var note_data = store_instance.NOTES[note_id]
		GameState.add_knowledge(note_data)

	# Start dialogue from diagnose_intro
	diag_runner.start(robot_tree, "diagnose_intro")

	# Intro choices: index 0 (進行診斷) -> diagnose_identity
	var curr_node = diag_runner.current()
	if curr_node.choices.size() != 2:
		printerr("FAIL 8-D: diagnose_intro choices size mismatch! Got: ", curr_node.choices.size())
		get_tree().quit(1)
		return

	diag_runner.choose(0) # We go to diagnose_identity
	curr_node = diag_runner.current()
	if diag_runner._current_node_id != "diagnose_identity":
		printerr("FAIL 8-D: Should enter diagnose_identity! Got: ", diag_runner._current_node_id)
		get_tree().quit(1)
		return

	# Identity choices: correct option (index 1) must be visible now
	var found_correct_id_now := false
	for choice in curr_node.choices:
		if choice.get("index") == 1:
			found_correct_id_now = true
	if not found_correct_id_now:
		printerr("FAIL 8-D: Correct identity choice should be visible with all clues!")
		get_tree().quit(1)
		return

	diag_runner.choose(1) # Go to diagnose_identity_correct
	curr_node = diag_runner.current()
	if diag_runner._current_node_id != "diagnose_identity_correct":
		printerr("FAIL 8-D: Should enter diagnose_identity_correct! Got: ", diag_runner._current_node_id)
		get_tree().quit(1)
		return

	# Identity correct choices: correct option (index 2) must be visible
	var found_correct_reason := false
	for choice in curr_node.choices:
		if choice.get("index") == 2:
			found_correct_reason = true
	if not found_correct_reason:
		printerr("FAIL 8-D: Correct reason choice should be visible with clues!")
		get_tree().quit(1)
		return

	diag_runner.choose(2) # Go to diagnose_reason_correct
	curr_node = diag_runner.current()
	if diag_runner._current_node_id != "diagnose_reason_correct":
		printerr("FAIL 8-D: Should enter diagnose_reason_correct! Got: ", diag_runner._current_node_id)
		get_tree().quit(1)
		return

	# Reason correct choices: correct option (index 1) must be visible
	var found_correct_truth := false
	for choice in curr_node.choices:
		if choice.get("index") == 1:
			found_correct_truth = true
	if not found_correct_truth:
		printerr("FAIL 8-D: Correct truth choice should be visible with clues!")
		get_tree().quit(1)
		return

	diag_runner.choose(1) # Go to diagnose_truth_leaf
	curr_node = diag_runner.current()
	if diag_runner._current_node_id != "diagnose_truth_leaf":
		printerr("FAIL 8-D: Should enter diagnose_truth_leaf! Got: ", diag_runner._current_node_id)
		get_tree().quit(1)
		return

	# Check quest flags after truth leaf
	if not QuestManager.get_flag("repair_vendor_bot", "mainframe_revealed", false):
		printerr("FAIL 8-D: mainframe_revealed quest flag not set on truth leaf!")
		get_tree().quit(1)
		return
	if not QuestManager.get_flag("repair_vendor_bot", "diagnosed", false):
		printerr("FAIL 8-D: diagnosed quest flag not set on truth leaf!")
		get_tree().quit(1)
		return
	if not QuestManager.get_flag("repair_vendor_bot", "understood_robot_truth", false):
		printerr("FAIL 8-D: understood_robot_truth quest flag not set on truth leaf!")
		get_tree().quit(1)
		return

	# Test host gating after mainframe_revealed is true
	store_instance.nearby_interactables.clear()
	store_instance.nearby_interactables.append(host_area)
	var closest_after_reveal = store_instance._get_closest_interactable()
	if closest_after_reveal != host_area:
		printerr("FAIL 8-D: host_area should be accessible after mainframe_revealed is true!")
		get_tree().quit(1)
		return
	print("PASS 8-D: Dialogue truth path and flags (mainframe_revealed, diagnosed, understood_robot_truth) verified.")

	# ---- Test 6: Dialogue tree partial path flow (incorrect choices selected) ----
	# Reset quest flags
	QuestManager.set_flag("repair_vendor_bot", "mainframe_revealed", false)
	QuestManager.set_flag("repair_vendor_bot", "diagnosed", false)
	QuestManager.set_flag("repair_vendor_bot", "understood_robot_truth", false)

	diag_runner.start(robot_tree, "diagnose_intro")
	diag_runner.choose(1) # We choose index 1: (不工作) -> diagnose_partial_intro
	curr_node = diag_runner.current()
	if diag_runner._current_node_id != "diagnose_partial_intro":
		printerr("FAIL 8-D: Should enter diagnose_partial_intro! Got: ", diag_runner._current_node_id)
		get_tree().quit(1)
		return

	# Check quest flags after partial leaf
	if not QuestManager.get_flag("repair_vendor_bot", "mainframe_revealed", false):
		printerr("FAIL 8-D: mainframe_revealed quest flag not set on partial leaf!")
		get_tree().quit(1)
		return
	if not QuestManager.get_flag("repair_vendor_bot", "diagnosed", false):
		printerr("FAIL 8-D: diagnosed quest flag not set on partial leaf!")
		get_tree().quit(1)
		return
	if QuestManager.get_flag("repair_vendor_bot", "understood_robot_truth", false):
		printerr("FAIL 8-D: understood_robot_truth should NOT be set on partial leaf!")
		get_tree().quit(1)
		return
	print("PASS 8-D: Dialogue partial path and flags verified.")

	# Cleanup 8-D
	store_instance.interaction_requested.disconnect(_temp_callable)
	store_instance.queue_free()
	store_scene = null
	diag_runner = null
	_temp_callable = Callable()
	if GameState.quest_states.has("repair_vendor_bot"):
		GameState.quest_states.erase("repair_vendor_bot")
	GameState.notes.clear()
	await get_tree().process_frame

	print("PASS: Phase 8-D clues & store robot diagnostic tree verified successfully.")
