extends "res://tests/manual/phases/phase_8f.gd"

func _run_phase_8e() -> void:
	# Phase 8-E: 店籍主機三段 + 兩種重置結局
	# ============================================================
	print("Verifying Phase 8-E: store registry host three stages & two endings...")

	# --- Setup / backups ---
	var inv_backup_8e = GameState.inventory.duplicate(true)
	GameState.story_flags.erase("vendor_bot_repaired")
	GameState.story_flags.erase("store_robot_resolution")
	if GameState.quest_states.has("repair_vendor_bot"):
		GameState.quest_states.erase("repair_vendor_bot")
	GameState.notes.clear()

	var find_choice_8e = func(curr: Dictionary, substr: String) -> int:
		for c in curr.get("choices", []):
			if substr in tr(c.get("label", "")):
				return c.get("index")
		return -1

	# ---- Test 1: clerk_echo_recording item metadata (不可賣、不可丟) ----
	var echo_meta_8e: Dictionary = GameState.ITEMS_DB.get("clerk_echo_recording", {})
	if echo_meta_8e.is_empty():
		printerr("FAIL 8-E: clerk_echo_recording missing from ITEMS_DB!")
		get_tree().quit(1)
		return
	if echo_meta_8e.get("discardable", true) != false or echo_meta_8e.get("sellable", true) != false:
		printerr("FAIL 8-E: clerk_echo_recording must be discardable=false and sellable=false! Got: ", echo_meta_8e)
		get_tree().quit(1)
		return
	print("PASS 8-E: clerk_echo_recording registered, not sellable and not discardable.")

	# ---- Test 2: dialogue tree registered + host area dispatches dialogue ----
	var host_tree_8e = DialogueDB.get_tree_for("store_registry_host")
	if host_tree_8e.is_empty():
		printerr("FAIL 8-E: DialogueDB store_registry_host tree not found!")
		get_tree().quit(1)
		return

	var store_scene_8e = load("res://scenes/levels/convenience_store/convenience_store.tscn")
	var store_instance_8e = store_scene_8e.instantiate()
	add_child(store_instance_8e)
	await get_tree().process_frame

	var host_area_8e = store_instance_8e.get_node_or_null("Interactables/StoreRegistryHostArea")
	if host_area_8e == null or host_area_8e.dialogue_id != "store_registry_host":
		printerr("FAIL 8-E: StoreRegistryHostArea must carry dialogue_id='store_registry_host'!")
		get_tree().quit(1)
		return

	var host_emit_data_8e = {}
	_temp_callable = func(data):
		host_emit_data_8e.clear()
		host_emit_data_8e.merge(data)
	store_instance_8e.interaction_requested.connect(_temp_callable)
	store_instance_8e.current_interactable = host_area_8e
	store_instance_8e._trigger_interaction()
	if host_emit_data_8e.get("type") != "dialogue" or host_emit_data_8e.get("dialogue_id") != "store_registry_host":
		printerr("FAIL 8-E: Host interaction should dispatch dialogue 'store_registry_host'! Got: ", host_emit_data_8e)
		get_tree().quit(1)
		return
	print("PASS 8-E: store_registry_host tree registered and host area dispatches dialogue.")

	# ---- Test 3: three-stage routing ----
	QuestManager.start("repair_vendor_bot")
	QuestManager.set_flag("repair_vendor_bot", "mainframe_revealed", true)

	var host_runner_8e = DialogueRunner.new()

	# 段1：revealed 但診斷不足 -> 只說明，無選項、無重置
	host_runner_8e.start(host_tree_8e, "start")
	if host_runner_8e._current_node_id != "stage1":
		printerr("FAIL 8-E: Should route to stage1 before diagnosed! Got: ", host_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	var host_curr_8e = host_runner_8e.current()
	if not host_curr_8e.get("choices", []).is_empty() or not host_curr_8e.get("is_terminal", false):
		printerr("FAIL 8-E: stage1 must be a terminal info message without reset choices!")
		get_tree().quit(1)
		return
	print("PASS 8-E: stage1 (info only, no reset) verified.")

	# 段2：diagnosed（未全對）-> 僅直接重置
	QuestManager.set_flag("repair_vendor_bot", "diagnosed", true)
	host_runner_8e.start(host_tree_8e, "start")
	if host_runner_8e._current_node_id != "stage2":
		printerr("FAIL 8-E: Should route to stage2 when diagnosed! Got: ", host_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	host_curr_8e = host_runner_8e.current()
	if find_choice_8e.call(host_curr_8e, "直接重置") == -1:
		printerr("FAIL 8-E: stage2 must offer 直接重置!")
		get_tree().quit(1)
		return
	if find_choice_8e.call(host_curr_8e, "先錄殘響") != -1:
		printerr("FAIL 8-E: stage2 must NOT offer 先錄殘響!")
		get_tree().quit(1)
		return
	print("PASS 8-E: stage2 (direct reset only) verified.")

	# 段3：understood_robot_truth -> 二選一
	QuestManager.set_flag("repair_vendor_bot", "understood_robot_truth", true)
	host_runner_8e.start(host_tree_8e, "start")
	if host_runner_8e._current_node_id != "stage3":
		printerr("FAIL 8-E: Should route to stage3 when understood_robot_truth! Got: ", host_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	host_curr_8e = host_runner_8e.current()
	if find_choice_8e.call(host_curr_8e, "直接重置") == -1 or find_choice_8e.call(host_curr_8e, "先錄殘響") == -1:
		printerr("FAIL 8-E: stage3 must offer both 直接重置 and 先錄殘響!")
		get_tree().quit(1)
		return
	print("PASS 8-E: stage3 (both endings offered) verified.")

	# ---- Test 4: gleaned ending with bag full -> whole transaction aborts, retryable ----
	for i in range(GameState.inventory_slots):
		GameState.inventory[i] = {
			"instance_id": GameState.generate_instance_id(),
			"item_id": "canned_food",
			"quantity": 5
		}
	host_runner_8e.start(host_tree_8e, "start")
	host_curr_8e = host_runner_8e.current()
	host_runner_8e.choose(find_choice_8e.call(host_curr_8e, "先錄殘響"))
	if host_runner_8e._current_node_id != "glean_bag_full":
		printerr("FAIL 8-E: Bag-full glean should land on glean_bag_full! Got: ", host_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	if GameState.has_flag("vendor_bot_repaired") or GameState.get_flag("store_robot_resolution", "") != "":
		printerr("FAIL 8-E: Bag-full glean must not set vendor_bot_repaired / store_robot_resolution!")
		get_tree().quit(1)
		return
	if GameState.has_item("clerk_echo_recording") or GameState.has_note("note_clerk_echo_recording"):
		printerr("FAIL 8-E: Bag-full glean must not grant echo item or note!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("repair_vendor_bot") != "active":
		printerr("FAIL 8-E: Bag-full glean must not complete the quest!")
		get_tree().quit(1)
		return
	print("PASS 8-E: Bag-full glean aborts whole transaction without side effects.")

	# ---- Test 5: gleaned ending succeeds after freeing a slot ----
	GameState.inventory[0] = {}
	host_runner_8e.start(host_tree_8e, "start")
	if host_runner_8e._current_node_id != "stage3":
		printerr("FAIL 8-E: After aborted glean, host should still offer stage3! Got: ", host_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	host_curr_8e = host_runner_8e.current()
	host_runner_8e.choose(find_choice_8e.call(host_curr_8e, "先錄殘響"))
	if host_runner_8e._current_node_id != "gleaned_done":
		printerr("FAIL 8-E: Successful glean should land on gleaned_done! Got: ", host_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	if not GameState.has_item("clerk_echo_recording"):
		printerr("FAIL 8-E: Glean ending must grant clerk_echo_recording!")
		get_tree().quit(1)
		return
	if not GameState.has_note("note_clerk_echo_recording"):
		printerr("FAIL 8-E: Glean ending must grant the echo note!")
		get_tree().quit(1)
		return
	if GameState.get_flag("store_robot_resolution", "") != "gleaned" or not GameState.has_flag("vendor_bot_repaired"):
		printerr("FAIL 8-E: Glean ending must set store_robot_resolution='gleaned' + vendor_bot_repaired!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("repair_vendor_bot") != "completed":
		printerr("FAIL 8-E: Glean ending must complete repair_vendor_bot!")
		get_tree().quit(1)
		return
	if not ("販賣機" in tr(host_runner_8e.current().get("text", ""))):
		printerr("FAIL 8-E: gleaned_done message must hint the outside vending machine is back online!")
		get_tree().quit(1)
		return
	var work_note_gleaned_8e = {}
	for n in GameState.get_notes("工作"):
		if n.get("id") == "quest_repair_vendor_bot":
			work_note_gleaned_8e = n
	if work_note_gleaned_8e.get("status", "") != "completed" or not ("殘響" in _tr_body(work_note_gleaned_8e.get("body", ""))):
		printerr("FAIL 8-E: Completed work note should be the gleaned variant! Got: ", work_note_gleaned_8e)
		get_tree().quit(1)
		return
	print("PASS 8-E: Gleaned ending (item + note + flags + quest complete + hint + work note) verified.")

	# ---- Test 6: host no longer offers reset; robot greets with gleaned voice ----
	host_runner_8e.start(host_tree_8e, "start")
	if host_runner_8e._current_node_id != "already_repaired" or not host_runner_8e.current().get("is_terminal", false):
		printerr("FAIL 8-E: After repair, host must only give neutral repaired message! Got: ", host_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	var robot_tree_8e = DialogueDB.get_tree_for("store_robot")
	var robot_runner_8e = DialogueRunner.new()
	robot_runner_8e.start(robot_tree_8e, "start")
	if robot_runner_8e._current_node_id != "repaired_gleaned":
		printerr("FAIL 8-E: Robot should greet with repaired_gleaned after gleaned ending! Got: ", robot_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	print("PASS 8-E: Post-repair host neutral message and gleaned robot greeting verified.")

	# ---- Test 7: direct reset ending via stage2 ----
	GameState.story_flags.erase("vendor_bot_repaired")
	GameState.story_flags.erase("store_robot_resolution")
	GameState.quest_states.erase("repair_vendor_bot")
	GameState.notes.clear()
	GameState.remove_item("clerk_echo_recording", 1)
	QuestManager.start("repair_vendor_bot")
	QuestManager.set_flag("repair_vendor_bot", "mainframe_revealed", true)
	QuestManager.set_flag("repair_vendor_bot", "diagnosed", true)

	host_runner_8e.start(host_tree_8e, "start")
	if host_runner_8e._current_node_id != "stage2":
		printerr("FAIL 8-E: Reset path should start from stage2! Got: ", host_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	host_curr_8e = host_runner_8e.current()
	host_runner_8e.choose(find_choice_8e.call(host_curr_8e, "直接重置"))
	if host_runner_8e._current_node_id != "reset_done":
		printerr("FAIL 8-E: Direct reset should land on reset_done! Got: ", host_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	if GameState.get_flag("store_robot_resolution", "") != "reset" or not GameState.has_flag("vendor_bot_repaired"):
		printerr("FAIL 8-E: Direct reset must set store_robot_resolution='reset' + vendor_bot_repaired!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("repair_vendor_bot") != "completed":
		printerr("FAIL 8-E: Direct reset must complete repair_vendor_bot!")
		get_tree().quit(1)
		return
	if not ("販賣機" in tr(host_runner_8e.current().get("text", ""))):
		printerr("FAIL 8-E: reset_done message must hint the outside vending machine is back online!")
		get_tree().quit(1)
		return
	var work_note_reset_8e = {}
	for n in GameState.get_notes("工作"):
		if n.get("id") == "quest_repair_vendor_bot":
			work_note_reset_8e = n
	if work_note_reset_8e.get("status", "") != "completed" or not ("直接重置" in _tr_body(work_note_reset_8e.get("body", ""))):
		printerr("FAIL 8-E: Completed work note should be the reset variant! Got: ", work_note_reset_8e)
		get_tree().quit(1)
		return
	host_runner_8e.start(host_tree_8e, "start")
	if host_runner_8e._current_node_id != "already_repaired":
		printerr("FAIL 8-E: After direct reset, host must not offer reset again!")
		get_tree().quit(1)
		return
	robot_runner_8e.start(robot_tree_8e, "start")
	if robot_runner_8e._current_node_id != "repaired_reset":
		printerr("FAIL 8-E: Robot should greet with repaired_reset after direct reset! Got: ", robot_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	print("PASS 8-E: Direct reset ending (flags + quest complete + hint + work note + greetings) verified.")

	# ---- Test 8: direct reset is also available from stage3 ----
	GameState.story_flags.erase("vendor_bot_repaired")
	GameState.story_flags.erase("store_robot_resolution")
	GameState.quest_states.erase("repair_vendor_bot")
	GameState.notes.clear()
	QuestManager.start("repair_vendor_bot")
	QuestManager.set_flag("repair_vendor_bot", "mainframe_revealed", true)
	QuestManager.set_flag("repair_vendor_bot", "diagnosed", true)
	QuestManager.set_flag("repair_vendor_bot", "understood_robot_truth", true)

	host_runner_8e.start(host_tree_8e, "start")
	host_curr_8e = host_runner_8e.current()
	host_runner_8e.choose(find_choice_8e.call(host_curr_8e, "直接重置"))
	if host_runner_8e._current_node_id != "reset_done":
		printerr("FAIL 8-E: stage3 direct reset should land on reset_done! Got: ", host_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	if GameState.get_flag("store_robot_resolution", "") != "reset" or QuestManager.get_status("repair_vendor_bot") != "completed":
		printerr("FAIL 8-E: stage3 direct reset must set resolution='reset' and complete the quest!")
		get_tree().quit(1)
		return
	print("PASS 8-E: stage3 direct reset variant verified.")

	# Cleanup 8-E
	store_instance_8e.interaction_requested.disconnect(_temp_callable)
	_temp_callable = Callable()
	store_instance_8e.queue_free()
	store_scene_8e = null
	host_runner_8e = null
	robot_runner_8e = null
	GameState.story_flags.erase("vendor_bot_repaired")
	GameState.story_flags.erase("store_robot_resolution")
	if GameState.quest_states.has("repair_vendor_bot"):
		GameState.quest_states.erase("repair_vendor_bot")
	GameState.notes.clear()
	GameState.inventory = inv_backup_8e
	GameState.inventory_changed.emit()
	find_choice_8e = Callable()
	await get_tree().process_frame

	print("PASS: Phase 8-E store registry host & two endings verified successfully.")
