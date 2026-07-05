extends "res://tests/manual/phases/phase_9h.gd"

func _run_phase_9g() -> void:
	# Phase 9-G Verification
	# ----------------------------------------------------
	print("Running 9-G Integration tests...")
	runner = DialogueRunner.new()
	GameState.reset_for_new_game()

	# 1. Direct call validation: sell_echo on incomplete echo should fail
	if GameState.sell_echo("echo_room401_tenant"):
		printerr("FAIL 9-G: GameState.sell_echo should return false on incomplete echo!")
		get_tree().quit(1)
		return

	# 2. Dialogue Routing - Empty Case: routes to sell_empty
	var lu_tree = DialogueDB.get_tree_for("lu_qichen")
	runner.start(lu_tree, "sell_gate")
	var curr = runner.current()
	if curr.get("text", "") == "" or not tr(curr.get("text", "")).contains("你手頭還沒有集滿的殘響"):
		printerr("FAIL 9-G: sell_gate should route to sell_empty when no echoes are complete! Got: ", curr)
		get_tree().quit(1)
		return

	# 3. Dialogue Routing - Sale Selection & Exclusions
	# Complete echo_room401_tenant
	GameState.collect_echo_segment("echo_room401_tenant", "s1")
	GameState.collect_echo_segment("echo_room401_tenant", "s2")
	GameState.collect_echo_segment("echo_room401_tenant", "s3")
	if not GameState.is_echo_complete("echo_room401_tenant"):
		printerr("FAIL 9-G: echo_room401_tenant failed to be marked complete!")
		get_tree().quit(1)
		return

	# Verify that only completed unsold echoes appear in sell_menu
	runner.start(lu_tree, "sell_gate")
	curr = runner.current()
	if curr.get("text", "") == "" or not tr(curr.get("text", "")).contains("你想把哪一段交給我"):
		printerr("FAIL 9-G: sell_gate should route to sell_menu when there are completed unsold echoes! Got: ", curr)
		get_tree().quit(1)
		return

	var choices = curr.get("choices", [])
	var room401_choice = null
	var clerk_choice = null
	var lu_family_choice = null
	for choice in choices:
		var label = tr(choice.get("label", ""))
		if "401" in label:
			room401_choice = choice
		elif "店員" in label:
			clerk_choice = choice
		elif "鹿家" in label:
			lu_family_choice = choice

	if room401_choice == null:
		printerr("FAIL 9-G: Room 401 echo choice not found in sell_menu! Got choices: ", choices)
		get_tree().quit(1)
		return
	if clerk_choice != null:
		printerr("FAIL 9-G: Incomplete clerk echo choice should NOT be visible in sell_menu!")
		get_tree().quit(1)
		return
	if lu_family_choice != null:
		printerr("FAIL 9-G: echo_lu_family choice should NOT be visible in sell_menu!")
		get_tree().quit(1)
		return

	# 4. Confirmation & Keep Path: routes back to sell_menu
	runner.choose(room401_choice.get("index"))
	curr = runner.current()
	if curr.get("text", "") == "" or not tr(curr.get("text", "")).contains("你想把這段記憶賣給我嗎"):
		printerr("FAIL 9-G: Selecting echo should route to confirmation node! Got: ", curr)
		get_tree().quit(1)
		return

	var conf_choices = curr.get("choices", [])
	var sell_choice = null
	var keep_choice = null
	for choice in conf_choices:
		var label = tr(choice.get("label", ""))
		if "賣" in label:
			sell_choice = choice
		elif "留" in label:
			keep_choice = choice

	if sell_choice == null or keep_choice == null:
		printerr("FAIL 9-G: Confirmation choices (sell/keep) missing! Got: ", conf_choices)
		get_tree().quit(1)
		return

	# Choose to keep
	runner.choose(keep_choice.get("index"))
	curr = runner.current()
	if curr.get("text", "") == "" or not tr(curr.get("text", "")).contains("你想把哪一段交給我"):
		printerr("FAIL 9-G: Keeping echo should route back to sell_menu! Got: ", curr)
		get_tree().quit(1)
		return

	# 5. Confirmation & Sell Path
	# Re-select room 401
	room401_choice = null
	for choice in curr.get("choices", []):
		if "401" in tr(choice.get("label", "")):
			room401_choice = choice
			break
	runner.choose(room401_choice.get("index"))

	# Select to sell
	conf_choices = runner.current().get("choices", [])
	sell_choice = null
	for choice in conf_choices:
		if "賣" in tr(choice.get("label", "")):
			sell_choice = choice
			break

	var old_credits = GameState.get_credits()
	runner.choose(sell_choice.get("index"))

	# Verify that credits increased by 200 (selling price of room 401 echo)
	if GameState.get_credits() != old_credits + 200:
		printerr("FAIL 9-G: Selling Room 401 echo did not reward correct credits! Expected: ", old_credits + 200, ", got: ", GameState.get_credits())
		get_tree().quit(1)
		return

	# Verify sold state
	if not GameState.is_echo_sold("echo_room401_tenant"):
		printerr("FAIL 9-G: Room 401 echo should be marked as sold!")
		get_tree().quit(1)
		return

	curr = runner.current()
	if curr.get("text", "") == "" or not tr(curr.get("text", "")).contains("獲得了 200 credits"):
		printerr("FAIL 9-G: Sold confirmation text incorrect! Got: ", curr)
		get_tree().quit(1)
		return

	runner.advance()
	curr = runner.current()
	if curr.get("text", "") == "" or not tr(curr.get("text", "")).contains("感謝你的回報"):
		printerr("FAIL 9-G: Should route to sell_done! Got: ", curr)
		get_tree().quit(1)
		return

	# 6. Sold Status & Exclusivity: routes to sell_empty if no completed echoes remain
	runner.advance()
	curr = runner.current()
	if curr.get("text", "") == "" or not tr(curr.get("text", "")).contains("你手頭還沒有集滿的殘響"):
		printerr("FAIL 9-G: After selling, sell_gate should route to sell_empty! Got: ", curr)
		get_tree().quit(1)
		return

	print("PASS 9-G: Dialogue-based sell menu, exclusions, confirmation, keeping, selling rewards, and sold status verified.")

	# ----------------------------------------------------
