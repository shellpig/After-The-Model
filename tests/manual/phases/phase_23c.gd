extends "res://tests/manual/phases/phase_23d.gd"

func _run_phase_23c() -> void:
	# ===================== Phase 23-C: Act 3 夜總會保全引開與潛行 =====================
	print("--- Phase 23-C: Act 3 夜總會保全引開與潛行 ---")
	GameState.reset_for_new_game()

	# 載入門面廳場景
	var nightclub_scene = load("res://scenes/levels/nightclub/nightclub.tscn")
	if nightclub_scene == null:
		printerr("FAIL 23-C: Could not load nightclub.tscn")
		get_tree().quit(1)
		return

	var nightclub_node = nightclub_scene.instantiate()
	get_tree().root.add_child(nightclub_node)

	# 初始化場景入口
	nightclub_node.set_entry_point("from_entrance")

	# 準備捕捉 interaction_requested 與 scene_transition_requested
	var captured_transition_p23c: Dictionary = {}
	var captured_msg_p23c: Dictionary = {}

	nightclub_node.scene_transition_requested.connect(func(scene_id, entry_point, payload):
		captured_transition_p23c["scene_id"] = scene_id
		captured_transition_p23c["entry_point"] = entry_point
	)
	nightclub_node.interaction_requested.connect(func(data):
		captured_msg_p23c.merge(data, true)
	)

	# 1. 測試：未引開保全時，互動 back_door 應該被阻擋
	var back_door = nightclub_node.get_node_or_null("Interactables/BackDoorArea")
	if back_door == null:
		printerr("FAIL 23-C: BackDoorArea interactable not found!")
		get_tree().quit(1)
		return

	nightclub_node.current_interactable = back_door
	nightclub_node._trigger_interaction()

	if not captured_msg_p23c.has("message_text") or captured_msg_p23c.get("message_text", "") != "MSG_NIGHTCLUB_SECURITY_BLOCKED":
		printerr("FAIL 23-C: back_door should be blocked when bodyguard is on post, got msg: ", captured_msg_p23c)
		get_tree().quit(1)
		return
	if GameState.get_flag("passed_nightclub_security", false):
		printerr("FAIL 23-C: passed_nightclub_security should not be set yet!")
		get_tree().quit(1)
		return

	# 清空捕捉的資訊
	captured_msg_p23c.clear()

	var bar_bot = nightclub_node.get_node_or_null("Interactables/BarBot")
	if bar_bot == null:
		printerr("FAIL 23-C: BarBot interactable not found!")
		get_tree().quit(1)
		return

	var bodyguard_node = nightclub_node.get_node_or_null("Interactables/Bodyguard")
	if bodyguard_node == null:
		printerr("FAIL 23-C: Bodyguard interactable not found!")
		get_tree().quit(1)
		return

	# 1.5 測試：未與保全對話前，互動 bar_bot 只給中性訊息、不觸發引開
	nightclub_node.current_interactable = bar_bot
	nightclub_node._trigger_interaction()
	if captured_msg_p23c.get("message_text", "") != "MSG_NIGHTCLUB_BAR_BOT_PRE_TALK":
		printerr("FAIL 23-C: bar_bot before talking should show pre-talk message, got: ", captured_msg_p23c)
		get_tree().quit(1)
		return
	if nightclub_node._bodyguard_off_post or GameState.has_flag("nightclub_bar_bot_used"):
		printerr("FAIL 23-C: bar_bot before talking must NOT trigger distraction!")
		get_tree().quit(1)
		return
	captured_msg_p23c.clear()

	# 模擬已與保全對話（解鎖 bar_bot 引開）
	GameState.set_flag("talked_nightclub_bodyguard", true)

	# 2. 測試：互動 bar_bot 觸發引開，_bodyguard_off_post 應為 true、used 旗標永久設定、保全與 bar_bot 淡出停用
	# 先確認保全在崗 (visible=true, process_mode=INHERIT)
	if not bodyguard_node.visible or bodyguard_node.process_mode != Node.PROCESS_MODE_INHERIT:
		printerr("FAIL 23-C: Bodyguard should be visible and inheriting process mode initially!")
		get_tree().quit(1)
		return

	captured_msg_p23c.clear()
	nightclub_node.current_interactable = bar_bot
	nightclub_node._trigger_interaction()

	# 引發時應先跳「玩家動手腳→混亂」前置 message box
	if captured_msg_p23c.get("message_text", "") != "MSG_NIGHTCLUB_BAR_BOT_TAMPER":
		printerr("FAIL 23-C: distraction should first show tamper narration, got: ", captured_msg_p23c)
		get_tree().quit(1)
		return

	if not nightclub_node._bodyguard_off_post:
		printerr("FAIL 23-C: _bodyguard_off_post should be true after distracting bar_bot!")
		get_tree().quit(1)
		return

	# 引發後 used 旗標應永久設定（持久、納存讀檔）
	if not GameState.has_flag("nightclub_bar_bot_used"):
		printerr("FAIL 23-C: nightclub_bar_bot_used should be set after distraction!")
		get_tree().quit(1)
		return

	# 觸發後，保全的 process_mode 應該被 disabled 且 visible 應該將要為 false
	if bodyguard_node.process_mode != Node.PROCESS_MODE_DISABLED:
		printerr("FAIL 23-C: Distracted bodyguard should have process mode disabled!")
		get_tree().quit(1)
		return

	# 且 bar_bot 也應該被 disabled 且從互動範圍移除
	if bar_bot.process_mode != Node.PROCESS_MODE_DISABLED:
		printerr("FAIL 23-C: Distracted bar_bot should have process mode disabled!")
		get_tree().quit(1)
		return

	# 3. 測試：引開保全後，此時互動 back_door 應該可以潛行通過 (set passed_nightclub_security=true 且 transition to nightclub_back)
	nightclub_node.current_interactable = back_door
	nightclub_node._trigger_interaction()

	if not GameState.get_flag("passed_nightclub_security", false):
		printerr("FAIL 23-C: passed_nightclub_security should be set to true after sneak in!")
		get_tree().quit(1)
		return
	if captured_transition_p23c.get("scene_id", "") != "nightclub_back":
		printerr("FAIL 23-C: Should transition to nightclub_back, got: ", captured_transition_p23c)
		get_tree().quit(1)
		return

	# 4. 測試：場景 transient 變數且重新加載時保全歸位
	# 在 passed_nightclub_security 仍為 false 情況下
	get_tree().root.remove_child(nightclub_node)
	nightclub_node.queue_free()

	GameState.reset_for_new_game()
	# 此時 passed_nightclub_security 應為 false
	nightclub_node = nightclub_scene.instantiate()
	get_tree().root.add_child(nightclub_node)

	# 重進場景後，保全應重新歸位 (visible=true, process_mode=INHERIT)
	bodyguard_node = nightclub_node.get_node_or_null("Interactables/Bodyguard")
	if bodyguard_node == null or not bodyguard_node.visible or bodyguard_node.process_mode != Node.PROCESS_MODE_INHERIT:
		printerr("FAIL 23-C: Bodyguard should reset to visible and inheriting process mode when passed_nightclub_security is false!")
		get_tree().quit(1)
		return

	# 5. 測試：即使 passed_nightclub_security 已為 true，保全仍永遠在崗（可見、INHERIT），只是後場門放行
	get_tree().root.remove_child(nightclub_node)
	nightclub_node.queue_free()

	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)

	nightclub_node = nightclub_scene.instantiate()
	get_tree().root.add_child(nightclub_node)

	bodyguard_node = nightclub_node.get_node_or_null("Interactables/Bodyguard")
	if bodyguard_node == null or not bodyguard_node.visible or bodyguard_node.process_mode != Node.PROCESS_MODE_INHERIT:
		printerr("FAIL 23-C: Bodyguard should stay visible and at post even when passed_nightclub_security is true!")
		get_tree().quit(1)
		return

	# 6. 測試：未在空窗內潛入 → 視窗到期保全歸位；引開為永久一次性
	get_tree().root.remove_child(nightclub_node)
	nightclub_node.queue_free()

	GameState.reset_for_new_game()
	nightclub_node = nightclub_scene.instantiate()
	get_tree().root.add_child(nightclub_node)
	nightclub_node.set_entry_point("from_entrance")

	var captured_msg_p23c6: Dictionary = {}
	nightclub_node.interaction_requested.connect(func(data):
		captured_msg_p23c6.merge(data, true)
	)

	GameState.set_flag("talked_nightclub_bodyguard", true)
	bar_bot = nightclub_node.get_node_or_null("Interactables/BarBot")
	bodyguard_node = nightclub_node.get_node_or_null("Interactables/Bodyguard")
	nightclub_node.current_interactable = bar_bot
	nightclub_node._trigger_interaction()

	if not nightclub_node._bodyguard_off_post:
		printerr("FAIL 23-C: window should open after distraction (step 6)!")
		get_tree().quit(1)
		return

	# 模擬 10 秒空窗到期（未潛入）
	captured_msg_p23c6.clear()
	nightclub_node.force_resolve_distraction()

	if nightclub_node._bodyguard_off_post:
		printerr("FAIL 23-C: window should be closed after expiry (step 6)!")
		get_tree().quit(1)
		return
	if not bodyguard_node.visible or bodyguard_node.process_mode != Node.PROCESS_MODE_INHERIT:
		printerr("FAIL 23-C: bodyguard should return to post after window expiry (step 6)!")
		get_tree().quit(1)
		return
	if captured_msg_p23c6.get("message_text", "") != "MSG_NIGHTCLUB_GUARD_RETURNED":
		printerr("FAIL 23-C: should show guard-returned message after expiry, got: ", captured_msg_p23c6)
		get_tree().quit(1)
		return
	if GameState.get_flag("passed_nightclub_security", false):
		printerr("FAIL 23-C: passed_nightclub_security must stay false after a failed sneak (step 6)!")
		get_tree().quit(1)
		return

	# 永久一次性：再次互動 bar_bot 只給「已修復」中性訊息、不再引開
	captured_msg_p23c6.clear()
	nightclub_node.current_interactable = bar_bot
	nightclub_node._trigger_interaction()
	if captured_msg_p23c6.get("message_text", "") != "MSG_NIGHTCLUB_BAR_BOT_USED":
		printerr("FAIL 23-C: spent bar_bot should show used message, got: ", captured_msg_p23c6)
		get_tree().quit(1)
		return
	if nightclub_node._bodyguard_off_post:
		printerr("FAIL 23-C: spent bar_bot must NOT re-trigger distraction!")
		get_tree().quit(1)
		return

	# 結束清理
	get_tree().root.remove_child(nightclub_node)
	nightclub_node.queue_free()

	print("PASS: Phase 23-C bodyguard distraction and sneak in mechanics verified.")

