extends "res://tests/manual/phases/phase_26e.gd"

func _run_phase_26d() -> void:
	# ===================== Phase 26-D: 結局觸發點武裝 + Branch B 檔案重標記 =====================
	print("--- Phase 26-D: 結局觸發點武裝 + Branch B 檔案重標記 ---")

	GameState.reset_for_new_game()
	var core_inst_phase26d = load("res://scenes/levels/datacenter_backup_core/datacenter_backup_core.tscn").instantiate()
	add_child(core_inst_phase26d)

	var own_backup_phase26d = core_inst_phase26d.get_node_or_null("Interactables/OwnBackupArea")
	var file_index_phase26d = core_inst_phase26d.get_node_or_null("Interactables/FileIndexTerminalArea")
	if own_backup_phase26d == null or file_index_phase26d == null:
		printerr("FAIL 26-D: datacenter_backup_core missing OwnBackupArea / FileIndexTerminalArea nodes!")
		get_tree().quit(1)
		return

	if file_index_phase26d.interaction_id != "file_index_terminal" or file_index_phase26d.prompt_text != "PROMPT_DATACENTER_CORE_FILE_INDEX":
		printerr("FAIL 26-D: FileIndexTerminalArea properties mismatch!")
		get_tree().quit(1)
		return

	var captured_26d: Dictionary = {}
	core_inst_phase26d.interaction_requested.connect(func(data):
		captured_26d.merge(data, true)
	)

	# 1. 碎片前：own_backup 維持中性佔位，不 set stood_before_own_backup
	core_inst_phase26d.current_interactable = own_backup_phase26d
	core_inst_phase26d._trigger_interaction()
	if captured_26d.get("message_text", "") != "MSG_DATACENTER_OWN_BACKUP_PLACEHOLDER":
		printerr("FAIL 26-D: expected placeholder before fragment collected, got: ", captured_26d)
		get_tree().quit(1)
		return
	if GameState.get_flag("stood_before_own_backup", false):
		printerr("FAIL 26-D: stood_before_own_backup must not be set before mem_frag_chose_deletion!")
		get_tree().quit(1)
		return

	# 2. 碎片後：own_backup 換重量級文字 + set stood_before_own_backup
	# （原 26-D「TRUTH 冪等可重看」語意已被 27-B 四層分派取代：武裝後重看改開三選對話）
	GameState.set_flag("mem_frag_chose_deletion", true)
	captured_26d.clear()
	core_inst_phase26d._trigger_interaction()
	if captured_26d.get("message_text", "") != "MSG_DATACENTER_OWN_BACKUP_TRUTH":
		printerr("FAIL 26-D: expected TRUTH text after fragment collected, got: ", captured_26d)
		get_tree().quit(1)
		return
	if not GameState.get_flag("stood_before_own_backup", false):
		printerr("FAIL 26-D: stood_before_own_backup should be set once TRUTH text is reached!")
		get_tree().quit(1)
		return

	captured_26d.clear()
	core_inst_phase26d._trigger_interaction()
	if captured_26d.get("type", "") != "dialogue" or captured_26d.get("dialogue_id", "") != "own_backup" or not GameState.get_flag("stood_before_own_backup", false):
		printerr("FAIL 26-D: re-examining own_backup after armament should open dialogue 'own_backup' (27-B layer), got: ", captured_26d)
		get_tree().quit(1)
		return

	# 3. 檔案索引終端：seven_stopped_partial=false → 中性 flavor；不 set 任何旗標
	core_inst_phase26d.current_interactable = file_index_phase26d
	captured_26d.clear()
	core_inst_phase26d._trigger_interaction()
	if captured_26d.get("message_text", "") != "MSG_DATACENTER_FILE_INDEX_NEUTRAL":
		printerr("FAIL 26-D: expected neutral file index flavor when seven_stopped_partial is false, got: ", captured_26d)
		get_tree().quit(1)
		return

	# 4. 檔案索引終端：seven_stopped_partial=true → Branch B 重標記變體；可重看
	GameState.set_flag("seven_stopped_partial", true)
	captured_26d.clear()
	core_inst_phase26d._trigger_interaction()
	if captured_26d.get("message_text", "") != "MSG_DATACENTER_FILE_INDEX_REMARKED":
		printerr("FAIL 26-D: expected remarked file index variant when seven_stopped_partial is true, got: ", captured_26d)
		get_tree().quit(1)
		return

	captured_26d.clear()
	core_inst_phase26d._trigger_interaction()
	if captured_26d.get("message_text", "") != "MSG_DATACENTER_FILE_INDEX_REMARKED":
		printerr("FAIL 26-D: file index terminal should stay re-viewable with the same remarked variant!")
		get_tree().quit(1)
		return

	# 5. Branch B 變體不寫進「自己的備份」examine（兩互動物分屬不同情緒重點）
	# （武裝後 own_backup 走 27-B 對話分派：斷言仍開 own_backup 對話、不受 seven_stopped_partial 影響）
	core_inst_phase26d.current_interactable = own_backup_phase26d
	captured_26d.clear()
	core_inst_phase26d._trigger_interaction()
	if captured_26d.get("type", "") != "dialogue" or captured_26d.get("dialogue_id", "") != "own_backup":
		printerr("FAIL 26-D: seven_stopped_partial must not leak Branch B variant into own_backup examine!")
		get_tree().quit(1)
		return

	core_inst_phase26d.free()
	await get_tree().process_frame

	GameState.reset_for_new_game()
	print("PASS: Phase 26-D ending trigger armament + Branch B file re-marking (own_backup TRUTH dispatch + stood_before_own_backup + file index terminal two variants) verified.")

