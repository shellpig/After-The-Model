extends "res://tests/manual/phases/phase_19a.gd"

func _run_phase_18() -> void:
	# ===================== Phase 18: Act 2B Combat Encounter & Receipt Retrieval =====================
	print("--- Phase 18: Act 2B Combat Encounter & Receipt Retrieval ---")

	# Reset states
	GameState.reset_for_new_game()

	# Load combat scene
	var p18_combat_scene = load("res://scenes/levels/tunnel_combat/tunnel_combat.tscn")
	if p18_combat_scene == null:
		printerr("FAIL 18-A: could not load tunnel_combat.tscn!")
		get_tree().quit(1)
		return
	print("PASS 18-A: tunnel_combat.tscn loaded.")

	p18_arena = p18_combat_scene.instantiate()
	add_child(p18_arena)
	await get_tree().process_frame

	var p18_player = p18_arena.find_child("Player", true, false)
	var p18_walker = p18_arena.find_child("Walker01", true, false)
	var p18_loot_box = p18_arena.find_child("LootBoxArea", true, false)
	var p18_exit = p18_arena.find_child("ExitToSettlementArea", true, false)

	if p18_player == null or p18_walker == null or p18_loot_box == null or p18_exit == null:
		printerr("FAIL 18-A: tunnel_combat scene missing required nodes!")
		get_tree().quit(1)
		return
	print("PASS 18-A: tunnel_combat scene contains all required nodes.")

	# Verify combat mode
	if not p18_player.combat_mode:
		printerr("FAIL 18-A: Player in tunnel_combat must have combat_mode = true!")
		get_tree().quit(1)
		return
	print("PASS 18-A: Player combat_mode is true in combat scene.")

	# Verify E key priority: player mock setup
	# Set player's parent to p18_arena so it can get tree if needed
	if p18_player.get_parent() == null:
		p18_arena.add_child(p18_player)

	# 1. format zone suppresses attack
	var existing_fmt = p18_player.get_node_or_null("FormatReset")
	if existing_fmt:
		p18_player.remove_child(existing_fmt)
		existing_fmt.free()

	# We can mock _in_format_zone returning true by mocking FormatReset node
	var mock_fmt = Node.new()
	mock_fmt.name = "FormatReset"
	var mock_script = GDScript.new()
	mock_script.source_code = "extends Node\nfunc has_target() -> bool: return true"
	mock_script.reload()
	mock_fmt.set_script(mock_script)
	p18_player.add_child(mock_fmt)

	if not p18_player._in_format_zone():
		printerr("FAIL 18-A: mock _in_format_zone failed!")
		get_tree().quit(1)
		return
	if not p18_player._e_reserved():
		printerr("FAIL 18-A: format zone should reserve E key!")
		get_tree().quit(1)
		return
	print("PASS 18-A: format zone correctly reserves E key.")
	mock_fmt.free()

	# Verify flag setting on walker defeat
	if GameState.get_flag("tunnel_machine_defeated", false):
		printerr("FAIL 18-A: tunnel_machine_defeated should start as false!")
		get_tree().quit(1)
		return

	# Call defeated on walker
	p18_walker.defeated()
	# Run process to let polling capture it
	p18_arena._process(0.016)
	if not GameState.get_flag("tunnel_machine_defeated", false):
		printerr("FAIL 18-A: defeated walker did not trigger tunnel_machine_defeated flag!")
		get_tree().quit(1)
		return
	print("PASS 18-A: walker defeat sets tunnel_machine_defeated flag.")

	# Loot box check before and after defeat
	# Let's reset the flag first
	GameState.set_flag("tunnel_machine_defeated", false)

	var p18_sig_tracker = {"msg": "", "toast": ""}
	p18_arena.interaction_requested.connect(func(d):
		if d.get("type") == "message":
			p18_sig_tracker["msg"] = d.get("message_text", "")
		elif d.get("type") == "toast":
			p18_sig_tracker["toast"] = d.get("message_text", "")
	)

	p18_arena.current_interactable = p18_loot_box
	p18_arena._trigger_interaction()
	if not "清潔機還在運運" in p18_sig_tracker["msg"] and not "清潔機還在運轉" in p18_sig_tracker["msg"]:
		printerr("FAIL 18-B: looting before defeat should warn player! Got p18_sig_tracker: ", p18_sig_tracker)
		get_tree().quit(1)
		return
	print("PASS 18-B: looting before defeat is blocked.")

	# Set defeated again
	GameState.set_flag("tunnel_machine_defeated", true)
	p18_sig_tracker["msg"] = ""

	# Backpack full test
	# Fill inventory: Max inventory capacity is 5x3 = 15 slots in GameState.
	for i in range(15):
		GameState.add_item("faded_jacket", 1)

	p18_arena._trigger_interaction()
	if not GameState.has_item("childcare_supply_receipt") and p18_sig_tracker["toast"] == "背包空間不足，無法放入。":
		print("PASS 18-B: looting with full backpack triggers toast and doesn't drop item.")
	else:
		printerr("FAIL 18-B: full backpack should block receipt acquisition! Got p18_sig_tracker: ", p18_sig_tracker)
		get_tree().quit(1)
		return

	# Free inventory slots
	GameState.reset_for_new_game()
	GameState.set_flag("tunnel_machine_defeated", true)
	p18_sig_tracker["toast"] = ""
	p18_sig_tracker["msg"] = ""

	p18_arena._trigger_interaction()
	if not GameState.has_item("childcare_supply_receipt"):
		printerr("FAIL 18-B: looting should award childcare_supply_receipt!")
		get_tree().quit(1)
		return
	if not "獲得了「兒少照護補給回執」" in p18_sig_tracker["msg"]:
		printerr("FAIL 18-B: looting did not show correct message! Got: ", p18_sig_tracker["msg"])
		get_tree().quit(1)
		return
	print("PASS 18-B: looting awards childcare_supply_receipt successfully.")

	# Check description constraints
	var receipt_meta = GameState.ITEMS_DB.get("childcare_supply_receipt", {})
	var r_desc = receipt_meta.get("description", "")
	if "七號" in r_desc or "妹妹" in r_desc or "林霏" in r_desc:
		printerr("FAIL 18-B: childcare_supply_receipt description violates forbidden words rule!")
		get_tree().quit(1)
		return
	print("PASS 18-B: receipt description conforms to narrative constraints.")

	# Verify dialogue branch for selling receipt to Wan
	GameState.reset_for_new_game()
	GameState.add_item("childcare_supply_receipt", 1)
	GameState.set_flag("affinity_wan", 2)
	GameState.add_trace(5)

	var d_runner = DialogueRunner.new()

	# We expect starting node to goto retalk
	GameState.set_flag("met_wan", true)
	var tree = DialogueDB.get_tree_for("wan")
	d_runner.start(tree)

	var p18_curr = d_runner.current()
	var p18_choices = p18_curr.get("choices", [])
	var found_sell_option = false
	for c in p18_choices:
		if "我撿到一張育兒照護回執" in tr(c.get("label", "")):
			found_sell_option = true
			d_runner.choose(c.get("index"))
			break
	if not found_sell_option:
		printerr("FAIL 18-C: sell option not found in retalk choices! Available choices: ", p18_choices)
		get_tree().quit(1)
		return
	print("PASS 18-C: sell option found and chosen under retalk.")

	p18_curr = d_runner.current()
	p18_choices = p18_curr.get("choices", [])
	var found_do_sell = false
	for c in p18_choices:
		if "將回執賣給她" in tr(c.get("label", "")):
			found_do_sell = true
			d_runner.choose(c.get("index"))
			break
	if not found_do_sell:
		printerr("FAIL 18-C: do_sell option not found in sell_receipt node! Available choices: ", p18_choices)
		get_tree().quit(1)
		return

	# Now sell dialogue completes, effects should execute
	if GameState.has_item("childcare_supply_receipt"):
		printerr("FAIL 18-C: receipt should be removed after selling!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 500:
		printerr("FAIL 18-C: credits should be 500 after selling receipt, got: ", GameState.get_credits())
		get_tree().quit(1)
		return
	if GameState.get_trace() != 4:
		printerr("FAIL 18-C: trace should decrease by 1, got: ", GameState.get_trace())
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_wan", 0) != 1:
		printerr("FAIL 18-C: affinity_wan should decrease by 1, got: ", GameState.get_flag("affinity_wan", 0))
		get_tree().quit(1)
		return
	if not GameState.get_flag("peace_line_locked", false):
		printerr("FAIL 18-C: peace_line_locked flag should be set to true after selling!")
		get_tree().quit(1)
		return
	print("PASS 18-C: selling effects executed correctly (credits +200, trace -1, trust -1, peace line locked).")
	d_runner = null

	# Verify Save/Load Round-trip for Phase 18 flags
	GameState.reset_for_new_game()
	GameState.set_flag("tunnel_machine_defeated", true)
	GameState.set_flag("peace_line_locked", true)
	GameState.add_item("childcare_supply_receipt", 1)

	p18_save_dict = SaveSystem.capture("tunnel_combat", 100.0, 1)
	GameState.reset_for_new_game()

	SaveSystem.apply(p18_save_dict)


	if not GameState.get_flag("tunnel_machine_defeated", false):
		printerr("FAIL 18-D: tunnel_machine_defeated flag not restored!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("peace_line_locked", false):
		printerr("FAIL 18-D: peace_line_locked flag not restored!")
		get_tree().quit(1)
		return
	if not GameState.has_item("childcare_supply_receipt"):
		printerr("FAIL 18-D: childcare_supply_receipt possession not restored!")
		get_tree().quit(1)
		return
	print("PASS 18-D: Save/Load round-trip for Phase 18 verified.")

