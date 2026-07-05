extends "res://tests/manual/phases/phase_26d.gd"

func _run_phase_26c() -> void:
	# ===================== Phase 26-C: 核心真相碎片 =====================
	print("--- Phase 26-C: 核心真相碎片 ---")

	GameState.reset_for_new_game()
	var core_inst_phase26c = load("res://scenes/levels/datacenter_backup_core/datacenter_backup_core.tscn").instantiate()
	add_child(core_inst_phase26c)

	var frag_node_phase26c = core_inst_phase26c.get_node_or_null("Interactables/MemoryFragmentArea")
	if frag_node_phase26c == null:
		printerr("FAIL 26-C: datacenter_backup_core missing MemoryFragmentArea node!")
		get_tree().quit(1)
		return

	if frag_node_phase26c.fragment_flag != "mem_frag_chose_deletion" or \
	   frag_node_phase26c.message_id != "mem_frag_chose_deletion":
		printerr("FAIL 26-C: MemoryFragmentArea properties mismatch!")
		get_tree().quit(1)
		return

	var captured_frag_phase26c: Dictionary = {}
	core_inst_phase26c.interaction_requested.connect(func(data):
		captured_frag_phase26c.merge(data, true)
	)

	var fake_player_phase26c := Node2D.new()
	fake_player_phase26c.name = "Player"

	# 1. 必經路徑自動收取
	frag_node_phase26c._on_body_entered(fake_player_phase26c)
	if captured_frag_phase26c.get("type", "") != "message" or captured_frag_phase26c.get("message_text", "") != "MSG_MEM_FRAG_CHOSE_DELETION":
		printerr("FAIL 26-C: expected MSG_MEM_FRAG_CHOSE_DELETION on collect, got: ", captured_frag_phase26c)
		get_tree().quit(1)
		return

	if not GameState.get_flag("mem_frag_chose_deletion", false):
		printerr("FAIL 26-C: mem_frag_chose_deletion flag not set after collect!")
		get_tree().quit(1)
		return

	# 2. 重入不重複
	captured_frag_phase26c.clear()
	frag_node_phase26c._on_body_entered(fake_player_phase26c)
	if not captured_frag_phase26c.is_empty():
		printerr("FAIL 26-C: MemoryFragmentArea must not re-fire once mem_frag_chose_deletion is true!")
		get_tree().quit(1)
		return

	fake_player_phase26c.free()
	core_inst_phase26c.free()
	await get_tree().process_frame

	GameState.reset_for_new_game()
	print("PASS: Phase 26-C core truth fragment (必經自動收取 + one-shot guard) verified.")

