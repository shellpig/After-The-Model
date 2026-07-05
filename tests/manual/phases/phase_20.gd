extends "res://tests/manual/phases/phase_21a.gd"

func _run_phase_20() -> void:
	# ===================== Phase 20: Act 2D 七號可選 + 和平線 Branch D =====================
	print("--- Phase 20: Act 2D 七號可選 + 和平線 Branch D ---")
	var dialogue_db_p20 = load("res://data/dialogue/dialogue_db.gd")
	var seven_tree_20 = dialogue_db_p20.get_tree_for("seven")

	# Test Case 1: Without receipt item, the receipt-hand-over choice should NOT be visible.
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	var runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	var curr_20 = runner_20.current()
	var choices_20 = curr_20.get("choices", [])
	var has_receipt_choice = false
	for choice in choices_20:
		if "回執" in tr(choice.get("label", "")):
			has_receipt_choice = true
	if has_receipt_choice:
		printerr("FAIL 20: Receipt choice visible when item is missing!")
		get_tree().quit(1)
		return

	# Test Case 2: With receipt item but peace_line_locked = true, the choice should NOT be visible.
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	GameState.set_flag("peace_line_locked", true)
	GameState.add_item("childcare_supply_receipt", 1)
	runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	curr_20 = runner_20.current()
	choices_20 = curr_20.get("choices", [])
	has_receipt_choice = false
	for choice in choices_20:
		if "回執" in tr(choice.get("label", "")):
			has_receipt_choice = true
	if has_receipt_choice:
		printerr("FAIL 20: Receipt choice visible when peace_line_locked is true!")
		get_tree().quit(1)
		return

	# Test Case 3: With receipt item and peace_line_locked = false, choice is visible. Choose return path.
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	GameState.add_item("childcare_supply_receipt", 1)
	runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	curr_20 = runner_20.current()
	choices_20 = curr_20.get("choices", [])
	var receipt_choice_index := -1
	for choice in choices_20:
		if "回執" in tr(choice.get("label", "")):
			receipt_choice_index = choice.get("index", -1)
	if receipt_choice_index == -1:
		printerr("FAIL 20: Receipt choice NOT visible when conditions are met!")
		get_tree().quit(1)
		return

	# Choose the receipt choice
	runner_20.choose(receipt_choice_index)
	curr_20 = runner_20.current()
	if not "物流單" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected receipt_probe node, got: ", curr_20)
		get_tree().quit(1)
		return

	# Stage 1 now offers 3 choices: Threaten, Taunt, and the correct give-it line.
	var probe_choices = curr_20.get("choices", [])
	if probe_choices.size() != 3:
		printerr("FAIL 20: Expected 3 choices in receipt_probe stage 1, got: ", probe_choices.size())
		get_tree().quit(1)
		return

	# Test Case 3: Stage-1 Threaten (index 0) -> rebuff_leverage -> leave.
	runner_20.choose(0)
	curr_20 = runner_20.current()
	if not "我不做這種買賣" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected rebuff_leverage on stage-1 threat, got: ", curr_20)
		get_tree().quit(1)
		return
	runner_20.advance()
	curr_20 = runner_20.current()
	if not "不再理會你" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected leave node after failure, got: ", curr_20)
		get_tree().quit(1)
		return
	if GameState.get_flag("seven_peace_branch_d", false):
		printerr("FAIL 20: seven_peace_branch_d set on failure path!")
		get_tree().quit(1)
		return
	if not GameState.has_item("childcare_supply_receipt", 1):
		printerr("FAIL 20: receipt item removed on failure path!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("seven_receipt_rebuffed", false):
		printerr("FAIL 20: seven_receipt_rebuffed not set on stage-1 threat failure!")
		get_tree().quit(1)
		return

	# Test Case 4: Stage-1 Taunt (index 1) -> rebuff_probe.
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	GameState.add_item("childcare_supply_receipt", 1)
	runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	curr_20 = runner_20.current()
	choices_20 = curr_20.get("choices", [])
	receipt_choice_index = -1
	for choice in choices_20:
		if "回執" in tr(choice.get("label", "")):
			receipt_choice_index = choice.get("index", -1)
	runner_20.choose(receipt_choice_index)
	runner_20.choose(1) # Taunt -> rebuff_probe
	curr_20 = runner_20.current()
	if not "別在我面前耍花樣" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected rebuff_probe on stage-1 taunt, got: ", curr_20)
		get_tree().quit(1)
		return

	# Test Case 5a: Stage-1 correct -> stage 2; Pry (index 0) -> rebuff_probe.
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	GameState.add_item("childcare_supply_receipt", 1)
	runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	curr_20 = runner_20.current()
	choices_20 = curr_20.get("choices", [])
	receipt_choice_index = -1
	for choice in choices_20:
		if "回執" in tr(choice.get("label", "")):
			receipt_choice_index = choice.get("index", -1)
	runner_20.choose(receipt_choice_index)
	runner_20.choose(2) # Stage 1 correct -> stage 2
	curr_20 = runner_20.current()
	if not "在哪裡撿到的" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected receipt_probe_s2 after stage-1 correct, got: ", curr_20)
		get_tree().quit(1)
		return
	runner_20.choose(0) # Pry -> rebuff_probe
	curr_20 = runner_20.current()
	if not "別在我面前耍花樣" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected rebuff_probe on stage-2 pry, got: ", curr_20)
		get_tree().quit(1)
		return

	# Test Case 5b: Stage-1 correct -> stage 2; Bargain (index 1) -> rebuff_leverage.
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	GameState.add_item("childcare_supply_receipt", 1)
	runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	curr_20 = runner_20.current()
	choices_20 = curr_20.get("choices", [])
	receipt_choice_index = -1
	for choice in choices_20:
		if "回執" in tr(choice.get("label", "")):
			receipt_choice_index = choice.get("index", -1)
	runner_20.choose(receipt_choice_index)
	runner_20.choose(2) # Stage 1 correct -> stage 2
	runner_20.choose(1) # Bargain -> rebuff_leverage
	curr_20 = runner_20.current()
	if not "我不做這種買賣" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected rebuff_leverage on stage-2 bargain, got: ", curr_20)
		get_tree().quit(1)
		return

	# Test Case 5c: Stage 1+2 correct -> stage 3; Pity (index 0) -> rebuff_leverage.
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	GameState.add_item("childcare_supply_receipt", 1)
	runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	curr_20 = runner_20.current()
	choices_20 = curr_20.get("choices", [])
	receipt_choice_index = -1
	for choice in choices_20:
		if "回執" in tr(choice.get("label", "")):
			receipt_choice_index = choice.get("index", -1)
	runner_20.choose(receipt_choice_index)
	runner_20.choose(2) # Stage 1 correct
	runner_20.choose(2) # Stage 2 correct -> stage 3
	curr_20 = runner_20.current()
	if not "為什麼拿來給我" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected receipt_probe_s3 after stage-2 correct, got: ", curr_20)
		get_tree().quit(1)
		return
	runner_20.choose(0) # Pity -> rebuff_leverage
	curr_20 = runner_20.current()
	if not "我不做這種買賣" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected rebuff_leverage on stage-3 pity, got: ", curr_20)
		get_tree().quit(1)
		return

	# Test Case 5d: Stage 1+2 correct -> stage 3; Withdraw (index 1) -> rebuff_probe.
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	GameState.add_item("childcare_supply_receipt", 1)
	runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	curr_20 = runner_20.current()
	choices_20 = curr_20.get("choices", [])
	receipt_choice_index = -1
	for choice in choices_20:
		if "回執" in tr(choice.get("label", "")):
			receipt_choice_index = choice.get("index", -1)
	runner_20.choose(receipt_choice_index)
	runner_20.choose(2) # Stage 1 correct
	runner_20.choose(2) # Stage 2 correct
	runner_20.choose(1) # Withdraw -> rebuff_probe
	curr_20 = runner_20.current()
	if not "別在我面前耍花樣" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected rebuff_probe on stage-3 withdraw, got: ", curr_20)
		get_tree().quit(1)
		return

	# Test Case 6: Choose Return (index 3) -> Success path!
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	GameState.add_item("childcare_supply_receipt", 1)

	var initial_affinity_phase20 = GameState.get_trust("seven")
	var initial_trace_phase20 = GameState.get_trace()

	runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	curr_20 = runner_20.current()
	choices_20 = curr_20.get("choices", [])
	receipt_choice_index = -1
	for choice in choices_20:
		if "回執" in tr(choice.get("label", "")):
			receipt_choice_index = choice.get("index", -1)
	runner_20.choose(receipt_choice_index)

	runner_20.choose(2) # Stage 1 correct
	runner_20.choose(2) # Stage 2 correct
	runner_20.choose(2) # Stage 3 return
	curr_20 = runner_20.current()
	if not "故意打錯的字" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected receipt_return, got: ", curr_20)
		get_tree().quit(1)
		return

	runner_20.advance()
	curr_20 = runner_20.current()
	if not "那我不能回去" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected receipt_recognized, got: ", curr_20)
		get_tree().quit(1)
		return

	runner_20.advance()
	curr_20 = runner_20.current()
	if not "我欠你一次" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected peace_branch_d_done, got: ", curr_20)
		get_tree().quit(1)
		return

	if GameState.has_item("childcare_supply_receipt", 1):
		printerr("FAIL 20: receipt item was NOT removed on success path!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("seven_peace_branch_d", false):
		printerr("FAIL 20: seven_peace_branch_d flag NOT set to true on success path!")
		get_tree().quit(1)
		return
	if GameState.get_trust("seven") != initial_affinity_phase20 + 2:
		printerr("FAIL 20: affinity_seven did not increase by 2! Got: ", GameState.get_trust("seven"))
		get_tree().quit(1)
		return
	if GameState.get_trace() != initial_trace_phase20 - 1:
		printerr("FAIL 20: trace did not decrease by 1! Got: ", GameState.get_trace())
		get_tree().quit(1)
		return

	# Test save & load round-trip
	var save_data_phase20 = SaveSystem.capture("underground_settlement_right", 100.0, 1)
	GameState.reset_for_new_game()
	SaveSystem.apply(save_data_phase20)
	if not GameState.get_flag("seven_peace_branch_d", false):
		printerr("FAIL 20: seven_peace_branch_d flag not restored after save/load!")
		get_tree().quit(1)
		return
	if GameState.get_trust("seven") != initial_affinity_phase20 + 2:
		printerr("FAIL 20: affinity_seven not restored after save/load!")
		get_tree().quit(1)
		return
	if GameState.get_trace() != initial_trace_phase20 - 1:
		printerr("FAIL 20: trace not restored after save/load!")
		get_tree().quit(1)
		return

	# Test Case 7: retalk_d routing when seven_peace_branch_d is true.
	runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	curr_20 = runner_20.current()
	if not "沒別的事就別煩我" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected retalk_d when seven_peace_branch_d is true, got: ", curr_20)
		get_tree().quit(1)
		return
	choices_20 = curr_20.get("choices", [])
	if choices_20.size() != 1 or not "離開" in tr(choices_20[0].get("label", "")):
		printerr("FAIL 20: Expected only 'leave' choice in retalk_d, got: ", choices_20)
		get_tree().quit(1)
		return

	# Test Case 8: Failure sets seven_receipt_rebuffed; on retry the receipt choice
	# routes to receipt_reprobe (terse, no naive first-time replay) and can still succeed.
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	GameState.add_item("childcare_supply_receipt", 1)
	runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	curr_20 = runner_20.current()
	choices_20 = curr_20.get("choices", [])
	receipt_choice_index = -1
	for choice in choices_20:
		if "回執" in tr(choice.get("label", "")):
			receipt_choice_index = choice.get("index", -1)
	runner_20.choose(receipt_choice_index)
	runner_20.choose(0) # Threaten -> rebuff_leverage (sets seven_receipt_rebuffed)
	if not GameState.get_flag("seven_receipt_rebuffed", false):
		printerr("FAIL 20: seven_receipt_rebuffed not set after failure path!")
		get_tree().quit(1)
		return

	# Re-open dialogue: receipt choice now routes to receipt_reprobe.
	runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	curr_20 = runner_20.current()
	choices_20 = curr_20.get("choices", [])
	receipt_choice_index = -1
	for choice in choices_20:
		if "回執" in tr(choice.get("label", "")):
			receipt_choice_index = choice.get("index", -1)
	runner_20.choose(receipt_choice_index)
	curr_20 = runner_20.current()
	if not "又是這個" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected receipt_reprobe on retry after rebuff, got: ", curr_20)
		get_tree().quit(1)
		return

	# Return path from reprobe still walks the 3 stages to success and applies effects.
	runner_20.choose(2) # Stage 1 correct (from reprobe) -> stage 2
	runner_20.choose(2) # Stage 2 correct -> stage 3
	runner_20.choose(2) # Stage 3 return -> receipt_return
	runner_20.advance() # receipt_recognized
	runner_20.advance() # peace_branch_d_done (effects fire on enter)
	if GameState.has_item("childcare_supply_receipt", 1):
		printerr("FAIL 20: receipt NOT removed on reprobe success path!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("seven_peace_branch_d", false):
		printerr("FAIL 20: seven_peace_branch_d NOT set on reprobe success path!")
		get_tree().quit(1)
		return

	# Forbidden word checks for all Phase 20 keys
	var keys_20 = [
		"DLG_SEVEN_RETALK_CHOICE_RECEIPT",
		"DLG_SEVEN_RETALK_D_TEXT",
		"DLG_SEVEN_RECEIPT_PROBE_TEXT",
		"DLG_SEVEN_RECEIPT_CHOICE_THREAT",
		"DLG_SEVEN_RECEIPT_CHOICE_TAUNT",
		"DLG_SEVEN_RECEIPT_S1_CHOICE_CORRECT",
		"DLG_SEVEN_RECEIPT_CHOICE_RETURN",
		"DLG_SEVEN_RECEIPT_REPROBE_TEXT",
		"DLG_SEVEN_RECEIPT_S2_TEXT",
		"DLG_SEVEN_RECEIPT_S2_CHOICE_PRY",
		"DLG_SEVEN_RECEIPT_S2_CHOICE_BARGAIN",
		"DLG_SEVEN_RECEIPT_S2_CHOICE_CORRECT",
		"DLG_SEVEN_RECEIPT_S3_TEXT",
		"DLG_SEVEN_RECEIPT_S3_CHOICE_PITY",
		"DLG_SEVEN_RECEIPT_S3_CHOICE_WITHDRAW",
		"DLG_SEVEN_REBUFF_LEVERAGE_TEXT",
		"DLG_SEVEN_REBUFF_PROBE_TEXT",
		"DLG_SEVEN_RECEIPT_RETURN_TEXT",
		"DLG_SEVEN_RECEIPT_RECOGNIZED_TEXT",
		"DLG_SEVEN_PEACE_BRANCH_D_DONE_TEXT"
	]
	for k in keys_20:
		for lang in ["zh_TW", "zh_CN", "en"]:
			LocaleManager.set_locale(lang)
			var txt = tr(k)
			if lang == "en":
				var lower_txt = txt.to_lower()
				if "lin fei" in lower_txt or "linfei" in lower_txt:
					printerr("FAIL 20: Forbidden word Lin Fei found in key ", k, " for lang ", lang)
					get_tree().quit(1)
					return
			else:
				if "林霏" in txt:
					printerr("FAIL 20: Forbidden word 林霏 found in key ", k, " for lang ", lang)
					get_tree().quit(1)
					return
	LocaleManager.set_locale("zh_TW")
	print("PASS: Phase 20 seven dialogue choices and state effects verified.")

