extends "res://tests/manual/phases/phase_8d.gd"

func _run_phase_8c() -> void:
	# Phase 8-C: 公寓電腦兩段 gate + QuestManager.start("repair_vendor_bot")
	# ==============================================================
	print("Verifying Phase 8-C: desk computer two-stage gate + quest dispatch...")

	# 重設狀態（確保乾淨的測試環境）
	GameState.reset_for_new_game()
	GameState.quest_states.clear()

	# QuestDB 內應含 repair_vendor_bot
	var QuestDB_8c = load("res://data/quests/quest_db.gd")
	if not QuestDB_8c:
		printerr("FAIL 8-C: Could not load quest_db.gd!")
		get_tree().quit(1)
		return
	var repair_quest_data = QuestDB_8c.get_quest_data("repair_vendor_bot")
	if repair_quest_data == null:
		printerr("FAIL 8-C: 'repair_vendor_bot' not found in quest_db!")
		get_tree().quit(1)
		return
	print("PASS 8-C: repair_vendor_bot registered in QuestDB.")

	# repair_vendor_bot 的 QUEST_ID、WORK_NOTE_ID 常數正確
	if repair_quest_data.QUEST_ID != "repair_vendor_bot":
		printerr("FAIL 8-C: repair_vendor_bot QUEST_ID mismatch! Got: ", repair_quest_data.QUEST_ID)
		get_tree().quit(1)
		return
	if repair_quest_data.WORK_NOTE_ID != "quest_repair_vendor_bot":
		printerr("FAIL 8-C: repair_vendor_bot WORK_NOTE_ID mismatch! Got: ", repair_quest_data.WORK_NOTE_ID)
		get_tree().quit(1)
		return
	print("PASS 8-C: QUEST_ID and WORK_NOTE_ID constants correct.")

	# STEPS 應只有 "started"
	if not repair_quest_data.STEPS.has("started") or repair_quest_data.STEPS.size() != 1:
		printerr("FAIL 8-C: repair_vendor_bot STEPS should only contain 'started'! Got: ", repair_quest_data.STEPS)
		get_tree().quit(1)
		return
	print("PASS 8-C: repair_vendor_bot STEPS contains only 'started'.")

	# HAS_COMPLETED_NOTE_RESOLVER 常數必須存在且為 true
	if not "HAS_COMPLETED_NOTE_RESOLVER" in repair_quest_data:
		printerr("FAIL 8-C: repair_vendor_bot missing HAS_COMPLETED_NOTE_RESOLVER constant!")
		get_tree().quit(1)
		return
	if not repair_quest_data.HAS_COMPLETED_NOTE_RESOLVER:
		printerr("FAIL 8-C: HAS_COMPLETED_NOTE_RESOLVER should be true!")
		get_tree().quit(1)
		return
	print("PASS 8-C: HAS_COMPLETED_NOTE_RESOLVER constant present and true.")

	# STORY_MESSAGES 應含 desk_computer_dispatch_quest
	if not GameState.STORY_MESSAGES.has("desk_computer_dispatch_quest"):
		printerr("FAIL 8-C: STORY_MESSAGES missing 'desk_computer_dispatch_quest'!")
		get_tree().quit(1)
		return
	print("PASS 8-C: desk_computer_dispatch_quest message exists in STORY_MESSAGES.")

	# ---- 模擬電腦互動真值表 ----
	# 準備公寓房間 instance（用來呼叫 _trigger_interaction）
	var room_scene_8c = load("res://scenes/levels/apartment/apartment_room.tscn")
	var room_instance_8c = room_scene_8c.instantiate()
	var ui_scene_8c = load("res://scenes/ui/game_ui.tscn")
	var ui_instance_8c = ui_scene_8c.instantiate()
	add_child(ui_instance_8c)
	add_child(room_instance_8c)
	await get_tree().process_frame

	# 確認 DeskComputerArea 有 interaction_id == "desk_computer"
	var desk_area = room_instance_8c.get_node_or_null("Interactables/DeskComputerArea")
	if not desk_area:
		printerr("FAIL 8-C: DeskComputerArea not found in apartment_room!")
		get_tree().quit(1)
		return
	if desk_area.get("interaction_id") != "desk_computer":
		printerr("FAIL 8-C: DeskComputerArea interaction_id is not 'desk_computer'! Got: ", desk_area.get("interaction_id"))
		get_tree().quit(1)
		return
	print("PASS 8-C: DeskComputerArea has interaction_id='desk_computer'.")

	# 測試狀態記錄
	var computer_dispatch_data_8c := {}
	_temp_callable = func(data):
		computer_dispatch_data_8c.clear()
		computer_dispatch_data_8c.merge(data)
	room_instance_8c.interaction_requested.connect(_temp_callable)

	# --- 測試 1：第一次互動（used_room_computer_once 未設） ---
	GameState.story_flags.erase("used_room_computer_once")
	GameState.story_flags.erase("discovered_vendor_error")
	room_instance_8c.current_interactable = desk_area
	room_instance_8c._trigger_interaction()

	if not GameState.get_flag("used_room_computer_once", false):
		printerr("FAIL 8-C: After first interaction, used_room_computer_once should be true!")
		get_tree().quit(1)
		return
	if computer_dispatch_data_8c.get("message_text", "") != GameState.STORY_MESSAGES["desk_computer_msg"]:
		printerr("FAIL 8-C: First interaction should show desk_computer_msg! Got: ", computer_dispatch_data_8c.get("message_text", ""))
		get_tree().quit(1)
		return
	if QuestManager.get_status("repair_vendor_bot") == "active":
		printerr("FAIL 8-C: Quest should NOT be started on first interaction!")
		get_tree().quit(1)
		return
	print("PASS 8-C: First computer interaction shows old content and sets used_room_computer_once.")

	# --- 測試 2：第二次互動 + discovered_vendor_error 但任務未接 → 派工 ---
	GameState.set_flag("discovered_vendor_error", true)
	# 確保任務尚未啟動
	if GameState.quest_states.has("repair_vendor_bot"):
		GameState.quest_states.erase("repair_vendor_bot")
	computer_dispatch_data_8c.clear()
	room_instance_8c.current_interactable = desk_area
	room_instance_8c._trigger_interaction()

	if QuestManager.get_status("repair_vendor_bot") != "active":
		printerr("FAIL 8-C: Quest 'repair_vendor_bot' should be active after quest dispatch! Got status: ", QuestManager.get_status("repair_vendor_bot"))
		get_tree().quit(1)
		return
	if computer_dispatch_data_8c.get("message_text", "") != GameState.STORY_MESSAGES["desk_computer_dispatch_quest"]:
		printerr("FAIL 8-C: Quest dispatch should show desk_computer_dispatch_quest message!")
		get_tree().quit(1)
		return
	print("PASS 8-C: Second interaction with discovered_vendor_error dispatches quest and shows dispatch message.")

	# 工作筆記應出現在「工作」分類
	var work_notes_8c = GameState.get_notes("工作")
	var found_quest_note_8c := false
	for note in work_notes_8c:
		if note.get("id") == "quest_repair_vendor_bot":
			found_quest_note_8c = true
			break
	if not found_quest_note_8c:
		printerr("FAIL 8-C: Work note 'quest_repair_vendor_bot' not found in 工作 category after quest dispatch!")
		get_tree().quit(1)
		return
	print("PASS 8-C: Work note 'quest_repair_vendor_bot' appears in 工作 notes after quest dispatch.")

	# --- 測試 3：任務已 active 時再互動電腦不重開任務 ---
	var before_step = QuestManager.get_step("repair_vendor_bot")
	computer_dispatch_data_8c.clear()
	room_instance_8c.current_interactable = desk_area
	room_instance_8c._trigger_interaction()

	if QuestManager.get_step("repair_vendor_bot") != before_step:
		printerr("FAIL 8-C: Quest step should not change when interacting with computer while quest is already active!")
		get_tree().quit(1)
		return
	if computer_dispatch_data_8c.get("message_text", "") != GameState.STORY_MESSAGES["desk_computer_msg"]:
		printerr("FAIL 8-C: Repeated interaction when quest is active should show desk_computer_msg fallback!")
		get_tree().quit(1)
		return
	print("PASS 8-C: Repeated computer interaction while quest is active doesn't restart quest.")

	# --- 測試 4：未發現異常（第二次起 + NOT discovered_vendor_error）不派工 ---
	GameState.story_flags.erase("discovered_vendor_error")
	if GameState.quest_states.has("repair_vendor_bot"):
		GameState.quest_states.erase("repair_vendor_bot")
	computer_dispatch_data_8c.clear()
	room_instance_8c.current_interactable = desk_area
	room_instance_8c._trigger_interaction()

	if QuestManager.get_status("repair_vendor_bot") == "active":
		printerr("FAIL 8-C: Quest should NOT be dispatched without discovered_vendor_error!")
		get_tree().quit(1)
		return
	if computer_dispatch_data_8c.get("message_text", "") != GameState.STORY_MESSAGES["desk_computer_msg"]:
		printerr("FAIL 8-C: Without discovered_vendor_error, computer should show old content!")
		get_tree().quit(1)
		return
	print("PASS 8-C: Computer without discovered_vendor_error shows old content (no quest dispatch).")

	# --- 測試 5：resolve_completed_note() 依 store_robot_resolution 分流 ---
	GameState.story_flags.erase("store_robot_resolution")
	var note_reset = repair_quest_data.resolve_completed_note()
	if note_reset.get("id") != "quest_repair_vendor_bot" or note_reset.get("status") != "completed":
		printerr("FAIL 8-C: resolve_completed_note() default (no resolution) should return 'reset' completed note!")
		get_tree().quit(1)
		return
	if not tr(note_reset.get("body", "")).contains("直接重置"):
		printerr("FAIL 8-C: Default resolved note body should mention '直接重置'! Got: ", tr(note_reset.get("body", "")))
		get_tree().quit(1)
		return
	print("PASS 8-C: resolve_completed_note() returns reset variant by default.")

	GameState.set_flag("store_robot_resolution", "gleaned")
	var note_gleaned = repair_quest_data.resolve_completed_note()
	if not tr(note_gleaned.get("body", "")).contains("殘響"):
		printerr("FAIL 8-C: Gleaned resolved note body should mention '殘響'! Got: ", tr(note_gleaned.get("body", "")))
		get_tree().quit(1)
		return
	print("PASS 8-C: resolve_completed_note() returns gleaned variant when store_robot_resolution='gleaned'.")

	# Cleanup 8-C
	room_instance_8c.interaction_requested.disconnect(_temp_callable)
	room_instance_8c.free()
	ui_instance_8c.free()
	room_scene_8c = null
	ui_scene_8c = null
	_temp_callable = Callable()
	GameState.story_flags.erase("store_robot_resolution")
	if GameState.quest_states.has("repair_vendor_bot"):
		GameState.quest_states.erase("repair_vendor_bot")
	await get_tree().process_frame

	print("PASS: Phase 8-C desk computer gate & quest dispatch verified successfully.")
