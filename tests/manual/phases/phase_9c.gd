extends "res://tests/manual/phases/phase_9d.gd"

func _run_phase_9c() -> void:
	# Phase 9-C Verification
	# ----------------------------------------------------
	print("Running 9-C Integration tests...")

	# Regression checks for discovered fixes
	# Issue 1: gleaner_gloves can_decode capability
	if not GameState.ITEMS_DB["gleaner_gloves"].get("can_decode", false):
		printerr("FAIL 9-C: gleaner_gloves metadata is missing can_decode: true!")
		get_tree().quit(1)
		return

	# Issue 2: entry_points registry check
	var MainClass = load("res://scenes/main/main.gd")
	if not MainClass.SCENES["apartment_entrance"]["entry_points"].has("from_collector_shop"):
		printerr("FAIL 9-C: apartment_entrance is missing from_collector_shop entry point!")
		get_tree().quit(1)
		return

	# Issue 3: DialogueRunner echo_complete and echo_unsold condition evaluation
	var runner_test = DialogueRunner.new()
	GameState.reset_for_new_game()
	var cond_complete = {"type": "echo_complete", "value": "echo_clerk"}
	if runner_test._eval_condition_dict(cond_complete):
		printerr("FAIL 9-C: echo_complete condition should evaluate to false when echo is not complete!")
		get_tree().quit(1)
		return

	GameState.record_full_echo("echo_clerk")
	if not runner_test._eval_condition_dict(cond_complete):
		printerr("FAIL 9-C: echo_complete condition should evaluate to true when echo is complete!")
		get_tree().quit(1)
		return

	var cond_unsold = {"type": "echo_unsold", "value": "echo_clerk"}
	if not runner_test._eval_condition_dict(cond_unsold):
		printerr("FAIL 9-C: echo_unsold condition should evaluate to true when echo is unsold!")
		get_tree().quit(1)
		return

	# Issue 4: DialogueRunner sell_echo effect application
	var eff_sell = {"op": "sell_echo", "value": "echo_clerk"}
	var old_credits_sell = GameState.get_credits()
	if not runner_test._apply_effect(eff_sell):
		printerr("FAIL 9-C: sell_echo effect execution failed!")
		get_tree().quit(1)
		return
	if not GameState.is_echo_sold("echo_clerk") or GameState.get_credits() != old_credits_sell + 300:
		printerr("FAIL 9-C: sell_echo effect did not sell the echo or reward credits!")
		get_tree().quit(1)
		return

	if runner_test._eval_condition_dict(cond_unsold):
		printerr("FAIL 9-C: echo_unsold condition should evaluate to false after echo is sold!")
		get_tree().quit(1)
		return

	# Issue 5: lu_qichen hub appraise condition includes fingerless_gloves check
	var lu_tree_check = DialogueDB.get_tree_for("lu_qichen")
	var appraise_choices = lu_tree_check["hub"]["choices"]
	var appraise_choice = null
	for choice in appraise_choices:
		if choice.get("goto") == "appraise":
			appraise_choice = choice
			break
	if not appraise_choice:
		printerr("FAIL 9-C: appraise choice not found in lu_qichen hub dialogue tree!")
		get_tree().quit(1)
		return
	var appraise_conds = appraise_choice.get("condition", [])
	var has_fingerless_check := false
	for cond in appraise_conds:
		if cond.get("type") == "has_item" and cond.get("item_id") == "fingerless_gloves":
			has_fingerless_check = true
			break
	if not has_fingerless_check:
		printerr("FAIL 9-C: lu_qichen hub appraise choice is missing fingerless_gloves condition check!")
		get_tree().quit(1)
		return

	# 1. Glove Upgrade Mechanics
	# Case A: fingerless_gloves is in inventory (not equipped)
	GameState.reset_for_new_game()
	GameState.add_item("old_probe_module", 1)
	GameState.add_item("fingerless_gloves", 1)

	# Find fingerless_gloves instance ID
	var gloves_inst_id := ""
	for slot in GameState.get_inventory():
		if not slot.is_empty() and slot.get("item_id") == "fingerless_gloves":
			gloves_inst_id = slot.get("instance_id", "")
			break

	if gloves_inst_id.is_empty():
		printerr("FAIL 9-C: fingerless_gloves not found in inventory!")
		get_tree().quit(1)
		return

	var upgrade_success = GameState.install_probe_module()
	if not upgrade_success:
		printerr("FAIL 9-C: install_probe_module failed when gloves are in inventory!")
		get_tree().quit(1)
		return

	if GameState.has_item("old_probe_module"):
		printerr("FAIL 9-C: old_probe_module should be removed after upgrade!")
		get_tree().quit(1)
		return

	# Verify in-place replacement
	var found_gleaner := false
	for slot in GameState.get_inventory():
		if not slot.is_empty() and slot.get("instance_id") == gloves_inst_id:
			if slot.get("item_id") != "gleaner_gloves":
				printerr("FAIL 9-C: Item ID should be updated to gleaner_gloves!")
				get_tree().quit(1)
				return
			found_gleaner = true
			break
	if not found_gleaner:
		printerr("FAIL 9-C: gleaner_gloves not found with matching instance ID!")
		get_tree().quit(1)
		return

	if not GameState.get_flag("gleaner_gloves_installed", false):
		printerr("FAIL 9-C: gleaner_gloves_installed story flag should be true!")
		get_tree().quit(1)
		return

	# Case B: fingerless_gloves is equipped
	GameState.reset_for_new_game()
	GameState.add_item("old_probe_module", 1)
	GameState.add_item("fingerless_gloves", 1)

	# Find gloves instance ID and equip it
	var gloves_inst_id_b := ""
	for slot in GameState.get_inventory():
		if not slot.is_empty() and slot.get("item_id") == "fingerless_gloves":
			gloves_inst_id_b = slot.get("instance_id", "")
			break

	GameState.equip(gloves_inst_id_b)
	if not GameState.is_equipped(gloves_inst_id_b):
		printerr("FAIL 9-C: failed to equip fingerless_gloves for test case B!")
		get_tree().quit(1)
		return

	var upgrade_success_b = GameState.install_probe_module()
	if not upgrade_success_b:
		printerr("FAIL 9-C: install_probe_module failed when gloves are equipped!")
		get_tree().quit(1)
		return

	if not GameState.is_equipped(gloves_inst_id_b):
		printerr("FAIL 9-C: gleaner_gloves should remain equipped with same instance ID!")
		get_tree().quit(1)
		return

	# Verify in-place replacement in inventory slots
	var found_gleaner_b := false
	for slot in GameState.get_inventory():
		if not slot.is_empty() and slot.get("instance_id") == gloves_inst_id_b:
			if slot.get("item_id") != "gleaner_gloves":
				printerr("FAIL 9-C: Item ID of equipped gloves should be updated to gleaner_gloves!")
				get_tree().quit(1)
				return
			found_gleaner_b = true
			break
	if not found_gleaner_b:
		printerr("FAIL 9-C: equipped gleaner_gloves not found with matching instance ID!")
		get_tree().quit(1)
		return

	# 2. Dialogue Transitions
	# Dialogue A: travel_street_east choice
	var travel_tree = DialogueDB.get_tree_for("travel_street_east")
	if travel_tree.is_empty() or not travel_tree.has("travel_to_shop"):
		printerr("FAIL 9-C: DialogueDB could not fetch travel_street_east tree!")
		get_tree().quit(1)
		return

	var travel_runner = DialogueRunner.new()
	travel_runner.start(travel_tree)
	travel_runner.choose(0) # Choose "前往收藏家的店"

	var travel_payload = travel_runner.pending_travel
	if travel_payload.get("scene_id") != "collector_shop" or travel_payload.get("entry_point_id") != "from_street":
		printerr("FAIL 9-C: pending_travel mismatch! Got: ", travel_payload)
		get_tree().quit(1)
		return

	# Dialogue B: lu_qichen appraisal and install_module effect
	var lu_tree = DialogueDB.get_tree_for("lu_qichen")
	if lu_tree.is_empty() or not lu_tree.has("appraise_gloves"):
		printerr("FAIL 9-C: DialogueDB could not fetch lu_qichen tree!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	GameState.add_item("old_probe_module", 1)
	GameState.add_item("fingerless_gloves", 1)

	var lu_runner = DialogueRunner.new()
	lu_runner.start(lu_tree, "appraise_gloves") # Start at appraise_gloves node
	# Node entry automatically triggers effect "install_module"
	if not GameState.get_flag("gleaner_gloves_installed", false):
		printerr("FAIL 9-C: Dialogue install_module effect did not install glove module!")
		get_tree().quit(1)
		return

	# 3. Scene Load Verification
	print("Loading res://scenes/levels/collector_shop/collector_shop.tscn...")
	var shop_scene = load("res://scenes/levels/collector_shop/collector_shop.tscn")
	if not shop_scene:
		printerr("FAIL 9-C: Could not load collector_shop.tscn!")
		get_tree().quit(1)
		return

	var shop_instance = shop_scene.instantiate()
	if not shop_instance:
		printerr("FAIL 9-C: Could not instantiate collector_shop.tscn!")
		get_tree().quit(1)
		return

	var shop_camera = shop_instance.get_node_or_null("Camera2D")
	if not shop_camera or shop_camera.limit_left != 0 or shop_camera.limit_right != 2560 or shop_camera.limit_top != 0 or shop_camera.limit_bottom != 720:
		printerr("FAIL 9-C: Camera bounds in collector_shop are not 0-2560 x 0-720!")
		get_tree().quit(1)
		return

	var shop_spawn = shop_instance.get_node_or_null("SpawnPoints/from_street")
	if not shop_spawn or shop_spawn.position != Vector2(190, 665):
		printerr("FAIL 9-C: SpawnPoint from_street is wrong or missing!")
		get_tree().quit(1)
		return

	var interactables_parent = shop_instance.get_node_or_null("Interactables")
	if not interactables_parent:
		printerr("FAIL 9-C: Interactables container missing in collector_shop!")
		get_tree().quit(1)
		return

	var lu_area = interactables_parent.get_node_or_null("LuQichenArea")
	if not lu_area or lu_area.dialogue_id != "lu_qichen" or lu_area.prompt_text != "PROMPT_TALK":
		printerr("FAIL 9-C: LuQichenArea interaction properties are incorrect!")
		get_tree().quit(1)
		return

	var lu_sprite = lu_area.get_node_or_null("Sprite2D")
	if not lu_sprite or lu_sprite.texture == null:
		printerr("FAIL 9-C: Lu Qichen NPC sprite is missing or texture is empty!")
		get_tree().quit(1)
		return

	if lu_sprite.position != Vector2(1870.9995, 355):
		printerr("FAIL 9-C: Lu Qichen NPC sprite position should be [1870.9995, 355]! Got: ", lu_sprite.position)
		get_tree().quit(1)
		return

	shop_instance.free()
	print("PASS 9-C: Glove upgrade mechanics, dialogue transitions, and collector shop scene load verified.")

	# ----------------------------------------------------
