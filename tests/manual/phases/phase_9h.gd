extends "res://tests/manual/phases/phase_10a.gd"

func _run_phase_9h() -> void:
	# Phase 9-H Verification
	# ----------------------------------------------------
	print("Running 9-H Integration tests...")

	# We will verify save/load round-trip across 5 checkpoints:
	# Checkpoint 1: Before taking module (取模組前)
	GameState.reset_for_new_game()
	GameState.set_flag("apartment_initialized", true)
	GameState.add_item("fingerless_gloves", 1)

	var checkpoint1_save = GameState.to_save_dict()

	# Verify Checkpoint 1 state
	if GameState.get_flag("probe_module_taken", false) or GameState.has_item("old_probe_module") or GameState.get_flag("gleaner_gloves_installed", false):
		printerr("FAIL 9-H Checkpoint 1: Initial state is incorrect!")
		get_tree().quit(1)
		return

	# Checkpoint 2: Before appraisal (鑑定前)
	GameState.set_flag("probe_module_taken", true)
	GameState.add_item("old_probe_module", 1)

	var checkpoint2_save = GameState.to_save_dict()

	# Checkpoint 3: During collection (採集中)
	# Install glove upgrade
	if not GameState.install_probe_module():
		printerr("FAIL 9-H Checkpoint 3: install_probe_module failed during state transition!")
		get_tree().quit(1)
		return

	# Collect some segments (not complete)
	GameState.collect_echo_segment("echo_room401_tenant", "s1")
	GameState.collect_echo_segment("echo_room401_tenant", "s2")

	var checkpoint3_save = GameState.to_save_dict()

	# Checkpoint 4: Completed but unsold (集滿未賣)
	GameState.collect_echo_segment("echo_room401_tenant", "s3")

	var checkpoint4_save = GameState.to_save_dict()

	# Checkpoint 5: Sold (賣出後)
	var old_credits_9h = GameState.get_credits()
	if not GameState.sell_echo("echo_room401_tenant"):
		printerr("FAIL 9-H Checkpoint 5: sell_echo failed during state transition!")
		get_tree().quit(1)
		return

	var checkpoint5_save = GameState.to_save_dict()

	# Now, we will load and verify each checkpoint save dict one by one to ensure exact state restoration.

	# Restore Checkpoint 5
	GameState.reset_for_new_game()
	GameState.load_save_dict(checkpoint5_save)
	if not GameState.is_echo_sold("echo_room401_tenant") or GameState.get_credits() != old_credits_9h + 200:
		printerr("FAIL 9-H restore: Checkpoint 5 sold status or credits failed to restore!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("gleaner_gloves_installed", false):
		printerr("FAIL 9-H restore: Checkpoint 5 glove install status failed to restore!")
		get_tree().quit(1)
		return

	# Restore Checkpoint 4
	GameState.reset_for_new_game()
	GameState.load_save_dict(checkpoint4_save)
	if not GameState.is_echo_complete("echo_room401_tenant") or GameState.is_echo_sold("echo_room401_tenant"):
		printerr("FAIL 9-H restore: Checkpoint 4 complete/sold status failed to restore!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != old_credits_9h:
		printerr("FAIL 9-H restore: Checkpoint 4 credits failed to restore!")
		get_tree().quit(1)
		return

	# Restore Checkpoint 3
	GameState.reset_for_new_game()
	GameState.load_save_dict(checkpoint3_save)
	if GameState.is_echo_complete("echo_room401_tenant") or not GameState.has_echo_segment("echo_room401_tenant", "s1") or GameState.has_echo_segment("echo_room401_tenant", "s3"):
		printerr("FAIL 9-H restore: Checkpoint 3 echo segments failed to restore!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("gleaner_gloves_installed", false):
		printerr("FAIL 9-H restore: Checkpoint 3 glove install status failed to restore!")
		get_tree().quit(1)
		return

	# Restore Checkpoint 2
	GameState.reset_for_new_game()
	GameState.load_save_dict(checkpoint2_save)
	if not GameState.get_flag("probe_module_taken", false) or not GameState.has_item("old_probe_module") or GameState.get_flag("gleaner_gloves_installed", false):
		printerr("FAIL 9-H restore: Checkpoint 2 probe module or glove status failed to restore!")
		get_tree().quit(1)
		return

	# Restore Checkpoint 1
	GameState.reset_for_new_game()
	GameState.load_save_dict(checkpoint1_save)
	if GameState.get_flag("probe_module_taken", false) or GameState.has_item("old_probe_module") or GameState.get_flag("gleaner_gloves_installed", false):
		printerr("FAIL 9-H restore: Checkpoint 1 initial flags failed to restore!")
		get_tree().quit(1)
		return

	print("PASS 9-H: Save/load round-trip across 5 checkpoints verified successfully.")

	# ============================================================
