extends "res://tests/manual/phases/phase_6a.gd"

func _run_phase_5b() -> void:
	# 14. Verify GameUI DialoguePanel & Wiring (Phase 5-B)
	print("Verifying GameUI DialoguePanel & Wiring (Phase 5-B)...")

	var test_game_ui = main_instance.get_node_or_null("GameUI")
	if not test_game_ui:
		printerr("FAIL: GameUI not found in Main scene!")
		get_tree().quit(1)
		return

	var dp = test_game_ui.get_node_or_null("DialoguePanel")
	if not dp:
		printerr("FAIL: DialoguePanel not found in GameUI!")
		get_tree().quit(1)
		return
	print("PASS: DialoguePanel exists inside GameUI.")

	# Reset state before testing Dialogue UI
	GameState.story_flags.clear()
	UIMode.set_mode(UIMode.Mode.NONE)

	# Trigger dialogue via mediator channel (simulated level interaction request)
	main_instance._on_level_interaction_requested({
		"type": "dialogue",
		"dialogue_id": "wan"
	})

	if UIMode.get_mode() != UIMode.Mode.DIALOGUE:
		printerr("FAIL: UIMode should be DIALOGUE after starting dialogue! Got: ", UIMode.get_mode())
		get_tree().quit(1)
		return

	if not dp.visible:
		printerr("FAIL: DialoguePanel should be visible in DIALOGUE mode!")
		get_tree().quit(1)
		return
	print("PASS: DialoguePanel visibility toggled correctly by UIMode.")

	# Enable touch buttons for testing TouchControls visibility
	var old_touch_enabled = TouchControls.touch_buttons_enabled
	TouchControls.touch_buttons_enabled = true
	TouchControls._update_dynamic_button_visibility()

	# Verify TouchControls visibility in DIALOGUE mode
	if not TouchControls.get_node("Control/DPad").visible:
		printerr("FAIL: DPad should be visible in DIALOGUE mode!")
		get_tree().quit(1)
		return
	if TouchControls.get_node("Control/Menus/BtnBag").visible or TouchControls.get_node("Control/Menus/BtnNote").visible or TouchControls.get_node("Control/Menus/BtnClose").visible:
		printerr("FAIL: Menu buttons should be hidden in DIALOGUE mode!")
		get_tree().quit(1)
		return
	if not TouchControls.get_node("Control/Actions/BtnE").visible:
		printerr("FAIL: BtnE should be visible in DIALOGUE mode!")
		get_tree().quit(1)
		return
	if TouchControls.get_node("Control/Actions/BtnR").visible or TouchControls.get_node("Control/Actions/BtnT").visible:
		printerr("FAIL: BtnR/BtnT should be hidden in DIALOGUE mode!")
		get_tree().quit(1)
		return
	print("PASS: TouchControls visibility rules in DIALOGUE mode verified.")

	var press_e = func():
		var event := InputEventAction.new()
		event.action = "interact_primary"
		event.pressed = true
		dp._unhandled_input(event)

	var name_lbl = dp.get_node("DialogueBox/MarginContainer/VBoxContainer/NameLabel") as Label
	var text_lbl = dp.get_node("DialogueBox/MarginContainer/VBoxContainer/TextLabel") as Label
	var choice_box = dp.get_node("DialogueBox/MarginContainer/VBoxContainer/ChoicesContainer") as VBoxContainer

	if name_lbl.text != "晚" or not text_lbl.text.contains("新面孔"):
		printerr("FAIL: DialoguePanel should display first meet text! Got: ", name_lbl.text, " - ", text_lbl.text)
		get_tree().quit(1)
		return

	if choice_box.get_child_count() != 3:
		printerr("FAIL: first_meet should display 3 choices in UI, got: ", choice_box.get_child_count())
		get_tree().quit(1)
		return
	print("PASS: DialoguePanel contents initialized correctly (Name, text, and 3 choices).")

	# Wait a frame to let UI grab focus and connection setups complete
	await get_tree().process_frame

	# Verify focus on first choice
	var btn0 = choice_box.get_child(0) as Button
	if not btn0.text.begins_with(">"):
		printerr("FAIL: First choice should have focus caret prefix '> '! Got button text: ", btn0.text)
		get_tree().quit(1)
		return
	print("PASS: Focused choice has caret prefix '> '.")

	# Verify HintLabel content for choices state
	var hint_lbl = dp.get_node("DialogueBox/MarginContainer/HintLabel") as Label
	if hint_lbl.text != "W/S: 選擇    E: 確認":
		printerr("FAIL: HintLabel text should be 'W/S: 選擇    E: 確認' when choices exist! Got: ", hint_lbl.text)
		get_tree().quit(1)
		return
	print("PASS: Dialogue HintLabel verified for choices state.")

	# Verify keyboard S / move_down moves focus
	var event_down := InputEventAction.new()
	event_down.action = "move_down"
	event_down.pressed = true
	dp._unhandled_input(event_down)
	await get_tree().process_frame

	var btn_ws1 = choice_box.get_child(1) as Button
	if not btn_ws1.text.begins_with(">"):
		printerr("FAIL: Keyboard S / move_down did not move focus to second choice!")
		get_tree().quit(1)
		return

	# Move back up using W / move_up
	var event_up := InputEventAction.new()
	event_up.action = "move_up"
	event_up.pressed = true
	dp._unhandled_input(event_up)
	await get_tree().process_frame
	if not btn0.text.begins_with(">"):
		printerr("FAIL: Keyboard W / move_up did not move focus back to first choice!")
		get_tree().quit(1)
		return
	print("PASS: Keyboard W/S choice navigation verified.")

	# Move focus down using TouchControls simulated Dpad Down
	TouchControls._simulate_action("move_down", true)
	await get_tree().process_frame

	var btn1 = choice_box.get_child(1) as Button
	if not btn1.text.begins_with(">") or btn0.text.begins_with(">"):
		printerr("FAIL: Focus didn't move to second choice or first choice retained caret! btn0: ", btn0.text, ", btn1: ", btn1.text)
		get_tree().quit(1)
		return
	print("PASS: Focus moved down correctly using TouchControls Dpad, caret prefixes updated.")

	# Confirm the chosen option ("妳是誰？" which is index 1, option 1) using TouchControls simulated BtnE
	TouchControls._simulate_action("interact_primary", true)
	await get_tree().process_frame

	if not text_lbl.text.contains("名字？"):
		printerr("FAIL: Dialogue didn't branch to 'who' node! Got: ", text_lbl.text)
		get_tree().quit(1)
		return

	if not GameState.has_flag("knows_wan_name"):
		printerr("FAIL: knows_wan_name flag not set after choosing 'who' choice!")
		get_tree().quit(1)
		return
	print("PASS: Branching and GameState flags modification verified in UI dialogue sequence.")

	if hint_lbl.text != "E: 繼續":
		printerr("FAIL: HintLabel text should be 'E: 繼續' for non-choices non-terminal node! Got: ", hint_lbl.text)
		get_tree().quit(1)
		return
	print("PASS: Dialogue HintLabel verified for E: 繼續 state.")

	# 'who' node is terminal, so confirm again should advance to 'watch'
	press_e.call()
	await get_tree().process_frame

	if not text_lbl.text.contains("那塊招牌"):
		printerr("FAIL: Dialogue didn't advance to 'watch' node! Got: ", text_lbl.text)
		get_tree().quit(1)
		return

	if choice_box.get_child_count() != 2:
		printerr("FAIL: 'watch' node should have 2 choices in UI, got: ", choice_box.get_child_count())
		get_tree().quit(1)
		return

	# Confirm option 0 ("我也撿這種東西。" which has index 0)
	# Focus is on first choice by default, so just confirm
	press_e.call()
	await get_tree().process_frame

	if not text_lbl.text.contains("同類"):
		printerr("FAIL: Dialogue didn't branch to 'kin' node! Got: ", text_lbl.text)
		get_tree().quit(1)
		return

	if GameState.get_flag("affinity_wan") != 1 or not GameState.get_flag("met_wan"):
		printerr("FAIL: kin effect values not updated in GameState!")
		get_tree().quit(1)
		return

	# 'kin' is terminal -> advance to 'end_warm'
	press_e.call()
	await get_tree().process_frame

	if not text_lbl.text.contains("有意思的"):
		printerr("FAIL: Dialogue didn't advance to 'end_warm'! Got: ", text_lbl.text)
		get_tree().quit(1)
		return

	if hint_lbl.text != "E: 關閉":
		printerr("FAIL: HintLabel text should be 'E: 關閉' for terminal node! Got: ", hint_lbl.text)
		get_tree().quit(1)
		return
	print("PASS: Dialogue HintLabel verified for E: 關閉 state.")

	# 'end_warm' is terminal -> advance to end dialogue
	press_e.call()
	await get_tree().process_frame

	if UIMode.get_mode() != UIMode.Mode.NONE:
		printerr("FAIL: UIMode should revert to NONE after dialogue finished! Got: ", UIMode.get_mode())
		get_tree().quit(1)
		return

	if dp.visible:
		printerr("FAIL: DialoguePanel should be hidden after dialogue finished!")
		get_tree().quit(1)
		return
	print("PASS: Dialogue sequence finished, UI closed, and UIMode reverted to NONE.")

	TouchControls.touch_buttons_enabled = old_touch_enabled
	TouchControls._update_dynamic_button_visibility()

