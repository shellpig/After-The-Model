extends "res://tests/manual/phases/phase_19c.gd"

func _run_phase_19b() -> void:
	# ===================== Phase 19-B: Old Work Order examine & old_work_badge acquisition =====================
	print("--- Phase 19-B: Old Work Order examine & old_work_badge acquisition ---")

	# 1. Verify OldWorkOrderArea node in underground_settlement.tscn
	var settlement_scene = load("res://scenes/levels/underground_settlement/underground_settlement.tscn")
	if settlement_scene == null:
		printerr("FAIL 19-B: could not load underground_settlement.tscn!")
		get_tree().quit(1)
		return

	var settlement_inst = settlement_scene.instantiate()
	var order_node = settlement_inst.find_child("OldWorkOrderArea", true, false)
	if order_node == null:
		printerr("FAIL 19-B: OldWorkOrderArea node not found in underground_settlement.tscn!")
		get_tree().quit(1)
		return

	if order_node.interaction_id != "examine_old_work_order" or order_node.prompt_text != "PROMPT_EXAMINE_OLD_WORK_ORDER":
		printerr("FAIL 19-B: OldWorkOrderArea properties mismatch!")
		get_tree().quit(1)
		return

	print("DEBUG: order_node interaction_id='", order_node.interaction_id, "' dialogue_id='", order_node.dialogue_id, "'")

	# 2. Test interaction before collecting Ada's echo
	GameState.reset_for_new_game()
	GameState.add_item("old_work_badge", 1)

	var last_msg = {"text": ""}
	var on_msg = func(data: Dictionary):
		if data.get("type") == "message":
			last_msg["text"] = data.get("message_text", "")
	settlement_inst.interaction_requested.connect(on_msg)

	settlement_inst.current_interactable = order_node
	settlement_inst._trigger_interaction()

	if last_msg["text"] != "MSG_OLD_WORK_ORDER_NEUTRAL":
		printerr("FAIL 19-B: Expected MSG_OLD_WORK_ORDER_NEUTRAL when echo is incomplete, got: ", last_msg["text"])
		get_tree().quit(1)
		return

	if GameState.get_flag("read_old_work_order", false) or GameState.has_note("clue_old_work_order"):
		printerr("FAIL 19-B: States modified before echo collection!")
		get_tree().quit(1)
		return

	# 3. Test successful interaction
	GameState.reset_for_new_game()
	GameState.add_item("old_work_badge", 1)
	GameState.collect_echo_segment("echo_ada_reset", "s1")

	last_msg["text"] = ""
	settlement_inst._trigger_interaction()

	if last_msg["text"] != "MSG_OLD_WORK_ORDER_REVEALED":
		printerr("FAIL 19-B: Expected MSG_OLD_WORK_ORDER_REVEALED on first success, got: ", last_msg["text"])
		get_tree().quit(1)
		return

	if not GameState.get_flag("read_old_work_order", false):
		printerr("FAIL 19-B: read_old_work_order flag not set on success!")
		get_tree().quit(1)
		return

	if not GameState.has_item("old_work_badge"):
		printerr("FAIL 19-B: old_work_badge not in inventory!")
		get_tree().quit(1)
		return

	var badge_count_success = 0
	for slot in GameState.inventory:
		if not slot.is_empty() and slot.get("item_id") == "old_work_badge":
			badge_count_success += slot.get("quantity", 0)
	if badge_count_success != 1:
		printerr("FAIL 19-B: old_work_badge count is not 1, got: ", badge_count_success)
		get_tree().quit(1)
		return

	if GameState.get_item_description("old_work_badge") != "ITEM_OLD_WORK_BADGE_DESC_REVEALED":
		printerr("FAIL 19-B: old_work_badge description was not updated dynamically!")
		get_tree().quit(1)
		return

	if not GameState.has_note("clue_old_work_order"):
		printerr("FAIL 19-B: clue_old_work_order note not registered!")
		get_tree().quit(1)
		return

	# 4. Test subsequent interaction (already read)
	last_msg["text"] = ""
	var badge_count_before = 0
	for slot in GameState.inventory:
		if not slot.is_empty() and slot.get("item_id") == "old_work_badge":
			badge_count_before += slot.get("quantity", 0)

	settlement_inst._trigger_interaction()

	if last_msg["text"] != "MSG_OLD_WORK_ORDER_READ":
		printerr("FAIL 19-B: Expected MSG_OLD_WORK_ORDER_READ on repeat exam, got: ", last_msg["text"])
		get_tree().quit(1)
		return

	var badge_count_after = 0
	for slot in GameState.inventory:
		if not slot.is_empty() and slot.get("item_id") == "old_work_badge":
			badge_count_after += slot.get("quantity", 0)

	if badge_count_after != badge_count_before:
		printerr("FAIL 19-B: Re-granted old_work_badge on repeat exam!")
		get_tree().quit(1)
		return

	# 5. Verification of forbidden words
	var i18n_keys := [
		"MSG_OLD_WORK_ORDER_NEUTRAL",
		"MSG_OLD_WORK_ORDER_REVEALED",
		"MSG_OLD_WORK_ORDER_READ",
		"NOTE_CLUE_OLD_WORK_ORDER_TITLE",
		"NOTE_CLUE_OLD_WORK_ORDER_BODY",
		"PROMPT_EXAMINE_OLD_WORK_ORDER",
		"ITEM_OLD_WORK_BADGE_DESC_REVEALED"
	]

	for lang in ["zh_TW", "zh_CN", "en"]:
		LocaleManager.set_locale(lang)
		for key in i18n_keys:
			var txt = tr(key)
			if lang == "en":
				var lower_txt = txt.to_lower()
				if "lin fei" in lower_txt or "linfei" in lower_txt:
					printerr("FAIL 19-B: Forbidden word Lin Fei found in key: ", key, " for lang: ", lang)
					get_tree().quit(1)
					return
			else:
				if "林霏" in txt:
					printerr("FAIL 19-B: Forbidden word 林霏 found in key: ", key, " for lang: ", lang)
					get_tree().quit(1)
					return

	LocaleManager.set_locale("zh_TW")
	settlement_inst.free()
	print("PASS: Phase 19-B Old Work Order examine & old_work_badge acquisition verified.")

