extends "res://tests/manual/phases/phase_17b.gd"

func _run_phase_17a() -> void:
	# ===================== Phase 17-A: memory_fragment_area in subway_station_platform =====================
	print("--- Phase 17-A: memory_fragment_area in subway_station_platform ---")
	var platform_scene_17 = load("res://scenes/levels/subway_station/subway_station_platform.tscn")
	var platform_inst_17 = platform_scene_17.instantiate()
	var mem_area_17 = platform_inst_17.find_child("MemoryFragmentArea", true, false)
	if mem_area_17 == null:
		printerr("FAIL 17-A: MemoryFragmentArea node not found in subway_station_platform.tscn!")
		get_tree().quit(1)
		return

	if mem_area_17.fragment_flag != "mem_frag_commute_topside" or mem_area_17.message_id != "mem_frag_commute_topside":
		printerr("FAIL 17-A: MemoryFragmentArea properties mismatch! Got: flag=", mem_area_17.fragment_flag, " msg=", mem_area_17.message_id)
		get_tree().quit(1)
		return

	# Assert narrative text constraints
	var msg_text_17 = GameState.STORY_MESSAGES.get("mem_frag_commute_topside", "")
	if msg_text_17 == "":
		printerr("FAIL 17-A: STORY_MESSAGES missing 'mem_frag_commute_topside'!")
		get_tree().quit(1)
		return
	if "林霏" in msg_text_17:
		printerr("FAIL 17-A: STORY_MESSAGES for 'mem_frag_commute_topside' contains forbidden word '林霏'!")
		get_tree().quit(1)
		return

	# Set up environment
	GameState.reset_for_new_game()
	UIMode.set_mode(UIMode.Mode.NONE)

	var p17_player = platform_inst_17.find_child("Player", true, false)
	if p17_player == null:
		printerr("FAIL 17-A: Player node not found in platform scene for Phase 17-A!")
		get_tree().quit(1)
		return

	# We listen to interaction_requested on the platform root to verify emission
	var p17_received = {"message_text": ""}
	var p17_on_interaction = func(data: Dictionary):
		if data.get("type") == "message":
			p17_received["message_text"] = data.get("message_text")
	platform_inst_17.interaction_requested.connect(p17_on_interaction)

	# Trigger body_entered
	mem_area_17._on_body_entered(p17_player)

	if not GameState.get_flag("mem_frag_commute_topside", false):
		printerr("FAIL 17-A: mem_frag_commute_topside flag not set after collision!")
		get_tree().quit(1)
		return

	if p17_received["message_text"] != GameState.STORY_MESSAGES["mem_frag_commute_topside"]:
		printerr("FAIL 17-A: Message not received or text mismatch! Got: ", p17_received["message_text"])
		get_tree().quit(1)
		return

	# Reset received message and try to trigger again (should be blocked by flag)
	p17_received["message_text"] = ""
	mem_area_17._on_body_entered(p17_player)
	if p17_received["message_text"] != "":
		printerr("FAIL 17-A: MemoryFragmentArea triggered repeatedly!")
		get_tree().quit(1)
		return

	# Save/Load (round-trip) verification
	# Set flag true, save to scratch slot, reset, load, assert flag is true
	GameState.reset_for_new_game()
	GameState.set_flag("mem_frag_commute_topside", true)
	var save_p17 = SaveSystem.capture("subway_station_platform", 100.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_p17):
		printerr("FAIL 17-A: Failed to write Phase 17 save to scratch slot!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	if GameState.get_flag("mem_frag_commute_topside", false) != false:
		printerr("FAIL 17-A: Flag 'mem_frag_commute_topside' did not reset to false!")
		get_tree().quit(1)
		return

	var load_p17 = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	if load_p17.is_empty():
		printerr("FAIL 17-A: Failed to read Phase 17 save from scratch slot!")
		get_tree().quit(1)
		return
	SaveSystem.apply(load_p17)

	if not GameState.get_flag("mem_frag_commute_topside", false):
		printerr("FAIL 17-A: Flag 'mem_frag_commute_topside' not restored from save!")
		get_tree().quit(1)
		return

	# Test default fallback value (missing keys)
	GameState.reset_for_new_game()
	if GameState.get_flag("mem_frag_commute_topside", false) != false:
		printerr("FAIL 17-A: mem_frag_commute_topside default value should be false!")
		get_tree().quit(1)
		return

	# Clean up
	platform_inst_17.interaction_requested.disconnect(p17_on_interaction)
	platform_inst_17.free()
	platform_scene_17 = null
	p17_player = null

	print("PASS: Phase 17-A memory_fragment_area in platform verified.")

