extends Node

var _temp_callable: Callable

func _ready() -> void:
	print("==================================================")
	print("RUNNING INTEGRATION VERIFICATION FOR UI MODE & BACKPACK")
	print("==================================================")

	# 1. Verify Autoload Configuration
	print("Checking UIMode autoload...")
	var autoload_exists = ProjectSettings.has_setting("autoload/UIMode")
	if not autoload_exists:
		printerr("FAIL: UIMode not found in ProjectSettings autoload!")
		get_tree().quit(1)
		return
	print("PASS: UIMode registered in autoload.")

	# 2. Verify InputMap Actions
	print("Checking InputMap actions...")
	var actions = ["open_inventory", "open_notebook", "ui_cancel",
	               "ui_page_up", "ui_page_down",
	               "move_left", "move_right", "move_up", "move_down"]
	for action in actions:
		if not InputMap.has_action(action):
			printerr("FAIL: InputMap action '" + action + "' is missing!")
			get_tree().quit(1)
			return
		print("PASS: InputMap action '" + action + "' exists.")


	# 3. Load & Instantiate apartment_room.tscn
	print("Loading res://scenes/levels/apartment/apartment_room.tscn...")
	var room_scene = load("res://scenes/levels/apartment/apartment_room.tscn")
	if not room_scene:
		printerr("FAIL: Could not load apartment_room.tscn!")
		get_tree().quit(1)
		return
	print("PASS: apartment_room.tscn loaded successfully.")

	var room_instance = room_scene.instantiate()

	# Instantiate GameUI so that apartment_room.gd can retrieve its UI references
	var ui_scene = load("res://scenes/ui/game_ui.tscn")
	var ui_instance = ui_scene.instantiate()
	add_child(ui_instance)
	print("PASS: game_ui.tscn instantiated in scene tree.")

	add_child(room_instance)
	print("PASS: apartment_room.tscn instantiated in scene tree.")

	# 4. Verify Relative Node Paths
	print("Verifying UI node structures inside GameUI...")
	var ui_nodes = {
		"UIOverlay": "UIOverlay",
		"NotebookPanel": "NotebookPanel",
		"DualPaneContainer": "DualPaneContainer",
		"InventoryPanel": "InventoryPanel",
		"BagGrid": "InventoryPanel/VBoxContainer/BagGrid",
		"CreditsLabel": "InventoryPanel/VBoxContainer/HBoxContainer/CreditsLabel",
		"PanelFooterHint": "InventoryPanel/VBoxContainer/PanelFooterHint",
		"ItemDetailModal": "ItemDetailModal",
		"ConfirmDialog": "ConfirmDialog"
	}

	for node_name in ui_nodes:
		var path: String = ui_nodes[node_name]
		var node = ui_instance.get_node_or_null(path)
		if not node:
			printerr("FAIL: UI node '" + node_name + "' not found at path: " + path)
			get_tree().quit(1)
			return
		print("PASS: Node '" + node_name + "' exists at '" + path + "'.")

		# Extra properties verification
		if node_name == "UIOverlay":
			var overlay = node as ColorRect
			if overlay.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				printerr("FAIL: UIOverlay mouse_filter is not MOUSE_FILTER_IGNORE!")
				get_tree().quit(1)
				return
			print("PASS: UIOverlay mouse_filter set to IGNORE.")
		elif node_name == "NotebookPanel":
			var panel = node as Control
			if panel.custom_minimum_size != Vector2(880, 560):
				printerr("FAIL: NotebookPanel custom_minimum_size is not 880x560! Got: ", panel.custom_minimum_size)
				get_tree().quit(1)
				return
			print("PASS: NotebookPanel custom minimum size is 880x560.")
		elif node_name == "InventoryPanel":
			var panel = node as PanelContainer
			if panel.custom_minimum_size != Vector2(368, 256):
				printerr("FAIL: InventoryPanel custom_minimum_size is not 368x256! Got: ", panel.custom_minimum_size)
				get_tree().quit(1)
				return
			print("PASS: InventoryPanel custom minimum size is 368x256.")

	# 4b. Verify Story Preloads (Relaxed Contains Checks)
	print("Verifying preloaded story notes (relaxed)...")
	var categories_to_check = {
		"身份": "identity_apartment_is_mine",
		"線索": "clue_door_sensor_scratch"
	}
	for cat in categories_to_check:
		var expected_id: String = categories_to_check[cat]
		var notes = GameState.get_notes(cat)
		var found = false
		for note in notes:
			if note.get("id") == expected_id:
				found = true
				break
		if not found:
			printerr("FAIL: Story note with ID '" + expected_id + "' was not preloaded in category '" + cat + "'!")
			get_tree().quit(1)
			return
		print("PASS: Story note '" + expected_id + "' preloaded.")

	# Verify work_ai_cleanup_role is NOT preloaded in Phase 2
	if GameState.has_note("work_ai_cleanup_role"):
		printerr("FAIL: Story note work_ai_cleanup_role is preloaded, but it must NOT be preloaded!")
		get_tree().quit(1)
		return
	print("PASS: Story note work_ai_cleanup_role is NOT preloaded.")

	# Verify door unlock method is NOT preloaded
	if GameState.has_knowledge("identity_door_unlock_method"):
		printerr("FAIL: Door unlock method identity_door_unlock_method is preloaded, but it must NOT be preloaded!")
		get_tree().quit(1)
		return
	print("PASS: Door unlock method is NOT preloaded.")

	# Verify Phase 1-D container seeding
	print("Verifying Phase 1-D container seeding...")

	var cabinet_slots = GameState.get_container("cabinet_storage")
	if cabinet_slots.size() != 30:
		printerr("FAIL: cabinet_storage should have 30 slots, got %d" % cabinet_slots.size())
		get_tree().quit(1)
		return
	print("PASS: cabinet_storage has 30 slots.")

	var fridge_slots = GameState.get_container("fridge_storage")
	if fridge_slots.size() != 10:
		printerr("FAIL: fridge_storage should have 10 slots, got %d" % fridge_slots.size())
		get_tree().quit(1)
		return
	print("PASS: fridge_storage has 10 slots.")

	# After scene _ready, cabinet should contain faded_jacket + 2 canned_food, fridge should contain 3 canned_food
	var found_jacket := false
	for slot in cabinet_slots:
		if not slot.is_empty() and slot.get("item_id") == "faded_jacket":
			found_jacket = true
			break
	if not found_jacket:
		printerr("FAIL: faded_jacket not seeded into cabinet_storage")
		get_tree().quit(1)
		return
	print("PASS: faded_jacket seeded into cabinet_storage.")


	# 4c. Verify UI Sibling Drawing Z-Order
	print("Verifying UI sibling drawing Z-Order...")
	var children = ui_instance.get_children()
	var overlay_idx = children.find(ui_instance.get_node("UIOverlay"))
	var notebook_idx = children.find(ui_instance.get_node("NotebookPanel"))
	var dual_pane_idx = children.find(ui_instance.get_node("DualPaneContainer"))
	var inventory_idx = children.find(ui_instance.get_node("InventoryPanel"))
	var modal_idx = children.find(ui_instance.get_node_or_null("ItemDetailModal"))
	var confirm_idx = children.find(ui_instance.get_node_or_null("ConfirmDialog"))
	if overlay_idx == -1 or notebook_idx == -1 or dual_pane_idx == -1 or inventory_idx == -1 or modal_idx == -1 or confirm_idx == -1:
		printerr("FAIL: Sibling nodes not found in UI children list!")
		get_tree().quit(1)
		return
	if not (overlay_idx < notebook_idx and notebook_idx < dual_pane_idx and dual_pane_idx < inventory_idx
			and inventory_idx < modal_idx and modal_idx < confirm_idx):
		printerr("FAIL: UI sibling Z-order is wrong! Expected overlay < notebook < dual_pane < inventory < modal < confirm.")
		get_tree().quit(1)
		return
	print("PASS: UI sibling Z-order correct (Overlay -> Notebook -> DualPane -> Inventory -> Modal -> Confirm).")


	# 5. Verify ITEMS_DB icon paths on disk
	print("Verifying ITEMS_DB icon paths...")
	var items = GameState.ITEMS_DB
	for item_id in items:
		var meta: Dictionary = items[item_id]
		var icon_path: String = meta.get("icon_path", "")
		if icon_path.is_empty():
			printerr("FAIL: Item '" + item_id + "' is missing icon_path!")
			get_tree().quit(1)
			return

		var file_exists = FileAccess.file_exists(icon_path)
		if not file_exists:
			printerr("FAIL: Icon file for '" + item_id + "' does not exist at path: " + icon_path)
			get_tree().quit(1)
			return
		print("PASS: Icon file for '" + item_id + "' exists at '" + icon_path + "'.")

	# 6. Verify UIMode clean APIs
	print("Verifying UIMode API presence...")
	if not UIMode.has_method("get_mode") or not UIMode.has_method("set_mode") or not UIMode.has_method("is_world_input_blocked"):
		printerr("FAIL: UIMode lacks get_mode, set_mode, or is_world_input_blocked API!")
		get_tree().quit(1)
		return
	print("PASS: UIMode APIs verified.")

	# 7. Verify UIMode Phase 1-E CONFIRM APIs
	print("Verifying UIMode CONFIRM APIs (Phase 1-E)...")
	if not UIMode.has_method("enter_confirm") or not UIMode.has_method("exit_confirm"):
		printerr("FAIL: UIMode lacks enter_confirm / exit_confirm!")
		get_tree().quit(1)
		return
	print("PASS: UIMode CONFIRM APIs verified.")

	# 8. Verify GameState Phase 1-E APIs
	print("Verifying GameState Phase 1-E APIs...")
	if not GameState.has_method("unequip_by_instance") or not GameState.has_method("discard_item"):
		printerr("FAIL: GameState lacks unequip_by_instance / discard_item!")
		get_tree().quit(1)
		return
	print("PASS: GameState Phase 1-E APIs verified.")

	# 9. Verify TouchControls Autoload & Platform Detection (Phase 3-C)
	print("Verifying TouchControls Autoload & Platform Detection...")
	var touch_controls = get_node_or_null("/root/TouchControls")
	if not touch_controls:
		printerr("FAIL: TouchControls autoload not found at /root/TouchControls!")
		get_tree().quit(1)
		return

	# Since this test runs on Windows (PC), is_pc_platform must be true
	if not touch_controls.is_pc_platform:
		printerr("FAIL: TouchControls.is_pc_platform should be true on Windows PC!")
		get_tree().quit(1)
		return
	print("PASS: TouchControls.is_pc_platform is true on Windows PC.")

	# On PC, touch buttons should be disabled by default
	if touch_controls.touch_buttons_enabled:
		printerr("FAIL: TouchControls.touch_buttons_enabled should be false by default on PC!")
		get_tree().quit(1)
		return
	print("PASS: TouchControls.touch_buttons_enabled is false by default on PC.")

	# On PC, BtnToggle should be visible by default in NONE mode
	ui_instance.set_monologue_active(false)
	UIMode.set_mode(UIMode.Mode.NONE)
	touch_controls._update_dynamic_button_visibility()
	var btn_toggle = touch_controls.get_node_or_null("Control/BtnToggle")
	if not btn_toggle:
		printerr("FAIL: Control/BtnToggle node not found in TouchControls!")
		get_tree().quit(1)
		return
	if not btn_toggle.visible:
		printerr("FAIL: BtnToggle should be visible by default on PC in world mode!")
		get_tree().quit(1)
		return
	print("PASS: TouchControls BtnToggle visibility and default state verified.")

	# 9.1 Verify TouchControls Safe Area Dynamic Fitting
	print("Verifying TouchControls Safe Area dynamic adaptation...")
	var control_node = touch_controls.get_node_or_null("Control")
	if not control_node:
		printerr("FAIL: TouchControls/Control node not found!")
		get_tree().quit(1)
		return

	# Since this test runs on Windows (PC), offsets must be strictly 0
	if control_node.offset_left != 0 or control_node.offset_top != 0 or control_node.offset_right != 0 or control_node.offset_bottom != 0:
		printerr("FAIL: TouchControls/Control offsets must be strictly 0 on PC desktop platform!")
		printerr("Actual offsets: Left=%d, Top=%d, Right=%d, Bottom=%d" % [control_node.offset_left, control_node.offset_top, control_node.offset_right, control_node.offset_bottom])
		get_tree().quit(1)
		return
	print("PASS: TouchControls Safe Area dynamic offsets validated (strictly 0 on PC desktop).")

	# 10. Verify Phase 4-A Main Scene, SceneRouter & SceneRegistry
	print("Verifying Phase 4-A Main Scene configuration...")
	var main_scene_setting = ProjectSettings.get_setting("application/run/main_scene")
	if main_scene_setting != "res://scenes/ui/title_screen.tscn":
		printerr("FAIL: Main scene setting in project.godot is not 'res://scenes/ui/title_screen.tscn'! Got: ", main_scene_setting)
		get_tree().quit(1)
		return
	print("PASS: project.godot configured to use res://scenes/ui/title_screen.tscn.")

	print("Loading res://scenes/main/main.tscn...")
	var main_scene = load("res://scenes/main/main.tscn")
	if not main_scene:
		printerr("FAIL: Could not load main.tscn!")
		get_tree().quit(1)
		return
	print("PASS: main.tscn loaded successfully.")

	var main_instance = main_scene.instantiate()
	add_child(main_instance)
	print("PASS: main.tscn instantiated in scene tree.")

	print("Verifying Main scene hierarchy...")
	var world_root_node = main_instance.get_node_or_null("WorldRoot")
	if not world_root_node:
		printerr("FAIL: WorldRoot node not found in Main scene!")
		get_tree().quit(1)
		return
	print("PASS: WorldRoot node exists in Main.")

	print("Verifying SceneRouter APIs on Main...")
	var required_methods = [
		"transition_to", "reload_current_scene",
		"get_current_scene_id", "get_current_entry_point_id"
	]
	for method in required_methods:
		if not main_instance.has_method(method):
			printerr("FAIL: Main script lacks required SceneRouter method: " + method)
			get_tree().quit(1)
			return
		print("PASS: Main script has method: " + method)

	print("Verifying SceneRegistry config on Main...")
	if not "SCENES" in main_instance:
		printerr("FAIL: SCENES registry dictionary not found in main.gd!")
		get_tree().quit(1)
		return
	var scenes_dict = main_instance.get("SCENES")
	if not scenes_dict.has("apartment") or not scenes_dict.has("apartment_entrance"):
		printerr("FAIL: SCENES registry is missing 'apartment' or 'apartment_entrance' keys!")
		get_tree().quit(1)
		return

	var apartment_config = scenes_dict["apartment"]
	if apartment_config.get("path") != "res://scenes/levels/apartment/apartment_room.tscn":
		printerr("FAIL: apartment path in registry is wrong!")
		get_tree().quit(1)
		return
	if apartment_config.get("default_entry_point_id") != "wake_bed":
		printerr("FAIL: apartment default_entry_point_id is wrong!")
		get_tree().quit(1)
		return

	var street_config = scenes_dict["apartment_entrance"]
	if street_config.get("path") != "res://scenes/levels/apartment_entrance.tscn":
		printerr("FAIL: apartment_entrance path in registry is wrong!")
		get_tree().quit(1)
		return
	print("PASS: SceneRegistry config verified.")

	print("Loading res://scenes/levels/apartment_entrance.tscn...")
	var street_scene = load("res://scenes/levels/apartment_entrance.tscn")
	if not street_scene:
		printerr("FAIL: Could not load apartment_entrance.tscn!")
		get_tree().quit(1)
		return
	print("PASS: apartment_entrance.tscn loaded successfully.")

	var street_instance = street_scene.instantiate()
	add_child(street_instance)
	print("PASS: apartment_entrance.tscn instantiated in scene tree.")
	UIMode.set_mode(UIMode.Mode.NONE)

	if not street_instance.has_signal("current_interactable_changed") or not street_instance.has_signal("interaction_requested") or not street_instance.has_signal("scene_transition_requested"):
		printerr("FAIL: apartment_entrance lacks Level interaction contract signals!")
		get_tree().quit(1)
		return
	if not street_instance.has_method("prepare_entry_point") or not street_instance.has_method("set_entry_point"):
		printerr("FAIL: apartment_entrance lacks prepare_entry_point or set_entry_point API!")
		get_tree().quit(1)
		return

	street_instance.set_entry_point("from_apartment", {})
	var street_background = street_instance.get_node_or_null("Background")
	if not street_background or street_background.texture == null:
		printerr("FAIL: apartment_entrance Background texture failed to load!")
		get_tree().quit(1)
		return
	var street_camera = street_instance.get_node_or_null("Camera2D")
	if not street_camera or not street_camera.enabled:
		printerr("FAIL: apartment_entrance Camera2D is missing or disabled!")
		get_tree().quit(1)
		return
	var street_player = street_instance.get_node_or_null("Player")
	if not street_player:
		printerr("FAIL: apartment_entrance Player node missing!")
		get_tree().quit(1)
		return
	if street_player.global_position != Vector2(730, 675):
		printerr("FAIL: apartment_entrance from_apartment spawn is wrong! Got: ", street_player.global_position)
		get_tree().quit(1)
		return
	if street_player.get("walk_line_y") != 665.0 or street_player.get("min_x") != 80.0 or street_player.get("max_x") != 4000.0:
		printerr("FAIL: apartment_entrance player walk bounds are wrong!")
		get_tree().quit(1)
		return
	if not street_instance.get_node_or_null("Interactables/BackToApartmentArea"):
		printerr("FAIL: apartment_entrance back_to_apartment interactable missing!")
		get_tree().quit(1)
		return

	# Verify NpcWan properties
	var npc_wan = street_instance.get_node_or_null("Interactables/NpcWan")
	if not npc_wan:
		printerr("FAIL: NpcWan node not found in apartment_entrance scene!")
		get_tree().quit(1)
		return
	if npc_wan.interaction_id != "talk_wan" or npc_wan.dialogue_id != "wan" or npc_wan.prompt_text != "E: █ 交談":
		printerr("FAIL: NpcWan interaction properties are incorrect!")
		get_tree().quit(1)
		return

	var npc_sprite = npc_wan.get_node_or_null("Sprite2D") as Sprite2D
	if not npc_sprite or npc_sprite.texture == null:
		printerr("FAIL: NpcWan Sprite2D or texture is missing!")
		get_tree().quit(1)
		return
	print("PASS: NpcWan node structure and texture verified.")

	# Verify generalized dialogue dispatch
	var dispatch_signal_received = {"emitted": false, "dialogue_id": ""}
	street_instance.interaction_requested.connect(func(data):
		if data.get("type") == "dialogue":
			dispatch_signal_received["emitted"] = true
			dispatch_signal_received["dialogue_id"] = data.get("dialogue_id", "")
	)

	# Simulate player entering NPC interaction range and triggering E
	street_instance._on_interactable_entered(npc_wan)
	Input.action_press("interact_primary")
	street_instance._process(0.0)
	Input.action_release("interact_primary")

	if not dispatch_signal_received["emitted"] or dispatch_signal_received["dialogue_id"] != "wan":
		printerr("FAIL: Generalized dialogue dispatch failed to emit interaction_requested signal!")
		get_tree().quit(1)
		return
	print("PASS: Generalized dialogue dispatch verified.")

	print("PASS: apartment_entrance map scene, spawn, bounds, and contract verified.")

	# 11. Verify Phase 4-E Entry Point methods on apartment_room
	print("Verifying Phase 4-E Entry Point APIs on apartment_room...")
	if not room_instance.has_method("prepare_entry_point") or not room_instance.has_method("set_entry_point"):
		printerr("FAIL: apartment_room.gd lacks prepare_entry_point or set_entry_point API!")
		get_tree().quit(1)
		return
	print("PASS: apartment_room prepare_entry_point & set_entry_point APIs verified.")

	# 12. Verify Room State Persistence
	print("Verifying room state persistence...")
	# Verify initial room state (unsolved)
	var clock = room_instance.get_node_or_null("Interactables/ProjectionClockArea")
	if not clock:
		printerr("FAIL: ProjectionClockArea should exist in unsolved room initial load!")
		get_tree().quit(1)
		return
	if room_instance.CONTAINERS.has("apartment_slot"):
		printerr("FAIL: CONTAINERS should not have apartment_slot in unsolved room initial load!")
		get_tree().quit(1)
		return
	print("PASS: Unsolved room layout verified (clock exists, slot hidden).")

	# Clean up first instantiation
	room_instance.queue_free()
	# Wait for queue_free to process
	await get_tree().process_frame

	# Simulate puzzle completion in GameState
	GameState.apartment_sonar_revealed = true
	GameState.apartment_slot_unlocked = true
	GameState.apartment_beyond_door_bgm_triggered = true

	# Instantiate the apartment room scene a second time (simulating re-entry)
	var room_instance2 = room_scene.instantiate()
	add_child(room_instance2)
	room_instance2.prepare_entry_point("from_street")
	room_instance2.set_entry_point("from_street")

	# Wait for queue_free to process on clock
	await get_tree().process_frame

	var clock2 = room_instance2.get_node_or_null("Interactables/ProjectionClockArea")
	if clock2 != null:
		printerr("FAIL: ProjectionClockArea should be deleted/removed in solved room re-entry!")
		get_tree().quit(1)
		return
	if not room_instance2.CONTAINERS.has("apartment_slot"):
		printerr("FAIL: CONTAINERS should have apartment_slot in solved room re-entry!")
		get_tree().quit(1)
		return
	if room_instance2.CONTAINERS["apartment_slot"]["title"] != "隱藏插槽":
		printerr("FAIL: Apartment slot should be dynamically registered!")
		get_tree().quit(1)
		return
	print("PASS: Solved room layout verified (clock removed, slot revealed).")

	# 13. Verify GameState Story Flags API & DialogueRunner Pure Logic (Phase 5-A)
	print("Verifying GameState Story Flags APIs...")
	GameState.story_flags.clear()
	GameState.set_flag("test_flag_bool", true)
	if not GameState.has_flag("test_flag_bool") or GameState.get_flag("test_flag_bool") != true:
		printerr("FAIL: GameState set_flag / get_flag for boolean failed!")
		get_tree().quit(1)
		return

	GameState.add_int("test_flag_int", 5)
	if GameState.get_flag("test_flag_int") != 5:
		printerr("FAIL: GameState add_int failed!")
		get_tree().quit(1)
		return

	GameState.add_int("test_flag_int", -2)
	if GameState.get_flag("test_flag_int") != 3:
		printerr("FAIL: GameState add_int delta accumulation failed!")
		get_tree().quit(1)
		return

	if not GameState.has_flag("test_flag_int"):
		printerr("FAIL: GameState has_flag for non-zero int failed!")
		get_tree().quit(1)
		return

	GameState.set_flag("test_flag_int", 0)
	if GameState.has_flag("test_flag_int"):
		printerr("FAIL: GameState has_flag for zero int should be false!")
		get_tree().quit(1)
		return

	print("PASS: GameState Story Flags APIs verified.")

	print("Verifying DialogueDB lookup...")
	var DialogueDB = load("res://data/dialogue/dialogue_db.gd")
	var wan_tree = DialogueDB.get_tree_for("wan")
	if wan_tree.is_empty() or not wan_tree.has("start"):
		printerr("FAIL: DialogueDB could not fetch wan tree!")
		get_tree().quit(1)
		return
	print("PASS: DialogueDB lookup verified.")

	print("Verifying DialogueRunner flow simulation (First Meet)...")
	var runner = DialogueRunner.new()
	GameState.story_flags.clear()
	runner.start(wan_tree)

	var curr = runner.current()
	if curr.get("speaker") != "晚" or not curr.get("text").contains("新面孔"):
		printerr("FAIL: DialogueRunner start should route to first_meet! Got text: ", curr.get("text"))
		get_tree().quit(1)
		return

	var choices = curr.get("choices")
	if choices.size() != 3:
		printerr("FAIL: first_meet should have 3 choices, got: ", choices.size())
		get_tree().quit(1)
		return

	# Choose option 1: "妳是誰？" -> who
	var idx_who = -1
	for choice in choices:
		if choice.get("label").contains("誰"):
			idx_who = choice.get("index")
			break
	if idx_who != 1:
		printerr("FAIL: who choice index should be 1, got: ", idx_who)
		get_tree().quit(1)
		return

	runner.choose(idx_who)
	curr = runner.current()
	if not curr.get("text").contains("名字？"):
		printerr("FAIL: should go to 'who' node! Got: ", curr.get("text"))
		get_tree().quit(1)
		return

	if not GameState.has_flag("knows_wan_name"):
		printerr("FAIL: knows_wan_name flag was not set upon entering 'who' node!")
		get_tree().quit(1)
		return

	runner.advance()
	curr = runner.current()
	if not curr.get("text").contains("那塊招牌"):
		printerr("FAIL: should advance to 'watch' node! Got: ", curr.get("text"))
		get_tree().quit(1)
		return

	choices = curr.get("choices")
	if choices.size() != 2:
		printerr("FAIL: watch node should have 2 choices, got: ", choices.size())
		get_tree().quit(1)
		return

	# Choose option 0: "我也撿這種東西。" -> kin
	var idx_kin = -1
	for choice in choices:
		if choice.get("label").contains("撿"):
			idx_kin = choice.get("index")
			break
	if idx_kin != 0:
		printerr("FAIL: kin choice index should be 0, got: ", idx_kin)
		get_tree().quit(1)
		return

	runner.choose(idx_kin)
	curr = runner.current()
	if not curr.get("text").contains("同類"):
		printerr("FAIL: should go to 'kin' node! Got: ", curr.get("text"))
		get_tree().quit(1)
		return

	if GameState.get_flag("affinity_wan") != 1 or not GameState.get_flag("met_wan"):
		printerr("FAIL: kin effects not applied correctly!")
		get_tree().quit(1)
		return

	runner.advance()
	curr = runner.current()
	if not curr.get("text").contains("有意思的"):
		printerr("FAIL: should advance to 'end_warm' node! Got: ", curr.get("text"))
		get_tree().quit(1)
		return

	if not curr.get("is_terminal"):
		printerr("FAIL: end_warm should be a terminal node!")
		get_tree().quit(1)
		return

	var finished_signal_status = {"emitted": false}
	runner.finished.connect(func(): finished_signal_status["emitted"] = true)
	runner.advance()
	if not finished_signal_status["emitted"]:
		printerr("FAIL: DialogueRunner should emit finished on terminal node advance!")
		get_tree().quit(1)
		return

	print("PASS: DialogueRunner flow simulation (First Meet) verified.")

	print("Verifying DialogueRunner flow simulation (Retalk & Intel Gate Locked)...")
	# met_wan is true, affinity_wan is 1
	runner.start(wan_tree)
	curr = runner.current()
	if not curr.get("text").contains("又是你"):
		printerr("FAIL: start should route to retalk since met_wan is true! Got: ", curr.get("text"))
		get_tree().quit(1)
		return

	choices = curr.get("choices")
	var idx_news = -1
	for choice in choices:
		if choice.get("label").contains("消息"):
			idx_news = choice.get("index")
			break
	if idx_news != 1:
		printerr("FAIL: news choice index should be 1, got: ", idx_news)
		get_tree().quit(1)
		return

	runner.choose(idx_news)
	curr = runner.current()
	if not curr.get("text").contains("我又不是 AI 客服"):
		printerr("FAIL: should route to intel_locked since affinity_wan < 2! Got: ", curr.get("text"))
		get_tree().quit(1)
		return

	if GameState.get_flag("affinity_wan") != 2:
		printerr("FAIL: intel_locked effect affinity_wan += 1 failed!")
		get_tree().quit(1)
		return

	runner.advance()
	curr = runner.current()
	if not curr.get("text").contains("死掉的招牌"):
		printerr("FAIL: should advance to 'end_cold'! Got: ", curr.get("text"))
		get_tree().quit(1)
		return
	if not curr.get("is_terminal"):
		printerr("FAIL: end_cold should be terminal!")
		get_tree().quit(1)
		return

	print("PASS: DialogueRunner flow simulation (Retalk & Intel Gate Locked) verified.")

	print("Verifying DialogueRunner flow simulation (Retalk & Intel Gate Unlocked)...")
	# met_wan is true, affinity_wan is now 2
	runner.start(wan_tree)
	curr = runner.current()
	choices = curr.get("choices")

	runner.choose(idx_news)
	curr = runner.current()
	if not curr.get("text").contains("想聽好料"):
		printerr("FAIL: should route to intel since affinity_wan >= 2! Got: ", curr.get("text"))
		get_tree().quit(1)
		return

	# start_quest should trigger, check quest status
	if QuestManager.get_status("alley_backrooms_3f") != "active":
		printerr("FAIL: start_quest effect failed to start 'alley_backrooms_3f' quest!")
		get_tree().quit(1)
		return

	runner.advance()
	curr = runner.current()
	if not curr.get("text").contains("有意思的"):
		printerr("FAIL: should advance to 'end_warm'! Got: ", curr.get("text"))
		get_tree().quit(1)
		return

	# Additional Phase 7-B Verification: test new dialogue tree conditions (quest_status, quest_step, has_item)
	print("Verifying Phase 7-B Condition Evaluation...")
	# 1. Test condition: type = quest_status, op = ==, value = active
	var test_cond_active = {"type": "quest_status", "quest_id": "alley_backrooms_3f", "op": "==", "value": "active"}
	if not runner._eval_condition(test_cond_active):
		printerr("FAIL: Condition quest_status=active should evaluate to true!")
		get_tree().quit(1)
		return
		
	# 2. Test condition: type = quest_step, op = ==, value = checked_alley (not reached yet)
	var test_cond_checked = {"type": "quest_step", "quest_id": "alley_backrooms_3f", "op": "==", "value": "checked_alley"}
	if runner._eval_condition(test_cond_checked):
		printerr("FAIL: Condition quest_step=checked_alley should evaluate to false!")
		get_tree().quit(1)
		return
		
	# 3. Test condition: type = has_item, item_id = canned_food, op = ==, value = true (not owned yet)
	var test_cond_item = {"type": "has_item", "item_id": "canned_food", "op": "==", "value": true}
	if runner._eval_condition(test_cond_item):
		printerr("FAIL: Condition has_item=true should evaluate to false when item is not owned!")
		get_tree().quit(1)
		return
		
	# Add item and verify has_item condition
	GameState.add_item("canned_food", 1)
	if not runner._eval_condition(test_cond_item):
		printerr("FAIL: Condition has_item=true should evaluate to true after adding item!")
		get_tree().quit(1)
		return
		
	# Clean up item
	GameState.remove_item("canned_food", 1)
	
	# 4. Test condition array (AND evaluation)
	var test_cond_arr = [
		{"type": "quest_status", "quest_id": "alley_backrooms_3f", "op": "==", "value": "active"},
		{"type": "quest_step", "quest_id": "alley_backrooms_3f", "op": "==", "value": "started"}
	]
	if not runner._eval_condition(test_cond_arr):
		printerr("FAIL: Condition array AND evaluation failed!")
		get_tree().quit(1)
		return
		
	# Verify retalk with active quest routes to intel_already_given
	runner.start(wan_tree)
	curr = runner.current()
	var idx_news_retalk = -1
	for ch in curr.get("choices"):
		if ch.get("label") == "有新消息嗎？":
			idx_news_retalk = ch.get("index")
			break
	
	runner.choose(idx_news_retalk)
	curr = runner.current()
	if not curr.get("text").contains("不是跟你說過了"):
		printerr("FAIL: retalk news with active quest should route to 'intel_already_given'! Got: ", curr.get("text"))
		get_tree().quit(1)
		return
	print("PASS: retalk news with active quest routing verified.")

	print("PASS: DialogueRunner flow simulation (Retalk & Intel Gate Unlocked) verified.")

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

	# 15. Verify Phase 6-A SaveSystem Autoload & State Serialization
	print("Verifying Phase 6-A SaveSystem Autoload & State Serialization...")
	
	# Prepare some state changes
	GameState.reset_for_new_game()
	if GameState.get_credits() != 300:
		printerr("FAIL: GameState reset_for_new_game did not set default credits!")
		get_tree().quit(1)
		return
	
	GameState.set_credits(500)
	GameState.set_flag("test_story_flag", 42)
	GameState.apartment_sonar_revealed = true
	
	# Add item and verify it exists
	if not GameState.add_item("canned_food", 3):
		printerr("FAIL: Could not add canned_food for test!")
		get_tree().quit(1)
		return
	
	var inventory_before = GameState.get_inventory()
	var credits_before = GameState.get_credits()
	
	# Capture state
	var save_data = SaveSystem.capture("apartment", 425.0, -1)
	if not SaveSystem.validate(save_data):
		printerr("FAIL: Captured save data failed validation!")
		get_tree().quit(1)
		return
	print("PASS: Capture and validate verified.")
	
	# Write slot and read back
	var slot_idx := 1
	var dir = DirAccess.open("user://")
	if dir and dir.file_exists("save_01.sav"):
		dir.remove("save_01.sav")
	
	var slots_list_before = SaveSystem.list_slots()
	if not slots_list_before[0]["empty"]:
		printerr("FAIL: Slot 1 should be empty before writing!")
		get_tree().quit(1)
		return
	
	if not SaveSystem.write_slot(slot_idx, save_data):
		printerr("FAIL: Failed to write to slot 1!")
		get_tree().quit(1)
		return
	print("PASS: Write slot verified.")
	
	var slots_list_after = SaveSystem.list_slots()
	if slots_list_after[0]["empty"] or slots_list_after[0]["meta"]["credits"] != 500:
		printerr("FAIL: list_slots did not report written slot 1 metadata correctly!")
		get_tree().quit(1)
		return
	print("PASS: list_slots verified with active slot.")
	
	# Read slot
	var read_data = SaveSystem.read_slot(slot_idx)
	if not SaveSystem.validate(read_data):
		printerr("FAIL: Read save data failed validation!")
		get_tree().quit(1)
		return
	if read_data["data"]["player_x"] != 425.0 or read_data["data"]["player_facing"] != -1:
		printerr("FAIL: Read data fields did not match captured fields!")
		get_tree().quit(1)
		return
	print("PASS: Read slot and validation verified.")
	
	# Corrupt slot simulation
	var corrupt_slot_idx := 2
	var corrupt_file = FileAccess.open("user://save_02.sav", FileAccess.WRITE)
	if corrupt_file:
		corrupt_file.store_string("THIS IS NOT A VALID SAV OBJECT")
		corrupt_file.close()
	
	var slots_list_corrupt = SaveSystem.list_slots()
	if slots_list_corrupt[1]["empty"] or not slots_list_corrupt[1].get("corrupt", false):
		printerr("FAIL: list_slots did not identify corrupt slot 2!")
		get_tree().quit(1)
		return
	print("PASS: list_slots corrupt detection verified.")
	
	# Clean up corrupt file
	if dir:
		dir.remove("save_02.sav")
	
	# Reset state and apply read data
	GameState.reset_for_new_game()
	if GameState.get_credits() != 300 or GameState.story_flags.has("test_story_flag"):
		printerr("FAIL: reset_for_new_game failed to clear state before load!")
		get_tree().quit(1)
		return
	
	SaveSystem.apply(read_data)
	
	# Verify restored state
	var inventory_after = GameState.get_inventory()
	var credits_after = GameState.get_credits()
	
	if credits_after != credits_before:
		printerr("FAIL: Credits mismatch after applying save!")
		get_tree().quit(1)
		return
	if GameState.get_flag("test_story_flag") != 42:
		printerr("FAIL: Story flags mismatch after applying save!")
		get_tree().quit(1)
		return
	if not GameState.apartment_sonar_revealed:
		printerr("FAIL: Apartment sonar state mismatch after applying save!")
		get_tree().quit(1)
		return
		
	# Compare inventory arrays
	if inventory_after.size() != inventory_before.size():
		printerr("FAIL: Inventory slot count mismatch after applying save!")
		get_tree().quit(1)
		return
	for i in range(inventory_after.size()):
		var slot_a = inventory_after[i]
		var slot_b = inventory_before[i]
		if slot_a.get("item_id") != slot_b.get("item_id") or slot_a.get("quantity") != slot_b.get("quantity"):
			printerr("FAIL: Inventory slot content mismatch after applying save!")
			get_tree().quit(1)
			return
	print("PASS: SaveSystem state application and validation matches perfectly.")

	room_instance2.queue_free()

	# 16. Verify Phase 6-B Load Game Entry Path & Dual Validation
	print("Verifying Phase 6-B Load Game Entry Path & Dual Validation...")
	
	# Reset state first
	GameState.reset_for_new_game()
	
	# Load slot 1 (which we saved in 6-A with player_x = 425.0, facing = -1)
	var load_success = main_instance.load_game_slot(1)
	if not load_success:
		printerr("FAIL: load_game_slot(1) failed to load valid slot!")
		get_tree().quit(1)
		return
	
	var active_level = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion():
			active_level = child
			break
	if not active_level or not active_level.get_script() or not active_level.get_script().resource_path.contains("apartment_room.gd"):
		printerr("FAIL: Restored scene is not ApartmentRoom! Script was: ", active_level.get_script().resource_path if active_level and active_level.get_script() else "null")
		get_tree().quit(1)
		return
	
	if active_level.get("_opening_monologue_active"):
		printerr("FAIL: Monologue was not bypassed during restore load!")
		get_tree().quit(1)
		return
	print("PASS: Monologue bypass verified.")
	
	var active_player = active_level.get_node("Player")
	if active_player.get_save_x() != 425.0:
		printerr("FAIL: Restored player position is wrong! Got: ", active_player.get_save_x())
		get_tree().quit(1)
		return
	if active_player.get_facing() != -1:
		printerr("FAIL: Restored player facing is wrong! Got: ", active_player.get_facing())
		get_tree().quit(1)
		return
	print("PASS: Player position and facing restore verified.")
	
	# Verify dual stage validation failures
	# 1. Validation fail due to invalid scene registry on Main
	var invalid_scene_payload = SaveSystem.capture("apartment", 425.0, -1)
	invalid_scene_payload["data"]["current_scene_id"] = "nonexistent_scene_id"
	if not SaveSystem.write_slot(3, invalid_scene_payload):
		printerr("FAIL: Failed to write test payload to slot 3!")
		get_tree().quit(1)
		return
	
	# Set some check value in GameState
	GameState.set_credits(9999)
	var load_invalid_success = main_instance.load_game_slot(3)
	if load_invalid_success:
		printerr("FAIL: load_game_slot(3) should have failed due to invalid scene ID registry check!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 9999:
		printerr("FAIL: GameState applied half-validated save changes! GameState must be intact.")
		get_tree().quit(1)
		return
	print("PASS: Scene registry validation failure correctly aborted load and left GameState intact.")
	
	# Clean up slot 3
	if dir and dir.file_exists("save_03.sav"):
		dir.remove("save_03.sav")
		
	# 2. Validation fail due to corrupted payload (validate() check)
	if not SaveSystem.write_slot(3, {}): # Empty payload
		printerr("FAIL: Failed to write empty dict to slot 3!")
		get_tree().quit(1)
		return
	var load_empty_success = main_instance.load_game_slot(3)
	if load_empty_success:
		printerr("FAIL: load_game_slot(3) should have failed due to validate check on empty payload!")
		get_tree().quit(1)
		return
	print("PASS: Payload validation failure correctly aborted load.")
	
	# Clean up slot 3
	if dir and dir.file_exists("save_03.sav"):
		dir.remove("save_03.sav")
		
	# Verify start_new_game resets state and plays monologue
	main_instance.start_new_game()
	var new_level = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion():
			new_level = child
			break
	if not new_level or not new_level.get_script() or not new_level.get_script().resource_path.contains("apartment_room.gd"):
		printerr("FAIL: New game scene is not ApartmentRoom! Script was: ", new_level.get_script().resource_path if new_level and new_level.get_script() else "null")
		get_tree().quit(1)
		return
	if not new_level.get("_opening_monologue_active"):
		printerr("FAIL: New game did not start opening monologue!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 300:
		printerr("FAIL: New game did not reset credits to 300!")
		get_tree().quit(1)
		return
	print("PASS: start_new_game monologue and reset verified.")

	# 17. Verify Phase 6-D & 6-E GUI components (TitleScreen & PauseMenu)
	print("Verifying Phase 6-D & 6-E Title Screen, Pause Menu, & Save/Load UI...")
	
	# Verify TitleScreen Isolation
	var title_scene = load("res://scenes/ui/title_screen.tscn")
	if not title_scene:
		printerr("FAIL: Could not load title_screen.tscn!")
		get_tree().quit(1)
		return
		
	var title_instance = title_scene.instantiate()
	main_instance.add_child(title_instance)
	if not TouchControls.force_hidden:
		printerr("FAIL: Title Screen did not trigger TouchControls force_hidden = true!")
		get_tree().quit(1)
		return
	print("PASS: Title Screen TouchControls isolation verified.")
	
	title_instance.queue_free()
	TouchControls.set_force_hidden(false)
	
	# Verify PauseMenu integration inside GameUI
	var game_ui = main_instance.get_node("GameUI")
	var pause_menu = game_ui.get_node("PauseMenu")
	if not pause_menu:
		printerr("FAIL: PauseMenu not found under GameUI!")
		get_tree().quit(1)
		return
		
	# Trigger pause menu
	UIMode.set_mode(UIMode.Mode.NONE)
	game_ui.open_pause_menu()
	if UIMode.get_mode() != UIMode.Mode.PAUSE:
		printerr("FAIL: open_pause_menu() did not switch UIMode to PAUSE!")
		get_tree().quit(1)
		return
	if not pause_menu.visible:
		printerr("FAIL: PauseMenu node was not made visible in PAUSE mode!")
		get_tree().quit(1)
		return
	print("PASS: PauseMenu opening and UIMode.PAUSE verified.")
	
	# Check TouchControls visibility in PAUSE mode
	TouchControls.touch_buttons_enabled = true
	TouchControls._update_dynamic_button_visibility()
	if not TouchControls.get_node("Control/DPad").visible:
		printerr("FAIL: DPad should be visible in PAUSE mode for UI focus navigation!")
		get_tree().quit(1)
		return
	if TouchControls.get_node("Control/Actions").visible or TouchControls.get_node("Control/Menus").visible:
		printerr("FAIL: Actions/Menus should be hidden in PAUSE mode!")
		get_tree().quit(1)
		return
	print("PASS: TouchControls visibility in PAUSE mode verified.")
	
	# Reset touch_buttons_enabled
	TouchControls.touch_buttons_enabled = false
	
	# Test Resume option
	pause_menu._on_resume_pressed()
	if UIMode.get_mode() != UIMode.Mode.NONE or pause_menu.visible:
		printerr("FAIL: Resume did not exit PAUSE mode or hide PauseMenu!")
		get_tree().quit(1)
		return
	print("PASS: PauseMenu Resume verified.")
	
	# Test Slot List rendering inside PauseMenu
	game_ui.open_pause_menu()
	pause_menu._on_save_pressed()
	var slot_list = pause_menu.get_node("SaveSlotList")
	if not slot_list or not slot_list.visible:
		printerr("FAIL: SaveSlotList was not displayed after clicking Save!")
		get_tree().quit(1)
		return
		
	# Verify list slot contents (7 buttons populated)
	var slots = slot_list.get_node("Panel/VBoxContainer/SlotsVBox")
	var buttons_count := 0
	for child in slots.get_children():
		if child is Button:
			buttons_count += 1
	if buttons_count != 7:
		printerr("FAIL: SaveSlotList did not contain exactly 7 slots! Got: ", buttons_count)
		get_tree().quit(1)
		return
		
	# Verify slot 1 text is populated (we saved to it in 6-A/6-B)
	var slot1_btn = slots.get_child(0) as Button
	if "空白" in slot1_btn.text or slot1_btn.text.is_empty():
		printerr("FAIL: Slot 1 should display active save metadata, got text: ", slot1_btn.text)
		get_tree().quit(1)
		return
	print("PASS: SaveSlotList metadata population verified.")
	
	# Verify ConfirmDialog Overwrite & Title Return behavior (Guard against Button restore crashes & UIMode exit issues)
	var confirm_dialog = game_ui.get_node("ConfirmDialog")
	if not confirm_dialog:
		printerr("FAIL: ConfirmDialog not found inside GameUI!")
		get_tree().quit(1)
		return
		
	# 1. Overwrite confirm simulation (triggers ConfirmDialog, restores to Slot Button)
	slot_list._on_slot_button_pressed(1) # Slot 1 is active, should trigger overwrite warning
	if UIMode.get_mode() != UIMode.Mode.CONFIRM or not confirm_dialog.visible:
		printerr("FAIL: Overwriting active slot did not open ConfirmDialog!")
		get_tree().quit(1)
		return
		
	# Simulate Cancel: close_dialog should restore state to PAUSE without crashing on Button restore
	confirm_dialog.close_dialog()
	if UIMode.get_mode() != UIMode.Mode.PAUSE or confirm_dialog.visible:
		printerr("FAIL: Cancel overwrite did not return UIMode to PAUSE!")
		get_tree().quit(1)
		return
	print("PASS: Overwrite confirmation Cancel & UIMode restore verified.")
	
	# Simulate Confirm: confirm execution should perform save and return back to PAUSE (single exit_confirm)
	slot_list._on_slot_button_pressed(1)
	if confirm_dialog._on_confirm.is_valid():
		confirm_dialog._on_confirm.call()
	confirm_dialog.close_dialog()
	if UIMode.get_mode() != UIMode.Mode.PAUSE:
		printerr("FAIL: Confirming overwrite did not return UIMode back to PAUSE (got mode: ", UIMode.get_mode(), ")")
		get_tree().quit(1)
		return
	print("PASS: Overwrite confirmation Confirm & single exit_confirm verified.")
	
	# 2. Return to Title confirmation simulation (triggers ConfirmDialog, restores to btn_title)
	pause_menu._on_title_pressed()
	if UIMode.get_mode() != UIMode.Mode.CONFIRM or not confirm_dialog.visible:
		printerr("FAIL: Clicking Return to Title did not show ConfirmDialog!")
		get_tree().quit(1)
		return
		
	# Simulate Cancel: should return to PAUSE
	confirm_dialog.close_dialog()
	if UIMode.get_mode() != UIMode.Mode.PAUSE or confirm_dialog.visible:
		printerr("FAIL: Cancelling Title return did not restore UIMode to PAUSE!")
		get_tree().quit(1)
		return
	print("PASS: Title return confirmation Cancel & UIMode restore verified.")
	
	# Close pause menu
	UIMode.set_mode(UIMode.Mode.NONE)

	# 18. Verify Phase 7-A QuestManager & QuestState
	print("Verifying Phase 7-A QuestManager & QuestState...")
	
	# Reset state first
	GameState.reset_for_new_game()
	
	# Verify initial state
	if QuestManager.get_status("alley_backrooms_3f") != "":
		printerr("FAIL: Initial quest status should be empty string!")
		get_tree().quit(1)
		return
	if QuestManager.get_step("alley_backrooms_3f") != "":
		printerr("FAIL: Initial quest step should be empty string!")
		get_tree().quit(1)
		return
	
	# Start quest
	var start_ok = QuestManager.start("alley_backrooms_3f")
	if not start_ok:
		printerr("FAIL: Failed to start quest 'alley_backrooms_3f'!")
		get_tree().quit(1)
		return
	if not GameState.has_active_quest("alley_backrooms_3f"):
		printerr("FAIL: GameState has_active_quest returned false after start!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("alley_backrooms_3f") != "active":
		printerr("FAIL: Quest status is not 'active' after start!")
		get_tree().quit(1)
		return
	if QuestManager.get_step("alley_backrooms_3f") != "started":
		printerr("FAIL: Quest step is not 'started' after start!")
		get_tree().quit(1)
		return
		
	# Verify note sync
	var notes_started = GameState.get_notes("工作")
	if notes_started.size() != 1:
		printerr("FAIL: Work notes count is not 1! Got: ", notes_started.size())
		get_tree().quit(1)
		return
	var work_note = notes_started[0]
	if work_note.get("id") != "quest_alley_backrooms_3f":
		printerr("FAIL: Work note id is wrong! Got: ", work_note.get("id"))
		get_tree().quit(1)
		return
	if not "「晚」提到暗巷三樓" in work_note.get("body", ""):
		printerr("FAIL: Work note body for started state is wrong! Got: ", work_note.get("body"))
		get_tree().quit(1)
		return
	print("PASS: Quest start and initial note sync verified.")
	
	# Advance quest
	var adv_ok = QuestManager.advance("alley_backrooms_3f", "checked_alley", {"checked": true})
	if not adv_ok:
		printerr("FAIL: Failed to advance quest 'alley_backrooms_3f' to 'checked_alley'!")
		get_tree().quit(1)
		return
	if QuestManager.get_step("alley_backrooms_3f") != "checked_alley":
		printerr("FAIL: Quest step is not 'checked_alley' after advance!")
		get_tree().quit(1)
		return
	if not QuestManager.get_flag("alley_backrooms_3f", "checked"):
		printerr("FAIL: Quest flag 'checked' was not set!")
		get_tree().quit(1)
		return
		
	# Verify advanced note body
	var notes_checked = GameState.get_notes("工作")
	if notes_checked.size() != 1:
		printerr("FAIL: Work notes count after advance is not 1!")
		get_tree().quit(1)
		return
	if not "去後巷看過了" in notes_checked[0].get("body", ""):
		printerr("FAIL: Work note body for checked_alley state is wrong! Got: ", notes_checked[0].get("body"))
		get_tree().quit(1)
		return
	print("PASS: Quest advance and note updating verified.")
	
	# Verify invalid step transition
	var adv_invalid = QuestManager.advance("alley_backrooms_3f", "nonexistent_step")
	if adv_invalid:
		printerr("FAIL: Advancing to nonexistent step should fail!")
		get_tree().quit(1)
		return
	print("PASS: Invalid quest step transition correctly blocked.")
	
	# Verify Quest states are NOT stored in GameState.knowledge (should remain empty)
	if GameState.knowledge.has("quest_alley_backrooms_3f"):
		printerr("FAIL: Quest notes must not be stored in GameState.knowledge!")
		get_tree().quit(1)
		return
	print("PASS: Quest status is not saved in knowledge database.")

	# Complete quest
	var complete_ok = QuestManager.complete("alley_backrooms_3f")
	if not complete_ok:
		printerr("FAIL: Failed to complete quest!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("alley_backrooms_3f") != "completed":
		printerr("FAIL: Quest status is not 'completed' after complete()!")
		get_tree().quit(1)
		return
	var notes_completed = GameState.get_notes("工作")
	if notes_completed[0].get("status") != "completed":
		printerr("FAIL: Work note status was not updated to completed!")
		get_tree().quit(1)
		return
	if not "已將「早期" in notes_completed[0].get("body", ""):
		printerr("FAIL: Work note body for completed status is wrong! Got: ", notes_completed[0].get("body"))
		get_tree().quit(1)
		return
	print("PASS: Quest completion and note status update verified.")
	
	# Verify Save/Load Serialization of quest_states
	var save_dict = GameState.to_save_dict()
	if not save_dict.has("quest_states"):
		printerr("FAIL: Save dictionary is missing 'quest_states' key!")
		get_tree().quit(1)
		return
	var saved_quest_state = save_dict["quest_states"].get("alley_backrooms_3f", {})
	if saved_quest_state.get("status") != "completed":
		printerr("FAIL: Saved quest status is wrong! Got: ", saved_quest_state.get("status"))
		get_tree().quit(1)
		return
		
	# Reset state and restore from save dict
	GameState.reset_for_new_game()
	if QuestManager.get_status("alley_backrooms_3f") != "":
		printerr("FAIL: Quest states not cleared after reset_for_new_game!")
		get_tree().quit(1)
		return
		
	GameState.load_save_dict(save_dict)
	if QuestManager.get_status("alley_backrooms_3f") != "completed":
		printerr("FAIL: Quest states not restored correctly from load_save_dict!")
		get_tree().quit(1)
		return
	print("PASS: Quest states serialization and restoration verified.")

	# 19. Verify Phase 7-C apartment_entrance alley_view quest event
	print("Verifying Phase 7-C apartment_entrance alley_view quest event...")
	
	# Reset state first
	GameState.reset_for_new_game()
	
	# Transition into apartment_entrance
	main_instance.transition_to("apartment_entrance", "from_apartment")
	await get_tree().process_frame
	
	var active_street = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("apartment_entrance.gd"):
			active_street = child
			break
			
	if not active_street:
		printerr("FAIL: Current scene is not apartment_entrance after transition!")
		get_tree().quit(1)
		return
		
	# Find alley_view interactable node in active_street
	var alley_area = active_street.get_node_or_null("Interactables/AlleyViewArea")
	if not alley_area:
		printerr("FAIL: AlleyViewArea not found under active_street/Interactables!")
		get_tree().quit(1)
		return
		
	# Test BEFORE quest is started (should return default message)
	var last_interaction_data = {}
	_temp_callable = func(data):
		last_interaction_data.clear()
		last_interaction_data.merge(data)
	active_street.interaction_requested.connect(_temp_callable)
	
	active_street.current_interactable = alley_area
	active_street._trigger_interaction()
	
	if last_interaction_data.get("type") != "message":
		printerr("FAIL: Interaction type is not 'message' before quest started! Got data: ", last_interaction_data)
		get_tree().quit(1)
		return
	if not "右側暗巷深得像" in last_interaction_data.get("message_text", ""):
		printerr("FAIL: Default alley_view message is wrong! Got: ", last_interaction_data.get("message_text"))
		get_tree().quit(1)
		return
	print("PASS: Default alley_view message verified when quest is not active.")
	
	# Test AFTER quest is started (should advance quest and show danger message)
	QuestManager.start("alley_backrooms_3f")
	if QuestManager.get_status("alley_backrooms_3f") != "active" or QuestManager.get_step("alley_backrooms_3f") != "started":
		printerr("FAIL: Failed to initialize quest state to started!")
		get_tree().quit(1)
		return
		
	last_interaction_data.clear()
	active_street._trigger_interaction()
	
	if not "暗巷深處有幾具損毀" in last_interaction_data.get("message_text", ""):
		printerr("FAIL: Danger alley_view message is wrong! Got: ", last_interaction_data.get("message_text"))
		get_tree().quit(1)
		return
	if last_interaction_data.get("note_title", "") == "":
		printerr("FAIL: note_title should be present to show note update toast!")
		get_tree().quit(1)
		return
		
	# Check if quest stepped advanced
	if QuestManager.get_step("alley_backrooms_3f") != "checked_alley":
		printerr("FAIL: Quest step did not advance to 'checked_alley' after interaction!")
		get_tree().quit(1)
		return
	print("PASS: Quest advanced and danger message shown on first active interaction.")
	
	# Test SECOND interaction when quest step is checked_alley (should show danger message but NOT change state)
	last_interaction_data.clear()
	active_street._trigger_interaction()
	
	if not "暗巷深處有幾具損毀" in last_interaction_data.get("message_text", ""):
		printerr("FAIL: Danger message should be shown on subsequent active interactions!")
		get_tree().quit(1)
		return
	if QuestManager.get_step("alley_backrooms_3f") != "checked_alley":
		printerr("FAIL: Quest step changed incorrectly on duplicate interaction!")
		get_tree().quit(1)
		return
	print("PASS: Duplicate interaction does not alter quest step.")
	
	# Clean up signal connection
	active_street.interaction_requested.disconnect(_temp_callable)

	# 20. Verify Phase 7-D Apartment Window conditional entry
	print("Verifying Phase 7-D Apartment Window conditional entry...")
	
	# Reset state first
	GameState.reset_for_new_game()
	
	# Transition into apartment
	main_instance.transition_to("apartment", "wake_bed")
	await get_tree().process_frame
	
	var active_apartment = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("apartment_room.gd"):
			active_apartment = child
			break
			
	if not active_apartment:
		printerr("FAIL: Current scene is not apartment after transition!")
		get_tree().quit(1)
		return
		
	# Find ApartmentWindow interactable node in active_apartment
	var window_area = active_apartment.get_node_or_null("Interactables/ApartmentWindow")
	if not window_area:
		printerr("FAIL: ApartmentWindow not found under active_apartment/Interactables!")
		get_tree().quit(1)
		return
		
	# Test 20.1: Window NOT available before checked_alley (not started, or active but started step)
	# Case A: status = "" (not started)
	active_apartment._on_interactable_entered(window_area)
	
	active_apartment._refresh_current_interactable()
	if active_apartment.current_interactable == window_area:
		printerr("FAIL: Window should not be interactable when quest is not started!")
		get_tree().quit(1)
		return
	print("PASS: Window interaction correctly disabled when quest is not started.")
	
	active_apartment._on_interactable_exited(window_area)
	
	# Case B: active + step=started (started, but not yet checked_alley)
	QuestManager.start("alley_backrooms_3f")
	if QuestManager.get_status("alley_backrooms_3f") != "active" or QuestManager.get_step("alley_backrooms_3f") != "started":
		printerr("FAIL: Quest not correctly initialized to started state!")
		get_tree().quit(1)
		return
		
	active_apartment._on_interactable_entered(window_area)
	active_apartment._refresh_current_interactable()
	if active_apartment.current_interactable == window_area:
		printerr("FAIL: Window should not be interactable when quest step is started!")
		get_tree().quit(1)
		return
	print("PASS: Window interaction correctly disabled when quest step is started.")
	
	active_apartment._on_interactable_exited(window_area)
	
	# Test 20.2: Start quest and advance to checked_alley
	QuestManager.advance("alley_backrooms_3f", "checked_alley")
	if QuestManager.get_step("alley_backrooms_3f") != "checked_alley":
		printerr("FAIL: Quest step is not checked_alley!")
		get_tree().quit(1)
		return
		
	active_apartment._on_interactable_entered(window_area)
	active_apartment._refresh_current_interactable()
	if active_apartment.current_interactable != window_area:
		printerr("FAIL: Window should be interactable when quest step is checked_alley!")
		get_tree().quit(1)
		return
	if not "爬出窗外" in active_apartment.current_interactable.prompt_text:
		printerr("FAIL: Window prompt text is wrong! Got: ", active_apartment.current_interactable.prompt_text)
		get_tree().quit(1)
		return
	print("PASS: Window interaction enabled with correct prompt after checked_alley.")
	
	# Test 20.3: Interact with window and verify transition request
	var last_transition_data = {}
	_temp_callable = func(scene_id, entry_point_id, payload):
		last_transition_data["scene_id"] = scene_id
		last_transition_data["entry_point_id"] = entry_point_id
		last_transition_data["payload"] = payload
	active_apartment.scene_transition_requested.connect(_temp_callable)
	
	active_apartment._trigger_interaction()
	
	if last_transition_data.get("scene_id") != "apartment_fire_escape":
		printerr("FAIL: Transition scene_id is not apartment_fire_escape! Got: ", last_transition_data)
		get_tree().quit(1)
		return
	if last_transition_data.get("entry_point_id") != "from_window":
		printerr("FAIL: Transition entry_point_id is not from_window! Got: ", last_transition_data)
		get_tree().quit(1)
		return
	print("PASS: Window interaction correctly emits scene_transition_requested to fire escape.")
	
	active_apartment.scene_transition_requested.disconnect(_temp_callable)
	active_apartment._on_interactable_exited(window_area)
	
	# Test 20.4: Verify from_fire_escape entry point positioning and monologue suppression
	GameState.reset_for_new_game()
	
	main_instance.transition_to("apartment", "from_fire_escape")
	await get_tree().process_frame
	
	var active_apartment_from_escape = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("apartment_room.gd"):
			active_apartment_from_escape = child
			break
			
	if not active_apartment_from_escape:
		printerr("FAIL: Current scene is not apartment after transition from fire escape!")
		get_tree().quit(1)
		return
		
	var player_node = active_apartment_from_escape.get_node("Player")
	if abs(player_node.global_position.x - 1000.0) > 1.0 or abs(player_node.global_position.y - 700.0) > 1.0:
		printerr("FAIL: Player position is not near window at (1000, 700)! Got: ", player_node.global_position)
		get_tree().quit(1)
		return
		
	if active_apartment_from_escape._opening_monologue_active:
		printerr("FAIL: Opening monologue should be suppressed when entering from_fire_escape!")
		get_tree().quit(1)
		return
		
	print("PASS: from_fire_escape entry point positioning and monologue suppression verified.")
	
	# Test 21: Verify 7-G Fire Escape Target Box Search & Activation Box Retrieval
	print("Verifying Phase 7-G Fire Escape Target Box Search & Retrieval...")
	# 1. Load fire escape scene
	var escape_scene = load("res://scenes/levels/apartment_fire_escape/apartment_fire_escape.tscn")
	if not escape_scene:
		printerr("FAIL: Could not load apartment_fire_escape.tscn!")
		get_tree().quit(1)
		return
	var escape_instance = escape_scene.instantiate()
	add_child(escape_instance)
	
	# 2. Reset quest states and inventory
	GameState.reset_for_new_game()
	
	# 3. Initially, when quest not started, target box interaction should show locked message
	var box_area = escape_instance.get_node("Interactables/QuestBox")
	if not box_area:
		printerr("FAIL: QuestBox interactable not found in fire escape scene!")
		get_tree().quit(1)
		return
	
	escape_instance._on_interactable_entered(box_area)
	
	var test_state = {
		"message_text": "",
		"on_closed": Callable()
	}
	var test_callback = func(data):
		if data.get("type") == "message":
			test_state["message_text"] = data.get("message_text", "")
			test_state["on_closed"] = data.get("on_closed", Callable())
	escape_instance.interaction_requested.connect(test_callback)
	
	# Trigger E interaction when quest is not started
	escape_instance._handle_primary_interaction()
	if test_state["message_text"] != escape_instance.MESSAGES["quest_box_locked"]:
		printerr("FAIL: Box interaction should be locked when quest not started! Got: ", test_state["message_text"])
		get_tree().quit(1)
		return
	print("PASS: Locked message shown correctly when quest is not started.")
	
	# 4. Start quest, but step is not checked_alley (it's started)
	QuestManager.start("alley_backrooms_3f")
	test_state["message_text"] = ""
	test_state["on_closed"] = Callable()
	escape_instance._handle_primary_interaction()
	if test_state["message_text"] != escape_instance.MESSAGES["quest_box_locked"]:
		printerr("FAIL: Box interaction should be locked when quest step is started! Got: ", test_state["message_text"])
		get_tree().quit(1)
		return
	print("PASS: Locked message shown correctly when quest step is started.")
	
	# 5. Advance quest to checked_alley, but fill player inventory (so item add fails)
	QuestManager.advance("alley_backrooms_3f", "checked_alley")
	
	# Fill all inventory slots (simulate bag full)
	for i in range(GameState.inventory_slots):
		GameState.inventory[i] = {
			"instance_id": GameState.generate_instance_id(),
			"item_id": "canned_food",
			"quantity": 5
		}
	
	test_state["message_text"] = ""
	test_state["on_closed"] = Callable()
	escape_instance._handle_primary_interaction()
	
	if test_state["message_text"] != escape_instance.MESSAGES["quest_box_search_quiet"]:
		printerr("FAIL: Box search message should be shown when step is checked_alley! Got: ", test_state["message_text"])
		get_tree().quit(1)
		return
		
	# Call on_closed to simulate search complete
	if test_state["on_closed"].is_null():
		printerr("FAIL: on_closed callback is null when searching box!")
		get_tree().quit(1)
		return
		
	var on_closed_callback_full = test_state["on_closed"]
	test_state["message_text"] = ""
	test_state["on_closed"] = Callable()
	
	on_closed_callback_full.call()
	
	if test_state["message_text"] != escape_instance.MESSAGES["inventory_full_for_activation_box"]:
		printerr("FAIL: Inventory full warning not shown! Got: ", test_state["message_text"])
		get_tree().quit(1)
		return
		
	# Quest state and flag should remain unchanged
	if QuestManager.get_step("alley_backrooms_3f") != "checked_alley" or QuestManager.get_flag("alley_backrooms_3f", "found_activation_box", false):
		printerr("FAIL: Quest state advanced even when inventory was full!")
		get_tree().quit(1)
		return
	print("PASS: Box search correctly handles inventory full state without changing quest flags.")
	
	# 6. Clear inventory space and try again
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
		
	test_state["message_text"] = ""
	test_state["on_closed"] = Callable()
	escape_instance._handle_primary_interaction()
	
	if test_state["message_text"] != escape_instance.MESSAGES["quest_box_search_quiet"]:
		printerr("FAIL: Box search message should be shown again! Got: ", test_state["message_text"])
		get_tree().quit(1)
		return
		
	# Call on_closed again (now bag has space)
	var on_closed_callback_ok = test_state["on_closed"]
	test_state["message_text"] = ""
	test_state["on_closed"] = Callable()
	
	on_closed_callback_ok.call()
	
	# Item should be in inventory
	if not GameState.has_item("early_ai_assistant_activation_box", 1):
		printerr("FAIL: activation box item was not added to inventory!")
		get_tree().quit(1)
		return
		
	# Quest state should be advanced to found_activation_box
	if QuestManager.get_step("alley_backrooms_3f") != "found_activation_box":
		printerr("FAIL: Quest step did not advance to found_activation_box! Got: ", QuestManager.get_step("alley_backrooms_3f"))
		get_tree().quit(1)
		return
		
	if not QuestManager.get_flag("alley_backrooms_3f", "found_activation_box", false):
		printerr("FAIL: found_activation_box flag was not set on quest!")
		get_tree().quit(1)
		return
		
	# The final box obtained message should be shown
	if test_state["message_text"] != escape_instance.MESSAGES["quest_box_obtained_box"]:
		printerr("FAIL: Box obtained message was incorrect! Got: ", test_state["message_text"])
		get_tree().quit(1)
		return
		
	print("PASS: Box search correctly advanced and final message shown.")
	
	# 7. Once found, closest interactable check should ignore the quest box
	escape_instance.interaction_requested.disconnect(test_callback)
	escape_instance._refresh_current_interactable()
	if escape_instance.current_interactable == box_area:
		printerr("FAIL: Quest box should be ignored once activation box has been found!")
		get_tree().quit(1)
		return
	print("PASS: Quest box ignored once item has been retrieved.")
	
	# Test 22: Verify 7-H R Inspect Grants Item Flow
	print("Verifying Phase 7-H R Inspect Grants Item Flow...")
	
	# 1. Reset for clean test state with active quest at found_activation_box
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	QuestManager.set_flag("alley_backrooms_3f", "found_old_ai_authorization_module", false)
	
	# 2. Add activation box (A) to inventory
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
	GameState.add_item("early_ai_assistant_activation_box", 1)
	
	var box_instance_id := ""
	for slot in GameState.get_inventory():
		if slot.get("item_id", "") == "early_ai_assistant_activation_box":
			box_instance_id = slot.get("instance_id", "")
			break
			
	if box_instance_id.is_empty():
		printerr("FAIL: Could not add activation box to inventory!")
		get_tree().quit(1)
		return
		
	# 3. Fill remaining slots to simulate bag full
	for i in range(GameState.inventory_slots):
		if GameState.inventory[i].is_empty():
			GameState.inventory[i] = {
				"instance_id": GameState.generate_instance_id(),
				"item_id": "canned_food",
				"quantity": 5
			}
			
	# 4. Open inventory UI to put UI in correct mode/state
	ui_instance.open_inventory()
	
	# 5. Trigger view action (R inspect) on A while bag is full
	ui_instance._on_bag_item_action("view", box_instance_id)
	
	# Force message to finish writing, and verify message contents
	ui_instance.force_finish_message()
	if not ui_instance.message_label.text.contains("你仔細端詳啟用盒的底部"):
		printerr("FAIL: First inspect message did not show! Got: ", ui_instance.message_label.text)
		get_tree().quit(1)
		return
		
	# Simulate closing the first message box
	var first_callback = ui_instance._message_on_closed
	if first_callback.is_null():
		printerr("FAIL: first_callback is null!")
		get_tree().quit(1)
		return
	ui_instance.close_message()
	first_callback.call()
	
	# Since bag is full, warning message should be shown next
	ui_instance.force_finish_message()
	if not ui_instance.message_label.text.contains("你發現了啟用盒底部的夾層") or not ui_instance.message_label.text.contains("但你的背包太滿了"):
		printerr("FAIL: Inventory full warning message did not show! Got: ", ui_instance.message_label.text)
		get_tree().quit(1)
		return
		
	# Flags and items should remain unchanged
	if QuestManager.get_flag("alley_backrooms_3f", "found_old_ai_authorization_module", false):
		printerr("FAIL: flag set even when inventory is full!")
		get_tree().quit(1)
		return
	if GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: old_ai_authorization_module added even when inventory is full!")
		get_tree().quit(1)
		return
		
	# Simulate closing the warning message box, which should restore the detail modal
	var warning_callback = ui_instance._message_on_closed
	if warning_callback.is_null():
		printerr("FAIL: warning_callback is null!")
		get_tree().quit(1)
		return
	ui_instance.close_message()
	warning_callback.call()
	
	if not ui_instance.item_detail_modal.visible:
		printerr("FAIL: Item detail modal not opened after warning closed!")
		get_tree().quit(1)
		return
		
	# Close the detail modal
	ui_instance.item_detail_modal.close_modal()
	if ui_instance.item_detail_modal.visible:
		printerr("FAIL: Detail modal did not close!")
		get_tree().quit(1)
		return
		
	# 6. Clear space and test successful retrieval
	for i in range(1, GameState.inventory_slots):
		GameState.inventory[i] = {}
		
	# Trigger view action (R inspect) again
	ui_instance._on_bag_item_action("view", box_instance_id)
	ui_instance.force_finish_message()
	
	var success_callback = ui_instance._message_on_closed
	if success_callback.is_null():
		printerr("FAIL: success_callback is null!")
		get_tree().quit(1)
		return
	ui_instance.close_message()
	success_callback.call()
	
	# Verify flag is set, and old_ai_authorization_module (B) is added to inventory, and A remains
	if not QuestManager.get_flag("alley_backrooms_3f", "found_old_ai_authorization_module", false):
		printerr("FAIL: flag not set on successful inspect!")
		get_tree().quit(1)
		return
	if not GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: old_ai_authorization_module not added on successful inspect!")
		get_tree().quit(1)
		return
	if not GameState.has_item("early_ai_assistant_activation_box", 1):
		printerr("FAIL: early_ai_assistant_activation_box consumed on successful inspect!")
		get_tree().quit(1)
		return
		
	# Verify detail modal is now open
	if not ui_instance.item_detail_modal.visible:
		printerr("FAIL: Detail modal not opened after successful inspect message closed!")
		get_tree().quit(1)
		return
		
	# Close the detail modal
	ui_instance.item_detail_modal.close_modal()
	
	# 7. Test subsequent inspections of A (should open detail modal directly without messages)
	ui_instance._message_on_closed = Callable()
	ui_instance._on_bag_item_action("view", box_instance_id)
	
	if ui_instance._message_on_closed.is_valid():
		printerr("FAIL: Subsequent inspect triggered message box flow!")
		get_tree().quit(1)
		return
		
	if not ui_instance.item_detail_modal.visible:
		printerr("FAIL: Detail modal not opened directly on subsequent inspect!")
		get_tree().quit(1)
		return
		
	ui_instance.item_detail_modal.close_modal()
	ui_instance.close_all_ui()
	
	print("PASS: Phase 7-H R Inspect Grants Item Flow verified successfully.")
	
	# 23. Verify Phase 7-I Turn-in Quest to Wan
	print("Verifying Phase 7-I Turn-in Quest to Wan...")
	
	# 1. Reset state
	GameState.reset_for_new_game()
	
	# 2. Start quest and advance to found_activation_box
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	
	# 3. Add item A and B to inventory
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
	GameState.add_item("early_ai_assistant_activation_box", 1)
	GameState.add_item("old_ai_authorization_module", 1)
	QuestManager.set_flag("alley_backrooms_3f", "found_old_ai_authorization_module", true)
	
	# Verify items exist
	if not GameState.has_item("early_ai_assistant_activation_box", 1) or not GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: Failed to populate items A and B for turn-in test!")
		get_tree().quit(1)
		return
		
	# 4. Instantiate dialogue tree for Wan and verify options in retalk node
	runner = DialogueRunner.new()
	DialogueDB = load("res://data/dialogue/dialogue_db.gd")
	wan_tree = DialogueDB.get_tree_for("wan")
	
	# Set met_wan flag so start goes to retalk
	GameState.set_flag("met_wan", true)
	runner.start(wan_tree)
	
	var cur = runner.current()
	# Current should be retalk
	if cur.get("text", "") == "":
		printerr("FAIL: Dialogue tree failed to start on Wan tree!")
		get_tree().quit(1)
		return
		
	# Check retalk choices to ensure choice index 3 is '我找到那個啟用盒了。'
	choices = cur.get("choices", [])
	var turn_in_choice = null
	for choice in choices:
		if choice.get("label", "") == "我找到那個啟用盒了。":
			turn_in_choice = choice
			break
			
	if not turn_in_choice:
		printerr("FAIL: Turn-in choice '我找到那個啟用盒了。' not visible in retalk node!")
		get_tree().quit(1)
		return
		
	# 5. Choose turn-in option (we have B, so this routes to turn_in_found_module choice node)
	runner.choose(turn_in_choice.get("index"))
	
	# 6. Verify transition to turn_in_found_module
	var after_choice = runner.current()
	if not after_choice.get("text", "").contains("底下還藏了什麼寶貝"):
		printerr("FAIL: Choice did not transition to turn_in_found_module node! Text got: ", after_choice.get("text"))
		get_tree().quit(1)
		return
		
	# Verify two choices present
	var end_choices = after_choice.get("choices", [])
	if end_choices.size() != 2:
		printerr("FAIL: turn_in_found_module should have 2 choices, got: ", end_choices.size())
		get_tree().quit(1)
		return
		
	# Choose Choice 0: Only turn in plain box (Ending B)
	var idx_plain = end_choices[0].get("index")
	runner.choose(idx_plain)
	
	var plain_node = runner.current()
	if not plain_node.get("text", "").contains("開玩笑的啦"):
		printerr("FAIL: turn_in_plain text incorrect! Got: ", plain_node.get("text"))
		get_tree().quit(1)
		return
		
	# Advance to trigger effects
	runner.advance()
	
	# Verify Ending B state: A removed, B retained, completed, credits = 800 (300 + 500), note B
	if GameState.has_item("early_ai_assistant_activation_box", 1):
		printerr("FAIL: early_ai_assistant_activation_box (A) was not removed in Ending B!")
		get_tree().quit(1)
		return
	if not GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: old_ai_authorization_module (B) was removed in Ending B!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("alley_backrooms_3f") != "completed":
		printerr("FAIL: Quest status is not 'completed' in Ending B!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 800:
		printerr("FAIL: Ending B credits should be 800, got: ", GameState.get_credits())
		get_tree().quit(1)
		return
	var notes_b = GameState.get_notes("工作")
	if notes_b.is_empty() or notes_b[0].get("status") != "completed" or not notes_b[0].get("body").contains("留在了自己身上"):
		printerr("FAIL: Work note for Ending B incorrect!")
		get_tree().quit(1)
		return
	print("PASS: Ending B (Kept module) verified successfully.")

	# --- Test Ending C (Gave module) ---
	# Reset state
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
	GameState.add_item("early_ai_assistant_activation_box", 1)
	GameState.add_item("old_ai_authorization_module", 1)
	QuestManager.set_flag("alley_backrooms_3f", "found_old_ai_authorization_module", true)

	runner = DialogueRunner.new()
	GameState.set_flag("met_wan", true)
	runner.start(wan_tree)
	runner.choose(turn_in_choice.get("index"))
	
	# Select Choice 1: 連舊模組也一起遞過去 (Ending C)
	end_choices = runner.current().get("choices", [])
	runner.choose(end_choices[1].get("index"))
	
	var full_node = runner.current()
	if not full_node.get("text", "").contains("舊式授權晶片"):
		printerr("FAIL: turn_in_full text incorrect! Got: ", full_node.get("text"))
		get_tree().quit(1)
		return
		
	# Advance to trigger effects
	runner.advance()
	
	# Verify Ending C state: A and B removed, completed, credits = 1300 (300 + 1000), affinity_wan = 2, gave_wan_old_module = true, note C
	if GameState.has_item("early_ai_assistant_activation_box", 1) or GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: Items A or B not removed in Ending C!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("alley_backrooms_3f") != "completed":
		printerr("FAIL: Quest status not completed in Ending C!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 1300:
		printerr("FAIL: Ending C credits should be 1300, got: ", GameState.get_credits())
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_wan") != 2 or not GameState.get_flag("gave_wan_old_module"):
		printerr("FAIL: Ending C flags/affinity not updated correctly!")
		get_tree().quit(1)
		return
	var notes_c = GameState.get_notes("工作")
	if notes_c.is_empty() or notes_c[0].get("status") != "completed" or not notes_c[0].get("body").contains("託付"):
		printerr("FAIL: Work note for Ending C incorrect!")
		get_tree().quit(1)
		return
	print("PASS: Ending C (Gave module) verified successfully.")

	# Verify retalk_close routing
	runner = DialogueRunner.new()
	runner.start(wan_tree)
	var close_node = runner.current()
	if not close_node.get("text", "").contains("擠擠"):
		printerr("FAIL: Start did not route to retalk_close after Ending C! Got: ", close_node.get("text"))
		get_tree().quit(1)
		return
	
	# Select choice 0: "陪妳站會兒。"
	var close_choices = close_node.get("choices", [])
	runner.choose(close_choices[0].get("index"))
	
	# Verify affinity increment and transition to end_close
	if GameState.get_flag("affinity_wan") != 3:
		printerr("FAIL: retalk_close choice 0 did not increment affinity_wan! Got: ", GameState.get_flag("affinity_wan"))
		get_tree().quit(1)
		return
	var close_end = runner.current()
	if not close_end.get("text", "").contains("別把雨聲"):
		printerr("FAIL: retalk_close did not transition to end_close! Got: ", close_end.get("text"))
		get_tree().quit(1)
		return
	print("PASS: retalk_close dialogue flow verified successfully.")

	# --- Test Ending A (Plain box only) ---
	# Reset state
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
	GameState.add_item("early_ai_assistant_activation_box", 1)
	QuestManager.set_flag("alley_backrooms_3f", "found_old_ai_authorization_module", false)

	runner = DialogueRunner.new()
	GameState.set_flag("met_wan", true)
	runner.start(wan_tree)
	
	# Select turn-in option (routes to turn_in_plain since we don't have B)
	runner.choose(turn_in_choice.get("index"))
	
	var plain_node_a = runner.current()
	if not plain_node_a.get("text", "").contains("開玩笑的啦"):
		printerr("FAIL: Ending A did not route directly to turn_in_plain! Got text: ", plain_node_a.get("text"))
		get_tree().quit(1)
		return
		
	# Advance to trigger effects
	runner.advance()
	
	# Verify Ending A state: A removed, completed, credits = 800 (+500), note A, gave_wan_old_module false
	if GameState.has_item("early_ai_assistant_activation_box", 1):
		printerr("FAIL: early_ai_assistant_activation_box was not removed in Ending A!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("alley_backrooms_3f") != "completed":
		printerr("FAIL: Quest status is not 'completed' in Ending A!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 800:
		printerr("FAIL: Ending A credits should be 800, got: ", GameState.get_credits())
		get_tree().quit(1)
		return
	if GameState.get_flag("gave_wan_old_module", false):
		printerr("FAIL: gave_wan_old_module should be false in Ending A!")
		get_tree().quit(1)
		return
	var notes_a = GameState.get_notes("工作")
	if notes_a.is_empty() or notes_a[0].get("status") != "completed" or not notes_a[0].get("body").contains("錯過"):
		printerr("FAIL: Work note for Ending A incorrect!")
		get_tree().quit(1)
		return
	print("PASS: Ending A (Plain box only) verified successfully.")

	# 9. Verify defensive case: if A is not in inventory, turn-in fails and quest is NOT completed
	# Reset for clean test state with active quest at found_activation_box
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	
	# Clear inventory (ensure NO activation box A is present)
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
		
	# Instantiate tree and force enter turn-in node directly (routes to turn_in_plain since no B)
	runner = DialogueRunner.new()
	wan_tree = DialogueDB.get_tree_for("wan")
	runner.start(wan_tree, "alley_backrooms_turn_in")
	
	# Advance dialogue to trigger effects
	runner.advance()
	
	# Since A was missing, remove_item effect should fail and abort completion
	if QuestManager.get_status("alley_backrooms_3f") == "completed":
		printerr("FAIL: Quest status was marked completed even when A was missing during turn-in!")
		get_tree().quit(1)
		return
		
	var notes_defensive = GameState.get_notes("工作")
	if notes_defensive.is_empty() or notes_defensive[0].get("status") == "completed":
		printerr("FAIL: Work note status was marked completed even when A was missing during turn-in!")
		get_tree().quit(1)
		return
	print("PASS: Turn-in defensive constraint verified (missing item aborts quest completion).")
		
	print("PASS: Phase 7-I Turn-in Quest to Wan verified successfully.")
	
	# 24. Verify Phase 7-J Regression & Save/Restore
	print("Verifying Phase 7-J Regression & Save/Restore...")
	
	# 1. Quest Started Save/Load Check
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")
	
	var save_p1 = SaveSystem.capture("apartment", 100.0, 1)
	if not SaveSystem.write_slot(4, save_p1):
		printerr("FAIL: Failed to write save_p1 to slot 4!")
		get_tree().quit(1)
		return
		
	GameState.reset_for_new_game()
	var loaded_p1 = SaveSystem.read_slot(4)
	SaveSystem.apply(loaded_p1)
	
	if QuestManager.get_status("alley_backrooms_3f") != "active" or QuestManager.get_step("alley_backrooms_3f") != "started":
		printerr("FAIL: Quest status/step was not restored correctly in started check!")
		get_tree().quit(1)
		return
		
	var notes_p1 = GameState.get_notes("工作")
	if notes_p1.is_empty() or notes_p1[0].get("id") != "quest_alley_backrooms_3f":
		printerr("FAIL: Quest work note not restored correctly in started check!")
		get_tree().quit(1)
		return
	print("PASS: Quest started state successfully saved and restored.")
	
	# 2. Alley Checked Save/Load Check
	QuestManager.advance("alley_backrooms_3f", "checked_alley")
	var save_p2 = SaveSystem.capture("apartment", 100.0, 1)
	if not SaveSystem.write_slot(4, save_p2):
		printerr("FAIL: Failed to write save_p2 to slot 4!")
		get_tree().quit(1)
		return
		
	GameState.reset_for_new_game()
	var loaded_p2 = SaveSystem.read_slot(4)
	SaveSystem.apply(loaded_p2)
	
	if QuestManager.get_step("alley_backrooms_3f") != "checked_alley":
		printerr("FAIL: Quest step was not restored to checked_alley!")
		get_tree().quit(1)
		return
		
	# Verify window interaction gate in apartment_room
	var room_instance_j = room_scene.instantiate()
	add_child(room_instance_j)
	var win_area_j = room_instance_j.get_node_or_null("Interactables/ApartmentWindow")
	if not win_area_j:
		printerr("FAIL: ApartmentWindow not found in room_instance_j!")
		get_tree().quit(1)
		return
	room_instance_j._on_interactable_entered(win_area_j)
	room_instance_j._refresh_current_interactable()
	if room_instance_j.current_interactable != win_area_j:
		printerr("FAIL: ApartmentWindow was not interactable after restore from checked_alley!")
		get_tree().quit(1)
		return
	room_instance_j.queue_free()
	print("PASS: Checked_alley state and window interaction gate successfully saved and restored.")
	
	# 3. Activation Box Found Save/Load Check (Inspectable A)
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
	GameState.add_item("early_ai_assistant_activation_box", 1)
	
	var save_p3 = SaveSystem.capture("apartment", 100.0, 1)
	if not SaveSystem.write_slot(4, save_p3):
		printerr("FAIL: Failed to write save_p3 to slot 4!")
		get_tree().quit(1)
		return
		
	GameState.reset_for_new_game()
	var loaded_p3 = SaveSystem.read_slot(4)
	SaveSystem.apply(loaded_p3)
	
	if not GameState.has_item("early_ai_assistant_activation_box", 1) or GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: Items not restored correctly in found_activation_box check!")
		get_tree().quit(1)
		return
		
	# Retrieve box instance id and verify we can inspect A to get B
	var box_inst_id := ""
	for slot in GameState.get_inventory():
		if slot.get("item_id", "") == "early_ai_assistant_activation_box":
			box_inst_id = slot.get("instance_id", "")
			break
			
	# Instantiate UI for modal check
	var ui_instance_j = ui_scene.instantiate()
	add_child(ui_instance_j)
	ui_instance_j.open_inventory()
	ui_instance_j._on_bag_item_action("view", box_inst_id)
	ui_instance_j.force_finish_message()
	var view_callback = ui_instance_j._message_on_closed
	ui_instance_j.close_message()
	view_callback.call()
	
	if not GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: old_ai_authorization_module (B) was not obtained on inspect after load!")
		get_tree().quit(1)
		return
	print("PASS: Item A state restored, and inspect-to-obtain-B functionality verified after load.")
	
	# 4. Authorization Module Obtained Save/Load Check
	var save_p4 = SaveSystem.capture("apartment", 100.0, 1)
	if not SaveSystem.write_slot(4, save_p4):
		printerr("FAIL: Failed to write save_p4 to slot 4!")
		get_tree().quit(1)
		return
		
	GameState.reset_for_new_game()
	var loaded_p4 = SaveSystem.read_slot(4)
	SaveSystem.apply(loaded_p4)
	
	if not GameState.has_item("early_ai_assistant_activation_box", 1) or not GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: Items A/B not restored in authorization module obtained check!")
		get_tree().quit(1)
		return
		
	# Try inspect A again and check it doesn't give duplicate B
	var box_inst_id_p4 := ""
	for slot in GameState.get_inventory():
		if slot.get("item_id", "") == "early_ai_assistant_activation_box":
			box_inst_id_p4 = slot.get("instance_id", "")
			break
	ui_instance_j._message_on_closed = Callable()
	ui_instance_j._on_bag_item_action("view", box_inst_id_p4)
	if ui_instance_j._message_on_closed.is_valid():
		printerr("FAIL: Subsequent inspect after load triggered message box flow!")
		get_tree().quit(1)
		return
	print("PASS: Item A and B state, and single-inspect constraint successfully saved and restored.")
	
	# 5. Quest Completed Save/Load Check
	GameState.remove_item("early_ai_assistant_activation_box", 1)
	QuestManager.complete("alley_backrooms_3f")
	
	var save_p5 = SaveSystem.capture("apartment", 100.0, 1)
	if not SaveSystem.write_slot(4, save_p5):
		printerr("FAIL: Failed to write save_p5 to slot 4!")
		get_tree().quit(1)
		return
		
	GameState.reset_for_new_game()
	var loaded_p5 = SaveSystem.read_slot(4)
	SaveSystem.apply(loaded_p5)
	
	if GameState.has_item("early_ai_assistant_activation_box", 1) or not GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: Item states incorrect after load in completed check!")
		get_tree().quit(1)
		return
		
	if QuestManager.get_status("alley_backrooms_3f") != "completed":
		printerr("FAIL: Quest status not 'completed' after load in completed check!")
		get_tree().quit(1)
		return
		
	var notes_p5 = GameState.get_notes("工作")
	if notes_p5.is_empty() or notes_p5[0].get("status") != "completed":
		printerr("FAIL: Work note status not 'completed' after load in completed check!")
		get_tree().quit(1)
		return
	print("PASS: Quest completed state, item states, and work note states successfully saved and restored.")
	
	# 25. Verify Quest Ending Message Boxes Triggering
	print("Verifying Quest Ending Message Boxes Triggering...")
	
	# Test case 1: Ending 1 (Did not retrieve the hidden module)
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	QuestManager.complete("alley_backrooms_3f")
	QuestManager.set_flag("alley_backrooms_3f", "found_old_ai_authorization_module", false)
	GameState.story_flags.erase("alley_backrooms_ended")
	
	UIMode.set_mode(UIMode.Mode.DIALOGUE)
	UIMode.set_mode(UIMode.Mode.NONE)
	await get_tree().process_frame
	
	if UIMode.get_mode() != UIMode.Mode.MESSAGE:
		printerr("FAIL: Ending 1 did not trigger MESSAGE mode!")
		get_tree().quit(1)
		return
	if not ui_instance.message_box.visible:
		printerr("FAIL: Ending 1 message box not visible!")
		get_tree().quit(1)
		return
	if not ui_instance.message_label.text.contains("結局 1"):
		printerr("FAIL: Ending 1 text incorrect! Got: ", ui_instance.message_label.text)
		get_tree().quit(1)
		return
	print("PASS: Ending 1 messagebox triggered successfully.")
	
	# Close the message box
	ui_instance.close_message()
	await get_tree().process_frame
	
	# Verify it doesn't trigger again
	UIMode.set_mode(UIMode.Mode.DIALOGUE)
	UIMode.set_mode(UIMode.Mode.NONE)
	await get_tree().process_frame
	if UIMode.get_mode() != UIMode.Mode.NONE:
		printerr("FAIL: Ending triggered repeatedly!")
		get_tree().quit(1)
		return
	print("PASS: Ending single-trigger constraint verified.")
	
	# Test case 2: Ending 2 (Retrieved the hidden module)
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	QuestManager.set_flag("alley_backrooms_3f", "found_old_ai_authorization_module", true)
	QuestManager.complete("alley_backrooms_3f")
	GameState.story_flags.erase("alley_backrooms_ended")

	UIMode.set_mode(UIMode.Mode.DIALOGUE)
	UIMode.set_mode(UIMode.Mode.NONE)
	await get_tree().process_frame
	
	if UIMode.get_mode() != UIMode.Mode.MESSAGE:
		printerr("FAIL: Ending 2 did not trigger MESSAGE mode!")
		get_tree().quit(1)
		return
	if not ui_instance.message_box.visible:
		printerr("FAIL: Ending 2 message box not visible!")
		get_tree().quit(1)
		return
	if not ui_instance.message_label.text.contains("結局 2"):
		printerr("FAIL: Ending 2 text incorrect! Got: ", ui_instance.message_label.text)
		get_tree().quit(1)
		return
	print("PASS: Ending 2 messagebox triggered successfully.")
	
	# Close the message box
	ui_instance.close_message()
	await get_tree().process_frame
	
	# Test case 3: Ending 3 (Gave the module)
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	QuestManager.complete("alley_backrooms_3f")
	GameState.story_flags.erase("alley_backrooms_ended")
	GameState.set_flag("gave_wan_old_module", true)

	UIMode.set_mode(UIMode.Mode.DIALOGUE)
	UIMode.set_mode(UIMode.Mode.NONE)
	await get_tree().process_frame
	
	if UIMode.get_mode() != UIMode.Mode.MESSAGE:
		printerr("FAIL: Ending 3 did not trigger MESSAGE mode!")
		get_tree().quit(1)
		return
	if not ui_instance.message_box.visible:
		printerr("FAIL: Ending 3 message box not visible!")
		get_tree().quit(1)
		return
	if not ui_instance.message_label.text.contains("結局 3"):
		printerr("FAIL: Ending 3 text incorrect! Got: ", ui_instance.message_label.text)
		get_tree().quit(1)
		return
	print("PASS: Ending 3 messagebox triggered successfully.")

	# 26. Verify Phase 8-A Convenience Store Scene Skeleton & Transitions
	print("Verifying Phase 8-A Convenience Store scene skeleton & transitions...")

	GameState.reset_for_new_game()
	ui_instance.close_message()
	await get_tree().process_frame

	# 26.1 SceneRegistry checks
	var scenes_dict_8a = main_instance.get("SCENES")
	if not scenes_dict_8a.has("convenience_store"):
		printerr("FAIL: SCENES registry is missing 'convenience_store' key!")
		get_tree().quit(1)
		return
	var store_cfg = scenes_dict_8a["convenience_store"]
	if store_cfg.get("path") != "res://scenes/levels/convenience_store/convenience_store.tscn":
		printerr("FAIL: convenience_store registry path is wrong! Got: ", store_cfg.get("path"))
		get_tree().quit(1)
		return
	if not "from_street" in store_cfg.get("entry_points", []) or store_cfg.get("default_entry_point_id") != "from_street":
		printerr("FAIL: convenience_store entry point 'from_street' not registered correctly!")
		get_tree().quit(1)
		return
	if not "from_store" in scenes_dict_8a["apartment_entrance"].get("entry_points", []):
		printerr("FAIL: apartment_entrance entry point 'from_store' not registered!")
		get_tree().quit(1)
		return
	print("PASS: SceneRegistry contains convenience_store (from_street) and apartment_entrance gains from_store.")

	# 26.2 Load & instantiate standalone, verify level contract + entry point
	var store_scene = load("res://scenes/levels/convenience_store/convenience_store.tscn")
	if not store_scene:
		printerr("FAIL: Could not load convenience_store.tscn!")
		get_tree().quit(1)
		return
	var store_instance = store_scene.instantiate()
	add_child(store_instance)

	if not store_instance.has_signal("current_interactable_changed") \
		or not store_instance.has_signal("interaction_requested") \
		or not store_instance.has_signal("scene_transition_requested"):
		printerr("FAIL: convenience_store is missing level contract signals!")
		get_tree().quit(1)
		return
	if not store_instance.has_method("prepare_entry_point") or not store_instance.has_method("set_entry_point"):
		printerr("FAIL: convenience_store is missing entry point API!")
		get_tree().quit(1)
		return

	store_instance.set_entry_point("from_street", {})
	var store_spawn = store_instance.get_node_or_null("SpawnPoints/from_street")
	if not store_spawn:
		printerr("FAIL: SpawnPoints/from_street not found in convenience_store!")
		get_tree().quit(1)
		return
	var store_player = store_instance.get_node("Player")
	if abs(store_player.global_position.x - store_spawn.global_position.x) > 1.0:
		printerr("FAIL: Player not positioned at from_street spawn! Got: ", store_player.global_position)
		get_tree().quit(1)
		return
	if not SaveSystem.can_save_here:
		printerr("FAIL: can_save_here is not true inside convenience_store!")
		get_tree().quit(1)
		return
	print("PASS: convenience_store loads with contract signals, from_street spawn, and can_save_here true.")

	# 26.3 Auto door emits transition back to street at from_store
	var store_transition_data = {}
	_temp_callable = func(scene_id, entry_point_id, payload):
		store_transition_data["scene_id"] = scene_id
		store_transition_data["entry_point_id"] = entry_point_id
		store_transition_data["payload"] = payload
	store_instance.scene_transition_requested.connect(_temp_callable)

	var auto_door_area = store_instance.get_node_or_null("Interactables/AutoDoorArea")
	if not auto_door_area:
		printerr("FAIL: AutoDoorArea not found in convenience_store!")
		get_tree().quit(1)
		return
	store_instance.current_interactable = auto_door_area
	store_instance._trigger_interaction()

	if store_transition_data.get("scene_id") != "apartment_entrance" or store_transition_data.get("entry_point_id") != "from_store":
		printerr("FAIL: Auto door transition request is wrong! Got: ", store_transition_data)
		get_tree().quit(1)
		return
	store_instance.scene_transition_requested.disconnect(_temp_callable)
	print("PASS: Store auto door emits scene_transition_requested(apartment_entrance, from_store).")

	# 26.4 Locked back door shows message only
	var store_interaction_data = {}
	_temp_callable = func(data):
		store_interaction_data.clear()
		store_interaction_data.merge(data)
	store_instance.interaction_requested.connect(_temp_callable)

	var back_door_area = store_instance.get_node_or_null("Interactables/BackDoorArea")
	if not back_door_area:
		printerr("FAIL: BackDoorArea not found in convenience_store!")
		get_tree().quit(1)
		return
	store_instance.current_interactable = back_door_area
	store_instance._trigger_interaction()

	if store_interaction_data.get("type") != "message" \
		or store_interaction_data.get("message_text") != store_instance.MESSAGES["back_door"]:
		printerr("FAIL: Back door did not show locked message! Got: ", store_interaction_data)
		get_tree().quit(1)
		return
	store_instance.interaction_requested.disconnect(_temp_callable)
	store_instance.free()
	print("PASS: Locked back door shows message only.")

	# 26.5 Street store_front now emits transition into the store
	main_instance.transition_to("apartment_entrance", "from_apartment")
	await get_tree().process_frame

	var street_8a = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("apartment_entrance.gd"):
			street_8a = child
			break
	if not street_8a:
		printerr("FAIL: Current scene is not apartment_entrance after transition!")
		get_tree().quit(1)
		return

	if not street_8a.get_node_or_null("SpawnPoints/from_store"):
		printerr("FAIL: SpawnPoints/from_store not found in apartment_entrance!")
		get_tree().quit(1)
		return

	var store_front_area = street_8a.get_node_or_null("Interactables/StoreFrontArea")
	if not store_front_area:
		printerr("FAIL: StoreFrontArea not found in apartment_entrance!")
		get_tree().quit(1)
		return

	store_transition_data.clear()
	_temp_callable = func(scene_id, entry_point_id, payload):
		store_transition_data["scene_id"] = scene_id
		store_transition_data["entry_point_id"] = entry_point_id
		store_transition_data["payload"] = payload
	street_8a.scene_transition_requested.connect(_temp_callable)

	street_8a.current_interactable = store_front_area
	street_8a._trigger_interaction()

	if store_transition_data.get("scene_id") != "convenience_store" or store_transition_data.get("entry_point_id") != "from_street":
		printerr("FAIL: store_front transition request is wrong! Got: ", store_transition_data)
		get_tree().quit(1)
		return
	street_8a.scene_transition_requested.disconnect(_temp_callable)
	print("PASS: Street store_front emits scene_transition_requested(convenience_store, from_street).")

	# 26.6 Real two-way transition through the SceneRouter
	main_instance.transition_to("convenience_store", "from_street")
	await get_tree().process_frame

	var active_store = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("convenience_store.gd"):
			active_store = child
			break
	if not active_store:
		printerr("FAIL: Current scene is not convenience_store after router transition!")
		get_tree().quit(1)
		return
	if not SaveSystem.can_save_here:
		printerr("FAIL: can_save_here is not true after router transition into store!")
		get_tree().quit(1)
		return

	main_instance.transition_to("apartment_entrance", "from_store")
	await get_tree().process_frame

	var street_back_8a = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("apartment_entrance.gd"):
			street_back_8a = child
			break
	if not street_back_8a:
		printerr("FAIL: Current scene is not apartment_entrance after leaving store!")
		get_tree().quit(1)
		return
	var street_back_spawn = street_back_8a.get_node("SpawnPoints/from_store")
	var street_back_player = street_back_8a.get_node("Player")
	if abs(street_back_player.global_position.x - street_back_spawn.global_position.x) > 1.0:
		printerr("FAIL: Player not positioned at from_store spawn after leaving store! Got: ", street_back_player.global_position)
		get_tree().quit(1)
		return
	print("PASS: Two-way street <-> store transition via SceneRouter verified.")

	# 26.7 Save/load round-trip inside the store
	main_instance.transition_to("convenience_store", "from_street")
	await get_tree().process_frame

	var save_store = SaveSystem.capture("convenience_store", 900.0, -1)
	if not SaveSystem.write_slot(5, save_store):
		printerr("FAIL: Failed to write store save to slot 5!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	if not main_instance.load_game_slot(5):
		printerr("FAIL: load_game_slot(5) failed for store save!")
		get_tree().quit(1)
		return
	await get_tree().process_frame

	var restored_store = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("convenience_store.gd"):
			restored_store = child
			break
	if not restored_store:
		printerr("FAIL: Loaded scene is not convenience_store after store save round-trip!")
		get_tree().quit(1)
		return
	var restored_player = restored_store.get_node("Player")
	if abs(restored_player.global_position.x - 900.0) > 1.0:
		printerr("FAIL: Player x not restored to 900 in store! Got: ", restored_player.global_position.x)
		get_tree().quit(1)
		return
	if restored_player.get_facing() != -1:
		printerr("FAIL: Player facing not restored to -1 in store!")
		get_tree().quit(1)
		return
	if not SaveSystem.can_save_here:
		printerr("FAIL: can_save_here is not true after loading a store save!")
		get_tree().quit(1)
		return
	print("PASS: Store save/load round-trip restores scene, position, and facing.")

	# Clean up slot 5 and release store scene reference
	if dir and dir.file_exists("save_05.sav"):
		dir.remove("save_05.sav")
	store_scene = null

	print("PASS: Phase 8-A Convenience Store scene skeleton & transitions verified successfully.")

	# 27. Verify Phase 8-B Babble Dialogues & discovered_vendor_error Aggregation
	print("Verifying Phase 8-B babble dialogues & discovered_vendor_error aggregation...")

	GameState.reset_for_new_game()

	# 27.1 Street vending machine babble message + talked_outside_vendor (single side: no discovery)
	main_instance.transition_to("apartment_entrance", "from_apartment")
	await get_tree().process_frame

	var street_8b = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("apartment_entrance.gd"):
			street_8b = child
			break
	if not street_8b:
		printerr("FAIL: Current scene is not apartment_entrance for 8-B vending check!")
		get_tree().quit(1)
		return

	var vending_area_8b = street_8b.get_node_or_null("Interactables/VendingMachineArea")
	if not vending_area_8b:
		printerr("FAIL: VendingMachineArea not found in apartment_entrance!")
		get_tree().quit(1)
		return

	var vending_interaction_data = {}
	_temp_callable = func(data):
		vending_interaction_data.clear()
		vending_interaction_data.merge(data)
	street_8b.interaction_requested.connect(_temp_callable)

	street_8b.current_interactable = vending_area_8b
	street_8b._trigger_interaction()

	if vending_interaction_data.get("type") != "message" \
		or vending_interaction_data.get("message_text") != street_8b.MESSAGES["vending_machine"]:
		printerr("FAIL: Vending machine did not show babble message! Got: ", vending_interaction_data)
		get_tree().quit(1)
		return
	if not "辭呈" in vending_interaction_data.get("message_text", ""):
		printerr("FAIL: Vending babble text lacks the malfunction echo! Got: ", vending_interaction_data.get("message_text"))
		get_tree().quit(1)
		return
	if not GameState.has_flag("talked_outside_vendor"):
		printerr("FAIL: talked_outside_vendor not set after vending interaction!")
		get_tree().quit(1)
		return
	if GameState.has_flag("discovered_vendor_error"):
		printerr("FAIL: discovered_vendor_error set after only ONE machine was talked to!")
		get_tree().quit(1)
		return
	print("PASS: Vending machine babble sets talked_outside_vendor without premature discovery.")

	# 27.2 Robot babble tree: routing, anomaly text, talked_store_robot, aggregation completes
	DialogueDB = load("res://data/dialogue/dialogue_db.gd")
	var robot_tree = DialogueDB.get_tree_for("store_robot")
	if robot_tree.is_empty():
		printerr("FAIL: DialogueDB could not fetch store_robot tree!")
		get_tree().quit(1)
		return

	runner = DialogueRunner.new()
	var robot_dialogue_finished = {"value": false}
	var robot_finished_callable := func():
		robot_dialogue_finished["value"] = true
	runner.finished.connect(robot_finished_callable)
	runner.start(robot_tree)

	var robot_curr = runner.current()
	if robot_curr.get("speaker") != "店控機器人":
		printerr("FAIL: store_robot speaker is wrong! Got: ", robot_curr.get("speaker"))
		get_tree().quit(1)
		return
	if not "排班表" in robot_curr.get("text", ""):
		printerr("FAIL: babble_intro text lacks the schedule anomaly! Got: ", robot_curr.get("text"))
		get_tree().quit(1)
		return
	if not GameState.has_flag("talked_store_robot"):
		printerr("FAIL: talked_store_robot not set on babble_intro entry!")
		get_tree().quit(1)
		return
	if not GameState.has_flag("discovered_vendor_error"):
		printerr("FAIL: discovered_vendor_error not set after talking to BOTH machines!")
		get_tree().quit(1)
		return
	print("PASS: Robot babble sets talked_store_robot and completes discovered_vendor_error aggregation.")

	# 27.3 Babble branch flow: deny choice reveals "not a vending machine", terminal finishes cleanly
	if robot_curr.get("choices", []).size() != 2:
		printerr("FAIL: babble_intro should expose 2 choices! Got: ", robot_curr.get("choices"))
		get_tree().quit(1)
		return
	runner.choose(0)
	robot_curr = runner.current()
	if not "我不是販賣機" in robot_curr.get("text", ""):
		printerr("FAIL: babble_deny text lacks identity denial! Got: ", robot_curr.get("text"))
		get_tree().quit(1)
		return
	runner.advance()
	robot_curr = runner.current()
	if not robot_curr.get("is_terminal", false):
		printerr("FAIL: babble_end should be a terminal node! Got: ", robot_curr)
		get_tree().quit(1)
		return
	runner.advance()
	if not robot_dialogue_finished["value"]:
		printerr("FAIL: store_robot babble dialogue did not emit finished!")
		get_tree().quit(1)
		return
	runner.finished.disconnect(robot_finished_callable)
	print("PASS: Babble branch flow (deny -> end -> finished) verified.")

	# 27.4 Robot-only path: no discovery until vending machine is also talked to; repeats stay idempotent
	GameState.reset_for_new_game()
	runner = DialogueRunner.new()
	runner.start(robot_tree)
	if not GameState.has_flag("talked_store_robot"):
		printerr("FAIL: talked_store_robot not set in robot-only path!")
		get_tree().quit(1)
		return
	if GameState.has_flag("talked_outside_vendor") or GameState.has_flag("discovered_vendor_error"):
		printerr("FAIL: Robot-only path leaked vendor/discovery flags!")
		get_tree().quit(1)
		return
	print("PASS: Robot-only path does not set discovered_vendor_error.")

	street_8b._trigger_interaction()
	if not GameState.has_flag("discovered_vendor_error"):
		printerr("FAIL: discovered_vendor_error not set once both sides are talked to (robot first)!")
		get_tree().quit(1)
		return

	street_8b._trigger_interaction()
	runner = DialogueRunner.new()
	runner.start(robot_tree)
	if not (GameState.has_flag("talked_outside_vendor") and GameState.has_flag("talked_store_robot") and GameState.has_flag("discovered_vendor_error")):
		printerr("FAIL: Flags regressed after repeated interactions!")
		get_tree().quit(1)
		return
	street_8b.interaction_requested.disconnect(_temp_callable)
	print("PASS: Reverse order discovery and repeated-interaction idempotence verified.")

	# 27.5 Store robot interactable dispatches dialogue (not examine message)
	store_scene = load("res://scenes/levels/convenience_store/convenience_store.tscn")
	var store_instance_8b = store_scene.instantiate()
	add_child(store_instance_8b)

	var robot_area_8b = store_instance_8b.get_node_or_null("Interactables/StoreRobotArea")
	if not robot_area_8b:
		printerr("FAIL: StoreRobotArea not found in convenience_store!")
		get_tree().quit(1)
		return
	if robot_area_8b.dialogue_id != "store_robot":
		printerr("FAIL: StoreRobotArea dialogue_id is not 'store_robot'! Got: ", robot_area_8b.dialogue_id)
		get_tree().quit(1)
		return

	var robot_dispatch_data = {}
	_temp_callable = func(data):
		robot_dispatch_data.clear()
		robot_dispatch_data.merge(data)
	store_instance_8b.interaction_requested.connect(_temp_callable)
	store_instance_8b.current_interactable = robot_area_8b
	store_instance_8b._trigger_interaction()

	if robot_dispatch_data.get("type") != "dialogue" or robot_dispatch_data.get("dialogue_id") != "store_robot":
		printerr("FAIL: Store robot interaction did not dispatch dialogue! Got: ", robot_dispatch_data)
		get_tree().quit(1)
		return
	store_instance_8b.interaction_requested.disconnect(_temp_callable)
	store_instance_8b.free()
	store_scene = null
	print("PASS: Store robot interactable dispatches store_robot dialogue.")

	print("PASS: Phase 8-B babble dialogues & discovered_vendor_error verified successfully.")

	# ==============================================================
	# Phase 8-C: 公寓電腦兩段 gate + QuestManager.start("repair_vendor_bot")
	# ==============================================================
	print("Verifying Phase 8-C: desk computer two-stage gate + quest dispatch...")

	# 重設狀態（確保乾淨的測試環境）
	GameState.reset_for_new_game()
	GameState.quest_states.clear()

	# QuestDB 內應含 repair_vendor_bot
	var QuestDB_8c = load("res://data/quests/quest_db.gd")
	if not QuestDB_8c:
		printerr("FAIL 8-C: Could not load quest_db.gd!")
		get_tree().quit(1)
		return
	var repair_quest_data = QuestDB_8c.get_quest_data("repair_vendor_bot")
	if repair_quest_data == null:
		printerr("FAIL 8-C: 'repair_vendor_bot' not found in quest_db!")
		get_tree().quit(1)
		return
	print("PASS 8-C: repair_vendor_bot registered in QuestDB.")

	# repair_vendor_bot 的 QUEST_ID、WORK_NOTE_ID 常數正確
	if repair_quest_data.QUEST_ID != "repair_vendor_bot":
		printerr("FAIL 8-C: repair_vendor_bot QUEST_ID mismatch! Got: ", repair_quest_data.QUEST_ID)
		get_tree().quit(1)
		return
	if repair_quest_data.WORK_NOTE_ID != "quest_repair_vendor_bot":
		printerr("FAIL 8-C: repair_vendor_bot WORK_NOTE_ID mismatch! Got: ", repair_quest_data.WORK_NOTE_ID)
		get_tree().quit(1)
		return
	print("PASS 8-C: QUEST_ID and WORK_NOTE_ID constants correct.")

	# STEPS 應只有 "started"
	if not repair_quest_data.STEPS.has("started") or repair_quest_data.STEPS.size() != 1:
		printerr("FAIL 8-C: repair_vendor_bot STEPS should only contain 'started'! Got: ", repair_quest_data.STEPS)
		get_tree().quit(1)
		return
	print("PASS 8-C: repair_vendor_bot STEPS contains only 'started'.")

	# HAS_COMPLETED_NOTE_RESOLVER 常數必須存在且為 true
	if not "HAS_COMPLETED_NOTE_RESOLVER" in repair_quest_data:
		printerr("FAIL 8-C: repair_vendor_bot missing HAS_COMPLETED_NOTE_RESOLVER constant!")
		get_tree().quit(1)
		return
	if not repair_quest_data.HAS_COMPLETED_NOTE_RESOLVER:
		printerr("FAIL 8-C: HAS_COMPLETED_NOTE_RESOLVER should be true!")
		get_tree().quit(1)
		return
	print("PASS 8-C: HAS_COMPLETED_NOTE_RESOLVER constant present and true.")

	# STORY_MESSAGES 應含 desk_computer_dispatch_quest
	if not GameState.STORY_MESSAGES.has("desk_computer_dispatch_quest"):
		printerr("FAIL 8-C: STORY_MESSAGES missing 'desk_computer_dispatch_quest'!")
		get_tree().quit(1)
		return
	print("PASS 8-C: desk_computer_dispatch_quest message exists in STORY_MESSAGES.")

	# ---- 模擬電腦互動真值表 ----
	# 準備公寓房間 instance（用來呼叫 _trigger_interaction）
	var room_scene_8c = load("res://scenes/levels/apartment/apartment_room.tscn")
	var room_instance_8c = room_scene_8c.instantiate()
	var ui_scene_8c = load("res://scenes/ui/game_ui.tscn")
	var ui_instance_8c = ui_scene_8c.instantiate()
	add_child(ui_instance_8c)
	add_child(room_instance_8c)
	await get_tree().process_frame

	# 確認 DeskComputerArea 有 interaction_id == "desk_computer"
	var desk_area = room_instance_8c.get_node_or_null("Interactables/DeskComputerArea")
	if not desk_area:
		printerr("FAIL 8-C: DeskComputerArea not found in apartment_room!")
		get_tree().quit(1)
		return
	if desk_area.get("interaction_id") != "desk_computer":
		printerr("FAIL 8-C: DeskComputerArea interaction_id is not 'desk_computer'! Got: ", desk_area.get("interaction_id"))
		get_tree().quit(1)
		return
	print("PASS 8-C: DeskComputerArea has interaction_id='desk_computer'.")

	# 測試狀態記錄
	var computer_dispatch_data_8c := {}
	_temp_callable = func(data):
		computer_dispatch_data_8c.clear()
		computer_dispatch_data_8c.merge(data)
	room_instance_8c.interaction_requested.connect(_temp_callable)

	# --- 測試 1：第一次互動（used_room_computer_once 未設） ---
	GameState.story_flags.erase("used_room_computer_once")
	GameState.story_flags.erase("discovered_vendor_error")
	room_instance_8c.current_interactable = desk_area
	room_instance_8c._trigger_interaction()

	if not GameState.get_flag("used_room_computer_once", false):
		printerr("FAIL 8-C: After first interaction, used_room_computer_once should be true!")
		get_tree().quit(1)
		return
	if computer_dispatch_data_8c.get("message_text", "") != GameState.STORY_MESSAGES["desk_computer_msg"]:
		printerr("FAIL 8-C: First interaction should show desk_computer_msg! Got: ", computer_dispatch_data_8c.get("message_text", ""))
		get_tree().quit(1)
		return
	if QuestManager.get_status("repair_vendor_bot") == "active":
		printerr("FAIL 8-C: Quest should NOT be started on first interaction!")
		get_tree().quit(1)
		return
	print("PASS 8-C: First computer interaction shows old content and sets used_room_computer_once.")

	# --- 測試 2：第二次互動 + discovered_vendor_error 但任務未接 → 派工 ---
	GameState.set_flag("discovered_vendor_error", true)
	# 確保任務尚未啟動
	if GameState.quest_states.has("repair_vendor_bot"):
		GameState.quest_states.erase("repair_vendor_bot")
	computer_dispatch_data_8c.clear()
	room_instance_8c.current_interactable = desk_area
	room_instance_8c._trigger_interaction()

	if QuestManager.get_status("repair_vendor_bot") != "active":
		printerr("FAIL 8-C: Quest 'repair_vendor_bot' should be active after quest dispatch! Got status: ", QuestManager.get_status("repair_vendor_bot"))
		get_tree().quit(1)
		return
	if computer_dispatch_data_8c.get("message_text", "") != GameState.STORY_MESSAGES["desk_computer_dispatch_quest"]:
		printerr("FAIL 8-C: Quest dispatch should show desk_computer_dispatch_quest message!")
		get_tree().quit(1)
		return
	print("PASS 8-C: Second interaction with discovered_vendor_error dispatches quest and shows dispatch message.")

	# 工作筆記應出現在「工作」分類
	var work_notes_8c = GameState.get_notes("工作")
	var found_quest_note_8c := false
	for note in work_notes_8c:
		if note.get("id") == "quest_repair_vendor_bot":
			found_quest_note_8c = true
			break
	if not found_quest_note_8c:
		printerr("FAIL 8-C: Work note 'quest_repair_vendor_bot' not found in 工作 category after quest dispatch!")
		get_tree().quit(1)
		return
	print("PASS 8-C: Work note 'quest_repair_vendor_bot' appears in 工作 notes after quest dispatch.")

	# --- 測試 3：任務已 active 時再互動電腦不重開任務 ---
	var before_step = QuestManager.get_step("repair_vendor_bot")
	computer_dispatch_data_8c.clear()
	room_instance_8c.current_interactable = desk_area
	room_instance_8c._trigger_interaction()

	if QuestManager.get_step("repair_vendor_bot") != before_step:
		printerr("FAIL 8-C: Quest step should not change when interacting with computer while quest is already active!")
		get_tree().quit(1)
		return
	if computer_dispatch_data_8c.get("message_text", "") != GameState.STORY_MESSAGES["desk_computer_msg"]:
		printerr("FAIL 8-C: Repeated interaction when quest is active should show desk_computer_msg fallback!")
		get_tree().quit(1)
		return
	print("PASS 8-C: Repeated computer interaction while quest is active doesn't restart quest.")

	# --- 測試 4：未發現異常（第二次起 + NOT discovered_vendor_error）不派工 ---
	GameState.story_flags.erase("discovered_vendor_error")
	if GameState.quest_states.has("repair_vendor_bot"):
		GameState.quest_states.erase("repair_vendor_bot")
	computer_dispatch_data_8c.clear()
	room_instance_8c.current_interactable = desk_area
	room_instance_8c._trigger_interaction()

	if QuestManager.get_status("repair_vendor_bot") == "active":
		printerr("FAIL 8-C: Quest should NOT be dispatched without discovered_vendor_error!")
		get_tree().quit(1)
		return
	if computer_dispatch_data_8c.get("message_text", "") != GameState.STORY_MESSAGES["desk_computer_msg"]:
		printerr("FAIL 8-C: Without discovered_vendor_error, computer should show old content!")
		get_tree().quit(1)
		return
	print("PASS 8-C: Computer without discovered_vendor_error shows old content (no quest dispatch).")

	# --- 測試 5：resolve_completed_note() 依 store_robot_resolution 分流 ---
	GameState.story_flags.erase("store_robot_resolution")
	var note_reset = repair_quest_data.resolve_completed_note()
	if note_reset.get("id") != "quest_repair_vendor_bot" or note_reset.get("status") != "completed":
		printerr("FAIL 8-C: resolve_completed_note() default (no resolution) should return 'reset' completed note!")
		get_tree().quit(1)
		return
	if not note_reset.get("body", "").contains("直接重置"):
		printerr("FAIL 8-C: Default resolved note body should mention '直接重置'! Got: ", note_reset.get("body", ""))
		get_tree().quit(1)
		return
	print("PASS 8-C: resolve_completed_note() returns reset variant by default.")

	GameState.set_flag("store_robot_resolution", "gleaned")
	var note_gleaned = repair_quest_data.resolve_completed_note()
	if not note_gleaned.get("body", "").contains("殘響"):
		printerr("FAIL 8-C: Gleaned resolved note body should mention '殘響'! Got: ", note_gleaned.get("body", ""))
		get_tree().quit(1)
		return
	print("PASS 8-C: resolve_completed_note() returns gleaned variant when store_robot_resolution='gleaned'.")

	# Cleanup 8-C
	room_instance_8c.interaction_requested.disconnect(_temp_callable)
	room_instance_8c.free()
	ui_instance_8c.free()
	room_scene_8c = null
	ui_scene_8c = null
	_temp_callable = Callable()
	GameState.story_flags.erase("store_robot_resolution")
	if GameState.quest_states.has("repair_vendor_bot"):
		GameState.quest_states.erase("repair_vendor_bot")
	await get_tree().process_frame

	print("PASS: Phase 8-C desk computer gate & quest dispatch verified successfully.")

	# ---- Phase 8-D: 蒐證 + 診斷對話樹 ----
	print("Verifying Phase 8-D: clues examine & store robot diagnostic tree...")
	
	store_scene = load("res://scenes/levels/convenience_store/convenience_store.tscn")
	if not store_scene:
		printerr("FAIL 8-D: Could not load convenience_store.tscn!")
		get_tree().quit(1)
		return
	
	store_instance = store_scene.instantiate()
	add_child(store_instance)
	await get_tree().process_frame
	
	var locker_area = store_instance.get_node_or_null("Interactables/ClerkLockerArea")
	var diary_area = store_instance.get_node_or_null("Interactables/ClerkDiaryArea")
	var notice_area = store_instance.get_node_or_null("Interactables/TerminationNoticeArea")
	var photo_area = store_instance.get_node_or_null("Interactables/CounterPhotoArea")
	var plate_area = store_instance.get_node_or_null("Interactables/RobotPlateArea")
	var host_area = store_instance.get_node_or_null("Interactables/StoreRegistryHostArea")
	
	if not locker_area or not diary_area or not notice_area or not photo_area or not plate_area or not host_area:
		printerr("FAIL 8-D: Clue areas or host area not found in convenience_store.tscn!")
		get_tree().quit(1)
		return
	print("PASS 8-D: Clue areas and host area exist in convenience_store.tscn.")

	# ---- Test 1: Gating before quest is active ----
	if GameState.quest_states.has("repair_vendor_bot"):
		GameState.quest_states.erase("repair_vendor_bot")
	
	store_instance.nearby_interactables.clear()
	for area in [locker_area, diary_area, notice_area, photo_area, plate_area, host_area]:
		store_instance.nearby_interactables.append(area)
	var closest_before = store_instance._get_closest_interactable()
	if closest_before != null:
		printerr("FAIL 8-D: Clues and host should be gated and ignored before quest is active! Got: ", closest_before.name)
		get_tree().quit(1)
		return
	print("PASS 8-D: Clue areas and host area are gated before quest is active.")

	# ---- Test 2: Gating after quest is active ----
	QuestManager.start("repair_vendor_bot")
	# Clues should now be accessible, but host is still gated since mainframe_revealed is false
	store_instance.nearby_interactables.clear()
	store_instance.nearby_interactables.append(locker_area)
	var closest_after_locker = store_instance._get_closest_interactable()
	if closest_after_locker != locker_area:
		printerr("FAIL 8-D: locker_area should be accessible after quest is active!")
		get_tree().quit(1)
		return
	
	store_instance.nearby_interactables.clear()
	store_instance.nearby_interactables.append(host_area)
	var closest_after_host = store_instance._get_closest_interactable()
	if closest_after_host != null:
		printerr("FAIL 8-D: host_area should remain gated before mainframe_revealed is true!")
		get_tree().quit(1)
		return
	print("PASS 8-D: Clue areas accessible and host area remains gated after quest is active.")

	# ---- Test 3: Clue examine & note creation ----
	GameState.notes.clear()
	var clue_emit_data = {}
	_temp_callable = func(data):
		clue_emit_data.clear()
		clue_emit_data.merge(data)
	store_instance.interaction_requested.connect(_temp_callable)
	
	var clue_areas = [locker_area, diary_area, notice_area, photo_area, plate_area]
	var expected_note_ids = ["clue_clerk_locker", "clue_clerk_diary", "clue_termination_notice", "clue_counter_photo", "clue_robot_plate"]
	
	for i in range(clue_areas.size()):
		var area = clue_areas[i]
		var note_id = expected_note_ids[i]
		
		# First examine
		store_instance.current_interactable = area
		store_instance._trigger_interaction()
		
		if clue_emit_data.get("type") != "message" or clue_emit_data.get("note_title", "") == "":
			printerr("FAIL 8-D: First examine on " + area.name + " should show message and note_title toast! Got: ", clue_emit_data)
			get_tree().quit(1)
			return
		
		if not GameState.has_note(note_id):
			printerr("FAIL 8-D: GameState should have note: " + note_id)
			get_tree().quit(1)
			return
		
		# Second examine: toast should be empty (no duplicate note notification)
		clue_emit_data.clear()
		store_instance._trigger_interaction()
		if clue_emit_data.get("note_title", "") != "":
			printerr("FAIL 8-D: Repeated examine on " + area.name + " should not toast note_title!")
			get_tree().quit(1)
			return
		
		var notes_list = GameState.get_notes("線索")
		var note_count = 0
		for n in notes_list:
			if n.get("id") == note_id:
				note_count += 1
		if note_count != 1:
			printerr("FAIL 8-D: Note " + note_id + " should not be duplicated! Got count: ", note_count)
			get_tree().quit(1)
			return
	
	print("PASS 8-D: All 5 clues successfully examined, notes created and deduplicated.")

	# ---- Test 4: Dialogue option gating depending on note presence ----
	robot_tree = DialogueDB.get_tree_for("store_robot")
	if robot_tree.is_empty():
		printerr("FAIL 8-D: DialogueDB store_robot tree not found!")
		get_tree().quit(1)
		return
	
	var diag_runner = DialogueRunner.new()
	
	# Clear clue notes temporarily to test gating
	GameState.notes.clear()
	diag_runner.start(robot_tree, "diagnose_intro")
	
	var node_identity = robot_tree["diagnose_identity"]
	diag_runner._enter_node("diagnose_identity")
	var curr_identity = diag_runner.current()
	
	var choices_identity = curr_identity.get("choices", [])
	# Without clues, correct option (index 0) should be hidden, leaving only index 1 and 2
	var found_correct_identity := false
	for choice in choices_identity:
		if choice.get("index") == 0:
			found_correct_identity = true
	if found_correct_identity:
		printerr("FAIL 8-D: Correct identity choice should be gated/hidden without clues!")
		get_tree().quit(1)
		return
	print("PASS 8-D: Correct identity choice gated without clues.")

	# ---- Test 5: Dialogue tree full-truth path flow (all clues found) ----
	# Restore all clue notes
	for note_id in expected_note_ids:
		var note_data = store_instance.NOTES[note_id]
		GameState.add_knowledge(note_data)
		
	# Start dialogue from diagnose_intro
	diag_runner.start(robot_tree, "diagnose_intro")
	
	# Intro choices: index 0 (進行診斷) -> diagnose_identity
	var curr_node = diag_runner.current()
	if curr_node.choices.size() != 2:
		printerr("FAIL 8-D: diagnose_intro choices size mismatch! Got: ", curr_node.choices.size())
		get_tree().quit(1)
		return
	
	diag_runner.choose(0) # We go to diagnose_identity
	curr_node = diag_runner.current()
	if diag_runner._current_node_id != "diagnose_identity":
		printerr("FAIL 8-D: Should enter diagnose_identity! Got: ", diag_runner._current_node_id)
		get_tree().quit(1)
		return
	
	# Identity choices: correct option (index 0) must be visible now
	var found_correct_id_now := false
	for choice in curr_node.choices:
		if choice.get("index") == 0:
			found_correct_id_now = true
	if not found_correct_id_now:
		printerr("FAIL 8-D: Correct identity choice should be visible with all clues!")
		get_tree().quit(1)
		return
		
	diag_runner.choose(0) # Go to diagnose_identity_correct
	curr_node = diag_runner.current()
	if diag_runner._current_node_id != "diagnose_identity_correct":
		printerr("FAIL 8-D: Should enter diagnose_identity_correct! Got: ", diag_runner._current_node_id)
		get_tree().quit(1)
		return
	
	# Identity correct choices: correct option (index 0) must be visible
	var found_correct_reason := false
	for choice in curr_node.choices:
		if choice.get("index") == 0:
			found_correct_reason = true
	if not found_correct_reason:
		printerr("FAIL 8-D: Correct reason choice should be visible with clues!")
		get_tree().quit(1)
		return
		
	diag_runner.choose(0) # Go to diagnose_reason_correct
	curr_node = diag_runner.current()
	if diag_runner._current_node_id != "diagnose_reason_correct":
		printerr("FAIL 8-D: Should enter diagnose_reason_correct! Got: ", diag_runner._current_node_id)
		get_tree().quit(1)
		return
	
	# Reason correct choices: correct option (index 0) must be visible
	var found_correct_truth := false
	for choice in curr_node.choices:
		if choice.get("index") == 0:
			found_correct_truth = true
	if not found_correct_truth:
		printerr("FAIL 8-D: Correct truth choice should be visible with clues!")
		get_tree().quit(1)
		return
		
	diag_runner.choose(0) # Go to diagnose_truth_leaf
	curr_node = diag_runner.current()
	if diag_runner._current_node_id != "diagnose_truth_leaf":
		printerr("FAIL 8-D: Should enter diagnose_truth_leaf! Got: ", diag_runner._current_node_id)
		get_tree().quit(1)
		return
		
	# Check quest flags after truth leaf
	if not QuestManager.get_flag("repair_vendor_bot", "mainframe_revealed", false):
		printerr("FAIL 8-D: mainframe_revealed quest flag not set on truth leaf!")
		get_tree().quit(1)
		return
	if not QuestManager.get_flag("repair_vendor_bot", "diagnosed", false):
		printerr("FAIL 8-D: diagnosed quest flag not set on truth leaf!")
		get_tree().quit(1)
		return
	if not QuestManager.get_flag("repair_vendor_bot", "understood_robot_truth", false):
		printerr("FAIL 8-D: understood_robot_truth quest flag not set on truth leaf!")
		get_tree().quit(1)
		return
	
	# Test host gating after mainframe_revealed is true
	store_instance.nearby_interactables.clear()
	store_instance.nearby_interactables.append(host_area)
	var closest_after_reveal = store_instance._get_closest_interactable()
	if closest_after_reveal != host_area:
		printerr("FAIL 8-D: host_area should be accessible after mainframe_revealed is true!")
		get_tree().quit(1)
		return
	print("PASS 8-D: Dialogue truth path and flags (mainframe_revealed, diagnosed, understood_robot_truth) verified.")

	# ---- Test 6: Dialogue tree partial path flow (incorrect choices selected) ----
	# Reset quest flags
	QuestManager.set_flag("repair_vendor_bot", "mainframe_revealed", false)
	QuestManager.set_flag("repair_vendor_bot", "diagnosed", false)
	QuestManager.set_flag("repair_vendor_bot", "understood_robot_truth", false)
	
	diag_runner.start(robot_tree, "diagnose_intro")
	diag_runner.choose(1) # We choose index 1: (不工作) -> diagnose_partial_intro
	curr_node = diag_runner.current()
	if diag_runner._current_node_id != "diagnose_partial_intro":
		printerr("FAIL 8-D: Should enter diagnose_partial_intro! Got: ", diag_runner._current_node_id)
		get_tree().quit(1)
		return
		
	# Check quest flags after partial leaf
	if not QuestManager.get_flag("repair_vendor_bot", "mainframe_revealed", false):
		printerr("FAIL 8-D: mainframe_revealed quest flag not set on partial leaf!")
		get_tree().quit(1)
		return
	if not QuestManager.get_flag("repair_vendor_bot", "diagnosed", false):
		printerr("FAIL 8-D: diagnosed quest flag not set on partial leaf!")
		get_tree().quit(1)
		return
	if QuestManager.get_flag("repair_vendor_bot", "understood_robot_truth", false):
		printerr("FAIL 8-D: understood_robot_truth should NOT be set on partial leaf!")
		get_tree().quit(1)
		return
	print("PASS 8-D: Dialogue partial path and flags verified.")

	# Cleanup 8-D
	store_instance.interaction_requested.disconnect(_temp_callable)
	store_instance.queue_free()
	store_scene = null
	diag_runner = null
	_temp_callable = Callable()
	if GameState.quest_states.has("repair_vendor_bot"):
		GameState.quest_states.erase("repair_vendor_bot")
	GameState.notes.clear()
	await get_tree().process_frame
	
	print("PASS: Phase 8-D clues & store robot diagnostic tree verified successfully.")

	# Clean up slot 4
	if dir and dir.file_exists("save_04.sav"):
		dir.remove("save_04.sav")
		
	# Clean up temporary instances
	ui_instance_j.free()
	
	# Clean up fire escape test instance
	escape_instance.free()
	escape_scene = null

	# Clean up instantiated test nodes
	if is_instance_valid(ui_instance):
		ui_instance.free()
	if is_instance_valid(street_instance):
		street_instance.free()
	if is_instance_valid(main_instance):
		main_instance.free()

	# Wait a frame to let queue_free'd nodes actually get deleted
	await get_tree().process_frame

	# Release RefCounted resources explicitly to prevent exit leaks
	room_scene = null
	ui_scene = null
	main_scene = null
	street_scene = null
	DialogueDB = null
	title_scene = null
	runner = null
	press_e = Callable()
	_temp_callable = Callable()

	print("==================================================")
	print("ALL INTEGRATION VERIFICATIONS PASSED SUCCESSFULLY!")
	print("==================================================")
	
	# Defer quit so that this ready function can return and pop stack frame, clearing references
	get_tree().call_deferred("quit", 0)
