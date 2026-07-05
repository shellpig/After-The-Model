extends "res://tests/manual/phases/phase_17a.gd"

func _run_phase_14d() -> void:
	# 拆檔補宣告：原為 _ready() 早期區域變數，本段先寫後讀（scratch 重用）
	var curr_node
	# ===================== Phase 14-D: Regression + Save/Load + GUI =====================
	print("--- Phase 14-D: Regression + Save/Load + GUI ---")

	# Test 1: Reset and initial state defaults (default to false if missing, or after reset)
	GameState.reset_for_new_game()
	if GameState.get_flag("mem_frag_linfei_1", false) or GameState.get_flag("lu_hinted_topside", false) or GameState.get_flag("wan_noticed_daze", false) or GameState.get_flag("ada_misrecognized", false):
		printerr("FAIL 14-D: Phase 14 flags not default to false after reset!")
		get_tree().quit(1)
		return

	# Test 2: Set flags to true, capture, apply, check they are preserved
	GameState.set_flag("mem_frag_linfei_1", true)
	GameState.set_flag("lu_hinted_topside", true)
	GameState.set_flag("wan_noticed_daze", true)
	GameState.set_flag("ada_misrecognized", true)

	var save_p14 = SaveSystem.capture("apartment_entrance", 1500.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_p14):
		printerr("FAIL 14-D: SaveSystem.write_slot failed for Phase 14 flags!")
		get_tree().quit(1)
		return

	# Reset state to clear flags
	GameState.reset_for_new_game()
	if GameState.get_flag("mem_frag_linfei_1", false) or GameState.get_flag("lu_hinted_topside", false) or GameState.get_flag("wan_noticed_daze", false) or GameState.get_flag("ada_misrecognized", false):
		printerr("FAIL 14-D: Phase 14 flags not cleared on reset prior to load!")
		get_tree().quit(1)
		return

	# Load and check applied flags
	var loaded_p14 = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	SaveSystem.apply(loaded_p14)

	if not GameState.get_flag("mem_frag_linfei_1", false):
		printerr("FAIL 14-D: mem_frag_linfei_1 not loaded from save!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("lu_hinted_topside", false):
		printerr("FAIL 14-D: lu_hinted_topside not loaded from save!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("wan_noticed_daze", false):
		printerr("FAIL 14-D: wan_noticed_daze not loaded from save!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("ada_misrecognized", false):
		printerr("FAIL 14-D: ada_misrecognized not loaded from save!")
		get_tree().quit(1)
		return

	# Test 3: Backwards compatibility (simulate old save format where keys don't exist)
	var old_save_dict = {
		"meta": {
			"version": 1,
			"timestamp": 1234567,
			"scene_id": "apartment_entrance",
			"credits": 100
		},
		"data": {
			"credits": 100,
			"player_pos_x": 730.0,
			"player_facing": 1,
			"scene_id": "apartment_entrance",
			"inventory": [],
			"equipment": {},
			"knowledge": {},
			"notes": [],
			"containers": {},
			"story_flags": {
				"vendor_bot_repaired": false
			}
		}
	}
	GameState.reset_for_new_game()
	GameState.load_save_dict(old_save_dict.data)
	if GameState.get_flag("mem_frag_linfei_1", false) or GameState.get_flag("lu_hinted_topside", false) or GameState.get_flag("wan_noticed_daze", false) or GameState.get_flag("ada_misrecognized", false):
		printerr("FAIL 14-D: missing keys in save dictionary did not default to false!")
		get_tree().quit(1)
		return

	print("PASS: Phase 14-D regression + save/load verified.")

	# ----------------------------------------------------
	# Phase 15 Verification
	# ----------------------------------------------------
	print("Running Phase 15 map scene tests...")
	var MainClass15 = load("res://scenes/main/main.gd")
	var scenes15: Dictionary = MainClass15.SCENES
	var required_phase15_scenes := ["subway_station", "subway_station_platform", "underground_settlement", "underground_settlement_right"]
	for scene_id in required_phase15_scenes:
		if not scenes15.has(scene_id):
			printerr("FAIL 15: SCENES missing ", scene_id)
			get_tree().quit(1)
			return
	if not scenes15["apartment_entrance"].get("entry_points", []).has("from_subway"):
		printerr("FAIL 15: apartment_entrance missing from_subway entry point!")
		get_tree().quit(1)
		return
	if scenes15["subway_station"].get("entry_points", []) != ["from_street", "from_platform", "epilogue_cen"]:
		printerr("FAIL 15: subway_station entry points wrong: ", scenes15["subway_station"].get("entry_points", []))
		get_tree().quit(1)
		return
	if scenes15["subway_station_platform"].get("entry_points", []) != ["from_concourse", "from_settlement"]:
		printerr("FAIL 15: subway_station_platform entry points wrong: ", scenes15["subway_station_platform"].get("entry_points", []))
		get_tree().quit(1)
		return
	if scenes15["underground_settlement"].get("entry_points", []) != ["from_subway", "from_right", "epilogue_settlement"]:
		printerr("FAIL 15: underground_settlement entry points wrong: ", scenes15["underground_settlement"].get("entry_points", []))
		get_tree().quit(1)
		return
	if not "from_left" in scenes15["underground_settlement_right"].get("entry_points", []):
		printerr("FAIL 15: underground_settlement_right entry points missing from_left: ", scenes15["underground_settlement_right"].get("entry_points", []))
		get_tree().quit(1)
		return
	if SaveSystem.get_scene_display_name("underground_settlement_right") == "未知區域":
		printerr("FAIL 15: SaveSystem scene names missing Phase 15 scenes!")
		get_tree().quit(1)
		return

	var travel_tree15 = DialogueDB.get_tree_for("travel_street_west")
	GameState.reset_for_new_game()
	var travel_runner15_locked = DialogueRunner.new()
	travel_runner15_locked.start(travel_tree15)
	var locked_labels := []
	for choice in travel_runner15_locked.current().get("choices", []):
		locked_labels.append(tr(choice.get("label", "")))
	if locked_labels.has("前往地鐵站"):
		printerr("FAIL 15: subway travel choice should be hidden before lu_hinted_topside!")
		get_tree().quit(1)
		return
	GameState.set_flag("lu_hinted_topside", true)
	var travel_runner15_unlocked = DialogueRunner.new()
	travel_runner15_unlocked.start(travel_tree15)
	var unlocked_labels := []
	for choice in travel_runner15_unlocked.current().get("choices", []):
		unlocked_labels.append(tr(choice.get("label", "")))
	if not unlocked_labels.has("前往地鐵站"):
		printerr("FAIL 15: subway travel choice should appear after lu_hinted_topside!")
		get_tree().quit(1)
		return
	travel_runner15_unlocked.choose(0)
	if travel_runner15_unlocked.pending_travel.get("scene_id", "") != "subway_station" or travel_runner15_unlocked.pending_travel.get("entry_point_id", "") != "from_street":
		printerr("FAIL 15: subway travel payload wrong: ", travel_runner15_unlocked.pending_travel)
		get_tree().quit(1)
		return

	var scene_specs15 := {
		"subway_station": {"path": "res://scenes/levels/subway_station/subway_station.tscn", "right": 1376, "bottom": 768, "spawns": ["from_street", "from_platform"]},
		"subway_station_platform": {"path": "res://scenes/levels/subway_station/subway_station_platform.tscn", "right": 4800, "bottom": 896, "spawns": ["from_concourse", "from_settlement"]},
		"underground_settlement": {"path": "res://scenes/levels/underground_settlement/underground_settlement.tscn", "right": 4352, "bottom": 960, "spawns": ["from_subway", "from_right"]},
		"underground_settlement_right": {"path": "res://scenes/levels/underground_settlement/underground_settlement_right.tscn", "right": 4352, "bottom": 960, "spawns": ["from_left"]}
	}
	for scene_id in scene_specs15:
		var spec: Dictionary = scene_specs15[scene_id]
		var packed15 = load(spec["path"])
		if not packed15:
			printerr("FAIL 15: Could not load ", spec["path"])
			get_tree().quit(1)
			return
		var inst15 = packed15.instantiate()
		var bg15 = inst15.get_node_or_null("Background") as Sprite2D
		if bg15 == null or bg15.texture == null:
			printerr("FAIL 15: Background texture missing in ", scene_id)
			get_tree().quit(1)
			return
		var cam15 = inst15.get_node_or_null("Camera2D") as Camera2D
		if cam15 == null or cam15.limit_right != spec["right"] or cam15.limit_bottom != spec["bottom"]:
			printerr("FAIL 15: Camera bounds wrong in ", scene_id)
			get_tree().quit(1)
			return
		for spawn_id in spec["spawns"]:
			if inst15.get_node_or_null("SpawnPoints/" + spawn_id) == null:
				printerr("FAIL 15: Missing spawn ", spawn_id, " in ", scene_id)
				get_tree().quit(1)
				return
		inst15.free()

	var transition_specs15 := [
		{"path": "res://scenes/levels/subway_station/subway_station.tscn", "area": "Interactables/ExitToStreetArea", "scene": "apartment_entrance", "entry": "from_subway"},
		{"path": "res://scenes/levels/subway_station/subway_station.tscn", "area": "Interactables/GateToPlatformArea", "scene": "subway_station_platform", "entry": "from_concourse"},
		{"path": "res://scenes/levels/subway_station/subway_station_platform.tscn", "area": "Interactables/ExitToStreetArea", "scene": "subway_station", "entry": "from_platform"},
		{"path": "res://scenes/levels/subway_station/subway_station_platform.tscn", "area": "Interactables/StairsToSettlementArea", "scene": "underground_settlement", "entry": "from_subway"},
		{"path": "res://scenes/levels/underground_settlement/underground_settlement.tscn", "area": "Interactables/ExitToSubwayArea", "scene": "subway_station_platform", "entry": "from_settlement"},
		{"path": "res://scenes/levels/underground_settlement/underground_settlement.tscn", "area": "Interactables/GoRightArea", "scene": "underground_settlement_right", "entry": "from_left"},
		{"path": "res://scenes/levels/underground_settlement/underground_settlement_right.tscn", "area": "Interactables/GoLeftArea", "scene": "underground_settlement", "entry": "from_right"}
	]
	for spec in transition_specs15:
		var packed_transition = load(spec["path"])
		var inst_transition = packed_transition.instantiate()
		var captured := {}
		inst_transition.scene_transition_requested.connect(func(scene_id: String, entry_point_id: String, payload: Dictionary):
			captured["scene"] = scene_id
			captured["entry"] = entry_point_id
		)
		inst_transition.current_interactable = inst_transition.get_node(spec["area"])
		inst_transition._trigger_interaction()
		if captured.get("scene", "") != spec["scene"] or captured.get("entry", "") != spec["entry"]:
			printerr("FAIL 15: Transition mismatch for ", spec["area"], ": ", captured)
			get_tree().quit(1)
			return
		inst_transition.free()

	GameState.reset_for_new_game()
	var settlement_scene15 = load("res://scenes/levels/underground_settlement/underground_settlement.tscn")
	var settlement_inst15 = settlement_scene15.instantiate()
	add_child(settlement_inst15)
	await get_tree().process_frame
	if not GameState.get_flag("reached_settlement", false):
		printerr("FAIL 15: entering underground_settlement should set reached_settlement!")
		get_tree().quit(1)
		return
	settlement_inst15.free()
	await get_tree().process_frame

	print("PASS: Phase 15 split-map routing and scene skeleton verified.")

	# ----------------------------------------------------
	# Phase 16 Verification (16-A)
	# ----------------------------------------------------
	print("Running Phase 16 NPC dialogue verification (16-A Cen)...")
	var cen_tree = DialogueDB.get_tree_for("cen")
	if cen_tree.is_empty():
		printerr("FAIL 16: Dialogue tree 'cen' not found or empty!")
		get_tree().quit(1)
		return

	for node_name in cen_tree:
		var node = cen_tree[node_name]
		var text = node.get("text", "")
		if "林" + "霏" in text:
			printerr("FAIL 16: 'cen' tree node '", node_name, "' contains forbidden string!")
			get_tree().quit(1)
			return

	GameState.reset_for_new_game()
	var runner_cen := DialogueRunner.new()
	runner_cen.start(cen_tree)

	curr_node = runner_cen.current()
	if tr(curr_node.get("speaker", "")) != "小岑" or not "新來的？" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: Initial routing should go to first_meet! Got: ", curr_node)
		get_tree().quit(1)
		return

	runner_cen.choose(0) # goto intro
	curr_node = runner_cen.current()
	if not "叫我小岑" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: Choice 0 should route to intro! Got: ", curr_node)
		get_tree().quit(1)
		return

	if not GameState.get_flag("met_cen", false) or GameState.get_flag("affinity_cen", 0) != 1:
		printerr("FAIL 16: intro effects failed! met_cen: ", GameState.get_flag("met_cen", false), " affinity_cen: ", GameState.get_flag("affinity_cen", 0))
		get_tree().quit(1)
		return

	runner_cen.advance()
	curr_node = runner_cen.current()
	if not "真撿到吃的" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: intro should goto end_warm! Got: ", curr_node)
		get_tree().quit(1)
		return

	# Path B: pickpocket_caught
	GameState.reset_for_new_game()
	runner_cen = DialogueRunner.new()
	runner_cen.start(cen_tree)
	runner_cen.choose(2) # Option 2
	curr_node = runner_cen.current()
	if not "手快一點才不會餓死" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: Choice 2 should route to pickpocket_caught! Got: ", curr_node)
		get_tree().quit(1)
		return
	if not GameState.get_flag("met_cen", false):
		printerr("FAIL 16: pickpocket_caught should set met_cen = true!")
		get_tree().quit(1)
		return

	# Path C: retalk
	runner_cen = DialogueRunner.new()
	runner_cen.start(cen_tree)
	curr_node = runner_cen.current()
	if not "又是你。" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: routing with met_cen=true should go to retalk! Got: ", curr_node)
		get_tree().quit(1)
		return

	var prev_affinity = GameState.get_flag("affinity_cen", 0)
	runner_cen.choose(0) # 來看看你
	curr_node = runner_cen.current()
	if not "真撿到吃的" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: retalk choice 0 should route to end_warm! Got: ", curr_node)
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_cen", 0) != prev_affinity + 1:
		printerr("FAIL 16: retalk choice 0 should increase affinity_cen! Got: ", GameState.get_flag("affinity_cen", 0))
		get_tree().quit(1)
		return

	# Assert cen portrait path is wired
	var dp_scene = load("res://scenes/ui/dialogue_panel.tscn")
	if dp_scene:
		var dp_inst = dp_scene.instantiate()
		add_child(dp_inst)
		dp_inst.start_dialogue("cen")
		if dp_inst.portrait_rect.texture == null:
			printerr("FAIL 16: cen dialogue portrait texture is null!")
			get_tree().quit(1)
			return
		dp_inst.free()

	# Verify NpcCen node setup in underground_settlement.tscn
	var settlement_scene16 = load("res://scenes/levels/underground_settlement/underground_settlement.tscn")
	var settlement_inst16 = settlement_scene16.instantiate()
	var npc_cen = settlement_inst16.get_node_or_null("Interactables/NpcCen")
	if npc_cen == null:
		printerr("FAIL 16: Interactables/NpcCen node missing in underground_settlement.tscn!")
		get_tree().quit(1)
		return
	if npc_cen.interaction_id != "talk_cen" or npc_cen.dialogue_id != "cen":
		printerr("FAIL 16: NpcCen node properties wrong! ID: ", npc_cen.interaction_id, " Dialogue: ", npc_cen.dialogue_id)
		get_tree().quit(1)
		return

	if npc_cen.get_node_or_null("CollisionShape2D") == null:
		printerr("FAIL 16: NpcCen missing CollisionShape2D!")
		get_tree().quit(1)
		return
	var npc_sprite = npc_cen.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if npc_sprite == null or npc_sprite.sprite_frames == null or not npc_sprite.sprite_frames.has_animation("idle"):
		printerr("FAIL 16: NpcCen missing AnimatedSprite2D or idle animation!")
		get_tree().quit(1)
		return
	settlement_inst16.free()

	print("PASS: Phase 16 NPC dialogue verification (16-A Cen) verified.")

	# ----------------------------------------------------
	# Phase 16 Verification (16-B Wu)
	# ----------------------------------------------------
	print("Running Phase 16 NPC dialogue verification (16-B Wu)...")
	var wu_tree = DialogueDB.get_tree_for("wu")
	if wu_tree.is_empty():
		printerr("FAIL 16: Dialogue tree 'wu' not found or empty!")
		get_tree().quit(1)
		return

	for node_name in wu_tree:
		var node = wu_tree[node_name]
		var text = node.get("text", "")
		if "林" + "霏" in text:
			printerr("FAIL 16: 'wu' tree node '", node_name, "' contains forbidden string!")
			get_tree().quit(1)
			return

	# Path A: first_meet -> repairer
	GameState.reset_for_new_game()
	var runner_wu := DialogueRunner.new()
	runner_wu.start(wu_tree)

	curr_node = runner_wu.current()
	if tr(curr_node.get("speaker", "")) != "伍姐" or not "別站光裡" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: Wu initial routing should go to first_meet! Got: ", curr_node)
		get_tree().quit(1)
		return

	runner_wu.choose(0) # goto repairer
	curr_node = runner_wu.current()
	if not "電力、淨水" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: Choice 0 should route to repairer! Got: ", curr_node)
		get_tree().quit(1)
		return

	if not GameState.get_flag("met_wu", false) or GameState.get_flag("affinity_wu", 0) != 1:
		printerr("FAIL 16: repairer effects failed! met_wu: ", GameState.get_flag("met_wu", false), " affinity_wu: ", GameState.get_flag("affinity_wu", 0))
		get_tree().quit(1)
		return

	runner_wu.advance()
	curr_node = runner_wu.current()
	if not "多搬兩趟水" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: repairer should goto end_cold! Got: ", curr_node)
		get_tree().quit(1)
		return

	# Path B: first_meet -> maker
	GameState.reset_for_new_game()
	runner_wu = DialogueRunner.new()
	runner_wu.start(wu_tree)
	runner_wu.choose(1) # Choice 1 (maker)
	curr_node = runner_wu.current()
	if not "有過一個人" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: Choice 1 should route to maker! Got: ", curr_node)
		get_tree().quit(1)
		return
	if not GameState.get_flag("met_wu", false) or not GameState.get_flag("knows_settlement_had_maker", false):
		printerr("FAIL 16: maker flags failed to set! met_wu: ", GameState.get_flag("met_wu", false), " knows_settlement_had_maker: ", GameState.get_flag("knows_settlement_had_maker", false))
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_wu", 0) != 1:
		printerr("FAIL 16: maker should increase affinity_wu! Got: ", GameState.get_flag("affinity_wu", 0))
		get_tree().quit(1)
		return

	runner_wu.advance()
	curr_node = runner_wu.current()
	if not "多搬兩趟水" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: maker should goto end_cold! Got: ", curr_node)
		get_tree().quit(1)
		return

	# Path C: retalk with knows_settlement_had_maker = false
	GameState.reset_for_new_game()
	GameState.set_flag("met_wu", true)
	runner_wu = DialogueRunner.new()
	runner_wu.start(wu_tree)
	curr_node = runner_wu.current()
	if not "來了。手別閒著" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: routing with met_wu=true should go to retalk! Got: ", curr_node)
		get_tree().quit(1)
		return
	var choices_no_maker = curr_node.get("choices", [])
	var has_ask_maker_more := false
	for choice in choices_no_maker:
		if "建立這裡的人" in tr(choice.get("label", "")):
			has_ask_maker_more = true
	if has_ask_maker_more:
		printerr("FAIL 16: ask_maker_more should be locked if knows_settlement_had_maker is false!")
		get_tree().quit(1)
		return

	# Path D: retalk with knows_settlement_had_maker = true
	GameState.reset_for_new_game()
	GameState.set_flag("met_wu", true)
	GameState.set_flag("knows_settlement_had_maker", true)
	runner_wu = DialogueRunner.new()
	runner_wu.start(wu_tree)
	curr_node = runner_wu.current()
	var choices_with_maker = curr_node.get("choices", [])
	var ask_maker_index := -1
	for idx in range(choices_with_maker.size()):
		if "建立這裡的人" in tr(choices_with_maker[idx].get("label", "")):
			ask_maker_index = idx
	if ask_maker_index == -1:
		printerr("FAIL 16: ask_maker_more option missing from retalk with knows_settlement_had_maker=true!")
		get_tree().quit(1)
		return

	# Choose ask_maker_more
	runner_wu.choose(ask_maker_index)
	curr_node = runner_wu.current()
	if not "自己把自己關掉的" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: ask_maker_more choice should route to ask_maker_more node! Got: ", curr_node)
		get_tree().quit(1)
		return

	# Assert wu portrait path is wired
	if dp_scene:
		var dp_inst = dp_scene.instantiate()
		add_child(dp_inst)
		dp_inst.start_dialogue("wu")
		if dp_inst.portrait_rect.texture == null:
			printerr("FAIL 16: wu dialogue portrait texture is null!")
			get_tree().quit(1)
			return
		dp_inst.free()

	# Verify NpcWu node setup in underground_settlement_right.tscn
	var settlement_right_scene16 = load("res://scenes/levels/underground_settlement/underground_settlement_right.tscn")
	var settlement_right_inst16 = settlement_right_scene16.instantiate()
	var npc_wu = settlement_right_inst16.get_node_or_null("Interactables/NpcWu")
	if npc_wu == null:
		printerr("FAIL 16: Interactables/NpcWu node missing in underground_settlement_right.tscn!")
		get_tree().quit(1)
		return
	if npc_wu.interaction_id != "talk_wu" or npc_wu.dialogue_id != "wu":
		printerr("FAIL 16: NpcWu node properties wrong! ID: ", npc_wu.interaction_id, " Dialogue: ", npc_wu.dialogue_id)
		get_tree().quit(1)
		return

	if npc_wu.get_node_or_null("CollisionShape2D") == null:
		printerr("FAIL 16: NpcWu missing CollisionShape2D!")
		get_tree().quit(1)
		return
	var npc_wu_sprite = npc_wu.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if npc_wu_sprite == null or npc_wu_sprite.sprite_frames == null or not npc_wu_sprite.sprite_frames.has_animation("idle"):
		printerr("FAIL 16: NpcWu missing AnimatedSprite2D or idle animation!")
		get_tree().quit(1)
		return
	settlement_right_inst16.free()

	print("PASS: Phase 16 NPC dialogue verification (16-B Wu) verified.")

	# ----------------------------------------------------
	# Phase 16 Verification (16-C Seven)
	# ----------------------------------------------------
	print("Running Phase 16 NPC dialogue verification (16-C Seven)...")
	var seven_tree = DialogueDB.get_tree_for("seven")
	if seven_tree.is_empty():
		printerr("FAIL 16: Dialogue tree 'seven' not found or empty!")
		get_tree().quit(1)
		return

	for node_name in seven_tree:
		var node = seven_tree[node_name]
		var text = node.get("text", "")
		if "林" + "霏" in text:
			printerr("FAIL 16: 'seven' tree node '", node_name, "' contains forbidden string!")
			get_tree().quit(1)
			return

	# Path A: first_meet -> ask_who -> hook -> end_cold
	GameState.reset_for_new_game()
	var runner_seven := DialogueRunner.new()
	runner_seven.start(seven_tree)

	curr_node = runner_seven.current()
	if tr(curr_node.get("speaker", "")) != "七號" or not "躲下來的" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: Seven initial routing should go to first_meet! Got: ", curr_node)
		get_tree().quit(1)
		return

	runner_seven.choose(0) # goto ask_who
	curr_node = runner_seven.current()
	if not "大家叫我七號" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: Choice 0 should route to ask_who! Got: ", curr_node)
		get_tree().quit(1)
		return

	runner_seven.advance() # goto hook
	curr_node = runner_seven.current()
	if not "我有一個名字" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: ask_who should goto hook! Got: ", curr_node)
		get_tree().quit(1)
		return

	if not GameState.get_flag("met_seven", false) or not GameState.get_flag("seven_hinted_name_topside", false):
		printerr("FAIL 16: hook effects failed! met_seven: ", GameState.get_flag("met_seven", false), " seven_hinted_name_topside: ", GameState.get_flag("seven_hinted_name_topside", false))
		get_tree().quit(1)
		return

	runner_seven.advance() # goto end_cold
	curr_node = runner_seven.current()
	if not "目光沉進更深" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: hook should goto end_cold! Got: ", curr_node)
		get_tree().quit(1)
		return

	# Path B: first_meet -> hook -> end_cold
	GameState.reset_for_new_game()
	runner_seven = DialogueRunner.new()
	runner_seven.start(seven_tree)
	runner_seven.choose(1) # Choice 1 (hook)
	curr_node = runner_seven.current()
	if not "我有一個名字" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: Choice 1 should route to hook! Got: ", curr_node)
		get_tree().quit(1)
		return

	# Path C: retalk with seven_hinted_name_topside = false
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	runner_seven = DialogueRunner.new()
	runner_seven.start(seven_tree)
	curr_node = runner_seven.current()
	if not "還是你。……我說過" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: routing with met_seven=true should go to retalk! Got: ", curr_node)
		get_tree().quit(1)
		return
	var choices_no_name = curr_node.get("choices", [])
	var has_ask_name := false
	for choice in choices_no_name:
		if "掛在上面的名字" in tr(choice.get("label", "")):
			has_ask_name = true
	if has_ask_name:
		printerr("FAIL 16: ask_name should be locked if seven_hinted_name_topside is false!")
		get_tree().quit(1)
		return

	# Path D: retalk with seven_hinted_name_topside = true
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	GameState.set_flag("seven_hinted_name_topside", true)
	runner_seven = DialogueRunner.new()
	runner_seven.start(seven_tree)
	curr_node = runner_seven.current()
	var choices_with_name = curr_node.get("choices", [])
	var ask_name_index := -1
	for idx in range(choices_with_name.size()):
		if "掛在上面的名字" in tr(choices_with_name[idx].get("label", "")):
			ask_name_index = idx
	if ask_name_index == -1:
		printerr("FAIL 16: ask_name option missing from retalk with seven_hinted_name_topside=true!")
		get_tree().quit(1)
		return

	# Choose ask_name
	runner_seven.choose(ask_name_index)
	curr_node = runner_seven.current()
	if not "非找回不可的人" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: ask_name choice should route to ask_name node! Got: ", curr_node)
		get_tree().quit(1)
		return

	# Assert seven portrait path is wired
	if dp_scene:
		var dp_inst = dp_scene.instantiate()
		add_child(dp_inst)
		dp_inst.start_dialogue("seven")
		if dp_inst.portrait_rect.texture == null:
			printerr("FAIL 16: seven dialogue portrait texture is null!")
			get_tree().quit(1)
			return
		dp_inst.free()

	# Verify NpcSeven node setup in underground_settlement_right.tscn
	var settlement_right_inst16_seven = settlement_right_scene16.instantiate()
	var npc_seven = settlement_right_inst16_seven.get_node_or_null("Interactables/NpcSeven")
	if npc_seven == null:
		printerr("FAIL 16: Interactables/NpcSeven node missing in underground_settlement_right.tscn!")
		get_tree().quit(1)
		return
	if npc_seven.interaction_id != "talk_seven" or npc_seven.dialogue_id != "seven":
		printerr("FAIL 16: NpcSeven node properties wrong! ID: ", npc_seven.interaction_id, " Dialogue: ", npc_seven.dialogue_id)
		get_tree().quit(1)
		return

	if npc_seven.get_node_or_null("CollisionShape2D") == null:
		printerr("FAIL 16: NpcSeven missing CollisionShape2D!")
		get_tree().quit(1)
		return
	var npc_seven_sprite = npc_seven.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if npc_seven_sprite == null or npc_seven_sprite.sprite_frames == null or not npc_seven_sprite.sprite_frames.has_animation("idle"):
		printerr("FAIL 16: NpcSeven missing AnimatedSprite2D or idle animation!")
		get_tree().quit(1)
		return
	settlement_right_inst16_seven.free()

	print("PASS: Phase 16 NPC dialogue verification (16-C Seven) verified.")

	# ----------------------------------------------------
	# Phase 16 Verification (16-D)
	# ----------------------------------------------------
	print("Running Phase 16 NPC dialogue verification (16-D)...")

	# Set 8 flags to unique values
	GameState.set_flag("met_cen", true)
	GameState.set_flag("met_wu", true)
	GameState.set_flag("met_seven", true)
	GameState.set_flag("knows_settlement_had_maker", true)
	GameState.set_flag("seven_hinted_name_topside", true)
	GameState.set_flag("affinity_cen", 3)
	GameState.set_flag("affinity_wu", 4)
	GameState.set_flag("affinity_seven", 5)

	# Verify flag values in GameState
	if not GameState.get_flag("met_cen", false) or not GameState.get_flag("met_wu", false) or not GameState.get_flag("met_seven", false):
		printerr("FAIL 16-D: met_* flags not correctly set in GameState!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("knows_settlement_had_maker", false) or not GameState.get_flag("seven_hinted_name_topside", false):
		printerr("FAIL 16-D: knows_settlement_had_maker or seven_hinted_name_topside not correctly set!")
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_cen", 0) != 3 or GameState.get_flag("affinity_wu", 0) != 4 or GameState.get_flag("affinity_seven", 0) != 5:
		printerr("FAIL 16-D: affinity_* flags not correctly set in GameState!")
		get_tree().quit(1)
		return

	# Capture save state to scratch slot
	var save_data_16d = SaveSystem.capture("underground_settlement", 100.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_data_16d):
		printerr("FAIL 16-D: Failed to write Phase 16 save to scratch slot!")
		get_tree().quit(1)
		return

	# Reset game state
	GameState.reset_for_new_game()

	# Verify flags are reset
	if GameState.get_flag("met_cen", false) or GameState.get_flag("met_wu", false) or GameState.get_flag("met_seven", false):
		printerr("FAIL 16-D: met_* flags not reset!")
		get_tree().quit(1)
		return
	if GameState.get_flag("knows_settlement_had_maker", false) or GameState.get_flag("seven_hinted_name_topside", false):
		printerr("FAIL 16-D: knows_settlement_had_maker or seven_hinted_name_topside not reset!")
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_cen", 0) != 0 or GameState.get_flag("affinity_wu", 0) != 0 or GameState.get_flag("affinity_seven", 0) != 0:
		printerr("FAIL 16-D: affinity_* flags not reset!")
		get_tree().quit(1)
		return

	# Read scratch slot
	var read_data_16d = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	if read_data_16d.is_empty():
		printerr("FAIL 16-D: Failed to read save from scratch slot!")
		get_tree().quit(1)
		return

	# Apply state
	SaveSystem.apply(read_data_16d)

	# Verify flags are restored
	if not GameState.get_flag("met_cen", false) or not GameState.get_flag("met_wu", false) or not GameState.get_flag("met_seven", false):
		printerr("FAIL 16-D: met_* flags not restored after load!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("knows_settlement_had_maker", false) or not GameState.get_flag("seven_hinted_name_topside", false):
		printerr("FAIL 16-D: knows_settlement_had_maker or seven_hinted_name_topside not restored after load!")
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_cen", 0) != 3 or GameState.get_flag("affinity_wu", 0) != 4 or GameState.get_flag("affinity_seven", 0) != 5:
		printerr("FAIL 16-D: affinity_* flags not restored after load!")
		get_tree().quit(1)
		return

	# Test default fallback value (missing keys)
	GameState.reset_for_new_game()
	if GameState.get_flag("met_cen", false) != false:
		printerr("FAIL 16-D: met_cen default value should be false!")
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_cen", 0) != 0:
		printerr("FAIL 16-D: affinity_cen default value should be 0!")
		get_tree().quit(1)
		return

	print("PASS: Phase 16 NPC dialogue verification (16-D) verified.")

