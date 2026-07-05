extends "res://tests/manual/phases/phase_14b.gd"

func _run_phase_14a() -> void:
	# ===================== Phase 14-A: memory_fragment_area =====================
	print("--- Phase 14-A: memory_fragment_area ---")
	var street_scene_14 = load("res://scenes/levels/apartment_entrance.tscn")
	var street_inst_14 = street_scene_14.instantiate()
	var mem_area = street_inst_14.find_child("MemoryFragmentArea", true, false)
	if mem_area == null:
		printerr("FAIL: MemoryFragmentArea node not found in apartment_entrance.tscn!")
		get_tree().quit(1)
		return

	if mem_area.fragment_flag != "mem_frag_linfei_1" or mem_area.message_id != "mem_frag_linfei_1":
		printerr("FAIL: MemoryFragmentArea properties mismatch!")
		get_tree().quit(1)
		return

	# Set up environment
	GameState.reset_for_new_game()
	UIMode.set_mode(UIMode.Mode.NONE)

	var p14_player = street_inst_14.find_child("Player", true, false)
	if p14_player == null:
		printerr("FAIL: Player node not found in street scene for Phase 14-A!")
		get_tree().quit(1)
		return

	# We listen to interaction_requested on the street root to verify emission
	var p14_received = {"message_text": ""}
	var p14_on_interaction = func(data: Dictionary):
		if data.get("type") == "message":
			p14_received["message_text"] = data.get("message_text")
	street_inst_14.interaction_requested.connect(p14_on_interaction)

	# Trigger body_entered
	mem_area._on_body_entered(p14_player)

	if not GameState.get_flag("mem_frag_linfei_1", false):
		printerr("FAIL: mem_frag_linfei_1 flag not set after collision!")
		get_tree().quit(1)
		return

	if p14_received["message_text"] != GameState.STORY_MESSAGES["mem_frag_linfei_1"]:
		printerr("FAIL: Message not received or text mismatch! Got: ", p14_received["message_text"])
		get_tree().quit(1)
		return

	# Reset received message and try to trigger again (should be blocked by flag)
	p14_received["message_text"] = ""
	mem_area._on_body_entered(p14_player)
	if p14_received["message_text"] != "":
		printerr("FAIL: MemoryFragmentArea triggered repeatedly!")
		get_tree().quit(1)
		return

	# Clean up
	street_inst_14.interaction_requested.disconnect(p14_on_interaction)
	street_inst_14.free()
	street_scene_14 = null
	p14_player = null

	print("PASS: Phase 14-A memory_fragment_area verified.")

